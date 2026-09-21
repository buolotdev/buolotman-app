import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'core/api_service.dart';
import 'app_state.dart';
import 'technician_public_profile_screen.dart';

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
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(
          appBar: _ProfileAppBar(),
          body: Center(child: CircularProgressIndicator(color: orange)),
        );
      }
      if (snapshot.hasError || snapshot.data is! Map) {
        return const Scaffold(
          appBar: _ProfileAppBar(),
          body: Center(child: Text('Unable to load this profile.')),
        );
      }
      final rawProfile = Map<String, dynamic>.from(snapshot.data as Map);
      final nestedUser = rawProfile['user'] is Map
          ? Map<String, dynamic>.from(rawProfile['user'] as Map)
          : const <String, dynamic>{};
      final p = <String, dynamic>{...rawProfile, ...nestedUser};
      final name =
          '${p['name'] ?? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'}'
              .trim();
      final username = '${p['username'] ?? ''}'.trim();
      final role =
          '${p['role'] ?? p['user_type'] ?? p['account_type'] ?? p['user_role'] ?? p['type'] ?? 'Member'}'
              .trim();
      final avatar = api.resolveImageUrl(p['avatar_url'] as String?);
      final normalizedRole = role.toLowerCase();

      // Technicians already have a complete public-profile experience with
      // tabs for services, portfolio, reviews, availability and rates.
      // Chat used to open only this generic contact summary, which hid all
      // of those fields.
      if (normalizedRole.contains('technician') || normalizedRole == 'tech') {
        if (!Get.isRegistered<AppState>()) {
          Get.put(AppState());
        }
        final displaySkill =
            (p['primary_occupation'] ??
                    p['professional_title'] ??
                    p['specialization'] ??
                    p['trade'] ??
                    'Technician')
                .toString();
        final displayPrice =
            (p['hourly_rate'] ?? p['starting_price'] ?? p['price'] ?? '')
                .toString();
        final displayRating = (p['average_rating'] ?? p['rating'] ?? '0')
            .toString();
        return TechnicianPublicProfileScreen(
          name: name.isEmpty ? 'Technician' : name,
          skill: displaySkill,
          avatar: avatar,
          price: displayPrice,
          rating: displayRating,
          rawData: p,
        );
      }
      final banner = api.resolveImageUrl(
        (p['banner_url'] ?? p['cover_url']) as String?,
      );
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: const _ProfileAppBar(),
        body: ListView(
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
                      fontWeight: FontWeight.w600,
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
        ),
      );
    },
  );
}

class _ProfileAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ProfileAppBar();

  @override
  Widget build(BuildContext context) => AppBar(
    title: const Text('Profile'),
    foregroundColor: _ChatContactProfileState.navy,
    backgroundColor: Colors.white,
  );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
