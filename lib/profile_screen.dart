import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:country_picker/country_picker.dart';
import 'package:file_picker/file_picker.dart' as fp;

import 'app_state.dart';
import 'company_registration_screen.dart';
import 'help_center_screen.dart';
import 'dispute_screen.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';
import 'post_service_screen.dart';
import 'post_task_form_screen.dart';
import 'technician_profile_settings_screen.dart';
import 'verification_screen.dart';
import 'wallet_screen.dart';
import 'messages_screen.dart';

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
                _buildHero(context, appState, displayName, displayTagline, displayAvatar, role, isOwnProfile),
                const SizedBox(height: 20),
                if (role == 'Technician') ...[
                  _buildSectionCard(
                    title: 'Personal Details',
                    children: [
                      _buildDetailRow('First Name', appState.currentUser.firstName),
                      _buildDetailRow('Last Name', appState.currentUser.lastName),
                      _buildDetailRow('Phone Number', appState.currentUser.phone),
                      _buildDetailRow('Country', appState.currentUser.country),
                      _buildDetailRow('Bio', appState.currentUser.bio),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Skills & Categories',
                    children: [
                      if (appState.currentUser.skills.isEmpty)
                        const Text('No skills added yet.', style: TextStyle(color: Color(0xFF64748B)))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: appState.currentUser.skills.map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Experience',
                    children: [
                      Text(
                        appState.currentUser.experience.isNotEmpty ? appState.currentUser.experience : 'No experience details added yet.',
                        style: const TextStyle(color: Color(0xFF001F3F)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Certifications',
                    children: [
                      if (appState.currentUser.certifications.isEmpty)
                        const Text('No certifications added yet.', style: TextStyle(color: Color(0xFF64748B)))
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: appState.currentUser.certifications.map((c) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEAD8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Availability',
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 12,
                            color: appState.currentUser.availabilityStatus == 'available'
                                ? Colors.green
                                : (appState.currentUser.availabilityStatus == 'busy' ? Colors.orange : Colors.grey),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            appState.currentUser.availabilityStatus.toUpperCase(),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildSectionCard(
                    title: 'Pricing',
                    children: [
                      Text(
                        '\$${appState.currentUser.hourlyRate.toStringAsFixed(2)} / hour',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFFF4500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPortfolio(context, appState, isOwnProfile),
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

  Widget _buildHero(BuildContext context, AppState appState, String displayName, String displayTagline, String displayAvatar, String role, bool isOwnProfile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: (displayAvatar.isNotEmpty && !displayAvatar.contains('onboard'))
                ? getAvatarImageProvider(displayAvatar)
                : null,
            child: (displayAvatar.isEmpty || displayAvatar.contains('onboard'))
                ? const Icon(Icons.person, size: 48, color: Color(0xFF94A3B8))
                : null,
          ),
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
          if (isOwnProfile) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: () {
                if (role == 'Technician') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TechnicianProfileSettingsScreen()));
                } else {
                  _showEditProfileDialog(context, appState);
                }
              },
              icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFFFF4500)),
              label: const Text('Edit Profile Details', style: TextStyle(color: Color(0xFFFF4500), fontWeight: FontWeight.bold, fontSize: 13)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: Color(0xFFFF4500)),
                ),
              ),
            ),
          ],
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
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const PostTaskFormScreen()));
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
        if (role == 'Technician')
          _buildTile(
            icon: Icons.chat_bubble_outline,
            title: 'Inbox / Messages',
            subtitle: 'Chat with clients and manage tasks',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const MessagesScreen()));
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
    if (role == 'Technician') {
      return _buildSectionCard(
        title: 'Support & Trust',
        children: [
          _buildTile(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Wallet',
            subtitle: 'Track balance, payouts, and transactions',
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => const WalletScreen()));
            },
          ),
        ],
      );
    }
    
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
    return Column(
      children: [
        SizedBox(
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
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => _confirmDeleteAccount(context),
            child: const Text(
              'Delete Account',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Account?',
          style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
        ),
        content: const Text(
          'This will permanently delete your account and all your data. '
          'You cannot undo this action.\n\n'
          'If you want to re-register with a different role, you can sign up again after deletion.',
          style: TextStyle(color: Color(0xFF64748B), height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await AppStateScope.of(context).deleteAccount();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB91C1C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
    Widget? action,
  }) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
                ),
              ),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF64748B), fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'Not provided',
              style: const TextStyle(color: Color(0xFF001F3F), fontSize: 14),
            ),
          ),
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

  void _showEditProfileDialog(BuildContext context, AppState appState) {
    final firstName = appState.currentUser.firstName;
    final lastName = appState.currentUser.lastName;
    final phone = appState.currentUser.phone;
    final country = appState.currentUser.country;
    
    final firstNameController = TextEditingController(text: firstName);
    final lastNameController = TextEditingController(text: lastName);
    final phoneController = TextEditingController(text: phone);
    final countryController = TextEditingController(text: country.isNotEmpty ? country : 'Nigeria');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Edit Profile Info',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: firstNameController,
                  decoration: const InputDecoration(labelText: 'First Name', labelStyle: TextStyle(color: Color(0xFF64748B))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: lastNameController,
                  decoration: const InputDecoration(labelText: 'Last Name', labelStyle: TextStyle(color: Color(0xFF64748B))),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: Color(0xFF64748B))),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    showCountryPicker(
                      context: context,
                      showPhoneCode: false,
                      onSelect: (Country selectedCountry) {
                        countryController.text = selectedCountry.name;
                      },
                    );
                  },
                  child: AbsorbPointer(
                    child: TextField(
                      controller: countryController,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        labelStyle: TextStyle(color: Color(0xFF64748B)),
                        suffixIcon: Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
                    ),
                  ),
                );
                try {
                  await appState.updateProfile(
                    firstName: firstNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    phone: phoneController.text.trim(),
                    country: countryController.text.trim(),
                  );
                  if (context.mounted) {
                    Navigator.of(context).pop(); // pop loader
                    Navigator.of(ctx).pop(); // pop edit dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Profile updated successfully.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // pop loader
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
  Widget _buildPortfolio(BuildContext context, AppState appState, bool isOwnProfile) {
    return _buildSectionCard(
      title: 'Portfolio & Gallery',
      action: isOwnProfile
          ? IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Color(0xFFFF4500)),
              onPressed: () => _showAddPortfolioDialog(context, appState),
            )
          : null,
      children: [
        if (appState.portfolioItems.isEmpty)
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
            itemCount: appState.portfolioItems.length,
            itemBuilder: (context, index) {
              final item = appState.portfolioItems[index];
              final int itemId = item['id'] ?? 0;
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFFF1F5F9),
                      image: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                          ? DecorationImage(
                              image: getAvatarImageProvider(item['image_url']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: item['image_url'] == null || item['image_url'].toString().isEmpty
                        ? const Center(child: Icon(Icons.image_not_supported, color: Color(0xFF94A3B8)))
                        : null,
                  ),
                  if (isOwnProfile && itemId != 0)
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
                        hintText: 'e.g., Leaking Pipes Fixed',
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
                        hintText: 'e.g., Plumbing',
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
                              elevation: 0,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    final t = titleController.text.trim();
                    final d = descController.text.trim();
                    final c = catController.text.trim();
                    if (t.isEmpty || c.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Title and Category are required.')),
                      );
                      return;
                    }
                    if (base64DataUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select an image file.')),
                      );
                      return;
                    }
                    Navigator.pop(ctx);
                    BuildContext? loaderContext;
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (lCtx) {
                        loaderContext = lCtx;
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
                          ),
                        );
                      },
                    );
                    try {
                      await appState.createPortfolioItem(
                        title: t,
                        description: d,
                        category: c,
                        imageUrl: base64DataUrl!,
                      );
                      if (loaderContext != null && loaderContext!.mounted) {
                        Navigator.pop(loaderContext!);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Portfolio item added successfully!')),
                        );
                      }
                    } catch (e) {
                      if (loaderContext != null && loaderContext!.mounted) {
                        Navigator.pop(loaderContext!);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to add portfolio item: $e')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4500),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
