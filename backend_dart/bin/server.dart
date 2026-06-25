import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:postgres/postgres.dart';
import 'package:dotenv/dotenv.dart';

import 'auth_helpers.dart';

// Global DB pool
late final Pool dbPool;
// JWT Secret Key
late final String secretKey;

// ─── UTILITIES & SERIALIZERS ───────────────────────────────────────────────

Response jsonResponse(dynamic data, {int statusCode = 200}) {
  return Response(
    statusCode,
    body: jsonEncode(data),
    headers: {'content-type': 'application/json'},
  );
}

Response errorResponse(String message, {int statusCode = 400}) {
  return Response(
    statusCode,
    body: jsonEncode({'detail': message, 'error': message}),
    headers: {'content-type': 'application/json'},
  );
}

int getUserId(Request request) {
  final uid = request.context['user_id'];
  if (uid == null) {
    throw StateError('User ID not found in request context.');
  }
  return uid as int;
}

String? getUserRole(Request request) {
  return request.context['user_role'] as String?;
}

String? getUserEmail(Request request) {
  return request.context['user_email'] as String?;
}

dynamic parseJsonField(dynamic val) {
  if (val == null) return null;
  if (val is String) {
    try {
      return jsonDecode(val);
    } catch (_) {
      return val;
    }
  }
  return val;
}

Map<String, dynamic> formatUserMe(Map<String, dynamic> u) {
  return {
    'id': u['id'],
    'first_name': u['first_name'] ?? '',
    'last_name': u['last_name'] ?? '',
    'email': u['email'] ?? '',
    'username': u['username'] ?? '',
    'role': u['role'] ?? 'CLIENT',
    'phone': u['phone'] ?? '',
    'avatar_url': u['avatar_url'] ?? '',
    'is_verified': u['is_verified'] ?? false,
    'language_preference': u['language_preference'] ?? 'en',
    'country': u['country'] ?? '',
    'created_at': u['created_at'] != null ? (u['created_at'] as DateTime).toIso8601String() : '',
  };
}

Map<String, dynamic> formatUserPublic(Map<String, dynamic> u) {
  return {
    'id': u['id'],
    'first_name': u['first_name'] ?? '',
    'last_name': u['last_name'] ?? '',
    'username': u['username'] ?? '',
    'role': u['role'] ?? 'CLIENT',
    'avatar_url': u['avatar_url'] ?? '',
    'is_verified': u['is_verified'] ?? false,
    'country': u['country'] ?? '',
    'services': [], // Filled externally
  };
}

Map<String, dynamic> formatJoinedTask(Map<String, dynamic> row) {
  final categoryId = row['category_id'];
  Map<String, dynamic>? categoryMap;
  if (categoryId != null) {
    categoryMap = {
      'id': categoryId,
      'name': row['category_name'] ?? '',
      'slug': row['category_slug'] ?? '',
    };
  }

  final clientId = row['client_id'];
  Map<String, dynamic>? clientMap;
  if (clientId != null) {
    clientMap = {
      'id': clientId,
      'email': row['client_email'] ?? '',
      'username': row['client_email'] ?? '',
      'first_name': row['client_first_name'] ?? '',
      'last_name': row['client_last_name'] ?? '',
      'avatar_url': row['client_avatar'] ?? '',
      'role': row['client_role'] ?? '',
      'is_verified': row['client_is_verified'] ?? false,
    };
  }

  final assignedId = row['assigned_to_id'];
  Map<String, dynamic>? assignedMap;
  if (assignedId != null) {
    assignedMap = {
      'id': assignedId,
      'email': row['assigned_email'] ?? '',
      'username': row['assigned_email'] ?? '',
      'first_name': row['assigned_first_name'] ?? '',
      'last_name': row['assigned_last_name'] ?? '',
      'avatar_url': row['assigned_avatar'] ?? '',
      'role': row['assigned_role'] ?? '',
      'is_verified': row['assigned_is_verified'] ?? false,
    };
  }

  return {
    'id': row['id'],
    'title': row['title'] ?? '',
    'description': row['description'] ?? '',
    'status': row['status'] ?? '',
    'budget_min': row['budget_min'] != null ? row['budget_min'].toString() : null,
    'budget_max': row['budget_max'] != null ? row['budget_max'].toString() : null,
    'budget_mode': row['budget_mode'] ?? '',
    'urgency': row['urgency'] ?? '',
    'service_type': row['service_type'] ?? '',
    'location': row['location'] ?? '',
    'city': row['city'] ?? '',
    'latitude': row['latitude'] != null ? row['latitude'].toString() : null,
    'longitude': row['longitude'] != null ? row['longitude'].toString() : null,
    'schedule': row['schedule'] ?? '',
    'deadline': row['deadline'] != null ? (row['deadline'] is DateTime ? (row['deadline'] as DateTime).toIso8601String().substring(0, 10) : row['deadline'].toString()) : null,
    'materials_provided': row['materials_provided'] ?? false,
    'contact_methods': parseJsonField(row['contact_methods']) ?? [],
    'views_count': row['views_count'] ?? 0,
    'bids_count': row['bids_count'] ?? 0,
    'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
    'updated_at': row['updated_at'] != null ? (row['updated_at'] as DateTime).toIso8601String() : '',
    'published_at': row['published_at'] != null ? (row['published_at'] as DateTime).toIso8601String() : null,
    'category': categoryMap,
    'client': clientMap,
    'assigned_to': assignedMap,
    'skills': [], // filled externally
  };
}

Map<String, dynamic> formatBid(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'task_id': row['task_id'],
    'amount': row['amount']?.toString() ?? '0.00',
    'amount_type': row['amount_type'] ?? 'fixed',
    'message': row['message'] ?? '',
    'duration': row['duration'] ?? '',
    'extra_notes': row['extra_notes'] ?? '',
    'status': row['status'] ?? '',
    'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
    'updated_at': row['updated_at'] != null ? (row['updated_at'] as DateTime).toIso8601String() : '',
    'accepted_at': row['accepted_at'] != null ? (row['accepted_at'] as DateTime).toIso8601String() : null,
    'rejected_at': row['rejected_at'] != null ? (row['rejected_at'] as DateTime).toIso8601String() : null,
    'technician': {
      'id': row['tech_id'],
      'email': row['tech_email'],
      'first_name': row['tech_first_name'] ?? '',
      'last_name': row['tech_last_name'] ?? '',
      'avatar_url': row['tech_avatar'] ?? '',
      'is_verified': row['tech_is_verified'] ?? false,
    }
  };
}

Map<String, dynamic> formatTransaction(Map<String, dynamic> tx) {
  return {
    'id': tx['id'],
    'amount': tx['amount']?.toString() ?? '0.00',
    'type': tx['type'] ?? '',
    'category': tx['category'] ?? '',
    'description': tx['description'] ?? '',
    'status': tx['status'] ?? '',
    'metadata': parseJsonField(tx['metadata']) ?? {},
    'created_at': tx['created_at'] != null ? (tx['created_at'] as DateTime).toIso8601String() : '',
    'reference': tx['reference_id'],
  };
}

// ─── AUDIT LOGS & NOTIFICATIONS HELPERS ────────────────────────────────────

Future<void> createAuditLog({
  required int? actorId,
  required String action,
  required String entityType,
  required String entityId,
  required String summary,
  required Map<String, dynamic> metadata,
  required String? ipAddress,
}) async {
  try {
    await dbPool.execute(
      Sql.named('INSERT INTO governance_audit_log (action, entity_type, entity_id, summary, metadata, ip_address, created_at, actor_id) '
                'VALUES (@action, @entityType, @entityId, @summary, @metadata, @ip, @now, @actorId)'),
      parameters: {
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'summary': summary,
        'metadata': jsonEncode(metadata),
        'ip': ipAddress,
        'now': DateTime.now(),
        'actorId': actorId,
      },
    );
  } catch (e) {
    print('Failed to create audit log: $e');
  }
}

Future<void> createNotification({
  required int userId,
  required String category,
  required String title,
  required String body,
  required String link,
  required Map<String, dynamic> metadata,
}) async {
  try {
    await dbPool.execute(
      Sql.named('INSERT INTO governance_notification (category, title, body, link, metadata, is_read, created_at, user_id) '
                'VALUES (@category, @title, @body, @link, @metadata, @isRead, @now, @userId)'),
      parameters: {
        'category': category,
        'title': title,
        'body': body,
        'link': link,
        'metadata': jsonEncode(metadata),
        'isRead': false,
        'now': DateTime.now(),
        'userId': userId,
      },
    );
  } catch (e) {
    print('Failed to create notification: $e');
  }
}

// ─── MIDDLEWARES ───────────────────────────────────────────────────────────

bool isPublicPath(String path, String method) {
  final p = path.trim().replaceAll(RegExp(r'^/|/$'), '');

  if (p == 'api/auth/login' ||
      p == 'api/auth/otp/request' ||
      p == 'api/auth/otp/verify' ||
      p == 'api/auth/register/client' ||
      p == 'api/auth/register/technician' ||
      p == 'api/auth/register/company') {
    return true;
  }

  if (p == 'api/auth/users' && method == 'GET') return true;
  if (RegExp(r'^api/auth/users/\d+$').hasMatch(p) && method == 'GET') return true;

  if (p == 'api/tasks' && method == 'GET') return true;
  if (p == 'api/tasks/categories' && method == 'GET') return true;
  if (RegExp(r'^api/tasks/categories/\d+$').hasMatch(p) && method == 'GET') return true;
  if (p == 'api/tasks/skills' && method == 'GET') return true;
  if (RegExp(r'^api/tasks/\d+$').hasMatch(p) && method == 'GET') return true;
  if (RegExp(r'^api/tasks/\d+/bids$').hasMatch(p) && method == 'GET') return true;

  if (p == 'api/company' && method == 'GET') return true;
  if (RegExp(r'^api/company/\d+$').hasMatch(p) && method == 'GET') return true;

  if (p == 'api/search' && method == 'GET') return true;

  if (p == 'api/governance/public-pages' && method == 'GET') return true;
  if (RegExp(r'^api/governance/public-pages/[^/]+$').hasMatch(p) && method == 'GET') return true;

  return false;
}

Middleware authMiddleware(String secret) {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return innerHandler(request);
      }

      final path = request.url.path;
      final isPublic = isPublicPath(path, request.method);

      final authHeader = request.headers['Authorization'] ?? request.headers['authorization'];
      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        final token = authHeader.substring(7);
        final payload = verifyJwt(token, secret);
        if (payload != null) {
          final updatedRequest = request.change(context: {
            'user_id': payload['user_id'],
            'user_role': payload['role'],
            'user_email': payload['email'],
          });
          return innerHandler(updatedRequest);
        } else if (!isPublic) {
          return Response(401, body: jsonEncode({'detail': 'Invalid or expired token.'}), headers: {'content-type': 'application/json'});
        }
      }

      if (!isPublic) {
        return Response(401, body: jsonEncode({'detail': 'Authentication credentials were not provided.'}), headers: {'content-type': 'application/json'});
      }

      return innerHandler(request);
    };
  };
}

Middleware corsHeaders() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return Response(200, headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept, Authorization',
        });
      }

      final response = await innerHandler(request);
      return response.change(headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept, Authorization',
      });
    };
  };
}

// ─── AUTH CONTROLLERS ──────────────────────────────────────────────────────

Future<Response> loginHandler(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final email = body['username']?.toString().trim();
  final password = body['password']?.toString();

  if (email == null || email.isEmpty || password == null || password.isEmpty) {
    return errorResponse('Email and password are required', statusCode: 400);
  }

  final results = await dbPool.execute(
    Sql.named('SELECT * FROM accounts_user WHERE email = @email OR username = @email'),
    parameters: {'email': email},
  );

  if (results.isEmpty) {
    return errorResponse('No active account found with the given credentials', statusCode: 401);
  }

  final user = results[0].toColumnMap();
  final isActive = user['is_active'] as bool? ?? false;
  if (!isActive) {
    return errorResponse('This account is suspended.', statusCode: 401);
  }

  final dbHash = user['password'] as String? ?? '';
  if (!verifyPassword(password, dbHash)) {
    return errorResponse('Invalid email/password.', statusCode: 401);
  }

  // Update last login
  final now = DateTime.now();
  await dbPool.execute(
    Sql.named('UPDATE accounts_user SET last_login = @now WHERE id = @id'),
    parameters: {'now': now, 'id': user['id']},
  );

  // Generate tokens
  final userId = user['id'] as int;
  final role = user['role']?.toString() ?? 'CLIENT';
  final userEmail = user['email']?.toString() ?? '';

  final accessPayload = {
    'user_id': userId,
    'role': role,
    'email': userEmail,
    'token_type': 'access',
    'exp': (now.millisecondsSinceEpoch ~/ 1000) + 15 * 60, // 15 mins
  };

  final refreshPayload = {
    'user_id': userId,
    'role': role,
    'email': userEmail,
    'token_type': 'refresh',
    'exp': (now.millisecondsSinceEpoch ~/ 1000) + 7 * 24 * 60 * 60, // 7 days
  };

  final accessToken = generateJwt(payload: accessPayload, secret: secretKey);
  final refreshToken = generateJwt(payload: refreshPayload, secret: secretKey);

  await createAuditLog(
    actorId: userId,
    action: 'user_logged_in',
    entityType: 'user',
    entityId: userId.toString(),
    summary: 'Logged in successfully',
    metadata: {'email': userEmail},
    ipAddress: null,
  );

  return jsonResponse({
    'access': accessToken,
    'refresh': refreshToken,
    'role': role,
    'username': user['username'],
    'email': userEmail,
    'first_name': user['first_name'] ?? '',
    'last_name': user['last_name'] ?? '',
  });
}

Future<Response> tokenRefreshHandler(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final refresh = body['refresh']?.toString();

  if (refresh == null) {
    return errorResponse('refresh token is required', statusCode: 400);
  }

  final payload = verifyJwt(refresh, secretKey);
  if (payload == null || payload['token_type'] != 'refresh') {
    return errorResponse('Invalid or expired refresh token', statusCode: 401);
  }

  final userId = payload['user_id'] as int;
  final role = payload['role']?.toString() ?? 'CLIENT';
  final email = payload['email']?.toString() ?? '';

  final now = DateTime.now();
  final accessPayload = {
    'user_id': userId,
    'role': role,
    'email': email,
    'token_type': 'access',
    'exp': (now.millisecondsSinceEpoch ~/ 1000) + 15 * 60,
  };

  final accessToken = generateJwt(payload: accessPayload, secret: secretKey);
  return jsonResponse({'access': accessToken});
}

Future<Response> requestOtpHandler(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final phone = body['phone']?.toString().trim();
  final email = body['email']?.toString().trim();
  final purpose = body['purpose']?.toString().trim() ?? 'verification';

  if (phone == null || phone.isEmpty) {
    return errorResponse('phone is required', statusCode: 400);
  }

  // Find user by email or phone
  int? userId;
  if (email != null && email.isNotEmpty) {
    final res = await dbPool.execute(Sql.named('SELECT id FROM accounts_user WHERE email = @email'), parameters: {'email': email});
    if (res.isNotEmpty) userId = res[0][0] as int;
  }
  if (userId == null) {
    final res = await dbPool.execute(Sql.named('SELECT id FROM accounts_user WHERE phone = @phone'), parameters: {'phone': phone});
    if (res.isNotEmpty) userId = res[0][0] as int;
  }

  // Mock OTP challenge: code 123456 (or randomized, let's randomize)
  final code = (100000 + (DateTime.now().microsecondsSinceEpoch % 900000)).toString();
  print('========================');
  print('OTP SEND REQUESTED FOR: $phone');
  print('CODE GENERATED: $code');
  print('========================');

  final codeHash = hashPassword(code, iterations: 100000);
  final expiresAt = DateTime.now().add(const Duration(minutes: 10));

  final res = await dbPool.execute(
    Sql.named('INSERT INTO accounts_phone_otp_challenge (phone, email, purpose, code_hash, attempts, expires_at, metadata, created_at, user_id) '
              'VALUES (@phone, @email, @purpose, @codeHash, @attempts, @expiresAt, @metadata, @now, @userId) RETURNING id'),
    parameters: {
      'phone': phone,
      'email': email ?? '',
      'purpose': purpose,
      'codeHash': codeHash,
      'attempts': 0,
      'expiresAt': expiresAt,
      'metadata': jsonEncode({'requested_from': 'api'}),
      'now': DateTime.now(),
      'userId': userId,
    },
  );

  return jsonResponse({
    'message': 'OTP sent',
    'challenge_id': res[0][0],
    'expires_at': expiresAt.toIso8601String(),
  });
}

