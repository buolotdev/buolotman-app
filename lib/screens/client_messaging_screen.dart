import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'client_dashboard_screen.dart';
import 'client_task_management_screen.dart';
import 'client_navigation_screens.dart';
import '../core/realtime_chat.dart';
import '../attachment_actions.dart';
import '../chat_contact_profile_screen.dart';

const messageNavy = Color(0xFF001F3F),
    messageOrange = Color(0xFFFF4500),
    messageMuted = Color(0xFF64748B),
    messageBg = Color(0xFFF5F7FA);

class ClientMessagesScreen extends StatefulWidget {
  const ClientMessagesScreen({
    super.key,
    this.conversationId,
    this.taskId,
    this.participantId,
    this.participantName,
    this.contextType,
    this.contextId,
    this.withBottomNavigation = true,
  });
  final dynamic conversationId, taskId, participantId, contextId;
  final String? contextType;
  final String? participantName;
  final bool withBottomNavigation;
  @override
  State<ClientMessagesScreen> createState() => _ClientMessagesState();
}

class _ClientMessagesState extends State<ClientMessagesScreen> {
  final api = ApiService();
  List<dynamic> conversations = [];
  dynamic activeId;
  bool loading = true, openingLinked = false;
  @override
  void initState() {
    super.initState();
    activeId = widget.conversationId;
    _load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await api.conversations();
      if (!mounted) return;
      setState(() {
        conversations = data;
        loading = false;
      });
      if (activeId == null && conversations.isNotEmpty)
        setState(() => activeId = conversations.first['id']);
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openLinked() async {
    if (openingLinked ||
        (widget.taskId == null &&
            widget.participantId == null &&
            (widget.participantName ?? '').isEmpty))
      return;
    openingLinked = true;
    try {
      final created = await api.createConversation(
        widget.participantId,
        taskId: widget.taskId,
        contextType: widget.contextType,
        contextId: widget.contextId,
      );
      if (mounted && created is Map && created['id'] != null)
        setState(() => activeId = created['id']);
    } catch (_) {
    } finally {
      openingLinked = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.taskId != null ||
        widget.participantId != null ||
        (widget.participantName ?? '').isNotEmpty)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (activeId == null) _openLinked();
      });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        foregroundColor: messageNavy,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh, color: messageNavy),
          ),
        ],
      ),
      backgroundColor: messageBg,
      body: loading
          ? const Center(child: CircularProgressIndicator(color: messageOrange))
          : conversations.isEmpty && activeId == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.forum_outlined,
                      size: 48,
                      color: Color(0xFFCBD5E1),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No conversations yet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: messageNavy,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Accept a proposal to start messaging.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: messageMuted, height: 1.35),
                    ),
                  ],
                ),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                if (compact && activeId != null) {
                  return Column(
                    children: [
                      Container(
                        color: Colors.white,
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => setState(() => activeId = null),
                          icon: const Icon(Icons.arrow_back),
                          label: const Text('All conversations'),
                        ),
                      ),
                      Expanded(
                        child: ClientConversationScreen(
                          conversationId: activeId,
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    SizedBox(
                      width: compact ? double.infinity : 145,
                      child: _conversationList(),
                    ),
                    if (!compact)
                      Expanded(
                        child: activeId == null
                            ? const Center(
                                child: Text(
                                  'Select a conversation',
                                  style: TextStyle(color: messageMuted),
                                ),
                              )
                            : ClientConversationScreen(
                                conversationId: activeId,
                              ),
                      ),
                  ],
                );
              },
            ),
      bottomNavigationBar: widget.withBottomNavigation
          ? _bottomNavigation(context)
          : null,
    );
  }

  Widget _bottomNavigation(BuildContext context) => BottomNavigationBar(
    currentIndex: 2,
    selectedItemColor: messageOrange,
    unselectedItemColor: messageMuted,
    onTap: (index) {
      if (index == 2) return;
      final page = index == 0
          ? const ClientDashboardScreen()
          : index == 1
          ? const ClientTasksScreen()
          : const ClientProfileOverviewScreen();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page));
    },
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
  Widget _conversationList() => ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: 8),
    itemCount: conversations.length,
    itemBuilder: (_, i) {
      final x = conversations[i] is Map
          ? conversations[i] as Map
          : <String, dynamic>{};
      final other = x['other_participant'] is Map
          ? x['other_participant'] as Map
          : <String, dynamic>{};
      final selected = '${x['id']}' == '$activeId';
      final unread = int.tryParse('${x['unread_count'] ?? 0}') ?? 0;
      return InkWell(
        onTap: () => setState(() => activeId = x['id']),
        child: Container(
          padding: const EdgeInsets.all(10),
          color: selected ? const Color(0xFFFFE0D6) : Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: const Color(0xFFFFE8E0),
                child: Text(
                  '${other['initials'] ?? '?'}',
                  style: const TextStyle(
                    color: messageOrange,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${other['name'] ?? 'Conversation'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: messageNavy,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              if ('${x['task_title'] ?? ''}'.isNotEmpty)
                Text(
                  '${x['task_title']}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: messageMuted, fontSize: 10),
                ),
              if (unread > 0)
                Text(
                  '$unread unread',
                  style: const TextStyle(
                    color: messageOrange,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class ClientConversationScreen extends StatefulWidget {
  const ClientConversationScreen({super.key, required this.conversationId});
  final dynamic conversationId;
  @override
  State<ClientConversationScreen> createState() => _ClientConversationState();
}

class _ClientConversationState extends State<ClientConversationScreen> {
  final api = ApiService();
  final draft = TextEditingController();
  Map<String, dynamic> conversation = {};
  List<dynamic> messages = [];
  PlatformFile? attachment;
  dynamic currentUserId;
  bool loading = true, sending = false;
  RealtimeChatConnection? realtime;
  final Map<String, bool> presence = {};
  @override
  void initState() {
    super.initState();
    _load();
    _connectRealtime();
  }

  Future<void> _connectRealtime() async {
    realtime = RealtimeChatConnection();
    await realtime!.connect(
      conversationId: widget.conversationId,
      onMessage: _receiveRealtimeMessage,
      onPresence: (event) {
        if (!mounted || event['user_id'] == null) return;
        setState(
          () => presence['${event['user_id']}'] = event['is_online'] == true,
        );
      },
    );
  }

  void _receiveRealtimeMessage(Map<String, dynamic> event) {
    if (event['type'] == 'message_status' ||
        event['type'] == 'message_read' ||
        event['type'] == 'read_receipt') {
      _applyReceipt(event);
      return;
    }
    if (!mounted || event['type'] != 'message' || event['message'] is! Map)
      return;
    final incoming = Map<String, dynamic>.from(event['message'] as Map);
    final incomingId = incoming['id'];
    if (incomingId != null &&
        messages.any((item) => item is Map && item['id'] == incomingId))
      return;
    setState(() => messages = [...messages, incoming]);
    ApiService().markConversationRead(widget.conversationId);
  }

  void _applyReceipt(Map<String, dynamic> event) {
    final id = event['message_id'] ?? event['id'];
    if (!mounted || id == null) return;
    final status = '${event['status'] ?? ''}'.toLowerCase();
    final timestamp = event['timestamp'] ?? DateTime.now().toIso8601String();
    setState(() {
      messages = messages.map((raw) {
        if (raw is! Map || '${raw['id']}' != '$id') return raw;
        return {
          ...raw,
          if (status == 'delivered' || status == 'read')
            'delivered_at': event['delivered_at'] ?? timestamp,
          if (status == 'read') 'read_at': event['read_at'] ?? timestamp,
        };
      }).toList();
    });
  }

  @override
  void dispose() {
    realtime?.close();
    draft.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await api.conversation(widget.conversationId);
      Map<String, dynamic> profile = {};
      try {
        profile = await api.profile();
      } catch (_) {}
      if (mounted)
        setState(() {
          conversation = data is Map ? Map<String, dynamic>.from(data) : {};
          currentUserId = profile['id'] ?? profile['user_id'];
          messages = conversation['messages'] is List
              ? conversation['messages'] as List
              : [];
          loading = false;
        });
      await api.markConversationRead(widget.conversationId);
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pickFromDevice() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'mp4',
        'mov',
        'pdf',
        'doc',
        'docx',
      ],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final file = result.files.single;
    if (file.size > 25 * 1024 * 1024) {
      _notice('Files must be 25 MB or smaller.');
      return;
    }
    setState(() => attachment = file);
  }

  Future<void> _pickFromGallery() async {
    final file = await AttachmentActions.pickGallery();
    if (file == null || !mounted) return;
    if (file.size > 25 * 1024 * 1024) {
      _notice('Files must be 25 MB or smaller.');
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
      _notice('Files must be 25 MB or smaller.');
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
    final text = draft.text.trim();
    if ((text.isEmpty && attachment == null) || sending) return;
    setState(() => sending = true);
    try {
      Map<String, dynamic>? uploaded;
      final file = attachment;
      if (file != null)
        uploaded = await api.uploadMessageAttachment(
          conversationId: widget.conversationId,
          bytes: file.bytes!,
          filename: file.name,
        );
      final payload = <String, dynamic>{
        'text': text,
        if (uploaded != null) ...{
          'attachment_url': uploaded['url'] ?? '',
          'attachment_key': uploaded['key'] ?? '',
          'attachment_name': uploaded['name'] ?? file?.name ?? '',
          'attachment_type': uploaded['type'] ?? 'file',
          'attachment_size': uploaded['size'] ?? file?.size ?? 0,
          'attachment_content_type': uploaded['content_type'] ?? '',
        },
      };
      await api.sendMessage(widget.conversationId, payload);
      draft.clear();
      if (mounted) setState(() => attachment = null);
      await _load();
    } catch (e) {
      _notice('$e');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _notice(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final participants = conversation['participants'] is List
        ? conversation['participants'] as List
        : const [];
    final other =
        participants
            .where(
              (p) =>
                  p is Map &&
                  currentUserId != null &&
                  '${p['id']}' != '$currentUserId',
            )
            .cast<dynamic>()
            .firstOrNull ??
        (participants.isNotEmpty ? participants.first : <String, dynamic>{});
    final otherMap = other is Map ? other : <String, dynamic>{};
    final online =
        presence['${otherMap['id']}'] ?? otherMap['is_online'] == true;
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: otherMap['id'] == null
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChatContactProfileScreen(userId: otherMap['id']),
                        ),
                      ),
                child: CircleAvatar(
                  backgroundColor: const Color(0xFFFFE8E0),
                  backgroundImage:
                      api
                          .resolveImageUrl(otherMap['avatar_url'] as String?)
                          .isEmpty
                      ? null
                      : NetworkImage(
                          api.resolveImageUrl(
                            otherMap['avatar_url'] as String?,
                          ),
                        ),
                  child: '${otherMap['avatar_url'] ?? ''}'.isEmpty
                      ? Text(
                          '${other is Map ? other['initials'] ?? '?' : '?'}',
                          style: const TextStyle(
                            color: messageOrange,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${other is Map ? other['name'] ?? other['email'] ?? 'Conversation' : 'Conversation'}',
                      style: const TextStyle(
                        color: messageNavy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if ('${otherMap['username'] ?? ''}'.trim().isNotEmpty)
                      Text(
                        '@${otherMap['username']}',
                        style: const TextStyle(
                          color: messageMuted,
                          fontSize: 11,
                        ),
                      ),
                    Text(
                      online ? 'Online' : _lastSeen(otherMap),
                      style: TextStyle(
                        color: online ? Colors.green.shade700 : messageMuted,
                        fontSize: 11,
                      ),
                    ),
                    if ('${conversation['task_title'] ?? ''}'.isNotEmpty)
                      Text(
                        '${conversation['task_title']}',
                        style: const TextStyle(
                          color: messageMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: messageOrange),
                )
              : messages.isEmpty
              ? const Center(
                  child: Text(
                    'No messages yet. Say hello.',
                    style: TextStyle(color: messageMuted),
                  ),
                )
              : ListView.builder(
                  reverse: false,
                  padding: const EdgeInsets.all(14),
                  itemCount: messages.length,
                  itemBuilder: (_, i) => _bubble(messages[i]),
                ),
        ),
        if (attachment != null)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.attach_file, color: messageOrange),
                Expanded(
                  child: Text(
                    attachment!.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: sending
                      ? null
                      : () => setState(() => attachment = null),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 7, 10, 10),
            child: Row(
              children: [
                IconButton(
                  onPressed: sending ? null : _pick,
                  icon: const Icon(Icons.attach_file, color: messageOrange),
                ),
                Expanded(
                  child: TextField(
                    controller: draft,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.newline,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                IconButton(
                  onPressed: sending ? null : _send,
                  icon: Icon(
                    Icons.send,
                    color: sending ? messageMuted : messageOrange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _bubble(dynamic raw) {
    final m = raw is Map ? raw : <String, dynamic>{};
    final mine =
        currentUserId != null &&
        '${m['sender'] ?? m['sender_id']}' == '$currentUserId';
    final text = '${m['text'] ?? ''}';
    final attachmentUrl = '${m['attachment_url'] ?? ''}';
    final attachmentName = '${m['attachment_name'] ?? ''}';
    final read =
        m['read_at'] != null ||
        m['is_read'] == true ||
        '${m['status']}'.toLowerCase() == 'read';
    final delivered =
        read ||
        m['delivered_at'] != null ||
        m['is_delivered'] == true ||
        '${m['status']}'.toLowerCase() == 'delivered';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: mine ? const Color(0xFFFFE0D6) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (text.isNotEmpty)
              Text(
                text,
                style: const TextStyle(color: messageNavy, height: 1.35),
              ),
            if (attachmentUrl.isNotEmpty) ...[
              if ([
                'jpg',
                'jpeg',
                'png',
                'gif',
                'webp',
              ].any((e) => attachmentName.toLowerCase().endsWith('.$e')))
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Image.network(
                    api.resolveImageUrl(attachmentUrl),
                    height: 150,
                    width: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.broken_image_outlined),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 7),
                  child: Text(
                    attachmentName.isEmpty ? 'Attachment' : attachmentName,
                    style: const TextStyle(
                      color: messageOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _time(m['created_at']),
                  style: const TextStyle(color: messageMuted, fontSize: 10),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    delivered ? Icons.done_all : Icons.done,
                    size: 13,
                    color: read ? messageOrange : messageMuted,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _time(dynamic value) {
    final date = DateTime.tryParse('$value');
    return date == null
        ? ''
        : '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _lastSeen(Map other) =>
      '${other['last_seen_display'] ?? other['last_seen_at'] ?? other['last_seen'] ?? 'Offline'}';
}
