import 'package:flutter/material.dart';

import 'technician_area_screens.dart';
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

  final int selectedIndex;

  void _open(BuildContext context, int index) {
    final Widget page = switch (index) {
      0 => const TechnicianDashboardScreen(),
      1 => const TechnicianBidsManagementScreen(),
      2 => const TechnicianWalletScreen(),
      _ => const TechnicianProfileDetailsScreen(),
    };
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: technicianNavy,
        indicatorColor: technicianOrange.withValues(alpha: .22),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? technicianOrange : Colors.white70);
        }),
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex.clamp(0, 3),
        onDestinationSelected: (index) => _open(context, index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Feed'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), label: 'Bids'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Wallet'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
