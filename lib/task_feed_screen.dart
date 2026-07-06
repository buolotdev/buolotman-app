import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'browse_tasks_screen.dart';
import 'notifications_screen.dart';
import 'messages_screen.dart';

class TaskFeedScreen extends StatefulWidget {
  const TaskFeedScreen({super.key});

  @override
  State<TaskFeedScreen> createState() => _TaskFeedScreenState();
}

class _TaskFeedScreenState extends State<TaskFeedScreen> {
  String _activeCategory = 'All Tasks';
  String _searchQuery = '';
  String _budgetFilter = 'Any';
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openFilterSheet() {
    String tempBudget = _budgetFilter;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Budget Range', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: ['Any', 'Under \$50', '\$50–\$200', '\$200–\$500', '\$500+'].map((opt) {
                      final selected = tempBudget == opt;
                      return GestureDetector(
                        onTap: () => setModal(() => tempBudget = opt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFFF4500) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(opt, style: TextStyle(color: selected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _budgetFilter = tempBudget);
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4500),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
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

        final bottomPadding = MediaQuery.of(context).padding.bottom + 120;
        final tasks = appState.openMarketplaceTasks.where((task) {
          // Category filter
          if (_activeCategory != 'All Tasks' && task.category != _activeCategory) return false;

          // Search filter
          if (_searchQuery.isNotEmpty) {
            final q = _searchQuery.toLowerCase();
            if (!task.title.toLowerCase().contains(q) &&
                !task.category.toLowerCase().contains(q) &&
                !task.location.toLowerCase().contains(q)) {
              return false;
            }
          }

          // Budget filter
          if (_budgetFilter != 'Any') {
            final b = task.budget;
            if (_budgetFilter == 'Under \$50' && b >= 50) return false;
            if (_budgetFilter == '\$50–\$200' && (b < 50 || b > 200)) return false;
            if (_budgetFilter == '\$200–\$500' && (b < 200 || b > 500)) return false;
            if (_budgetFilter == '\$500+' && b < 500) return false;
          }

          return true;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildSearchAndFilters(),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              const Text('No tasks match your filters', style: TextStyle(fontSize: 16, color: Color(0xFF64748B))),
                            ],
                          ),
                        )
                      : ListView.builder(
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
                Text('Technician Feed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                SizedBox(height: 2),
                Text('Browse live work near you', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
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
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF001F3F)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MessagesScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF001F3F)),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: Color(0xFF001F3F)),
                onPressed: _openFilterSheet,
              ),
              if (_budgetFilter != 'Any')
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Color(0xFFFF4500), shape: BoxShape.circle),
                  ),
                ),
            ],
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
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: Color(0xFF64748B), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v.trim()),
                    decoration: const InputDecoration(
                      hintText: 'Search tasks...',
                      hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Icon(Icons.close, color: Color(0xFF64748B), size: 16),
                  ),
              ],
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
                _buildFilterChip('Cleaning'),
                _buildFilterChip('Moving'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(String taskId) {
    final task = AppStateScope.of(context).findTask(taskId);
    if (task == null) return const SizedBox.shrink();
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
                      color: task.urgency == 'Urgent' ? const Color(0xFFB91C1C) : const Color(0xFF64748B),
                    ),
                  ),
                ),
                Text(task.createdLabel, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 12),
            Text(task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
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
                      child: buildAvatarImage(task.clientAvatar, width: 30, height: 30, fit: BoxFit.cover),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF4500)),
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
