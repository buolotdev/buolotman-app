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
    final appState = Get.find<AppState>();
    final isClient = appState.currentRole == 'Client';
    final hasNoData = appState.tasks.isEmpty && (!isClient || appState.clientContracts.isEmpty);
    if (hasNoData) {
      _isLoading = true;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await AppStateScope.of(context).syncTasks();
        if (AppStateScope.of(context).currentRole == 'Client') {
          await AppStateScope.of(context).syncClientContracts();
        }
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
        final isCompany = appState.currentRole == 'Company';
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
                    await AppStateScope.of(context).syncAll();
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
              if (isClient) _buildTabBar(showSaved: true, showContracts: true),
              if (!isClient) _buildTabBar(showSaved: false, showContracts: false),
              Expanded(
                child: _activeTab == 'Saved' && isClient
                    ? (savedServices.isEmpty ? _buildSavedEmptyState() : _buildSavedServicesList(savedServices))
                    : _activeTab == 'Contracts' && isClient
                        ? (appState.clientContracts.isEmpty ? _buildEmptyContractsState() : _buildClientContractsList(appState.clientContracts, context, appState))
                        : (tasks.isEmpty ? _buildEmptyState(isClient, isCompany) : _buildTasksList(tasks, isClient, isCompany)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabBar({bool showSaved = true, bool showContracts = false}) {
    List<String> tabs = ['Active', 'Completed'];
    if (showContracts) tabs.add('Contracts');
    if (showSaved) tabs.add('Saved');
    return Container(
      color: Colors.white,
      child: Row(
        children: tabs.map(_buildTabItem).toList(),
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

  Widget _buildEmptyState(bool isClient, [bool isCompany = false]) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isCompany ? Icons.business_center_outlined : Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            isClient
                ? 'You haven\'t posted any tasks yet'
                : isCompany
                    ? 'No active contracts yet. Browse tasks to bid.'
                    : 'No active projects assigned yet',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 16),
          ),
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

  Widget _buildTasksList(List<dynamic> tasks, bool isClient, [bool isCompany = false]) {
    final visibleTasks = tasks.where((task) {
      if (isClient && task.status == 'Deleted') {
        return false;
      }
      if (_activeTab == 'Completed') {
        return task.status == 'Completed' || task.status == 'Cancelled' || task.status == 'Deleted';
      }
      if (_activeTab == 'Saved') {
        return false;
      }
      return task.status != 'Completed' && task.status != 'Cancelled' && task.status != 'Deleted';
    }).toList();

    if (visibleTasks.isEmpty) {
      return _buildFilteredEmptyState(isClient, isCompany);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: visibleTasks.length,
      itemBuilder: (context, index) => _buildTaskCard(visibleTasks[index], isClient, isCompany),
    );
  }

  Widget _buildFilteredEmptyState(bool isClient, [bool isCompany = false]) {
    final message = _activeTab == 'Saved'
        ? 'Saved services and professionals will show up here.'
        : _activeTab == 'Completed'
            ? 'Completed tasks will appear here once they are finished.'
            : isClient
                ? 'No active tasks yet.'
                : isCompany
                    ? 'No active contracts yet. Bid on tasks to get started.'
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
          if (!isClient && _activeTab == 'Active')
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const TaskFeedScreen()),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), foregroundColor: Colors.white),
              child: const Text('Browse Open Tasks'),
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

  Widget _buildTaskCard(dynamic task, bool isClient, [bool isCompany = false]) {
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
          const SizedBox(height: 8),
          // Company: show milestone progress if in progress
          if (isCompany && (task.status == 'In Progress' || task.status == 'Delivered')) ...[
            _buildMilestoneProgressBar(task),
            const SizedBox(height: 8),
          ],
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
                                    builder: (c) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500)))),
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
                ] else if (task.status == 'Completed') ...[
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
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Delete Task',
                    onPressed: () => _showDeleteConfirmationDialog(context, task.id),
                  ),
                ],
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

  Widget _buildMilestoneProgressBar(dynamic task) {
    if (task.milestones == null || task.milestones!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final milestones = List<Map<String, dynamic>>.from(task.milestones!);
    final total = milestones.length;
    final completed = milestones.where((m) => m['status'] == 'completed').length;
    final progress = total > 0 ? (completed / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Milestones: $completed / $total', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(task.status == 'Delivered' ? const Color(0xFF16A34A) : const Color(0xFF2563EB)),
          ),
        ),
      ],
    );
  }
  void _showDeleteConfirmationDialog(BuildContext context, String taskId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Task', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
        content: const Text('Are you sure you want to delete this task? This action will cancel any active contracts, release/refund escrow funds, and notify the assigned technician.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (c) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500)))),
              );
              try {
                await AppStateScope.of(context).deleteTask(taskId);
                if (context.mounted) {
                  Navigator.pop(context); // dismiss spinner
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task deleted successfully.'), backgroundColor: Color(0xFF1E8E3E)));
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // dismiss spinner
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete task: $e'), backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB91C1C), foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContractsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.assignment_turned_in_outlined, size: 40, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 16),
          const Text('No contracts yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 6),
          const Text('Contracts sent by companies will appear here.', style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildClientContractsList(List<Map<String, dynamic>> contracts, BuildContext context, AppState appState) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: contracts.length,
      itemBuilder: (context, index) {
        final contract = contracts[index];
        final progress = (contract['progress'] ?? 0) as num;
        final status = contract['status'] ?? 'active';
        final paymentStatus = contract['payment_status'] ?? 'awaiting';
        
        final double budget = double.tryParse(contract['budget']?.toString() ?? '0') ?? 0.0;
        final int milestonesCompleted = int.tryParse(contract['milestones_completed']?.toString() ?? '0') ?? 0;
        final int milestonesTotal = int.tryParse(contract['milestones_total']?.toString() ?? '0') ?? 0;
        final int milestonesReleased = int.tryParse(contract['milestones_released']?.toString() ?? '0') ?? 0;
        final double milestoneAmount = milestonesTotal > 0 ? budget / milestonesTotal : budget;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(contract['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: paymentStatus == 'released' ? Colors.green.shade100 : Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                      child: Text(paymentStatus.toString().toUpperCase(), style: TextStyle(color: paymentStatus == 'released' ? Colors.green.shade700 : Colors.orange.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('\$${contract['budget']}', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Text('${contract['timeline']}', style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Progress: ${progress.toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(progress == 100 ? Colors.green : const Color(0xFFFF4500)),
                ),
                const SizedBox(height: 16),
                if (paymentStatus == 'in_escrow' && milestonesCompleted > milestonesReleased)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await appState.releaseContractEscrow(contract['id'].toString());
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escrow released!')));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: Text('Approve & Release Milestone (\$${milestoneAmount.toStringAsFixed(2)})'),
                    ),
                  )
                else if (paymentStatus == 'awaiting')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        await appState.fundContractEscrow(contract['id'].toString());
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funds secured in escrow!')));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: Text('Fund Escrow (\$${milestoneAmount.toStringAsFixed(2)})'),
                    ),
                  )
                else if (paymentStatus == 'in_escrow')
                  const Center(child: Text('Funds in Escrow - Awaiting Completion', style: TextStyle(color: Color(0xFF64748B))))
                else if (paymentStatus == 'released')
                  const Center(child: Text('Escrow Released', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)))
                else
                  const Center(child: Text('Awaiting Company Completion', style: TextStyle(color: Color(0xFF64748B)))),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Message Company'),
                    onPressed: () {
                      final companyName = contract['company_name']?.toString() ?? 'Company';
                      final title = contract['title']?.toString() ?? '';
                      final existingThreadId = appState.threads
                          .where((t) => t.name == companyName)
                          .map((t) => t.id)
                          .firstOrNull;
                      if (existingThreadId == null) {
                        appState.createOrOpenThread(
                          otherPartyName: companyName,
                          otherPartyImage: '',
                          initialMessage: 'Hi $companyName, let\'s chat about contract: "$title".',
                        );
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            name: companyName,
                            image: '',
                            threadId: existingThreadId,
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF001F3F),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
