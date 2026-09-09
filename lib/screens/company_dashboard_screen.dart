import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'login_screen.dart';
import 'company_profile_screen.dart';
import 'company_settings_screen.dart';
import 'company_services_screen.dart';
import 'company_workflow_screens.dart';
import 'client_messaging_screen.dart';
import 'server_notifications_screen.dart';

class CompanyDashboardScreen extends StatefulWidget {
  const CompanyDashboardScreen({super.key});
  @override
  State<CompanyDashboardScreen> createState() => _CompanyDashboardState();
}

class _CompanyDashboardState extends State<CompanyDashboardScreen> {
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      muted = Color(0xFF64748B),
      bg = Color(0xFFF5F7FA);
  final api = ApiService();
  int tab = 0;
  bool loading = true, loadError = false, drawerOpen = false;
  Map<String, dynamic> profile = {}, wallet = {};
  List<dynamic> projects = [],
      services = [],
      quotes = [],
      activities = [],
      messages = [],
      notifications = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<dynamic> _list(dynamic value) => value is List
      ? value
      : value is Map && value['results'] is List
      ? value['results'] as List
      : const [];
  bool _verified() => profile['is_verified'] == true;
  Future<void> _load() async {
    try {
      final v = await Future.wait<dynamic>([
        api.companyProfile(),
        api.companyProjects(),
        api.companyServices(),
        api.companyQuotes(),
        api.companyActivities(),
        api.wallet(),
        api.conversations(),
        api.notifications(),
      ]);
      if (!mounted) return;
      setState(() {
        profile = v[0] is Map ? Map<String, dynamic>.from(v[0]) : {};
        projects = _list(v[1]);
        services = _list(v[2]);
        quotes = _list(v[3]);
        activities = _list(v[4]);
        wallet = v[5] is Map ? Map<String, dynamic>.from(v[5]) : {};
        messages = _list(v[6]);
        notifications = _list(v[7]);
        loading = false;
        loadError = false;
      });
    } catch (_) {
      if (mounted)
        setState(() {
          loading = false;
          loadError = true;
        });
    }
  }

