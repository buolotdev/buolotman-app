import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'chat_screen.dart';
import 'submit_bid_screen.dart';

class BrowseTasksScreen extends StatelessWidget {
  const BrowseTasksScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final task = appState.findTask(taskId)!;

        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTaskSummaryCard(task),
                          const SizedBox(height: 16),
                          _buildScopeCard(task),
                          const SizedBox(height: 16),
                          _buildClientCard(task),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildStickyCta(context, task),
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
                  child: const Icon(Icons.arrow_back, color: Color(0xFF001F3F), size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Task details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                  Text('Browse Tasks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                ],
              ),
            ],
          ),
          Row(
            children: [
              _buildHeaderIcon(Icons.bookmark_border),
              const SizedBox(width: 8),
              _buildHeaderIcon(Icons.share_outlined),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
      child: Icon(icon, color: const Color(0xFF001F3F), size: 20),
    );
  }

  Widget _buildTaskSummaryCard(dynamic task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF000000).withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF4500).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(task.status, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
                  ),
                  if (task.deadline != null) ...[
                    const SizedBox(width: 8),
                    _buildDeadlineTracker(task.deadline!),
                  ],
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4500).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('\$${task.budget.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.title,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: Color(0xFF001F3F), height: 1.25),
          ),
          const SizedBox(height: 12),
          Text(
            task.description,
            style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.6),
          ),
          const SizedBox(height: 16),
          _buildMetaGrid(task),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final tag in task.tags) _buildChip(tag.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaGrid(dynamic task) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: [
        _buildMetaItem('Location', Icons.location_on_outlined, task.location),
        _buildMetaItem('Schedule', Icons.calendar_today_outlined, task.schedule),
        _buildMetaItem('Posted', Icons.access_time, task.createdLabel),
        _buildMetaItem('Category', Icons.work_outline, task.category),
      ],
    );
  }

  Widget _buildMetaItem(String label, IconData icon, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF001F3F)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
    );
  }

  Widget _buildScopeCard(dynamic task) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF000000).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Scope of work', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 12),
          Text(
            task.description,
            style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _buildClientCard(dynamic task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF000000).withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Client information', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 16),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: buildAvatarImage(task.clientAvatar, width: 52, height: 52, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(task.clientName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFF16A34A).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Verified client', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildClientMetaItem(Icons.star, '${task.clientRating.toStringAsFixed(1)} rating'),
                          const SizedBox(width: 12),
                          _buildClientMetaItem(Icons.assignment_turned_in, '${task.bidsCount} bids'),
                          const SizedBox(width: 12),
                          _buildClientMetaItem(Icons.account_balance_wallet_outlined, task.paymentMethod),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClientMetaItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildStickyCta(BuildContext context, dynamic task) {
    final appState = AppStateScope.of(context);
    final canBid = appState.currentRole != 'Client';
    final hasBid = appState.bids.any((b) => b.taskId == task.id.toString());

    final isAssigned = task.assignedToId == appState.currentUser.id.toString();
    final isInProgress = task.status == 'In Progress';
    final isDelivered = task.status == 'Delivered';

    final bool showSubmitWork = isAssigned && isInProgress;
    final bool showDelivered = isAssigned && isDelivered;

    VoidCallback? buttonOnTap;
    String buttonText;
    Color buttonColor;

    if (showSubmitWork) {
      buttonText = 'Submit Work';
      buttonColor = const Color(0xFFFF4500);
      buttonOnTap = () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Submit Work', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            content: const Text('Are you sure you want to mark this task as done and submit it for client review?'),
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
                    await appState.submitWork(task.id);
                    if (context.mounted) {
                      Navigator.pop(context); // dismiss spinner
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work submitted successfully! Client has been notified.')));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // dismiss spinner
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit work: $e')));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500), foregroundColor: Colors.white),
                child: const Text('Submit'),
              ),
            ],
          ),
        );
      };
    } else if (showDelivered) {
      buttonText = 'Work Submitted';
      buttonColor = const Color(0xFFCBD5E1);
      buttonOnTap = null;
    } else {
      buttonText = !canBid
          ? 'Clients cannot bid'
          : hasBid
              ? 'Bid Submitted'
              : 'Submit a Bid';
      buttonColor = (canBid && !hasBid) ? const Color(0xFFFF4500) : const Color(0xFFCBD5E1);
      buttonOnTap = canBid && !hasBid
          ? () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => SubmitBidScreen(taskId: task.id)),
              );
            }
          : null;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.08))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    String? existingThreadId;
                    for (final item in appState.threads) {
                      if (item.name.toLowerCase() == task.clientName.toLowerCase()) {
                        existingThreadId = item.id;
                        break;
                      }
                    }
                    if (existingThreadId == null) {
                      appState.createOrOpenThread(
                        otherPartyName: task.clientName,
                        otherPartyImage: task.clientAvatar,
                        initialMessage: 'Hi ${task.clientName}, I have a question about "${task.title}".',
                      );
                    }
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          name: task.clientName,
                          image: task.clientAvatar,
                          threadId: existingThreadId,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: const Text('Message Client', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: buttonOnTap,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      buttonText,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Submitting a bid lets the client review your timeline, price, and experience before hiring.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
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
