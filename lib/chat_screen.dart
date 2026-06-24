import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.name, required this.image});

  final String name;
  final String image;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).syncConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final thread = appState.threads.firstWhere((item) => item.name == widget.name);
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
                      Text(thread.online ? 'Online' : 'Offline', style: TextStyle(fontSize: 11, color: thread.online ? const Color(0xFF16A34A) : const Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: thread.messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(thread.messages[index]),
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
          GestureDetector(
            onTap: () {
              AppStateScope.of(context).sendMessage(threadId, _controller.text);
              _controller.clear();
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