Future<Response> verifyOtpHandler(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final challengeIdVal = body['challenge_id'];
  final code = body['code']?.toString().trim();

  if (challengeIdVal == null || code == null || code.isEmpty) {
    return errorResponse('challenge_id and code are required', statusCode: 400);
  }

  final challengeId = int.tryParse(challengeIdVal.toString()) ?? 0;
  final results = await dbPool.execute(
    Sql.named('SELECT * FROM accounts_phone_otp_challenge WHERE id = @id'),
    parameters: {'id': challengeId},
  );

  if (results.isEmpty) {
    return errorResponse('OTP challenge not found', statusCode: 404);
  }

  final challenge = results[0].toColumnMap();
  if (challenge['verified_at'] != null) {
    return errorResponse('OTP already verified', statusCode: 400);
  }

  final expiresAt = challenge['expires_at'] as DateTime;
  if (expiresAt.isBefore(DateTime.now())) {
    return errorResponse('OTP expired', statusCode: 400);
  }

  final attempts = (challenge['attempts'] as int? ?? 0);
  if (attempts >= 5) {
    return errorResponse('Too many failed attempts', statusCode: 429);
  }

  final codeHash = challenge['code_hash'] as String? ?? '';
  final isValid = verifyPassword(code, codeHash);

  await dbPool.execute(
    Sql.named('UPDATE accounts_phone_otp_challenge SET attempts = attempts + 1 WHERE id = @id'),
    parameters: {'id': challengeId},
  );

  if (!isValid) {
    return errorResponse('Invalid OTP', statusCode: 400);
  }

  // Update verified_at
  final now = DateTime.now();
  await dbPool.execute(
    Sql.named('UPDATE accounts_phone_otp_challenge SET verified_at = @now WHERE id = @id'),
    parameters: {'now': now, 'id': challengeId},
  );

  final userId = challenge['user_id'] as int?;
  final responseData = <String, dynamic>{
    'message': 'OTP verified',
    'verified': true,
    'purpose': challenge['purpose'],
  };

  if (userId != null) {
    final userQuery = await dbPool.execute(
      Sql.named('SELECT * FROM accounts_user WHERE id = @id'),
      parameters: {'id': userId},
    );
    if (userQuery.isNotEmpty) {
      final user = userQuery[0].toColumnMap();
      final role = user['role'] ?? 'CLIENT';
      final email = user['email'] ?? '';

      // Verify user in db if not verified
      if (!(user['is_verified'] as bool? ?? false)) {
        await dbPool.execute(
          Sql.named('UPDATE accounts_user SET is_verified = true WHERE id = @id'),
          parameters: {'id': userId},
        );
      }

      await createAuditLog(
        actorId: userId,
        action: 'phone_verified',
        entityType: 'user',
        entityId: userId.toString(),
        summary: email,
        metadata: {'challenge_id': challengeId, 'purpose': challenge['purpose']},
        ipAddress: null,
      );

      final accessPayload = {
        'user_id': userId,
        'role': role,
        'email': email,
        'token_type': 'access',
        'exp': (now.millisecondsSinceEpoch ~/ 1000) + 15 * 60,
      };
      final refreshPayload = {
        'user_id': userId,
        'role': role,
        'email': email,
        'token_type': 'refresh',
        'exp': (now.millisecondsSinceEpoch ~/ 1000) + 7 * 24 * 60 * 60,
      };

      responseData['access'] = generateJwt(payload: accessPayload, secret: secretKey);
      responseData['refresh'] = generateJwt(payload: refreshPayload, secret: secretKey);
      responseData['role'] = role;
    }
  }

  return jsonResponse(responseData);
}

Future<Response> registerClientHandler(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final email = body['email']?.toString().trim();
  final password = body['password']?.toString();
  final firstName = body['first_name']?.toString().trim() ?? '';
  final lastName = body['last_name']?.toString().trim() ?? '';
  final phone = body['phone']?.toString().trim() ?? '';

  if (email == null || email.isEmpty || password == null || password.isEmpty) {
    return errorResponse('Email and password are required', statusCode: 400);
  }

  final exists = await dbPool.execute(Sql.named('SELECT id FROM accounts_user WHERE email = @email'), parameters: {'email': email});
  if (exists.isNotEmpty) {
    return errorResponse('A user with this email already exists.', statusCode: 400);
  }

  final pwdHash = hashPassword(password);
  final now = DateTime.now();

  final res = await dbPool.execute(
    Sql.named('INSERT INTO accounts_user (username, password, is_superuser, first_name, last_name, email, is_staff, is_active, date_joined, role, phone, avatar_url, is_verified, language_preference, country, created_at, updated_at) '
              'VALUES (@email, @pwdHash, false, @first, @last, @email, false, true, @now, \'CLIENT\', @phone, \'\', false, \'en\', \'\', @now, @now) RETURNING id'),
    parameters: {
      'email': email,
      'pwdHash': pwdHash,
      'first': firstName,
      'last': lastName,
      'phone': phone,
      'now': now,
    },
  );
  final newId = res[0][0] as int;

  // Insert wallet
  await dbPool.execute(
    Sql.named('INSERT INTO wallet_wallet (available_balance, pending_escrow, total_earnings, total_withdrawn, currency, created_at, updated_at, user_id) '
              'VALUES (0, 0, 0, 0, \'XOF\', @now, @now, @userId)'),
    parameters: {'now': now, 'userId': newId},
  );

  await createAuditLog(
    actorId: newId,
    action: 'user_registered',
    entityType: 'user',
    entityId: newId.toString(),
    summary: 'Client registration',
    metadata: {'role': 'CLIENT'},
    ipAddress: null,
  );

  return Response(201, body: jsonEncode({'message': 'Client registered successfully.'}), headers: {'content-type': 'application/json'});
}

Future<Response> registerTechnicianHandler(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final email = body['email']?.toString().trim();
  final password = body['password']?.toString();
  final firstName = body['first_name']?.toString().trim() ?? '';
  final lastName = body['last_name']?.toString().trim() ?? '';
  final phone = body['phone']?.toString().trim() ?? '';

  if (email == null || email.isEmpty || password == null || password.isEmpty) {
    return errorResponse('Email and password are required', statusCode: 400);
  }

  final exists = await dbPool.execute(Sql.named('SELECT id FROM accounts_user WHERE email = @email'), parameters: {'email': email});
  if (exists.isNotEmpty) {
    return errorResponse('A user with this email already exists.', statusCode: 400);
  }

  final pwdHash = hashPassword(password);
  final now = DateTime.now();

  final res = await dbPool.execute(
    Sql.named('INSERT INTO accounts_user (username, password, is_superuser, first_name, last_name, email, is_staff, is_active, date_joined, role, phone, avatar_url, is_verified, language_preference, country, created_at, updated_at) '
              'VALUES (@email, @pwdHash, false, @first, @last, @email, false, true, @now, \'TECHNICIAN\', @phone, \'\', false, \'en\', \'\', @now, @now) RETURNING id'),
    parameters: {
      'email': email,
      'pwdHash': pwdHash,
      'first': firstName,
      'last': lastName,
      'phone': phone,
      'now': now,
    },
  );
  final newId = res[0][0] as int;

  // Insert technician profile
  await dbPool.execute(
    Sql.named('INSERT INTO accounts_technician_profile (bio, phone_number, hourly_rate, languages, portfolio, background_check_status, is_verified, availability_status, completed_jobs, average_rating, response_time, user_id) '
              'VALUES (\'\', @phone, 0.00, \'[]\'::jsonb, \'[]\'::jsonb, \'pending\', false, \'available\', 0, 0.00, \'\', @userId)'),
    parameters: {'phone': phone, 'userId': newId},
  );

  // Insert wallet
  await dbPool.execute(
    Sql.named('INSERT INTO wallet_wallet (available_balance, pending_escrow, total_earnings, total_withdrawn, currency, created_at, updated_at, user_id) '
              'VALUES (0, 0, 0, 0, \'XOF\', @now, @now, @userId)'),
    parameters: {'now': now, 'userId': newId},
  );

  await createAuditLog(
    actorId: newId,
    action: 'user_registered',
    entityType: 'user',
    entityId: newId.toString(),
    summary: 'Technician registration',
    metadata: {'role': 'TECHNICIAN'},
    ipAddress: null,
  );

  return Response(201, body: jsonEncode({'message': 'Technician registered successfully. Awaiting verification.'}), headers: {'content-type': 'application/json'});
}

Future<Response> registerCompanyHandler(Request request) async {
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final email = body['email']?.toString().trim();
  final password = body['password']?.toString();
  final companyName = body['company_name']?.toString().trim() ?? '';
  final phone = body['phone']?.toString().trim() ?? '';

  if (email == null || email.isEmpty || password == null || password.isEmpty || companyName.isEmpty) {
    return errorResponse('Email, password and company name are required', statusCode: 400);
  }

  final exists = await dbPool.execute(Sql.named('SELECT id FROM accounts_user WHERE email = @email'), parameters: {'email': email});
  if (exists.isNotEmpty) {
    return errorResponse('A user with this email already exists.', statusCode: 400);
  }

  final pwdHash = hashPassword(password);
  final now = DateTime.now();

  final res = await dbPool.execute(
    Sql.named('INSERT INTO accounts_user (username, password, is_superuser, first_name, last_name, email, is_staff, is_active, date_joined, role, phone, avatar_url, is_verified, language_preference, country, created_at, updated_at) '
              'VALUES (@email, @pwdHash, false, @first, \'\', @email, false, true, @now, \'COMPANY\', @phone, \'\', false, \'en\', \'\', @now, @now) RETURNING id'),
    parameters: {
      'email': email,
      'pwdHash': pwdHash,
      'first': companyName,
      'phone': phone,
      'now': now,
    },
  );
  final newId = res[0][0] as int;

  // Insert company profile
  await dbPool.execute(
    Sql.named('INSERT INTO companies_profile (company_name, registration_number, services_offered, company_size, logo_url, cover_url, about, website, headquarters, business_hours, is_verified, average_rating, review_count, team_size, completed_tasks, response_time, created_at, updated_at, user_id) '
              'VALUES (@companyName, \'\', \'[]\'::jsonb, \'\', \'\', \'\', \'\', \'\', \'\', \'[]\'::jsonb, false, 0.00, 0, 0, 0, \'\', @now, @now, @userId)'),
    parameters: {'companyName': companyName, 'now': now, 'userId': newId},
  );

  // Insert wallet
  await dbPool.execute(
    Sql.named('INSERT INTO wallet_wallet (available_balance, pending_escrow, total_earnings, total_withdrawn, currency, created_at, updated_at, user_id) '
              'VALUES (0, 0, 0, 0, \'XOF\', @now, @now, @userId)'),
    parameters: {'now': now, 'userId': newId},
  );

  await createAuditLog(
    actorId: newId,
    action: 'user_registered',
    entityType: 'user',
    entityId: newId.toString(),
    summary: 'Company registration',
    metadata: {'role': 'COMPANY'},
    ipAddress: null,
  );

  return Response(201, body: jsonEncode({'message': 'Company registered successfully. Awaiting verification.'}), headers: {'content-type': 'application/json'});
}

Future<Response> getMeHandler(Request request) async {
  final userId = getUserId(request);
  final results = await dbPool.execute(Sql.named('SELECT * FROM accounts_user WHERE id = @id'), parameters: {'id': userId});
  if (results.isEmpty) {
    return errorResponse('User not found', statusCode: 404);
  }
  return jsonResponse(formatUserMe(results[0].toColumnMap()));
}

Future<Response> updateMeHandler(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

  // Filter keys allowed for User
  final allowedUserFields = ['first_name', 'last_name', 'phone', 'avatar_url', 'language_preference', 'country'];
  final userUpdates = <String, dynamic>{};
  for (final f in allowedUserFields) {
    if (body.containsKey(f)) userUpdates[f] = body[f];
  }

  if (userUpdates.isNotEmpty) {
    final queryParts = userUpdates.keys.map((k) => '$k = @$k').join(', ');
    final params = Map<String, dynamic>.from(userUpdates)..['id'] = userId;
    await dbPool.execute(
      Sql.named('UPDATE accounts_user SET $queryParts, updated_at = NOW() WHERE id = @id'),
      parameters: params,
    );
  }

  // Filter keys for technician profile
  final role = getUserRole(request);
  if (role == 'TECHNICIAN') {
    final allowedProfileFields = ['bio', 'hourly_rate', 'availability_status'];
    final profileUpdates = <String, dynamic>{};
    for (final f in allowedProfileFields) {
      if (body.containsKey(f)) {
        if (f == 'hourly_rate') {
          profileUpdates[f] = double.tryParse(body[f].toString()) ?? 0.0;
        } else {
          profileUpdates[f] = body[f];
        }
      }
    }

    if (profileUpdates.isNotEmpty) {
      final queryParts = profileUpdates.keys.map((k) => '$k = @$k').join(', ');
      final params = Map<String, dynamic>.from(profileUpdates)..['userId'] = userId;
      await dbPool.execute(
        Sql.named('UPDATE accounts_technician_profile SET $queryParts WHERE user_id = @userId'),
        parameters: params,
      );
    }
  }

  final updatedUser = await dbPool.execute(Sql.named('SELECT * FROM accounts_user WHERE id = @id'), parameters: {'id': userId});
  return jsonResponse(formatUserMe(updatedUser[0].toColumnMap()));
}

Future<Response> listUsersHandler(Request request) async {
  final params = request.url.queryParameters;
  final role = (params['role'] ?? '').toUpperCase();
  final limit = int.tryParse(params['limit'] ?? '12') ?? 12;

  var query = 'SELECT * FROM accounts_user WHERE is_active = true';
  final sqlParams = <String, dynamic>{'limit': limit > 50 ? 50 : limit};

  if (role.isNotEmpty && ['TECHNICIAN', 'CLIENT', 'COMPANY', 'ADMIN'].contains(role)) {
    query += ' AND role = @role';
    sqlParams['role'] = role;
  }
  query += ' ORDER BY created_at DESC LIMIT @limit';

  final results = await dbPool.execute(Sql.named(query), parameters: sqlParams);
  final List<Map<String, dynamic>> responseList = [];

  for (final row in results) {
    final u = row.toColumnMap();
    final item = formatUserPublic(u);

    if (u['role'] == 'TECHNICIAN') {
      final profileQuery = await dbPool.execute(
        Sql.named('SELECT * FROM accounts_technician_profile WHERE user_id = @id'),
        parameters: {'id': u['id']},
      );
      if (profileQuery.isNotEmpty) {
        final prof = profileQuery[0].toColumnMap();
        item['bio'] = prof['bio'] ?? '';
        item['hourly_rate'] = prof['hourly_rate']?.toString();
        item['completed_jobs'] = prof['completed_jobs'] ?? 0;
        item['average_rating'] = prof['average_rating']?.toString() ?? '0.00';
        item['availability_status'] = prof['availability_status'] ?? 'available';

        // skills
        final skillsQuery = await dbPool.execute(
          Sql.named('SELECT s.name FROM tasks_skill s JOIN accounts_technician_profile_skills ps ON s.id = ps.skill_id WHERE ps.technicianprofile_id = @profId'),
          parameters: {'profId': prof['id']},
        );
        item['skills'] = skillsQuery.map((r) => r[0]?.toString() ?? '').toList();
      }
    }
    responseList.add(item);
  }

  return jsonResponse(responseList);
}

Future<Response> userPublicProfileHandler(Request request, String userIdStr) async {
  final userId = int.tryParse(userIdStr) ?? 0;
  final userQuery = await dbPool.execute(Sql.named('SELECT * FROM accounts_user WHERE id = @id'), parameters: {'id': userId});

  if (userQuery.isEmpty) {
    return errorResponse('User not found', statusCode: 404);
  }

  final u = userQuery[0].toColumnMap();
  final data = formatUserPublic(u);

  if (u['role'] == 'TECHNICIAN') {
    final profileQuery = await dbPool.execute(
      Sql.named('SELECT * FROM accounts_technician_profile WHERE user_id = @id'),
      parameters: {'id': userId},
    );
    if (profileQuery.isNotEmpty) {
      final prof = profileQuery[0].toColumnMap();
      data['bio'] = prof['bio'] ?? '';
      data['hourly_rate'] = prof['hourly_rate']?.toString();
      data['languages'] = parseJsonField(prof['languages']) ?? [];
      data['completed_jobs'] = prof['completed_jobs'] ?? 0;
      data['average_rating'] = prof['average_rating']?.toString() ?? '0.00';
      data['availability_status'] = prof['availability_status'] ?? 'available';
      data['portfolio'] = parseJsonField(prof['portfolio']) ?? [];
      data['response_time'] = prof['response_time'] ?? '';

      final skillsQuery = await dbPool.execute(
        Sql.named('SELECT s.name FROM tasks_skill s JOIN accounts_technician_profile_skills ps ON s.id = ps.skill_id WHERE ps.technicianprofile_id = @profId'),
        parameters: {'profId': prof['id']},
      );
      data['skills'] = skillsQuery.map((r) => r[0]?.toString() ?? '').toList();
    }
  } else if (u['role'] == 'COMPANY') {
    final companyQuery = await dbPool.execute(
      Sql.named('SELECT * FROM companies_profile WHERE user_id = @id'),
      parameters: {'id': userId},
    );
    if (companyQuery.isNotEmpty) {
      final company = companyQuery[0].toColumnMap();
      data['company_name'] = company['company_name'] ?? '';
      data['registration_number'] = company['registration_number'] ?? '';
      data['services_offered'] = parseJsonField(company['services_offered']) ?? [];
      data['company_size'] = company['company_size'] ?? '';
      data['logo_url'] = company['logo_url'] ?? '';
      data['cover_url'] = company['cover_url'] ?? '';
      data['about'] = company['about'] ?? '';
      data['website'] = company['website'] ?? '';
      data['headquarters'] = company['headquarters'] ?? '';
      data['business_hours'] = parseJsonField(company['business_hours']) ?? [];
      data['average_rating'] = company['average_rating']?.toString() ?? '0.00';
      data['review_count'] = company['review_count'] ?? 0;
      data['team_size'] = company['team_size'] ?? 0;
      data['completed_tasks'] = company['completed_tasks'] ?? 0;
      data['response_time'] = company['response_time'] ?? '';
    }
  }

  return jsonResponse(data);
}