  void _open(String title, {bool restricted = false}) {
    setState(() => drawerOpen = false);
    if (title == 'Company profile') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
      );
      return;
    }
    if (title == 'Settings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanySettingsScreen()),
      );
      return;
    }
    if (title == 'Services') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanyServicesScreen()),
      );
      return;
    }
    if (title == 'Projects') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanyProjectsScreen()),
      );
      return;
    }
    if (title == 'Quote requests') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanyQuotesScreen()),
      );
      return;
    }
    if (title == 'Team') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanyTeamScreen()),
      );
      return;
    }
    if (title == 'Reviews' || title == 'Analytics') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanyInsightsScreen()),
      );
      return;
    }
    if (title == 'Wallet') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CompanyWalletScreen()),
      );
      return;
    }
    if (title == 'Notifications') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ServerNotificationsScreen()),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CompanyPlaceholderScreen(
          title: title,
          restricted: restricted,
          verified: _verified(),
        ),
      ),
    );
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _logout() async {
    await api.clearSession();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onHorizontalDragEnd: (details) {
      if ((details.primaryVelocity ?? 0) > 250 && !drawerOpen) _showDrawer();
    },
    child: Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: tab == 0
            ? _home()
            : tab == 1
            ? _projects()
            : tab == 2
            ? _messages()
            : _profile(),
      ),
      bottomNavigationBar: _bottom(),
    ),
  );
  Widget _header(String title) => Row(
    children: [
      IconButton(
        onPressed: _showDrawer,
        icon: const Icon(Icons.menu, color: navy),
      ),
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: navy,
            fontSize: 23,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      Stack(
        children: [
          IconButton(
            onPressed: () => _open('Notifications'),
            icon: const Icon(Icons.notifications_none, color: navy),
          ),
          if (notifications.any((n) => n is Map && n['is_read'] != true))
            Positioned(
              right: 5,
              top: 5,
              child: Container(
                width: 9,
                height: 9,
                decoration: const BoxDecoration(
                  color: orange,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
      IconButton(
        onPressed: () => setState(() => tab = 2),
        icon: const Icon(Icons.chat_bubble_outline, color: navy),
      ),
    ],
  );
  Widget _home() {
    final name = '${profile['company_name'] ?? 'Company'}';
    final active = projects
        .where((p) => p is Map && '${p['status'] ?? ''}' != 'completed')
        .length;
    final verified = _verified();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
        children: [
          _header('Company dashboard'),
          if (loading) const LinearProgressIndicator(color: orange),
          if (loadError)
            Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: Colors.red),
                title: const Text('Dashboard data unavailable'),
                subtitle: const Text('Check your connection and try again.'),
                trailing: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: navy,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  verified
                      ? 'Your company account is verified.'
                      : 'Your company account is pending admin verification.',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _action(
                      'New project',
                      Icons.add_business,
                      verified
                          ? () => _open('Create project', restricted: true)
                          : () => _notice(
                              'Project publishing unlocks after admin verification.',
                            ),
                    ),
                    _action(
                      'Services',
                      Icons.layers_outlined,
                      verified
                          ? () => _open('Services', restricted: true)
                          : () => _notice(
                              'Service publishing unlocks after admin verification.',
                            ),
                    ),
                    _action(
                      'Quotes',
                      Icons.request_quote_outlined,
                      verified
                          ? () => _open('Quote requests', restricted: true)
                          : () => _notice(
                              'Quote requests unlock after admin verification.',
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('Active projects', '$active', Icons.folder_open_outlined),
              _stat('Quotes', '${quotes.length}', Icons.request_quote_outlined),
            ],
          ),
          Row(
            children: [
              _stat('Messages', '${messages.length}', Icons.message_outlined),
              _stat(
                'Wallet',
                '${wallet['available_balance'] ?? wallet['balance'] ?? 0} ${wallet['currency'] ?? 'XOF'}',
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          const SizedBox(height: 18),
          _section(
            'Recent projects',
            projects.isEmpty
                ? const [
                    Text(
                      'No company projects yet.',
                      style: TextStyle(color: muted),
                    ),
                  ]
                : projects
                      .take(3)
                      .map((p) => _row(p, Icons.folder_open_outlined))
                      .toList(),
          ),
          _section(
            'Recent activity',
            activities.isEmpty
                ? const [
                    Text(
                      'No recent company activity.',
                      style: TextStyle(color: muted),
                    ),
                  ]
                : activities
                      .take(4)
                      .map((p) => _row(p, Icons.history))
                      .toList(),
          ),
        ],
      ),
    );
  }

  Widget _projects() =>
      _listPage('Projects', projects, Icons.folder_open_outlined);
  Widget _messages() => const ClientMessagesScreen(withBottomNavigation: false);
  Widget _profile() =>
      _listPage('Company profile', [profile], Icons.business_outlined);
  Widget _listPage(
    String title,
    List<dynamic> items,
    IconData icon,
  ) => RefreshIndicator(
    onRefresh: _load,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
      children: [
        _header(title),
        if (loading) const LinearProgressIndicator(color: orange),
        const SizedBox(height: 16),
        if (items.isEmpty)
          const Padding(
            padding: EdgeInsets.all(30),
            child: Text(
              'Nothing to display yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted),
            ),
          )
        else
          ...items
              .take(8)
              .map(
                (x) => Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(icon, color: orange),
                    title: Text(
                      '${x is Map ? (x['title'] ?? x['company_name'] ?? x['subject'] ?? 'Item') : 'Item'}',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${x is Map ? (x['status'] ?? x['description'] ?? '') : ''}',
                      style: const TextStyle(color: muted),
                    ),
                    onTap: () {},
                  ),
                ),
              ),
      ],
    ),
  );
  Widget _bottom() => NavigationBarTheme(
    data: NavigationBarThemeData(
      backgroundColor: navy,
      indicatorColor: orange.withValues(alpha: .2),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          color: s.contains(WidgetState.selected)
              ? Colors.white
              : Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? orange : Colors.white70,
        ),
      ),
    ),
    child: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (i) {
        if (i == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
          );
        } else {
          setState(() => tab = i);
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.folder_open_outlined),
          label: 'Projects',
        ),
        NavigationDestination(
          icon: Icon(Icons.message_outlined),
          label: 'Messages',
        ),
        NavigationDestination(
          icon: Icon(Icons.business_outlined),
          label: 'Profile',
        ),
      ],
    ),
  );
  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: Card(
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(0, 0, 8, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: orange),
            const SizedBox(height: 5),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(color: navy, fontWeight: FontWeight.w800),
            ),
            Text(label, style: const TextStyle(color: muted, fontSize: 11)),
          ],
        ),
      ),
    ),
  );
  Widget _section(String title, List<Widget> children) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    ),
  );
  Widget _row(dynamic value, IconData icon) {
    final x = value is Map ? value : const {};
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: orange),
      title: Text(
        '${x['title'] ?? x['text'] ?? x['company_name'] ?? 'Item'}',
        style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${x['status'] ?? x['description'] ?? ''}',
        style: const TextStyle(color: muted),
      ),
    );
  }

  Widget _action(String text, IconData icon, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 17),
        label: Text(text),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white54),
        ),
      );
  void _showDrawer() {
    if (drawerOpen) return;
    setState(() => drawerOpen = true);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close navigation',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (d, _, __) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.sizeOf(d).width * .84,
          child: _drawer(d),
        ),
      ),
      transitionBuilder: (_, a, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
        child: child,
      ),
    ).whenComplete(() {
      if (mounted) setState(() => drawerOpen = false);
    });
  }

  Widget _drawer(BuildContext c) => Drawer(
    child: SafeArea(
      child: Column(
        children: [
          Container(
            color: navy,
            padding: const EdgeInsets.fromLTRB(20, 24, 14, 22),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Image.asset(
                    'assets/images/boulotman-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${profile['company_name'] ?? 'Company'}\nCompany Space',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(c),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _item(
                  c,
                  'Dashboard',
                  Icons.dashboard_outlined,
                  () => setState(() => tab = 0),
                ),
                _item(
                  c,
                  'Profile',
                  Icons.business_outlined,
                  () => _open('Company profile'),
                ),
                _item(
                  c,
                  'Services',
                  Icons.layers_outlined,
                  () => _open('Services', restricted: true),
                ),
                _item(
                  c,
                  'Projects',
                  Icons.folder_open_outlined,
                  () => _open('Projects', restricted: true),
                ),
                _item(
                  c,
                  'Quote requests',
                  Icons.request_quote_outlined,
                  () => _open('Quote requests', restricted: true),
                ),
                _item(
                  c,
                  'Messages',
                  Icons.message_outlined,
                  () => setState(() => tab = 2),
                ),
                _item(c, 'Team', Icons.groups_outlined, () => _open('Team')),
                _item(c, 'Reviews', Icons.star_outline, () => _open('Reviews')),
                _item(
                  c,
                  'Analytics',
                  Icons.bar_chart_outlined,
                  () => _open('Analytics'),
                ),
                _item(
                  c,
                  'Wallet',
                  Icons.account_balance_wallet_outlined,
                  () => _open('Wallet'),
                ),
                _item(
                  c,
                  'Settings',
                  Icons.settings_outlined,
                  () => _open('Settings'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _item(c, 'Log out', Icons.logout, _logout, danger: true),
        ],
      ),
    ),
  );
  Widget _item(
    BuildContext c,
    String label,
    IconData icon,
    VoidCallback action, {
    bool danger = false,
  }) => ListTile(
    leading: Icon(icon, color: danger ? Colors.red : navy),
    title: Text(
      label,
      style: TextStyle(
        color: danger ? Colors.red : navy,
        fontWeight: FontWeight.w700,
      ),
    ),
    onTap: () {
      Navigator.pop(c);
      action();
    },
  );
}

class CompanyPlaceholderScreen extends StatelessWidget {
  const CompanyPlaceholderScreen({
    super.key,
    required this.title,
    this.restricted = false,
    this.verified = false,
  });
  final String title;
  final bool restricted, verified;

  @override
  Widget build(BuildContext context) {
    final locked = restricted && !verified;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        foregroundColor: const Color(0xFF001F3F),
        backgroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: Card(
          elevation: 0,
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  locked ? Icons.lock_outline : Icons.construction_outlined,
                  color: const Color(0xFFFF4500),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  locked
                      ? 'Verification required'
                      : '$title is ready for the next implementation phase.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF001F3F),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  locked
                      ? 'An administrator must verify this company before it can publish or manage this feature.'
                      : 'The navigation is connected and this page will be implemented in its dedicated phase.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
