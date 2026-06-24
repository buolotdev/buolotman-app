import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  ApiService._privateConstructor();

  static final ApiService instance = ApiService._privateConstructor();

  // Change this URL if the backend is running on a physical device (e.g. http://192.168.x.x:8000/api)
  String baseUrl = 'http://192.168.0.101:8000/api';

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;

  void setTokens(String? access, String? refresh) {
    _accessToken = access;
    _refreshToken = refresh;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
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

  Future<http.Response> get(String path, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.get(url, headers: _getHeaders(requireAuth: requireAuth));
    return response;
  }

  Future<http.Response> post(String path, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.post(
      url,
      headers: _getHeaders(requireAuth: requireAuth),
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> patch(String path, Map<String, dynamic> body, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.patch(
      url,
      headers: _getHeaders(requireAuth: requireAuth),
      body: jsonEncode(body),
    );
    return response;
  }

  Future<http.Response> delete(String path, {bool requireAuth = true}) async {
    final url = Uri.parse('$baseUrl$path');
    final response = await http.delete(url, headers: _getHeaders(requireAuth: requireAuth));
    return response;
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
  }) async {
    final response = await post('/auth/register/company/', {
      'company_name': companyName,
      'email': email,
      'password': password,
      'phone': phone,
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

  Future<Map<String, dynamic>> cancelTask(int taskId) async {
    final response = await post('/tasks/$taskId/cancel/', {});
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final err = jsonDecode(response.body);
      throw Exception(err['detail'] ?? err['error'] ?? 'Failed to cancel task.');
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

  Future<Map<String, dynamic>> sendMessage(int conversationId, String text) async {
    final response = await post('/conversations/$conversationId/messages/', {
      'text': text,
    });

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send message.');
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