// ─── PORTFOLIO HANDLERS ───────────────────────────────────────────────────

Future<Response> listPortfolioItemsHandler(Request request) async {
  final userId = getUserId(request);
  final results = await dbPool.execute(
    Sql.named('SELECT * FROM accounts_portfolio_item WHERE user_id = @userId ORDER BY created_at DESC'),
    parameters: {'userId': userId},
  );

  return jsonResponse(results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'title': row['title'] ?? '',
      'description': row['description'] ?? '',
      'category': row['category'] ?? '',
      'image_url': row['image_url'] ?? '',
      'completed_date': row['completed_date']?.toString(),
      'project_value': row['project_value']?.toString(),
      'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
    };
  }).toList());
}

Future<Response> createPortfolioItemHandler(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

  final title = body['title']?.toString() ?? '';
  final description = body['description']?.toString() ?? '';
  final category = body['category']?.toString() ?? '';
  final imageUrl = body['image_url']?.toString() ?? '';
  final completedDateStr = body['completed_date']?.toString();
  final projectValueStr = body['project_value']?.toString();

  DateTime? completedDate;
  if (completedDateStr != null && completedDateStr.isNotEmpty) {
    completedDate = DateTime.tryParse(completedDateStr);
  }
  double? projectValue;
  if (projectValueStr != null && projectValueStr.isNotEmpty) {
    projectValue = double.tryParse(projectValueStr);
  }

  final res = await dbPool.execute(
    Sql.named('INSERT INTO accounts_portfolio_item (title, description, category, image_url, completed_date, project_value, created_at, user_id) '
              'VALUES (@title, @description, @category, @imageUrl, @completedDate, @projectValue, @now, @userId) RETURNING id'),
    parameters: {
      'title': title,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'completedDate': completedDate,
      'projectValue': projectValue,
      'now': DateTime.now(),
      'userId': userId,
    },
  );

  return Response(201, body: jsonEncode({
    'id': res[0][0],
    'title': title,
    'description': description,
    'category': category,
    'image_url': imageUrl,
    'completed_date': completedDateStr,
    'project_value': projectValueStr,
  }), headers: {'content-type': 'application/json'});
}

Future<Response> deletePortfolioItemHandler(Request request, String itemIdStr) async {
  final userId = getUserId(request);
  final itemId = int.tryParse(itemIdStr) ?? 0;

  final res = await dbPool.execute(
    Sql.named('DELETE FROM accounts_portfolio_item WHERE id = @id AND user_id = @userId'),
    parameters: {'id': itemId, 'userId': userId},
  );

  if (res.affectedRows == 0) {
    return errorResponse('Not found', statusCode: 404);
  }

  return Response(204);
}

// ─── SAVED PROFESSIONALS HANDLERS ──────────────────────────────────────────

Future<Response> listSavedProfessionalsHandler(Request request) async {
  final userId = getUserId(request);
  final results = await dbPool.execute(
    Sql.named('SELECT s.id, s.created_at, u.* FROM accounts_saved_professional s JOIN accounts_user u ON s.professional_id = u.id WHERE s.user_id = @userId'),
    parameters: {'userId': userId},
  );

  final list = results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
      'professional': formatUserPublic(row),
    };
  }).toList();

  return jsonResponse(list);
}

Future<Response> createSavedProfessionalHandler(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final professionalIdVal = body['professional_id'];

  if (professionalIdVal == null) {
    return errorResponse('professional_id is required', statusCode: 400);
  }

  final professionalId = int.tryParse(professionalIdVal.toString()) ?? 0;
  final check = await dbPool.execute(
    Sql.named('SELECT id FROM accounts_user WHERE id = @id AND role IN (\'TECHNICIAN\', \'COMPANY\')'),
    parameters: {'id': professionalId},
  );

  if (check.isEmpty) {
    return errorResponse('Professional not found', statusCode: 404);
  }

  final existing = await dbPool.execute(
    Sql.named('SELECT id FROM accounts_saved_professional WHERE user_id = @userId AND professional_id = @profId'),
    parameters: {'userId': userId, 'profId': professionalId},
  );

  if (existing.isNotEmpty) {
    return jsonResponse({'message': 'Already saved'});
  }

  await dbPool.execute(
    Sql.named('INSERT INTO accounts_saved_professional (created_at, professional_id, user_id) VALUES (@now, @profId, @userId)'),
    parameters: {'now': DateTime.now(), 'profId': professionalId, 'userId': userId},
  );

  return Response(201, body: jsonEncode({'message': 'Saved successfully'}), headers: {'content-type': 'application/json'});
}

Future<Response> deleteSavedProfessionalHandler(Request request, String professionalIdStr) async {
  final userId = getUserId(request);
  final professionalId = int.tryParse(professionalIdStr) ?? 0;

  final res = await dbPool.execute(
    Sql.named('DELETE FROM accounts_saved_professional WHERE user_id = @userId AND professional_id = @profId'),
    parameters: {'userId': userId, 'profId': professionalId},
  );

  if (res.affectedRows == 0) {
    return errorResponse('Not found', statusCode: 404);
  }

  return Response(204);
}

// ─── TECHNICIAN SERVICES HANDLERS ──────────────────────────────────────────

Future<Response> listTechnicianServicesHandler(Request request) async {
  final userId = getUserId(request);
  final role = getUserRole(request);

  if (role != 'TECHNICIAN') {
    return errorResponse('Technician only', statusCode: 403);
  }

  final results = await dbPool.execute(
    Sql.named('SELECT ts.*, c.name as category_name FROM accounts_technician_service ts LEFT JOIN tasks_category c ON ts.category_id = c.id WHERE ts.technician_id = @techId ORDER BY ts.created_at DESC'),
    parameters: {'techId': userId},
  );

  return jsonResponse(results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'title': row['title'] ?? '',
      'category': row['category_id'],
      'category_name': row['category_name'] ?? '',
      'description': row['description'] ?? '',
      'service_type': row['service_type'] ?? 'onsite',
      'coverage_area': row['coverage_area'] ?? '',
      'pricing_model': row['pricing_model'] ?? 'fixed',
      'pricing_min': row['pricing_min']?.toString(),
      'pricing_max': row['pricing_max']?.toString(),
      'is_active': row['is_active'] ?? true,
      'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
      'updated_at': row['updated_at'] != null ? (row['updated_at'] as DateTime).toIso8601String() : '',
    };
  }).toList());
}

Future<Response> createTechnicianServiceHandler(Request request) async {
  final userId = getUserId(request);
  final role = getUserRole(request);

  if (role != 'TECHNICIAN') {
    return errorResponse('Technician only', statusCode: 403);
  }

  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final title = body['title']?.toString() ?? '';
  final categoryId = int.tryParse(body['category']?.toString() ?? '') ?? 0;
  final description = body['description']?.toString() ?? '';
  final serviceType = body['service_type']?.toString() ?? 'onsite';
  final coverageArea = body['coverage_area']?.toString() ?? '';
  final pricingModel = body['pricing_model']?.toString() ?? 'fixed';
  final pricingMin = double.tryParse(body['pricing_min']?.toString() ?? '');
  final pricingMax = double.tryParse(body['pricing_max']?.toString() ?? '');
  final isActive = body['is_active'] as bool? ?? true;

  final res = await dbPool.execute(
    Sql.named('INSERT INTO accounts_technician_service (title, description, service_type, coverage_area, pricing_model, pricing_min, pricing_max, is_active, created_at, updated_at, category_id, technician_id) '
              'VALUES (@title, @desc, @type, @area, @model, @min, @max, @active, @now, @now, @catId, @techId) RETURNING id'),
    parameters: {
      'title': title,
      'desc': description,
      'type': serviceType,
      'area': coverageArea,
      'model': pricingModel,
      'min': pricingMin,
      'max': pricingMax,
      'active': isActive,
      'now': DateTime.now(),
      'catId': categoryId > 0 ? categoryId : null,
      'techId': userId,
    },
  );
  final newId = res[0][0] as int;

  await createAuditLog(
    actorId: userId,
    action: 'technician_service_created',
    entityType: 'technician_service',
    entityId: newId.toString(),
    summary: title,
    metadata: {'service_type': serviceType, 'pricing_model': pricingModel},
    ipAddress: null,
  );

  return Response(201, body: jsonEncode({
    'id': newId,
    'title': title,
    'category': categoryId,
    'description': description,
    'service_type': serviceType,
    'coverage_area': coverageArea,
    'pricing_model': pricingModel,
    'pricing_min': pricingMin?.toString(),
    'pricing_max': pricingMax?.toString(),
    'is_active': isActive,
  }), headers: {'content-type': 'application/json'});
}

Future<Response> technicianServiceDetailHandler(Request request, String serviceIdStr) async {
  final userId = getUserId(request);
  final serviceId = int.tryParse(serviceIdStr) ?? 0;

  final results = await dbPool.execute(
    Sql.named('SELECT ts.*, c.name as category_name FROM accounts_technician_service ts LEFT JOIN tasks_category c ON ts.category_id = c.id WHERE ts.id = @id AND ts.technician_id = @techId'),
    parameters: {'id': serviceId, 'techId': userId},
  );

  if (results.isEmpty) {
    return errorResponse('Service not found', statusCode: 404);
  }

  final row = results[0].toColumnMap();

  if (request.method == 'GET') {
    return jsonResponse({
      'id': row['id'],
      'title': row['title'] ?? '',
      'category': row['category_id'],
      'category_name': row['category_name'] ?? '',
      'description': row['description'] ?? '',
      'service_type': row['service_type'] ?? 'onsite',
      'coverage_area': row['coverage_area'] ?? '',
      'pricing_model': row['pricing_model'] ?? 'fixed',
      'pricing_min': row['pricing_min']?.toString(),
      'pricing_max': row['pricing_max']?.toString(),
      'is_active': row['is_active'] ?? true,
      'created_at': row['created_at']?.toString(),
    });
  } else if (request.method == 'DELETE') {
    await dbPool.execute(Sql.named('DELETE FROM accounts_technician_service WHERE id = @id'), parameters: {'id': serviceId});
    return Response(204);
  } else if (request.method == 'PATCH') {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

    final allowed = ['title', 'category_id', 'description', 'service_type', 'coverage_area', 'pricing_model', 'pricing_min', 'pricing_max', 'is_active'];
    final updates = <String, dynamic>{};
    for (final f in allowed) {
      if (body.containsKey(f)) updates[f] = body[f];
      // Special handle category naming differences
      if (f == 'category_id' && body.containsKey('category')) {
        updates['category_id'] = int.tryParse(body['category']?.toString() ?? '');
      }
    }

    if (updates.isNotEmpty) {
      final queryParts = updates.keys.map((k) => '$k = @$k').join(', ');
      final params = Map<String, dynamic>.from(updates)..['id'] = serviceId;
      await dbPool.execute(
        Sql.named('UPDATE accounts_technician_service SET $queryParts, updated_at = NOW() WHERE id = @id'),
        parameters: params,
      );
    }

    await createAuditLog(
      actorId: userId,
      action: 'technician_service_updated',
      entityType: 'technician_service',
      entityId: serviceId.toString(),
      summary: row['title'] ?? '',
      metadata: {'service_type': row['service_type'], 'pricing_model': row['pricing_model']},
      ipAddress: null,
    );

    final updated = await dbPool.execute(
      Sql.named('SELECT ts.*, c.name as category_name FROM accounts_technician_service ts LEFT JOIN tasks_category c ON ts.category_id = c.id WHERE ts.id = @id'),
      parameters: {'id': serviceId},
    );
    final row2 = updated[0].toColumnMap();

    return jsonResponse({
      'id': row2['id'],
      'title': row2['title'] ?? '',
      'category': row2['category_id'],
      'category_name': row2['category_name'] ?? '',
      'description': row2['description'] ?? '',
      'service_type': row2['service_type'] ?? 'onsite',
      'coverage_area': row2['coverage_area'] ?? '',
      'pricing_model': row2['pricing_model'] ?? 'fixed',
      'pricing_min': row2['pricing_min']?.toString(),
      'pricing_max': row2['pricing_max']?.toString(),
      'is_active': row2['is_active'] ?? true,
    });
  }

  return errorResponse('Method not allowed', statusCode: 405);
}

// ─── ADMIN USERS HANDLERS ─────────────────────────────────────────────────

Future<Response> adminListUsersHandler(Request request) async {
  final role = getUserRole(request);
  if (role != 'ADMIN') {
    return errorResponse('Admin only', statusCode: 403);
  }

  final params = request.url.queryParameters;
  final roleFilter = (params['role'] ?? '').toUpperCase();
  final verifiedFilter = params['verified'];

  var query = 'SELECT * FROM accounts_user';
  final clauses = <String>[];
  final sqlParams = <String, dynamic>{};

  if (roleFilter.isNotEmpty && ['TECHNICIAN', 'CLIENT', 'COMPANY', 'ADMIN'].contains(roleFilter)) {
    clauses.add('role = @role');
    sqlParams['role'] = roleFilter;
  }
  if (verifiedFilter == 'true') {
    clauses.add('is_verified = true');
  } else if (verifiedFilter == 'false') {
    clauses.add('is_verified = false');
  }

  if (clauses.isNotEmpty) {
    query += ' WHERE ' + clauses.join(' AND ');
  }
  query += ' ORDER BY created_at DESC';

  final results = await dbPool.execute(Sql.named(query), parameters: sqlParams);
  final list = results.map((row) => formatUserMe(row.toColumnMap())).toList();
  return jsonResponse(list);
}

Future<Response> adminVerifyUserHandler(Request request, String userIdStr) async {
  final role = getUserRole(request);
  if (role != 'ADMIN') {
    return errorResponse('Admin only', statusCode: 403);
  }

  final targetUserId = int.tryParse(userIdStr) ?? 0;
  final results = await dbPool.execute(
    Sql.named('SELECT * FROM accounts_user WHERE id = @id'),
    parameters: {'id': targetUserId},
  );

  if (results.isEmpty) {
    return errorResponse('User not found', statusCode: 404);
  }

  await dbPool.execute(
    Sql.named('UPDATE accounts_user SET is_verified = true WHERE id = @id'),
    parameters: {'id': targetUserId},
  );

  final user = results[0].toColumnMap();

  await createAuditLog(
    actorId: getUserId(request),
    action: 'user_verified',
    entityType: 'user',
    entityId: targetUserId.toString(),
    summary: user['email'] ?? '',
    metadata: {'verified': true},
    ipAddress: null,
  );

  await createNotification(
    userId: targetUserId,
    category: 'verification',
    title: 'Account verified',
    body: 'Your account has been verified by the admin team.',
    link: '/dashboard/client',
    metadata: {'user_id': targetUserId},
  );

  return jsonResponse({'message': '${user['email']} verified', 'is_verified': true});
}

Future<Response> adminSuspendUserHandler(Request request, String userIdStr) async {
  final role = getUserRole(request);
  if (role != 'ADMIN') {
    return errorResponse('Admin only', statusCode: 403);
  }

  final targetUserId = int.tryParse(userIdStr) ?? 0;
  final results = await dbPool.execute(
    Sql.named('SELECT * FROM accounts_user WHERE id = @id'),
    parameters: {'id': targetUserId},
  );

  if (results.isEmpty) {
    return errorResponse('User not found', statusCode: 404);
  }

  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final action = body['action']?.toString() ?? 'suspend';
  final user = results[0].toColumnMap();

  if (action == 'unsuspend') {
    await dbPool.execute(
      Sql.named('UPDATE accounts_user SET is_active = true WHERE id = @id'),
      parameters: {'id': targetUserId},
    );
    await createAuditLog(
      actorId: getUserId(request),
      action: 'user_unsuspended',
      entityType: 'user',
      entityId: targetUserId.toString(),
      summary: user['email'] ?? '',
      metadata: {'is_active': true},
      ipAddress: null,
    );
    await createNotification(
      userId: targetUserId,
      category: 'system',
      title: 'Account reactivated',
      body: 'Your account has been reactivated.',
      link: '/login',
      metadata: {'user_id': targetUserId},
    );
    return jsonResponse({'message': '${user['email']} reactivated', 'is_active': true});
  } else {
    await dbPool.execute(
      Sql.named('UPDATE accounts_user SET is_active = false WHERE id = @id'),
      parameters: {'id': targetUserId},
    );
    await createAuditLog(
      actorId: getUserId(request),
      action: 'user_suspended',
      entityType: 'user',
      entityId: targetUserId.toString(),
      summary: user['email'] ?? '',
      metadata: {'is_active': false},
      ipAddress: null,
    );
    await createNotification(
      userId: targetUserId,
      category: 'system',
      title: 'Account suspended',
      body: 'Your account has been suspended by the admin team.',
      link: '/login',
      metadata: {'user_id': targetUserId},
    );
    return jsonResponse({'message': '${user['email']} suspended', 'is_active': false});
  }
}

// ─── ADMIN TASKS CONTROLLERS ──────────────────────────────────────────────

