import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api_service.dart';
import '../attachment_actions.dart';
import 'login_screen.dart';
import 'technician_navigation.dart';

const _navy = Color(0xFF001F3F),
    _orange = Color(0xFFFF4500),
    _muted = Color(0xFF64748B),
    _bg = Color(0xFFF5F7FA);
List<dynamic> _items(dynamic v) => v is List
    ? v
    : v is Map && v['results'] is List
    ? v['results'] as List
    : const [];

class TechnicianProjectsScreen extends StatefulWidget {
  const TechnicianProjectsScreen({super.key});
  @override
  State<TechnicianProjectsScreen> createState() => _ProjectsState();
}

class _ProjectsState extends State<TechnicianProjectsScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = _load();
  String filter = 'all', query = '';
  List<dynamic> _list(dynamic v) => v is List
      ? v
      : v is Map && v['results'] is List
      ? v['results'] as List
      : const [];
  Future<List<dynamic>> _load() async {
    final values = await Future.wait<dynamic>([api.myTasks(), api.myBids()]);
    final projects = <dynamic>[];
    projects.addAll(_list(values[0]));
    for (final bid in _list(values[1])) {
      if (bid is Map && '${bid['status'] ?? ''}'.toLowerCase() == 'accepted') {
        final task = bid['task'] is Map
            ? Map<String, dynamic>.from(bid['task'])
            : <String, dynamic>{};
        projects.add({
          ...task,
          'id': task['id'] ?? bid['task_id'],
          'accepted_bid_id': bid['id'],
          'bid_amount': bid['amount'],
          'is_accepted_bid': true,
        });
      }
    }
    final seen = <String>{};
    return projects.where((x) {
      final id = '${x is Map ? x['id'] : ''}';
      return id.isNotEmpty && seen.add(id);
    }).toList();
  }

  bool _authorized(Map x) =>
      x['assigned_to'] != null ||
      x['specialist_id'] != null ||
      x['is_accepted_bid'] == true ||
      '${x['status'] ?? ''}'.toLowerCase() == 'in_progress';
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Projects'),
      foregroundColor: _navy,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () => setState(() => future = _load()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    backgroundColor: _bg,
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 0),
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: _orange));
        final all = s.data ?? [];
        final projects = all.whereType<Map>().where((x) {
          final status = '${x['status'] ?? 'pending'}'.toLowerCase();
          if (filter == 'active' &&
              !['in_progress', 'assigned'].contains(status))
            return false;
          if (filter == 'completed' && status != 'completed') return false;
          if (filter == 'pending' &&
              status != 'assigned' &&
              status != 'pending')
            return false;
          final q = query.trim().toLowerCase();
          return q.isEmpty ||
              '${x['title'] ?? ''} ${x['client_name'] ?? ''} ${x['city'] ?? x['location'] ?? ''}'
                  .toLowerCase()
                  .contains(q);
        }).toList();
        return RefreshIndicator(
          onRefresh: () async => setState(() => future = _load()),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Search projects, clients or locations',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['all', 'active', 'pending', 'completed']
                      .map(
                        (v) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(v),
                            selected: filter == v,
                            onSelected: (_) => setState(() => filter = v),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${projects.length} projects',
                style: const TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              if (projects.isEmpty)
                _center('No projects or accepted bids found.')
              else
                ...projects.map<Widget>((raw) {
                  final x = raw as Map;
                  final status = '${x['status'] ?? 'pending'}';
                  final authorized = _authorized(x);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        c,
                        MaterialPageRoute(
                          builder: (_) =>
                              TechnicianTaskDetailScreen(taskId: x['id']),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: status == 'completed'
                            ? Colors.green.shade100
                            : const Color(0xFFFFE8E0),
                        child: Icon(
                          status == 'completed'
                              ? Icons.check
                              : Icons.folder_open,
                          color: status == 'completed' ? Colors.green : _orange,
                        ),
                      ),
                      title: Text(
                        '${x['title'] ?? 'Project'}',
                        style: const TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${x['client_name'] ?? 'Client'} • ${x['city'] ?? x['location'] ?? 'Location not specified'}\n${authorized ? status.replaceAll('_', ' ') : 'Not assigned'}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right, color: _muted),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    ),
  );
}

class TechnicianTasksScreen extends StatefulWidget {
  const TechnicianTasksScreen({super.key});
  @override
  State<TechnicianTasksScreen> createState() => _TasksGateState();
}

class _TasksGateState extends State<TechnicianTasksScreen> {
  final api = ApiService();
  late Future<Map<String, dynamic>> profile = api.profile();
  late Future<dynamic> tasks = api.tasks();
  String query = '', category = 'all', urgency = 'all', city = 'all';
  double? minBudget, maxBudget;
  bool _bool(dynamic value) =>
      value == true || value.toString().toLowerCase() == 'true' || value == 1;
  List<dynamic> _filtered(List<dynamic> source) => source.where((raw) {
    if (raw is! Map) return false;
    final x = raw;
    final status = '${x['status'] ?? 'open'}'.toLowerCase();
    if (status != 'open' || x['assigned_to'] != null) return false;
    final searchable =
        '${x['title'] ?? ''} ${x['description'] ?? ''} ${x['city'] ?? ''} ${x['location'] ?? ''} ${x['category_name'] ?? ''} ${x['category'] is Map ? x['category']['name'] : x['category']}'
            .toLowerCase();
    if (query.trim().isNotEmpty &&
        !searchable.contains(query.trim().toLowerCase()))
      return false;
    final categoryName =
        '${x['category_name'] ?? (x['category'] is Map ? x['category']['name'] : x['category'] ?? '')}'
            .toLowerCase();
    if (category != 'all' &&
        categoryName != category.toLowerCase() &&
        '${x['category'] ?? ''}' != category)
      return false;
    if (urgency != 'all' && '${x['urgency'] ?? ''}'.toLowerCase() != urgency)
      return false;
    if (city != 'all' &&
        !'${x['city'] ?? ''} ${x['location'] ?? ''}'.toLowerCase().contains(
          city.toLowerCase(),
        ))
      return false;
    final budget = double.tryParse(
      '${x['budget_max'] ?? x['budget_min'] ?? ''}',
    );
    if (minBudget != null && (budget == null || budget < minBudget!))
      return false;
    if (maxBudget != null && (budget == null || budget > maxBudget!))
      return false;
    if (_bool(x['direct_offer']) || _bool(x['is_direct_offer'])) return false;
    return true;
  }).toList();
  Future<void> _reload() async {
    setState(() => tasks = api.tasks());
  }

  @override
  Widget build(BuildContext c) => FutureBuilder<Map<String, dynamic>>(
    future: profile,
    builder: (_, s) {
      final p = s.data ?? {};
      final nested = p['technician_profile'] is Map
          ? p['technician_profile'] as Map
          : const {};
      final verified = _bool(p['is_verified']) || _bool(nested['is_verified']);
      if (s.connectionState != ConnectionState.done)
        return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: _orange)),
        );
      if (!verified)
        return Scaffold(
          appBar: AppBar(
            title: const Text('Browse Tasks'),
            foregroundColor: _navy,
            backgroundColor: Colors.white,
          ),
          backgroundColor: _bg,
          bottomNavigationBar: const TechnicianBottomNavigation(
            selectedIndex: 0,
          ),
          body: _center(
            'Task browsing and bidding unlock after admin verification.',
          ),
        );
      return Scaffold(
        appBar: AppBar(
          title: const Text('Browse Tasks'),
          foregroundColor: _navy,
          backgroundColor: Colors.white,
          actions: [
            IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
          ],
        ),
        backgroundColor: _bg,
        bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 0),
        body: FutureBuilder<dynamic>(
          future: tasks,
          builder: (_, snapshot) {
            if (snapshot.connectionState != ConnectionState.done)
              return const Center(
                child: CircularProgressIndicator(color: _orange),
              );
            final all = _items(snapshot.data);
            final list = _filtered(all);
            final cities = all
                .whereType<Map>()
                .map((x) => '${x['city'] ?? ''}')
                .where((x) => x.isNotEmpty)
                .toSet()
                .toList();
            final categories = all
                .whereType<Map>()
                .map(
                  (x) =>
                      '${x['category_name'] ?? (x['category'] is Map ? x['category']['name'] : x['category'] ?? '')}',
                )
                .where((x) => x.isNotEmpty)
                .toSet()
                .toList();
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    onChanged: (v) => setState(() => query = v),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      labelText: 'Search tasks, skills, city or location',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _select('Category', category, [
                        'all',
                        ...categories,
                      ], (v) => setState(() => category = v)),
                      _select('Urgency', urgency, const [
                        'all',
                        'urgent',
                        'flexible',
                        'scheduled',
                      ], (v) => setState(() => urgency = v)),
                      _select('City', city, [
                        'all',
                        ...cities,
                      ], (v) => setState(() => city = v)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (v) =>
                              setState(() => minBudget = double.tryParse(v)),
                          decoration: const InputDecoration(
                            labelText: 'Minimum budget',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (v) =>
                              setState(() => maxBudget = double.tryParse(v)),
                          decoration: const InputDecoration(
                            labelText: 'Maximum budget',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${list.length} available tasks',
                    style: const TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    _center('No tasks match your filters.')
                  else
                    ...list.map<Widget>((raw) {
                      final x = raw as Map;
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            c,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TechnicianTaskDetailScreen(taskId: x['id']),
                            ),
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFE8E0),
                            child: Icon(Icons.work_outline, color: _orange),
                          ),
                          title: Text(
                            '${x['title'] ?? 'Task'}',
                            style: const TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${x['city'] ?? x['location'] ?? 'Location not specified'} • ${x['budget_min'] ?? 'TBD'} - ${x['budget_max'] ?? ''} • ${x['urgency'] ?? 'flexible'}',
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: _muted,
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      );
    },
  );
  Widget _select(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> onChanged,
  ) => SizedBox(
    width: 160,
    child: DropdownButtonFormField<String>(
      initialValue: values.contains(value) ? value : 'all',
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(),
      ),
      items: values
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(v, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (v) => onChanged(v ?? 'all'),
    ),
  );
}

class TechnicianBidsScreen extends StatefulWidget {
  const TechnicianBidsScreen({super.key});
  @override
  State<TechnicianBidsScreen> createState() => _BidsState();
}

class _BidsState extends State<TechnicianBidsScreen> {
  final api = ApiService();
  late Future<dynamic> future = ApiService().myBids();
  String filter = 'all';
  void note(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> withdraw(dynamic id) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw bid?'),
        content: const Text('You can submit a new proposal after withdrawal.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      await api.withdrawBid(id);
      if (mounted) {
        note('Bid withdrawn.');
        setState(() => future = api.myBids());
      }
    } catch (_) {
      note('We could not withdraw this bid.');
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('My Bids'),
      foregroundColor: _navy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: _bg,
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 1),
    body: FutureBuilder<dynamic>(
      future: future,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: _orange));
        final all = _items(s.data);
        final list = filter == 'all'
            ? all
            : all.where((x) => x is Map && x['status'] == filter).toList();
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(12),
              child: Row(
                children:
                    [
                      'all',
                      'pending',
                      'accepted',
                      'rejected',
                      'withdrawn',
                    ].map<Widget>((f) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(f),
                          selected: filter == f,
                          onSelected: (_) => setState(() => filter = f),
                        ),
                      );
                    }).toList(),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? _center('No bids found.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: list.length,
                      itemBuilder: (_, i) {
                        final x = list[i] is Map
                            ? list[i] as Map
                            : <String, dynamic>{};
                        final pending = x['status'] == 'pending';
                        return Card(
                          elevation: 0,
                          child: ListTile(
                            title: Text(
                              'Task #${x['task_id'] ?? x['task'] ?? x['id'] ?? ''}',
                              style: const TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              'Status: ${x['status'] ?? 'submitted'} • Amount: ${x['amount'] ?? ''}',
                            ),
                            trailing: pending
                                ? TextButton(
                                    onPressed: () => withdraw(x['id']),
                                    child: const Text(
                                      'Withdraw',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );
}

class _ListPage extends StatelessWidget {
  const _ListPage({
    required this.title,
    required this.icon,
    required this.request,
    required this.empty,
    required this.line,
    this.open,
  });
  final String title, empty;
  final IconData icon;
  final Future<dynamic> Function() request;
  final String Function(Map) line;
  final Widget Function(Map)? open;
  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      foregroundColor: _navy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: _bg,
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 0),
    body: FutureBuilder<dynamic>(
      future: request(),
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: _orange));
        final list = _items(s.data);
        if (list.isEmpty) return _center(empty);
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final x = list[i] is Map ? list[i] as Map : <String, dynamic>{};
            return Card(
              elevation: 0,
              child: ListTile(
                onTap: open == null
                    ? null
                    : () => Navigator.push(
                        c,
                        MaterialPageRoute(builder: (_) => open!(x)),
                      ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFFFE8E0),
                  child: Icon(icon, color: _orange),
                ),
                title: Text(
                  '${x['title'] ?? (title == 'My Bids' ? 'Task #${x['task_id'] ?? x['id'] ?? ''}' : title.substring(0, title.length - 1))}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                subtitle: Text(line(x)),
                trailing: open == null
                    ? null
                    : const Icon(Icons.chevron_right, color: _muted),
              ),
            );
          },
        );
      },
    ),
  );
}

