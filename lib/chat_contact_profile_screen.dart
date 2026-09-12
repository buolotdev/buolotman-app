import 'package:flutter/material.dart';

import 'core/api_service.dart';

class ChatContactProfileScreen extends StatefulWidget {
  const ChatContactProfileScreen({super.key, required this.userId});

  final dynamic userId;

  @override
  State<ChatContactProfileScreen> createState() => _ChatContactProfileState();
}

class _ChatContactProfileState extends State<ChatContactProfileScreen> {
  static const navy = Color(0xFF001F3F), orange = Color(0xFFFF4500);
  final api = ApiService();
  late Future<dynamic> future = api.publicUserProfile(widget.userId);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F7FA),
    appBar: AppBar(
      title: const Text('Profile'),
      foregroundColor: navy,
      backgroundColor: Colors.white,
    ),
    body: FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator(color: orange));
        }
        if (snapshot.hasError || snapshot.data is! Map) {
          return const Center(child: Text('Unable to load this profile.'));
        }
        final p = snapshot.data as Map;
        final name =
            '${p['name'] ?? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'}'
                .trim();
        final username = '${p['username'] ?? ''}'.trim();
        final role = '${p['role'] ?? p['user_type'] ?? 'Member'}'.trim();
        final avatar = api.resolveImageUrl(p['avatar_url'] as String?);
        final banner = api.resolveImageUrl(
          (p['banner_url'] ?? p['cover_url']) as String?,
        );
        return ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 170,
              width: double.infinity,
              child: banner.isEmpty
                  ? Container(color: navy)
                  : Image.network(banner, fit: BoxFit.cover),
            ),
            Transform.translate(
              offset: const Offset(0, -46),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 52,
                    backgroundColor: const Color(0xFFFFE8E0),
                    backgroundImage: avatar.isEmpty
                        ? null
                        : NetworkImage(avatar),
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, color: orange, size: 52)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name.isEmpty ? 'Member' : name,
                    style: const TextStyle(
                      color: navy,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (username.isNotEmpty)
                    Text(
                      '@$username',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  Text(role, style: const TextStyle(color: Colors.black54)),
                  if ('${p['city'] ?? ''}'.trim().isNotEmpty)
                    Text(
                      '${p['city']}, ${p['country'] ?? ''}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  const SizedBox(height: 18),
                  if ('${p['about'] ?? ''}'.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Text(
                        '${p['about']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black87,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}