Future<Response> adminListTasksHandler(Request request) async {
  final role = getUserRole(request);
  if (role != 'ADMIN') {
    return errorResponse('Admin only', statusCode: 403);
  }

  final params = request.url.queryParameters;
  final statusFilter = params['status'];

  var query = 'SELECT t.*, c.name as category_name, c.slug as category_slug, cl.email as client_email, cl.first_name as client_first_name, cl.last_name as client_last_name, cl.avatar_url as client_avatar, cl.role as client_role, cl.is_verified as client_is_verified, ast.email as assigned_email, ast.first_name as assigned_first_name, ast.last_name as assigned_last_name, ast.avatar_url as assigned_avatar, ast.role as assigned_role, ast.is_verified as assigned_is_verified FROM tasks_task t LEFT JOIN tasks_category c ON t.category_id = c.id LEFT JOIN accounts_user cl ON t.client_id = cl.id LEFT JOIN accounts_user ast ON t.assigned_to_id = ast.id';
  final sqlParams = <String, dynamic>{};

  if (statusFilter != null && statusFilter.isNotEmpty) {
    query += ' WHERE t.status = @status';
    sqlParams['status'] = statusFilter;
  }
  query += ' ORDER BY t.created_at DESC';

  final results = await dbPool.execute(Sql.named(query), parameters: sqlParams);
  final list = results.map((row) => formatJoinedTask(row.toColumnMap())).toList();
  return jsonResponse(list);
}

// ─── TASK CONTROLLERS ──────────────────────────────────────────────────────

Future<Response> listTasksHandler(Request request) async {
  final params = request.url.queryParameters;
  final category = params['category'];
  final city = params['city'];
  final budgetMin = double.tryParse(params['budget_min'] ?? '');
  final budgetMax = double.tryParse(params['budget_max'] ?? '');
  final urgency = params['urgency'];
  final search = params['q'];
  final sort = params['sort'] ?? '-created_at';
  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = int.tryParse(params['limit'] ?? '20') ?? 20;

  var query = 'SELECT t.*, c.name as category_name, c.slug as category_slug, cl.email as client_email, cl.first_name as client_first_name, cl.last_name as client_last_name, cl.avatar_url as client_avatar, cl.role as client_role, cl.is_verified as client_is_verified, ast.email as assigned_email, ast.first_name as assigned_first_name, ast.last_name as assigned_last_name, ast.avatar_url as assigned_avatar, ast.role as assigned_role, ast.is_verified as assigned_is_verified FROM tasks_task t LEFT JOIN tasks_category c ON t.category_id = c.id LEFT JOIN accounts_user cl ON t.client_id = cl.id LEFT JOIN accounts_user ast ON t.assigned_to_id = ast.id WHERE t.status = \'open\'';

  final clauses = <String>[];
  final sqlParams = <String, dynamic>{};

  if (category != null && category.isNotEmpty) {
    clauses.add('c.slug = @category');
    sqlParams['category'] = category;
  }
  if (city != null && city.isNotEmpty) {
    clauses.add('t.city ILIKE @city');
    sqlParams['city'] = '%$city%';
  }
  if (budgetMin != null) {
    clauses.add('t.budget_max >= @budgetMin');
    sqlParams['budgetMin'] = budgetMin;
  }
  if (budgetMax != null) {
    clauses.add('t.budget_min <= @budgetMax');
    sqlParams['budgetMax'] = budgetMax;
  }
  if (urgency != null && urgency.isNotEmpty) {
    clauses.add('t.urgency = @urgency');
    sqlParams['urgency'] = urgency;
  }
  if (search != null && search.isNotEmpty) {
    clauses.add('(t.title ILIKE @search OR t.description ILIKE @search)');
    sqlParams['search'] = '%$search%';
  }

  if (clauses.isNotEmpty) {
    query += ' AND ' + clauses.join(' AND ');
  }

  // Sorting
  if (sort == 'budget_high') {
    query += ' ORDER BY t.budget_max DESC, t.created_at DESC';
  } else if (sort == 'budget_low') {
    query += ' ORDER BY t.budget_min ASC, t.created_at DESC';
  } else {
    query += ' ORDER BY t.created_at DESC';
  }

  // Pagination
  final start = (page - 1) * limit;
  query += ' LIMIT @limit OFFSET @offset';
  sqlParams['limit'] = limit;
  sqlParams['offset'] = start;

  // Execute
  final results = await dbPool.execute(Sql.named(query), parameters: sqlParams);
  final list = results.map((row) => formatJoinedTask(row.toColumnMap())).toList();

  // Count total tasks (non-paginated)
  var countQuery = 'SELECT COUNT(*) FROM tasks_task t LEFT JOIN tasks_category c ON t.category_id = c.id WHERE t.status = \'open\'';
  if (clauses.isNotEmpty) {
    countQuery += ' AND ' + clauses.join(' AND ');
  }
  final countParams = Map<String, dynamic>.from(sqlParams)..remove('limit')..remove('offset');
  final countRes = await dbPool.execute(Sql.named(countQuery), parameters: countParams);
  final total = countRes[0][0] as int;

  return jsonResponse({
    'results': list,
    'total': total,
    'page': page,
    'limit': limit,
    'total_pages': (total + limit - 1) ~/ limit,
  });
}

Future<Response> createTaskHandler(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

  final title = body['title']?.toString() ?? '';
  final description = body['description']?.toString() ?? '';
  final categoryId = int.tryParse(body['category_id']?.toString() ?? '') ?? int.tryParse(body['category']?.toString() ?? '') ?? 0;
  final budgetMin = double.tryParse(body['budget_min']?.toString() ?? '');
  final budgetMax = double.tryParse(body['budget_max']?.toString() ?? '');
  final budgetMode = body['budget_mode']?.toString() ?? 'fixed';
  final urgency = body['urgency']?.toString() ?? 'standard';
  final serviceType = body['service_type']?.toString() ?? 'onsite';
  final location = body['location']?.toString() ?? '';
  final city = body['city']?.toString() ?? '';
  final schedule = body['schedule']?.toString() ?? '';
  final deadlineStr = body['deadline']?.toString();
  final materialsProvided = body['materials_provided'] as bool? ?? false;
  final contactMethods = body['contact_methods'] ?? [];

  DateTime? deadline;
  if (deadlineStr != null && deadlineStr.isNotEmpty) {
    deadline = DateTime.tryParse(deadlineStr);
  }

  final res = await dbPool.execute(
    Sql.named('INSERT INTO tasks_task (title, description, status, budget_min, budget_max, budget_mode, urgency, service_type, location, city, latitude, longitude, schedule, deadline, materials_provided, contact_methods, views_count, bids_count, created_at, updated_at, category_id, client_id) '
              'VALUES (@title, @desc, \'draft\', @bMin, @bMax, @bMode, @urgency, @type, @loc, @city, null, null, @sched, @deadline, @materials, @contact, 0, 0, @now, @now, @catId, @clientId) RETURNING id'),
    parameters: {
      'title': title,
      'desc': description,
      'bMin': budgetMin,
      'bMax': budgetMax,
      'bMode': budgetMode,
      'urgency': urgency,
      'type': serviceType,
      'loc': location,
      'city': city,
      'sched': schedule,
      'deadline': deadline,
      'materials': materialsProvided,
      'contact': jsonEncode(contactMethods),
      'now': DateTime.now(),
      'catId': categoryId > 0 ? categoryId : null,
      'clientId': userId,
    },
  );
  final newTaskId = res[0][0] as int;

  // Insert skills if provided
  final skillsList = body['skills'] as List? ?? [];
  for (final sk in skillsList) {
    int? skId = int.tryParse(sk.toString());
    if (skId == null) {
      final skSearch = await dbPool.execute(Sql.named('SELECT id FROM tasks_skill WHERE name ILIKE @name'), parameters: {'name': sk.toString()});
      if (skSearch.isNotEmpty) {
        skId = skSearch[0][0] as int;
      }
    }
    if (skId != null) {
      await dbPool.execute(
        Sql.named('INSERT INTO tasks_task_skills (task_id, skill_id) VALUES (@taskId, @skId)'),
        parameters: {'taskId': newTaskId, 'skId': skId},
      );
    }
  }

  final taskQuery = await dbPool.execute(
    Sql.named('SELECT t.*, c.name as category_name, c.slug as category_slug, cl.email as client_email, cl.first_name as client_first_name, cl.last_name as client_last_name, cl.avatar_url as client_avatar, cl.role as client_role, cl.is_verified as client_is_verified FROM tasks_task t LEFT JOIN tasks_category c ON t.category_id = c.id LEFT JOIN accounts_user cl ON t.client_id = cl.id WHERE t.id = @id'),
    parameters: {'id': newTaskId},
  );

  return Response(201, body: jsonEncode(formatJoinedTask(taskQuery[0].toColumnMap())), headers: {'content-type': 'application/json'});
}

Future<Response> myTasksHandler(Request request) async {
  final userId = getUserId(request);
  final role = getUserRole(request);
  final params = request.url.queryParameters;
  final statusFilter = params['status'];

  var query = 'SELECT t.*, c.name as category_name, c.slug as category_slug, cl.email as client_email, cl.first_name as client_first_name, cl.last_name as client_last_name, cl.avatar_url as client_avatar, cl.role as client_role, cl.is_verified as client_is_verified, ast.email as assigned_email, ast.first_name as assigned_first_name, ast.last_name as assigned_last_name, ast.avatar_url as assigned_avatar, ast.role as assigned_role, ast.is_verified as assigned_is_verified FROM tasks_task t LEFT JOIN tasks_category c ON t.category_id = c.id LEFT JOIN accounts_user cl ON t.client_id = cl.id LEFT JOIN accounts_user ast ON t.assigned_to_id = ast.id';
  final sqlParams = <String, dynamic>{'userId': userId};

  if (role == 'TECHNICIAN' || role == 'COMPANY') {
    query += ' WHERE t.assigned_to_id = @userId';
  } else {
    query += ' WHERE t.client_id = @userId';
  }

  if (statusFilter != null && statusFilter.isNotEmpty) {
    query += ' AND t.status = @status';
    sqlParams['status'] = statusFilter;
  }
  query += ' ORDER BY t.created_at DESC';

  final results = await dbPool.execute(Sql.named(query), parameters: sqlParams);
  final list = results.map((row) => formatJoinedTask(row.toColumnMap())).toList();
  return jsonResponse(list);
}

Future<Response> categoryListHandler(Request request) async {
  final results = await dbPool.execute('SELECT * FROM tasks_category ORDER BY "order" ASC, name ASC');
  final list = results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'name': row['name'] ?? '',
      'slug': row['slug'] ?? '',
      'icon': row['icon'] ?? '',
      'description': row['description'] ?? '',
      'is_active': row['is_active'] ?? true,
      'order': row['order'] ?? 0,
      'parent': row['parent_id'],
    };
  }).toList();
  return jsonResponse(list);
}

Future<Response> skillListHandler(Request request) async {
  final results = await dbPool.execute('SELECT * FROM tasks_skill ORDER BY name ASC');
  final list = results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'name': row['name'] ?? '',
      'slug': row['slug'] ?? '',
      'category': row['category_id'],
    };
  }).toList();
  return jsonResponse(list);
}

Future<Response> taskDetailHandler(Request request, String idStr) async {
  final id = int.tryParse(idStr) ?? 0;

  // Increment views
  await dbPool.execute(Sql.named('UPDATE tasks_task SET views_count = views_count + 1 WHERE id = @id'), parameters: {'id': id});

  final results = await dbPool.execute(
    Sql.named('SELECT t.*, c.name as category_name, c.slug as category_slug, cl.email as client_email, cl.first_name as client_first_name, cl.last_name as client_last_name, cl.avatar_url as client_avatar, cl.role as client_role, cl.is_verified as client_is_verified, ast.email as assigned_email, ast.first_name as assigned_first_name, ast.last_name as assigned_last_name, ast.avatar_url as assigned_avatar, ast.role as assigned_role, ast.is_verified as assigned_is_verified FROM tasks_task t LEFT JOIN tasks_category c ON t.category_id = c.id LEFT JOIN accounts_user cl ON t.client_id = cl.id LEFT JOIN accounts_user ast ON t.assigned_to_id = ast.id WHERE t.id = @id'),
    parameters: {'id': id},
  );

  if (results.isEmpty) {
    return errorResponse('Task not found', statusCode: 404);
  }

  final task = formatJoinedTask(results[0].toColumnMap());

  // fetch task skills
  final skills = await dbPool.execute(
    Sql.named('SELECT s.id, s.name, s.slug FROM tasks_skill s JOIN tasks_task_skills ts ON s.id = ts.skill_id WHERE ts.task_id = @id'),
    parameters: {'id': id},
  );
  task['skills'] = skills.map((r) => {'id': r[0], 'name': r[1], 'slug': r[2]}).toList();

  return jsonResponse(task);
}

Future<Response> taskPublishHandler(Request request, String idStr) async {
  final id = int.tryParse(idStr) ?? 0;
  final userId = getUserId(request);

  final taskRes = await dbPool.execute(Sql.named('SELECT client_id FROM tasks_task WHERE id = @id'), parameters: {'id': id});
  if (taskRes.isEmpty) return errorResponse('Task not found', statusCode: 404);
  if (taskRes[0][0] != userId) return errorResponse('Not authorized', statusCode: 403);

  await dbPool.execute(
    Sql.named('UPDATE tasks_task SET status = \'open\', published_at = NOW() WHERE id = @id'),
    parameters: {'id': id},
  );

  return jsonResponse({'message': 'Task published successfully', 'status': 'open'});
}

Future<Response> taskCompleteHandler(Request request, String idStr) async {
  final id = int.tryParse(idStr) ?? 0;
  final userId = getUserId(request);

  final taskRes = await dbPool.execute(Sql.named('SELECT client_id FROM tasks_task WHERE id = @id'), parameters: {'id': id});
  if (taskRes.isEmpty) return errorResponse('Task not found', statusCode: 404);
  if (taskRes[0][0] != userId) return errorResponse('Not authorized', statusCode: 403);

  await dbPool.execute(
    Sql.named('UPDATE tasks_task SET status = \'completed\' WHERE id = @id'),
    parameters: {'id': id},
  );

  return jsonResponse({'message': 'Task completed', 'status': 'completed'});
}

Future<Response> taskCancelHandler(Request request, String idStr) async {
  final id = int.tryParse(idStr) ?? 0;
  final userId = getUserId(request);

  final taskRes = await dbPool.execute(Sql.named('SELECT client_id FROM tasks_task WHERE id = @id'), parameters: {'id': id});
  if (taskRes.isEmpty) return errorResponse('Task not found', statusCode: 404);
  if (taskRes[0][0] != userId) return errorResponse('Not authorized', statusCode: 403);

  await dbPool.execute(
    Sql.named('UPDATE tasks_task SET status = \'cancelled\' WHERE id = @id'),
    parameters: {'id': id},
  );

  return jsonResponse({'message': 'Task cancelled', 'status': 'cancelled'});
}

// ─── BIDDING CONTROLLERS ───────────────────────────────────────────────────

Future<Response> taskBidsHandler(Request request, String idStr) async {
  final id = int.tryParse(idStr) ?? 0;

  if (request.method == 'GET') {
    final results = await dbPool.execute(
      Sql.named('SELECT b.*, u.id as tech_id, u.email as tech_email, u.first_name as tech_first_name, u.last_name as tech_last_name, u.avatar_url as tech_avatar, u.is_verified as tech_is_verified FROM tasks_bid b JOIN accounts_user u ON b.technician_id = u.id WHERE b.task_id = @id AND b.status != \'withdrawn\' ORDER BY b.created_at DESC'),
      parameters: {'id': id},
    );
    return jsonResponse(results.map((r) => formatBid(r.toColumnMap())).toList());
  } else if (request.method == 'POST') {
    final userId = getUserId(request);
    final role = getUserRole(request);

    if (role != 'TECHNICIAN') {
      return errorResponse('Only technicians can bid', statusCode: 403);
    }

    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final amount = double.tryParse(body['amount']?.toString() ?? '') ?? 0.0;
    final amountType = body['amount_type']?.toString() ?? 'fixed';
    final duration = body['duration']?.toString() ?? '';
    final message = body['message']?.toString() ?? '';
    final extraNotes = body['extra_notes']?.toString() ?? '';

    // Check unique active bid
    final existing = await dbPool.execute(
      Sql.named('SELECT id FROM tasks_bid WHERE task_id = @taskId AND technician_id = @techId AND status != \'withdrawn\''),
      parameters: {'taskId': id, 'techId': userId},
    );
    if (existing.isNotEmpty) {
      return errorResponse('You have already submitted a bid for this task.', statusCode: 400);
    }

    final res = await dbPool.execute(
      Sql.named('INSERT INTO tasks_bid (amount, amount_type, message, duration, extra_notes, status, created_at, updated_at, task_id, technician_id) '
                'VALUES (@amount, @type, @message, @duration, @extra, \'pending\', NOW(), NOW(), @taskId, @techId) RETURNING id'),
      parameters: {
        'amount': amount,
        'type': amountType,
        'message': message,
        'duration': duration,
        'extra': extraNotes,
        'taskId': id,
        'techId': userId,
      },
    );
    final newBidId = res[0][0] as int;

    // Increment bid count on task
    await dbPool.execute(Sql.named('UPDATE tasks_task SET bids_count = bids_count + 1 WHERE id = @id'), parameters: {'id': id});

    // Notify client
    final clientRes = await dbPool.execute(Sql.named('SELECT client_id, title FROM tasks_task WHERE id = @id'), parameters: {'id': id});
    if (clientRes.isNotEmpty) {
      await createNotification(
        userId: clientRes[0][0] as int,
        category: 'bid',
        title: 'New bid submitted',
        body: 'A technician submitted a bid on task: ${clientRes[0][1]}',
        link: '/dashboard/client/tasks/$id',
        metadata: {'task_id': id, 'bid_id': newBidId},
      );
    }

    return Response(201, body: jsonEncode({'id': newBidId, 'message': 'Bid submitted successfully', 'status': 'pending'}), headers: {'content-type': 'application/json'});
  }

  return errorResponse('Method not allowed', statusCode: 405);
}

