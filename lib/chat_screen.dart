import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  String? _attachedFileName;
  dynamic _attachedFileBytes; // Uint8List or dynamic
  String? _attachedFileBase64;

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
    final text = message.text as String;

    // System notification messages (start with '⚙️' or 'System:')
    final isSystem = text.startsWith('⚙️') ||
        text.startsWith('System:') ||
        text.startsWith('[System]');
    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            text.replaceAll('⚙️ ', '').replaceAll('System: ', '').replaceAll('[System] ', ''),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // File attachment messages
    final isFile = text.startsWith('[File]');
    final hasAttachment = message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty;
    if (isFile || hasAttachment) {
      final fileName = hasAttachment ? (message.attachmentName ?? 'file') : text.replaceFirst('[File] ', '');
      final fileUrl = hasAttachment ? message.attachmentUrl! : '';
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: InkWell(
          onTap: () => _openAttachment(context, fileName, fileUrl),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMe ? const Color(0xFF001F3F) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.15)
                        : const Color(0xFFFF4500).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.insert_drive_file_outlined,
                      color: isMe ? Colors.white : const Color(0xFFFF4500), size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white : const Color(0xFF001F3F),
                      ),
                    ),
                    Text('Attachment',
                        style: TextStyle(
                            fontSize: 11,
                            color: isMe ? Colors.white60 : const Color(0xFF94A3B8))),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

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
              text,
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

  void _openAttachment(BuildContext context, String fileName, String fileUrl) {
    final isImage = fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.gif') ||
        fileUrl.startsWith('data:image/');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Attachment Preview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001F3F),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 250,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Center(
                    child: fileUrl.isEmpty
                        ? Icon(
                            isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                            size: 64,
                            color: const Color(0xFFFF4500),
                          )
                        : (isImage
                            ? (fileUrl.startsWith('data:')
                                ? Image.memory(
                                    base64Decode(fileUrl.split(',').last),
                                    fit: BoxFit.contain,
                                  )
                                : Image.network(
                                    fileUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => const Icon(
                                      Icons.broken_image_outlined,
                                      size: 64,
                                      color: Color(0xFFFF4500),
                                    ),
                                  ))
                            : Icon(
                                isImage ? Icons.image_outlined : Icons.insert_drive_file_outlined,
                                size: 64,
                                color: const Color(0xFFFF4500),
                              )),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                fileName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF001F3F),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: const Text('Close', style: TextStyle(color: Color(0xFF64748B))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final downloadUrl = fileUrl.isNotEmpty
                            ? fileUrl
                            : 'data:text/plain;charset=utf-8,Simulated attachment download for file: $fileName';

                        if (kIsWeb) {
                          // Standard, foolproof way to download files in browser on Flutter Web
                          final anchor = html.AnchorElement(href: downloadUrl)
                            ..setAttribute("download", fileName)
                            ..style.display = 'none';
                          html.document.body?.children.add(anchor);
                          anchor.click();
                          anchor.remove();
                        } else {
                          if (downloadUrl.startsWith('data:')) {
                            try {
                              final parts = downloadUrl.split(',');
                              if (parts.length > 1) {
                                final bytes = base64Decode(parts.last);
                                final tempDir = await getTemporaryDirectory();
                                final file = File('${tempDir.path}/$fileName');
                                await file.writeAsBytes(bytes);
                                await Share.shareXFiles([XFile(file.path)], text: fileName);
                              }
                            } catch (e) {
                              debugPrint('Failed to save/share base64 file: $e');
                            }
                          } else {
                            final uri = Uri.parse(downloadUrl);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4500),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Download', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(String threadId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Attached file preview
          if (_attachedFileName != null)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insert_drive_file_outlined,
                      size: 16, color: Color(0xFF0284C7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _attachedFileName!,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0284C7)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _attachedFileName = null),
                    child: const Icon(Icons.close,
                        size: 16, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          Row(
            children: [
              // Attach button
              GestureDetector(
                onTap: () => _showAttachOptions(threadId),
                child: Container(
                  width: 40,
                  height: 40,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Icon(Icons.attach_file,
                      color: Color(0xFF64748B), size: 20),
                ),
              ),
              // Text field
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
              const SizedBox(width: 8),
              // Send button
              _isSending
                  ? const SizedBox(
                      width: 40,
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
                        ),
                      ),
                    )
                  : GestureDetector(
                      onTap: () => _sendMessage(threadId),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                            color: Color(0xFFFF4500), shape: BoxShape.circle),
                        child: const Icon(Icons.send, color: Colors.white, size: 18),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage(String threadId) async {
    String text = _controller.text.trim();
    final hasAttachment = _attachedFileName != null;

    if (text.isEmpty && !hasAttachment) return;

    _controller.clear();
    final attachName = _attachedFileName;
    final attachBase64 = _attachedFileBase64;
    setState(() {
      _isSending = true;
      _attachedFileName = null;
      _attachedFileBytes = null;
      _attachedFileBase64 = null;
    });

    try {
      String currentThreadId = threadId;

      if (hasAttachment) {
        // Send the file attachment and text together (or text as placeholder if empty)
        final finalMsg = text.isNotEmpty ? text : '[File] $attachName';
        if (currentThreadId == 'temp') {
          final newId = await AppStateScope.of(context).createOrOpenThread(
            otherPartyName: widget.name,
            otherPartyImage: widget.image,
            initialMessage: finalMsg,
            attachmentUrl: attachBase64,
            attachmentName: attachName,
          );
          if (newId != null) currentThreadId = newId;
        } else {
          await AppStateScope.of(context).sendMessage(
            currentThreadId,
            finalMsg,
            attachmentUrl: attachBase64,
            attachmentName: attachName,
          );
        }
      } else {
        // Normal text message
        if (currentThreadId == 'temp') {
          await AppStateScope.of(context).createOrOpenThread(
            otherPartyName: widget.name,
            otherPartyImage: widget.image,
            initialMessage: text,
          );
        } else {
          await AppStateScope.of(context).sendMessage(currentThreadId, text);
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showAttachOptions(String threadId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share a File',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001F3F))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _attachOption(Icons.image_outlined, 'Photo', 'image.jpg', threadId),
                _attachOption(Icons.picture_as_pdf_outlined, 'Document', 'document.pdf', threadId),
                _attachOption(Icons.video_file_outlined, 'Video', 'video.mp4', threadId),
                _attachOption(Icons.folder_outlined, 'Files', 'file.zip', threadId),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _attachOption(IconData icon, String label, String mockFile, String threadId) {
    return GestureDetector(
      onTap: () async {
        try {
          final ImagePicker picker = ImagePicker();
          if (label == 'Photo') {
            final XFile? image = await picker.pickImage(source: ImageSource.gallery);
            Navigator.pop(context);
            if (image != null) {
              final bytes = await image.readAsBytes();
              final ext = image.name.split('.').last;
              final b64 = base64Encode(bytes);
              setState(() {
                _attachedFileName = image.name;
                _attachedFileBytes = bytes;
                _attachedFileBase64 = 'data:image/$ext;base64,$b64';
              });
            }
          } else if (label == 'Video') {
            final XFile? video = await picker.pickVideo(source: ImageSource.gallery);
            Navigator.pop(context);
            if (video != null) {
              final bytes = await video.readAsBytes();
              final ext = video.name.split('.').last;
              final b64 = base64Encode(bytes);
              setState(() {
                _attachedFileName = video.name;
                _attachedFileBytes = bytes;
                _attachedFileBase64 = 'data:video/$ext;base64,$b64';
              });
            }
          } else {
            fp.FilePickerResult? result = await fp.FilePicker.pickFiles(
              withData: true,
            );
            Navigator.pop(context);
            if (result != null && result.files.isNotEmpty) {
              final file = result.files.single;
              final bytes = file.bytes;
              if (bytes != null) {
                final ext = file.extension ?? 'png';
                final b64 = base64Encode(bytes);
                setState(() {
                  _attachedFileName = file.name;
                  _attachedFileBytes = bytes;
                  _attachedFileBase64 = 'data:application/$ext;base64,$b64';
                });
              }
            }
          }
        } catch (e) {
          Navigator.pop(context);
          debugPrint('Error picking file: $e');
        }
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: const Color(0xFFFF4500), size: 26),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
