import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'technician_public_profile_screen.dart';

class BrowseProfessionalsScreen extends StatefulWidget {
  const BrowseProfessionalsScreen({super.key});

  @override
  State<BrowseProfessionalsScreen> createState() => _BrowseProfessionalsScreenState();
}

class _BrowseProfessionalsScreenState extends State<BrowseProfessionalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Plumbing',
    'Electrical',
    'HVAC',
    'Carpentry',
    'Painting',
    'Masonry',
    'Security',
    'Cleaning',
    'Furniture'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final query = _searchController.text.trim().toLowerCase();
        final filteredPros = appState.publicPros.where((user) {
          final String name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().toLowerCase();
          final skills = (user['skills'] is List ? (user['skills'] as List).join(', ') : 'Technician').toLowerCase();

          // 1. Search Query filter
          if (query.isNotEmpty && !name.contains(query) && !skills.contains(query)) {
            return false;
          }

          // 2. Category tag filter
          if (_selectedCategory != 'All') {
            final catLower = _selectedCategory.toLowerCase();
            if (!skills.contains(catLower)) {
              return false;
            }
          }

          return true;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFFEFEFF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Browse Professionals",
              style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                _buildSearchSection(),
                _buildCategoryChips(),
                Expanded(
                  child: filteredPros.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredPros.length,
                          itemBuilder: (context, index) {
                            final user = filteredPros[index];
                            return _buildProfessionalCard(user, appState);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: "Search by name or skills...",
                  hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                  });
                },
                child: const Icon(Icons.close, color: Color(0xFF64748B), size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final active = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF001F3F) : Colors.white,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: active ? const Color(0xFF001F3F) : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : const Color(0xFF001F3F),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfessionalCard(Map<String, dynamic> user, AppState appState) {
    final String techId = user['id']?.toString() ?? '';
    final String name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isNotEmpty
        ? '${user['first_name']} ${user['last_name']}'.trim()
        : (user['username'] ?? 'Technician');
    final String avatar = user['avatar_url']?.toString().isNotEmpty == true ? user['avatar_url'] : 'assets/images/onboard1.jpg';
    final skills = user['skills'] is List ? (user['skills'] as List).join(', ') : 'Technician';
    final double rating = double.tryParse(user['average_rating']?.toString() ?? '') ?? 0.0;
    final int completedJobs = int.tryParse(user['completed_jobs']?.toString() ?? '0') ?? 0;
    final double rate = double.tryParse(user['hourly_rate']?.toString() ?? '0') ?? 0.0;
    final bool isSaved = appState.isTechSaved(techId);

    final priceLabel = rate > 0 ? '\$${rate.toStringAsFixed(0)}/hr' : 'Rate not set';
    final ratingLabel = rating > 0 ? '$rating ($completedJobs)' : '—';
    final specialty = skills.isNotEmpty ? skills : 'Professional Specialist';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: avatar.startsWith('http')
                    ? Image.network(avatar, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => Image.asset('assets/images/onboard1.jpg', width: 56, height: 56, fit: BoxFit.cover))
                    : Image.asset(avatar, width: 56, height: 56, fit: BoxFit.cover),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (user['is_verified'] == true)
                          const Icon(Icons.verified, color: Colors.blue, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      specialty,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13, color: Color(0xFFFF4500), fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFF59E0B), size: 15),
                        const SizedBox(width: 4),
                        Text(
                          ratingLabel,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.location_on, color: Color(0xFF64748B), size: 14),
                        const SizedBox(width: 4),
                        Text(
                          user['country']?.toString().isNotEmpty == true ? user['country'].toString() : "Nigeria",
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  appState.toggleSavedTech(techId);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isSaved ? const Color(0xFFFFF0EB) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? const Color(0xFFFF4500) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                priceLabel,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TechnicianPublicProfileScreen(
                        name: name,
                        skill: specialty,
                        avatar: avatar,
                        price: priceLabel,
                        rating: ratingLabel,
                        rawData: user,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 0,
                ),
                child: const Text("View Profile", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
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
            Icon(Icons.people_outline, size: 76, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "No professionals found",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Try searching for another skill category or adjust your keyword query.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
