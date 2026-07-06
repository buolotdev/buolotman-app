import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'company_profile_screen.dart';
import 'listing_screen.dart';
import 'post_task_form_screen.dart';

class CategoryBrowsingScreen extends StatefulWidget {
  const CategoryBrowsingScreen({super.key});

  @override
  State<CategoryBrowsingScreen> createState() => _CategoryBrowsingScreenState();
}

class _CategoryBrowsingScreenState extends State<CategoryBrowsingScreen> {
  String _activeChip = 'All';

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final categories = _deriveCategories(appState);
        final featuredServices = _featuredServices(appState);
        final pros = _topProfessionals(appState);

        return Scaffold(
          backgroundColor: const Color(0xFFFEFEFF),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildPopularChips(categories),
                        _buildSubcategoriesGrid(categories),
                        _buildTopPros(pros),
                        _buildFeaturedServices(featuredServices),
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

  List<String> _deriveCategories(AppState appState) {
    final names = <String>{'All'};
    for (final task in appState.tasks) {
      names.add(task.category);
    }
    for (final service in appState.services) {
      names.add(service.category);
    }
    final categories = names.toList()..sort();
    return ['All', ...categories.where((item) => item != 'All')];
  }

  List<Map<String, dynamic>> _featuredServices(AppState appState) {
    if (appState.services.isEmpty) return [];
    return appState.services.map((service) => {
      'title': service.title,
      'price': service.priceLabel,
      'rating': '', // will be hidden when empty
      'location': appState.currentUser.location,
      'provider': service.category,
      'providerImg': appState.currentUser.avatar,
      'image': appState.currentUser.avatar,
      'badge': 'Listed',
      'badgeIcon': Icons.check_circle_outline,
    }).toList();
  }

  List<Map<String, String>> _topProfessionals(AppState appState) {
    if (appState.publicPros.isEmpty) return [];
    return appState.publicPros.map((user) {
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
        'role': skills.isNotEmpty ? skills : 'Professional',
        'rating': rating > 0 ? rating.toStringAsFixed(1) : '—',
        'reviews': jobs.toString(),
        'avatar': avatar,
      };
    }).toList();
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
            ),
          ),
          const Text(
            'Browse Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PostTaskFormScreen()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              child: const Icon(Icons.add_circle_outline, color: Color(0xFF001F3F)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ListingScreen()),
          );
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: const Row(
            children: [
              Icon(Icons.search, color: Color(0xFF64748B), size: 20),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Search services and tasks...',
                    hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPopularChips(List<String> categories) {
    final chips = categories.take(8).toList();
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          final bool isActive = _activeChip == chip;
          return GestureDetector(
            onTap: () {
              setState(() => _activeChip = chip);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ListingScreen(initialQuery: chip == 'All' ? null : chip)),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF001F3F) : Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: isActive ? const Color(0xFF001F3F) : const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF001F3F).withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                chip,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : const Color(0xFF001F3F),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubcategoriesGrid(List<String> categories) {
    final items = categories.where((item) => item != 'All').take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final title = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => ListingScreen(initialQuery: title)),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF001F3F).withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.category_outlined, color: Color(0xFF001F3F)),
                      ),
                      const Spacer(),
                      Text(
                        title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Browse matching tasks and providers',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTopPros(List<Map<String, String>> pros) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Professionals',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const ListingScreen()),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 195,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: pros.length,
              itemBuilder: (context, index) {
                final pro = pros[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const CompanyProfileScreen()),
                    );
                  },
                  child: Container(
                    width: 140,
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
                          child: buildAvatarImage(pro['avatar']!, width: 64, height: 64, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          pro['name']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                        ),
                        Text(
                          pro['role']!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.star, color: Color(0xFFF59E0B), size: 14),
                            const SizedBox(width: 4),
                            Text(pro['rating']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                            const SizedBox(width: 4),
                            Text('(${pro['reviews']})', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w400)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedServices(List<Map<String, dynamic>> featuredServices) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Featured Services',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
          ),
          const SizedBox(height: 16),
          Column(
            children: featuredServices.map((service) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CompanyProfileScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF001F3F).withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            child: buildAvatarImage(service['image'], height: 160, width: double.infinity, fit: BoxFit.cover),
                          ),
                          if (service['badge'] != null)
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
                                child: Row(
                                  children: [
                                    Icon(service['badgeIcon'], size: 14, color: const Color(0xFFFF4500)),
                                    const SizedBox(width: 4),
                                    Text(
                                      service['badge'],
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFF4500)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    service['title'],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(service['price'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFFF4500))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Color(0xFFF59E0B)),
                                const SizedBox(width: 4),
                                Text(service['rating'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                                const SizedBox(width: 4),
                                Text('(${service['reviews']} reviews)', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                                const SizedBox(width: 8),
                                const Icon(Icons.location_on, size: 16, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    service['location'],
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: buildAvatarImage(service['providerImg'], width: 32, height: 32, fit: BoxFit.cover),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    service['provider'],
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, size: 16, color: Color(0xFF3B82F6)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const CompanyProfileScreen()),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFFF4500)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text(
                                  'View Details',
                                  style: TextStyle(color: Color(0xFFFF4500), fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
