import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final role = appState.currentRole;
        final items = _itemsForRole(appState, role);

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: const Text(
              'Notifications',
              style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w700),
            ),
            centerTitle: true,
          ),
          body: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: item['color'] as Color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item['icon'] as IconData, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title'] as String,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['subtitle'] as String,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['time'] as String,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  List<Map<String, Object>> _itemsForRole(AppState appState, String role) {
    final firstTask = appState.openMarketplaceTasks.isNotEmpty ? appState.openMarketplaceTasks.first : null;
    final unreadMessage = appState.threads.isNotEmpty ? appState.threads.first : null;

    if (role == 'Technician') {
      return [
        {
          'icon': Icons.work_outline,
          'color': const Color(0xFFFF4500),
          'title': 'New task available',
          'subtitle': firstTask == null
              ? 'A new task matching your category will appear here.'
              : '${firstTask.title} is open in ${firstTask.location}.',
          'time': 'Just now',
        },
        {
          'icon': Icons.chat_bubble_outline,
          'color': const Color(0xFF001F3F),
          'title': 'New message',
          'subtitle': unreadMessage == null ? 'No unread conversations.' : 'You have a message from ${unreadMessage.name}.',
          'time': '5 min ago',
        },
      ];
    }

    if (role == 'Company') {
      return [
        {
          'icon': Icons.assignment_turned_in_outlined,
          'color': const Color(0xFF001F3F),
          'title': 'Project update',
          'subtitle': firstTask == null
              ? 'Your project activity will appear here.'
              : '${firstTask.title} has ${firstTask.bidsCount} bids waiting.',
          'time': 'Today',
        },
        {
          'icon': Icons.verified_user_outlined,
          'color': const Color(0xFF1E8E3E),
          'title': 'Verification reminder',
          'subtitle': 'Upload compliance documents to keep your company verified.',
          'time': 'Yesterday',
        },
      ];
    }

    final List<Map<String, Object>> list = [];
    
    if (unreadMessage != null) {
      list.add({
        'icon': Icons.chat_bubble_outline,
        'color': const Color(0xFF001F3F),
        'title': 'New message',
        'subtitle': 'You have an active chat thread with ${unreadMessage.name}.',
        'time': 'Just now',
      });
    }

    for (final task in appState.tasks) {
      if (task.status == 'completed') {
        list.add({
          'icon': Icons.check_circle_outline,
          'color': const Color(0xFF1E8E3E),
          'title': 'Task completed',
          'subtitle': 'Your task "${task.title}" is complete and payment is released.',
          'time': 'Today',
        });
      } else if (task.status == 'in_progress') {
        list.add({
          'icon': Icons.hourglass_top_outlined,
          'color': const Color(0xFFFF5500),
          'title': 'Task in progress',
          'subtitle': 'Work is in progress on "${task.title}".',
          'time': 'Today',
        });
      } else if (task.status == 'open' && task.bidsCount > 0) {
        list.add({
          'icon': Icons.receipt_long_outlined,
          'color': const Color(0xFFFF5500),
          'title': 'Bids received',
          'subtitle': 'Your task "${task.title}" has received ${task.bidsCount} bids.',
          'time': 'Today',
        });
      }
    }

    if (list.isEmpty) {
      list.add({
        'icon': Icons.notifications_none_outlined,
        'color': const Color(0xFF94A3B8),
        'title': 'Welcome to Boulot Man',
        'subtitle': 'Post a task or browse professionals to get started!',
        'time': 'Today',
      });
    }
    return list;
  }
}
