import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'browse_tasks_screen.dart';
import 'company_profile_screen.dart';
import 'profile_screen.dart';

class ListingScreen extends StatefulWidget {
  final String? initialQuery;
  const ListingScreen({super.key, this.initialQuery});

  @override
  State<ListingScreen> createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> {
  late final TextEditingController _searchController;
  String _activeFilter = 'All Categories';

  final List<Map<String, dynamic>> _filters = const [
    {'label': 'All Categories', 'icon': null},
    {'label': '4.5+ Rating', 'icon': Icons.star},
    {'label': 'Nearest to me', 'icon': Icons.location_on},
    {'label': 'Available Today', 'icon': Icons.access_time},
    {'label': 'Under \$100', 'icon': null},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).performSearch(_searchController.text.trim());
    });
  }

  @override
  void didUpdateWidget(covariant ListingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery && widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      AppStateScope.of(context).performSearch(widget.initialQuery!);
    }
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
        final services = appState.searchResults
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
        }).where((service) => _matchesServiceFilter(service)).toList();

        final tasks = appState.searchResults
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
        }).where((task) => _matchesTaskFilter(task, appState)).toList();

        final totalCount = services.length + tasks.length;

        return Scaffold(
          backgroundColor: const Color(0xFFFEFEFF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(appState),
                Expanded(
                  child: Column(
                    children: [
                      _buildFilterBar(),
                      _buildResultsCount(totalCount),
                      Expanded(
                        child: totalCount == 0
                            ? _buildEmptyState()
                            : ListView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                children: [
                                  for (final service in services) _buildServiceCard(service),
                                  for (final task in tasks) _buildTaskCard(task),
                                ],
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
    );
  }

  bool _matchesServiceFilter(dynamic service) {
    switch (_activeFilter) {
      case 'Under \$100':
        final price = _extractPrice(service.priceLabel);
        return price == null || price < 100;
      default:
        return true;
    }
  }

  bool _matchesTaskFilter(dynamic task, AppState appState) {
    switch (_activeFilter) {
      case '4.5+ Rating':
        return task.clientRating >= 4.5;
      case 'Nearest to me':
        final city = appState.currentUser.location.split(',').first.trim().toLowerCase();
        return city.isNotEmpty && task.location.toLowerCase().contains(city);
      case 'Available Today':
        return task.urgency.toLowerCase() == 'urgent' || task.schedule.toLowerCase().contains('today');
      case 'Under \$100':
        return task.budget < 100;
      default:
        return true;
    }
  }

  double? _extractPrice(String priceLabel) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(priceLabel.replaceAll(',', ''));
    if (match == null) {
      return null;
    }
    return double.tryParse(match.group(1)!);
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
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        appState.performSearch(val.trim());
                        setState(() {});
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search for plumbers, electricians...',
                        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isActive = _activeFilter == filter['label'];
          return GestureDetector(
            onTap: () => setState(() => _activeFilter = filter['label']),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF001F3F) : Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: isActive ? const Color(0xFF001F3F) : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  if (filter['icon'] != null) ...[
                    Icon(
                      filter['icon'],
                      size: 14,
                      color: isActive
                          ? Colors.white
                          : (filter['icon'] == Icons.star ? const Color(0xFFF59E0B) : const Color(0xFF001F3F)),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    filter['label'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : const Color(0xFF001F3F),
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

  Widget _buildResultsCount(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'Showing $count results nearby',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_search_outlined, size: 76, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No matching services or tasks',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try a different query or clear the filter chip.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchController.clear();
                  _activeFilter = 'All Categories';
                });
              },
              child: const Text('Reset Search'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(dynamic service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.work_outline, color: Color(0xFF001F3F)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.category.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFF4500)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.providerName,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Text(
                service.priceLabel,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFF4500)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${service.serviceType} · ${service.availability}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
              TextButton(
              onPressed: () {
                _openProviderProfile(service);
              },
              child: const Text('View Profile', style: TextStyle(color: Color(0xFFFF4500))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                _openProviderProfile(service);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF4500)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Open', style: TextStyle(color: Color(0xFFFF4500), fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                AppStateScope.of(context).toggleSavedService(service.id);
              },
              icon: Icon(
                AppStateScope.of(context).isServiceSaved(service.id) ? Icons.bookmark : Icons.bookmark_border,
                color: const Color(0xFF001F3F),
              ),
              label: Text(
                AppStateScope.of(context).isServiceSaved(service.id) ? 'Saved' : 'Save Service',
                style: const TextStyle(color: Color(0xFF001F3F)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openProviderProfile(dynamic service) {
    if (service.providerRole == 'Company') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const CompanyProfileScreen()),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProfileScreen(
          name: service.providerName,
          tagline: service.providerRole,
          avatar: service.providerAvatar,
          isTechnician: service.providerRole == 'Technician',
        ),
      ),
    );
  }

  Widget _buildTaskCard(dynamic task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.category.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
          const SizedBox(height: 4),
          Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 6),
          Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Expanded(child: Text(task.location, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)))),
              Text('\$${task.budget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFF4500))),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => BrowseTasksScreen(taskId: task.id)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001F3F),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Open Task'),
            ),
          ),
        ],
      ),
    );
  }
}