class LegacyTechnicianServicesScreen extends StatefulWidget {
  const LegacyTechnicianServicesScreen({super.key});
  @override
  State<LegacyTechnicianServicesScreen> createState() => _ServicesState();
}

class _ServicesState extends State<LegacyTechnicianServicesScreen> {
  final api = ApiService();
  late Future<dynamic> future = ApiService().technicianServices();
  bool verified = false;
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final p = await api.profile();
      if (mounted)
        setState(
          () => verified =
              p['is_verified'] == true ||
              (p['technician_profile'] is Map &&
                  p['technician_profile']['is_verified'] == true),
        );
    } catch (_) {}
  }

  void _notice(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> _edit([Map? existing]) async {
    if (!verified && existing == null) {
      _notice('Service creation unlocks after admin verification.');
      return;
    }
    final title = TextEditingController(text: '${existing?['title'] ?? ''}');
    final desc = TextEditingController(
      text: '${existing?['description'] ?? ''}',
    );
    final min = TextEditingController(
      text: '${existing?['pricing_min'] ?? ''}',
    );
    final max = TextEditingController(
      text: '${existing?['pricing_max'] ?? ''}',
    );
    String serviceType = '${existing?['service_type'] ?? 'onsite'}';
    String pricingModel = '${existing?['pricing_model'] ?? 'fixed'}';
    final save = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'New service' : 'Edit service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(title, 'Service title'),
                _field(desc, 'Description', lines: 3),
                DropdownButtonFormField<String>(
                  value: serviceType,
                  decoration: const InputDecoration(labelText: 'Service type'),
                  items: const [
                    DropdownMenuItem(value: 'onsite', child: Text('On-site')),
                    DropdownMenuItem(value: 'remote', child: Text('Remote')),
                  ],
                  onChanged: (v) =>
                      setDialog(() => serviceType = v ?? 'onsite'),
                ),
                DropdownButtonFormField<String>(
                  value: pricingModel,
                  decoration: const InputDecoration(labelText: 'Pricing model'),
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                    DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                    DropdownMenuItem(value: 'range', child: Text('Range')),
                  ],
                  onChanged: (v) =>
                      setDialog(() => pricingModel = v ?? 'fixed'),
                ),
                _field(
                  min,
                  'Minimum price',
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (pricingModel == 'range')
                  _field(
                    max,
                    'Maximum price',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (save != true || title.text.trim().isEmpty) return;
    try {
      final data = <String, dynamic>{
        'title': title.text.trim(),
        'description': desc.text.trim(),
        'service_type': serviceType,
        'pricing_model': pricingModel,
        'pricing_min': double.tryParse(min.text.trim()),
        'pricing_max': pricingModel == 'range'
            ? double.tryParse(max.text.trim())
            : null,
        'is_active': existing?['is_active'] == true,
      };
      if (existing == null)
        await api.createTechnicianService(data);
      else
        await api.updateTechnicianService(existing['id'], data);
      if (mounted) {
        setState(() => future = api.technicianServices());
        _notice('Service saved successfully.');
      }
    } catch (_) {
      _notice('We could not save this service. Please check the fields.');
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('My Services'),
      foregroundColor: _navy,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add, color: _orange),
        ),
      ],
    ),
    backgroundColor: _bg,
    body: FutureBuilder<dynamic>(
      future: future,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: _orange));
        final list = _items(s.data);
        if (list.isEmpty) return _center('No services yet.');
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final x = list[i] is Map ? list[i] as Map : <String, dynamic>{};
            return Card(
              elevation: 0,
              child: ListTile(
                title: Text(
                  '${x['title'] ?? 'Service'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _navy,
                  ),
                ),
                subtitle: Text(
                  '${x['is_active'] == true ? 'Live' : 'Draft'} • ${x['description'] ?? 'No description'}',
                  maxLines: 2,
                ),
                onTap: () => _edit(x),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    try {
                      await api.deleteTechnicianService(x['id']);
                      if (mounted)
                        setState(() => future = api.technicianServices());
                    } catch (_) {
                      _notice('We could not delete this service.');
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class LegacyTechnicianSettingsScreen extends StatelessWidget {
  const LegacyTechnicianSettingsScreen({super.key});
  Future<void> _logout(BuildContext c) async {
    await ApiService().clearSession();
    if (c.mounted)
      Navigator.of(c).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Settings'),
      foregroundColor: _navy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: _bg,
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 3),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Card(
          elevation: 0,
          child: ListTile(
            leading: Icon(Icons.security, color: _orange),
            title: Text('Account security'),
            subtitle: Text(
              'Your account and verification are managed securely.',
            ),
          ),
        ),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.logout, color: _orange),
            title: const Text('Log out'),
            onTap: () => _logout(c),
          ),
        ),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete account permanently',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text('This action cannot be undone.'),
            onTap: () => _confirmDelete(c),
          ),
        ),
      ],
    ),
  );
  Future<void> _confirmDelete(BuildContext c) async {
    final input = TextEditingController();
    final ok = await showDialog<bool>(
      context: c,
      builder: (_) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Type DELETE to confirm.'),
            _field(input, 'Confirmation'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, input.text == 'DELETE'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ApiService().deleteAccount();
        if (c.mounted)
          Navigator.of(c).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
      } catch (_) {
        if (c.mounted)
          ScaffoldMessenger.of(c).showSnackBar(
            const SnackBar(content: Text('We could not delete your account.')),
          );
      }
    }
  }
}

