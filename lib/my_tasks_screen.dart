import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'browse_tasks_screen.dart';
import 'received_bids_screen.dart';
import 'task_feed_screen.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  String _activeTab = 'Active';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).syncTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final isClient = appState.currentRole == 'Client';
        final tasks = isClient ? appState.clientTasks : appState.openMarketplaceTasks;
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
          ),
          body: Column(
            children: [
              if (isClient) _buildTabBar(),
              Expanded(
                child: _activeTab == 'Saved' && isClient
                    ? (savedServices.isEmpty ? _buildSavedEmptyState() : _buildSavedServicesList(savedServices))
                    : (tasks.isEmpty ? _buildEmptyState() : _buildTasksList(tasks, isClient)),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No active tasks yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TaskFeedScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001F3F),
              foregroundColor: Colors.white,
            ),
            child: const Text('Browse Open Tasks'),
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
                MaterialPageRoute(builder: (context) => const TaskFeedScreen()),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(4)),
                child: Text(task.status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E8E3E))),
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
              if (isClient)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ReceivedBidsScreen(taskId: task.id)),
                      );
                    },
                    child: const Text('Manage Task'),
                  ),
                )
              else
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
                        builder: (context) => isClient
                            ? ReceivedBidsScreen(taskId: task.id)
                            : BrowseTasksScreen(taskId: task.id),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), foregroundColor: Colors.white),
                  child: Text(isClient ? 'View Bids' : 'Open Task'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
