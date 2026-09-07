import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'client_messaging_screen.dart';
import 'client_payment_screen.dart';

const projectNavy = Color(0xFF001F3F), projectOrange = Color(0xFFFF4500), projectMuted = Color(0xFF64748B), projectBg = Color(0xFFF5F7FA);

List<dynamic> projectItems(dynamic value) => value is List ? value : value is Map && value['results'] is List ? value['results'] as List : const [];

class ClientProjectsScreen extends StatefulWidget {
  const ClientProjectsScreen({super.key});
  @override State<ClientProjectsScreen> createState() => _ClientProjectsState();
}

class _ClientProjectsState extends State<ClientProjectsScreen> {
  final api = ApiService();
  List<dynamic> tasks = [];
  String filter = 'all';
  bool loading = true;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final data = await api.myTasks(); if (mounted) setState(() { tasks = projectItems(data); loading = false; }); } catch (_) { if (mounted) setState(() => loading = false); } }
  bool _matches(dynamic raw) { final x = raw is Map ? raw : <String, dynamic>{}; final status = '${x['status'] ?? 'open'}'; if (filter == 'completed') return status == 'completed'; if (filter == 'active') return status == 'in_progress'; if (filter == 'pending') return status == 'open' || status == 'draft'; return true; }
  @override Widget build(BuildContext context) { final visible = tasks.where(_matches).toList(); final active = tasks.where((x) => x is Map && '${x['status']}' == 'in_progress').length; final completed = tasks.where((x) => x is Map && '${x['status']}' == 'completed').length; final pending = tasks.where((x) => x is Map && ['open', 'draft'].contains('${x['status']}')).length; return Scaffold(appBar: AppBar(title: const Text('My projects'), foregroundColor: projectNavy, backgroundColor: Colors.white, actions: [IconButton(onPressed: loading ? null : _load, icon: const Icon(Icons.refresh, color: projectNavy))]), backgroundColor: projectBg, body: RefreshIndicator(onRefresh: _load, child: loading ? const Center(child: CircularProgressIndicator(color: projectOrange)) : ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 28), children: [_hero(), const SizedBox(height: 16), _stats(active, completed, pending), const SizedBox(height: 18), _filters(), const SizedBox(height: 14), if (visible.isEmpty) _empty() else ...visible.map(_projectCard)]))); }
  Widget _hero() => Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: projectNavy, borderRadius: BorderRadius.circular(18)), child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Projects & contracts', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800)), SizedBox(height: 8), Text('Track assigned professionals, deliverables, milestones, and protected escrow from one workspace.', style: TextStyle(color: Colors.white70, height: 1.4))]));
  Widget _stats(int active, int completed, int pending) => Row(children: [_stat('In progress', '$active', Icons.timelapse), _stat('Completed', '$completed', Icons.check_circle_outline), _stat('Pending', '$pending', Icons.schedule)]);
  Widget _stat(String label, String value, IconData icon) => Expanded(
    child: Card(
      elevation: 0,
      margin: const EdgeInsets.only(right: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(children: [
          Icon(icon, color: projectOrange),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: projectNavy, fontWeight: FontWeight.w800, fontSize: 19)),
          Text(label, style: const TextStyle(color: projectMuted, fontSize: 11), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );
  Widget _filters() => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(children: [
      for (final item in const [('all', 'All'), ('active', 'In progress'), ('pending', 'Pending'), ('completed', 'Completed')])
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(item.$2),
            selected: filter == item.$1,
            selectedColor: const Color(0xFFFFE0D6),
            checkmarkColor: projectOrange,
            onSelected: (_) => setState(() => filter = item.$1),
          ),
        ),
    ]),
  );
  Widget _projectCard(dynamic raw) { final x = raw is Map ? raw : <String, dynamic>{}; final status = '${x['status'] ?? 'open'}'; final accepted = status == 'in_progress' || status == 'completed'; final budget = x['budget_max'] ?? x['budget_min']; return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 12), child: InkWell(borderRadius: BorderRadius.circular(14), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ClientProjectWorkspaceScreen(taskId: x['id']))).then((_) => _load()), child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('${x['title'] ?? 'Project'}', style: const TextStyle(color: projectNavy, fontSize: 18, fontWeight: FontWeight.w800))), _status(status)]), const SizedBox(height: 10), Row(children: [const Icon(Icons.location_on_outlined, color: projectMuted, size: 16), const SizedBox(width: 5), Expanded(child: Text('${x['city'] ?? x['location'] ?? 'Location not specified'}', style: const TextStyle(color: projectMuted))), Text(budget == null ? 'Negotiable' : '$budget XOF', style: const TextStyle(color: projectNavy, fontWeight: FontWeight.w800))]), const SizedBox(height: 13), LinearProgressIndicator(value: status == 'completed' ? 1 : accepted ? .5 : .2, color: status == 'completed' ? Colors.green : projectOrange, backgroundColor: const Color(0xFFE2E8F0), minHeight: 7), const SizedBox(height: 7), Row(children: [Text(status == 'completed' ? 'Completed' : accepted ? 'Active workspace' : 'Awaiting assignment', style: const TextStyle(color: projectMuted, fontSize: 12)), const Spacer(), const Text('Open workspace', style: TextStyle(color: projectOrange, fontWeight: FontWeight.w700, fontSize: 12)), const Icon(Icons.chevron_right, color: projectOrange, size: 18)])])))); }
  Widget _status(String value) => Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5), decoration: BoxDecoration(color: value == 'completed' ? const Color(0xFFDCFCE7) : value == 'in_progress' ? const Color(0xFFE0F2FE) : const Color(0xFFFFF4D6), borderRadius: BorderRadius.circular(20)), child: Text(value.replaceAll('_', ' ').toUpperCase(), style: TextStyle(color: value == 'completed' ? Colors.green.shade700 : projectNavy, fontSize: 10, fontWeight: FontWeight.w800)));
  Widget _empty() => const Padding(padding: EdgeInsets.all(40), child: Column(children: [Icon(Icons.folder_open_outlined, color: projectMuted, size: 48), SizedBox(height: 12), Text('No projects in this view.', style: TextStyle(color: projectNavy, fontWeight: FontWeight.w700)), SizedBox(height: 5), Text('Accepted tasks will appear here as project workspaces.', textAlign: TextAlign.center, style: TextStyle(color: projectMuted))]));
}

