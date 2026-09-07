import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'technician_navigation.dart';
import 'technician_area_screens.dart';

class TechnicianBidsManagementScreen extends StatefulWidget {
  const TechnicianBidsManagementScreen({super.key});
  @override
  State<TechnicianBidsManagementScreen> createState() => _BidsManagementState();
}

class _BidsManagementState extends State<TechnicianBidsManagementScreen> {
  final api = ApiService();
  late Future<dynamic> future = api.myBids();
  String query = '', filter = 'all', sort = 'newest';
  int page = 0;
  static const pageSize = 5;
  dynamic data;

  List<dynamic> _items(dynamic value) => value is List
      ? value
      : value is Map && value['results'] is List
          ? value['results'] as List
          : const [];

  List<Map> _filtered() {
    final result = _items(data).whereType<Map>().where((bid) {
      final status = '${bid['status'] ?? 'pending'}'.toLowerCase();
      if (filter != 'all' && status != filter) return false;
      final searchable = '${bid['task_title'] ?? bid['title'] ?? ''} '
          '${bid['location'] ?? bid['city'] ?? ''} '
          '${bid['client'] ?? bid['client_name'] ?? ''} '
          '${bid['message'] ?? bid['proposal'] ?? ''} '
          '${bid['extra_notes'] ?? bid['extra'] ?? ''} '
          '${bid['skills'] ?? ''}'.toLowerCase();
      return query.trim().isEmpty || searchable.contains(query.trim().toLowerCase());
    }).toList();
    result.sort((a, b) {
      final aAmount = double.tryParse('${a['amount'] ?? 0}') ?? 0;
      final bAmount = double.tryParse('${b['amount'] ?? 0}') ?? 0;
      if (sort == 'highest') return bAmount.compareTo(aAmount);
      if (sort == 'lowest') return aAmount.compareTo(bAmount);
      return '${b['submitted_at'] ?? b['created_at'] ?? ''}'.compareTo('${a['submitted_at'] ?? a['created_at'] ?? ''}');
    });
    return result;
  }

  Future<void> _reload() async => setState(() => future = api.myBids());

  Future<void> _withdraw(Map bid) async {
    final id = bid['id'];
    if (id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Withdraw pending bid?'),
        content: const Text('You can submit a new bid for this task after withdrawal.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Withdraw')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.withdrawBid(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid withdrawn.')));
        setState(() => future = api.myBids());
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('We could not withdraw this bid.')));
    }
  }

  Future<void> _messageClient(Map bid) async {
    final client = bid['client_id'] ?? bid['client_user_id'] ?? bid['client'];
    final task = bid['task_id'] ?? bid['task'];
    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Client messaging is unavailable for this bid.')));
      return;
    }
    try {
      await api.createConversation(client, taskId: task);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conversation opened.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('We could not open a conversation with the client.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bids'),
        foregroundColor: const Color(0xFF001F3F),
        backgroundColor: Colors.white,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 1),
      body: FutureBuilder<dynamic>(
        future: future,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4500)));
          }
          if (snapshot.hasError) return const Center(child: Text('Unable to load your bids.'));
          data = snapshot.data;
          final all = _filtered();
          final totalPages = all.isEmpty ? 1 : (all.length / pageSize).ceil();
          final current = page.clamp(0, totalPages - 1);
          final visible = all.skip(current * pageSize).take(pageSize).toList();
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  onChanged: (value) => setState(() { query = value; page = 0; }),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search bids, tasks, clients or skills',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['all', 'pending', 'accepted', 'rejected', 'withdrawn']
                        .map((value) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(value),
                                selected: filter == value,
                                onSelected: (_) => setState(() { filter = value; page = 0; }),
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: sort,
                  decoration: const InputDecoration(labelText: 'Sort bids', filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Newest')),
                    DropdownMenuItem(value: 'highest', child: Text('Highest amount')),
                    DropdownMenuItem(value: 'lowest', child: Text('Lowest amount')),
                  ],
                  onChanged: (value) => setState(() { sort = value ?? 'newest'; page = 0; }),
                ),
                const SizedBox(height: 14),
                Text('${all.length} bids found', style: const TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                if (visible.isEmpty)
                  const Padding(padding: EdgeInsets.all(28), child: Text('No bids match your filters.', textAlign: TextAlign.center))
                else
                  ...visible.map(_card),
                if (totalPages > 1)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(onPressed: current == 0 ? null : () => setState(() => page--), icon: const Icon(Icons.chevron_left)),
                      Text('${current + 1} / $totalPages'),
                      IconButton(onPressed: current >= totalPages - 1 ? null : () => setState(() => page++), icon: const Icon(Icons.chevron_right)),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(Map bid) {
    final status = '${bid['status'] ?? 'pending'}'.toLowerCase();
    final taskId = bid['task_id'] ?? bid['task'];
    final amount = double.tryParse('${bid['amount'] ?? 0}') ?? 0;
    final skills = bid['skills'] is List ? (bid['skills'] as List).join(', ') : '${bid['skills'] ?? ''}';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${bid['task_title'] ?? bid['title'] ?? 'Task #$taskId'}', style: const TextStyle(color: Color(0xFF001F3F), fontSize: 17, fontWeight: FontWeight.w800))),
            Chip(label: Text(status), side: BorderSide.none),
          ]),
          const SizedBox(height: 8),
          Text('${bid['location'] ?? bid['city'] ?? 'Location not specified'} • ${bid['competing_bids'] ?? bid['competingBids'] ?? 0} competing bids', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Text('Your proposal: ${bid['message'] ?? bid['proposal'] ?? 'No message'}', style: const TextStyle(color: Color(0xFF334155))),
          if (skills.isNotEmpty) Text('Skills: $skills', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Text('${bid['amount_type'] ?? 'fixed'} • ${amount.toStringAsFixed(0)} XOF • ${bid['duration'] ?? 'Duration not specified'}', style: const TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w700)),
          if ('${bid['extra_notes'] ?? bid['extra'] ?? ''}'.isNotEmpty) Text('Extra notes: ${bid['extra_notes'] ?? bid['extra']}', style: const TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (status == 'pending') OutlinedButton.icon(onPressed: () => _withdraw(bid), icon: const Icon(Icons.undo), label: const Text('Withdraw')),
            if (status == 'accepted') OutlinedButton.icon(onPressed: () => _messageClient(bid), icon: const Icon(Icons.message_outlined), label: const Text('Message client')),
            OutlinedButton.icon(onPressed: taskId == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TechnicianTaskDetailScreen(taskId: taskId))), icon: const Icon(Icons.open_in_new), label: const Text('View task')),
          ]),
        ]),
      ),
    );
  }
}
