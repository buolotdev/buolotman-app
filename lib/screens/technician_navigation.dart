import 'package:flutter/material.dart';

import 'technician_bids_management_screen.dart';
import 'technician_dashboard_screen.dart';
import 'technician_profile_details_screen.dart';
import 'technician_wallet_screen.dart';

const technicianNavy = Color(0xFF001F3F);
const technicianOrange = Color(0xFFFF4500);

/// Shared technician bottom navigation. It keeps the shell consistent when a
/// user opens a destination from the sidebar or a dashboard card.
class TechnicianBottomNavigation extends StatelessWidget {
  const TechnicianBottomNavigation({super.key, required this.selectedIndex});

  /// Use null for screens that are not represented by a bottom-bar tab,
  /// such as Messages. This keeps Feed from appearing incorrectly selected.
  final int? selectedIndex;

  void _open(BuildContext context, int index) {
    final Widget page = switch (index) {
      0 => const TechnicianDashboardScreen(),
      1 => const TechnicianBidsManagementScreen(),
      2 => const TechnicianWalletScreen(),
      _ => const TechnicianProfileDetailsScreen(),
    };
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: technicianNavy,
        indicatorColor: selectedIndex == null
            ? Colors.transparent
            : technicianOrange.withValues(alpha: .22),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selectedIndex == null || !selected
                ? Colors.white70
                : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selectedIndex == null || !selected
                ? Colors.white70
                : technicianOrange,
          );
        }),
      ),
      child: NavigationBar(
        // NavigationBar requires an index even when selection is hidden; the
        // theme above makes that fallback visually neutral.
        selectedIndex: selectedIndex?.clamp(0, 3) ?? 0,
        onDestinationSelected: (index) => _open(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            label: 'Bids',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Wallet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
