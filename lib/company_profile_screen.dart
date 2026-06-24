import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'chat_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'notifications_screen.dart';
import 'post_service_screen.dart';

class CompanyProfileScreen extends StatelessWidget {
  const CompanyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final bottomPadding = MediaQuery.of(context).padding.bottom + 140;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _goHome(context, appState.currentRole);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.white,
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(context, appState),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: bottomPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCompanyHeader(appState),
                        _buildStats(appState),
                        if (appState.companyRegistrationStatus != null) ...[
                          _buildSectionTitle('Registration Status'),
                          _buildStatusCard(
                            title: appState.companyRegistrationStatus!,
                            subtitle: appState.companyRegistrationSummary ?? 'Registration pending review.',
                          ),
                        ],
                        if (appState.verificationStatus != null) ...[
                          _buildSectionTitle('Verification Status'),
                          _buildStatusCard(
                            title: appState.verificationStatus!,
                            subtitle: appState.verificationSummary ?? 'Verification pending review.',
                          ),
                        ],
                        _buildSectionTitle('About Company'),
                        _buildOverview(appState),
                        _buildSectionTitle('Our Services'),
                        _buildServiceCatalog(appState),
                        _buildSectionTitle('Our Team'),
                        _buildTeamScroll(appState),
                        _buildSectionTitle('Portfolio'),
                        _buildPortfolioGrid(appState),
                        const SizedBox(height: 28),
                        _buildPrimaryActions(context, appState),
                        const SizedBox(height: 12),
                        _buildLogoutButton(context),
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
      MaterialPageRoute(builder: (context) => MainNavigationScreen(role: role, initialIndex: 0)),
      (route) => false,
    );
  }

  Widget _buildSliverAppBar(BuildContext context, AppState appState) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF001F3F),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => _goHome(context, appState.currentRole),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.white),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              appState.currentUser.avatar,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: const Color(0xFF001F3F));
              },
            ),
            Container(color: Colors.black.withOpacity(0.30)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(AppState appState) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(appState.currentUser.avatar, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appState.currentUser.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: const [
                    Icon(Icons.verified, color: Color(0xFF1E8E3E), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'Verified Company',
                      style: TextStyle(color: Color(0xFF1E8E3E), fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  appState.currentUser.tagline,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AppState appState) {
    final rating = appState.companyProfile?['average_rating']?.toString() ?? '4.9';
    final completed = appState.companyProfile?['completed_tasks']?.toString() ?? '0';
    final teamSize = appState.companyProfile?['team_size']?.toString() ?? '1';

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
        Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
    );
  }

  Widget _buildStatusCard({required String title, required String subtitle}) {
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
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview(AppState appState) {
    final about = appState.companyProfile?['about']?.toString();
    final description = about != null && about.isNotEmpty
        ? about
        : 'Registered contractor profile with services, project tracking, and compliance flows.';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        description,
        style: const TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 15),
      ),
    );
  }

  Widget _buildServiceCatalog(AppState appState) {
    final services = appState.services.map((service) => service.title).toList();
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
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(99)),
          child: Text(services[index], style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
        ),
      ),
    );
  }

  Widget _buildTeamScroll(AppState appState) {
    final int teamSize = int.tryParse(appState.companyProfile?['team_size']?.toString() ?? '1') ?? 1;
    final List<Map<String, String>> team = [
      {'name': appState.currentUser.name, 'role': 'Managing Director', 'image': appState.currentUser.avatar},
    ];
    for (int i = 1; i < teamSize; i++) {
      team.add({
        'name': 'Staff Member $i',
        'role': 'Technical Support',
        'image': 'assets/images/onboard1.jpg',
      });
    }

    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: team.length,
        itemBuilder: (context, index) {
          final member = team[index];
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
                  backgroundImage: img.startsWith('http') ? NetworkImage(img) : AssetImage(img) as ImageProvider,
                ),
                const SizedBox(height: 8),
                Text(
                  member['name']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
                ),
                Text(
                  member['role']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortfolioGrid(AppState appState) {
    final List<dynamic> projects = appState.companyProfile?['projects'] ?? [];
    if (projects.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text(
          "No registered projects in portfolio yet.",
          style: TextStyle(color: Color(0xFF64748B), fontStyle: FontStyle.italic),
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
        final String title = proj['title'] ?? 'Company Project';
        final String location = proj['location']?.toString().isNotEmpty == true ? proj['location'] : 'Lagos, Nigeria';
        final String progress = 'Progress: ${proj['progress'] ?? 0}%';
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
                  child: const Icon(Icons.business, size: 40, color: Colors.white70),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                    const SizedBox(height: 2),
                    Text(location, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(progress, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrimaryActions(BuildContext context, AppState appState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PostServiceScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001F3F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('Post Company Service', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.message_outlined, color: Color(0xFF001F3F)),
              onPressed: () {
                AppStateScope.of(context).createOrOpenThread(
                  otherPartyName: appState.currentUser.name,
                  otherPartyImage: appState.currentUser.avatar,
                  initialMessage: 'Hi, I would like to ask about your company services.',
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(name: appState.currentUser.name, image: appState.currentUser.avatar),
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
            style: TextStyle(color: Color(0xFFB91C1C), fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFCA5A5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