class TechnicianTaskDetailScreen extends StatefulWidget {
  const TechnicianTaskDetailScreen({super.key, required this.taskId});
  final dynamic taskId;
  @override
  State<TechnicianTaskDetailScreen> createState() => _TaskState();
}

class _TaskState extends State<TechnicianTaskDetailScreen> {
  final api = ApiService();
  late Future<dynamic> future = ApiService().task(widget.taskId);
  late Future<dynamic> questions = ApiService().taskQuestions(widget.taskId);
  bool verified = false, sending = false, completing = false, uploading = false;
  dynamic currentUserId;
  String amountType = 'fixed', duration = '3 Days';
  final amount = TextEditingController(),
      proposal = TextEditingController(),
      extraNotes = TextEditingController();
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final p = await api.profile();
      if (mounted)
        setState(() {
          currentUserId = p['id'] ?? p['user_id'];
          verified =
              p['is_verified'] == true ||
              (p['technician_profile'] is Map &&
                  p['technician_profile']['is_verified'] == true);
        });
    } catch (_) {}
  }

  bool _canAct(Map task) {
    final assigned = task['assigned_to'];
    final specialist = task['specialist_id'];
    final accepted = task['accepted_bidder_id'] ?? task['accepted_bid_id'];
    return (assigned != null && '$assigned' == '$currentUserId') ||
        (specialist != null && '$specialist' == '$currentUserId') ||
        accepted != null;
  }

  void _notice(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> _submit() async {
    if (!verified) return _notice('Bidding unlocks after admin verification.');
    final value = double.tryParse(amount.text.trim());
    if (value == null || value <= 0)
      return _notice('Enter a valid bid amount.');
    setState(() => sending = true);
    try {
      await api.submitBid(widget.taskId, {
        'amount': value,
        'amount_type': amountType,
        'message': proposal.text.trim(),
        'duration': duration,
        'extra_notes': extraNotes.text.trim(),
      });
      _notice('Bid submitted successfully.');
    } catch (_) {
      _notice('We could not submit your bid. Please check your proposal.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  Future<void> _complete() async {
    setState(() => completing = true);
    try {
      await api.completeTask(widget.taskId);
      _notice('Task marked as completed.');
    } catch (_) {
      _notice('We could not complete this task.');
    } finally {
      if (mounted) setState(() => completing = false);
    }
  }

  Future<void> _deliverable() async {
    final notes = TextEditingController();
    final percentage = TextEditingController(text: '100');
    PlatformFile? evidence;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialog) => AlertDialog(
          title: const Text('Submit work for inspection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(
                percentage,
                'Completion percentage',
                keyboard: TextInputType.number,
              ),
              _field(notes, 'Completion notes', lines: 3),
              OutlinedButton.icon(
                onPressed: () => AttachmentActions.show(
                  context,
                  label: 'evidence',
                  hasAttachment: evidence != null,
                  onDevice: () async {
                    final result = await FilePicker.pickFiles(
                      type: FileType.any,
                      withData: true,
                    );
                    if (result != null &&
                        result.files.single.bytes != null &&
                        result.files.single.size <= 25 * 1024 * 1024) {
                      setDialog(() => evidence = result.files.single);
                    }
                  },
                  onGallery: () async {
                    final file = await AttachmentActions.pickGallery();
                    if (file != null && file.size <= 25 * 1024 * 1024) {
                      setDialog(() => evidence = file);
                    }
                  },
                  onCamera: () async {
                    final file = await AttachmentActions.takePhoto(
                      context,
                      label: 'evidence',
                    );
                    if (file != null && file.size <= 25 * 1024 * 1024) {
                      setDialog(() => evidence = file);
                    }
                  },
                  onRemove: () => setDialog(() => evidence = null),
                ),
                icon: const Icon(Icons.attach_file),
                label: Text(
                  evidence == null ? 'Attach evidence' : evidence!.name,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return;
    final value = int.tryParse(percentage.text.trim());
    if (value == null || value < 0 || value > 100)
      return _notice('Enter a completion percentage from 0 to 100.');
    try {
      String fileUrl = '', fileName = '';
      int fileSize = 0;
      if (evidence != null) {
        final upload = await api.uploadEvidenceBytes(
          bytes: evidence!.bytes!,
          filename: evidence!.name,
        );
        fileUrl = '${upload['file_url'] ?? upload['url'] ?? ''}';
        fileName = evidence!.name;
        fileSize = evidence!.size;
      }
      await api.submitDeliverable(widget.taskId, {
        'completion_percentage': value,
        'notes': notes.text.trim(),
        'file_url': fileUrl,
        'file_name': fileName,
        'file_size': fileSize,
      });
      _notice('Work submitted for client inspection.');
    } catch (_) {
      _notice('We could not submit the deliverable.');
    }
  }

  Future<void> _quote() async {
    final quote = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Submit project quotation'),
        content: _field(
          quote,
          'Quotation amount (XOF)',
          keyboard: const TextInputType.numberWithOptions(decimal: true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Send quote'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final value = double.tryParse(quote.text.trim());
    if (value == null || value <= 0)
      return _notice('Enter a valid quotation amount.');
    try {
      await api.updateTask(widget.taskId, {
        'budget': value,
        'budget_min': value,
        'budget_max': value,
      });
      _notice('Project quotation sent.');
    } catch (_) {
      _notice('We could not send the quotation.');
    }
  }

  Future<void> _acceptOffer() async {
    try {
      await api.updateTask(widget.taskId, {'status': 'in_progress'});
      _notice('Project accepted.');
      if (mounted) setState(() => future = api.task(widget.taskId));
    } catch (_) {
      _notice('We could not accept this project offer.');
    }
  }

  Future<void> _messageClient(Map task) async {
    final client =
        task['client_id'] ??
        (task['client'] is Map ? task['client']['id'] : task['client']);
    if (client == null)
      return _notice('Client messaging is unavailable for this project.');
    try {
      await api.createConversation(client, taskId: widget.taskId);
      _notice('Conversation opened.');
    } catch (_) {
      _notice('We could not open a conversation with the client.');
    }
  }

  Future<void> _dispute() async {
    final title = TextEditingController(),
        description = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Open project dispute'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(title, 'Issue title'),
            _field(description, 'Describe the issue', lines: 4),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok != true ||
        title.text.trim().isEmpty ||
        description.text.trim().isEmpty)
      return;
    try {
      await api.createDispute({
        'task': widget.taskId,
        'title': title.text.trim(),
        'reason': 'project_issue',
        'description': description.text.trim(),
      });
      _notice('Dispute submitted for review.');
    } catch (_) {
      _notice('We could not submit the dispute.');
    }
  }

  @override
  Widget build(BuildContext c) => Scaffold(
    appBar: AppBar(
      title: const Text('Task details'),
      foregroundColor: _navy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: _bg,
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 0),
    body: FutureBuilder<dynamic>(
      future: future,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: _orange));
        if (s.hasError) return _center('This task is unavailable.');
        final t = s.data is Map ? s.data as Map : <String, dynamic>{};
        final status = '${t['status'] ?? 'open'}';
        final authorized = _canAct(t);
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${t['title'] ?? 'Task'}',
              style: const TextStyle(
                color: _navy,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${t['city'] ?? t['location'] ?? 'Location not specified'} • ${t['budget_min'] ?? 'Budget TBD'}',
              style: const TextStyle(color: _muted),
            ),
            const SizedBox(height: 18),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${t['description'] ?? 'No description provided.'}',
                      style: const TextStyle(color: _navy, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    _detailGrid(t),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _clientDetails(t),
            if (t['attachments'] is List &&
                (t['attachments'] as List).isNotEmpty)
              _attachments(t['attachments'] as List),
            if (t['skills_required'] is List || t['skills'] is List)
              _skills(
                t['skills_required'] is List
                    ? t['skills_required'] as List
                    : t['skills'] as List,
              ),
            FutureBuilder<dynamic>(
              future: questions,
              builder: (_, q) {
                final list = _items(q.data);
                return Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Questions',
                          style: TextStyle(
                            color: _navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (list.isEmpty)
                          const Text(
                            'No questions yet.',
                            style: TextStyle(color: _muted),
                          )
                        else
                          ...list.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.help_outline,
                                color: _orange,
                              ),
                              title: Text(
                                '${item is Map ? item['question'] ?? item['body'] ?? item['text'] ?? '' : item}',
                              ),
                              subtitle: item is Map && item['answer'] != null
                                  ? Text('${item['answer']}')
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            if (status == 'in_progress' && authorized) ...[
              ElevatedButton(
                onPressed: _deliverable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Submit work for inspection'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: completing ? null : _complete,
                child: Text(
                  completing ? 'Completing...' : 'Mark task complete',
                ),
              ),
            ],
            if (status == 'in_progress' && !authorized)
              _locked(
                'Project actions unavailable',
                'Only the assigned technician or accepted bidder can update this project.',
              ),
            if ((status == 'assigned' || status == 'pending') && authorized)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Direct hire offer',
                        style: TextStyle(
                          color: _navy,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _acceptOffer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Accept project offer'),
                      ),
                      OutlinedButton(
                        onPressed: _quote,
                        child: const Text('Submit project quotation'),
                      ),
                    ],
                  ),
                ),
              ),
            if (authorized && status != 'open')
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _messageClient(t),
                        icon: const Icon(Icons.message_outlined),
                        label: const Text('Message client'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _dispute,
                        icon: const Icon(Icons.support_agent),
                        label: const Text('Open dispute'),
                      ),
                    ],
                  ),
                ),
              ),
            if (status == 'open' && !verified)
              _locked(
                'Bidding is locked',
                'Admin verification is required before submitting bids.',
              ),
            if (status == 'open' && verified)
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: amountType,
                        decoration: const InputDecoration(
                          labelText: 'Quote type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'fixed',
                            child: Text('Fixed quote'),
                          ),
                          DropdownMenuItem(
                            value: 'hourly',
                            child: Text('Hourly rate'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => amountType = v ?? 'fixed'),
                      ),
                      _field(
                        amount,
                        amountType == 'hourly'
                            ? 'Hourly rate'
                            : 'Your fixed quote amount',
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: duration,
                        decoration: const InputDecoration(
                          labelText: 'Delivery duration',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            const [
                                  '1 Day',
                                  '2 Days',
                                  '3 Days',
                                  '5 Days',
                                  '1 Week',
                                ]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                        onChanged: (v) =>
                            setState(() => duration = v ?? '3 Days'),
                      ),
                      _field(proposal, 'Proposal message', lines: 4),
                      _field(extraNotes, 'Extra notes (optional)', lines: 3),
                      if (double.tryParse(amount.text.trim()) case final value?
                          when value > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _feePreview(value),
                        ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: sending ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(sending ? 'Submitting...' : 'Submit bid'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

Widget _detailGrid(Map t) => Wrap(
  spacing: 10,
  runSpacing: 10,
  children: [
    _detail(
      'Category',
      t['category_name'] ??
          (t['category'] is Map ? t['category']['name'] : t['category']),
    ),
    _detail('Budget mode', t['budget_mode']),
    _detail('Budget minimum', t['budget_min']),
    _detail('Budget maximum', t['budget_max']),
    _detail('Urgency', t['urgency']),
    _detail('Service type', t['service_type']),
    _detail('Schedule', t['schedule']),
    _detail('Deadline', t['deadline'] ?? t['due_date']),
    _detail('City', t['city']),
    _detail('Location', t['location']),
    _detail('Latitude', t['latitude']),
    _detail('Longitude', t['longitude']),
    _detail(
      'Materials provided',
      t['materials_provided'] == null
          ? null
          : (t['materials_provided'] == true ? 'Yes' : 'No'),
    ),
    _detail(
      'Contact methods',
      t['contact_methods'] is List
          ? (t['contact_methods'] as List).join(', ')
          : t['contact_methods'],
    ),
    _detail('Bid count', t['bids_count'] ?? t['bid_count'] ?? 0),
    _detail('Task views', t['views_count'] ?? t['views'] ?? 0),
    _detail(
      'Escrow status',
      t['escrow_status'] ?? (t['has_escrow'] == true ? 'Funded' : 'Not funded'),
    ),
    _detail(
      'Milestones',
      t['milestones'] is List
          ? '${(t['milestones'] as List).length} milestone(s)'
          : t['milestones'],
    ),
  ],
);
Widget _clientDetails(Map t) {
  final client = t['client_details'] is Map
      ? t['client_details'] as Map
      : const {};
  final name =
      t['client_name'] ??
      client['name'] ??
      client['full_name'] ??
      (t['client'] is Map ? t['client']['name'] : null) ??
      'Verified client';
  final avatar = t['client_avatar'] ?? client['avatar_url'];
  return Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: const Color(0xFFFFE8E0),
            backgroundImage: avatar == null || '$avatar'.isEmpty
                ? null
                : NetworkImage(ApiService().resolveImageUrl('$avatar')),
            child: avatar == null || '$avatar'.isEmpty
                ? const Icon(Icons.person_outline, color: _orange)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Client details',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$name',
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${client['client_type'] ?? t['client_type'] ?? 'Client'}',
                  style: const TextStyle(color: _muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _detail(String label, dynamic value) => SizedBox(
  width: 145,
  child: Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _muted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value == null || '$value'.isEmpty ? 'Not provided' : '$value',
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  ),
);
Widget _feePreview(double amount) {
  final fee = amount * .1;
  final payout = amount - fee;
  String money(double value) => value.toStringAsFixed(0);
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Service fee (10%)'),
            Text('- ${money(fee)} XOF'),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Estimated payout',
              style: TextStyle(fontWeight: FontWeight.w800, color: _navy),
            ),
            Text(
              '${money(payout)} XOF',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: _orange,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _skills(List values) => Card(
  elevation: 0,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Required skills',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: values
              .map(
                (x) => Chip(
                  label: Text(
                    x is Map ? '${x['name'] ?? x['title'] ?? ''}' : '$x',
                  ),
                  backgroundColor: const Color(0xFFFFE8E0),
                  side: BorderSide.none,
                ),
              )
              .toList(),
        ),
      ],
    ),
  ),
);
Widget _attachments(List values) => Card(
  elevation: 0,
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        ...values.map(
          (x) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.attach_file, color: _orange),
            title: Text(
              '${x is Map ? x['file_name'] ?? x['name'] ?? 'Attachment' : x}',
            ),
            subtitle: x is Map ? Text('${x['content_type'] ?? ''}') : null,
          ),
        ),
      ],
    ),
  ),
);
Widget _field(
  TextEditingController c,
  String hint, {
  int lines = 1,
  TextInputType? keyboard,
}) => Padding(
  padding: const EdgeInsets.only(top: 10),
  child: TextField(
    controller: c,
    maxLines: lines,
    keyboardType: keyboard,
    decoration: InputDecoration(
      hintText: hint,
      border: const OutlineInputBorder(),
    ),
  ),
);
Widget _locked(String title, String message) => Card(
  elevation: 0,
  child: ListTile(
    leading: const Icon(Icons.lock_outline, color: _orange),
    title: Text(
      title,
      style: const TextStyle(color: _navy, fontWeight: FontWeight.w700),
    ),
    subtitle: Text(message, style: const TextStyle(color: _muted)),
  ),
);
Widget _center(String text) => Center(
  child: Padding(
    padding: const EdgeInsets.all(28),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: _muted),
    ),
  ),
);
