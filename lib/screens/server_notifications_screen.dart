import 'package:flutter/material.dart';
import '../core/api_service.dart';

class ServerNotificationsScreen extends StatefulWidget {
  const ServerNotificationsScreen({super.key});
  @override
  State<ServerNotificationsScreen> createState() => _ServerNotificationsState();
}

class _ServerNotificationsState extends State<ServerNotificationsScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = ApiService().notifications();
  Future<void> reload() async => setState(() => future = api.notifications());
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Notifications'),
      foregroundColor: const Color(0xFF001F3F),
      backgroundColor: Colors.white,
      actions: [IconButton(onPressed: reload, icon: const Icon(Icons.refresh))],
    ),
    backgroundColor: const Color(0xFFF5F7FA),
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (_, snap) {
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF4500)),
          );
        final items = snap.data!;
        if (items.isEmpty)
          return const Center(child: Text('No notifications yet.'));
        return RefreshIndicator(
          onRefresh: reload,
          child: ListView.builder(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final n = items[i] is Map ? items[i] as Map : {};
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: Icon(
                    n['is_read'] == true
                        ? Icons.notifications_none
                        : Icons.notifications_active,
                    color: const Color(0xFFFF4500),
                  ),
                  title: Text(
                    '${n['title'] ?? 'Notification'}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${n['body'] ?? n['message'] ?? ''}\n${n['created_at'] ?? ''}',
                  ),
                  isThreeLine: true,
                  onTap: n['id'] == null
                      ? null
                      : () async {
                          await api.markNotificationRead(n['id']);
                          reload();
                        },
                ),
              );
            },
          ),
        );
      },
    ),
  );
}
