import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'app_models.dart';
export 'app_models.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


class AppState extends GetxController {
  AppState() {
    // Start with a guest user or attempt to load from local storage.
    // For demo/testing, we fallback to a local mock if not logged in.
    _currentUser = const AppUser(
      name: 'Guest User',
      role: 'Client',
      tagline: 'Please log in to continue',
      avatar: 'assets/images/onboard3.jpg',
    );
  }

  late AppUser _currentUser;
  List<TaskItem> _myTasks = [];
  List<TaskItem> _marketplaceTasks = [];
  Map<String, dynamic>? _companyProfile;
  List<BidItem> _bids = [];
  List<ChatThread> _threads = [];
  final Map<String, List<ChatMessage>> _threadMessages = {};
  List<WalletTransaction> _walletTransactions = [];
  List<ServiceItem> _services = [];
  final Set<String> _savedServiceIds = {};
  final Set<String> _savedTechUserIds = {};
  double _walletBalance = 0.0;
  double _pendingBalance = 0.0;

  List<Map<String, dynamic>> _publicCompanies = [];
  List<Map<String, dynamic>> _publicPros = [];
  List<Map<String, dynamic>> _faqPages = [];
  List<dynamic> _searchResults = [];
  List<dynamic> _portfolioItems = [];

  String? _companyRegistrationStatus;
  String? _companyRegistrationSummary;
  String? _verificationStatus;
  String? _verificationSummary;

  AppUser get currentUser => _currentUser;
  String get currentRole => _currentUser.role;
  List<TaskItem> get tasks => List.unmodifiable(_myTasks);
  List<BidItem> get bids => List.unmodifiable(_bids);
  List<ChatThread> get threads => List.unmodifiable(_threads);
  List<ChatMessage> getMessagesForThread(String threadId) => _threadMessages[threadId] ?? [];
  List<WalletTransaction> get walletTransactions => List.unmodifiable(_walletTransactions);
  List<ServiceItem> get services => List.unmodifiable(_services);
  List<ServiceItem> get savedServices => _services.where((service) => _savedServiceIds.contains(service.id)).toList();
  List<Map<String, dynamic>> get publicCompanies => List.unmodifiable(_publicCompanies);
  List<Map<String, dynamic>> get publicPros => List.unmodifiable(_publicPros);
  List<Map<String, dynamic>> get faqPages => List.unmodifiable(_faqPages);
  List<dynamic> get searchResults => List.unmodifiable(_searchResults);
  List<dynamic> get portfolioItems => List.unmodifiable(_portfolioItems);
  String? get companyRegistrationStatus => _companyRegistrationStatus;
  String? get companyRegistrationSummary => _companyRegistrationSummary;
  String? get verificationStatus => _verificationStatus;
  String? get verificationSummary => _verificationSummary;
  Map<String, dynamic>? get companyProfile => _companyProfile;

  List<TaskItem> get openMarketplaceTasks => List.unmodifiable(_marketplaceTasks);

  List<TaskItem> get clientTasks => List.unmodifiable(_myTasks);

  double get walletBalance => _walletBalance;
  double get pendingBalance => _pendingBalance;

  String _formatTime12Hour(dynamic createdAt) {
    if (createdAt == null) return '12:00 AM';
    final parsed = DateTime.tryParse(createdAt.toString());
    if (parsed == null) return '12:00 AM';
    final local = parsed.toLocal();
    int hour = local.hour;
    final int minute = local.minute;
    final String period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    final String minuteStr = minute < 10 ? '0$minute' : '$minute';
    return '$hour:$minuteStr $period';
  }

  // Helper to map Django backend roles to Flutter title case roles
  String _mapRole(String backendRole) {
    switch (backendRole.toUpperCase()) {
      case 'CLIENT':
        return 'Client';
      case 'TECHNICIAN':
        return 'Technician';
      case 'COMPANY':
        return 'Company';
      case 'ADMIN':
        return 'Admin';
      default:
        return 'Client';
    }
  }

  // Helper to map Django task status to Flutter status labels
  String _mapStatus(String backendStatus) {
    switch (backendStatus.toLowerCase()) {
      case 'draft':
        return 'Draft';
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'delivered':
        return 'Delivered';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      case 'deleted':
        return 'Deleted';
      default:
        return 'Open';
    }
  }

  // ─── AUTHENTICATION ACTIONS ────────────────────────────────────────────────

  Future<void> loginUser(String username, String password) async {
    await ApiService.instance.login(username, password);
    await syncAll();
  }

