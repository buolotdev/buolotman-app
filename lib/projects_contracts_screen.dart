import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';

class ProjectsContractsScreen extends StatefulWidget {
  const ProjectsContractsScreen({super.key});

  @override
  State<ProjectsContractsScreen> createState() => _ProjectsContractsScreenState();
}

class _ProjectsContractsScreenState extends State<ProjectsContractsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).syncCompanyProjects();
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
        final projects = appState.companyProjects;
        final active = projects.where((p) => (p['status'] ?? 'active') == 'active').toList();
        final completed = projects.where((p) => p['status'] == 'completed').toList();
        final onHold = projects.where((p) => p['status'] == 'on_hold').toList();

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              'Projects & Contracts',
              style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF001F3F)))
                    : const Icon(Icons.refresh, color: Color(0xFF001F3F)),
                onPressed: _isLoading
                    ? null
                    : () async {
                        setState(() => _isLoading = true);
                        await appState.syncCompanyProjects();
                        if (mounted) setState(() => _isLoading = false);
                      },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF4500),
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: const Color(0xFFFF4500),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: [
                Tab(text: 'Active (${active.length})'),
                Tab(text: 'Completed (${completed.length})'),
                Tab(text: 'On Hold (${onHold.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildProjectList(active, context, appState),
              _buildProjectList(completed, context, appState),
              _buildProjectList(onHold, context, appState),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateProjectSheet(context, appState),
            backgroundColor: const Color(0xFFFF4500),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Contract', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        );
      },
    );
  }

  Widget _buildProjectList(
      List<Map<String, dynamic>> projects, BuildContext context, AppState appState) {
    if (projects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.assignment_outlined, size: 40, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            const Text('No contracts here',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
            const SizedBox(height: 6),
            const Text('Tap "New Contract" to create one',
                style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFFFF4500),
      onRefresh: () async => appState.syncCompanyProjects(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projects.length,
        itemBuilder: (context, index) =>
            _buildProjectCard(projects[index], context, appState),
      ),
    );
  }

  Widget _buildProjectCard(
      Map<String, dynamic> project, BuildContext context, AppState appState) {
    final id = project['id']?.toString() ?? '';
    final title = project['title']?.toString() ?? 'Untitled';
    final clientName = project['client_name']?.toString() ?? 'Unknown Client';
    final budget = double.tryParse(project['budget']?.toString() ?? '0') ?? 0.0;
    final timeline = project['timeline']?.toString() ?? '';
    final status = project['status']?.toString() ?? 'active';
    final paymentStatus = project['payment_status']?.toString() ?? 'awaiting';
    final milestonesTotal = int.tryParse(project['milestones_total']?.toString() ?? '0') ?? 0;
    final milestonesCompleted = int.tryParse(project['milestones_completed']?.toString() ?? '0') ?? 0;
    final progress = int.tryParse(project['progress']?.toString() ?? '0') ?? 0;
    final location = project['location']?.toString() ?? '';

    final statusColor = _statusColor(status);
    final paymentColor = _paymentColor(paymentStatus);

    return GestureDetector(
      key: ValueKey(id),
      onTap: () => _showProjectDetail(context, appState, project),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF001F3F).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.business_center_outlined, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF001F3F))),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 13, color: Color(0xFF94A3B8)),
                            const SizedBox(width: 4),
                            Text(clientName,
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${budget.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001F3F))),
                      const SizedBox(height: 4),
                      _statusBadge(status, statusColor),
                    ],
                  ),
                ],
              ),
            ),
            // Progress bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Milestones: $milestonesCompleted / $milestonesTotal',
                        style:
                            const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                      Text('$progress%',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: milestonesTotal > 0
                          ? milestonesCompleted / milestonesTotal
                          : 0,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(statusColor),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
              ),
              child: Row(
                children: [
                  if (timeline.isNotEmpty) ...[
                    const Icon(Icons.calendar_today_outlined,
                        size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(timeline,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(width: 12),
                  ],
                  if (location.isNotEmpty) ...[
                    const Icon(Icons.location_on_outlined,
                        size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(location,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF64748B))),
                  ],
                  const Spacer(),
                  _paymentBadge(paymentStatus, paymentColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail Bottom Sheet ────────────────────────────────────────────────────

  void _showProjectDetail(
      BuildContext context, AppState appState, Map<String, dynamic> project) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProjectDetailSheet(project: project, appState: appState),
    );
  }

  // ── Create Contract Sheet ─────────────────────────────────────────────────

  void _showCreateProjectSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateContractSheet(appState: appState),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF16A34A);
      case 'on_hold':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF2563EB);
    }
  }

  Color _paymentColor(String ps) {
    switch (ps) {
      case 'released':
        return const Color(0xFF16A34A);
      case 'in_escrow':
        return const Color(0xFF7C3AED);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  Widget _statusBadge(String status, Color color) {
    final label = status == 'on_hold'
        ? 'On Hold'
        : status == 'completed'
            ? 'Completed'
            : 'Active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _paymentBadge(String ps, Color color) {
    final label = ps == 'released'
        ? '✓ Released'
        : ps == 'in_escrow'
            ? '🔒 In Escrow'
            : '⏳ Awaiting';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}

// ── Project Detail Sheet ───────────────────────────────────────────────────

class _ProjectDetailSheet extends StatefulWidget {
  final Map<String, dynamic> project;
  final AppState appState;
  const _ProjectDetailSheet({required this.project, required this.appState});

  @override
  State<_ProjectDetailSheet> createState() => _ProjectDetailSheetState();
}

class _ProjectDetailSheetState extends State<_ProjectDetailSheet> {
  bool _isUpdating = false;

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
    final id = project['id']?.toString() ?? '';
    final title = project['title']?.toString() ?? 'Untitled';
    final clientName = project['client_name']?.toString() ?? 'Unknown';
    final budget = double.tryParse(project['budget']?.toString() ?? '0') ?? 0.0;
    final timeline = project['timeline']?.toString() ?? '';
    final status = project['status']?.toString() ?? 'active';
    final paymentStatus = project['payment_status']?.toString() ?? 'awaiting';
    int milestonesTotal = int.tryParse(project['milestones_total']?.toString() ?? '0') ?? 0;
    int milestonesCompleted =
        int.tryParse(project['milestones_completed']?.toString() ?? '0') ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Client
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF001F3F))),
                                const SizedBox(height: 4),
                                Text('Client: $clientName',
                                    style: const TextStyle(
                                        fontSize: 14, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Text('\$${budget.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFF4500))),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Info chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (timeline.isNotEmpty)
                            _infoChip(Icons.calendar_today_outlined, timeline),
                          _infoChip(
                              Icons.circle,
                              status == 'completed'
                                  ? 'Completed'
                                  : status == 'on_hold'
                                      ? 'On Hold'
                                      : 'Active'),
                          _infoChip(
                              Icons.payment_outlined,
                              paymentStatus == 'released'
                                  ? 'Released'
                                  : paymentStatus == 'in_escrow'
                                      ? 'In Escrow'
                                      : 'Awaiting Payment'),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Milestone Tracker
                      const Text('Milestone Tracking',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001F3F))),
                      const SizedBox(height: 12),
                      _buildMilestoneTracker(
                          milestonesCompleted, milestonesTotal, id),
                      const SizedBox(height: 28),

                      // Payment Status
                      const Text('Payment / Escrow',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001F3F))),
                      const SizedBox(height: 12),
                      _buildPaymentStatusSelector(paymentStatus, id),
                      const SizedBox(height: 28),

                      // Contract Status
                      const Text('Contract Status',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001F3F))),
                      const SizedBox(height: 12),
                      _buildContractStatusSelector(status, id),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildMilestoneTracker(
      int completed, int total, String projectId) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$completed of $total milestones complete',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF001F3F))),
              Text('${total > 0 ? ((completed / total) * 100).round() : 0}%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF4500))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: total > 0 ? completed / total : 0,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          // Milestone steps visualization
          if (total > 0)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(total, (i) {
                final isDone = i < completed;
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDone
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w600)),
                  ),
                );
              }),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.remove, size: 16),
                  label: const Text('Remove'),
                  onPressed: completed <= 0 || _isUpdating
                      ? null
                      : () => _updateMilestones(
                          projectId, completed - 1, total),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF001F3F),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Complete'),
                  onPressed: completed >= total || _isUpdating
                      ? null
                      : () => _updateMilestones(
                          projectId, completed + 1, total),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Add milestone button
          OutlinedButton.icon(
            icon: const Icon(Icons.playlist_add, size: 16),
            label: const Text('Add Milestone'),
            onPressed: _isUpdating
                ? null
                : () => _updateMilestones(projectId, completed, total + 1),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              side: const BorderSide(color: Color(0xFF2563EB)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: const Size(double.infinity, 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStatusSelector(String current, String projectId) {
    final options = [
      {'key': 'awaiting', 'label': '⏳ Awaiting Payment', 'color': const Color(0xFF94A3B8)},
      {'key': 'in_escrow', 'label': '🔒 Funds in Escrow', 'color': const Color(0xFF7C3AED)},
      {'key': 'released', 'label': '✓ Payment Released', 'color': const Color(0xFF16A34A)},
    ];
    return Column(
      children: options.map((opt) {
        final isSelected = current == opt['key'];
        final color = opt['color'] as Color;
        return GestureDetector(
          onTap: _isUpdating
              ? null
              : () => _updatePaymentStatus(projectId, opt['key'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : const Color(0xFFE2E8F0),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(opt['label'] as String,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color:
                              isSelected ? color : const Color(0xFF64748B))),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContractStatusSelector(String current, String projectId) {
    final options = [
      {'key': 'active', 'label': 'Active', 'icon': Icons.play_circle_outline, 'color': const Color(0xFF2563EB)},
      {'key': 'on_hold', 'label': 'On Hold', 'icon': Icons.pause_circle_outline, 'color': const Color(0xFFF59E0B)},
      {'key': 'completed', 'label': 'Completed', 'icon': Icons.check_circle_outline, 'color': const Color(0xFF16A34A)},
    ];
    return Row(
      children: options.map((opt) {
        final isSelected = current == opt['key'];
        final color = opt['color'] as Color;
        return Expanded(
          child: GestureDetector(
            onTap: _isUpdating
                ? null
                : () => _updateContractStatus(projectId, opt['key'] as String),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: opt['key'] != 'completed' ? 8.0 : 0.0),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? color : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Icon(opt['icon'] as IconData,
                      color: isSelected ? Colors.white : color, size: 22),
                  const SizedBox(height: 4),
                  Text(opt['label'] as String,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : color)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _updateMilestones(
      String projectId, int completed, int total) async {
    setState(() => _isUpdating = true);
    try {
      await widget.appState.updateProjectMilestone(projectId, completed, total);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update milestone: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updatePaymentStatus(String projectId, String status) async {
    setState(() => _isUpdating = true);
    try {
      await widget.appState.updateProjectPaymentStatus(projectId, status);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _updateContractStatus(String projectId, String status) async {
    setState(() => _isUpdating = true);
    try {
      await widget.appState.updateProjectStatus(projectId, status);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }
}

// ── Create Contract Sheet ─────────────────────────────────────────────────

class _CreateContractSheet extends StatefulWidget {
  final AppState appState;
  const _CreateContractSheet({required this.appState});

  @override
  State<_CreateContractSheet> createState() => _CreateContractSheetState();
}

class _CreateContractSheetState extends State<_CreateContractSheet> {
  final _titleController = TextEditingController();
  final _clientController = TextEditingController();
  final _budgetController = TextEditingController();
  final _timelineController = TextEditingController();
  final _locationController = TextEditingController();
  int _milestonesTotal = 3;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _clientController.dispose();
    _budgetController.dispose();
    _timelineController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text('New Contract',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001F3F))),
              const SizedBox(height: 4),
              const Text('Create a long-term contract for a client project.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
              const SizedBox(height: 24),
              _label('Project Title *'),
              _field('e.g. Office Renovation – Phase 1', _titleController),
              const SizedBox(height: 16),
              _label('Client Name *'),
              _field('Who is this contract for?', _clientController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Budget (\$) *'),
                        _field('0', _budgetController,
                            keyboardType: TextInputType.number),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Timeline'),
                        _field('e.g. 3 months', _timelineController),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _label('Location (optional)'),
              _field('e.g. Lagos, Nigeria', _locationController),
              const SizedBox(height: 16),
              _label('Number of Milestones'),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline,
                        color: Color(0xFF64748B)),
                    onPressed: _milestonesTotal > 1
                        ? () => setState(() => _milestonesTotal--)
                        : null,
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text('$_milestonesTotal milestones',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF001F3F))),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline,
                        color: Color(0xFFFF4500)),
                    onPressed: _milestonesTotal < 20
                        ? () => setState(() => _milestonesTotal++)
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4500),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Create Contract',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF001F3F))),
    );
  }

  Widget _field(String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              const BorderSide(color: Color(0xFF001F3F), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      _error('Enter a project title.');
      return;
    }
    if (_clientController.text.trim().isEmpty) {
      _error('Enter the client name.');
      return;
    }
    final budget =
        double.tryParse(_budgetController.text.trim()) ?? 0.0;
    if (budget <= 0) {
      _error('Enter a valid budget.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.appState.createProject(
        title: _titleController.text.trim(),
        clientName: _clientController.text.trim(),
        budget: budget,
        timeline: _timelineController.text.trim(),
        milestonesTotal: _milestonesTotal,
        location: _locationController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        Get.snackbar(
          'Contract Created',
          '"${_titleController.text.trim()}" is now live.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF001F3F),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
        );
      }
    } catch (e) {
      _error('Failed to create contract: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
