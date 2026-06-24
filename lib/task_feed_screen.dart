import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'browse_tasks_screen.dart';
import 'notifications_screen.dart';
import 'search_screen.dart';

class TaskFeedScreen extends StatefulWidget {
  const TaskFeedScreen({super.key});

  @override
  State<TaskFeedScreen> createState() => _TaskFeedScreenState();
}

class _TaskFeedScreenState extends State<TaskFeedScreen> {
  String _activeCategory = 'All Tasks';

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
        final bottomPadding = MediaQuery.of(context).padding.bottom + 120;
        final tasks = appState.openMarketplaceTasks.where((task) {
          if (_activeCategory == 'All Tasks') {
            return true;
          }
          return task.category == _activeCategory;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildSearchAndFilters(),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) => _buildTaskCard(tasks[index].id),
                ),
              ),
            ],
          ),
         ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset('assets/images/boulotman-logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Technician Feed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
                ),
                SizedBox(height: 2),
                Text(
                  'Browse live work near you',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF001F3F)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Color(0xFF001F3F)),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'Search tasks...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: Color(0xFF64748B)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Tasks'),
                _buildFilterChip('Electrical'),
                _buildFilterChip('Plumbing'),
                _buildFilterChip('Handyman'),
                _buildFilterChip('Tech'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String taskId) {
    final task = AppStateScope.of(context).findTask(taskId)!;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => BrowseTasksScreen(taskId: taskId)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.urgency == 'Urgent'
                        ? const Color(0xFFFEE2E2)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    task.urgency.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: task.urgency == 'Urgent'
                          ? const Color(0xFFB91C1C)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                Text(
                  task.createdLabel,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              task.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F3F),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(task.location, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                const SizedBox(width: 16),
                const Icon(Icons.work_outline, size: 14, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(task.category, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.asset(task.clientAvatar, width: 30, height: 30, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task.clientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Row(
                          children: [
                            const Icon(Icons.star, size: 10, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(task.clientRating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  '\$${task.budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF4500),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _activeCategory == label;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4500) : Colors.white,
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}
