import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_service.dart';
import '../core/realtime_chat.dart';
import '../attachment_actions.dart';
import '../chat_contact_profile_screen.dart';
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
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: null),
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
      muted = Color(0xFF64748B),
      sentBubble = Color(0xFFFFE0D6);
  final api = ApiService();
  final draft = TextEditingController();
  late Future<dynamic> future = api.conversation(widget.conversationId);
  RealtimeChatConnection? realtime;
  PlatformFile? attachment;
  bool sending = false;
  dynamic currentUserId;
  bool? otherOnline;
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
      onPresence: (event) {
        if (!mounted || event['user_id'] == null) return;
        setState(() => otherOnline = event['is_online'] == true);
      },
    );
  }

  void _receiveRealtimeMessage(Map<String, dynamic> event) {
    if (!mounted) return;
    if (event['type'] != 'message') {
      if (event['type'] == 'message_status' ||
          event['type'] == 'message_read' ||
          event['type'] == 'read_receipt') {
        setState(() => future = api.conversation(widget.conversationId));
      }
      return;
    }
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

  Future<void> _pickFromDevice() async {
    final r = await FilePicker.pickFiles(type: FileType.any, withData: true);
    if (!mounted || r == null || r.files.single.bytes == null) return;
    if (r.files.single.bytes!.length > 25 * 1024 * 1024) {
      _notice('Attachment must be 25 MB or smaller.');
      return;
    }
    setState(() => attachment = r.files.single);
  }

  Future<void> _pickFromGallery() async {
    final file = await AttachmentActions.pickGallery();
    if (file == null || !mounted) return;
    if (file.size > 25 * 1024 * 1024) {
      _notice('Attachment must be 25 MB or smaller.');
      return;
    }
    setState(() => attachment = file);
  }

  Future<void> _pickFromCamera() async {
    final file = await AttachmentActions.takePhoto(
      context,
      label: 'attachment',
    );
    if (file == null || !mounted) return;
    if (file.size > 25 * 1024 * 1024) {
      _notice('Attachment must be 25 MB or smaller.');
      return;
    }
    setState(() => attachment = file);
  }

  Future<void> _pick() => AttachmentActions.show(
    context,
    label: 'attachment',
    hasAttachment: attachment != null,
    onDevice: _pickFromDevice,
    onGallery: _pickFromGallery,
    onCamera: _pickFromCamera,
    onRemove: () => setState(() => attachment = null),
  );

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
      final uploadedFile = uploaded['file'];
      final uploadedUrl = attachment == null
          ? ''
          : '${uploaded['url'] ?? uploaded['file_url'] ?? uploaded['attachment_url'] ?? (uploadedFile is Map ? uploadedFile['url'] ?? uploadedFile['file_url'] : '')}';
      final attachmentUrl = api.resolveImageUrl(uploadedUrl);
      if (attachment != null && attachmentUrl.isEmpty) {
        throw const ApiException('The attachment upload returned no URL.', 500);
      }
      await api.sendMessage(widget.conversationId, {
        'text': draft.text.trim(),
        'attachment_url': attachmentUrl,
        'attachment_name':
            uploaded['name'] ?? uploaded['file_name'] ?? attachment?.name ?? '',
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

  String _lastSeen(Map other) =>
      '${other['last_seen_display'] ?? other['last_seen_at'] ?? other['last_seen'] ?? 'Offline'}';

  Future<void> _openAttachment(String value, String name) async {
    final uri = Uri.tryParse(api.resolveImageUrl(value));
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _notice('Could not open ${name.isEmpty ? 'the attachment' : name}.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: null),
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
        final participants = data['participants'] is List
            ? data['participants'] as List
            : const [];
        final other = participants
            .where((p) => p is Map && '${p['id']}' != '$currentUserId')
            .cast<dynamic>()
            .firstOrNull;
        final otherMap = other is Map ? other : <String, dynamic>{};
        final online = otherOnline ?? otherMap['is_online'] == true;
        final messages = data['messages'] is List
            ? data['messages'] as List
            : const [];
        return Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: otherMap['id'] == null
                        ? null
                        : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatContactProfileScreen(
                                userId: otherMap['id'],
                              ),
                            ),
                          ),
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFFE2E8F0),
                      backgroundImage:
                          api
                              .resolveImageUrl(
                                otherMap['avatar_url'] as String?,
                              )
                              .isEmpty
                          ? null
                          : NetworkImage(
                              api.resolveImageUrl(
                                otherMap['avatar_url'] as String?,
                              ),
                            ),
                      child: '${otherMap['avatar_url'] ?? ''}'.isEmpty
                          ? Text('${otherMap['initials'] ?? '?'}')
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: otherMap['id'] == null
                          ? null
                          : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatContactProfileScreen(
                                  userId: otherMap['id'],
                                ),
                              ),
                            ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${otherMap['name'] ?? otherMap['email'] ?? 'Conversation'}',
                            style: const TextStyle(
                              color: navy,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if ('${otherMap['username'] ?? ''}'.trim().isNotEmpty)
                            Text(
                              '@${otherMap['username']}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 11,
                              ),
                            ),
                          Text(
                            online ? 'Online' : _lastSeen(otherMap),
                            style: TextStyle(
                              color: online ? Colors.green : muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                        final previous = i > 0 ? messages[i - 1] : null;
                        final currentDate = _messageDate(messages[i]);
                        final showDate =
                            i == 0 ||
                            !_sameDay(currentDate, _messageDate(previous));
                        final m = messages[i] is Map ? messages[i] as Map : {};
                        final mine = '${m['sender']}' == '$currentUserId';
                        final text = '${m['text'] ?? ''}';
                        final url = '${m['attachment_url'] ?? ''}';
                        final read =
                            m['read_at'] != null ||
                            m['is_read'] == true ||
                            '${m['status']}'.toLowerCase() == 'read';
                        final delivered =
                            read ||
                            m['delivered_at'] != null ||
                            m['is_delivered'] == true ||
                            '${m['status']}'.toLowerCase() == 'delivered';
                        return Column(
                          children: [
                            if (showDate) _dateDivider(currentDate),
                            Align(
                              alignment: mine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 310,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: mine ? sentBubble : Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (text.isNotEmpty)
                                      Text(text, style: TextStyle(color: navy)),
                                    if (url.isNotEmpty)
                                      InkWell(
                                        onTap: () => _openAttachment(
                                          url,
                                          '${m['attachment_name'] ?? ''}',
                                        ),
                                        child: Text(
                                          'Attachment: ${m['attachment_name'] ?? 'Attachment'}',
                                          style: TextStyle(
                                            color: orange,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 3),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          _time(m['created_at']),
                                          style: TextStyle(
                                            color: muted,
                                            fontSize: 10,
                                          ),
                                        ),
                                        if (mine) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            delivered
                                                ? Icons.done_all
                                                : Icons.done,
                                            size: 14,
                                            color: read ? orange : muted,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
            Padding(
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
          ],
        );
      },
    ),
  );

  String _time(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '';
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  DateTime? _messageDate(dynamic raw) {
    if (raw is! Map) return null;
    return DateTime.tryParse(
      '${raw['created_at'] ?? raw['timestamp']}',
    )?.toLocal();
  }

  bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _dateDivider(DateTime? date) {
    final label = _dateLabel(date);
    if (label.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
