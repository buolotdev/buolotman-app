import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'chat_screen.dart';
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
                              title: appState.companyRegistrationStatus!,
                              subtitle: appState.companyRegistrationSummary ??
                                  'Registration pending review.',
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
                        _buildServiceCatalog(appState, profile),
                        _buildSectionTitle('Team'),
                        _buildTeamSection(appState, profile),
                        _buildSectionTitle('Portfolio'),
                        _buildPortfolioGrid(profile),
                        const SizedBox(height: 28),
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
        if (!_isPublicView)
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
    final description = about != null && about.isNotEmpty
        ? about
        : _isPublicView
            ? 'No company description provided yet.'
            : 'Registered contractor profile with services, project tracking, and compliance flows.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        description,
        style: const TextStyle(
            color: Color(0xFF64748B), height: 1.5, fontSize: 15),
      ),
    );
  }

  Widget _buildServiceCatalog(
      AppState appState, Map<String, dynamic> profile) {
    List<String> services;
    if (_isPublicView) {
      final offered = profile['services_offered'];
      services = offered is List
          ? offered.map((e) => e.toString()).toList()
          : [];
    } else {
      services = appState.services.map((s) => s.title).toList();
    }

    if (services.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('No services listed yet.',
            style: TextStyle(color: Color(0xFF64748B))),
      );
    }

    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: services.length,
        itemBuilder: (context, index) => Container(
          margin: const EdgeInsets.only(right: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(99)),
          child: Text(services[index],
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
        ),
      ),
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
      height: 104,
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

  Widget _buildPortfolioGrid(Map<String, dynamic> profile) {
    final List<dynamic> projects = profile['projects'] ?? [];
    if (projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          'No projects in portfolio yet.',
          style: TextStyle(
              color: Color(0xFF64748B), fontStyle: FontStyle.italic),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        final proj = projects[index];
        final String title = proj['title'] ?? 'Project';
        final String location = proj['location']?.toString().isNotEmpty == true
            ? proj['location']
            : 'Location not specified';
        final int progress = int.tryParse(proj['progress']?.toString() ?? '0') ?? 0;
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  color: const Color(0xFF001F3F),
                  child: const Icon(Icons.business, size: 40, color: Colors.white30),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF001F3F))),
                    const SizedBox(height: 2),
                    Text(location,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text('Progress: $progress%',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF4500))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