class ClientProjectWorkspaceScreen extends StatefulWidget { const ClientProjectWorkspaceScreen({super.key, required this.taskId}); final dynamic taskId; @override State<ClientProjectWorkspaceScreen> createState() => _ClientWorkspaceState(); }
class _ClientWorkspaceState extends State<ClientProjectWorkspaceScreen> {
  final api = ApiService(); Map<String, dynamic> task = {}; bool loading = true, acting = false;
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { final data = await api.task(widget.taskId); if (mounted) setState(() { task = data is Map ? Map<String, dynamic>.from(data) : {}; loading = false; }); } catch (_) { if (mounted) setState(() => loading = false); } }
  void _notice(String text, {bool error = true}) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: error ? Colors.red.shade700 : projectNavy, content: Text(text))); }
  Future<void> _complete() async { setState(() => acting = true); try { await api.completeTask(widget.taskId); _notice('Project marked completed.', error: false); await _load(); } catch (e) { _notice('$e'); } finally { if (mounted) setState(() => acting = false); } }
  Future<void> _openDispute() async { final title = TextEditingController(), description = TextEditingController(); final ok = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('Open a dispute'), content: Column(mainAxisSize: MainAxisSize.min, children: [TextField(controller: title, decoration: const InputDecoration(labelText: 'Issue title')), TextField(controller: description, maxLines: 4, decoration: const InputDecoration(labelText: 'Describe the issue'))]), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')), ElevatedButton(onPressed: () => Navigator.pop(d, true), child: const Text('Submit'))])); if (ok != true || title.text.trim().isEmpty || description.text.trim().isEmpty) return; try { await api.createDispute({'task': widget.taskId, 'title': title.text.trim(), 'reason': 'service_issue', 'description': description.text.trim()}); _notice('Dispute submitted for review.', error: false); } catch (e) { _notice('$e'); } }
  Future<void> _messages() async { final id = task['assigned_to']; if (id == null) return _notice('Messaging becomes available after a professional is assigned.'); if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ClientMessagesScreen(taskId: widget.taskId, participantId: id))); }
  @override Widget build(BuildContext context) { if (loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: projectOrange))); final status = '${task['status'] ?? 'open'}'; final files = projectItems(task['attachments']); final milestones = projectItems(task['milestones']); final budget = task['escrow_amount'] ?? task['budget_max'] ?? task['budget_min'] ?? 0; final escrow = task['has_escrow'] == true; return Scaffold(appBar: AppBar(title: const Text('Project workspace'), foregroundColor: projectNavy, backgroundColor: Colors.white, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: projectNavy))]), backgroundColor: projectBg, body: RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 30), children: [_hero(status), _summary(budget, escrow, status), _milestones(milestones, budget, escrow, status), _files(files), _actions(status), _support()]))); }
  Widget _hero(String status) => Container(padding: const EdgeInsets.all(20), margin: const EdgeInsets.only(bottom: 14), decoration: BoxDecoration(color: projectNavy, borderRadius: BorderRadius.circular(18)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('PROJECT WORKSPACE', style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)), const SizedBox(height: 7), Text('${task['title'] ?? 'Project'}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)), const SizedBox(height: 10), Text('${task['description'] ?? 'Manage your project deliverables and progress.'}', style: const TextStyle(color: Colors.white70, height: 1.4)), const SizedBox(height: 14), Wrap(spacing: 8, runSpacing: 8, children: [_darkPill('Status: ${status.replaceAll('_', ' ')}'), _darkPill('Client: ${task['client_name'] ?? 'You'}'), _darkPill('Professional: ${task['assigned_to_name'] ?? 'Awaiting assignment'}'), _darkPill('Location: ${task['city'] ?? task['location'] ?? 'Not specified'}')]) ]));
  Widget _darkPill(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(18)), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)));
  Widget _summary(dynamic budget, bool escrow, String status) => _section('Escrow and progress', [Row(children: [_metric('Total budget', '$budget XOF', Icons.account_balance_wallet_outlined), _metric('Escrow', escrow ? 'Protected' : 'Not funded', Icons.shield_outlined), _metric('Status', status.replaceAll('_', ' '), Icons.timelapse)]), const SizedBox(height: 14), LinearProgressIndicator(value: status == 'completed' ? 1 : escrow ? .5 : .2, color: status == 'completed' ? Colors.green : projectOrange, backgroundColor: const Color(0xFFE2E8F0), minHeight: 8), const SizedBox(height: 7), Text(status == 'completed' ? 'Project completed and funds released.' : escrow ? 'Funds remain protected until work is approved.' : 'Escrow has not been funded yet.', style: const TextStyle(color: projectMuted, fontSize: 12))]);
  Widget _metric(String label, String value, IconData icon) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: projectOrange, size: 21), const SizedBox(height: 5), Text(label, style: const TextStyle(color: projectMuted, fontSize: 11)), const SizedBox(height: 2), Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: projectNavy, fontWeight: FontWeight.w800, fontSize: 13))]));
  Widget _milestones(List milestones, dynamic budget, bool escrow, String status) => _section('Milestones and deliverables', [if (milestones.isEmpty) _milestone('Project delivery and sign-off', 'Full project execution, inspection, and final handover', budget, status == 'completed', escrow) else ...milestones.map((m) => _milestone('${m['title'] ?? 'Milestone'}', '${m['status'] ?? 'pending'} • Due ${m['due_date'] ?? 'Not specified'}', m['amount'] ?? budget, '${m['status']}' == 'completed', escrow))]);
  Widget _milestone(String title, String subtitle, dynamic amount, bool done, bool escrow) => Container(margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(children: [Icon(done ? Icons.check_circle : escrow ? Icons.lock_outline : Icons.schedule, color: done ? Colors.green : projectOrange), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: projectNavy, fontWeight: FontWeight.w800)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(color: projectMuted, fontSize: 12))])), Text('$amount XOF', style: const TextStyle(color: projectNavy, fontWeight: FontWeight.w800, fontSize: 12))]));
  Widget _files(List files) => _section('Project files and deliverables', files.isEmpty ? [const Text('No deliverables uploaded yet.', style: TextStyle(color: projectMuted)), const SizedBox(height: 5), const Text('Submitted work and project attachments will appear here.', style: TextStyle(color: projectMuted, fontSize: 12))] : files.map((f) { final x = f is Map ? f : <String, dynamic>{}; final name = '${x['file_name'] ?? 'Attachment'}'; return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.insert_drive_file_outlined, color: projectOrange), title: Text(name, style: const TextStyle(color: projectNavy, fontWeight: FontWeight.w600)), subtitle: Text('${x['file_type'] ?? x['content_type'] ?? 'File'} • ${x['file_size'] ?? ''}', style: const TextStyle(color: projectMuted))); }).toList());
  Widget _actions(String status) {
    final accepted = task['assigned_to'] != null || status == 'in_progress' || status == 'completed';
    if (!accepted) {
      return _section('Workspace actions', [
        const Icon(Icons.lock_outline, color: projectMuted, size: 28),
        const SizedBox(height: 8),
        const Text('Actions unlock after you accept a professional’s proposal.', style: TextStyle(color: projectNavy, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Review proposals from the task details screen before starting this project.', style: TextStyle(color: projectMuted, height: 1.4)),
      ]);
    }
    return _section('Workspace actions', [
    if (task['assigned_to'] != null) ...[
      OutlinedButton.icon(onPressed: _messages, icon: const Icon(Icons.message_outlined), label: const Text('Message professional'), style: OutlinedButton.styleFrom(foregroundColor: projectNavy, minimumSize: const Size.fromHeight(48))),
      const SizedBox(height: 12),
    ],
    if (status == 'in_progress') ...[
      ElevatedButton.icon(onPressed: acting ? null : _complete, icon: const Icon(Icons.check_circle_outline), label: Text(acting ? 'Completing...' : 'Approve completion'), style: ElevatedButton.styleFrom(backgroundColor: projectOrange, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48))),
      const SizedBox(height: 12),
    ],
    if (status != 'completed') OutlinedButton.icon(onPressed: task['has_escrow'] == true ? null : () async { final amount = task['escrow_amount'] ?? task['budget_max'] ?? task['budget_min'] ?? 0; await Navigator.push(context, MaterialPageRoute(builder: (_) => ClientEscrowPaymentScreen(taskId: widget.taskId, amount: amount, bidId: task['accepted_bid_id']))); _load(); }, icon: const Icon(Icons.lock_outline), label: Text(task['has_escrow'] == true ? 'Escrow funded' : 'Fund escrow'), style: OutlinedButton.styleFrom(foregroundColor: task['has_escrow'] == true ? Colors.green : projectOrange, minimumSize: const Size.fromHeight(48))),
    if (status != 'completed') ...[
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: task['has_escrow'] == true && status == 'completed' ? () async { await api.releaseEscrow(widget.taskId); await _load(); } : null, icon: const Icon(Icons.account_balance_wallet_outlined), label: const Text('Release escrow'), style: OutlinedButton.styleFrom(foregroundColor: projectOrange, minimumSize: const Size.fromHeight(48))),
    ],
  ]);
  }
  Widget _support() => _section('Need help or mediation?', [const Text('Open a dispute if there is a problem with the work, deliverables, or agreement.', style: TextStyle(color: projectMuted, height: 1.4)), const SizedBox(height: 10), OutlinedButton.icon(onPressed: _openDispute, icon: const Icon(Icons.support_agent), label: const Text('Open dispute / support request'), style: OutlinedButton.styleFrom(foregroundColor: projectNavy, minimumSize: const Size.fromHeight(48)))]);
  Widget _section(String title, List<Widget> children) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 14), child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: projectNavy, fontSize: 18, fontWeight: FontWeight.w800)), const SizedBox(height: 13), ...children])));
}
