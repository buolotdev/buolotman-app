import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'browse_tasks_screen.dart';
import 'received_bids_screen.dart';
import 'task_feed_screen.dart';
import 'post_task_form_screen.dart';
import 'listing_screen.dart';
import 'edit_task_screen.dart';
import 'chat_screen.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  String _activeTab = 'Active';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _isLoading = true);
      try {
        await AppStateScope.of(context).syncTasks();
      } catch (e) {
        debugPrint('Sync tasks error: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        if (_isLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6F8),
            body: Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500))),
            ),
          );
        }

        final isClient = appState.currentRole == 'Client';
        final tasks = appState.tasks;
        final savedServices = appState.savedServices;

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            title: Text(
              isClient ? 'My Tasks' : 'Projects & Contracts',
              style: const TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF001F3F)),
                onPressed: () async {
                  setState(() => _isLoading = true);
                  try {
                    await AppStateScope.of(context).syncTasks();
                  } catch (e) {
                    debugPrint('Refresh tasks error: $e');
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (isClient) _buildTabBar(),
              Expanded(
                child: _activeTab == 'Saved' && isClient
                    ? (savedServices.isEmpty ? _buildSavedEmptyState() : _buildSavedServicesList(savedServices))
                    : (tasks.isEmpty ? _buildEmptyState(isClient) : _buildTasksList(tasks, isClient)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: Row(
        children: ['Active', 'Completed', 'Saved'].map(_buildTabItem).toList(),
      ),
    );
  }

  Widget _buildTabItem(String title) {
    final bool isActive = _activeTab == title;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isActive ? const Color(0xFFFF4500) : Colors.transparent, width: 2)),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isActive ? const Color(0xFFFF4500) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isClient) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(isClient ? 'You haven\'t posted any tasks yet' : 'No active projects assigned yet', style: const TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => isClient ? const PostTaskFormScreen() : const TaskFeedScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001F3F),
              foregroundColor: Colors.white,
            ),
            child: Text(isClient ? 'Post a New Task' : 'Browse Open Tasks'),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksList(List<dynamic> tasks, bool isClient) {
    final visibleTasks = tasks.where((task) {
      if (_activeTab == 'Completed') {
        return task.status == 'Completed';
      }
      if (_activeTab == 'Saved') {
        return false;
      }
      return task.status != 'Completed';
    }).toList();

    if (visibleTasks.isEmpty) {
      return _buildFilteredEmptyState(isClient);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visibleTasks.length,
      itemBuilder: (context, index) => _buildTaskCard(visibleTasks[index], isClient),
    );
  }

  Widget _buildFilteredEmptyState(bool isClient) {
    final message = _activeTab == 'Saved'
        ? 'Saved services and professionals will show up here.'
        : _activeTab == 'Completed'
            ? 'Completed tasks will appear here once they are finished.'
            : isClient
                ? 'No active tasks yet.'
                : 'No assigned projects yet.';

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 16),
          if (isClient && _activeTab != 'Saved')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PostTaskFormScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), foregroundColor: Colors.white),
              child: const Text('Post a New Task'),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bookmark_border, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(
            'No saved services yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ListingScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), foregroundColor: Colors.white),
            child: const Text('Browse Services'),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedServicesList(List<dynamic> services) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(service.category.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
              const SizedBox(height: 4),
              Text(service.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
              const SizedBox(height: 4),
              Text(service.providerName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Text(
                service.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        AppStateScope.of(context).toggleSavedService(service.id);
                      },
                      child: const Text('Remove Saved'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => const TaskFeedScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), foregroundColor: Colors.white),
                      child: const Text('Open'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(dynamic task, bool isClient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(4)),
                    child: Text(task.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E8E3E))),
                  ),
                  if (task.deadline != null) ...[
                    const SizedBox(width: 8),
                    _buildDeadlineTracker(task.deadline!),
                  ],
                ],
              ),
              Text(task.createdLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 12),
          Text(task.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${task.bidsCount} bids received', style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              Text('\$${task.budget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF4500))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (isClient) ...[
                if (task.status == 'In Progress' || task.status == 'Delivered') ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chat_bubble_outline, size: 16),
                      label: const Text('Message Tech'),
                      onPressed: () {
                        final appState = AppStateScope.of(context);
                        final String otherName = task.assignedToName ?? 'Technician';
                        final String otherAvatar = task.assignedToAvatar ?? 'assets/images/onboard1.jpg';
                        
                        String? existingThreadId;
                        for (final item in appState.threads) {
                          if (item.name.toLowerCase() == otherName.toLowerCase()) {
                            existingThreadId = item.id;
                            break;
                          }
                        }
                        if (existingThreadId == null) {
                          appState.createOrOpenThread(
                            otherPartyName: otherName,
                            otherPartyImage: otherAvatar,
                            initialMessage: 'Hi $otherName, let\'s chat about task: "${task.title}".',
                          );
                        }
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ChatScreen(
                              name: otherName,
                              image: otherAvatar,
                              threadId: existingThreadId,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Complete Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text('Complete Task', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                            content: Text('Are you sure you want to mark this task as completed? This will release the escrow funds (\$${task.budget.toStringAsFixed(0)}) to ${task.assignedToName ?? 'the technician'}.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                              ElevatedButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (c) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF5500)))),
                                  );
                                  try {
                                    await AppStateScope.of(context).completeTask(task.id);
                                    if (context.mounted) {
                                      Navigator.pop(context); // dismiss loader
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task completed successfully! Escrow released.')));
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      Navigator.pop(context); // dismiss loader
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error completing task: $e')));
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5500), foregroundColor: Colors.white),
                                child: const Text('Complete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => EditTaskScreen(task: task)),
                        );
                      },
                      child: const Text('Edit Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ReceivedBidsScreen(taskId: task.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), foregroundColor: Colors.white),
                      child: const Text('View Bids'),
                    ),
                  ),
                ]
              ] else ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => BrowseTasksScreen(taskId: task.id)),
                      );
                    },
                    child: Text(task.status == 'In Progress' ? 'Active Contract' : 'Project Pipeline'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BrowseTasksScreen(taskId: task.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), foregroundColor: Colors.white),
                    child: const Text('Open Task'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeadlineTracker(String deadlineStr) {
    if (deadlineStr.isEmpty) return const SizedBox.shrink();
    final deadline = DateTime.tryParse(deadlineStr);
    if (deadline == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    final difference = deadlineDate.difference(today).inDays;

    if (difference < 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE2E2),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFEF4444)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 10, color: Color(0xFFB91C1C)),
            const SizedBox(width: 3),
            Text(
              'EXCEEDED BY ${difference.abs()} D',
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C)),
            ),
          ],
        ),
      );
    } else if (difference == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFF59E0B)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_filled, size: 10, color: Color(0xFFB45309)),
            SizedBox(width: 3),
            Text(
              'DUE TODAY',
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF0284C7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 8, color: Color(0xFF0369A1)),
            const SizedBox(width: 3),
            Text(
              '$difference D LEFT',
              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
            ),
          ],
        ),
      );
    }
  }
}