Future<Response> myBidsHandler(Request request) async {
  final userId = getUserId(request);
  final results = await dbPool.execute(
    Sql.named('SELECT b.*, u.id as tech_id, u.email as tech_email, u.first_name as tech_first_name, u.last_name as tech_last_name, u.avatar_url as tech_avatar, u.is_verified as tech_is_verified FROM tasks_bid b JOIN accounts_user u ON b.technician_id = u.id WHERE b.technician_id = @userId ORDER BY b.created_at DESC'),
    parameters: {'userId': userId},
  );
  return jsonResponse(results.map((r) => formatBid(r.toColumnMap())).toList());
}

Future<Response> bidDetailHandler(Request request, String idStr) async {
  final id = int.tryParse(idStr) ?? 0;
  final results = await dbPool.execute(
    Sql.named('SELECT b.*, u.id as tech_id, u.email as tech_email, u.first_name as tech_first_name, u.last_name as tech_last_name, u.avatar_url as tech_avatar, u.is_verified as tech_is_verified FROM tasks_bid b JOIN accounts_user u ON b.technician_id = u.id WHERE b.id = @id'),
    parameters: {'id': id},
  );

  if (results.isEmpty) {
    return errorResponse('Bid not found', statusCode: 404);
  }

  return jsonResponse(formatBid(results[0].toColumnMap()));
}

Future<Response> bidWithdrawHandler(Request request, String idStr) async {
  final id = int.tryParse(idStr) ?? 0;
  final userId = getUserId(request);

  final check = await dbPool.execute(Sql.named('SELECT technician_id, task_id FROM tasks_bid WHERE id = @id'), parameters: {'id': id});
  if (check.isEmpty) return errorResponse('Bid not found', statusCode: 404);
  if (check[0][0] != userId) return errorResponse('Not authorized', statusCode: 403);

  final taskId = check[0][1] as int;

  await dbPool.execute(
    Sql.named('UPDATE tasks_bid SET status = \'withdrawn\', updated_at = NOW() WHERE id = @id'),
    parameters: {'id': id},
  );

  // Decrement task bids_count
  await dbPool.execute(Sql.named('UPDATE tasks_task SET bids_count = GREATEST(0, bids_count - 1) WHERE id = @id'), parameters: {'id': taskId});

  return jsonResponse({'message': 'Bid withdrawn', 'status': 'withdrawn'});
}

// ─── WALLET & ESCROW CONTROLLERS ───────────────────────────────────────────

Future<Response> walletDetailHandler(Request request) async {
  final userId = getUserId(request);
  final results = await dbPool.execute(Sql.named('SELECT * FROM wallet_wallet WHERE user_id = @userId'), parameters: {'userId': userId});

  if (results.isEmpty) {
    // Create wallet
    final now = DateTime.now();
    final res = await dbPool.execute(
      Sql.named('INSERT INTO wallet_wallet (available_balance, pending_escrow, total_earnings, total_withdrawn, currency, created_at, updated_at, user_id) '
                'VALUES (0, 0, 0, 0, \'XOF\', @now, @now, @userId) RETURNING *'),
      parameters: {'now': now, 'userId': userId},
    );
    final w = res[0].toColumnMap();
    return jsonResponse({
      'id': w['id'],
      'available_balance': '0.00',
      'pending_escrow': '0.00',
      'total_earnings': '0.00',
      'total_withdrawn': '0.00',
      'currency': 'XOF',
    });
  }

  final w = results[0].toColumnMap();
  return jsonResponse({
    'id': w['id'],
    'available_balance': w['available_balance']?.toString() ?? '0.00',
    'pending_escrow': w['pending_escrow']?.toString() ?? '0.00',
    'total_earnings': w['total_earnings']?.toString() ?? '0.00',
    'total_withdrawn': w['total_withdrawn']?.toString() ?? '0.00',
    'currency': w['currency'] ?? 'XOF',
  });
}

Future<Response> listTransactionsHandler(Request request) async {
  final userId = getUserId(request);
  final walletRes = await dbPool.execute(Sql.named('SELECT id FROM wallet_wallet WHERE user_id = @userId'), parameters: {'userId': userId});
  if (walletRes.isEmpty) return jsonResponse({'results': [], 'total': 0});

  final walletId = walletRes[0][0] as int;
  final results = await dbPool.execute(
    Sql.named('SELECT * FROM wallet_transaction WHERE wallet_id = @walletId ORDER BY created_at DESC'),
    parameters: {'walletId': walletId},
  );

  final list = results.map((r) => formatTransaction(r.toColumnMap())).toList();
  return jsonResponse({
    'results': list,
    'total': list.length,
    'page': 1,
    'limit': list.length,
  });
}

Future<Response> adminTransactionListHandler(Request request) async {
  final role = getUserRole(request);
  if (role != 'ADMIN') return errorResponse('Admin only', statusCode: 403);

  final results = await dbPool.execute(
    'SELECT tx.*, u.email as user_email, u.first_name as user_first, u.last_name as user_last FROM wallet_transaction tx JOIN wallet_wallet w ON tx.wallet_id = w.id JOIN accounts_user u ON w.user_id = u.id ORDER BY tx.created_at DESC'
  );

  final totalInEscrowRes = await dbPool.execute('SELECT SUM(available_balance) FROM wallet_wallet');
  final totalInEscrow = totalInEscrowRes[0][0]?.toString() ?? '0.00';

  final pendingPayoutsRes = await dbPool.execute('SELECT COUNT(*) FROM wallet_transaction WHERE type = \'debit\' AND status = \'pending\'');
  final pendingPayouts = pendingPayoutsRes[0][0] as int;

  final data = results.map((r) {
    final row = r.toColumnMap();
    final name = (row['user_first']?.toString() ?? '') + ' ' + (row['user_last']?.toString() ?? '');
    return {
      'id': row['id'],
      'type': row['type'],
      'amount': row['amount']?.toString() ?? '0.00',
      'status': row['status'],
      'description': row['description'] ?? '',
      'user_name': name.trim().isEmpty ? row['user_email'] : name,
      'user_email': row['user_email'],
      'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
    };
  }).toList();

  return jsonResponse({
    'results': data,
    'total': data.length,
    'page': 1,
    'limit': data.length,
    'total_in_escrow': totalInEscrow,
    'pending_payouts': pendingPayouts,
  });
}

Future<Response> withdrawFundsHandler(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final amountVal = body['amount'];
  final method = body['account_details']?['method']?.toString() ?? 'Mobile Money';

  if (amountVal == null) return errorResponse('amount is required', statusCode: 400);
  final amount = double.tryParse(amountVal.toString()) ?? 0.0;

  final walletRes = await dbPool.execute(Sql.named('SELECT id, available_balance, currency FROM wallet_wallet WHERE user_id = @userId'), parameters: {'userId': userId});
  if (walletRes.isEmpty) return errorResponse('Wallet not found', statusCode: 404);

  final walletId = walletRes[0][0] as int;
  final balance = double.tryParse(walletRes[0][1]?.toString() ?? '0.0') ?? 0.0;
  final currency = walletRes[0][2]?.toString() ?? 'XOF';

  if (balance < amount) {
    return errorResponse('Insufficient balance', statusCode: 400);
  }

  // Deduct
  await dbPool.execute(
    Sql.named('UPDATE wallet_wallet SET available_balance = available_balance - @amount, total_withdrawn = total_withdrawn + @amount WHERE id = @id'),
    parameters: {'amount': amount, 'id': walletId},
  );

  // Record transaction
  await dbPool.execute(
    Sql.named('INSERT INTO wallet_transaction (amount, type, category, description, status, metadata, created_at, wallet_id) '
              'VALUES (@amount, \'debit\', \'withdrawal\', @desc, \'pending\', @meta, NOW(), @walletId)'),
    parameters: {
      'amount': amount,
      'desc': 'Withdrawal of $amount $currency',
      'meta': jsonEncode({'method': method}),
      'walletId': walletId,
    },
  );

  await createAuditLog(
    actorId: userId,
    action: 'withdrawal_requested',
    entityType: 'wallet',
    entityId: walletId.toString(),
    summary: 'Withdrawal of $amount $currency',
    metadata: {'amount': amount.toString(), 'currency': currency},
    ipAddress: null,
  );

  await createNotification(
    userId: userId,
    category: 'payment',
    title: 'Withdrawal initiated',
    body: 'Your withdrawal request for $amount $currency has been submitted.',
    link: '/dashboard/technician/wallet',
    metadata: {'amount': amount.toString(), 'currency': currency},
  );

  return jsonResponse({
    'message': 'Withdrawal initiated',
    'available_balance': (balance - amount).toString(),
  });
}

Future<Response> depositEscrowHandler(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

  final taskIdVal = body['task_id'];
  final bidIdVal = body['bid_id'];
  final amountVal = body['amount'];

  if (taskIdVal == null || amountVal == null) {
    return errorResponse('task_id and amount are required', statusCode: 400);
  }

  final taskId = int.tryParse(taskIdVal.toString()) ?? 0;
  final bidId = int.tryParse(bidIdVal?.toString() ?? '') ?? 0;
  final amount = double.tryParse(amountVal.toString()) ?? 0.0;

  final taskRes = await dbPool.execute(Sql.named('SELECT client_id, title FROM tasks_task WHERE id = @id'), parameters: {'id': taskId});
  if (taskRes.isEmpty) return errorResponse('Task not found', statusCode: 404);
  if (taskRes[0][0] != userId) return errorResponse('Not authorized', statusCode: 403);

  final clientWalletRes = await dbPool.execute(Sql.named('SELECT id, pending_escrow FROM wallet_wallet WHERE user_id = @userId'), parameters: {'userId': userId});
  if (clientWalletRes.isEmpty) return errorResponse('Wallet not found', statusCode: 404);
  final clientWalletId = clientWalletRes[0][0] as int;

  // Accept bid & assign
  if (bidId > 0) {
    final bidRes = await dbPool.execute(Sql.named('SELECT technician_id FROM tasks_bid WHERE id = @id'), parameters: {'id': bidId});
    if (bidRes.isNotEmpty) {
      final techId = bidRes[0][0] as int;
      await dbPool.execute(Sql.named('UPDATE tasks_bid SET status = \'accepted\', accepted_at = NOW() WHERE id = @id'), parameters: {'id': bidId});
      await dbPool.execute(Sql.named('UPDATE tasks_task SET status = \'in_progress\', assigned_to_id = @techId WHERE id = @id'), parameters: {'techId': techId, 'id': taskId});

      await createNotification(
        userId: techId,
        category: 'payment',
        title: 'Escrow funded',
        body: 'The client has funded the task: ${taskRes[0][1]}',
        link: '/dashboard/technician/tasks/$taskId',
        metadata: {'task_id': taskId, 'bid_id': bidId},
      );
    }
  }

  // Update escrow balance
  await dbPool.execute(
    Sql.named('UPDATE wallet_wallet SET pending_escrow = pending_escrow + @amount WHERE id = @id'),
    parameters: {'amount': amount, 'id': clientWalletId},
  );

  // Record transaction
  await dbPool.execute(
    Sql.named('INSERT INTO wallet_transaction (amount, type, category, description, status, metadata, created_at, reference_id, wallet_id) '
              'VALUES (@amount, \'pending\', \'escrow_hold\', @desc, \'completed\', @meta, NOW(), @taskId, @walletId)'),
    parameters: {
      'amount': amount,
      'desc': 'Escrow held for task: ${taskRes[0][1]}',
      'meta': jsonEncode({'bid_id': bidId}),
      'taskId': taskId,
      'walletId': clientWalletId,
    },
  );

  await createAuditLog(
    actorId: userId,
    action: 'escrow_deposited',
    entityType: 'wallet',
    entityId: clientWalletId.toString(),
    summary: taskRes[0][1]?.toString() ?? '',
    metadata: {'task_id': taskId, 'bid_id': bidId, 'amount': amount.toString()},
    ipAddress: null,
  );

  return jsonResponse({
    'message': 'Escrow deposited',
    'task_status': 'in_progress',
  });
}

Future<Response> releaseEscrowHandler(Request request, String taskIdStr) async {
  final userId = getUserId(request);
  final taskId = int.tryParse(taskIdStr) ?? 0;

  final taskRes = await dbPool.execute(Sql.named('SELECT client_id, assigned_to_id, title FROM tasks_task WHERE id = @id'), parameters: {'id': taskId});
  if (taskRes.isEmpty) return errorResponse('Task not found', statusCode: 404);
  if (taskRes[0][0] != userId) return errorResponse('Not authorized', statusCode: 403);

  final clientWalletRes = await dbPool.execute(Sql.named('SELECT id FROM wallet_wallet WHERE user_id = @userId'), parameters: {'userId': userId});
  final clientWalletId = clientWalletRes[0][0] as int;

  // Find escrow hold transaction
  final txRes = await dbPool.execute(
    Sql.named('SELECT id, amount FROM wallet_transaction WHERE wallet_id = @walletId AND reference_id = @taskId AND category = \'escrow_hold\''),
    parameters: {'walletId': clientWalletId, 'taskId': taskId},
  );
  if (txRes.isEmpty) {
    return errorResponse('No escrow found for this task. Deposit escrow before releasing.', statusCode: 400);
  }

  final txId = txRes[0][0] as int;
  final amount = double.tryParse(txRes[0][1]?.toString() ?? '0.0') ?? 0.0;

  // Deduct from client escrow
  await dbPool.execute(
    Sql.named('UPDATE wallet_wallet SET pending_escrow = pending_escrow - @amount WHERE id = @id'),
    parameters: {'amount': amount, 'id': clientWalletId},
  );

  // Credit to technician
  final techId = taskRes[0][1] as int?;
  if (techId != null) {
    // Find or create tech wallet
    final techWalletRes = await dbPool.execute(Sql.named('SELECT id FROM wallet_wallet WHERE user_id = @techId'), parameters: {'techId': techId});
    int techWalletId;
    if (techWalletRes.isEmpty) {
      final insertRes = await dbPool.execute(
        Sql.named('INSERT INTO wallet_wallet (available_balance, pending_escrow, total_earnings, total_withdrawn, currency, created_at, updated_at, user_id) '
                  'VALUES (0, 0, 0, 0, \'XOF\', NOW(), NOW(), @techId) RETURNING id'),
        parameters: {'techId': techId},
      );
      techWalletId = insertRes[0][0] as int;
    } else {
      techWalletId = techWalletRes[0][0] as int;
    }

    await dbPool.execute(
      Sql.named('UPDATE wallet_wallet SET available_balance = available_balance + @amount, total_earnings = total_earnings + @amount WHERE id = @id'),
      parameters: {'amount': amount, 'id': techWalletId},
    );

    // Record credit transaction
    await dbPool.execute(
      Sql.named('INSERT INTO wallet_transaction (amount, type, category, description, status, metadata, created_at, reference_id, wallet_id) '
                'VALUES (@amount, \'credit\', \'earnings\', @desc, \'completed\', @meta, NOW(), @taskId, @walletId)'),
      parameters: {
        'amount': amount,
        'desc': 'Payment received for: ${taskRes[0][2]}',
        'meta': jsonEncode({}),
        'taskId': taskId,
        'walletId': techWalletId,
      },
    );

    await createNotification(
      userId: techId,
      category: 'payment',
      title: 'Payment received',
      body: 'Payment for task: ${taskRes[0][2]} completed and your balance was updated.',
      link: '/dashboard/technician/wallet',
      metadata: {'task_id': taskId, 'amount': amount.toString()},
    );
  }

  // Update escrow hold transaction category to escrow_release
  await dbPool.execute(
    Sql.named('UPDATE wallet_transaction SET category = \'escrow_release\', description = @desc WHERE id = @id'),
    parameters: {'desc': 'Escrow released for task $taskId', 'id': txId},
  );

  await createAuditLog(
    actorId: userId,
    action: 'escrow_released',
    entityType: 'wallet',
    entityId: clientWalletId.toString(),
    summary: taskRes[0][2]?.toString() ?? '',
    metadata: {'task_id': taskId, 'amount': amount.toString()},
    ipAddress: null,
  );

  return jsonResponse({'message': 'Escrow released', 'amount': amount.toString()});
}

// ─── MESSAGING CONTROLLERS ─────────────────────────────────────────────────

