import 'package:flutter/material.dart';
import '../core/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.role});
  final String role;
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiService();
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool get isVerified =>
      _profile?['is_verified'] == true ||
      (_profile?['technician_profile'] is Map &&
          _profile!['technician_profile']['is_verified'] == true);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _api.profile();
      if (mounted)
        setState(() {
          _profile = p;
          _loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = (_profile?['first_name'] ?? '').toString().trim();
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Boulot Man',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF001F3F),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            Text(
              'Welcome${name.isEmpty ? '' : ', $name'}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF001F3F),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${_roleLabel(widget.role)} workspace',
              style: const TextStyle(fontSize: 15, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 22),
            if (widget.role == 'TECHNICIAN' && !isVerified) _notice(),
            _section('Quick access', [
              _action(
                Icons.person_outline,
                'My profile',
                'Complete your professional details',
              ),
              _action(
                Icons.verified_user_outlined,
                'Verification',
                'Upload documents and track review',
              ),
              _action(
                Icons.account_balance_wallet_outlined,
                'Wallet',
                'View balance and payouts',
              ),
              _action(
                Icons.notifications_none,
                'Notifications',
                'Stay updated on account activity',
              ),
            ]),
            const SizedBox(height: 18),
            _section('Work', [
              _action(
                Icons.work_outline,
                'Task feed',
                isVerified
                    ? 'Browse live client tasks'
                    : 'Available after admin approval',
              ),
              _action(
                Icons.assignment_outlined,
                'My bids',
                isVerified
                    ? 'Track submitted bids'
                    : 'Available after admin approval',
              ),
              _action(
                Icons.chat_bubble_outline,
                'Messages',
                'Chat with clients and support',
              ),
            ]),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFFFF4500)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String v) => switch (v) {
    'TECHNICIAN' => 'Technician',
    'COMPANY' => 'Company',
    'ADMIN' => 'Admin',
    _ => 'Client',
  };
  Widget _notice() => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFBEB),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFFCD34D)),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: Color(0xFFD97706)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Your account is pending admin verification. Profile, documents, wallet, messages, and notifications remain available. Task browsing and bidding unlock after approval.',
            style: TextStyle(
              color: Color(0xFF92400E),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  Widget _section(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: Color(0xFF001F3F),
        ),
      ),
      const SizedBox(height: 10),
      ...children,
    ],
  );
  Widget _action(IconData icon, String title, String subtitle) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 10),
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFFEDE7),
        child: Icon(icon, color: const Color(0xFFFF4500)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: Color(0xFF001F3F),
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
    ),
  );
}
