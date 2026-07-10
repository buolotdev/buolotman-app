import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart' as fp;

import 'app_models.dart';
import 'app_state.dart';
import 'chat_screen.dart';
import 'edit_company_profile_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'notifications_screen.dart';
import 'post_service_screen.dart';

/// A single screen that handles two modes:
///   - Own profile (companyData == null): full editing, Logout, Post Service
///   - Public profile (companyData != null): read-only view, Contact button, NO Logout
class CompanyProfileScreen extends StatelessWidget {
  /// Pass this when viewing ANOTHER company's profile (e.g. from Featured Companies).
  /// Leave null to show the logged-in user's own company profile.
  final Map<String, dynamic>? companyData;

  const CompanyProfileScreen({super.key, this.companyData});

  bool get _isPublicView => companyData != null;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final bottomPadding = MediaQuery.of(context).padding.bottom + 140;

        // Determine which data to display
        final Map<String, dynamic> profile = _isPublicView
            ? companyData!
            : (appState.companyProfile ?? {});

        final String displayName = _isPublicView
            ? (companyData!['company_name'] ?? 'Company')
            : appState.currentUser.name;

        final String displayTagline = _isPublicView
            ? (companyData!['services_offered'] is List &&
                    (companyData!['services_offered'] as List).isNotEmpty
                ? (companyData!['services_offered'] as List).first.toString()
                : 'Service Company')
            : appState.currentUser.tagline;

        final bool isVerified = _isPublicView
            ? (companyData!['is_verified'] == true)
            : (appState.companyProfile?['is_verified'] == true);

        return PopScope(
          canPop: _isPublicView, // Public profile can just pop back
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && !_isPublicView) {
              _goHome(context, appState.currentRole);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, appState, displayName),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompanyHeader(
                          appState,
                          displayName: displayName,
                          displayTagline: displayTagline,
                          isVerified: isVerified,
                        ),
                        _buildStats(appState, profile),

                        // Registration / verification status only shown in own profile
                        if (!_isPublicView) ...[
                          if (appState.companyRegistrationStatus != null) ...[
                            _buildSectionTitle('Registration Status'),
                            _buildStatusCard(
                              title: appState.companyProfile?['registration_status']?.toString() == 'verified' ? 'Verified' : 'Pending Review',
                              subtitle: appState.companyProfile?['registration_number']?.toString().isNotEmpty == true
                                  ? 'Reg. No: ${appState.companyProfile!['registration_number']}${appState.companyProfile?['tax_id']?.toString().isNotEmpty == true ? ' | Tax ID: ${appState.companyProfile!['tax_id']}' : ''}'
                                  : 'Registration pending review.',
                            ),
                          ],
                          if (appState.verificationStatus != null) ...[
                            _buildSectionTitle('Verification Status'),
                            _buildStatusCard(
                              title: appState.verificationStatus!,
                              subtitle: appState.verificationSummary ??
                                  'Verification pending review.',
                            ),
                          ],
                        ],

                        _buildSectionTitle('About Company'),
                        _buildOverview(appState, profile),
                        _buildSectionTitle('Services'),
                        _buildServiceCatalog(context, appState, profile),
                        _buildSectionTitle('Team'),
                        _buildTeamSection(appState, profile),
                        _buildPortfolio(context, appState, profile),
                        _buildSectionTitle('Ratings & Reviews'),
                        _buildRatings(context, appState, profile),
                        const SizedBox(height: 28),
                        if (!_isPublicView) _buildEditProfileButton(context),
                        const SizedBox(height: 12),
                        _buildPrimaryActions(context, appState, displayName),
                        const SizedBox(height: 12),

                        // Logout ONLY in own profile view
                        if (!_isPublicView) _buildLogoutButton(context),

                        const SizedBox(height: 24),
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