Future<Response> listConversationsHandler(Request request) async {
  final userId = getUserId(request);
  final results = await dbPool.execute(
    Sql.named('SELECT c.*, t.title as task_title FROM messaging_conversation c LEFT JOIN tasks_task t ON c.task_id = t.id JOIN messaging_conversation_participants cp ON c.id = cp.conversation_id WHERE cp.user_id = @userId ORDER BY c.last_message_at DESC'),
    parameters: {'userId': userId},
  );

  final List<Map<String, dynamic>> list = [];
  for (final r in results) {
    final row = r.toColumnMap();
    final convId = row['id'] as int;

    // Get participants
    final participantsQuery = await dbPool.execute(
      Sql.named('SELECT u.* FROM accounts_user u JOIN messaging_conversation_participants cp ON u.id = cp.user_id WHERE cp.conversation_id = @convId'),
      parameters: {'convId': convId},
    );
    final participants = participantsQuery.map((u) => formatUserPublic(u.toColumnMap())).toList();

    // Get last message
    final msgQuery = await dbPool.execute(
      Sql.named('SELECT * FROM messaging_message WHERE conversation_id = @convId ORDER BY created_at DESC LIMIT 1'),
      parameters: {'convId': convId},
    );
    Map<String, dynamic>? lastMsg;
    if (msgQuery.isNotEmpty) {
      final msg = msgQuery[0].toColumnMap();
      lastMsg = {
        'id': msg['id'],
        'text': msg['text'] ?? '',
        'created_at': msg['created_at'] != null ? (msg['created_at'] as DateTime).toIso8601String() : '',
        'sender': msg['sender_id'],
      };
    }

    list.add({
      'id': convId,
      'task': row['task_id'] != null ? {'id': row['task_id'], 'title': row['task_title']} : null,
      'participants': participants,
      'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
      'updated_at': row['updated_at'] != null ? (row['updated_at'] as DateTime).toIso8601String() : '',
      'last_message_at': row['last_message_at'] != null ? (row['last_message_at'] as DateTime).toIso8601String() : null,
      'last_message': lastMsg,
    });
  }

  return jsonResponse(list);
}

Future<Response> createConversationHandler(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final otherUserIdVal = body['other_user_id'] ?? body['participant_id'];
  final taskIdVal = body['task_id'];

  if (otherUserIdVal == null) {
    return errorResponse('participant_id is required', statusCode: 400);
  }

  final otherUserId = int.tryParse(otherUserIdVal.toString()) ?? 0;
  final taskId = int.tryParse(taskIdVal?.toString() ?? '');

  // Check if conversation exists
  var checkQuery = 'SELECT c.id FROM messaging_conversation c '
      'JOIN messaging_conversation_participants cp1 ON c.id = cp1.conversation_id '
      'JOIN messaging_conversation_participants cp2 ON c.id = cp2.conversation_id '
      'WHERE cp1.user_id = @u1 AND cp2.user_id = @u2';
  final checkParams = <String, dynamic>{'u1': userId, 'u2': otherUserId};
  if (taskId != null) {
    checkQuery += ' AND c.task_id = @taskId';
    checkParams['taskId'] = taskId;
  }
  final check = await dbPool.execute(Sql.named(checkQuery), parameters: checkParams);

  int convId;
  if (check.isNotEmpty) {
    convId = check[0][0] as int;
  } else {
    // Create new conversation
    final res = await dbPool.execute(
      Sql.named('INSERT INTO messaging_conversation (task_id, created_at, updated_at, last_message_at) VALUES (@taskId, NOW(), NOW(), null) RETURNING id'),
      parameters: {'taskId': taskId},
    );
    convId = res[0][0] as int;

    // Add participants
    await dbPool.execute(Sql.named('INSERT INTO messaging_conversation_participants (conversation_id, user_id) VALUES (@cId, @uId)'), parameters: {'cId': convId, 'uId': userId});
    await dbPool.execute(Sql.named('INSERT INTO messaging_conversation_participants (conversation_id, user_id) VALUES (@cId, @uId)'), parameters: {'cId': convId, 'uId': otherUserId});

    await createAuditLog(
      actorId: userId,
      action: 'conversation_created',
      entityType: 'conversation',
      entityId: convId.toString(),
      summary: 'Conversation created',
      metadata: {'participant_id': otherUserId, 'task_id': taskId},
      ipAddress: null,
    );
  }

  // Return detail
  final pQuery = await dbPool.execute(
    Sql.named('SELECT u.* FROM accounts_user u JOIN messaging_conversation_participants cp ON u.id = cp.user_id WHERE cp.conversation_id = @cId'),
    parameters: {'cId': convId},
  );
  final participants = pQuery.map((u) => formatUserPublic(u.toColumnMap())).toList();

  final messagesQuery = await dbPool.execute(
    Sql.named('SELECT * FROM messaging_message WHERE conversation_id = @cId ORDER BY created_at ASC'),
    parameters: {'cId': convId},
  );
  final messages = messagesQuery.map((m) {
    final row = m.toColumnMap();
    return {
      'id': row['id'],
      'text': row['text'] ?? '',
      'attachment_url': row['attachment_url'] ?? '',
      'attachment_name': row['attachment_name'] ?? '',
      'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
      'sender': row['sender_id'],
    };
  }).toList();

  return Response(201, body: jsonEncode({
    'id': convId,
    'participants': participants,
    'messages': messages,
  }), headers: {'content-type': 'application/json'});
}

Future<Response> conversationDetailHandler(Request request, String convIdStr) async {
  final userId = getUserId(request);
  final convId = int.tryParse(convIdStr) ?? 0;

  final check = await dbPool.execute(
    Sql.named('SELECT id FROM messaging_conversation_participants WHERE conversation_id = @cId AND user_id = @uId'),
    parameters: {'cId': convId, 'uId': userId},
  );
  if (check.isEmpty) return errorResponse('Not authorized', statusCode: 403);

  // Mark messages as read
  await dbPool.execute(
    Sql.named('UPDATE messaging_message SET read_at = NOW() WHERE conversation_id = @cId AND sender_id != @uId AND read_at IS NULL'),
    parameters: {'cId': convId, 'uId': userId},
  );

  final pQuery = await dbPool.execute(
    Sql.named('SELECT u.* FROM accounts_user u JOIN messaging_conversation_participants cp ON u.id = cp.user_id WHERE cp.conversation_id = @cId'),
    parameters: {'cId': convId},
  );
  final participants = pQuery.map((u) => formatUserPublic(u.toColumnMap())).toList();

  final messagesQuery = await dbPool.execute(
    Sql.named('SELECT * FROM messaging_message WHERE conversation_id = @cId ORDER BY created_at ASC'),
    parameters: {'cId': convId},
  );
  final messages = messagesQuery.map((m) {
    final row = m.toColumnMap();
    return {
      'id': row['id'],
      'text': row['text'] ?? '',
      'attachment_url': row['attachment_url'] ?? '',
      'attachment_name': row['attachment_name'] ?? '',
      'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
      'sender': row['sender_id'],
    };
  }).toList();

  return jsonResponse({
    'id': convId,
    'participants': participants,
    'messages': messages,
  });
}

Future<Response> sendMessageHandler(Request request, String convIdStr) async {
  final userId = getUserId(request);
  final convId = int.tryParse(convIdStr) ?? 0;
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final text = body['text']?.toString() ?? '';

  final check = await dbPool.execute(
    Sql.named('SELECT id FROM messaging_conversation_participants WHERE conversation_id = @cId AND user_id = @uId'),
    parameters: {'cId': convId, 'uId': userId},
  );
  if (check.isEmpty) return errorResponse('Not authorized', statusCode: 403);

  final res = await dbPool.execute(
    Sql.named('INSERT INTO messaging_message (text, attachment_url, attachment_key, attachment_name, attachment_type, attachment_size, attachment_content_type, created_at, read_at, conversation_id, sender_id) '
              'VALUES (@text, \'\', \'\', \'\', \'file\', 0, \'\', NOW(), null, @cId, @uId) RETURNING id'),
    parameters: {'text': text, 'cId': convId, 'uId': userId},
  );
  final newMsgId = res[0][0] as int;

  // Update conversation last message timestamp
  await dbPool.execute(Sql.named('UPDATE messaging_conversation SET last_message_at = NOW() WHERE id = @id'), parameters: {'id': convId});

  // Notify other participant
  final parts = await dbPool.execute(Sql.named('SELECT user_id FROM messaging_conversation_participants WHERE conversation_id = @cId AND user_id != @uId'), parameters: {'cId': convId, 'uId': userId});
  if (parts.isNotEmpty) {
    final other = parts[0][0] as int;
    await createNotification(
      userId: other,
      category: 'message',
      title: 'New message',
      body: text.length > 100 ? text.substring(0, 100) + '...' : text,
      link: '/dashboard/client/messages?c=$convId',
      metadata: {'conversation_id': convId, 'message_id': newMsgId},
    );
  }

  return Response(201, body: jsonEncode({
    'id': newMsgId,
    'text': text,
    'sender': userId,
    'created_at': DateTime.now().toIso8601String(),
  }), headers: {'content-type': 'application/json'});
}

// ─── COMPANY CONTROLLERS ───────────────────────────────────────────────────

Future<Response> listCompaniesHandler(Request request) async {
  final params = request.url.queryParameters;
  final limit = int.tryParse(params['limit'] ?? '12') ?? 12;

  final results = await dbPool.execute(
    Sql.named('SELECT cp.*, u.avatar_url as user_avatar FROM companies_profile cp JOIN accounts_user u ON cp.user_id = u.id ORDER BY cp.created_at DESC LIMIT @limit'),
    parameters: {'limit': limit},
  );

  final data = results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'company_name': row['company_name'] ?? '',
      'registration_number': row['registration_number'] ?? '',
      'services_offered': parseJsonField(row['services_offered']) ?? [],
      'company_size': row['company_size'] ?? '',
      'logo_url': row['logo_url'] ?? '',
      'cover_url': row['cover_url'] ?? '',
      'about': row['about'] ?? '',
      'website': row['website'] ?? '',
      'headquarters': row['headquarters'] ?? '',
      'business_hours': parseJsonField(row['business_hours']) ?? [],
      'is_verified': row['is_verified'] ?? false,
      'average_rating': row['average_rating']?.toString() ?? '0.00',
      'review_count': row['review_count'] ?? 0,
      'team_size': row['team_size'] ?? 0,
      'completed_tasks': row['completed_tasks'] ?? 0,
      'response_time': row['response_time'] ?? '',
      'user_id': row['user_id'],
    };
  }).toList();

  return jsonResponse(data);
}

Future<Response> getCompanyProfileHandler(Request request) async {
  final userId = getUserId(request);
  final results = await dbPool.execute(Sql.named('SELECT * FROM companies_profile WHERE user_id = @userId'), parameters: {'userId': userId});
  if (results.isEmpty) return errorResponse('Company profile not found', statusCode: 404);

  final profile = results[0].toColumnMap();
  final profileId = profile['id'] as int;

  // fetch projects, services, certifications, reviews
  final proj = await dbPool.execute(Sql.named('SELECT * FROM companies_project WHERE company_id = @id'), parameters: {'id': profileId});
  final serv = await dbPool.execute(Sql.named('SELECT * FROM companies_service WHERE company_id = @id'), parameters: {'id': profileId});
  final cert = await dbPool.execute(Sql.named('SELECT * FROM companies_certification WHERE company_id = @id'), parameters: {'id': profileId});
  final rev = await dbPool.execute(Sql.named('SELECT cr.*, u.email as rev_email, u.first_name as rev_first, u.last_name as rev_last, u.avatar_url as rev_avatar FROM companies_review cr JOIN accounts_user u ON cr.reviewer_id = u.id WHERE cr.company_id = @id'), parameters: {'id': profileId});

  final data = {
    'id': profile['id'],
    'company_name': profile['company_name'] ?? '',
    'registration_number': profile['registration_number'] ?? '',
    'services_offered': parseJsonField(profile['services_offered']) ?? [],
    'company_size': profile['company_size'] ?? '',
    'logo_url': profile['logo_url'] ?? '',
    'cover_url': profile['cover_url'] ?? '',
    'about': profile['about'] ?? '',
    'website': profile['website'] ?? '',
    'headquarters': profile['headquarters'] ?? '',
    'business_hours': parseJsonField(profile['business_hours']) ?? [],
    'is_verified': profile['is_verified'] ?? false,
    'average_rating': profile['average_rating']?.toString() ?? '0.00',
    'review_count': profile['review_count'] ?? 0,
    'team_size': profile['team_size'] ?? 0,
    'completed_tasks': profile['completed_tasks'] ?? 0,
    'response_time': profile['response_time'] ?? '',
    'projects': proj.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'],
        'title': row['title'],
        'status': row['status'],
        'client_name': row['client_name'],
        'budget': row['budget']?.toString(),
        'timeline': row['timeline'],
        'progress': row['progress'] ?? 0,
      };
    }).toList(),
    'services': serv.map((r) => {'id': r[0], 'title': r[2], 'description': r[3]}).toList(),
    'certifications': cert.map((r) => {'id': r[0], 'title': r[2], 'description': r[3]}).toList(),
    'reviews': rev.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'],
        'rating': row['rating'],
        'text': row['text'] ?? '',
        'service': row['service'] ?? '',
        'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
        'reviewer_name': ((row['rev_first']?.toString() ?? '') + ' ' + (row['rev_last']?.toString() ?? '')).trim().isEmpty ? row['rev_email'] : ((row['rev_first']?.toString() ?? '') + ' ' + (row['rev_last']?.toString() ?? '')).trim(),
        'reviewer_avatar': row['rev_avatar'] ?? '',
      };
    }).toList(),
  };

  return jsonResponse(data);
}

Future<Response> updateCompanyProfileHandler(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

  final allowed = ['company_name', 'registration_number', 'services_offered', 'company_size', 'logo_url', 'cover_url', 'about', 'website', 'headquarters', 'business_hours', 'team_size', 'completed_tasks', 'response_time'];
  final updates = <String, dynamic>{};
  for (final f in allowed) {
    if (body.containsKey(f)) {
      if (f == 'services_offered' || f == 'business_hours') {
        updates[f] = jsonEncode(body[f]);
      } else {
        updates[f] = body[f];
      }
    }
  }

  if (updates.isNotEmpty) {
    final queryParts = updates.keys.map((k) => '$k = @$k').join(', ');
    final params = Map<String, dynamic>.from(updates)..['userId'] = userId;
    await dbPool.execute(
      Sql.named('UPDATE companies_profile SET $queryParts, updated_at = NOW() WHERE user_id = @userId'),
      parameters: params,
    );
  }

  return getCompanyProfileHandler(request);
}

Future<Response> companyPublicProfileHandler(Request request, String idStr) async {
  final companyId = int.tryParse(idStr) ?? 0;
  final results = await dbPool.execute(Sql.named('SELECT * FROM companies_profile WHERE id = @id'), parameters: {'id': companyId});
  if (results.isEmpty) return errorResponse('Company not found', statusCode: 404);

  final profile = results[0].toColumnMap();
  final profileId = profile['id'] as int;

  // fetch projects, services, certifications, reviews
  final proj = await dbPool.execute(Sql.named('SELECT * FROM companies_project WHERE company_id = @id'), parameters: {'id': profileId});
  final serv = await dbPool.execute(Sql.named('SELECT * FROM companies_service WHERE company_id = @id'), parameters: {'id': profileId});
  final cert = await dbPool.execute(Sql.named('SELECT * FROM companies_certification WHERE company_id = @id'), parameters: {'id': profileId});
  final rev = await dbPool.execute(Sql.named('SELECT cr.*, u.email as rev_email, u.first_name as rev_first, u.last_name as rev_last, u.avatar_url as rev_avatar FROM companies_review cr JOIN accounts_user u ON cr.reviewer_id = u.id WHERE cr.company_id = @id'), parameters: {'id': profileId});

  final data = {
    'id': profile['id'],
    'company_name': profile['company_name'] ?? '',
    'registration_number': profile['registration_number'] ?? '',
    'services_offered': parseJsonField(profile['services_offered']) ?? [],
    'company_size': profile['company_size'] ?? '',
    'logo_url': profile['logo_url'] ?? '',
    'cover_url': profile['cover_url'] ?? '',
    'about': profile['about'] ?? '',
    'website': profile['website'] ?? '',
    'headquarters': profile['headquarters'] ?? '',
    'business_hours': parseJsonField(profile['business_hours']) ?? [],
    'is_verified': profile['is_verified'] ?? false,
    'average_rating': profile['average_rating']?.toString() ?? '0.00',
    'review_count': profile['review_count'] ?? 0,
    'team_size': profile['team_size'] ?? 0,
    'completed_tasks': profile['completed_tasks'] ?? 0,
    'response_time': profile['response_time'] ?? '',
    'projects': proj.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'],
        'title': row['title'],
        'status': row['status'],
        'client_name': row['client_name'],
        'budget': row['budget']?.toString(),
        'timeline': row['timeline'],
        'progress': row['progress'] ?? 0,
      };
    }).toList(),
    'services': serv.map((r) => {'id': r[0], 'title': r[2], 'description': r[3]}).toList(),
    'certifications': cert.map((r) => {'id': r[0], 'title': r[2], 'description': r[3]}).toList(),
    'reviews': rev.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'],
        'rating': row['rating'],
        'text': row['text'] ?? '',
        'service': row['service'] ?? '',
        'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
        'reviewer_name': ((row['rev_first']?.toString() ?? '') + ' ' + (row['rev_last']?.toString() ?? '')).trim().isEmpty ? row['rev_email'] : ((row['rev_first']?.toString() ?? '') + ' ' + (row['rev_last']?.toString() ?? '')).trim(),
        'reviewer_avatar': row['rev_avatar'] ?? '',
      };
    }).toList(),
  };

  return jsonResponse(data);
}

