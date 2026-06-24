import 'package:flutter/material.dart';
import 'app_state.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'my_bids_screen.dart';
import 'task_feed_screen.dart';
import 'messages_screen.dart';
import 'my_tasks_screen.dart';
import 'post_task_screen.dart';
import 'wallet_screen.dart';
import 'company_profile_screen.dart';
import 'post_service_screen.dart';
import 'admin_panel_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  final String role;
  const MainNavigationScreen({super.key, this.initialIndex = 0, this.role = 'Client'});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;
  late List<Widget> _screens;
  late List<Map<String, dynamic>> _tabs;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _setupRoleNavigation();
  }

  void _setupRoleNavigation() {
    final role = widget.role.isEmpty ? 'Client' : widget.role;
    if (role == 'Technician') {
      _screens = [
        const TaskFeedScreen(),
        const MyBidsScreen(),
        const WalletScreen(),
        const ProfileScreen(isTechnician: true),
      ];
      _tabs = [
        {'index': 0, 'icon': Icons.grid_view_rounded, 'label': 'Feed'},
        {'index': 1, 'icon': Icons.assignment_outlined, 'label': 'Bids'},
        {'index': 2, 'icon': Icons.account_balance_wallet_outlined, 'label': 'Wallet'},
        {'index': 3, 'icon': Icons.person_outline, 'label': 'Expert'},
      ];
    } else if (role == 'Company') {
      _screens = [
        const DashboardScreen(role: 'Company'),
        const MyTasksScreen(),
        const MessagesScreen(),
        const CompanyProfileScreen(),
      ];
      _tabs = [
        {'index': 0, 'icon': Icons.business, 'label': 'Business'},
        {'index': 1, 'icon': Icons.assignment_turned_in_outlined, 'label': 'Projects'},
        {'index': 2, 'icon': Icons.chat_bubble_outline, 'label': 'Inbox'},
        {'index': 3, 'icon': Icons.storefront, 'label': 'Profile'},
      ];
    } else if (role == 'Admin') {
      _screens = [
        const AdminPanelScreen(),
        const MessagesScreen(),
        const WalletScreen(),
        const ProfileScreen(isTechnician: false),
      ];
      _tabs = [
        {'index': 0, 'icon': Icons.admin_panel_settings_outlined, 'label': 'Admin'},
        {'index': 1, 'icon': Icons.chat_bubble_outline, 'label': 'Inbox'},
        {'index': 2, 'icon': Icons.account_balance_wallet_outlined, 'label': 'Escrow'},
        {'index': 3, 'icon': Icons.person_outline, 'label': 'Profile'},
      ];
    } else {
      // Default: Client
      _screens = [
        const DashboardScreen(role: 'Client'),
        const MyTasksScreen(),
        const MessagesScreen(),
        const ProfileScreen(isTechnician: false),
      ];
      _tabs = [
        {'index': 0, 'icon': Icons.home_filled, 'label': 'Home'},
        {'index': 1, 'icon': Icons.assignment_outlined, 'label': 'My Tasks'},
        {'index': 2, 'icon': Icons.chat_bubble_outline, 'label': 'Inbox'},
        {'index': 3, 'icon': Icons.person_outline, 'label': 'Profile'},
      ];
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final activeRole = widget.role.isEmpty ? appState.currentRole : widget.role;
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (activeRole == 'Client') {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostTaskScreen()));
          } else {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => PostServiceScreen()));
          }
        },
        backgroundColor: const Color(0xFFFF4500),
        elevation: 4,
        child: const Icon(Icons.add, size: 32, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: const Color(0xFF041120),
        elevation: 10,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(_tabs[0]['index'], _tabs[0]['icon'], _tabs[0]['label']),
              _buildNavItem(_tabs[1]['index'], _tabs[1]['icon'], _tabs[1]['label']),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(_tabs[2]['index'], _tabs[2]['icon'], _tabs[2]['label']),
              _buildNavItem(_tabs[3]['index'], _tabs[3]['icon'], _tabs[3]['label']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isActive = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFFFF4500) : const Color(0xFF94A3B8),
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFFFF4500) : const Color(0xFF94A3B8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