  void _goHome(BuildContext context, String role) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) =>
              MainNavigationScreen(role: role, initialIndex: 0)),
      (route) => false,
    );
  }

  Widget _buildSliverAppBar(
      BuildContext context, AppState appState, String displayName) {
    final String heroAvatar = _isPublicView
        ? (companyData!['logo_url']?.toString().isNotEmpty == true
            ? companyData!['logo_url']
            : '')
        : appState.currentUser.avatar;

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF001F3F),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          if (_isPublicView) {
            Navigator.of(context).pop();
          } else {
            _goHome(context, appState.currentRole);
          }
        },
      ),
      actions: [
        if (!_isPublicView) ...[
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Edit Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditCompanyProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (heroAvatar.startsWith('http'))
              Image.network(
                heroAvatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF001F3F)),
              )
            else if (heroAvatar.isNotEmpty)
              Image.asset(
                heroAvatar,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF001F3F)),
              )
            else
              Container(
                color: const Color(0xFF001F3F),
                child: Center(
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white24),
                  ),
                ),
              ),
            Container(color: Colors.black.withOpacity(0.30)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(
    AppState appState, {
    required String displayName,
    required String displayTagline,
    required bool isVerified,
  }) {
    final String logoAvatar = _isPublicView
        ? (companyData!['logo_url']?.toString().isNotEmpty == true
            ? companyData!['logo_url']
            : '')
        : appState.currentUser.avatar;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: logoAvatar.startsWith('http')
                ? Image.network(logoAvatar,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _logoFallback(displayName))
                : logoAvatar.isNotEmpty
                    ? Image.asset(logoAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _logoFallback(displayName))
                    : _logoFallback(displayName),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001F3F)),
                ),
                const SizedBox(height: 4),
                if (isVerified)
                  Row(
                    children: const [
                      Icon(Icons.verified, color: Color(0xFF1E8E3E), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Verified Company',
                        style: TextStyle(
                            color: Color(0xFF1E8E3E),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  )
                else
                  Row(
                    children: const [
                      Icon(Icons.pending_outlined,
                          color: Color(0xFFF59E0B), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Verification Pending',
                        style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  displayTagline,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoFallback(String name) {
    return Container(
      color: const Color(0xFF001F3F),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'C',
          style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildStats(AppState appState, Map<String, dynamic> profile) {
    final rating = profile['average_rating']?.toString() ?? '—';
    final completed = profile['completed_tasks']?.toString() ?? '0';
    final teamSize = profile['team_size']?.toString() ?? '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(rating, 'Rating', Icons.star),
          _buildStatItem(completed, 'Completed', Icons.done_all),
          _buildStatItem(teamSize, 'Team Size', Icons.people_outline),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFFFF4500), size: 20),
        const SizedBox(height: 4),
        Text(val,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F3F))),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Text(title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001F3F))),
    );
  }

  Widget _buildStatusCard(
      {required String title, required String subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF001F3F))),
            const SizedBox(height: 6),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(AppState appState, Map<String, dynamic> profile) {
    final about = profile['about']?.toString();
    final String description = about != null && about.isNotEmpty
        ? about
        : _isPublicView
            ? 'No company description provided yet.'
            : 'Registered contractor profile with services, project tracking, and compliance flows.';
    final String industry = profile['industry']?.toString() ?? '';
    final String regNum = profile['registration_number']?.toString() ?? '';
    final String headquarters = profile['headquarters']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 15),
          ),
          if (industry.isNotEmpty || regNum.isNotEmpty || headquarters.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  if (industry.isNotEmpty)
                    _buildInfoRow(Icons.business_outlined, 'Industry', industry),
                  if (regNum.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildInfoRow(Icons.badge_outlined, 'Registration No.', regNum),
                  ],
                  if (headquarters.isNotEmpty) ...[
                    const Divider(height: 16),
                    _buildInfoRow(Icons.location_on_outlined, 'Headquarters', headquarters),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFF4500)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF001F3F), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCatalog(
      BuildContext context, AppState appState, Map<String, dynamic> profile) {
    // Public view: show service chip pills
    if (_isPublicView) {
      final offered = profile['services_offered'];
      final services = offered is List ? offered.map((e) => e.toString()).toList() : <String>[];
      // Also try profile 'services' list which has richer data
      final richServices = profile['services'] as List? ?? [];

      final displayList = richServices.isNotEmpty
          ? richServices.map((s) => s['title']?.toString() ?? '').where((t) => t.isNotEmpty).toList()
          : services;

      if (displayList.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text('No services listed yet.', style: TextStyle(color: Color(0xFF64748B))),
        );
      }
      return SizedBox(
        height: 52,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: displayList.length,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(99)),
            child: Text(displayList[index],
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          ),
        ),
      );
    }

    // Own profile: show richer cards from appState.services
    final services = appState.services
        .where((s) => s.providerId == appState.currentUser.id.toString())
        .toList();
    if (services.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Text('No services listed yet.', style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Post a Service'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500), foregroundColor: Colors.white, elevation: 0),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PostServiceScreen())),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        ...services.take(3).map((svc) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.home_repair_service_outlined, color: Color(0xFFFF4500), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(svc.title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF001F3F), fontSize: 14)),
                      Text('${svc.category} · ${svc.serviceType}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text(svc.priceLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF4500), fontSize: 14)),
              ],
            ),
          ),
        )),
        if (services.length > 3)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Text('+ ${services.length - 3} more services', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
          ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add a Service'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500), foregroundColor: Colors.white, elevation: 0),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PostServiceScreen())),
          ),
        ),
      ],
    );
  }

  Widget _buildTeamSection(
      AppState appState, Map<String, dynamic> profile) {
    final int teamSize =
        int.tryParse(profile['team_size']?.toString() ?? '0') ?? 0;

    if (_isPublicView) {
      // In public view: just show the count, no fake names
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.group_outlined,
                  color: Color(0xFF001F3F), size: 24),
              const SizedBox(width: 12),
              Text(
                teamSize > 0
                    ? '$teamSize team member${teamSize == 1 ? '' : 's'}'
                    : 'Team size not specified',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF001F3F)),
              ),
            ],
          ),
        ),
      );
    }

    // Own profile: show current user as first member + count-based placeholders
    final List<Map<String, String>> team = [
      {
        'name': appState.currentUser.name,
        'role': 'Managing Director',
        'image': appState.currentUser.avatar,
      },
    ];
    // Additional members shown as count only (no fake names)
    final extraCount = (teamSize - 1).clamp(0, 99);

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          ...team.map((member) {
            final img = member['image']!;
            return Container(
              width: 124,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: img.startsWith('http')
                        ? NetworkImage(img)
                        : AssetImage(img) as ImageProvider,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    member['name']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF001F3F)),
                  ),
                  Text(
                    member['role']!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            );
          }),
          if (extraCount > 0)
            Container(
              width: 124,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group, color: Color(0xFF64748B), size: 28),
                  const SizedBox(height: 6),
                  Text(
                    '+$extraCount more',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPortfolio(BuildContext context, AppState appState, Map<String, dynamic> profile) {
    final List<dynamic> items = _isPublicView
        ? (profile['portfolio_items'] ?? [])
        : appState.portfolioItems;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Portfolio & Gallery',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
              ),
              if (!_isPublicView)
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF4500)),
                  onPressed: () => _showAddPortfolioDialog(context, appState),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No portfolio items yet. Add some to showcase your work.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final int itemId = item['id'] ?? 0;
                final imageUrl = item['image_url']?.toString() ?? '';
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: const Color(0xFFF1F5F9),
                        image: imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: getAvatarImageProvider(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl.isEmpty
                          ? const Center(child: Icon(Icons.image_not_supported, color: Color(0xFF94A3B8)))
                          : null,
                    ),
                    if (!_isPublicView && itemId != 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Portfolio Item'),
                                  content: const Text('Are you sure you want to delete this item?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                try {
                                  await appState.removePortfolioItem(itemId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Portfolio item deleted.')),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete: $e')),
                                    );
                                  }
                                }
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddPortfolioDialog(BuildContext context, AppState appState) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final catController = TextEditingController(text: appState.currentUser.skills.isNotEmpty ? appState.currentUser.skills.first : 'General');
    
    String? base64DataUrl;
    String selectedFileName = '';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Portfolio Item', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Project Title',
                        hintText: 'e.g., Office Renovation',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe the work done',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: catController,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        hintText: 'e.g., Commercial',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          if (base64DataUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.memory(
                                base64Decode(base64DataUrl!.split(',').last),
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selectedFileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 8),
                          ],
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await fp.FilePicker.pickFiles(
                                type: fp.FileType.image,
                                withData: true,
                              );
                              if (result != null && result.files.isNotEmpty) {
                                final file = result.files.first;
                                final bytes = file.bytes;
                                if (bytes != null) {
                                  final ext = file.extension ?? 'png';
                                  final b64 = base64Encode(bytes);
                                  setStateDialog(() {
                                    base64DataUrl = 'data:image/$ext;base64,$b64';
                                    selectedFileName = file.name;
                                  });
                                }
                              }
                            },
                            icon: Icon(base64DataUrl == null ? Icons.image : Icons.refresh, size: 18),
                            label: Text(base64DataUrl == null ? 'Select Image File' : 'Change Image'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF001F3F),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a title')),
                      );
                      return;
                    }
                    if (base64DataUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an image')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(child: CircularProgressIndicator()),
                      );
                      await appState.createPortfolioItem(
                        title: titleController.text.trim(),
                        description: descController.text.trim(),
                        category: catController.text.trim(),
                        imageUrl: base64DataUrl!,
                      );
                      if (context.mounted) {
                        Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Portfolio item added successfully!')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.pop(context); // Close loading dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add portfolio item: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4500),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRatings(
      BuildContext context, AppState appState, Map<String, dynamic> profile) {
    final List<dynamic> reviews = profile['reviews'] ?? [];
    final double avgRating =
        double.tryParse(profile['average_rating']?.toString() ?? '0') ?? 0.0;
    final int reviewCount =
        int.tryParse(profile['review_count']?.toString() ?? '0') ?? reviews.length;

    if (reviews.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              const Icon(Icons.star_outline, color: Color(0xFFCBD5E1), size: 40),
              const SizedBox(height: 8),
              const Text(
                'No reviews yet',
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Complete projects to start earning reviews.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF001F3F),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    Row(
                      children: List.generate(5, (i) {
                        if (i < avgRating.floor()) {
                          return const Icon(Icons.star, color: Color(0xFFFBBF24), size: 18);
                        } else if (i < avgRating) {
                          return const Icon(Icons.star_half, color: Color(0xFFFBBF24), size: 18);
                        } else {
                          return const Icon(Icons.star_outline, color: Color(0xFFFBBF24), size: 18);
                        }
                      }),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$reviewCount review${reviewCount == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white60, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Individual reviews
          ...reviews.take(3).map((rev) {
            final name = rev['reviewer_name']?.toString() ?? 'Client';
            final avatar = rev['reviewer_avatar']?.toString() ?? '';
            final rating = (rev['rating'] as num?)?.toDouble() ?? 0;
            final text = rev['text']?.toString() ?? '';
            final service = rev['service']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
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
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFF1F5F9),
                        backgroundImage: avatar.startsWith('http')
                            ? NetworkImage(avatar) as ImageProvider
                            : null,
                        child: !avatar.startsWith('http')
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF001F3F)),
                              )
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF001F3F))),
                            if (service.isNotEmpty)
                              Text(service,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                      Row(
                        children: List.generate(5, (i) => Icon(
                          i < rating ? Icons.star : Icons.star_outline,
                          color: const Color(0xFFFBBF24),
                          size: 14,
                        )),
                      ),
                    ],
                  ),
                  if (text.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(text,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF475569),
                            height: 1.5)),
                  ],
                ],
              ),
            );
          }),
          if (reviews.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${reviews.length - 3} more reviews',
                style:
                    const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const EditCompanyProfileScreen()),
            );
          },
          icon: const Icon(Icons.edit_outlined, color: Color(0xFF001F3F)),
          label: const Text(
            'Edit Company Profile',
            style: TextStyle(
                color: Color(0xFF001F3F), fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF001F3F)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryActions(
      BuildContext context, AppState appState, String displayName) {
    if (_isPublicView) {
      // Public view: show Contact button only
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  final String avatar =
                      companyData!['logo_url']?.toString().isNotEmpty == true
                          ? companyData!['logo_url']
                          : 'assets/images/onboard1.jpg';
                  AppStateScope.of(context).createOrOpenThread(
                    otherPartyName: displayName,
                    otherPartyImage: avatar,
                    initialMessage:
                        'Hi, I would like to ask about your company services.',
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatScreen(name: displayName, image: avatar),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Contact Company',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Own profile: show Post Service + Message (self-message opens inbox)
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const PostServiceScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001F3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Post Company Service',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.message_outlined, color: Color(0xFF001F3F)),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                        name: appState.currentUser.name,
                        image: appState.currentUser.avatar),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () {
            AppStateScope.of(context).logout();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
            );
          },
          icon: const Icon(Icons.logout, color: Color(0xFFB91C1C)),
          label: const Text(
            'Log Out',
            style: TextStyle(
                color: Color(0xFFB91C1C), fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFCA5A5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
