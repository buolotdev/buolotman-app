import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'login_screen.dart';
import 'client_task_create_screen.dart';
import '../verification_utils.dart';
import 'client_navigation_screens.dart';
import 'client_task_management_screen.dart';
import 'client_projects_screen.dart';
import 'client_messaging_screen.dart';
import 'server_notifications_screen.dart';

class ClientDashboardScreen extends StatefulWidget {
  const ClientDashboardScreen({super.key});
  @override
  State<ClientDashboardScreen> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboardScreen> {
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      muted = Color(0xFF64748B),
      bg = Color(0xFFF5F7FA);
  final api = ApiService();
  int tab = 0;
  Map<String, dynamic> profile = {}, wallet = {};
  List<dynamic> notifications = [];
  List<dynamic> tasks = [], conversations = [];
  bool loading = true;

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
  Future<void> _load() async {
    try {
      final values = await Future.wait<dynamic>([
        api.profile(),
        api.myTasks(),
        api.wallet(),
        api.conversations(),
        api.notifications(),
      ]);
      if (mounted)
        setState(() {
          profile = values[0] is Map ? values[0] as Map<String, dynamic> : {};
          tasks = _list(values[1]);
          wallet = values[2] is Map ? values[2] as Map<String, dynamic> : {};
          conversations = values[3] is List ? values[3] as List : [];
          notifications = values[4] is List ? values[4] as List : [];
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _logout() async {
    await api.clearSession();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
  }

  void _verificationNotice() => ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text(
        'Task posting is locked until an administrator verifies your account.',
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    key: _key,
    drawer: Builder(builder: (drawerContext) => _drawer(drawerContext)),
    drawerEnableOpenDragGesture: true,
    backgroundColor: bg,
    body: SafeArea(
      child: tab == 0
          ? _home()
          : tab == 1
          ? _tasks()
          : tab == 2
          ? _messages()
          : _profile(),
    ),
    // Keep one navigation shell mounted for every client tab. Messages must
    // not push its own Scaffold/bottom bar onto the route stack; doing that
    // makes the whole page slide and leaves later tabs inside that transition.
    bottomNavigationBar: _bottom(),
  );
  final _key = GlobalKey<ScaffoldState>();

  Widget _home() {
    final name = '${profile['first_name'] ?? ''}'.trim();
    final active = tasks
        .where(
          (x) =>
              x is Map &&
              !['completed', 'cancelled'].contains('${x['status']}'),
        )
        .length;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _top('Client dashboard'),
          if (loading) const LinearProgressIndicator(color: orange),
          const SizedBox(height: 18),
          Text(
            'Welcome${name.isEmpty ? '' : ', $name'}',
            style: const TextStyle(
              color: navy,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Find trusted professionals and manage your projects.',
            style: TextStyle(color: muted),
          ),
          const SizedBox(height: 20),
          _hero(),
          const SizedBox(height: 18),
          Row(
            children: [
              _stat('Active tasks', '$active', Icons.assignment_outlined),
              _stat(
                'Messages',
                '${conversations.length}',
                Icons.message_outlined,
              ),
              _stat(
                'Balance',
                '${wallet['available_balance'] ?? 0}',
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _heading('Recent tasks'),
          if (tasks.isEmpty)
            _empty('No tasks yet. Post a task to get started.')
          else
            ...tasks.take(4).map(_taskTile),
        ],
      ),
    );
  }

  Widget _tasks() => const ClientTasksScreen(withBottomNavigation: false);
  Widget _messages() => const ClientMessagesScreen(withBottomNavigation: false);
  Widget _profile() =>
      const ClientProfileOverviewScreen(withBottomNavigation: false);
  void _openAnimatedDrawer() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close menu',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, __, ___) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * .82,
          child: _drawer(dialogContext),
        ),
      ),
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(begin: const Offset(-1, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      ),
    );
  }

  Widget _top(String title) => Row(
    children: [
      IconButton(
        onPressed: _openAnimatedDrawer,
        icon: const Icon(Icons.menu, color: navy),
      ),
      Text(
        title,
        style: const TextStyle(
          color: navy,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      const Spacer(),
      Stack(
        children: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ServerNotificationsScreen(),
              ),
            ),
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
        onPressed: _load,
        icon: const Icon(Icons.refresh, color: navy),
      ),
    ],
  );
  Widget _hero() {
    final verified = isVerifiedProfile(profile);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: navy,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need help with a project?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Describe the work and receive proposals from professionals.',
            style: TextStyle(color: Colors.white70),
          ),
          if (!verified) ...[
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.lock_outline, color: Colors.amber, size: 17),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Verify your account before posting a task.',
                    style: TextStyle(
                      color: Colors.amber,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: verified
                ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientTaskCreateScreen(),
                    ),
                  ).then((_) => _load())
                : _verificationNotice,
            icon: Icon(verified ? Icons.add : Icons.lock_outline),
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              foregroundColor: Colors.white,
            ),
            label: Text(verified ? 'Post a task' : 'Posting locked'),
          ),
        ],
      ),
    );
  }

  Widget _taskTile(dynamic item) {
    final x = item is Map ? item : <String, dynamic>{};
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFE8E0),
          child: Icon(Icons.assignment_outlined, color: orange),
        ),
        title: Text(
          '${x['title'] ?? 'Task'}',
          style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${x['status'] ?? 'draft'} • ${x['city'] ?? x['location'] ?? 'Location not specified'}',
          style: const TextStyle(color: muted),
        ),
        trailing: Text(
          '${x['bids_count'] ?? 0} bids',
          style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
        ),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClientTaskDetailScreen(taskId: x['id']),
            ),
          );
          _load();
        },
      ),
    );
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        color: navy,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: Card(
      elevation: 0,
      margin: const EdgeInsets.only(right: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: orange),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                color: navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.all(28),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: muted),
    ),
  );
  Widget _bottom() => BottomNavigationBar(
    currentIndex: tab,
    selectedItemColor: orange,
    unselectedItemColor: muted,
    onTap: (value) => setState(() => tab = value),
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        label: 'Tasks',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.message_outlined),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
    ],
  );
  Widget _drawer(BuildContext closeContext) => Drawer(
    child: SafeArea(
      child: ListView(
        children: [
          Container(
            height: 188,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: const BoxDecoration(color: navy),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Image.asset(
                    'assets/images/boulotman-logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Boulot Man',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Client workspace',
                  style: TextStyle(color: Color(0xFFB8C7D9), fontSize: 14),
                ),
              ],
            ),
          ),
          _drawerItem(
            closeContext,
            Icons.dashboard_outlined,
            'Dashboard',
            () => setState(() => tab = 0),
          ),
          _drawerItem(
            closeContext,
            Icons.assignment_outlined,
            'My Tasks',
            () => setState(() => tab = 1),
          ),
          _drawerItem(
            closeContext,
            Icons.folder_open_outlined,
            'My Projects',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientProjectsScreen()),
            ),
          ),
          _drawerItem(
            closeContext,
            Icons.message_outlined,
            'Messages',
            () => setState(() => tab = 2),
          ),
          _drawerItem(
            closeContext,
            Icons.credit_card,
            'Payments',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientPaymentsScreen()),
            ),
          ),
          _drawerItem(
            closeContext,
            Icons.bookmark_border,
            'Saved',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientSavedScreen()),
            ),
          ),
          _drawerItem(
            closeContext,
            Icons.person_outline,
            'Profile',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClientProfileOverviewScreen(),
              ),
            ),
          ),
          _drawerItem(
            closeContext,
            Icons.verified_user_outlined,
            'Identity verification',
            () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ClientVerificationScreen(),
              ),
            ),
          ),
          _drawerItem(
            closeContext,
            Icons.support_agent,
            'Support Tickets',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientSupportScreen()),
            ),
          ),
          _drawerItem(
            closeContext,
            Icons.settings_outlined,
            'Settings',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientSettingsScreen()),
            ),
          ),
          _drawerItem(
            closeContext,
            Icons.search,
            'Explore Professionals',
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientExploreScreen()),
            ),
          ),
          const Divider(),
          _drawerItem(closeContext, Icons.logout, 'Log out', _logout),
        ],
      ),
    ),
  );
  Widget _drawerItem(
    BuildContext closeContext,
    IconData icon,
    String label,
    VoidCallback action,
  ) => ListTile(
    leading: Icon(icon, color: navy),
    title: Text(
      label,
      style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
    ),
    onTap: () {
      Navigator.of(closeContext).pop();
      action();
    },
  );
}
