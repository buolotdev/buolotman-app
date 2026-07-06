import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.name, required this.image, this.threadId});

  final String name;
  final String image;
  final String? threadId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _timer;
  bool _isLoading = true;
  bool _isSending = false;
  String? _activeThreadId;

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _activeThreadId = widget.threadId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMessages();
      _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
        _fetchMessages();
      });
    });
  }

  Future<void> _fetchMessages() async {
    if (!mounted) return;
    final appState = AppStateScope.of(context);
    String? threadId = _activeThreadId ?? widget.threadId;
    if (threadId == null) {
      for (final item in appState.threads) {
        if (item.name.toLowerCase() == widget.name.toLowerCase()) {
          threadId = item.id;
          _activeThreadId = item.id;
          break;
        }
      }
    }
    if (threadId != null && threadId != 'temp') {
      await appState.syncThreadMessages(threadId);
    } else {
      await appState.syncConversations();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        ChatThread? foundThread;
        String? activeId = _activeThreadId ?? widget.threadId;
        if (activeId != null) {
          for (final item in appState.threads) {
            if (item.id == activeId) {
              foundThread = item;
              break;
            }
          }
        }
        if (foundThread == null) {
          for (final item in appState.threads) {
            if (item.name.toLowerCase() == widget.name.toLowerCase()) {
              foundThread = item;
              _activeThreadId = item.id;
              break;
            }
          }
        }

        final thread = foundThread ?? ChatThread(
          id: 'temp',
          name: widget.name,
          image: widget.image,
          online: true,
          messages: const [],
        );

        final List<ChatMessage> messages = thread.id != 'temp'
            ? appState.getMessagesForThread(thread.id)
            : <ChatMessage>[];

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: buildAvatarImage(widget.image, width: 32, height: 32, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)), overflow: TextOverflow.ellipsis),
                      Text(
                        thread.online ? 'Online' : thread.lastSeen,
                        style: TextStyle(
                          fontSize: 11,
                          color: thread.online ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => _buildMessageBubble(messages[index]),
                      ),
              ),
              _buildMessageInput(thread.id),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageBubble(dynamic message) {
    final isMe = message.isMe as bool;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF001F3F) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : const Color(0xFF001F3F), fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 4),
            Text(
              message.time,
              style: TextStyle(color: isMe ? Colors.white70 : const Color(0xFF64748B), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(String threadId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _isSending
              ? const SizedBox(
                  width: 40,
                  height: 40,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
                    ),
                  ),
                )
              : GestureDetector(
                  onTap: () async {
                    final text = _controller.text.trim();
                    if (text.isEmpty) return;
                    _controller.clear();
                    setState(() {
                      _isSending = true;
                    });
                    try {
                      if (threadId == 'temp') {
                        await AppStateScope.of(context).createOrOpenThread(
                          otherPartyName: widget.name,
                          otherPartyImage: widget.image,
                          initialMessage: text,
                        );
                      } else {
                        await AppStateScope.of(context).sendMessage(threadId, text);
                      }
                    } catch (e) {
                      debugPrint('Error sending message: $e');
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSending = false;
                        });
                      }
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(color: Color(0xFFFF4500), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 18),
                  ),
                ),
        ],
      ),
    );
  }
}