  Future<void> registerAndLogin({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    if (role == 'Client') {
      await ApiService.instance.registerClient(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
    } else if (role == 'Technician') {
      await ApiService.instance.registerTechnician(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
    } else {
      await ApiService.instance.registerCompany(
        companyName: '$firstName $lastName'.trim(),
        email: email,
        password: password,
        phone: phone,
      );
    }
    // Auto-login after successful registration
    await loginUser(email, password);
  }

  Future<Map<String, dynamic>> registerUser({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    if (role == 'Client') {
      await ApiService.instance.registerClient(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
    } else if (role == 'Technician') {
      await ApiService.instance.registerTechnician(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );
    } else {
      await ApiService.instance.registerCompany(
        companyName: '$firstName $lastName'.trim(),
        email: email,
        password: password,
        phone: phone,
      );
    }
    // Request verification OTP code immediately
    return await ApiService.instance.requestPhoneOTP(phone, email: email, purpose: 'register');
  }



  void logout() {
    ApiService.instance.clearTokens();
    _currentUser = const AppUser(
      name: 'Guest User',
      role: 'Client',
      tagline: 'Please log in to continue',
      avatar: 'assets/images/onboard3.jpg',
    );
    _myTasks.clear();
    _marketplaceTasks.clear();
    _bids.clear();
    _threads.clear();
    _walletTransactions.clear();
    _walletBalance = 0.0;
    _pendingBalance = 0.0;
    update();
  }

  Future<void> deleteAccount() async {
    final response = await ApiService.instance.delete('/auth/user/delete/');
    if (response.statusCode == 204 || response.statusCode == 200) {
      logout();
    } else {
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  // ─── STATE SYNCHRONIZATION ──────────────────────────────────────────────────

  Future<void> syncAll() async {
    await syncProfile();
    await syncTasks();
    await syncWallet();
    await syncConversations();
    await syncPublicData();
    await syncMyServices();
    await syncBids();
    await syncPortfolio();
    await syncSavedProfessionals();
  }

  TaskItem _mapTaskItem(dynamic t) {
    final double budgetMin = double.tryParse(t['budget_min']?.toString() ?? '0') ?? 0.0;
    final double budgetMax = double.tryParse(t['budget_max']?.toString() ?? '0') ?? 0.0;
    
    final assignedMap = t['assigned_to'] as Map<String, dynamic>?;
    final String? assignedId = assignedMap?['id']?.toString();
    final String? assignedName = assignedMap != null
        ? '${assignedMap['first_name'] ?? ''} ${assignedMap['last_name'] ?? ''}'.trim()
        : null;
    final String? assignedAvatar = assignedMap?['avatar_url']?.toString();

    return TaskItem(
      id: t['id']?.toString() ?? '',
      title: t['title'] ?? '',
      description: t['description'] ?? '',
      category: t['category_name'] ?? 'General',
      location: t['location'] ?? 'Lagos, Nigeria',
      clientName: t['client'] != null ? '${t['client']['first_name'] ?? ''} ${t['client']['last_name'] ?? ''}'.trim() : (t['client_name'] ?? 'Client'),
      clientAvatar: (t['client'] != null && t['client']['avatar_url'] != null && t['client']['avatar_url'].toString().isNotEmpty) ? t['client']['avatar_url'] : 'assets/images/onboard3.jpg',
      clientRating: t['client'] != null ? (double.tryParse(t['client']['rating']?.toString() ?? '') ?? 4.9) : 4.9,
      budget: budgetMax > 0 ? budgetMax : budgetMin,
      status: _mapStatus(t['status'] ?? 'open'),
      createdLabel: t['created_at']?.toString().substring(0, 10) ?? 'Just now',
      schedule: t['schedule'] ?? 'Immediate',
      urgency: t['urgency']?.toString().toUpperCase() == 'URGENT' ? 'Urgent' : 'Flexible',
      paymentMethod: 'Escrow / Wallet',
      tags: [
        t['service_type'] ?? 'On-site',
        t['urgency'] ?? 'Flexible',
      ],
      bidsCount: t['bids_count'] ?? 0,
      acceptedBidId: assignedId,
      assignedToId: assignedId,
      assignedToName: assignedName,
      assignedToAvatar: assignedAvatar,
      deadline: t['deadline']?.toString(),
      imageUrl: t['image_url']?.toString(),
      clientReviews: t['client'] != null ? (int.tryParse(t['client']['tasks_count']?.toString() ?? '') ?? 0) : 0,
    );
  }

  Future<void> syncProfile() async {
    try {
      final profile = await ApiService.instance.fetchProfile();
      final String firstName = profile['first_name'] ?? '';
      final String lastName = profile['last_name'] ?? '';
      final String phone = profile['phone'] ?? '';
      final String country = profile['country'] ?? '';
      final String username = profile['username'] ?? '';
      final String name = (firstName.isEmpty && lastName.isEmpty) ? username : '$firstName $lastName'.trim();
      
      // Infer country from phone number prefix if database is empty (e.g. immediately after signup)
      String inferredCountry = country;
      if (inferredCountry.isEmpty && phone.isNotEmpty) {
        if (phone.startsWith('+92')) {
          inferredCountry = 'Pakistan';
        } else if (phone.startsWith('+234')) {
          inferredCountry = 'Nigeria';
        } else if (phone.startsWith('+1')) {
          inferredCountry = 'United States';
        } else if (phone.startsWith('+254')) {
          inferredCountry = 'Kenya';
        } else if (phone.startsWith('+27')) {
          inferredCountry = 'South Africa';
        } else if (phone.startsWith('+233')) {
          inferredCountry = 'Ghana';
        } else {
          inferredCountry = 'Nigeria';
        }
      } else if (inferredCountry.isEmpty) {
        inferredCountry = 'Nigeria';
      }

      _currentUser = AppUser(
        name: name,
        role: _mapRole(profile['role'] ?? 'CLIENT'),
        tagline: profile['tagline'] ?? '${_mapRole(profile['role'] ?? 'CLIENT')} Account',
        avatar: profile['avatar_url']?.toString().isNotEmpty == true ? profile['avatar_url'] : '',
        id: profile['id'] ?? 0,
        location: inferredCountry,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        country: inferredCountry,
        bio: profile['bio'] ?? '',
        hourlyRate: double.tryParse(profile['hourly_rate']?.toString() ?? '0') ?? 0.0,
        availabilityStatus: profile['availability_status'] ?? 'available',
        skills: (profile['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        certifications: (profile['certifications'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        experience: profile['experience'] ?? '',
      );

      if (_currentUser.role == 'Technician') {
        syncPortfolio();
      }
      
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('user_role', _currentUser.role);
      });
      
      if (profile['is_verified'] == true) {
        _verificationStatus = 'Verified';
        _verificationSummary = 'Your account has been fully verified.';
      } else {
        _verificationStatus = null;
      }

      if (_currentUser.role == 'Company') {
        try {
          _companyProfile = await ApiService.instance.fetchCompanyProfile();
          _companyRegistrationStatus = _companyProfile!['is_verified'] == true ? 'Verified' : 'Pending Review';
          _companyRegistrationSummary = _companyProfile!['registration_number']?.toString().isNotEmpty == true
              ? 'Registration: ${_companyProfile!['registration_number']}'
              : 'Registration pending review.';
        } catch (e) {
          debugPrint('Sync Company Profile Error: $e');
        }
      }
      update();
    } catch (e) {
      debugPrint('Sync Profile Error: $e');
    }
  }

  Future<void> syncTasks() async {
    try {
      final myRaw = await ApiService.instance.fetchMyTasks();
      _myTasks = myRaw.map((t) => _mapTaskItem(t)).toList();

      final marketRaw = await ApiService.instance.fetchTasks();
      _marketplaceTasks = marketRaw.map((t) => _mapTaskItem(t)).toList();

      update();
    } catch (e) {
      debugPrint('Sync Tasks Error: $e');
    }
  }

  Future<void> syncWallet() async {
    try {
      final wallet = await ApiService.instance.fetchWallet();
      _walletBalance = double.tryParse(wallet['available_balance']?.toString() ?? '0.0') ?? 0.0;
      _pendingBalance = double.tryParse(wallet['pending_escrow']?.toString() ?? '0.0') ?? 0.0;

      final backendTransactions = await ApiService.instance.fetchTransactions();
      _walletTransactions = backendTransactions.map((tx) {
        final double amountVal = double.tryParse(tx['amount']?.toString() ?? '0.0') ?? 0.0;
        final bool isCredit = tx['type']?.toString().toLowerCase() == 'credit' || tx['type']?.toString().toLowerCase() == 'pending';
        return WalletTransaction(
          title: tx['description'] ?? 'Transaction',
          date: tx['created_at']?.toString().substring(0, 10) ?? 'Today',
          amount: '${isCredit ? "+" : "-"}\$${amountVal.toStringAsFixed(2)}',
          status: tx['status']?.toString().toUpperCase() == 'COMPLETED' ? 'Completed' : 'Pending',
          isIncome: isCredit,
        );
      }).toList();
      update();
    } catch (e) {
      debugPrint('Sync Wallet Error: $e');
    }
  }

  Future<void> syncConversations() async {
    try {
      final conversations = await ApiService.instance.fetchConversations();
      _threads = conversations.map((conv) {
        final int id = conv['id'] ?? 0;
        final List<dynamic> participantsList = conv['participants'] ?? [];
        final otherUser = participantsList.firstWhere(
          (p) => p['id']?.toString() != currentUser.id.toString() && currentUser.id != 0,
          orElse: () {
            if (participantsList.length > 1) {
              final p1 = participantsList[0];
              final p2 = participantsList[1];
              if (p1['id']?.toString() == currentUser.id.toString()) {
                return p2;
              }
              return p1;
            }
            return participantsList.isNotEmpty ? participantsList.first : {};
          },
        );
        final String name = '${otherUser['first_name'] ?? ''} ${otherUser['last_name'] ?? ''}'.trim().isNotEmpty
            ? '${otherUser['first_name']} ${otherUser['last_name']}'.trim()
            : (otherUser['username'] ?? 'User');
        final String avatar = (otherUser['avatar_url']?.toString().isNotEmpty == true)
            ? otherUser['avatar_url']
            : 'assets/images/onboard2.jpg';
        final bool online = otherUser['is_online'] == true;
        final String lastSeen = otherUser['last_seen']?.toString() ?? 'Offline';
        
        final List<dynamic> rawMsgs = conv['last_messages'] ?? [];
        final List<ChatMessage> messages = rawMsgs.map((m) {
          final int senderId = m['sender'] ?? 0;
          return ChatMessage(
            text: m['text'] ?? '',
            time: _formatTime12Hour(m['created_at']),
            isMe: senderId != otherUser['id'],
          );
        }).toList();

        return ChatThread(
          id: id.toString(),
          name: name,
          image: avatar,
          online: online,
          lastSeen: lastSeen,
          messages: messages,
        );
      }).toList();
      update();
    } catch (e) {
      debugPrint('Sync Conversations Error: $e');
    }
  }

  Future<void> syncPublicData() async {
    try {
      final companies = await ApiService.instance.fetchCompanies();
      _publicCompanies = List<Map<String, dynamic>>.from(companies);
    } catch (e) {
      debugPrint('Sync Companies Error: $e');
    }

    try {
      final pros = await ApiService.instance.fetchPublicUsers(role: 'TECHNICIAN');
      _publicPros = List<Map<String, dynamic>>.from(pros);
    } catch (e) {
      debugPrint('Sync Pros Error: $e');
    }

    try {
      final pages = await ApiService.instance.fetchPublicCmsPages();
      _faqPages = List<Map<String, dynamic>>.from(pages);
    } catch (e) {
      debugPrint('Sync CMS Pages Error: $e');
    }

    try {
      final searchRes = await ApiService.instance.searchEverything(tab: 'services');
      final List<dynamic> results = searchRes['results'] ?? [];
      _services = results.map((item) {
        final double priceVal = double.tryParse(item['price']?.toString() ?? '') ?? 0.0;
        final String priceLbl = priceVal > 0 ? '\$${priceVal.toStringAsFixed(0)}/hr' : (item['priceLabel'] ?? 'hourly');
        return ServiceItem(
          id: item['id']?.toString() ?? '',
          title: item['name'] ?? '',
          category: item['category'] ?? 'General',
          description: item['description'] ?? '',
          priceLabel: priceLbl,
          providerName: item['role'] ?? 'Provider',
          providerAvatar: item['image']?.toString().isNotEmpty == true ? item['image'] : 'assets/images/onboard1.jpg',
          providerRole: item['type']?.toString().toLowerCase() == 'company' ? 'Company' : 'Technician',
          serviceType: item['serviceType'] ?? 'On-site',
          coverageArea: item['location'] ?? 'Lagos, Nigeria',
          availability: 'Flexible Availability',
          pricingModel: item['pricingModel'] ?? 'Hourly Rate',
          providerId: item['profileId']?.toString() ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('Sync Public Services Error: $e');
    }
    update();
  }

  Future<void> syncMyServices() async {
    try {
      List<dynamic> backendServices = [];
      if (currentRole == 'Technician') {
        backendServices = await ApiService.instance.fetchTechnicianServices();
      } else if (currentRole == 'Company') {
        backendServices = await ApiService.instance.fetchCompanyServices();
      }

      if (backendServices.isNotEmpty) {
        final mapped = backendServices.map((item) {
          final double priceMin = double.tryParse(item['pricing_min']?.toString() ?? '') ?? 0.0;
          final priceLabel = priceMin > 0 ? '\$${priceMin.toStringAsFixed(0)}/hr' : (item['pricing_model'] ?? 'hourly');
          return ServiceItem(
            id: item['id']?.toString() ?? '',
            title: item['title'] ?? '',
            category: item['category_name'] ?? 'General',
            description: item['description'] ?? '',
            priceLabel: priceLabel,
            providerName: currentUser.name,
            providerAvatar: currentUser.avatar,
            providerRole: currentRole,
            serviceType: item['service_type'] == 'remote' ? 'Remote' : 'On-site',
            coverageArea: item['coverage_area'] ?? 'Lagos, Nigeria',
            availability: 'Weekdays 9 AM - 6 PM',
            pricingModel: item['pricing_model'] ?? 'Hourly Rate',
            providerId: currentUser.id.toString(),
          );
        }).toList();
        
        for (final mySvc in mapped) {
          _services.removeWhere((element) => element.id == mySvc.id);
          _services.insert(0, mySvc);
        }
      }
      update();
    } catch (e) {
      debugPrint('Sync My Services Error: $e');
    }
  }

  Future<void> syncBids() async {
    try {
      final backendBids = await ApiService.instance.fetchMyBids();
      _bids = backendBids.map((b) {
        final taskIdStr = b['task_id']?.toString() ?? '';
        final double amount = double.tryParse(b['amount']?.toString() ?? '0.0') ?? 0.0;
        final isAccepted = b['status']?.toString().toLowerCase() == 'accepted';
        final tech = b['technician'] as Map<String, dynamic>? ?? {};
        final String firstName = tech['first_name'] ?? '';
        final String lastName = tech['last_name'] ?? '';
        final String bidderName = (firstName.isEmpty && lastName.isEmpty)
            ? (b['technician'] != null ? '${b['technician']['first_name'] ?? ''} ${b['technician']['last_name'] ?? ''}'.trim() : _currentUser.name)
            : '$firstName $lastName'.trim();
        final String avatar = (tech['avatar_url']?.toString().isNotEmpty == true)
            ? tech['avatar_url']
            : ((b['technician'] != null && b['technician']['avatar_url'] != null && b['technician']['avatar_url'].toString().isNotEmpty) ? b['technician']['avatar_url'] : 'assets/images/onboard1.jpg');

        final double rating = double.tryParse(tech['rating']?.toString() ?? '') ?? 4.9;
        final int reviews = int.tryParse(tech['reviews']?.toString() ?? '') ?? 0;

        return BidItem(
          id: b['id']?.toString() ?? '',
          taskId: taskIdStr,
          bidderName: bidderName.isEmpty ? _currentUser.name : bidderName,
          skill: 'Professional Provider',
          rating: rating,
          reviews: reviews,
          price: amount,
          timeline: b['duration'] ?? '3 days',
          message: b['message'] ?? '',
          avatar: avatar,
          role: 'Technician',
          isAccepted: isAccepted,
          technicianId: tech['id']?.toString() ?? _currentUser.id.toString(),
        );
      }).toList();
      update();
    } catch (e) {
      debugPrint('Sync Bids Error: $e');
    }
  }

  Future<void> performSearch(String query, {String? category, String? location, String? tab, String? type}) async {
    try {
      final res = await ApiService.instance.searchEverything(
        query: query,
        category: category,
        location: location,
        tab: tab,
        type: type,
      );
      _searchResults = res['results'] ?? [];
      update();
    } catch (e) {
      debugPrint('Search Error: $e');
    }
  }

  // ─── USER & TASK OPERATION METHODS ─────────────────────────────────────────

  TaskItem? findTask(String taskId) {
    for (final task in _myTasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    for (final task in _marketplaceTasks) {
      if (task.id == taskId) {
        return task;
      }
    }
    return null;
  }

  Future<List<BidItem>> bidsForTask(String taskId) async {
    try {
      final int id = int.tryParse(taskId) ?? 0;
      final backendBids = await ApiService.instance.fetchTaskBids(id);
      return backendBids.map((b) {
        final tech = b['technician'] as Map<String, dynamic>? ?? {};
        final String firstName = tech['first_name'] ?? '';
        final String lastName = tech['last_name'] ?? '';
        final String bidderName = (firstName.isEmpty && lastName.isEmpty)
            ? (tech['email']?.toString().split('@').first ?? 'Technician')
            : '$firstName $lastName'.trim();
        final String avatar = (tech['avatar_url']?.toString().isNotEmpty == true)
            ? tech['avatar_url']
            : 'assets/images/onboard1.jpg';

        final matchedPro = _publicPros.firstWhere(
          (u) => u['id']?.toString() == tech['id']?.toString(),
          orElse: () => <String, dynamic>{},
        );

        final List<dynamic> matchedSkills = matchedPro['skills'] is List ? matchedPro['skills'] : [];
        final String skill = matchedSkills.isNotEmpty ? matchedSkills.first.toString() : 'Professional Provider';
        final double rating = double.tryParse((matchedPro['rating'] ?? matchedPro['average_rating'])?.toString() ?? '') ?? 0.0;
        final int reviews = int.tryParse((matchedPro['reviews'] ?? matchedPro['completed_jobs'])?.toString() ?? '') ?? 0;

        return BidItem(
          id: b['id']?.toString() ?? '',
          taskId: taskId,
          bidderName: bidderName,
          skill: skill,
          rating: rating,
          reviews: reviews,
          price: double.tryParse(b['amount']?.toString() ?? '0') ?? 0.0,
          timeline: b['duration'] ?? '3 days',
          message: b['message'] ?? '',
          avatar: avatar,
          role: tech['role'] ?? 'Technician',
          isAccepted: b['status']?.toString().toLowerCase() == 'accepted',
          technicianId: tech['id']?.toString(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Fetch Task Bids Error: $e');
      return [];
    }
  }

  Future<TaskItem> publishTask(TaskDraft draft) async {
    // 1. Map to actual database category IDs
    int categoryId = 26; // Default to Plumbing (26)
    final catLower = draft.category.toLowerCase();
    if (catLower.contains('elec')) {
      categoryId = 25;
    } else if (catLower.contains('plumb') || catLower.contains('repair')) {
      categoryId = 26;
    } else if (catLower.contains('hvac')) {
      categoryId = 27;
    } else if (catLower.contains('carp')) {
      categoryId = 28;
    } else if (catLower.contains('paint')) {
      categoryId = 29;
    } else if (catLower.contains('mason')) {
      categoryId = 30;
    } else if (catLower.contains('secu')) {
      categoryId = 31;
    } else if (catLower.contains('clean')) {
      categoryId = 32;
    } else if (catLower.contains('furn')) {
      categoryId = 33;
    }
    
    // 2. Create task draft
    final taskData = {
      'title': draft.title,
      'description': draft.description,
      'category': categoryId,
      'budget_min': draft.budgetMin,
      'budget_max': draft.budgetMax,
      'budget_mode': draft.budgetMode,
      'urgency': draft.urgency.toLowerCase(),
      'service_type': draft.locationType == 'On-site' ? 'onsite' : (draft.locationType == 'Remote' ? 'remote' : 'hybrid'),
      'location': draft.location,
      'city': draft.city.isNotEmpty ? draft.city : 'Lagos',
      'schedule': draft.timeline,
      'deadline': draft.deadline,
      'materials_provided': false,
      'contact_methods': ['chat'],
      'skills': [],
      'image_url': draft.imageUrl,
    };

    final createdTask = await ApiService.instance.createTask(taskData);
    final int createdId = createdTask['id'] ?? 0;
    
    // 3. Publish task
    final published = await ApiService.instance.publishTask(createdId);
    await syncTasks();

    final double budgetMin = double.tryParse(published['budget_min']?.toString() ?? '0') ?? 0.0;
    final double budgetMax = double.tryParse(published['budget_max']?.toString() ?? '0') ?? 0.0;
    
    final assignedMap = published['assigned_to'] as Map<String, dynamic>?;
    final String? assignedId = assignedMap?['id']?.toString();
    final String? assignedName = assignedMap != null
        ? '${assignedMap['first_name'] ?? ''} ${assignedMap['last_name'] ?? ''}'.trim()
        : null;
    final String? assignedAvatar = assignedMap?['avatar_url']?.toString();

    return TaskItem(
      id: published['id']?.toString() ?? '',
      title: published['title'] ?? '',
      description: published['description'] ?? '',
      category: published['category_name'] ?? 'General',
      location: published['location'] ?? 'Lagos, Nigeria',
      clientName: published['client'] != null ? '${published['client']['first_name'] ?? ''} ${published['client']['last_name'] ?? ''}'.trim() : (published['client_name'] ?? 'Client'),
      clientAvatar: (published['client'] != null && published['client']['avatar_url'] != null && published['client']['avatar_url'].toString().isNotEmpty) ? published['client']['avatar_url'] : 'assets/images/onboard3.jpg',
      clientRating: published['client'] != null ? (double.tryParse(published['client']['rating']?.toString() ?? '') ?? 4.9) : 4.9,
      budget: budgetMax > 0 ? budgetMax : budgetMin,
      status: _mapStatus(published['status'] ?? 'open'),
      createdLabel: published['created_at']?.toString().substring(0, 10) ?? 'Just now',
      schedule: published['schedule'] ?? 'Immediate',
      urgency: published['urgency']?.toString().toUpperCase() == 'URGENT' ? 'Urgent' : 'Flexible',
      paymentMethod: 'Escrow / Wallet',
      tags: [
        published['service_type'] ?? 'On-site',
        published['urgency'] ?? 'Flexible',
      ],
      bidsCount: published['bids_count'] ?? 0,
      acceptedBidId: assignedId,
      assignedToId: assignedId,
      assignedToName: assignedName,
      assignedToAvatar: assignedAvatar,
      deadline: published['deadline']?.toString(),
      imageUrl: published['image_url']?.toString(),
      clientReviews: published['client'] != null ? (int.tryParse(published['client']['tasks_count']?.toString() ?? '') ?? 0) : 0,
    );
  }

  Future<void> updateTaskItem(String taskId, TaskDraft draft) async {
    final int id = int.tryParse(taskId) ?? 0;
    
    int categoryId = 26; // Default to Plumbing (26)
    final catLower = draft.category.toLowerCase();
    if (catLower.contains('elec')) {
      categoryId = 25;
    } else if (catLower.contains('plumb') || catLower.contains('repair')) {
      categoryId = 26;
    } else if (catLower.contains('hvac')) {
      categoryId = 27;
    } else if (catLower.contains('carp')) {
      categoryId = 28;
    } else if (catLower.contains('paint')) {
      categoryId = 29;
    } else if (catLower.contains('mason')) {
      categoryId = 30;
    } else if (catLower.contains('secu')) {
      categoryId = 31;
    } else if (catLower.contains('clean')) {
      categoryId = 32;
    } else if (catLower.contains('furn')) {
      categoryId = 33;
    }

    final taskData = {
      'title': draft.title,
      'description': draft.description,
      'category': categoryId,
      'budget_min': draft.budgetMin,
      'budget_max': draft.budgetMax,
      'budget_mode': draft.budgetMode,
      'urgency': draft.urgency.toLowerCase(),
      'service_type': draft.locationType == 'On-site' ? 'onsite' : (draft.locationType == 'Remote' ? 'remote' : 'hybrid'),
      'location': draft.location,
      'city': draft.city.isNotEmpty ? draft.city : 'Lagos',
      'schedule': draft.timeline,
      'deadline': draft.deadline,
      'image_url': draft.imageUrl,
    };

    await ApiService.instance.updateTask(id, taskData);
    await syncTasks();
  }

  Future<ServiceItem> publishService({
    required String title,
    required String category,
    required String description,
    required String priceLabel,
    required String providerName,
    required String providerAvatar,
    required String providerRole,
    required String serviceType,
    required String coverageArea,
    required String availability,
    required String pricingModel,
  }) async {
    int categoryId = 26; // Default to Plumbing (26)
    final catLower = category.toLowerCase();
    if (catLower.contains('elec')) {
      categoryId = 25;
    } else if (catLower.contains('plumb') || catLower.contains('repair')) {
      categoryId = 26;
    } else if (catLower.contains('hvac')) {
      categoryId = 27;
    } else if (catLower.contains('carp')) {
      categoryId = 28;
    } else if (catLower.contains('paint')) {
      categoryId = 29;
    } else if (catLower.contains('mason')) {
      categoryId = 30;
    } else if (catLower.contains('secu')) {
      categoryId = 31;
    } else if (catLower.contains('clean')) {
      categoryId = 32;
    } else if (catLower.contains('furn')) {
      categoryId = 33;
    }

    double priceVal = double.tryParse(priceLabel.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 50.0;

    if (currentRole == 'Technician') {
      final data = {
        'title': title,
        'category': categoryId,
        'description': description,
        'service_type': serviceType.toLowerCase().contains('remote') ? 'remote' : 'onsite',
        'coverage_area': coverageArea,
        'pricing_model': pricingModel.toLowerCase().contains('hour') ? 'hourly' : 'fixed',
        'pricing_min': priceVal,
        'pricing_max': priceVal,
        'is_active': true,
      };
      final published = await ApiService.instance.publishTechnicianService(data);
      await syncMyServices();
      return ServiceItem(
        id: published['id']?.toString() ?? '',
        title: published['title'] ?? '',
        category: category,
        description: published['description'] ?? '',
        priceLabel: '\$${priceVal.toStringAsFixed(0)}/hr',
        providerName: providerName,
        providerAvatar: providerAvatar,
        providerRole: providerRole,
        serviceType: serviceType,
        coverageArea: coverageArea,
        availability: availability,
        pricingModel: pricingModel,
        providerId: currentUser.id.toString(),
      );
    } else {
      final data = {
        'title': title,
        'description': description,
      };
      final published = await ApiService.instance.publishCompanyService(data);
      await syncMyServices();
      return ServiceItem(
        id: published['id']?.toString() ?? '',
        title: published['title'] ?? '',
        category: category,
        description: published['description'] ?? '',
        priceLabel: '\$${priceVal.toStringAsFixed(0)}/hr',
        providerName: providerName,
        providerAvatar: providerAvatar,
        providerRole: providerRole,
        serviceType: serviceType,
        coverageArea: coverageArea,
        availability: availability,
        pricingModel: pricingModel,
        providerId: currentUser.id.toString(),
      );
    }
  }

  Future<void> submitBid({
    required String taskId,
    required double price,
    required String timeline,
    required String message,
  }) async {
    final int id = int.tryParse(taskId) ?? 0;
    await ApiService.instance.submitBid(
      taskId: id,
      amount: price,
      timeline: timeline,
      message: message,
    );
    await syncTasks();
    await syncBids();
  }

  Future<void> acceptBid(String taskId, String bidId) async {
    final int tId = int.tryParse(taskId) ?? 0;
    final int bId = int.tryParse(bidId) ?? 0;
    
    // Fetch bids for task to get the correct bid amount
    final bidsList = await bidsForTask(taskId);
    final bid = bidsList.firstWhere((element) => element.id == bidId);

    // Call deposit escrow endpoint to trigger bid acceptance
    await ApiService.instance.depositEscrow(
      taskId: tId,
      bidId: bId,
      amount: bid.price,
    );
    await syncTasks();
    await syncWallet();
  }

  Future<void> completeTask(String taskId) async {
    final int tId = int.tryParse(taskId) ?? 0;
    await ApiService.instance.completeTask(tId);
    await syncTasks();
    await syncWallet();
  }

  Future<void> submitWork(String taskId) async {
    final int tId = int.tryParse(taskId) ?? 0;
    await ApiService.instance.submitWork(tId);
    await syncTasks();
  }

  Future<void> deleteTask(String taskId) async {
    final int tId = int.tryParse(taskId) ?? 0;
    await ApiService.instance.deleteTask(tId);
    await syncTasks();
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? phone,
    String? country,
    String? bio,
    double? hourlyRate,
    String? availabilityStatus,
    List<String>? skills,
    List<String>? certifications,
    String? experience,
  }) async {
    final body = <String, dynamic>{};
    if (firstName != null) body['first_name'] = firstName;
    if (lastName != null) body['last_name'] = lastName;
    if (phone != null) body['phone'] = phone;
    if (country != null) body['country'] = country;
    if (bio != null) body['bio'] = bio;
    if (hourlyRate != null) body['hourly_rate'] = hourlyRate;
    if (availabilityStatus != null) body['availability_status'] = availabilityStatus;
    if (skills != null) body['skills'] = skills;
    if (certifications != null) body['certifications'] = certifications;
    if (experience != null) body['experience'] = experience;

    if (currentRole == 'Technician') {
      await ApiService.instance.updateTechnicianProfile(body);
    } else {
      await ApiService.instance.updateProfile(body);
    }
    await syncAll(); // Reload user state from backend
  }

  Future<void> syncPortfolio() async {
    try {
      final items = await ApiService.instance.fetchPortfolioItems();
      _portfolioItems.clear();
      _portfolioItems.addAll(items);
      update();
    } catch (e) {
      debugPrint('Sync Portfolio Error: $e');
    }
  }

  Future<void> createPortfolioItem({
    required String title,
    required String description,
    required String category,
    required String imageUrl,
  }) async {
    await ApiService.instance.addPortfolioItem({
      'title': title,
      'description': description,
      'category': category,
      'image_url': imageUrl,
    });
    await syncPortfolio();
  }

  Future<void> removePortfolioItem(int itemId) async {
    await ApiService.instance.deletePortfolioItem(itemId);
    await syncPortfolio();
  }

  Future<void> syncThreadMessages(String threadId) async {
    final int convId = int.tryParse(threadId) ?? 0;
    if (convId == 0) return;
    try {
      final detail = await ApiService.instance.fetchConversationDetail(convId);
      final List<dynamic> rawMsgs = detail['messages'] ?? [];
      final List<ChatMessage> messages = rawMsgs.map((m) {
        final int senderId = m['sender'] ?? 0;
        return ChatMessage(
          text: m['text'] ?? '',
          time: _formatTime12Hour(m['created_at']),
          isMe: senderId == currentUser.id,
        );
      }).toList();
      _threadMessages[threadId] = messages;
      update();
    } catch (e) {
      debugPrint('Sync Thread Messages Error: $e');
    }
  }

  Future<void> sendMessage(String threadId, String text) async {
    final int convId = int.tryParse(threadId) ?? 0;
    await ApiService.instance.sendMessage(convId, text);
    await syncThreadMessages(threadId);
    await syncConversations();
  }

  Future<void> deleteConversation(String threadId) async {
    final int convId = int.tryParse(threadId) ?? 0;
    if (convId == 0) return;
    await ApiService.instance.deleteConversation(convId);
    _threads.removeWhere((t) => t.id == threadId);
    _threadMessages.remove(threadId);
    update();
  }

  Future<void> createOrOpenThread({
    required String otherPartyName,
    required String otherPartyImage,
    String initialMessage = '',
  }) async {
    // For demo integration, we look up the user by name or create a standard thread
    // To wire completely, we would fetch users list, find correct id, and call createConversation.
    // If not found, we fallback to opening thread 1.
    try {
      final usersResponse = await ApiService.instance.get('/auth/users/');
      final List<dynamic> users = jsonDecode(usersResponse.body);
      int otherUserId = 1;
      for (final u in users) {
        final fName = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim();
        final username = u['username'] ?? '';
        if (fName.toLowerCase() == otherPartyName.toLowerCase() ||
            username.toLowerCase() == otherPartyName.toLowerCase()) {
          otherUserId = u['id'];
          break;
        }
      }
      final conv = await ApiService.instance.createConversation(otherUserId);
      final int convId = conv['id'] ?? 1;
      if (initialMessage.isNotEmpty) {
        await ApiService.instance.sendMessage(convId, initialMessage);
      }
      await syncConversations();
      await syncThreadMessages(convId.toString());
    } catch (e) {
      debugPrint('Create Thread Error: $e');
    }
  }

  Future<void> requestWithdrawal({
    required double amount,
    required String method,
  }) async {
    await ApiService.instance.requestWithdrawal(amount, method);
    await syncWallet();
  }

  // ─── LOCAL STATE PREFS ─────────────────────────────────────────────────────

  bool isServiceSaved(String serviceId) => _savedServiceIds.contains(serviceId);

  Future<void> toggleSavedService(String serviceId) async {
    ServiceItem? service;
    for (final s in _services) {
      if (s.id == serviceId) {
        service = s;
        break;
      }
    }
    if (service == null) return;
    final providerId = service.providerId;

    if (_savedServiceIds.contains(serviceId)) {
      _savedServiceIds.remove(serviceId);
      update();
      try {
        final response = await ApiService.instance.delete('/auth/saved-pros/$providerId/?service_id=$serviceId');
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('Failed to remove');
        }
      } catch (e) {
        _savedServiceIds.add(serviceId);
        update();
        debugPrint('Remove saved service error: $e');
      }
    } else {
      _savedServiceIds.add(serviceId);
      update();
      try {
        await ApiService.instance.post('/auth/saved-pros/', {
          'professional_id': providerId,
          'service_id': serviceId,
        });
      } catch (e) {
        _savedServiceIds.remove(serviceId);
        update();
        debugPrint('Save service error: $e');
      }
    }
  }

  bool isTechSaved(String techId) => _savedTechUserIds.contains(techId);

  Future<void> toggleSavedTech(String techId) async {
    if (_savedTechUserIds.contains(techId)) {
      _savedTechUserIds.remove(techId);
      update();
      try {
        final response = await ApiService.instance.delete('/auth/saved-pros/$techId/');
        if (response.statusCode != 200 && response.statusCode != 204) {
          throw Exception('Failed to remove');
        }
      } catch (e) {
        _savedTechUserIds.add(techId);
        update();
        debugPrint('Remove saved tech error: $e');
      }
    } else {
      _savedTechUserIds.add(techId);
      update();
      try {
        await ApiService.instance.post('/auth/saved-pros/', {
          'professional_id': techId,
        });
      } catch (e) {
        _savedTechUserIds.remove(techId);
        update();
        debugPrint('Save tech error: $e');
      }
    }
  }

  Future<void> syncSavedProfessionals() async {
    try {
      final list = await ApiService.instance.fetchSavedProfessionals();
      _savedTechUserIds.clear();
      _savedServiceIds.clear();
      for (final item in list) {
        final profId = item['professional']?['id']?.toString();
        final serviceId = item['service_id']?.toString();
        if (profId != null) {
          if (serviceId != null) {
            _savedServiceIds.add(serviceId);
          } else {
            _savedTechUserIds.add(profId);
          }
        }
      }
      update();
    } catch (e) {
      debugPrint('Sync saved professionals error: $e');
    }
  }

  Future<void> submitCompanyRegistration({
    required Map<String, String> details,
  }) async {
    final body = {
      'company_name': details['companyName'] ?? '',
      'registration_number': details['registrationNumber'] ?? '',
      'website': (details['website'] != null && details['website']!.startsWith('http')) ? details['website'] : 'https://${details['website']}',
      'headquarters': details['address'] ?? '',
      'about': 'Industry: ${details['industry']}',
    };
    await ApiService.instance.updateCompanyProfile(body);
    _companyRegistrationStatus = 'Pending Review';
    _companyRegistrationSummary = '${details['companyName']} submitted for compliance review.';
    update();
  }

  Future<void> submitVerification({
    required Map<String, String> details,
  }) async {
    final body = {
      'first_name': currentUser.name.split(' ').first,
      'last_name': currentUser.name.split(' ').length > 1 ? currentUser.name.split(' ').sublist(1).join(' ') : '',
      'phone': details['license'] ?? '',
    };
    await ApiService.instance.updateTechnicianProfile(body);
    _verificationStatus = 'Pending Review';
    _verificationSummary = 'Professional verification details submitted for review. Specialization: ${details['specialization']}. Bio: ${details['bio']}';
    update();
  }

  Future<void> createDispute({
    required String taskId,
    required String reason,
    required String title,
    required String description,
  }) async {
    final tId = int.tryParse(taskId) ?? 0;
    final task = findTask(taskId);
    int? againstId;
    if (task != null && task.acceptedBidId != null) {
      againstId = int.tryParse(task.acceptedBidId!);
    }
    
    await ApiService.instance.createDispute(
      taskId: tId,
      reason: reason,
      title: title,
      description: description,
      againstId: againstId,
    );
  }

  Future<Map<String, dynamic>> requestLoginOTP(String phone) async {
    return await ApiService.instance.requestPhoneOTP(phone, purpose: 'login');
  }

  Future<Map<String, dynamic>> requestOTP(String identifier, String purpose) async {
    return await ApiService.instance.requestPhoneOTP(identifier, email: identifier.contains('@') ? identifier : null, purpose: purpose);
  }

  Future<void> verifyOTPAndLogin(int challengeId, String code) async {
    final res = await ApiService.instance.verifyPhoneOTP(challengeId, code);
    if (res['access'] != null) {
      ApiService.instance.setTokens(res['access'], res['refresh']);
      await syncAll();
    } else {
      throw Exception('Login credentials were not returned.');
    }
  }

  List<dynamic> _adminUsersList = [];
  List<dynamic> _adminTasksList = [];

  List<dynamic> get adminUsersList => _adminUsersList;
  List<dynamic> get adminTasksList => _adminTasksList;

  Future<void> syncAdminData() async {
    try {
      _adminUsersList = await ApiService.instance.fetchAdminUsers();
      _adminTasksList = await ApiService.instance.fetchAdminTasks();
      update();
    } catch (e) {
      debugPrint('Sync Admin Data Error: $e');
    }
  }

  Future<void> verifyUser(int userId) async {
    await ApiService.instance.adminVerifyUser(userId);
    await syncAdminData();
  }

  Future<void> suspendUser(int userId) async {
    await ApiService.instance.adminSuspendUser(userId);
    await syncAdminData();
  }
}

class AppStateScope {
  const AppStateScope._();

  static AppState of(BuildContext context) {
    return Get.find<AppState>();
  }
}
