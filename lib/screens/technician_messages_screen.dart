import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/realtime_chat.dart';
import 'technician_navigation.dart';

class TechnicianMessagesScreen extends StatefulWidget {
  const TechnicianMessagesScreen({super.key});
  @override
  State<TechnicianMessagesScreen> createState() => _MessagesState();
}

class _MessagesState extends State<TechnicianMessagesScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = api.conversations();
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      muted = Color(0xFF64748B);
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 0),
    appBar: AppBar(
      title: const Text('Messages'),
      foregroundColor: navy,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () => setState(() => future = api.conversations()),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    backgroundColor: const Color(0xFFF4F6F8),
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: orange));
        if (snapshot.hasError)
          return _empty('Messages are temporarily unavailable.');
        final items = snapshot.data ?? const [];
        if (items.isEmpty) return _empty('No conversations yet.');
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final x = items[i] as Map;
            final other = x['other_participant'] is Map
                ? x['other_participant'] as Map
                : {};
            final last = x['last_message'] is Map
                ? x['last_message'] as Map
                : {};
            final unread = int.tryParse('${x['unread_count'] ?? 0}') ?? 0;
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: x['id'] == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TechnicianConversationScreen(
                            conversationId: x['id'],
                          ),
                        ),
                      ),
                leading: CircleAvatar(
                  backgroundColor: unread > 0
                      ? const Color(0xFFFFE0D6)
                      : const Color(0xFFE8EEF5),
                  child: Text(
                    '${other['initials'] ?? 'C'}',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  '${other['name'] ?? 'Conversation'}',
                  style: TextStyle(
                    color: navy,
                    fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '${x['task_title'] ?? ''}${x['task_title'] != null && '${x['task_title']}'.isNotEmpty ? '\n' : ''}${last['text'] ?? 'No messages yet'}',
                  maxLines: 2,
                ),
                trailing: unread > 0
                    ? CircleAvatar(
                        radius: 12,
                        backgroundColor: orange,
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    ),
  );
  Widget _empty(String s) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Text(
        s,
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted),
      ),
    ),
  );
}

class TechnicianConversationScreen extends StatefulWidget {
  const TechnicianConversationScreen({super.key, required this.conversationId});
  final dynamic conversationId;
  @override
  State<TechnicianConversationScreen> createState() => _ConversationState();
}

class _ConversationState extends State<TechnicianConversationScreen> {
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      muted = Color(0xFF64748B);
  final api = ApiService();
  final draft = TextEditingController();
  late Future<dynamic> future = api.conversation(widget.conversationId);
  RealtimeChatConnection? realtime;
  PlatformFile? attachment;
  bool sending = false;
  dynamic currentUserId;
  @override
  void initState() {
    super.initState();
    _loadUser();
    _connectRealtime();
  }

  Future<void> _connectRealtime() async {
    realtime = RealtimeChatConnection();
    await realtime!.connect(
      conversationId: widget.conversationId,
      onMessage: _receiveRealtimeMessage,
    );
  }

  void _receiveRealtimeMessage(Map<String, dynamic> event) {
    if (!mounted || event['type'] != 'message') return;
    setState(() => future = api.conversation(widget.conversationId));
    api.markConversationRead(widget.conversationId);
  }

  Future<void> _loadUser() async {
    try {
      final p = await api.profile();
      currentUserId = p['id'];
      await api.markConversationRead(widget.conversationId);
      if (mounted) setState(() {});
    } catch (_) {}
  }

  @override
  void dispose() {
    realtime?.close();
    draft.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final r = await FilePicker.pickFiles(type: FileType.any, withData: true);
    if (!mounted || r == null || r.files.single.bytes == null) return;
    if (r.files.single.bytes!.length > 25 * 1024 * 1024) {
      _notice('Attachment must be 25 MB or smaller.');
      return;
    }
    setState(() => attachment = r.files.single);
  }

  Future<void> _send() async {
    if (draft.text.trim().isEmpty && attachment == null) return;
    setState(() => sending = true);
    try {
      Map<String, dynamic> uploaded = {};
      if (attachment != null)
        uploaded = await api.uploadMessageAttachment(
          conversationId: widget.conversationId,
          bytes: attachment!.bytes!,
          filename: attachment!.name,
        );
      await api.sendMessage(widget.conversationId, {
        'text': draft.text.trim(),
        'attachment_url': uploaded['url'] ?? '',
        'attachment_key': uploaded['key'] ?? '',
        'attachment_name': uploaded['name'] ?? '',
        'attachment_type': uploaded['type'] ?? 'file',
        'attachment_size': uploaded['size'] ?? 0,
        'attachment_content_type': uploaded['content_type'] ?? '',
      });
      draft.clear();
      attachment = null;
      if (mounted)
        setState(() => future = api.conversation(widget.conversationId));
    } catch (e) {
      if (mounted)
        _notice(
          e is ApiException ? e.message : 'We could not send this message.',
        );
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _notice(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 0),
    appBar: AppBar(
      title: const Text('Conversation'),
      foregroundColor: navy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: const Color(0xFFF4F6F8),
    body: FutureBuilder<dynamic>(
      future: future,
      builder: (_, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: orange));
        if (s.hasError)
          return const Center(
            child: Text(
              'Conversation unavailable.',
              style: TextStyle(color: muted),
            ),
          );
        final data = s.data is Map ? s.data as Map : {};
        final messages = data['messages'] is List
            ? data['messages'] as List
            : const [];
        return Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No messages yet. Start the conversation.',
                        style: TextStyle(color: muted),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(14),
                      itemCount: messages.length,
                      itemBuilder: (_, i) {
                        final m = messages[i] is Map ? messages[i] as Map : {};
                        final mine = '${m['sender']}' == '$currentUserId';
                        final text = '${m['text'] ?? ''}';
                        final url = '${m['attachment_url'] ?? ''}';
                        return Align(
                          alignment: mine
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 310),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: mine ? orange : Colors.white,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (text.isNotEmpty)
                                  Text(
                                    text,
                                    style: TextStyle(
                                      color: mine ? Colors.white : navy,
                                    ),
                                  ),
                                if (url.isNotEmpty)
                                  InkWell(
                                    onTap: () => _notice(
                                      'Attachment: ${m['attachment_name'] ?? 'file'}',
                                    ),
                                    child: Text(
                                      '📎 ${m['attachment_name'] ?? 'Attachment'}',
                                      style: TextStyle(
                                        color: mine ? Colors.white : orange,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 3),
                                Text(
                                  '${m['read_at'] != null && mine ? 'Read' : ''}',
                                  style: TextStyle(
                                    color: mine ? Colors.white70 : muted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (attachment != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Attached: ${attachment!.name}',
                  style: const TextStyle(color: muted),
                ),
              ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: sending ? null : _pick,
                      icon: const Icon(Icons.attach_file, color: orange),
                    ),
                    Expanded(
                      child: TextField(
                        controller: draft,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Write a message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: sending ? null : _send,
                      icon: const Icon(Icons.send, color: orange),
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
