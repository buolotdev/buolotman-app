import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'category_browsing_screen.dart';
import 'listing_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController(text: '');
  final List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).performSearch('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final taskMatches = appState.searchResults
            .where((item) => item['type'] == 'task')
            .map<TaskItem>((t) {
          final double priceVal = double.tryParse(t['price']?.toString() ?? '0') ?? 0.0;
          return TaskItem(
            id: t['id']?.toString() ?? '',
            title: t['name'] ?? '',
            description: t['description'] ?? '',
            category: t['category'] is Map ? (t['category']['name'] ?? 'General') : (t['category']?.toString() ?? 'General'),
            location: t['location'] ?? 'Lagos, Nigeria',
            clientName: t['client'] != null ? '${t['client']['first_name'] ?? ''} ${t['client']['last_name'] ?? ''}'.trim() : (t['client_name'] ?? 'Client'),
            clientAvatar: (t['client'] != null && t['client']['avatar_url'] != null && t['client']['avatar_url'].toString().isNotEmpty) ? t['client']['avatar_url'] : 'assets/images/onboard3.jpg',
            clientRating: t['client'] != null ? (double.tryParse(t['client']['rating']?.toString() ?? '') ?? 4.9) : 4.9,
            budget: priceVal,
            status: 'Open',
            createdLabel: 'Just now',
            schedule: 'Immediate',
            urgency: 'Flexible',
            paymentMethod: 'Escrow / Wallet',
            tags: ['On-site'],
            clientReviews: t['client'] != null ? (int.tryParse(t['client']['tasks_count']?.toString() ?? '') ?? 0) : 0,
          );
        }).toList();

        final serviceMatches = appState.searchResults
            .where((item) => item['type'] == 'service')
            .map<ServiceItem>((s) {
          final double priceVal = double.tryParse(s['price']?.toString() ?? '0') ?? 0.0;
          return ServiceItem(
            id: s['id']?.toString() ?? '',
            title: s['name'] ?? '',
            category: s['category'] is Map ? (s['category']['name'] ?? 'General') : (s['category']?.toString() ?? 'General'),
            description: s['description'] ?? '',
            priceLabel: '\$${priceVal.toStringAsFixed(0)}/hr',
            providerName: s['role'] ?? 'Provider',
            providerAvatar: s['image']?.toString().isNotEmpty == true ? s['image'] : 'assets/images/onboard1.jpg',
            providerRole: s['pricingModel'] ?? 'Technician',
            serviceType: s['serviceType'] ?? 'On-site',
            coverageArea: s['location'] ?? 'Lagos, Nigeria',
            availability: 'Flexible Availability',
            pricingModel: s['pricingModel'] ?? 'Hourly Rate',
            providerId: s['profileId']?.toString() ?? '',
          );
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFFEFEFF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(appState),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildRecentSearches(),
                        if (appState.currentRole == 'Client') _buildSuggestedCategories(),
                        _buildPopularNow(
                          appState.currentRole == 'Client' ? [] : taskMatches,
                          appState.currentRole == 'Client' ? serviceMatches : [],
                        ),
                        if (appState.currentRole == 'Client') _buildTopPros(appState),
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

  Widget _buildHeader(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFFFF4500), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        appState.performSearch(val.trim());
                        setState(() {});
                      },
                      onSubmitted: (val) {
                        final q = val.trim();
                        if (q.isNotEmpty) {
                          if (!_recentSearches.contains(q)) {
                            _recentSearches.insert(0, q);
                          }
                          appState.performSearch(q);
                          setState(() {});
                        }
                      },
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF001F3F)),
                      decoration: const InputDecoration(
                        hintText: 'Search for tasks or pros...',
                        hintStyle: TextStyle(color: Color(0xFF64748B)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      appState.performSearch('');
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Color(0xFFE2E8F0), shape: BoxShape.circle),
                      child: const Icon(Icons.close, size: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _showFilterSheet(appState),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: Color(0xFF001F3F), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        String selectedType = 'all';
        double minBudget = 0;
        double maxBudget = 1000;
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Filter Results",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text(
                      "Result Type",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildFilterOption(
                          label: "All",
                          active: selectedType == 'all',
                          onTap: () => setSheetState(() => selectedType = 'all'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterOption(
                          label: "Tasks",
                          active: selectedType == 'tasks',
                          onTap: () => setSheetState(() => selectedType = 'tasks'),
                        ),
                        const SizedBox(width: 8),
                        _buildFilterOption(
                          label: "Services",
                          active: selectedType == 'services',
                          onTap: () => setSheetState(() => selectedType = 'services'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Budget Range",
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                    ),
                    RangeSlider(
                      values: RangeValues(minBudget, maxBudget),
                      min: 0,
                      max: 2000,
                      divisions: 40,
                      activeColor: const Color(0xFFFF4500),
                      inactiveColor: const Color(0xFFE2E8F0),
                      labels: RangeLabels("\$${minBudget.round()}", "\$${maxBudget.round()}"),
                      onChanged: (values) {
                        setSheetState(() {
                          minBudget = values.start;
                          maxBudget = values.end;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("\$${minBudget.round()}", style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text("\$${maxBudget.round()}", style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          appState.performSearch(
                            _searchController.text.trim(),
                            tab: selectedType,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4500),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("Apply Filters", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterOption({required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF001F3F) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF001F3F),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
              GestureDetector(
                onTap: () => setState(() => _recentSearches.clear()),
                child: const Text('Clear All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._recentSearches.map((search) => Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Color(0xFF64748B), size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text(search, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF001F3F)))),
                    GestureDetector(
                      onTap: () => setState(() => _recentSearches.remove(search)),
                      child: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSuggestedCategories() {
    final appState = AppStateScope.of(context);
    final categories = appState.apiCategories.take(6).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Suggested Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories
                .map(
                  (cat) => GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ListingScreen(initialQuery: cat['name'] as String)),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.category_outlined, size: 16, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Text(cat['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CategoryBrowsingScreen()));
            },
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Browse All Categories', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w600, fontSize: 14)),
                SizedBox(width: 8),
                Icon(Icons.chevron_right, size: 16, color: Color(0xFF001F3F)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularNow(List<dynamic> tasks, List<dynamic> services) {
    final items = [
      ...tasks.take(2).map((task) => {
            'title': task.title,
            'subtitle': task.location,
            'icon': Icons.work_outline,
            'target': task.title,
          }),
      ...services.take(2).map((service) => {
            'title': service.title,
            'subtitle': service.category,
            'icon': Icons.auto_awesome,
            'target': service.title,
          }),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Popular Right Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 16),
          ...items.map(
            (item) => GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ListingScreen(initialQuery: item['target'] as String)),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4500).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(item['icon'] as IconData, color: const Color(0xFFFF4500)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                          Text(item['subtitle'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPros(AppState appState) {
    final rawPros = appState.publicPros;
    if (rawPros.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 24, 20, 0),
        child: Text('No professionals found yet.',
            style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    final pros = rawPros.map((user) {
      final String name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isNotEmpty
          ? '${user['first_name']} ${user['last_name']}'.trim()
          : (user['username'] ?? 'Professional');
      final String avatar = user['avatar_url']?.toString().isNotEmpty == true
          ? user['avatar_url']
          : 'assets/images/onboard1.jpg';
      final skills = user['skills'] is List
          ? (user['skills'] as List).join(', ')
          : 'Specialist';
      final double rating = double.tryParse(user['average_rating']?.toString() ?? '') ?? 0.0;
      final int jobs = int.tryParse(user['completed_jobs']?.toString() ?? '0') ?? 0;
      return {
        'name': name,
        'rating': rating > 0 ? '${rating.toStringAsFixed(1)} ($jobs)' : '—',
        'trade': skills.isNotEmpty ? skills : 'Professional',
        'avatar': avatar,
      };
    }).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Top Pros Nearby', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
              const Text('See All', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: pros.length,
              itemBuilder: (context, index) {
                final pro = pros[index];
                return Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: buildAvatarImage(pro['avatar'] as String, width: 64, height: 64, fit: BoxFit.cover),
                      ),
                      const SizedBox(height: 8),
                      Text(pro['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)), overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star, color: Color(0xFFEAB308), size: 14),
                          const SizedBox(width: 4),
                          Text(pro['rating'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
