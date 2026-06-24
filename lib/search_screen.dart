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
  final TextEditingController _searchController = TextEditingController(text: 'Plumbing services');
  final List<String> _recentSearches = [
    'Emergency plumber Brooklyn',
    'AC repair and installation',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).performSearch(_searchController.text.trim());
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
            category: t['category'] ?? 'General',
            location: t['location'] ?? 'Lagos, Nigeria',
            clientName: t['client_name'] ?? 'Client',
            clientAvatar: 'assets/images/onboard3.jpg',
            clientRating: 4.9,
            budget: priceVal,
            status: 'Open',
            createdLabel: 'Just now',
            schedule: 'Immediate',
            urgency: 'Flexible',
            paymentMethod: 'Escrow / Wallet',
            tags: ['On-site'],
          );
        }).toList();

        final serviceMatches = appState.searchResults
            .where((item) => item['type'] == 'service')
            .map<ServiceItem>((s) {
          final double priceVal = double.tryParse(s['price']?.toString() ?? '0') ?? 0.0;
          return ServiceItem(
            id: s['id']?.toString() ?? '',
            title: s['name'] ?? '',
            category: s['category'] ?? 'General',
            description: s['description'] ?? '',
            priceLabel: '\$${priceVal.toStringAsFixed(0)}/hr',
            providerName: s['role'] ?? 'Provider',
            providerAvatar: s['image']?.toString().isNotEmpty == true ? s['image'] : 'assets/images/onboard1.jpg',
            providerRole: s['pricingModel'] ?? 'Technician',
            serviceType: s['serviceType'] ?? 'On-site',
            coverageArea: s['location'] ?? 'Lagos, Nigeria',
            availability: 'Flexible Availability',
            pricingModel: s['pricingModel'] ?? 'Hourly Rate',
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
                        _buildSuggestedCategories(),
                        _buildPopularNow(taskMatches, serviceMatches),
                        _buildTopPros(appState),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune, color: Color(0xFF001F3F), size: 20),
          ),
        ],
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
    final categories = [
      {'label': 'Electrical', 'icon': Icons.bolt},
      {'label': 'Plumbing', 'icon': Icons.opacity},
      {'label': 'Carpentry', 'icon': Icons.handyman},
      {'label': 'Painting', 'icon': Icons.format_paint},
      {'label': 'Moving Services', 'icon': Icons.local_shipping},
      {'label': 'Handyman', 'icon': Icons.build},
    ];

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
                        MaterialPageRoute(builder: (context) => ListingScreen(initialQuery: cat['label'] as String)),
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
                          Icon(cat['icon'] as IconData, size: 18, color: const Color(0xFF001F3F)),
                          const SizedBox(width: 8),
                          Text(cat['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
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
    final pros = [
      {'name': appState.currentRole == 'Technician' ? appState.currentUser.name : 'Michael T.', 'rating': '4.9 (120)', 'trade': 'Electrician', 'avatar': 'assets/images/onboard1.jpg'},
      {'name': 'Sarah L.', 'rating': '5.0 (85)', 'trade': 'House Cleaner', 'avatar': 'assets/images/onboard2.jpg'},
      {'name': 'David R.', 'rating': '4.8 (210)', 'trade': 'Plumber', 'avatar': 'assets/images/onboard3.jpg'},
    ];

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