Future<Response> companyProjectsHandler(Request request) async {
  final userId = getUserId(request);
  final profileQuery = await dbPool.execute(Sql.named('SELECT id FROM companies_profile WHERE user_id = @userId'), parameters: {'userId': userId});
  if (profileQuery.isEmpty) return errorResponse('Company profile not found', statusCode: 404);
  final profileId = profileQuery[0][0] as int;

  if (request.method == 'GET') {
    final results = await dbPool.execute(Sql.named('SELECT * FROM companies_project WHERE company_id = @id'), parameters: {'id': profileId});
    return jsonResponse(results.map((r) {
      final row = r.toColumnMap();
      return {
        'id': row['id'],
        'title': row['title'],
        'status': row['status'],
        'client_name': row['client_name'],
        'budget': row['budget']?.toString(),
        'timeline': row['timeline'],
        'progress': row['progress'] ?? 0,
      };
    }).toList());
  } else if (request.method == 'POST') {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final title = body['title']?.toString() ?? '';
    final clientName = body['client_name']?.toString() ?? '';
    final budget = double.tryParse(body['budget']?.toString() ?? '');
    final timeline = body['timeline']?.toString() ?? '';

    final res = await dbPool.execute(
      Sql.named('INSERT INTO companies_project (title, status, client_name, budget, timeline, milestones_total, milestones_completed, payment_status, location, progress, created_at, updated_at, company_id) '
                'VALUES (@title, \'active\', @client, @budget, @timeline, 0, 0, \'awaiting\', \'\', 0, NOW(), NOW(), @companyId) RETURNING id'),
      parameters: {
        'title': title,
        'client': clientName,
        'budget': budget,
        'timeline': timeline,
        'companyId': profileId,
      },
    );

    return Response(201, body: jsonEncode({
      'id': res[0][0],
      'title': title,
      'client_name': clientName,
      'budget': budget?.toString(),
      'timeline': timeline,
      'status': 'active',
      'progress': 0,
    }), headers: {'content-type': 'application/json'});
  }

  return errorResponse('Method not allowed', statusCode: 405);
}

Future<Response> companyCertificationsHandler(Request request) async {
  final userId = getUserId(request);
  final profileQuery = await dbPool.execute(Sql.named('SELECT id FROM companies_profile WHERE user_id = @userId'), parameters: {'userId': userId});
  if (profileQuery.isEmpty) return errorResponse('Company profile not found', statusCode: 404);
  final profileId = profileQuery[0][0] as int;

  if (request.method == 'GET') {
    final results = await dbPool.execute(Sql.named('SELECT * FROM companies_certification WHERE company_id = @id'), parameters: {'id': profileId});
    return jsonResponse(results.map((r) => {'id': r[0], 'title': r[2], 'description': r[3]}).toList());
  } else if (request.method == 'POST') {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final title = body['title']?.toString() ?? '';
    final description = body['description']?.toString() ?? '';

    final res = await dbPool.execute(
      Sql.named('INSERT INTO companies_certification (title, description, created_at, company_id) VALUES (@title, @desc, NOW(), @companyId) RETURNING id'),
      parameters: {
        'title': title,
        'desc': description,
        'companyId': profileId,
      },
    );

    return Response(201, body: jsonEncode({
      'id': res[0][0],
      'title': title,
      'description': description,
    }), headers: {'content-type': 'application/json'});
  }

  return errorResponse('Method not allowed', statusCode: 405);
}

Future<Response> companyServicesHandler(Request request) async {
  final userId = getUserId(request);
  final profileQuery = await dbPool.execute(Sql.named('SELECT id FROM companies_profile WHERE user_id = @userId'), parameters: {'userId': userId});
  if (profileQuery.isEmpty) return errorResponse('Company profile not found', statusCode: 404);
  final profileId = profileQuery[0][0] as int;

  if (request.method == 'GET') {
    final results = await dbPool.execute(Sql.named('SELECT * FROM companies_service WHERE company_id = @id'), parameters: {'id': profileId});
    return jsonResponse(results.map((r) => {'id': r[0], 'title': r[2], 'description': r[3]}).toList());
  } else if (request.method == 'POST') {
    final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    final title = body['title']?.toString() ?? '';
    final description = body['description']?.toString() ?? '';

    final res = await dbPool.execute(
      Sql.named('INSERT INTO companies_service (title, description, created_at, company_id) VALUES (@title, @desc, NOW(), @companyId) RETURNING id'),
      parameters: {
        'title': title,
        'desc': description,
        'companyId': profileId,
      },
    );

    return Response(201, body: jsonEncode({
      'id': res[0][0],
      'title': title,
      'description': description,
    }), headers: {'content-type': 'application/json'});
  }

  return errorResponse('Method not allowed', statusCode: 405);
}

Future<Response> deleteCompanyServiceHandler(Request request, String idStr) async {
  final userId = getUserId(request);
  final serviceId = int.tryParse(idStr) ?? 0;

  final profileQuery = await dbPool.execute(Sql.named('SELECT id FROM companies_profile WHERE user_id = @userId'), parameters: {'userId': userId});
  if (profileQuery.isEmpty) return errorResponse('Company profile not found', statusCode: 404);
  final profileId = profileQuery[0][0] as int;

  final res = await dbPool.execute(
    Sql.named('DELETE FROM companies_service WHERE id = @id AND company_id = @companyId'),
    parameters: {'id': serviceId, 'companyId': profileId},
  );

  if (res.affectedRows == 0) return errorResponse('Service not found', statusCode: 404);
  return Response(204);
}

Future<Response> addCompanyReviewHandler(Request request, String companyIdStr) async {
  final userId = getUserId(request);
  final companyId = int.tryParse(companyIdStr) ?? 0;

  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final rating = int.tryParse(body['rating']?.toString() ?? '') ?? 5;
  final text = body['text']?.toString() ?? '';
  final service = body['service']?.toString() ?? '';

  final check = await dbPool.execute(Sql.named('SELECT id FROM companies_profile WHERE id = @id'), parameters: {'id': companyId});
  if (check.isEmpty) return errorResponse('Company not found', statusCode: 404);

  await dbPool.execute(
    Sql.named('INSERT INTO companies_review (rating, text, service, created_at, company_id, reviewer_id) VALUES (@rating, @text, @service, NOW(), @companyId, @userId)'),
    parameters: {
      'rating': rating,
      'text': text,
      'service': service,
      'companyId': companyId,
      'userId': userId,
    },
  );

  // recalculate average rating
  final allReviews = await dbPool.execute(Sql.named('SELECT rating FROM companies_review WHERE company_id = @id'), parameters: {'id': companyId});
  final total = allReviews.map((r) => r[0] as int).fold(0, (a, b) => a + b);
  final avg = allReviews.isEmpty ? 0.00 : (total / allReviews.length);

  await dbPool.execute(
    Sql.named('UPDATE companies_profile SET average_rating = @avg, review_count = @cnt WHERE id = @id'),
    parameters: {'avg': avg, 'cnt': allReviews.length, 'id': companyId},
  );

  return Response(201, body: jsonEncode({
    'rating': rating,
    'text': text,
    'service': service,
  }), headers: {'content-type': 'application/json'});
}

// ─── SEARCH CONTROLLER ─────────────────────────────────────────────────────

Future<Response> searchEverythingHandler(Request request) async {
  final params = request.url.queryParameters;
  final query = (params['q'] ?? '').trim();
  final category = (params['category'] ?? '').trim();
  final location = (params['location'] ?? '').trim();
  final professionalType = (params['professionalType'] ?? params['type'] ?? 'all').trim().toLowerCase();
  final tab = (params['tab'] ?? 'all').trim().toLowerCase();
  final sort = (params['sort'] ?? 'relevance').trim().toLowerCase();
  final minRating = double.tryParse(params['rating'] ?? params['min_rating'] ?? '');
  final budgetMin = double.tryParse(params['budgetMin'] ?? params['budget_min'] ?? '');
  final budgetMax = double.tryParse(params['budgetMax'] ?? params['budget_max'] ?? '');

  final includeTasks = tab == 'all' || tab == 'tasks';
  final includeServices = tab == 'all' || tab == 'services';
  final includeTechnicians = professionalType == 'all' || professionalType == 'technician' || professionalType == 'professionals';
  final includeCompanies = professionalType == 'all' || professionalType == 'company' || professionalType == 'companies' || professionalType == 'professionals';

  final results = <Map<String, dynamic>>[];

  if (includeTasks) {
    var taskSql = 'SELECT t.*, c.name as category_name, c.slug as category_slug, cl.email as client_email, cl.first_name as client_first_name, cl.last_name as client_last_name, cl.avatar_url as client_avatar, cl.role as client_role, cl.is_verified as client_is_verified, ast.email as assigned_email, ast.first_name as assigned_first_name, ast.last_name as assigned_last_name, ast.avatar_url as assigned_avatar, ast.role as assigned_role, ast.is_verified as assigned_is_verified FROM tasks_task t LEFT JOIN tasks_category c ON t.category_id = c.id LEFT JOIN accounts_user cl ON t.client_id = cl.id LEFT JOIN accounts_user ast ON t.assigned_to_id = ast.id WHERE t.status = \'open\'';
    final taskClauses = <String>[];
    final taskParams = <String, dynamic>{};

    if (query.isNotEmpty) {
      taskClauses.add('(t.title ILIKE @query OR t.description ILIKE @query OR t.location ILIKE @query OR t.city ILIKE @query)');
      taskParams['query'] = '%$query%';
    }
    if (category.isNotEmpty) {
      taskClauses.add('(c.slug = @category OR c.name ILIKE @category)');
      taskParams['category'] = category;
    }
    if (location.isNotEmpty) {
      taskClauses.add('(t.location ILIKE @location OR t.city ILIKE @location)');
      taskParams['location'] = '%$location%';
    }
    if (budgetMin != null) {
      taskClauses.add('t.budget_max >= @budgetMin');
      taskParams['budgetMin'] = budgetMin;
    }
    if (budgetMax != null) {
      taskClauses.add('t.budget_min <= @budgetMax');
      taskParams['budgetMax'] = budgetMax;
    }

    if (taskClauses.isNotEmpty) {
      taskSql += ' AND ' + taskClauses.join(' AND ');
    }
    if (sort == 'budget_high') {
      taskSql += ' ORDER BY t.budget_max DESC';
    } else if (sort == 'budget_low') {
      taskSql += ' ORDER BY t.budget_min ASC';
    } else {
      taskSql += ' ORDER BY t.created_at DESC';
    }
    taskSql += ' LIMIT 25';

    final taskRes = await dbPool.execute(Sql.named(taskSql), parameters: taskParams);
    for (final row in taskRes) {
      final tMap = formatJoinedTask(row.toColumnMap());
      tMap['type'] = 'task';
      tMap['name'] = tMap['title'];
      tMap['price'] = tMap['budget_min'] ?? tMap['budget_max'];
      tMap['rating'] = null;
      tMap['reviews_count'] = tMap['bids_count'];
      results.add(tMap);
    }
  }

  if (includeServices) {
    var servSql = 'SELECT ts.*, c.name as category_name, u.first_name, u.last_name, u.username, u.avatar_url, u.is_verified, tp.average_rating, tp.completed_jobs, tp.id as tp_id FROM accounts_technician_service ts JOIN accounts_user u ON ts.technician_id = u.id JOIN accounts_technician_profile tp ON u.id = tp.user_id LEFT JOIN tasks_category c ON ts.category_id = c.id WHERE ts.is_active = true';
    final servClauses = <String>[];
    final servParams = <String, dynamic>{};

    if (query.isNotEmpty) {
      servClauses.add('(ts.title ILIKE @query OR ts.description ILIKE @query OR ts.coverage_area ILIKE @query OR c.name ILIKE @query OR u.first_name ILIKE @query OR u.last_name ILIKE @query)');
      servParams['query'] = '%$query%';
    }
    if (category.isNotEmpty) {
      servClauses.add('(c.slug = @category OR c.name ILIKE @category)');
      servParams['category'] = category;
    }
    if (location.isNotEmpty) {
      servClauses.add('(ts.coverage_area ILIKE @location OR u.country ILIKE @location)');
      servParams['location'] = '%$location%';
    }
    if (minRating != null) {
      servClauses.add('tp.average_rating >= @minRating');
      servParams['minRating'] = minRating;
    }

    if (servClauses.isNotEmpty) {
      servSql += ' AND ' + servClauses.join(' AND ');
    }
    servSql += ' LIMIT 25';

    final servRes = await dbPool.execute(Sql.named(servSql), parameters: servParams);
    for (final row in servRes) {
      final map = row.toColumnMap();
      final name = ((map['first_name']?.toString() ?? '') + ' ' + (map['last_name']?.toString() ?? '')).trim();
      final profId = map['tp_id'] as int;

      // skills
      final skillsQuery = await dbPool.execute(
        Sql.named('SELECT s.name FROM tasks_skill s JOIN accounts_technician_profile_skills ps ON s.id = ps.skill_id WHERE ps.technicianprofile_id = @profId'),
        parameters: {'profId': profId},
      );
      final skills = skillsQuery.map((r) => r[0]?.toString() ?? '').toList();

      results.add({
        'id': map['id'],
        'type': 'service',
        'name': map['title'],
        'role': name.isEmpty ? map['username'] : name,
        'description': map['description'] ?? '',
        'image': map['avatar_url'] ?? '',
        'category': map['category_name'] ?? '',
        'rating': map['average_rating'] != null ? double.tryParse(map['average_rating'].toString()) : null,
        'reviews': map['completed_jobs'] ?? 0,
        'location': map['coverage_area'] ?? '',
        'price': map['pricing_min'] != null ? double.tryParse(map['pricing_min'].toString()) : null,
        'priceLabel': map['pricing_model'] ?? 'fixed',
        'verified': map['is_verified'] ?? false,
        'skills': skills,
        'serviceType': map['service_type'] ?? 'onsite',
        'pricingModel': map['pricing_model'] ?? 'fixed',
        'profileId': map['technician_id'],
      });
    }
  }

  if (includeTechnicians && tab != 'services' && tab != 'tasks') {
    var techSql = 'SELECT u.*, tp.bio, tp.hourly_rate, tp.average_rating, tp.completed_jobs, tp.availability_status, tp.id as tp_id FROM accounts_user u JOIN accounts_technician_profile tp ON u.id = tp.user_id WHERE u.is_active = true AND u.role = \'TECHNICIAN\'';
    final techClauses = <String>[];
    final techParams = <String, dynamic>{};

    if (query.isNotEmpty) {
      techClauses.add('(u.first_name ILIKE @query OR u.last_name ILIKE @query OR u.username ILIKE @query OR u.email ILIKE @query)');
      techParams['query'] = '%$query%';
    }
    if (location.isNotEmpty) {
      techClauses.add('(u.country ILIKE @location)');
      techParams['location'] = '%$location%';
    }
    if (minRating != null) {
      techClauses.add('tp.average_rating >= @minRating');
      techParams['minRating'] = minRating;
    }

    if (techClauses.isNotEmpty) {
      techSql += ' AND ' + techClauses.join(' AND ');
    }
    techSql += ' LIMIT 25';

    final techRes = await dbPool.execute(Sql.named(techSql), parameters: techParams);
    for (final row in techRes) {
      final map = row.toColumnMap();
      final name = ((map['first_name']?.toString() ?? '') + ' ' + (map['last_name']?.toString() ?? '')).trim();
      final profId = map['tp_id'] as int;

      // skills
      final skillsQuery = await dbPool.execute(
        Sql.named('SELECT s.name FROM tasks_skill s JOIN accounts_technician_profile_skills ps ON s.id = ps.skill_id WHERE ps.technicianprofile_id = @profId'),
        parameters: {'profId': profId},
      );
      final skills = skillsQuery.map((r) => r[0]?.toString() ?? '').toList();

      results.add({
        'id': map['id'],
        'type': 'technician',
        'name': name.isEmpty ? map['username'] : name,
        'role': 'Technician',
        'description': map['bio'] ?? '',
        'image': map['avatar_url'] ?? '',
        'category': '',
        'rating': map['average_rating'] != null ? double.tryParse(map['average_rating'].toString()) : null,
        'reviews': map['completed_jobs'] ?? 0,
        'location': map['country'] ?? '',
        'price': map['hourly_rate'] != null ? double.tryParse(map['hourly_rate'].toString()) : null,
        'priceLabel': 'hourly rate',
        'verified': map['is_verified'] ?? false,
        'skills': skills,
        'profile': formatUserPublic(map),
      });
    }
  }

  if (includeCompanies && tab != 'services' && tab != 'tasks') {
    var compSql = 'SELECT cp.*, u.avatar_url, u.country FROM companies_profile cp JOIN accounts_user u ON cp.user_id = u.id WHERE u.is_active = true';
    final compClauses = <String>[];
    final compParams = <String, dynamic>{};

    if (query.isNotEmpty) {
      compClauses.add('(cp.company_name ILIKE @query OR cp.about ILIKE @query OR cp.headquarters ILIKE @query)');
      compParams['query'] = '%$query%';
    }
    if (location.isNotEmpty) {
      compClauses.add('(cp.headquarters ILIKE @location OR u.country ILIKE @location)');
      compParams['location'] = '%$location%';
    }
    if (minRating != null) {
      compClauses.add('cp.average_rating >= @minRating');
      compParams['minRating'] = minRating;
    }

    if (compClauses.isNotEmpty) {
      compSql += ' AND ' + compClauses.join(' AND ');
    }
    compSql += ' LIMIT 25';

    final compRes = await dbPool.execute(Sql.named(compSql), parameters: compParams);
    for (final row in compRes) {
      final map = row.toColumnMap();
      results.add({
        'id': map['user_id'],
        'type': 'company',
        'name': map['company_name'],
        'role': 'Company',
        'description': map['about'] ?? '',
        'image': map['logo_url'] ?? map['avatar_url'] ?? '',
        'category': '',
        'rating': map['average_rating'] != null ? double.tryParse(map['average_rating'].toString()) : null,
        'reviews': map['review_count'] ?? 0,
        'location': map['headquarters'] ?? map['country'] ?? '',
        'price': null,
        'priceLabel': 'company profile',
        'verified': map['is_verified'] ?? false,
        'skills': parseJsonField(map['services_offered']) ?? [],
      });
    }
  }

  final page = int.tryParse(params['page'] ?? '1') ?? 1;
  final limit = int.tryParse(params['limit'] ?? '20') ?? 20;
  final start = (page - 1) * limit;
  final end = start + limit;
  final paginated = results.sublist(start, end > results.length ? results.length : end);

  return jsonResponse({
    'results': paginated,
    'total': results.length,
    'page': page,
    'limit': limit,
    'total_pages': (results.length + limit - 1) ~/ limit,
  });
}

