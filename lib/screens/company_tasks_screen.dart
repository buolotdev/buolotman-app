import 'package:flutter/material.dart';
import '../core/api_service.dart';

class CompanyTasksScreen extends StatefulWidget {
  const CompanyTasksScreen({super.key});
  @override
  State<CompanyTasksScreen> createState() => _CompanyTasksState();
}

class _CompanyTasksState extends State<CompanyTasksScreen> {
  final api = ApiService();
  late Future<dynamic> future = api.tasks();
  String query = '';

  List<dynamic> _items(dynamic value) => value is List
      ? value
      : value is Map && value['results'] is List
      ? value['results'] as List
      : const [];

  void _reload() => setState(() => future = api.tasks());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse tasks'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF001F3F),
        actions: [
          IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
        ],
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<dynamic>(
        future: future,
        builder: (_, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Unable to load tasks.'));
          }
          final tasks = _items(snapshot.data).whereType<Map>().where((task) {
            final text =
                '${task['title'] ?? ''} ${task['description'] ?? ''} '
                        '${task['city'] ?? task['location'] ?? ''}'
                    .toLowerCase();
            return text.contains(query.trim().toLowerCase());
          }).toList();
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search tasks, skills, city or location',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${tasks.length} available tasks',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (tasks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No tasks match your search.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...tasks.map((task) => _card(task)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(Map task) {
    final id = task['id'];
    final min = task['budget_min'] ?? task['budget'] ?? '';
    final max = task['budget_max'];
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          '${task['title'] ?? 'Untitled task'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            '${task['city'] ?? task['location'] ?? 'Location flexible'} • '
            '${min.isEmpty ? 'Quote-based' : '$min XOF'}${max == null ? '' : ' - $max XOF'}\n'
            '${task['urgency'] ?? task['status'] ?? 'open'}',
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: id == null
            ? null
            : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyTaskDetailScreen(taskId: id),
                ),
              ),
      ),
    );
  }
}

class CompanyTaskDetailScreen extends StatefulWidget {
  const CompanyTaskDetailScreen({super.key, required this.taskId});
  final dynamic taskId;
  @override
  State<CompanyTaskDetailScreen> createState() => _CompanyTaskDetailState();
}

class _CompanyTaskDetailState extends State<CompanyTaskDetailScreen> {
  final api = ApiService();
  late Future<dynamic> future = api.task(widget.taskId);
  bool saving = false;

  Future<void> _message(Map task) async {
    final client =
        task['client_id'] ??
        (task['client'] is Map ? task['client']['id'] : task['client']);
    try {
      final result = await api.createConversation(
        client,
        participantName: '${task['client_name'] ?? 'Client'}',
        taskId: widget.taskId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result == null
                ? 'Conversation unavailable.'
                : 'Conversation opened.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open conversation.')),
        );
      }
    }
  }

  Future<void> _submitBid(Map task) async {
    final amount = TextEditingController(
      text: '${task['budget_max'] ?? task['budget_min'] ?? ''}',
    );
    final message = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit proposal'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount (XOF)'),
                validator: (v) => double.tryParse(v?.trim() ?? '') == null
                    ? 'Enter a valid amount'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: message,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Proposal message',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter a message' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, {
                'amount': double.parse(amount.text.trim()),
                'message': message.text.trim(),
              });
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    amount.dispose();
    message.dispose();
    if (values == null) return;
    setState(() => saving = true);
    try {
      await api.submitBid(widget.taskId, values);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Proposal submitted.')));
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to submit proposal.')),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Task details'),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF001F3F),
    ),
    backgroundColor: const Color(0xFFF5F7FA),
    body: FutureBuilder<dynamic>(
      future: future,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError || snapshot.data is! Map)
          return const Center(child: Text('Task unavailable.'));
        final task = snapshot.data as Map;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              '${task['title'] ?? 'Task'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF001F3F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${task['city'] ?? task['location'] ?? 'Location flexible'} • ${task['status'] ?? 'open'}',
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '${task['description'] ?? 'No description provided.'}',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${task['budget_min'] ?? task['budget'] ?? 'Quote-based'} XOF${task['budget_max'] == null ? '' : ' - ${task['budget_max']} XOF'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : () => _submitBid(task),
              icon: const Icon(Icons.send),
              label: Text(saving ? 'Submitting...' : 'Submit proposal'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _message(task),
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message client'),
            ),
          ],
        );
      },
    ),
  );
}
