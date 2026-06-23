import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'company_registration_screen.dart';
import 'help_center_screen.dart';
import 'dispute_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'post_service_screen.dart';
import 'post_task_screen.dart';
import 'verification_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    this.name,
    this.tagline,
    this.avatar,
    this.isTechnician = false,
  });

  final String? name;
  final String? tagline;
  final String? avatar;
  final bool isTechnician;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final isOwnProfile = name == null;
        final displayName = name ?? appState.currentUser.name;
        final displayTagline = tagline ?? appState.currentUser.tagline;
        final displayAvatar = avatar ?? appState.currentUser.avatar;
        final role = isOwnProfile ? appState.currentRole : (isTechnician ? 'Technician' : 'Client');
        final bottomPadding = MediaQuery.of(context).padding.bottom + 112;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              _goHome(context, appState.currentRole);
            }
          },
          child: Scaffold(
            backgroundColor: const Color(0xFFFEFEFF),
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text('Profile', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w700)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
                onPressed: () => _goHome(context, appState.currentRole),
              ),
            ),
            body: ListView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
              children: [
                _buildHero(displayName, displayTagline, displayAvatar, role),
                const SizedBox(height: 20),
                if (role == 'Technician') ...[
                  _buildSectionCard(
                    title: 'Professional Summary',
                    children: const [
                      Text('Verified technician with in-app bidding, portfolio, and earnings tools enabled.'),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (role == 'Company') ...[
                  _buildSectionCard(
                    title: 'Company Summary',
                    children: [
                      Text('Registered contractor profile with services, project tracking, and compliance flows.'),
                      if (appState.companyRegistrationStatus != null) ...[
                        const SizedBox(height: 12),
                        Text('Registration: ${appState.companyRegistrationStatus}', style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                        if (appState.companyRegistrationSummary != null) ...[
                          const SizedBox(height: 4),
                          Text(appState.companyRegistrationSummary!, style: const TextStyle(color: Color(0xFF64748B))),
                        ],
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                if (role != 'Client' && appState.verificationStatus != null) ...[
                  _buildSectionCard(
                    title: 'Verification Status',
                    children: [
                      Text(appState.verificationStatus!, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                      if (appState.verificationSummary != null) ...[
                        const SizedBox(height: 4),
                        Text(appState.verificationSummary!, style: const TextStyle(color: Color(0xFF64748B))),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                _buildPrimaryActions(context, role, isOwnProfile),
                const SizedBox(height: 16),
                _buildAccountActions(context, role, isOwnProfile),
                const SizedBox(height: 16),
                _buildLogoutAction(context),
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

  Widget _buildHero(String displayName, String displayTagline, String displayAvatar, String role) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 44, backgroundImage: AssetImage(displayAvatar)),
          const SizedBox(height: 16),
          Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 4),
          Text(displayTagline, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
            child: Text(role, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions(BuildContext context, String role, bool isOwnProfile) {
    return _buildSectionCard(
      title: isOwnProfile ? 'Account Actions' : 'Profile Actions',
      children: [
        if (role == 'Client')
          _buildTile(
            icon: Icons.add_task_outlined,
            title: 'Post a Task',
            subtitle: 'Create a new job request',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PostTaskScreen()));
            },
          ),
        if (role == 'Technician')
          _buildTile(
            icon: Icons.add_business_outlined,
            title: 'Post a Service',
            subtitle: 'Publish a new service listing',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PostServiceScreen()));
            },
          ),
        if (role == 'Company')
          _buildTile(
            icon: Icons.business_outlined,
            title: 'Company Registration',
            subtitle: 'Update legal and verification details',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CompanyRegistrationScreen()));
            },
          ),
      ],
    );
  }

  Widget _buildAccountActions(BuildContext context, String role, bool isOwnProfile) {
    return _buildSectionCard(
      title: 'Support & Trust',
      children: [
        if (role != 'Client')
          _buildTile(
            icon: Icons.verified_user_outlined,
            title: 'Verification',
            subtitle: 'Manage identity and compliance review',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const VerificationScreen()));
            },
          ),
        if (role != 'Client')
          _buildTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: 'Track balance, payouts, and transactions',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WalletScreen()));
            },
          ),
        _buildTile(
          icon: Icons.gavel_outlined,
          title: 'Open a Dispute',
          subtitle: 'Report a task issue or resolution request',
          onTap: () {
            final firstTask = AppStateScope.of(context).clientTasks.isNotEmpty
                ? AppStateScope.of(context).clientTasks.first
                : null;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisputeScreen(
                  taskId: firstTask?.id,
                  taskTitle: firstTask?.title,
                ),
              ),
            );
          },
        ),
        _buildTile(
          icon: Icons.help_outline,
          title: 'Help Center',
          subtitle: 'FAQs, support, and platform guidance',
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => const HelpCenterScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildLogoutAction(BuildContext context) {
    return SizedBox(
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
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF1F5F9),
        child: Icon(icon, color: const Color(0xFF001F3F)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
