import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._privateConstructor();

  static final ApiService instance = ApiService._privateConstructor();

  String? ipOverride;
  bool _showingIpDialog = false;

  String get baseUrl {
    if (kIsWeb) {
      var host = Uri.base.host;
      if (host == 'localhost') {
        host = '127.0.0.1';
      }
      if (host.isNotEmpty) {
        return 'http://$host:8000/api';
      }
    }
    if (ipOverride != null && ipOverride!.isNotEmpty) {
      return 'http://$ipOverride:8000/api';
    }
    // Fallback for non-web environments (use computer local IP for physical devices on same Wi-Fi)
    return 'http://192.168.0.108:8000/api';
  }

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;

  void setTokens(String? access, String? refresh) {
    _accessToken = access;
    _refreshToken = refresh;
    SharedPreferences.getInstance().then((prefs) {
      if (access != null) {
        prefs.setString('access_token', access);
      } else {
        prefs.remove('access_token');
      }
      if (refresh != null) {
        prefs.setString('refresh_token', refresh);
      } else {
        prefs.remove('refresh_token');
      }
    });
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('access_token');
      prefs.remove('refresh_token');
      prefs.remove('user_role');
    });
  }

  Map<String, String> _getHeaders({bool requireAuth = true, bool isMultipart = false}) {
    final Map<String, String> headers = {};
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }
    if (requireAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  void _showIpOverrideDialog() {
    if (_showingIpDialog) return;
    _showingIpDialog = true;

    final controller = TextEditingController(text: ipOverride ?? '192.168.0.108');

    Get.dialog(
      AlertDialog(
        title: const Text('Backend IP Config'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Could not connect to the backend. Please enter your PC\'s local IP address:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: 'e.g. 192.168.1.15',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              _showingIpDialog = false;
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newIp = controller.text.trim();
              if (newIp.isNotEmpty) {
                ipOverride = newIp;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('backend_ip_override', newIp);
              }
              Get.back();
              _showingIpDialog = false;
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4500),
              foregroundColor: Colors.white,
            ),
            child: const Text('Save & Retry'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<http.Response> _wrapRequest(Future<http.Response> Function() reqFn) async {
    try {
      return await reqFn();
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('SocketException') || errStr.contains('Connection failed') || errStr.contains('Connection timed out') || errStr.contains('Operation timed out') || errStr.contains('timed out')) {
        _showIpOverrideDialog();
      }
      rethrow;
    }
  }

  Future<http.Response> get(String path, {bool requireAuth = true}) async {
    return _wrapRequest(() async {
      final url = Uri.parse('$baseUrl$path');
      final response = await http.get(url, headers: _getHeaders(requireAuth: requireAuth));
      return response;
    });
  }

  Future<http.Response> post(String path, Map<String, dynamic> body, {bool requireAuth = true}) async {
    return _wrapRequest(() async {
      final url = Uri.parse('$baseUrl$path');
      final response = await http.post(
        url,
        headers: _getHeaders(requireAuth: requireAuth),
        body: jsonEncode(body),
      );
      return response;
    });
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body, {bool requireAuth = true}) async {
    return _wrapRequest(() async {
      final url = Uri.parse('$baseUrl$path');
      final response = await http.patch(
        url,
        headers: _getHeaders(requireAuth: requireAuth),
        body: jsonEncode(body),
      );
      return response;
    });
  }

  Future<http.Response> delete(String path, {bool requireAuth = true}) async {
    return _wrapRequest(() async {
      final url = Uri.parse('$baseUrl$path');
      final response = await http.delete(url, headers: _getHeaders(requireAuth: requireAuth));
      return response;
    });
  }

  // ─── AUTHENTICATION ENDPOINTS ──────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await post('/auth/login/', {
      'username': username,
      'password': password,
    }, requireAuth: false);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setTokens(data['access'], data['refresh']);
      return data;
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to log in.');
    }
  }

  Future<void> registerClient({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final response = await post('/auth/register/client/', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'phone': phone,
    }, requireAuth: false);

    if (response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<void> registerTechnician({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final response = await post('/auth/register/technician/', {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'phone': phone,
    }, requireAuth: false);

    if (response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<void> registerCompany({
    required String companyName,
    required String email,
    required String password,
    required String phone,
    String? registrationNumber,
    String? taxId,
    String? industry,
  }) async {
    final response = await post('/auth/register/company/', {
      'company_name': companyName,
      'email': email,
      'password': password,
      'phone': phone,
      if (registrationNumber != null) 'registration_number': registrationNumber,
      if (taxId != null) 'tax_id': taxId,
      if (industry != null) 'industry': industry,
    }, requireAuth: false);

    if (response.statusCode != 201) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<Map<String, dynamic>> fetchProfile() async {
    final response = await get('/auth/me/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load profile.');
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final response = await patch('/auth/me/', body);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to update profile.');
    }
  }

  // ─── TASK ENDPOINTS ────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchTasks({String? category, String? query}) async {
    String queryParams = '';
    final List<String> params = [];
    if (category != null && category.isNotEmpty) {
      params.add('category=${Uri.encodeComponent(category.toLowerCase())}');
    }
    if (query != null && query.isNotEmpty) {
      params.add('q=${Uri.encodeComponent(query)}');
    }
    if (params.isNotEmpty) {
      queryParams = '?' + params.join('&');
    }

    final response = await get('/tasks/$queryParams', requireAuth: false);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Failed to fetch tasks.');
    }
  }

  Future<List<dynamic>> fetchMyTasks() async {
    final response = await get('/tasks/my/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user tasks.');
    }
  }

  Future<Map<String, dynamic>> fetchTaskDetail(int taskId) async {
    final response = await get('/tasks/$taskId/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch task details.');
    }
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> taskData) async {
    final response = await post('/tasks/create/', taskData);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<Map<String, dynamic>> updateTask(int taskId, Map<String, dynamic> taskData) async {
    final response = await patch('/tasks/$taskId/', taskData);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to update task.');
    }
  }

  Future<Map<String, dynamic>> publishTask(int taskId) async {
    final response = await post('/tasks/$taskId/publish/', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to publish task.');
    }
  }

  Future<Map<String, dynamic>> completeTask(int taskId) async {
    final response = await post('/tasks/$taskId/complete/', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to complete task.');
    }
  }

  Future<Map<String, dynamic>> submitWork(int taskId) async {
    final response = await post('/tasks/$taskId/submit-work/', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to submit work.');
    }
  }

  Future<Map<String, dynamic>> cancelTask(int taskId) async {
    final response = await post('/tasks/$taskId/cancel/', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to cancel task.');
    }
  }

  Future<Map<String, dynamic>> deleteTask(int taskId) async {
    final response = await post('/tasks/$taskId/delete/', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to delete task.');
    }
  }

  // ─── BIDDING ENDPOINTS ─────────────────────────────────────────────────────

  Future<List<dynamic>> fetchTaskBids(int taskId) async {
    final response = await get('/tasks/$taskId/bids/', requireAuth: false);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load bids for this task.');
    }
  }

  Future<Map<String, dynamic>> submitBid({
    required int taskId,
    required double amount,
    required String timeline,
    required String message,
  }) async {
    final response = await post('/tasks/$taskId/bids/', {
      'amount': amount,
      'amount_type': 'fixed',
      'duration': timeline,
      'message': message,
      'extra_notes': '',
    });

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<List<dynamic>> fetchMyBids() async {
    final response = await get('/tasks/bids/my/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user bids.');
    }
  }

  // ─── WALLET & ESCROW ENDPOINTS ─────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchWallet() async {
    final response = await get('/wallet/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch wallet info.');
    }
  }

  Future<List<dynamic>> fetchTransactions() async {
    final response = await get('/wallet/transactions/');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'] ?? [];
    } else {
      throw Exception('Failed to load transaction ledger.');
    }
  }

  Future<Map<String, dynamic>> requestWithdrawal(double amount, String method) async {
    final response = await post('/wallet/withdraw/', {
      'amount': amount,
      'account_details': {'method': method},
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<Map<String, dynamic>> depositEscrow({
    required int taskId,
    required int bidId,
    required double amount,
  }) async {
    final response = await post('/wallet/deposit/', {
      'task_id': taskId,
      'bid_id': bidId,
      'amount': amount,
    });

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to deposit escrow.');
    }
  }

  Future<Map<String, dynamic>> releaseEscrow(int taskId) async {
    final response = await post('/wallet/release-escrow/$taskId/', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to release escrow.');
    }
  }

  // ─── MESSAGING ENDPOINTS ───────────────────────────────────────────────────

  Future<List<dynamic>> fetchConversations() async {
    final response = await get('/conversations/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load conversations.');
    }
  }

  Future<Map<String, dynamic>> fetchConversationDetail(int conversationId) async {
    final response = await get('/conversations/$conversationId/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load message thread details.');
    }
  }

  Future<Map<String, dynamic>> sendMessage(int conversationId, String text, {String? attachmentUrl, String? attachmentName}) async {
    final response = await post('/conversations/$conversationId/messages/', {
      'text': text,
      if (attachmentUrl != null) 'attachment_url': attachmentUrl,
      if (attachmentName != null) 'attachment_name': attachmentName,
    });

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message.');
    }
  }

  Future<void> deleteConversation(int conversationId) async {
    final response = await delete('/conversations/$conversationId/');
    if (response.statusCode != 200) {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to delete conversation.');
    }
  }

  Future<Map<String, dynamic>> createConversation(int otherUserId) async {
    final response = await post('/conversations/create/', {
      'other_user_id': otherUserId,
    });

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to open conversation.');
    }
  }

  // ─── SEARCH & EXTRA ENDPOINTS ──────────────────────────────────────────────

  Future<List<dynamic>> fetchCompanies() async {
    final response = await get('/company/', requireAuth: false);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load companies.');
    }
  }

  Future<List<dynamic>> fetchPublicUsers({String? role}) async {
    final path = role != null ? '/auth/users/?role=${role.toUpperCase()}' : '/auth/users/';
    final response = await get(path, requireAuth: false);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users.');
    }
  }

  Future<List<dynamic>> fetchPublicCmsPages() async {
    final response = await get('/governance/public-pages/', requireAuth: false);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load help pages.');
    }
  }

  Future<Map<String, dynamic>> createDispute({
    required int taskId,
    required String reason,
    required String title,
    required String description,
    int? againstId,
  }) async {
    final response = await post('/governance/disputes/create/', {
      'task': taskId,
      if (againstId != null) 'against': againstId,
      'reason': reason,
      'title': title,
      'description': description,
    });
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<Map<String, dynamic>> updateCompanyProfile(Map<String, dynamic> data) async {
    final response = await patch('/company/profile/', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<Map<String, dynamic>> updateTechnicianProfile(Map<String, dynamic> data) async {
    final response = await patch('/auth/me/', data);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<List<dynamic>> fetchPortfolioItems() async {
    final response = await get('/auth/portfolio/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch portfolio items.');
    }
  }

  Future<Map<String, dynamic>> addPortfolioItem(Map<String, dynamic> itemData) async {
    final response = await post('/auth/portfolio/', itemData);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<void> deletePortfolioItem(int itemId) async {
    final response = await delete('/auth/portfolio/$itemId/');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete portfolio item.');
    }
  }

  Future<Map<String, dynamic>> publishTechnicianService(Map<String, dynamic> serviceData) async {
    final response = await post('/auth/technician-services/', serviceData);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<Map<String, dynamic>> publishCompanyService(Map<String, dynamic> serviceData) async {
    final response = await post('/company/services/', serviceData);
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? _parseValidationErrors(err));
    }
  }

  Future<List<dynamic>> fetchTechnicianServices() async {
    final response = await get('/auth/technician-services/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch technician services.');
    }
  }

  Future<List<dynamic>> fetchCompanyServices() async {
    final response = await get('/company/services/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch company services.');
    }
  }

  Future<Map<String, dynamic>> searchEverything({
    String? query,
    String? category,
    String? location,
    String? tab,
    String? type,
  }) async {
    final List<String> params = [];
    if (query != null && query.isNotEmpty) {
      params.add('q=${Uri.encodeComponent(query)}');
    }
    if (category != null && category.isNotEmpty) {
      params.add('category=${Uri.encodeComponent(category)}');
    }
    if (location != null && location.isNotEmpty) {
      params.add('location=${Uri.encodeComponent(location)}');
    }
    if (tab != null && tab.isNotEmpty) {
      params.add('tab=${Uri.encodeComponent(tab)}');
    }
    if (type != null && type.isNotEmpty) {
      params.add('type=${Uri.encodeComponent(type)}');
    }
    final queryStr = params.isNotEmpty ? '?' + params.join('&') : '';
    final response = await get('/search/$queryStr', requireAuth: false);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Search request failed.');
    }
  }

  Future<Map<String, dynamic>> fetchCompanyProfile() async {
    final response = await get('/company/profile/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load company profile.');
    }
  }

  Future<Map<String, dynamic>> requestPhoneOTP({String? phone, String? email, String purpose = 'verification'}) async {
    final response = await post('/auth/otp/request/', {
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      'purpose': purpose,
    }, requireAuth: false);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['detail'] ?? err['error'] ?? 'Failed to request OTP.');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to request OTP.');
      }
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required int challengeId,
    required String code,
    required String newPassword,
  }) async {
    final response = await post('/auth/reset-password/', {
      'challenge_id': challengeId,
      'code': code,
      'new_password': newPassword,
    }, requireAuth: false);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      try {
        final err = jsonDecode(response.body);
        throw Exception(err['detail'] ?? err['error'] ?? 'Failed to reset password.');
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Failed to reset password.');
      }
    }
  }

  Future<Map<String, dynamic>> verifyPhoneOTP(int challengeId, String code) async {
    final response = await post('/auth/otp/verify/', {
      'challenge_id': challengeId,
      'code': code,
    }, requireAuth: false);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Invalid verification code.');
    }
  }

  Future<List<dynamic>> fetchAdminUsers() async {
    final response = await get('/auth/admin/users/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user directories for admin.');
    }
  }

  Future<void> adminVerifyUser(int userId) async {
    final response = await post('/auth/admin/users/$userId/verify/', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to verify user.');
    }
  }

  Future<void> adminSuspendUser(int userId) async {
    final response = await post('/auth/admin/users/$userId/suspend/', {});
    if (response.statusCode != 200) {
      throw Exception('Failed to suspend/unsuspend user.');
    }
  }

  Future<List<dynamic>> fetchAdminTasks() async {
    final response = await get('/auth/admin/tasks/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load tasks for admin review.');
    }
  }

  Future<List<dynamic>> fetchSavedProfessionals() async {
    final response = await get('/auth/saved-pros/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load saved professionals.');
    }
  }

  Future<void> saveProfessional(int professionalId) async {
    final response = await post('/auth/saved-pros/', {'professional_id': professionalId});
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save professional.');
    }
  }

  Future<void> unsaveProfessional(int professionalId) async {
    final response = await delete('/auth/saved-pros/$professionalId/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to unsave professional.');
    }
  }

  Future<List<dynamic>> fetchSavedServices() async {
    final response = await get('/auth/saved-services/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load saved services.');
    }
  }

  Future<void> saveService(int serviceId) async {
    final response = await post('/auth/saved-services/', {'service_id': serviceId});
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to save service.');
    }
  }

  Future<void> unsaveService(int serviceId) async {
    final response = await delete('/auth/saved-services/$serviceId/');
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to unsave service.');
    }
  }

  // ─── COMPANY PROJECTS ────────────────────────────────────────────────────────

  Future<List<dynamic>> fetchClientContracts() async {
    final response = await get('/client/contracts/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to load client contracts.');
    }
  }

  Future<Map<String, dynamic>> fundEscrowPayment(String projectId) async {
    final response = await patch('/client/contracts/$projectId/fund/', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fund escrow.');
    }
  }

  Future<Map<String, dynamic>> releaseEscrowPayment(String projectId) async {
    final response = await patch('/client/contracts/$projectId/release/', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to release escrow.');
    }
  }

  Future<List<dynamic>> searchClients(String query) async {
    final response = await get('/company/search-clients/?q=$query');
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    } else {
      throw Exception('Failed to search clients.');
    }
  }

  Future<List<dynamic>> fetchCompanyProjects() async {
    final response = await get('/company/projects/');
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load company projects.');
    }
  }

  Future<Map<String, dynamic>> createCompanyProject(Map<String, dynamic> body) async {
    final response = await post('/company/projects/', body);
    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to create project.');
    }
  }

  Future<void> deleteCompanyProject(String projectId) async {
    final response = await http.delete(Uri.parse('$baseUrl/company/projects/$projectId/'), headers: _getHeaders());
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete project.');
    }
  }

  Future<Map<String, dynamic>> updateCompanyProject(String id, Map<String, dynamic> body) async {
    final url = Uri.parse('$baseUrl/company/projects/$id/');
    final response = await http.patch(
      url,
      headers: _getHeaders(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['error'] ?? 'Failed to update project.');
    }
  }

  // ─── HELPER FOR VALIDATION ERRORS ──────────────────────────────────────────

  String _parseValidationErrors(Map<String, dynamic> errors) {
    final List<String> list = [];
    errors.forEach((key, value) {
      if (value is List) {
        list.add('$key: ${value.join(", ")}');
      } else {
        list.add('$key: $value');
      }
    });
    return list.join('\n');
  }
}
