import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'browse_tasks_screen.dart';
import 'chat_screen.dart';
import 'submit_bid_screen.dart';
import 'task_feed_screen.dart';

class MyBidsScreen extends StatefulWidget {
  const MyBidsScreen({super.key});

  @override
  State<MyBidsScreen> createState() => _MyBidsScreenState();
}

class _MyBidsScreenState extends State<MyBidsScreen> {
  String _activeTab = 'Active';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() => _isLoading = true);
      try {
        await AppStateScope.of(context).syncBids();
        await AppStateScope.of(context).syncTasks();
      } catch (e) {
        debugPrint('Sync bids error: $e');
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

        final roleBids = appState.bids.where((bid) {
          return bid.role == appState.currentRole || bid.bidderName == appState.currentUser.name;
        }).toList();

        final query = _searchController.text.trim().toLowerCase();
        final visibleBids = roleBids.where((bid) {
          final task = appState.findTask(bid.taskId);
          final taskText = '${task?.title ?? ''} ${task?.category ?? ''} ${task?.location ?? ''}'.toLowerCase();
          final matchesSearch = query.isEmpty || taskText.contains(query) || bid.skill.toLowerCase().contains(query);

          final isAccepted = bid.isAccepted;
          final isArchived = isAccepted || bid.role != appState.currentRole;

          if (_activeTab == 'Archived') {
            return matchesSearch && isArchived;
          }
          return matchesSearch && !isArchived;
        }).toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _buildStats(appState, visibleBids),
                        _buildSearchAndFilter(),
                        visibleBids.isEmpty ? _buildEmptyState() : _buildBidsList(appState, visibleBids),
                      ],
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

  Widget _buildHeader() {
    final canPop = Navigator.canPop(context);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (canPop) ...[
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
                ),
                const SizedBox(width: 16),
              ],
              const Text(
                'My Bids',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF001F3F)),
                onPressed: () async {
                  setState(() => _isLoading = true);
                  try {
                    await AppStateScope.of(context).syncBids();
                    await AppStateScope.of(context).syncTasks();
                  } catch (e) {
                    debugPrint('Refresh bids error: $e');
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
              ),
              const SizedBox(width: 4),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.notifications_none, color: Color(0xFF001F3F), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          _buildTabItem('Active'),
          _buildTabItem('Archived'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title) {
    final bool isActive = _activeTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: isActive ? const Color(0xFFFF4500) : Colors.transparent, width: 2),
            ),
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

  Widget _buildStats(AppState appState, List<dynamic> visibleBids) {
    final accepted = visibleBids.where((bid) => bid.isAccepted).length;
    final pending = visibleBids.length - accepted;
    final total = visibleBids.fold<double>(0, (sum, bid) => sum + (bid.price as double));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildStatCard('Pending Offers', pending.toString()),
          const SizedBox(width: 12),
          _buildStatCard('Bid Value', '\$${total.toStringAsFixed(0)}'),
          const SizedBox(width: 12),
          _buildStatCard('Accepted', accepted.toString()),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Container(
      constraints: const BoxConstraints(minWidth: 130),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search your bids...',
                        hintStyle: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune, color: Color(0xFF001F3F)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text(
            'No bids found for this view',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try another tab or clear your search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const TaskFeedScreen()),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), foregroundColor: Colors.white),
            child: const Text('Browse Tasks'),
          ),
        ],
      ),
    );
  }

  Widget _buildBidsList(AppState appState, List<dynamic> bids) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        children: bids.map((bid) {
          final task = appState.findTask(bid.taskId);
          final status = bid.isAccepted ? 'Accepted' : 'Pending';
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildBidCard(appState, bid, task, status),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBidCard(AppState appState, dynamic bid, dynamic task, String status) {
    Color statusColor;
    Color statusBg;
    switch (status) {
      case 'Pending':
        statusColor = const Color(0xFFB45309);
        statusBg = const Color(0xFFFEF3C7);
        break;
      case 'Accepted':
        statusColor = const Color(0xFF047857);
        statusBg = const Color(0xFFD1FAE5);
        break;
      default:
        statusColor = const Color(0xFFB91C1C);
        statusBg = const Color(0xFFFEE2E2);
    }

    return Container(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: buildAvatarImage(bid.avatar, width: 36, height: 36, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bid.bidderName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Color(0xFFF59E0B), size: 12),
                          const SizedBox(width: 4),
                          Text('${bid.rating.toStringAsFixed(1)} (${bid.reviews})', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(task?.title ?? 'Unknown task', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4)),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMetaIconText(Icons.location_on_outlined, task?.location ?? 'Unknown location'),
              const SizedBox(width: 12),
              _buildMetaIconText(Icons.bolt, task?.category ?? bid.skill),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF4F6F8), borderRadius: BorderRadius.circular(8)),
            child: Column(
              children: [
                _buildDetailRow('Your Offer', '\$${bid.price.toStringAsFixed(0)}', isAmount: true),
                const SizedBox(height: 10),
                _buildDetailRow('Timeline', bid.timeline),
                const SizedBox(height: 10),
                _buildDetailRow('Role', bid.role),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            bid.message,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          _buildCardActions(appState, bid, task, status),
        ],
      ),
    );
  }

  Widget _buildMetaIconText(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontSize: isAmount ? 18 : 14,
            fontWeight: FontWeight.bold,
            color: isAmount ? const Color(0xFFFF4500) : const Color(0xFF001F3F),
          ),
        ),
      ],
    );
  }

  Widget _buildCardActions(AppState appState, dynamic bid, dynamic task, String status) {
    if (task == null) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const TaskFeedScreen()),
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFFF1F5F9),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Task unavailable', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w600)),
        ),
      );
    }

    if (status == 'Accepted') {
      return Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                appState.createOrOpenThread(
                  otherPartyName: task.clientName,
                  otherPartyImage: task.clientAvatar,
                );
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ChatScreen(name: task.clientName, image: task.clientAvatar)),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Message', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => BrowseTasksScreen(taskId: task.id)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Workspace', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => BrowseTasksScreen(taskId: task.id)),
              );
            },
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('View Task', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SubmitBidScreen(taskId: task.id)),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4500),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 0,
            ),
            child: const Text('Update Bid', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }
}
