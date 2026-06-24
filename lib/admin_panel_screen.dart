import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).syncAdminData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF001F3F),
            elevation: 0,
            title: const Text(
              "Admin Panel",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF4500),
              unselectedLabelColor: Colors.white70,
              indicatorColor: const Color(0xFFFF4500),
              tabs: const [
                Tab(icon: Icon(Icons.people_outline), text: "Users"),
                Tab(icon: Icon(Icons.assignment_outlined), text: "Tasks"),
                Tab(icon: Icon(Icons.payments_outlined), text: "Finance"),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildUsersTab(appState),
              _buildTasksTab(appState),
              _buildFinanceTab(appState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTab(AppState appState) {
    final users = appState.adminUsersList;
    if (users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final String name = '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim().isNotEmpty
            ? '${user['first_name']} ${user['last_name']}'.trim()
            : (user['username'] ?? 'User');
        final String email = user['email'] ?? 'no-email';
        final String role = user['role'] ?? 'CLIENT';
        final bool isVerified = user['is_verified'] == true;
        final bool isActive = user['is_active'] == true;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001F3F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Color(0xFF64748B))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isVerified ? Icons.verified : Icons.pending_actions,
                      color: isVerified ? const Color(0xFF1E8E3E) : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? "Verified" : "Verification Pending",
                      style: TextStyle(
                        fontSize: 13,
                        color: isVerified ? const Color(0xFF1E8E3E) : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (!isVerified && (role == 'TECHNICIAN' || role == 'COMPANY'))
                      ElevatedButton(
                        onPressed: () => appState.verifyUser(user['id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E8E3E),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text("Verify Pro", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => appState.suspendUser(user['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? const Color(0xFFEF4444) : const Color(0xFF1E8E3E),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      child: Text(
                        isActive ? "Suspend" : "Unsuspend",
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTasksTab(AppState appState) {
    final tasks = appState.adminTasksList;
    if (tasks.isEmpty) {
      return const Center(child: Text("No live platform tasks found."));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final String title = task['title'] ?? 'Task';
        final String statusText = task['status']?.toString().toUpperCase() ?? 'OPEN';
        final double minB = double.tryParse(task['budget_min']?.toString() ?? '0') ?? 0;
        final double maxB = double.tryParse(task['budget_max']?.toString() ?? '0') ?? 0;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      "\$${maxB > 0 ? maxB.toStringAsFixed(0) : minB.toStringAsFixed(0)}",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFFF4500)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(statusText).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(statusText)),
                      ),
                    ),
                    const Spacer(),
                    if (statusText != 'CANCELLED' && statusText != 'COMPLETED')
                      ElevatedButton(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text("Cancel Task?"),
                              content: const Text("Are you sure you want to cancel this task? This is irreversible."),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("No")),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      await appState.syncAdminData();
                                    } catch (e) {
                                      debugPrint('Cancel Task Error: $e');
                                    }
                                  },
                                  child: const Text("Yes, Cancel", style: TextStyle(color: Color(0xFFEF4444))),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        child: const Text("Cancel Task", style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFinanceTab(AppState appState) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF001F3F), Color(0xFF003366)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text("Total Platform Escrow", style: TextStyle(color: Colors.white70, fontSize: 14)),
              SizedBox(height: 8),
              Text(
                "\$124,560.00",
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                "Awaiting Milestone Release Releases",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          "Recent Platform Transactions",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
        ),
        const SizedBox(height: 12),
        if (appState.walletTransactions.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: Text("No transaction logs available.")),
          )
        else
          ...appState.walletTransactions.map((tx) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  tx.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: tx.isIncome ? const Color(0xFF1E8E3E) : const Color(0xFFEF4444),
                ),
                title: Text(tx.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(tx.date),
                trailing: Text(
                  tx.amount,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: tx.isIncome ? const Color(0xFF1E8E3E) : const Color(0xFFEF4444),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'OPEN':
        return const Color(0xFF3B82F6);
      case 'IN_PROGRESS':
        return Colors.orange;
      case 'COMPLETED':
        return const Color(0xFF1E8E3E);
      case 'CANCELLED':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }
}
