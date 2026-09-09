import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../core/api_service.dart';
import 'technician_messages_screen.dart';
import 'technician_notifications_screen.dart';
import 'technician_profile_details_screen.dart';
import 'technician_profile_screen.dart';
import 'technician_wallet_screen.dart';
import 'technician_area_screens.dart';
import 'technician_settings_screen.dart';
import 'technician_services_screen.dart';
import 'technician_navigation.dart';
import 'technician_bids_management_screen.dart';

class TechnicianDashboardScreen extends StatefulWidget {
  const TechnicianDashboardScreen({super.key, this.role = 'TECHNICIAN'});
  final String role;
  @override
  State<TechnicianDashboardScreen> createState() =>
      _TechnicianDashboardScreenState();
}

class _TechnicianDashboardScreenState extends State<TechnicianDashboardScreen> {
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      ink = Color(0xFF0B2948),
      muted = Color(0xFF64748B);
  final api = ApiService();
  final scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? verificationTimer;
  int tab = 0;
  bool loading = true;
  bool showVerificationCard = true;
  String query = '';
  Map<String, dynamic> user = {}, wallet = {};
  List<dynamic> tasks = [],
      bids = [],
      assignments = [],
      documents = [],
      notifications = [];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    _load();
    verificationTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshProfile(),
    );
  }

  Future<void> _refreshProfile() async {
    try {
      final latest = await api.profile();
      if (mounted) setState(() => user = latest);
    } catch (_) {}
  }

  List<dynamic> _list(dynamic v) => v is List
      ? v
      : v is Map && v['results'] is List
      ? v['results'] as List
      : const [];
  Future<dynamic> _try(Future<dynamic> request, dynamic fallback) async {
    try {
      return await request;
    } catch (_) {
      return fallback;
    }
  }

  Future<void> _load() async {
    try {
      final v = await Future.wait<dynamic>([
        _try(api.profile(), <String, dynamic>{}),
        _try(api.wallet(), <String, dynamic>{}),
        _try(api.tasks(), const []),
        _try(api.myBids(), const []),
        _try(api.myTasks(), const []),
        _try(api.technicianDocuments(), const []),
        _try(api.notifications(), const []),
      ]);
      if (!mounted) return;
      setState(() {
        user = v[0] as Map<String, dynamic>;
        wallet = v[1] as Map<String, dynamic>;
        tasks = _list(v[2]);
        bids = _list(v[3]);
        assignments = _list(v[4]);
        documents = _list(v[5]);
        notifications = _list(v[6]);
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Map<String, dynamic> get technicianProfile =>
      user['technician_profile'] is Map
      ? Map<String, dynamic>.from(user['technician_profile'] as Map)
      : user;
  bool _asBool(dynamic value) =>
      value == true || value.toString().toLowerCase() == 'true' || value == 1;
  bool get verified =>
      _asBool(user['is_verified']) || _asBool(technicianProfile['is_verified']);
  String get name {
    final n = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim();
    return n.isEmpty ? (user['username'] ?? 'Technician').toString() : n;
  }

  String get availabilityLabel {
    if (_asBool(user['available_now']) ||
        _asBool(technicianProfile['available_now']))
      return 'Available now';
    final value =
        '${user['availability_status'] ?? technicianProfile['availability_status'] ?? 'offline'}'
            .replaceAll('_', ' ');
    return value.isEmpty
        ? 'Offline'
        : '${value[0].toUpperCase()}${value.substring(1)}';
  }

  String get avatarUrl => api.resolveImageUrl(
    '${user['avatar_url'] ?? technicianProfile['avatar_url'] ?? ''}',
  );
  dynamic get balance =>
      wallet['available_balance'] ??
      wallet['balance'] ??
      wallet['available'] ??
      0;
  List<dynamic> get directOffers => assignments
      .where(
        (item) =>
            item is Map &&
            (_asBool(item['direct_offer']) ||
                _asBool(item['is_direct_offer']) ||
                '${item['offer_type'] ?? ''}'.toLowerCase() == 'direct'),
      )
      .toList();

  @override
  Widget build(BuildContext context) => Scaffold(
    key: scaffoldKey,
    backgroundColor: const Color(0xFFF5F7FA),
    drawerEnableOpenDragGesture: true,
    drawerEdgeDragWidth: 36,
    drawerScrimColor: Colors.black54,
    body: SafeArea(
      child: tab == 2
          ? const TechnicianWalletScreen()
          : tab == 3
          ? const TechnicianProfileDetailsScreen()
          : tab == 1
          ? const TechnicianBidsManagementScreen()
          : _feed(),
    ),
    drawer: _drawer(context),
    bottomNavigationBar: TechnicianBottomNavigation(selectedIndex: tab),
  );

  Widget _header() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: _refreshAndShowDrawer,
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            icon: const Icon(Icons.menu, color: navy),
          ),
          const SizedBox(width: 4),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Technician Feed',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                SizedBox(height: 5),
                Text('Dashboard overview', style: TextStyle(color: muted)),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TechnicianNotificationsScreen(),
                  ),
                ),
                icon: const Icon(Icons.notifications_none, color: navy),
              ),
              if (notifications.isNotEmpty)
                Positioned(
                  right: 5,
                  top: 5,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: orange,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${notifications.length > 99 ? '99+' : notifications.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TechnicianMessagesScreen(),
              ),
            ),
            icon: const Icon(Icons.chat_bubble_outline, color: navy),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 44,
        child: TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: InputDecoration(
            hintText: 'Search tasks or cities',
            prefixIcon: const Icon(Icons.search, size: 20, color: muted),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    ],
  );

  Future<void> _refreshAndShowDrawer() async {
    // Open immediately so the drawer never feels stuck behind a network call.
    // Refresh the verification state in the background for the next rebuild.
    _showAnimatedDrawer();
    try {
      final latest = await api.profile();
      if (mounted) setState(() => user = latest);
    } catch (_) {
      // Keep the existing session state if the refresh is temporarily offline.
    }
  }

  void _showAnimatedDrawer() {
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Close navigation',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, _, __) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: MediaQuery.sizeOf(dialogContext).width * .82,
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

  Widget _drawer(BuildContext context) => Drawer(
    child: SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: navy,
            padding: const EdgeInsets.fromLTRB(22, 24, 18, 22),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boulot Man',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Text(
                      'Technician Space',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _nav(
                  context,
                  Icons.dashboard_outlined,
                  'Dashboard',
                  () => setState(() => tab = 0),
                ),
                _nav(
                  context,
                  Icons.folder_open_outlined,
                  'Projects',
                  () => _push(const TechnicianProjectsScreen()),
                ),
                _nav(
                  context,
                  Icons.search,
                  'Browse Tasks',
                  () => _push(const TechnicianTasksScreen()),
                  locked: !verified,
                ),
                _nav(
                  context,
                  Icons.layers_outlined,
                  'My Services',
                  () => _push(const TechnicianServicesScreen()),
                ),
                _nav(
                  context,
                  Icons.send_outlined,
                  'My Bids',
                  () => _push(const TechnicianBidsManagementScreen()),
                ),
                _nav(
                  context,
                  Icons.message_outlined,
                  'Messages',
                  () => _push(const TechnicianMessagesScreen()),
                ),
                _nav(
                  context,
                  Icons.account_balance_wallet_outlined,
                  'Wallet',
                  () => setState(() => tab = 2),
                ),
                _nav(
                  context,
                  Icons.person_outline,
                  'Edit Profile',
                  () => setState(() => tab = 3),
                ),
                _nav(
                  context,
                  Icons.settings_outlined,
                  'Settings',
                  () => _push(const TechnicianSettingsScreen()),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _nav(context, Icons.logout, 'Log out', () async {
            await api.clearSession();
            if (context.mounted)
              Navigator.of(context).popUntil((r) => r.isFirst);
          }),
        ],
      ),
    ),
  );

  Widget _nav(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool locked = false,
  }) => ListTile(
    leading: Icon(icon, color: locked ? muted : navy),
    title: Text(
      label,
      style: TextStyle(
        color: locked ? muted : navy,
        fontWeight: FontWeight.w700,
      ),
    ),
    trailing: locked
        ? const Icon(Icons.lock_outline, size: 17, color: muted)
        : null,
    onTap: () {
      Navigator.pop(context);
      if (locked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This feature unlocks after admin verification.'),
          ),
        );
      } else {
        onTap();
      }
    },
  );
  void _push(Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  Widget _feed() {
    final accepted = bids
        .where(
          (b) => b is Map && '${b['status'] ?? ''}'.toLowerCase() == 'accepted',
        )
        .length;
    final progress = documents.length.clamp(0, 4);
    final search = query.trim().toLowerCase();
    final visibleTasks = search.isEmpty
        ? tasks
        : tasks.where((item) {
            if (item is! Map) return false;
            final title = '${item['title'] ?? ''}'.toLowerCase();
            final city = '${item['city'] ?? item['location'] ?? ''}'
                .toLowerCase();
            return title.contains(search) || city.contains(search);
          }).toList();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          _header(),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(color: orange),
            ),
          const SizedBox(height: 20),
          _hero(),
          if (showVerificationCard) ...[
            const SizedBox(height: 16),
            _verification(progress),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _metric('Total bids', '${bids.length}', Icons.work_outline),
              _metric('Accepted bids', '$accepted', Icons.check_circle_outline),
              _metric(
                'Balance',
                '$balance',
                Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _metric(
                'Assigned projects',
                '${assignments.length}',
                Icons.folder_open_outlined,
              ),
              _metric(
                'Available tasks',
                verified ? '${visibleTasks.length}' : 'Locked',
                Icons.search,
              ),
              _metric(
                'Direct offers',
                '${directOffers.length}',
                Icons.local_offer_outlined,
              ),
            ],
          ),
          const SizedBox(height: 22),
          _sectionTitle(
            'Direct projects & offers',
            assignments.isNotEmpty ? '${assignments.length} active' : null,
            onAction: () => _push(const TechnicianProjectsScreen()),
          ),
          if (assignments.isEmpty)
            _empty('No direct assignments yet.', Icons.assignment_ind_outlined)
          else
            ...assignments.take(3).map(_assignment),
          const SizedBox(height: 18),
          _sectionTitle(
            'Available tasks',
            'View all',
            onAction: () {
              if (!verified) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Task browsing unlocks after admin verification.',
                    ),
                  ),
                );
              } else {
                _push(const TechnicianTasksScreen());
              }
            },
          ),
          if (!verified)
            _lockedCard(
              'Task browsing is locked',
              'Marketplace tasks and bidding unlock after admin verification.',
              Icons.lock_outline,
            )
          else if (visibleTasks.isEmpty)
            _empty(
              search.isEmpty
                  ? 'No tasks available right now.'
                  : 'No tasks match your search.',
              Icons.search_off,
            )
          else
            ...visibleTasks.take(3).map(_task),
          const SizedBox(height: 18),
          _sectionTitle(
            'Recent bids',
            'View all',
            onAction: () => _push(const TechnicianBidsManagementScreen()),
          ),
          if (bids.isEmpty)
            _empty('No bids submitted yet.', Icons.gavel_outlined)
          else
            ...bids.take(3).map(_bid),
        ],
      ),
    );
  }

  Widget _hero() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: navy,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: orange,
              backgroundImage: avatarUrl.isEmpty
                  ? null
                  : NetworkImage(avatarUrl),
              child: avatarUrl.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Welcome, $name',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          verified
              ? 'Your specialist profile is active.'
              : 'Complete verification to unlock tasks and bidding.',
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              verified ? Icons.verified_outlined : Icons.pending_outlined,
              color: verified ? Colors.greenAccent : Colors.amberAccent,
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              verified ? 'Verified' : 'Pending verification',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            const Icon(Icons.circle, color: Colors.greenAccent, size: 10),
            const SizedBox(width: 5),
            Text(
              availabilityLabel,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => tab = 3),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: const Text('Manage profile'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => tab = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('View wallet'),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _verification(int progress) => Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(
        color: verified ? Colors.green.shade200 : Colors.amber.shade300,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified ? Icons.verified : Icons.shield_outlined,
                color: verified ? Colors.green : Colors.amber.shade800,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  verified
                      ? 'Boulot Man Approved Pro'
                      : 'Account pending admin verification',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
              ),
              if (verified)
                IconButton(
                  tooltip: 'Dismiss verification summary',
                  onPressed: () => setState(() => showVerificationCard = false),
                  icon: const Icon(Icons.close, color: muted),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            verified
                ? 'Your profile is eligible for marketplace work.'
                : 'Upload your identity and professional documents. Admin approval unlocks task browsing and bidding.',
            style: const TextStyle(color: muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: verified ? 1 : progress / 4,
            color: orange,
            backgroundColor: const Color(0xFFFFE8E0),
          ),
          const SizedBox(height: 8),
          Text(
            verified
                ? 'Verification complete'
                : '$progress of 4 documents submitted',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TechnicianProfileScreen(),
                ),
              ),
              icon: const Icon(Icons.verified_user_outlined),
              label: Text(
                verified ? 'View verification' : 'Manage verification',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: orange,
                side: const BorderSide(color: orange),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _metric(String label, String value, IconData icon) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: orange, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ink,
            ),
          ),
          Text(label, style: const TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    ),
  );
  Widget _sectionTitle(
    String title,
    String? action, {
    VoidCallback? onAction,
  }) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      if (action != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(
            foregroundColor: orange,
            padding: EdgeInsets.zero,
            minimumSize: const Size(1, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
    ],
  );
  Widget _empty(String text, IconData icon) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(icon, color: muted),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: muted)),
        ],
      ),
    ),
  );
  Widget _lockedCard(String title, String text, IconData icon) => Card(
    elevation: 0,
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFFE8E0),
        child: Icon(icon, color: orange),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, color: ink),
      ),
      subtitle: Text(text, style: const TextStyle(color: muted)),
    ),
  );
  Widget _assignment(dynamic x) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      final id = x is Map ? x['id'] : null;
      if (id != null) _push(TechnicianTaskDetailScreen(taskId: id));
    },
    child: _lockedCard(
      (x is Map ? x['title'] : null) ?? 'Direct assignment',
      'Open project workspace when available',
      Icons.assignment_ind_outlined,
    ),
  );
  Widget _task(dynamic x) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () {
      final id = x is Map ? x['id'] : null;
      if (id != null) _push(TechnicianTaskDetailScreen(taskId: id));
    },
    child: _lockedCard(
      (x is Map ? x['title'] : null) ?? 'Task',
      '${x is Map ? x['city'] ?? 'Location not specified' : 'Location not specified'} • ${x is Map ? x['budget_min'] ?? 'Budget TBD' : 'Budget TBD'}',
      Icons.work_outline,
    ),
  );
  Widget _bid(dynamic x) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: () => _push(const TechnicianBidsScreen()),
    child: _lockedCard(
      'Task #${x is Map ? x['task_id'] ?? x['task'] ?? x['id'] ?? '' : ''}',
      'Status: ${x is Map ? x['status'] ?? 'submitted' : 'submitted'}',
      Icons.gavel_outlined,
    ),
  );
  @override
  void dispose() {
    verificationTimer?.cancel();
    super.dispose();
  }
}
