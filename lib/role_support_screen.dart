import 'package:flutter/material.dart';
import 'core/api_service.dart';
import 'app_language.dart';

class RoleSupportScreen extends StatefulWidget {
  const RoleSupportScreen({super.key, required this.role});
  final String role;

  @override
  State<RoleSupportScreen> createState() => _RoleSupportScreenState();
}

class _RoleSupportScreenState extends State<RoleSupportScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = api.supportTickets();

  void reload() => setState(() => future = api.supportTickets());

  Future<void> createTicket() async {
    final subject = TextEditingController();
    final body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.text('New support ticket')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subject,
              decoration: InputDecoration(
                labelText: AppLanguage.text('Subject'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: body,
              minLines: 3,
              maxLines: 6,
              decoration: InputDecoration(
                labelText: AppLanguage.text('Describe the issue'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLanguage.text('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLanguage.text('Submit')),
          ),
        ],
      ),
    );
    if (ok != true || subject.text.trim().isEmpty || body.text.trim().isEmpty)
      return;
    try {
      await api.createSupportTicket({
        'subject': subject.text.trim(),
        'body': body.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLanguage.text('Support ticket submitted.')),
          ),
        );
        reload();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not submit ticket: $e')));
    }
  }

  Future<void> reply(dynamic id) async {
    final body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLanguage.text('Reply to support')),
        content: TextField(controller: body, minLines: 3, maxLines: 6),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLanguage.text('Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLanguage.text('Send')),
          ),
        ],
      ),
    );
    if (ok != true || body.text.trim().isEmpty) return;
    try {
      await api.replySupportTicket(id, body.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLanguage.text('Reply sent.'))),
        );
        reload();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not send reply: $e')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('${widget.role} support'),
      foregroundColor: const Color(0xFF001F3F),
      backgroundColor: Colors.white,
      actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
    ),
    backgroundColor: const Color(0xFFF5F7FA),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: createTicket,
      backgroundColor: const Color(0xFFFF4500),
      label: Text(AppLanguage.text('New ticket')),
      icon: const Icon(Icons.add),
    ),
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (_, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError)
          return Center(
            child: Text(
              AppLanguage.text('Support is temporarily unavailable.'),
            ),
          );
        final items = snapshot.data ?? const [];
        if (items.isEmpty)
          return Center(
            child: Text(AppLanguage.text('No support tickets yet.')),
          );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, index) {
            final ticket = items[index] is Map ? items[index] as Map : {};
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text('${ticket['subject'] ?? 'Support ticket'}'),
                subtitle: Text(
                  '${ticket['status'] ?? 'open'}\n${ticket['body'] ?? ''}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.reply),
                  onPressed: ticket['id'] == null
                      ? null
                      : () => reply(ticket['id']),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}
