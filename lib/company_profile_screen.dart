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
                        _buildPortfolioGrid(),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('4.9', 'Rating', Icons.star),
          _buildStatItem(appState.openMarketplaceTasks.length.toString(), 'Projects', Icons.done_all),
          _buildStatItem('${appState.services.length + 24}', 'Experts', Icons.people_outline),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        appState.currentUser.role == 'Company'
            ? 'BuildRight Construction handles residential and commercial work with role-based service publishing, messaging, and project management.'
            : 'Company profiles show verification, services, teams, and project tooling for the selected role.',
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
    final team = [
      {'name': appState.currentUser.name, 'role': appState.currentUser.tagline, 'image': appState.currentUser.avatar},
      {'name': 'M. Diallo', 'role': 'Site Supervisor', 'image': 'assets/images/onboard1.jpg'},
      {'name': 'A. Mensah', 'role': 'Project Lead', 'image': 'assets/images/onboard2.jpg'},
      {'name': 'J. Kim', 'role': 'Estimator', 'image': 'assets/images/onboard3.jpg'},
    ];

    return SizedBox(
      height: 104,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: team.length,
        itemBuilder: (context, index) {
          final member = team[index];
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
                CircleAvatar(radius: 20, backgroundImage: AssetImage(member['image'] as String)),
                const SizedBox(height: 8),
                Text(
                  member['name'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
                ),
                Text(
                  member['role'] as String,
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

  Widget _buildPortfolioGrid() {
    final portfolio = [
      {'title': 'Office Wiring', 'subtitle': 'Brooklyn project', 'image': 'assets/images/work1.png'},
      {'title': 'Emergency Repair', 'subtitle': '24h response', 'image': 'assets/images/work2.png'},
      {'title': 'Commercial Setup', 'subtitle': 'Team delivery', 'image': 'assets/images/work1.png'},
      {'title': 'Inspection Ready', 'subtitle': 'Compliance pass', 'image': 'assets/images/work2.png'},
    ];

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
      itemCount: portfolio.length,
      itemBuilder: (context, index) {
        final item = portfolio[index];
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
              Expanded(child: Image.asset(item['image'] as String, fit: BoxFit.cover)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                    const SizedBox(height: 2),
                    Text(item['subtitle'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
