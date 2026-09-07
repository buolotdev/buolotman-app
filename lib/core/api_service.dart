import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const serverBase =
      'http://BoulotMan-API-env.eba-exncce63.eu-north-1.elasticbeanstalk.com';
  static const _apiBase =
      '$serverBase/api';
  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_apiBase/auth/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': email.trim().toLowerCase(),
        'password': password,
      }),
    );
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _message(data, 'Unable to sign in. Please check your details.'),
        response.statusCode,
      );
    }
    final access = data['access'];
    final refresh = data['refresh'];
    if (access is! String || refresh is! String) {
      throw ApiException(
        'The server returned an invalid login response.',
        response.statusCode,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    if (data['role'] is String)
      await prefs.setString('user_role', data['role'] as String);
    return data;
  }

  Future<Map<String, dynamic>> googleLogin({
    required String token,
    String? role,
    bool signup = false,
  }) async {
    final payload = <String, dynamic>{'token': token};
    if (role != null && role.isNotEmpty) payload['role'] = role.toUpperCase();
    if (signup) payload['flow'] = 'signup';
    final response = await http.post(
      Uri.parse('$_apiBase/auth/google-login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _message(data, 'Google sign-in failed.'),
        response.statusCode,
      );
    }
    final access = data['access'];
    final refresh = data['refresh'];
    if (access is! String || refresh is! String) {
      throw const ApiException(
        'The server returned an invalid Google login response.',
        500,
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    await prefs.setString(_refreshKey, refresh);
    if (data['role'] is String)
      await prefs.setString('user_role', data['role'] as String);
    return data;
  }

  Future<void> register({
    required String role,
    required Map<String, dynamic> data,
  }) async {
    final endpoint = switch (role) {
      'technician' => 'register/technician',
      'company' => 'register/company',
      _ => 'register/client',
    };
    final response = await http.post(
      Uri.parse('$_apiBase/auth/$endpoint/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    final decoded = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _message(
          decoded,
          'We could not create your account. Please try again.',
        ),
        response.statusCode,
      );
    }
  }

  Future<Map<String, dynamic>> profile() async {
    final token = await accessToken();
    final response = await http.get(
      Uri.parse('$_apiBase/auth/me/'),
      headers: {'Authorization': 'Bearer $token'},
    );
    final data = _decode(response);
    if (response.statusCode != 200) {
      throw ApiException(
        _message(data, 'Unable to load your profile.'),
        response.statusCode,
      );
    }
    return data;
  }

  Future<dynamic> publicUserProfile(dynamic userId) async => _getAny('auth/users/$userId/');

  String resolveImageUrl(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) return raw;
    return '$serverBase${raw.startsWith('/') ? raw : '/$raw'}';
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> values) async {
    final token = await accessToken();
    final response = await http.patch(Uri.parse('$_apiBase/auth/me/'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(values));
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException('Unable to save your profile details.', response.statusCode);
    return data;
  }

  Future<dynamic> changePassword(Map<String, dynamic> values) async => _postAny('auth/change-password/', values);

  Future<String> uploadAvatarBytes({required List<int> bytes, required String filename}) async {
    final token = await accessToken();
    final extension = filename.toLowerCase().split('.').last;
    final mime = <String, MediaType>{'jpg': MediaType('image', 'jpeg'), 'jpeg': MediaType('image', 'jpeg'), 'png': MediaType('image', 'png'), 'webp': MediaType('image', 'webp'), 'gif': MediaType('image', 'gif')}[extension];
    final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/uploads/avatar/'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: mime));
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException('Unable to upload your profile picture.', response.statusCode);
    final url = data['avatar_url'];
    if (url is! String || url.isEmpty) throw const ApiException('The profile picture upload returned no URL.', 500);
    return url;
  }

  Future<String> uploadBannerBytes({required List<int> bytes, required String filename}) async {
    final token = await accessToken();
    final extension = filename.toLowerCase().split('.').last;
    final mime = <String, MediaType>{
      'jpg': MediaType('image', 'jpeg'), 'jpeg': MediaType('image', 'jpeg'),
      'png': MediaType('image', 'png'), 'webp': MediaType('image', 'webp'),
      'gif': MediaType('image', 'gif'),
    }[extension];
    final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/uploads/banner/'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: mime));
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Unable to upload your profile banner.', response.statusCode);
    }
    final url = data['banner_url'];
    if (url is! String || url.isEmpty) throw const ApiException('The banner upload returned no URL.', 500);
    return url;
  }

  Future<String> uploadPortfolioBytes({required List<int> bytes, required String filename}) async {
    final token = await accessToken();
    final ext = filename.toLowerCase().split('.').last;
    final mime = <String, MediaType>{'jpg': MediaType('image', 'jpeg'), 'jpeg': MediaType('image', 'jpeg'), 'png': MediaType('image', 'png'), 'webp': MediaType('image', 'webp')}[ext];
    final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/uploads/portfolio/'))..headers['Authorization'] = 'Bearer $token'..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: mime));
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException('Unable to upload portfolio image.', response.statusCode);
    final url = data['image_url'];
    if (url is! String || url.isEmpty) throw const ApiException('Portfolio upload returned no URL.', 500);
    return url;
  }

  Future<List<dynamic>> portfolioItems() async => _getList('auth/portfolio/');
  Future<void> createPortfolio(Map<String, dynamic> values) async { final token = await accessToken(); final response = await http.post(Uri.parse('$_apiBase/auth/portfolio/'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(values)); final data = _decode(response); if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(data, 'Unable to save portfolio project.'), response.statusCode); }
  Future<void> deletePortfolio(dynamic id) async => _deleteAny('auth/portfolio/$id/');

  Future<Map<String, dynamic>> uploadTechnicianDocumentBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    final token = await accessToken();
    final extension = filename.toLowerCase().split('.').last;
    final mime = <String, MediaType>{
      'jpg': MediaType('image', 'jpeg'), 'jpeg': MediaType('image', 'jpeg'),
      'png': MediaType('image', 'png'), 'webp': MediaType('image', 'webp'),
      'gif': MediaType('image', 'gif'), 'pdf': MediaType('application', 'pdf'),
    }[extension];
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_apiBase/uploads/document/'),
    )
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: mime));
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(data, 'Unable to upload this document.'), response.statusCode);
    }
    return data;
  }

  Future<Map<String, dynamic>> createTechnicianDocument({
    required String title,
    required String documentType,
    required String fileUrl,
  }) async {
    final token = await accessToken();
    final response = await http.post(
      Uri.parse('$_apiBase/auth/technician-documents/'),
      headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'document_type': documentType, 'file_url': fileUrl}),
    );
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(_message(data, 'Unable to save this document.'), response.statusCode);
    }
    return data;
  }

  Future<List<dynamic>> technicianDocuments() async {
    final token = await accessToken();
    final response = await http.get(Uri.parse('$_apiBase/auth/technician-documents/'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 200) throw ApiException('Unable to load verification documents.', response.statusCode);
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : const [];
  }

  Future<void> deleteTechnicianDocument(dynamic id) async {
    await _deleteAny('auth/technician-documents/$id/');
  }

  Future<List<dynamic>> notifications() async {
    final data = await _getList('governance/notifications/');
    return data;
  }
  Future<dynamic> markNotificationRead(dynamic id) async => _postAny('governance/notifications/$id/read/', const {});
  Future<dynamic> markConversationRead(dynamic id) async => _patchAny('conversations/$id/read/', const {});
  Future<Map<String, dynamic>> uploadEvidenceBytes({required List<int> bytes, required String filename}) async {
    final token = await accessToken();
    final ext = filename.toLowerCase().split('.').last;
    final mime = <String, MediaType>{
      'jpg': MediaType('image', 'jpeg'), 'jpeg': MediaType('image', 'jpeg'),
      'png': MediaType('image', 'png'), 'webp': MediaType('image', 'webp'),
      'gif': MediaType('image', 'gif'), 'pdf': MediaType('application', 'pdf'),
      'mp4': MediaType('video', 'mp4'), 'mov': MediaType('video', 'quicktime'),
    }[ext];
    final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/uploads/service_media/'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: mime));
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException('Unable to upload evidence.', response.statusCode);
    return data;
  }
  Future<dynamic> submitDeliverable(dynamic taskId, Map<String, dynamic> values) async => _postAny('tasks/$taskId/submit-deliverable/', values);
  Future<dynamic> cancelTask(dynamic taskId) async => _postAny('tasks/$taskId/cancel/', const {});
  Future<List<dynamic>> savedProfessionals() async => _getList('auth/saved-pros/');
  Future<void> unsaveProfessional(dynamic id) async { await _deleteAny('auth/saved-pros/$id/'); }
  Future<List<dynamic>> supportTickets() async => _getList('governance/my-support/');
  Future<dynamic> createSupportTicket(Map<String, dynamic> values) async => _postAny('governance/my-support/', values);
  Future<dynamic> replySupportTicket(dynamic id, String body) async => _postAny('governance/my-support/$id/reply/', {'body': body});
  Future<Map<String, dynamic>> uploadMessageAttachment({required dynamic conversationId, required List<int> bytes, required String filename}) async {
    final token = await accessToken();
    final ext = filename.toLowerCase().split('.').last;
    final mime = <String, MediaType>{
      'jpg': MediaType('image', 'jpeg'), 'jpeg': MediaType('image', 'jpeg'), 'png': MediaType('image', 'png'), 'gif': MediaType('image', 'gif'), 'webp': MediaType('image', 'webp'),
      'mp4': MediaType('video', 'mp4'), 'mov': MediaType('video', 'quicktime'), 'pdf': MediaType('application', 'pdf'), 'doc': MediaType('application', 'msword'), 'docx': MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
    }[ext];
    final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/conversations/$conversationId/attachments/'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: mime));
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(data, 'Unable to upload this attachment.'), response.statusCode);
    return data;
  }

  Future<List<dynamic>> conversations() async {
    return _getList('conversations/');
  }
  Future<dynamic> conversation(dynamic id) async => _getAny('conversations/$id/');
  Future<dynamic> sendMessage(dynamic id, Map<String, dynamic> values) async => _postAny('conversations/$id/messages/', values);
  Future<dynamic> createConversation(dynamic participantId, {dynamic taskId}) async => _postAny('conversations/create/', {'participant_id': participantId, if (taskId != null) 'task_id': taskId});

  // These use the same endpoints as the web technician dashboard. The API
  // may return either a plain list or a paginated {results: [...]} object.
  Future<dynamic> tasks() async => _getAny('tasks/');
  Future<dynamic> myTasks() async => _getAny('tasks/my/');
  Future<dynamic> createTask(Map<String, dynamic> values) async => _postAny('tasks/create/', values);

  Future<Map<String, dynamic>> uploadTaskAttachmentBytes({required int taskId, required List<int> bytes, required String filename}) async {
    final token = await accessToken();
    final ext = filename.toLowerCase().split('.').last;
    final mime = <String, MediaType>{'jpg': MediaType('image', 'jpeg'), 'jpeg': MediaType('image', 'jpeg'), 'png': MediaType('image', 'png'), 'webp': MediaType('image', 'webp'), 'gif': MediaType('image', 'gif'), 'pdf': MediaType('application', 'pdf')}[ext];
    final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/uploads/task/$taskId/'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: mime));
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(data, 'Unable to upload task attachment.'), response.statusCode);
    return data;
  }
  Future<dynamic> taskBids(dynamic id) async => _getAny('tasks/$id/bids/');
  Future<dynamic> taskQuestions(dynamic id) async => _getAny('tasks/$id/questions/');
  Future<dynamic> acceptBid(dynamic id) async => _patchAny('tasks/bids/$id/', {'status': 'accepted'});
  Future<dynamic> rejectBid(dynamic id) async => _patchAny('tasks/bids/$id/', {'status': 'rejected'});
  Future<dynamic> myBids() async => _getAny('tasks/bids/my/');
  Future<dynamic> task(dynamic id) async => _getAny('tasks/$id/');
  Future<dynamic> submitBid(dynamic id, Map<String, dynamic> values) async => _postAny('tasks/$id/bids/', values);
  Future<dynamic> withdrawBid(dynamic id) async => _postAny('tasks/bids/$id/withdraw/', const {});
  Future<dynamic> updateTask(dynamic id, Map<String, dynamic> values) async => _patchAny('tasks/$id/', values);
  Future<dynamic> completeTask(dynamic id) async => _postAny('tasks/$id/complete/', const {});
  Future<dynamic> depositEscrow(Map<String, dynamic> values) async => _postAny('wallet/deposit/', values);
  Future<dynamic> releaseEscrow(dynamic taskId) async => _postAny('wallet/release-escrow/$taskId/', const {});
  Future<dynamic> createDispute(Map<String, dynamic> values) async => _postAny('governance/disputes/create/', values);
  Future<dynamic> withdrawFunds(Map<String, dynamic> values) async => _postAny('wallet/withdraw/', values);
  Future<dynamic> depositFunds(Map<String, dynamic> values) async => _postAny('wallet/add-funds/', values);
  Future<dynamic> campayWithdraw(Map<String, dynamic> values) async => _postAny('wallet/campay/withdraw/', values);
  Future<dynamic> campayCollect(Map<String, dynamic> values) async => _postAny('wallet/campay/collect/', values);
  Future<dynamic> campayCheckStatus(String reference) async => _getAny('wallet/campay/status/$reference/');
  Future<dynamic> technicianServices() async => _getAny('auth/technician-services/');
  Future<List<dynamic>> serviceCategories() async => _getList('tasks/categories/');
  Future<dynamic> createTechnicianService(Map<String, dynamic> values) async => _postAny('auth/technician-services/', values);
  Future<dynamic> updateTechnicianService(dynamic id, Map<String, dynamic> values) async => _patchAny('auth/technician-services/$id/', values);
  Future<dynamic> deleteTechnicianService(dynamic id) async => _deleteAny('auth/technician-services/$id/');
  Future<Map<String, dynamic>> uploadServiceMedia({required List<int> bytes, required String filename}) async {
    final token = await accessToken();
    final ext = filename.toLowerCase().split('.').last;
    final mime = <String, MediaType>{
      'jpg': MediaType('image', 'jpeg'), 'jpeg': MediaType('image', 'jpeg'), 'png': MediaType('image', 'png'), 'webp': MediaType('image', 'webp'), 'gif': MediaType('image', 'gif'),
      'mp4': MediaType('video', 'mp4'), 'mov': MediaType('video', 'quicktime'), 'avi': MediaType('video', 'x-msvideo'), 'pdf': MediaType('application', 'pdf'), 'doc': MediaType('application', 'msword'), 'docx': MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
    }[ext];
    final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/uploads/service_media/'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: mime));
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(data, 'Unable to upload service media.'), response.statusCode);
    return Map<String, dynamic>.from(data as Map);
  }

  // Company API. These methods mirror the backend company serializers exactly.
  // There are intentionally no project/service update methods because the
  // backend currently exposes create/list/delete only for those resources.
  Future<Map<String, dynamic>> companyProfile() async => _getMap('company/profile/');
  Future<Map<String, dynamic>> updateCompanyProfile(Map<String, dynamic> values) async => _patchMap('company/profile/', values);
  Future<List<dynamic>> companyProjects({String? status}) async => _getList('company/projects/${status == null ? '' : '?status=${Uri.encodeQueryComponent(status)}'}');
  Future<Map<String, dynamic>> createCompanyProject(Map<String, dynamic> values) async => _postMap('company/projects/', values);
  Future<List<dynamic>> companyServices() async => _getList('company/services/');
  Future<Map<String, dynamic>> createCompanyService(Map<String, dynamic> values) async => _postMap('company/services/', values);
  Future<void> deleteCompanyService(dynamic id) async => _deleteAny('company/services/$id/');
  Future<List<dynamic>> companyCertifications() async => _getList('company/certifications/');
  Future<Map<String, dynamic>> createCompanyCertification(Map<String, dynamic> values) async => _postMap('company/certifications/', values);
  Future<List<dynamic>> companyQuotes() async => _getList('company/quotes/');
  Future<Map<String, dynamic>> updateCompanyQuote(dynamic id, Map<String, dynamic> values) async => _patchMap('company/quotes/$id/', values);
  Future<List<dynamic>> companyActivities() async => _getList('company/activities/');
  Future<Map<String, dynamic>> submitCompanyQuote(dynamic companyId, Map<String, dynamic> values) async => _postMap('company/$companyId/quotes/', values);
  Future<Map<String, dynamic>> addCompanyReview(dynamic companyId, Map<String, dynamic> values) async => _postMap('company/$companyId/reviews/', values);
  Future<Map<String, dynamic>> publicCompanyProfile(dynamic companyId) async => _getMap('company/$companyId/');

  Future<String> uploadCompanyServiceImageBytes({required List<int> bytes, required String filename}) async {
    final token = await accessToken();
    final ext = filename.toLowerCase().split('.').last;
    final mime = <String, MediaType>{
      'jpg': MediaType('image', 'jpeg'), 'jpeg': MediaType('image', 'jpeg'),
      'png': MediaType('image', 'png'), 'webp': MediaType('image', 'webp'), 'gif': MediaType('image', 'gif'),
    }[ext];
    if (mime == null) throw const ApiException('Company service images must be JPG, PNG, WEBP, or GIF.', 400);
    if (bytes.length > 50 * 1024 * 1024) throw const ApiException('Company service images cannot exceed 50 MB.', 400);
    final request = http.MultipartRequest('POST', Uri.parse('$_apiBase/uploads/company_service/'))
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename, contentType: mime));
    final response = await http.Response.fromStream(await request.send());
    final data = _decode(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException(_message(data, 'Unable to upload company service image.'), response.statusCode);
    final url = data['image_url'];
    if (url is! String || url.isEmpty) throw const ApiException('The upload returned no image URL.', 500);
    return url;
  }

  Future<Map<String, dynamic>> wallet() async {
    final data = await _getMap('wallet/');
    return data;
  }

  Future<List<dynamic>> walletTransactions() async {
    final response = await _authenticated('wallet/transactions/');
    if (response.statusCode != 200) throw ApiException('Unable to load wallet transactions.', response.statusCode);
    final decoded = jsonDecode(response.body);
    if (decoded is Map && decoded['results'] is List) return decoded['results'] as List<dynamic>;
    return decoded is List ? decoded : const [];
  }

  Future<List<dynamic>> _getList(String path) async {
    final response = await _authenticated(path);
    if (response.statusCode != 200) throw ApiException('Unable to load this information.', response.statusCode);
    final decoded = jsonDecode(response.body);
    return decoded is List ? decoded : const [];
  }

  Future<Map<String, dynamic>> _postMap(String path, Map<String, dynamic> values) async {
    final data = await _postAny(path, values);
    if (data is! Map) throw const ApiException('The server returned an invalid response.', 500);
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> _patchMap(String path, Map<String, dynamic> values) async {
    final data = await _patchAny(path, values);
    if (data is! Map) throw const ApiException('The server returned an invalid response.', 500);
    return Map<String, dynamic>.from(data);
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    final response = await _authenticated(path);
    final data = _decode(response);
    if (response.statusCode != 200) throw ApiException(_message(data, 'Unable to load this information.'), response.statusCode);
    return data;
  }

  Future<dynamic> _getAny(String path) async {
    final response = await _authenticated(path);
    final data = _decodeDynamic(response);
    if (response.statusCode != 200) {
      throw ApiException('Unable to load dashboard information.', response.statusCode);
    }
    return data;
  }

  Future<dynamic> _postAny(String path, Map<String, dynamic> values) async {
    final token = await accessToken();
    final response = await http.post(Uri.parse('$_apiBase/$path'), headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'}, body: jsonEncode(values));
    final data = _decodeDynamic(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException('Unable to save this information.', response.statusCode);
    return data;
  }

  Future<dynamic> _patchAny(String path, Map<String, dynamic> values) async {
    final response = await http.patch(Uri.parse('$_apiBase/$path'), headers: {'Authorization': 'Bearer ${await accessToken()}', 'Content-Type': 'application/json'}, body: jsonEncode(values));
    final data = _decodeDynamic(response);
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException('Unable to update this information.', response.statusCode);
    return data;
  }

  Future<void> _deleteAny(String path) async {
    final response = await http.delete(Uri.parse('$_apiBase/$path'), headers: {'Authorization': 'Bearer ${await accessToken()}'});
    if (response.statusCode < 200 || response.statusCode >= 300) throw ApiException('Unable to delete this item.', response.statusCode);
  }

  Future<http.Response> _authenticated(String path) async {
    final token = await accessToken();
    return http.get(Uri.parse('$_apiBase/$path'), headers: {'Authorization': 'Bearer $token'});
  }

  Future<String?> accessToken() async =>
      (await SharedPreferences.getInstance()).getString(_accessKey);
  Future<String?> refreshToken() async =>
      (await SharedPreferences.getInstance()).getString(_refreshKey);

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
    await prefs.remove('user_role');
  }

  Future<void> deleteAccount() async {
    final token = await accessToken();
    final response = await http.delete(Uri.parse('$_apiBase/auth/user/delete/'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode != 204) throw ApiException('Unable to delete your account.', response.statusCode);
    await clearSession();
  }

  Map<String, dynamic> _decode(http.Response response) {
    try {
      final value = jsonDecode(response.body);
      return value is Map<String, dynamic> ? value : <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  dynamic _decodeDynamic(http.Response response) {
    try {
      return jsonDecode(response.body);
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  String _message(Map<String, dynamic> data, String fallback) {
    final value = data['detail'] ?? data['error'] ?? data['message'];
    return value is String && value.isNotEmpty ? value : fallback;
  }
}

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => message;
}
