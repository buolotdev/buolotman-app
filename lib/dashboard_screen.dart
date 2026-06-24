import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';
import 'category_browsing_screen.dart';
import 'company_profile_screen.dart';
import 'listing_screen.dart';
import 'search_screen.dart';
import 'post_task_screen.dart';
import 'post_service_screen.dart';
import 'browse_tasks_screen.dart';
import 'my_tasks_screen.dart';
import 'task_feed_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String role;
  const DashboardScreen({super.key, this.role = 'Client'});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedCategory = 'Plumbing';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Plumbing', 'icon': Icons.opacity},
    {'label': 'Electrical', 'icon': Icons.bolt},
    {'label': 'Cleaning', 'icon': Icons.auto_awesome},
    {'label': 'Carpentry', 'icon': Icons.handyman},
    {'label': 'Painting', 'icon': Icons.format_paint},
    {'label': 'Repair', 'icon': Icons.build},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).syncAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final greetingName = appState.currentUser.name.split(' ').first;
        final location = appState.currentUser.location;
        final bottomPadding = MediaQuery.of(context).padding.bottom + 120;
        return Scaffold(
          key: _scaffoldKey,
          drawer: _buildCategoryDrawer(),
          backgroundColor: const Color(0xFFFEFEFF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(greetingName, location),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(0, 8, 0, bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.role == 'Company') ...[
                          _buildCompanyStats(appState),
                          const SizedBox(height: 28),
                          _buildCompanySummary(appState),
                          const SizedBox(height: 28),
                          _buildSectionHeader("Active Projects", "Manage", onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyTasksScreen()));
                          }),
                          _buildRecentTasks(appState),
                          const SizedBox(height: 28),
                          _buildSectionHeader("Your Team", "Open", onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CompanyProfileScreen()));
                          }),
                          _buildTopProfessionals(appState),
                          const SizedBox(height: 28),
                          _buildSectionHeader("Service Catalog", "Edit", onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PostServiceScreen()));
                          }),
                          _buildPopularServices(appState),
                        ] else ...[
                          _buildSearchBar(),
                          const SizedBox(height: 16),
                          _buildCategories(),
                          const SizedBox(height: 24),
                          _buildQuickActionBanner(appState),
                          const SizedBox(height: 28),
                          _buildSectionHeader("Popular Services", "See all", onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ListingScreen()));
                          }),
                          _buildPopularServices(appState),
                          const SizedBox(height: 28),
                          _buildSectionHeader("Tasks Near You", "Browse", onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TaskFeedScreen()));
                          }),
                          _buildRecentTasks(appState),
                          const SizedBox(height: 28),
                          _buildSectionHeader("Featured Companies", "See all", onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CategoryBrowsingScreen()));
                          }),
                          _buildFeaturedCompanies(appState),
                          const SizedBox(height: 16),
                          _buildTrustBanner(),
                          const SizedBox(height: 28),
                          _buildSectionHeader("Top Rated Professionals", "See all", onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ListingScreen()));
                          }),
                          _buildTopProfessionals(appState),
                        ],
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(String greetingName, String location) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF001F3F)),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(
                    "Good Morning, $greetingName",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Color(0xFFFF4500)),
                      const SizedBox(width: 4),
                      Text(
                        location,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
                      ),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF001F3F)),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => MessagesScreen()),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.chat_bubble_outline, color: Color(0xFF001F3F), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_none, color: Color(0xFF001F3F), size: 20),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4500),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SearchScreen()),
          );
        },
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: TextField(
                  readOnly: true,
                  enabled: false,
                  decoration: InputDecoration(
                    hintText: "What service do you need?",
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 15, fontWeight: FontWeight.w500),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF001F3F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.tune, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final bool isActive = _selectedCategory == category['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category['label']),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF001F3F) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                      boxShadow: isActive ? [
                        BoxShadow(
                          color: const Color(0xFF001F3F).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        )
                      ] : null,
                    ),
                    child: Icon(
                      category['icon'],
                      color: isActive ? Colors.white : const Color(0xFF001F3F),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['label'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF001F3F),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickActionBanner(AppState appState) {
    String title = "Need something done?";
    String subtitle = "Post a task & get bids fast";
    String buttonText = "Post a Task";
    VoidCallback? onTap;

    if (appState.currentRole == 'Technician') {
      title = "Ready to work?";
      subtitle = "Browse active tasks in your area";
      buttonText = "Find Tasks";
      onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TaskFeedScreen()));
    } else if (appState.currentRole == 'Company') {
      title = "Manage your team";
      subtitle = "Track milestones and escrow payments";
      buttonText = "Projects";
      onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MyTasksScreen())); 
    } else {
      onTap = () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PostTaskScreen()));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF001F3F), Color(0xFF003366)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF001F3F).withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String linkText, {VoidCallback? onTap}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF001F3F),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Text(
              linkText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: onTap == null ? const Color(0xFF94A3B8) : const Color(0xFFFF4500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularServices(AppState appState) {
    if (appState.services.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            "No services registered yet.",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final services = appState.services
        .map((service) => {
              'title': service.title,
              'price': service.priceLabel,
              'rating': '4.8',
              'image': service.id.endsWith('1') ? 'assets/images/work1.png' : 'assets/images/work2.png',
            })
        .toList();

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ListingScreen(initialQuery: service['title'] as String)),
              );
            },
            child: Container(
              width: 180,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF001F3F).withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.asset(
                          service['image']!,
                          height: 120,
                          width: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFFB020), size: 12),
                              const SizedBox(width: 4),
                              Text(
                                service['rating']!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF001F3F),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['title']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF001F3F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          service['price']!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFF4500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentTasks(AppState appState) {
    final tasks = appState.openMarketplaceTasks
        .map((task) => {
              'category': task.category,
              'budget': '\$${task.budget.toStringAsFixed(0)}',
              'title': task.title,
              'location': task.location,
              'time': task.createdLabel,
              'urgent': task.urgency == 'Urgent',
              'id': task.id,
            })
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: tasks.map((task) {
          final category = task['category'] as String;
          final budget = task['budget'] as String;
          final title = task['title'] as String;
          final location = task['location'] as String;
          final time = task['time'] as String;
          final urgent = task['urgent'] as bool;
          final id = task['id'] as String;

          return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => BrowseTasksScreen(taskId: id)),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 4),
                              const Text("LIVE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      budget,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF001F3F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF001F3F),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: urgent ? const Color(0xFFFF4500) : const Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13, 
                        color: urgent ? const Color(0xFFFF4500) : const Color(0xFF64748B),
                        fontWeight: urgent ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
        }).toList(),
      ),
    );
  }

  Widget _buildTrustBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined, color: Color(0xFF1E8E3E), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "100% Secure Escrow Payments",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
                  ),
                  Text(
                    "Your money is safe until the task is complete",
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProfessionals(AppState appState) {
    if (appState.publicPros.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            "No professionals registered yet.",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final professionals = appState.publicPros.map((user) {
        final String name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isNotEmpty
            ? '${user['first_name']} ${user['last_name']}'.trim()
            : (user['username'] ?? 'Technician');
        final String avatar = user['avatar_url']?.toString().isNotEmpty == true ? user['avatar_url'] : 'assets/images/onboard1.jpg';
        final skills = user['skills'] is List ? (user['skills'] as List).join(', ') : 'Technician';
        final double rating = double.tryParse(user['average_rating']?.toString() ?? '4.8') ?? 4.8;
        final int completedJobs = int.tryParse(user['completed_jobs']?.toString() ?? '10') ?? 10;
        final double rate = double.tryParse(user['hourly_rate']?.toString() ?? '45') ?? 45.0;
        return {
          'name': name,
          'skill': skills.isNotEmpty ? skills : 'Professional Specialist',
          'rating': '$rating ($completedJobs)',
          'success': '98%',
          'price': '\$${rate.toStringAsFixed(0)}/hr',
          'avatar': avatar,
        };
      }).toList();

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: professionals.length,
        itemBuilder: (context, index) {
          final pro = professionals[index];
          final String avatar = pro['avatar']!;
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: avatar.startsWith('http')
                          ? Image.network(avatar, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => Image.asset('assets/images/onboard1.jpg', width: 56, height: 56, fit: BoxFit.cover))
                          : Image.asset(avatar, width: 56, height: 56, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pro['name']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                          Text(pro['skill']!, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Color(0xFFFFB020), size: 14),
                              const SizedBox(width: 4),
                              Text(pro['rating']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                              const SizedBox(width: 12),
                              Text("${pro['success']} Success", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(height: 1, color: const Color(0xFFE2E8F0)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(pro['price']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFF4500)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text("View Profile", style: TextStyle(color: Color(0xFFFF4500), fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeaturedCompanies(AppState appState) {
    if (appState.publicCompanies.isEmpty) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            "No registered companies yet.",
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    final companies = appState.publicCompanies.map((c) {
        final String name = c['company_name'] ?? 'Company';
        final String industry = c['services_offered'] is List && (c['services_offered'] as List).isNotEmpty
            ? (c['services_offered'] as List).first.toString()
            : 'Service Company';
        final double rating = double.tryParse(c['average_rating']?.toString() ?? '4.8') ?? 4.8;
        final String logo = c['logo_url']?.toString().isNotEmpty == true
            ? c['logo_url']
            : 'https://plus.unsplash.com/premium_photo-1661877737564-3dfd7282efcb?w=800&auto=format&fit=crop&q=60';
        return {
          'name': name,
          'industry': industry,
          'rating': rating.toStringAsFixed(1),
          'image': logo,
        };
      }).toList();

    return SizedBox(
      height: 140,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: companies.length,
        itemBuilder: (context, index) {
          final co = companies[index];
          final String image = co['image']!;
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const CompanyProfileScreen()),
              );
            },
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: image.startsWith('http')
                        ? Image.network(image, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => Image.asset('assets/images/work1.png', width: 60, height: 60, fit: BoxFit.cover))
                        : Image.asset(image, width: 60, height: 60, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(co['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)), maxLines: 2, overflow: TextOverflow.ellipsis),
                        Text(co['industry']!, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFFB020), size: 12),
                            const SizedBox(width: 4),
                            Text(co['rating']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompanyStats(AppState appState) {
    final activeProjects = appState.clientTasks.where((t) => t.status == 'In Progress').length.toString();
    final teamSize = appState.companyProfile?['team_size']?.toString() ?? '1';
    final balance = '\$${appState.walletBalance.toStringAsFixed(0)}';
    final compliance = appState.companyProfile?['is_verified'] == true ? '100%' : 'Pending';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Company Overview",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard("Active Projects", activeProjects, Icons.assignment, Colors.blue),
              const SizedBox(width: 12),
              _buildStatCard("Team Members", teamSize, Icons.group, Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard("Revenue", balance, Icons.payments, Colors.green),
              const SizedBox(width: 12),
              _buildStatCard("Compliance", compliance, Icons.verified_user, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompanySummary(AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF001F3F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Company Workspace',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Track projects, manage services, and review incoming work requests from one place.',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _buildMiniSummary('Services', appState.services.length.toString()),
                const SizedBox(width: 10),
                _buildMiniSummary('Open Work', appState.openMarketplaceTasks.length.toString()),
                const SizedBox(width: 10),
                _buildMiniSummary('Inbox', appState.threads.length.toString()),
              ],
            ),
          ],
        ),
    ),
    );
  }

  Widget _buildMiniSummary(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
            width: double.infinity,
            color: const Color(0xFF001F3F),
            child: Row(
              children: [
                const Icon(Icons.category_outlined, color: Colors.white, size: 28),
                const SizedBox(width: 16),
                const Text("Categories", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return ListTile(
                  leading: Icon(cat['icon'], color: const Color(0xFF001F3F)),
                  title: Text(cat['label'], style: const TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context),
                  trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCBD5E1)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