// ─── GOVERNANCE CONTROLLERS ────────────────────────────────────────────────

Future<Response> publicCmsPagesHandler(Request request) async {
  final results = await dbPool.execute('SELECT * FROM governance_cms_page WHERE is_published = true ORDER BY sort_order ASC, title ASC');
  final list = results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'title': row['title'] ?? '',
      'slug': row['slug'] ?? '',
      'excerpt': row['excerpt'] ?? '',
      'content': row['content'] ?? '',
      'show_in_footer': row['show_in_footer'] ?? true,
    };
  }).toList();
  return jsonResponse(list);
}

Future<Response> publicCmsPageDetailHandler(Request request, String slug) async {
  final results = await dbPool.execute(
    Sql.named('SELECT * FROM governance_cms_page WHERE slug = @slug AND is_published = true'),
    parameters: {'slug': slug},
  );

  if (results.isEmpty) return errorResponse('Page not found', statusCode: 404);
  final row = results[0].toColumnMap();
  return jsonResponse({
    'id': row['id'],
    'title': row['title'] ?? '',
    'slug': row['slug'] ?? '',
    'excerpt': row['excerpt'] ?? '',
    'content': row['content'] ?? '',
    'show_in_footer': row['show_in_footer'] ?? true,
  });
}

Future<Response> listNotificationsHandler(Request request) async {
  final userId = getUserId(request);
  final results = await dbPool.execute(
    Sql.named('SELECT * FROM governance_notification WHERE user_id = @userId ORDER BY created_at DESC LIMIT 50'),
    parameters: {'userId': userId},
  );

  final list = results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'category': row['category'] ?? 'system',
      'title': row['title'] ?? '',
      'body': row['body'] ?? '',
      'link': row['link'] ?? '',
      'metadata': parseJsonField(row['metadata']) ?? {},
      'is_read': row['is_read'] ?? false,
      'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
    };
  }).toList();

  return jsonResponse(list);
}

Future<Response> markNotificationReadHandler(Request request, String idStr) async {
  final userId = getUserId(request);
  final id = int.tryParse(idStr) ?? 0;

  final res = await dbPool.execute(
    Sql.named('UPDATE governance_notification SET is_read = true, read_at = NOW() WHERE id = @id AND user_id = @userId'),
    parameters: {'id': id, 'userId': userId},
  );

  if (res.affectedRows == 0) return errorResponse('Notification not found', statusCode: 404);
  return jsonResponse({'message': 'Notification marked as read'});
}

Future<Response> listDisputesHandler(Request request) async {
  final userId = getUserId(request);
  final role = getUserRole(request);

  var query = 'SELECT * FROM governance_dispute';
  final sqlParams = <String, dynamic>{};

  if (role != 'ADMIN') {
    query += ' WHERE opened_by_id = @userId OR against_id = @userId';
    sqlParams['userId'] = userId;
  }
  query += ' ORDER BY opened_at DESC';

  final results = await dbPool.execute(Sql.named(query), parameters: sqlParams);
  final list = results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'task': row['task_id'],
      'reason': row['reason'] ?? 'other',
      'title': row['title'] ?? '',
      'description': row['description'] ?? '',
      'status': row['status'] ?? 'open',
      'resolution': row['resolution'] ?? '',
      'opened_at': row['opened_at'] != null ? (row['opened_at'] as DateTime).toIso8601String() : '',
      'resolved_at': row['resolved_at'] != null ? (row['resolved_at'] as DateTime).toIso8601String() : null,
    };
  }).toList();

  return jsonResponse(list);
}

Future<Response> createDisputeHandler(Request request) async {
  final userId = getUserId(request);
  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;

  final taskIdVal = body['task'];
  final againstIdVal = body['against'];
  final reason = body['reason']?.toString() ?? 'other';
  final title = body['title']?.toString() ?? '';
  final description = body['description']?.toString() ?? '';

  if (taskIdVal == null) return errorResponse('task ID is required', statusCode: 400);
  final taskId = int.tryParse(taskIdVal.toString()) ?? 0;
  final againstId = int.tryParse(againstIdVal?.toString() ?? '');

  final res = await dbPool.execute(
    Sql.named('INSERT INTO governance_dispute (reason, title, description, status, resolution, opened_at, updated_at, resolved_at, against_id, opened_by_id, task_id) '
              'VALUES (@reason, @title, @description, \'open\', \'\', NOW(), NOW(), null, @againstId, @openedBy, @taskId) RETURNING id'),
    parameters: {
      'reason': reason,
      'title': title,
      'description': description,
      'againstId': againstId,
      'openedBy': userId,
      'taskId': taskId,
    },
  );
  final newId = res[0][0] as int;

  await createAuditLog(
    actorId: userId,
    action: 'dispute_created',
    entityType: 'dispute',
    entityId: newId.toString(),
    summary: title,
    metadata: {'task_id': taskId},
    ipAddress: null,
  );

  return Response(201, body: jsonEncode({
    'id': newId,
    'task': taskId,
    'reason': reason,
    'title': title,
    'description': description,
    'status': 'open',
  }), headers: {'content-type': 'application/json'});
}

Future<Response> disputeDetailHandler(Request request, String idStr) async {
  final userId = getUserId(request);
  final role = getUserRole(request);
  final id = int.tryParse(idStr) ?? 0;

  final results = await dbPool.execute(Sql.named('SELECT * FROM governance_dispute WHERE id = @id'), parameters: {'id': id});
  if (results.isEmpty) return errorResponse('Dispute not found', statusCode: 404);

  final row = results[0].toColumnMap();
  if (role != 'ADMIN' && row['opened_by_id'] != userId && row['against_id'] != userId) {
    return errorResponse('Not authorized', statusCode: 403);
  }

  // fetch evidence
  final evQuery = await dbPool.execute(Sql.named('SELECT * FROM governance_dispute_evidence WHERE dispute_id = @id'), parameters: {'id': id});
  final evidence = evQuery.map((r) {
    final evRow = r.toColumnMap();
    return {
      'id': evRow['id'],
      'file_url': evRow['file_url'] ?? '',
      'file_name': evRow['file_name'] ?? '',
      'file_type': evRow['file_type'] ?? 'file',
      'note': evRow['note'] ?? '',
      'uploaded_by': evRow['uploaded_by_id'],
      'created_at': evRow['created_at'] != null ? (evRow['created_at'] as DateTime).toIso8601String() : '',
    };
  }).toList();

  return jsonResponse({
    'id': row['id'],
    'task': row['task_id'],
    'reason': row['reason'] ?? 'other',
    'title': row['title'] ?? '',
    'description': row['description'] ?? '',
    'status': row['status'] ?? 'open',
    'resolution': row['resolution'] ?? '',
    'opened_at': row['opened_at'] != null ? (row['opened_at'] as DateTime).toIso8601String() : '',
    'resolved_at': row['resolved_at'] != null ? (row['resolved_at'] as DateTime).toIso8601String() : null,
    'evidence': evidence,
  });
}

Future<Response> disputeEvidenceHandler(Request request, String idStr) async {
  final userId = getUserId(request);
  final id = int.tryParse(idStr) ?? 0;

  final results = await dbPool.execute(Sql.named('SELECT * FROM governance_dispute WHERE id = @id'), parameters: {'id': id});
  if (results.isEmpty) return errorResponse('Dispute not found', statusCode: 404);

  final row = results[0].toColumnMap();
  if (row['opened_by_id'] != userId && row['against_id'] != userId) {
    return errorResponse('Not authorized', statusCode: 403);
  }

  final body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
  final fileUrl = body['file_url']?.toString() ?? '';
  final fileName = body['file_name']?.toString() ?? '';
  final fileType = body['file_type']?.toString() ?? 'file';
  final note = body['note']?.toString() ?? '';

  final res = await dbPool.execute(
    Sql.named('INSERT INTO governance_dispute_evidence (file_url, storage_key, file_name, file_type, content_type, note, created_at, dispute_id, uploaded_by_id) '
              'VALUES (@fileUrl, \'\', @fileName, @fileType, \'\', @note, NOW(), @disputeId, @userId) RETURNING id'),
    parameters: {
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'note': note,
      'disputeId': id,
      'userId': userId,
    },
  );

  return Response(201, body: jsonEncode({
    'id': res[0][0],
    'file_url': fileUrl,
    'file_name': fileName,
    'file_type': fileType,
    'note': note,
  }), headers: {'content-type': 'application/json'});
}

Future<Response> listAuditLogsHandler(Request request) async {
  final userId = getUserId(request);
  final role = getUserRole(request);

  var query = 'SELECT * FROM governance_audit_log';
  final sqlParams = <String, dynamic>{};

  if (role != 'ADMIN') {
    query += ' WHERE actor_id = @userId';
    sqlParams['userId'] = userId;
  }
  query += ' ORDER BY created_at DESC LIMIT 100';

  final results = await dbPool.execute(Sql.named(query), parameters: sqlParams);
  final list = results.map((r) {
    final row = r.toColumnMap();
    return {
      'id': row['id'],
      'action': row['action'],
      'entity_type': row['entity_type'],
      'entity_id': row['entity_id'],
      'summary': row['summary'] ?? '',
      'metadata': parseJsonField(row['metadata']) ?? {},
      'ip_address': row['ip_address'],
      'created_at': row['created_at'] != null ? (row['created_at'] as DateTime).toIso8601String() : '',
    };
  }).toList();

  return jsonResponse(list);
}

Future<Response> platformSettingsHandler(Request request) async {
  final results = await dbPool.execute('SELECT * FROM governance_platform_setting');
  final map = <String, dynamic>{};
  for (final r in results) {
    final row = r.toColumnMap();
    map[row['key']] = parseJsonField(row['value']);
  }
  return jsonResponse(map);
}

// ─── MAIN APP ENTRYPOINT ───────────────────────────────────────────────────

void main() async {
  final env = DotEnv()..load(['../.env']);
  final dbUrl = env['DATABASE_URL'];
  secretKey = env['SECRET_KEY'] ?? r'django-insecure-(d4x++bp=mw#k!cmxm3^+jb3qsv!qwz)z(5^jr=c91$0i%dce$';

  if (dbUrl == null) {
    print('Error: DATABASE_URL environment variable is missing.');
    exit(1);
  }

  print('Connecting to Neon PostgreSQL Database...');
  dbPool = Pool.withUrl(dbUrl);

  final router = Router();

  // Authentication
  router.post('/api/auth/login/', loginHandler);
  router.post('/api/auth/token/refresh/', tokenRefreshHandler);
  router.post('/api/auth/otp/request/', requestOtpHandler);
  router.post('/api/auth/otp/verify/', verifyOtpHandler);
  router.post('/api/auth/register/client/', registerClientHandler);
  router.post('/api/auth/register/technician/', registerClientHandler); // map both client and tech if requested
  // Re-map correct handlers for specificity
  router.post('/api/auth/register/technician/', registerTechnicianHandler);
  router.post('/api/auth/register/company/', registerCompanyHandler);
  router.get('/api/auth/me/', getMeHandler);
  router.patch('/api/auth/me/', updateMeHandler);
  router.get('/api/auth/users/', listUsersHandler);
  router.get('/api/auth/users/<userId>/', userPublicProfileHandler);

  // Portfolio
  router.get('/api/auth/portfolio/', listPortfolioItemsHandler);
  router.post('/api/auth/portfolio/', createPortfolioItemHandler);
  router.delete('/api/auth/portfolio/<itemId>/', deletePortfolioItemHandler);

  // Saved Pros
  router.get('/api/auth/saved-pros/', listSavedProfessionalsHandler);
  router.post('/api/auth/saved-pros/', createSavedProfessionalHandler);
  router.delete('/api/auth/saved-pros/<professionalId>/', deleteSavedProfessionalHandler);

  // Technician Services
  router.get('/api/auth/technician-services/', listTechnicianServicesHandler);
  router.post('/api/auth/technician-services/', createTechnicianServiceHandler);
  router.get('/api/auth/technician-services/<serviceId>/', technicianServiceDetailHandler);
  router.patch('/api/auth/technician-services/<serviceId>/', technicianServiceDetailHandler);
  router.delete('/api/auth/technician-services/<serviceId>/', technicianServiceDetailHandler);

  // Admin User Controls
  router.get('/api/auth/admin/users/', adminListUsersHandler);
  router.post('/api/auth/admin/users/<userId>/verify/', adminVerifyUserHandler);
  router.post('/api/auth/admin/users/<userId>/suspend/', adminSuspendUserHandler);
  router.get('/api/auth/admin/tasks/', adminListTasksHandler);

  // Tasks
  router.get('/api/tasks/', listTasksHandler);
  router.post('/api/tasks/create/', createTaskHandler);
  router.get('/api/tasks/my/', myTasksHandler);
  router.get('/api/tasks/categories/', categoryListHandler);
  router.get('/api/tasks/skills/', skillListHandler);
  router.get('/api/tasks/<id>/', taskDetailHandler);
  router.post('/api/tasks/<id>/publish/', taskPublishHandler);
  router.post('/api/tasks/<id>/complete/', taskCompleteHandler);
  router.post('/api/tasks/<id>/cancel/', taskCancelHandler);

  // Bids
  router.get('/api/tasks/<id>/bids/', taskBidsHandler);
  router.post('/api/tasks/<id>/bids/', taskBidsHandler);
  router.get('/api/tasks/bids/my/', myBidsHandler);
  router.get('/api/tasks/bids/<id>/', bidDetailHandler);
  router.post('/api/tasks/bids/<id>/withdraw/', bidWithdrawHandler);

  // Wallet
  router.get('/api/wallet/', walletDetailHandler);
  router.get('/api/wallet/transactions/', listTransactionsHandler);
  router.get('/api/wallet/admin/transactions/', adminTransactionListHandler);
  router.post('/api/wallet/withdraw/', withdrawFundsHandler);
  router.post('/api/wallet/deposit/', depositEscrowHandler);
  router.post('/api/wallet/release-escrow/<taskId>/', releaseEscrowHandler);

  // Messaging
  router.get('/api/conversations/', listConversationsHandler);
  router.post('/api/conversations/create/', createConversationHandler);
  router.get('/api/conversations/<convId>/', conversationDetailHandler);
  router.post('/api/conversations/<convId>/messages/', sendMessageHandler);

  // Companies
  router.get('/api/company/', listCompaniesHandler);
  router.get('/api/company/profile/', getCompanyProfileHandler);
  router.patch('/api/company/profile/', updateCompanyProfileHandler);
  router.get('/api/company/projects/', companyProjectsHandler);
  router.post('/api/company/projects/', companyProjectsHandler);
  router.get('/api/company/certifications/', companyCertificationsHandler);
  router.post('/api/company/certifications/', companyCertificationsHandler);
  router.get('/api/company/services/', companyServicesHandler);
  router.post('/api/company/services/', companyServicesHandler);
  router.delete('/api/company/services/<id>/', deleteCompanyServiceHandler);
  router.get('/api/company/<id>/', companyPublicProfileHandler);
  router.post('/api/company/<companyId>/reviews/', addCompanyReviewHandler);

  // Search
  router.get('/api/search/', searchEverythingHandler);

  // Governance
  router.get('/api/governance/public-pages/', publicCmsPagesHandler);
  router.get('/api/governance/public-pages/<slug>/', publicCmsPageDetailHandler);
  router.get('/api/governance/notifications/', listNotificationsHandler);
  router.post('/api/governance/notifications/<id>/read/', markNotificationReadHandler);
  router.get('/api/governance/disputes/', listDisputesHandler);
  router.post('/api/governance/disputes/create/', createDisputeHandler);
  router.get('/api/governance/disputes/<id>/', disputeDetailHandler);
  router.post('/api/governance/disputes/<id>/evidence/', disputeEvidenceHandler);
  router.get('/api/governance/audit-logs/', listAuditLogsHandler);
  router.get('/api/governance/platform-settings/', platformSettingsHandler);

  // Pipeline with middlewares
  final pipeline = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addMiddleware(authMiddleware(secretKey))
      .addHandler(router);

  final portStr = Platform.environment['PORT'] ?? '8000';
  final port = int.tryParse(portStr) ?? 8000;
  final server = await io.serve(pipeline, '0.0.0.0', port);
  print('Dart Shelf server running at http://${server.address.host}:${server.port}');
}
