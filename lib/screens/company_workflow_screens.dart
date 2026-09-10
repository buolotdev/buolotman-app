import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'client_messaging_screen.dart';

const companyNavy = Color(0xFF001F3F);
const companyOrange = Color(0xFFFF4500);
const companyMuted = Color(0xFF64748B);
const companyBg = Color(0xFFF5F7FA);

class CompanyProjectsScreen extends StatefulWidget {
  const CompanyProjectsScreen({super.key});
  @override
  State<CompanyProjectsScreen> createState() => _CompanyProjectsState();
}

class _CompanyProjectsState extends State<CompanyProjectsScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = api.companyProjects();
  String filter = 'all';

  void reload() => setState(
    () => future = api.companyProjects(status: filter == 'all' ? null : filter),
  );
  void notice(Object e) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(e.toString())));

  Future<void> createProject() async {
    final title = TextEditingController();
    final client = TextEditingController();
    final budget = TextEditingController();
    final timeline = TextEditingController();
    final location = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Create project'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: title,
                decoration: const InputDecoration(labelText: 'Project title'),
              ),
              TextField(
                controller: client,
                decoration: const InputDecoration(labelText: 'Client name'),
              ),
              TextField(
                controller: budget,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Budget'),
              ),
              TextField(
                controller: timeline,
                decoration: const InputDecoration(
                  labelText: 'Timeline / deadline',
                ),
              ),
              TextField(
                controller: location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              d,
              title.text.trim().isNotEmpty && client.text.trim().isNotEmpty,
            ),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await api.createCompanyProject({
          'title': title.text.trim(),
          'client_name': client.text.trim(),
          'budget': budget.text.trim(),
          'timeline': timeline.text.trim(),
          'location': location.text.trim(),
          'status': 'pending',
          'progress': 0,
        });
        reload();
      } catch (e) {
        notice(e);
      }
    }
    for (final c in [title, client, budget, timeline, location]) {
      c.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Company projects'),
      foregroundColor: companyNavy,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: createProject,
          icon: const Icon(Icons.add, color: companyOrange),
        ),
      ],
    ),
    backgroundColor: companyBg,
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            initialValue: filter,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All projects')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'active', child: Text('Active')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
            ],
            onChanged: (v) {
              filter = v ?? 'all';
              reload();
            },
          ),
        ),
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: future,
            builder: (context, snap) {
              if (!snap.hasData)
                return const Center(
                  child: CircularProgressIndicator(color: companyOrange),
                );
              final items = snap.data!;
              if (items.isEmpty)
                return const Center(
                  child: Text(
                    'No projects yet.',
                    style: TextStyle(color: companyMuted),
                  ),
                );
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final p = items[i] as Map;
                          return Card(
                            elevation: 0,
                            child: ListTile(
                      title: Text(
                        '${p['title'] ?? 'Project'}',
                        style: const TextStyle(
                          color: companyNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${p['client_name'] ?? ''} • ${p['status'] ?? 'pending'}\nBudget: ${p['budget'] ?? '—'} • Progress: ${p['progress'] ?? 0}%',
                      ),
                              isThreeLine: true,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CompanyProjectDetailsScreen(
                                    project: Map<String, dynamic>.from(p),
                                  ),
                                ),
                              ),
                              trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (p['client_id'] != null)
                            IconButton(
                              icon: const Icon(
                                Icons.message_outlined,
                                color: companyNavy,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClientMessagesScreen(
                                    participantId: p['client_id'],
                                    participantName:
                                        '${p['client_name'] ?? 'Client'}',
                                    contextType: 'project',
                                    contextId: p['id'],
                                    withBottomNavigation: false,
                                  ),
                                ),
                              ),
                            ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () async {
                              try {
                                await api.deleteCompanyProject(p['id']);
                                reload();
                              } catch (e) {
                                notice(e);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class CompanyQuotesScreen extends StatefulWidget {
  const CompanyQuotesScreen({super.key});
  @override
  State<CompanyQuotesScreen> createState() => _CompanyQuotesState();
}

class _CompanyQuotesState extends State<CompanyQuotesScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = ApiService().companyQuotes();
  void notice(Object e) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(e.toString())));
  Future<void> setStatus(dynamic id, String status) async {
    try {
      await api.updateCompanyQuote(id, {'status': status});
      setState(() => future = api.companyQuotes());
    } catch (e) {
      notice(e);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Quote requests'),
      foregroundColor: companyNavy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: companyBg,
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: companyOrange),
          );
        final items = snap.data!;
        if (items.isEmpty)
          return const Center(
            child: Text(
              'No quote requests yet.',
              style: TextStyle(color: companyMuted),
            ),
          );
        return ListView.builder(
          padding: const EdgeInsets.all(14),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final q = items[i] as Map;
            final status = '${q['status'] ?? 'pending'}';
            final closed =
                status == 'approved' ||
                status == 'accepted' ||
                status == 'rejected';
            return Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${q['service'] ?? 'Quote request'}',
                      style: const TextStyle(
                        color: companyNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '${q['client_name'] ?? 'Client'} • ${q['client_email'] ?? ''}',
                      style: const TextStyle(color: companyMuted),
                    ),
                    Text(
                      'Budget: ${q['budget'] ?? '—'} • Deadline: ${q['deadline'] ?? '—'}',
                    ),
                    if ('${q['project_summary'] ?? ''}'.isNotEmpty)
                      Text('${q['project_summary']}'),
                    Row(
                      children: [
                        Chip(label: Text(status)),
                        const Spacer(),
                        if (q['client_id'] != null)
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClientMessagesScreen(
                                  participantId: q['client_id'],
                                  participantName:
                                      '${q['client_name'] ?? 'Client'}',
                                  contextType: 'quote',
                                  contextId: q['id'],
                                  withBottomNavigation: false,
                                ),
                              ),
                            ),
                            icon: const Icon(
                              Icons.message_outlined,
                              color: companyNavy,
                            ),
                          ),
                        if (!closed)
                          TextButton(
                            onPressed: () => setStatus(q['id'], 'rejected'),
                            child: const Text('Reject'),
                          ),
                        if (!closed)
                          ElevatedButton(
                            onPressed: () => setStatus(q['id'], 'approved'),
                            child: const Text('Approve'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class CompanyTeamScreen extends StatefulWidget {
  const CompanyTeamScreen({super.key});
  @override
  State<CompanyTeamScreen> createState() => _CompanyTeamState();
}

class _CompanyTeamState extends State<CompanyTeamScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = ApiService().companyTeam();
  void notice(Object e) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(e.toString())));
  Future<void> addMember() async {
    final name = TextEditingController(),
        role = TextEditingController(),
        email = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Add team member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: role,
              decoration: const InputDecoration(labelText: 'Position / role'),
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              d,
              name.text.trim().isNotEmpty && role.text.trim().isNotEmpty,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await api.createCompanyTeamMember({
          'name': name.text.trim(),
          'role': role.text.trim(),
          'email': email.text.trim(),
          'status': 'active',
        });
        setState(() => future = api.companyTeam());
      } catch (e) {
        notice(e);
      }
    }
    name.dispose();
    role.dispose();
    email.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Team'),
      foregroundColor: companyNavy,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: addMember,
          icon: const Icon(Icons.person_add, color: companyOrange),
        ),
      ],
    ),
    backgroundColor: companyBg,
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: companyOrange),
          );
        final items = snap.data!;
        if (items.isEmpty)
          return const Center(
            child: Text(
              'No team members yet.',
              style: TextStyle(color: companyMuted),
            ),
          );
        return ListView(
          padding: const EdgeInsets.all(14),
          children: items.map((item) {
            final m = item as Map;
            return Card(
              elevation: 0,
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text('${m['name'] ?? ''}'),
                subtitle: Text(
                  '${m['role'] ?? ''}\n${m['email'] ?? ''} • ${m['status'] ?? 'active'}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    try {
                      await api.deleteCompanyTeamMember(m['id']);
                      setState(() => future = api.companyTeam());
                    } catch (e) {
                      notice(e);
                    }
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    ),
  );
}

class CompanyInsightsScreen extends StatefulWidget {
  const CompanyInsightsScreen({super.key});
  @override
  State<CompanyInsightsScreen> createState() => _CompanyInsightsState();
}

class _CompanyInsightsState extends State<CompanyInsightsScreen> {
  late Future<Map<String, dynamic>> future = ApiService().companyProfile();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Analytics and reviews'),
      foregroundColor: companyNavy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: companyBg,
    body: FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: companyOrange),
          );
        final p = snap.data!;
        final d = p['rating_distribution'] is Map
            ? p['rating_distribution'] as Map
            : const {};
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _metric('Profile views', p['profile_views']),
            _metric('Completed projects', p['completed_tasks']),
            _metric('Average rating', p['average_rating']),
            _metric('Reviews', p['review_count']),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rating distribution',
                      style: TextStyle(
                        color: companyNavy,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final n in ['5', '4', '3', '2', '1'])
                      Text('$n stars: ${d[n] ?? 0}'),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );

  Widget _metric(String label, dynamic value) => Card(
    elevation: 0,
    child: ListTile(
      title: Text(label, style: const TextStyle(color: companyMuted)),
      trailing: Text(
        '${value ?? 0}',
        style: const TextStyle(
          color: companyNavy,
          fontWeight: FontWeight.w800,
          fontSize: 20,
        ),
      ),
    ),
  );
}

class CompanyProjectDetailsScreen extends StatefulWidget {
  const CompanyProjectDetailsScreen({super.key, required this.project});
  final Map<String, dynamic> project;

  @override
  State<CompanyProjectDetailsScreen> createState() =>
      _CompanyProjectDetailsState();
}

class _CompanyProjectDetailsState extends State<CompanyProjectDetailsScreen> {
  final api = ApiService();
  late Map<String, dynamic> project = Map<String, dynamic>.from(widget.project);
  bool saving = false;

  void notice(Object error) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(error.toString())),
  );

  Future<void> update(Map<String, dynamic> values) async {
    final id = project['id'];
    if (id == null) {
      notice('This project has no valid identifier.');
      return;
    }
    setState(() => saving = true);
    try {
      final result = await api.updateCompanyProject(id, values);
      if (mounted) {
        setState(() => project = {...project, ...result});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project saved successfully.')),
        );
      }
    } catch (e) {
      notice('Unable to save project: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> editProgress() async {
    final progress = TextEditingController(text: '${project['progress'] ?? 0}');
    var selectedStatus = '${project['status'] ?? 'pending'}';
    final selected = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Update project progress'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: progress,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Completion percentage'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: ['pending', 'active', 'completed', 'cancelled'].contains(selectedStatus)
                    ? selectedStatus
                    : 'pending',
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) => setDialogState(() => selectedStatus = value ?? 'pending'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(progress.text.trim());
                if (value == null || value < 0 || value > 100) return;
                Navigator.pop(context, {'progress': value, 'status': selectedStatus});
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (selected != null) await update(selected);
  }

  @override
  Widget build(BuildContext context) {
    final p = project;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project details'),
        foregroundColor: companyNavy,
        backgroundColor: Colors.white,
      ),
      backgroundColor: companyBg,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${p['title'] ?? 'Project'}', style: const TextStyle(color: companyNavy, fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          _detail('Client', p['client_name']),
          _detail('Budget', p['budget']),
          _detail('Timeline / deadline', p['timeline'] ?? p['deadline']),
          _detail('Location', p['location']),
          _detail('Status', p['status']),
          _detail('Payment status', p['payment_status']),
          _detail('Progress', '${p['progress'] ?? 0}%'),
          _detail('Milestones', '${p['milestones_completed'] ?? 0} / ${p['milestones_total'] ?? 0}'),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: saving ? null : editProgress,
            icon: const Icon(Icons.edit_outlined),
            label: Text(saving ? 'Saving...' : 'Update progress'),
            style: FilledButton.styleFrom(backgroundColor: companyOrange),
          ),
          const SizedBox(height: 10),
          if (p['client_id'] != null)
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientMessagesScreen(
                    participantId: p['client_id'],
                    participantName: '${p['client_name'] ?? 'Client'}',
                    contextType: 'project',
                    contextId: p['id'],
                    withBottomNavigation: false,
                  ),
                ),
              ),
              icon: const Icon(Icons.message_outlined),
              label: const Text('Message client'),
            ),
        ],
      ),
    );
  }

  Widget _detail(String label, dynamic value) => Card(
    elevation: 0,
    child: ListTile(
      title: Text(label, style: const TextStyle(color: companyMuted)),
      subtitle: Text("${value ?? '—'}", style: const TextStyle(color: companyNavy, fontWeight: FontWeight.w600)),
    ),
  );
}

class CompanyWalletScreen extends StatefulWidget {
  const CompanyWalletScreen({super.key});
  @override
  State<CompanyWalletScreen> createState() => _CompanyWalletState();
}

class _CompanyWalletState extends State<CompanyWalletScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = ApiService().walletTransactions();
  bool busy = false;
  String campayStatus = '';

  void reload() => setState(() {
    future = api.walletTransactions();
  });

  void notice(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );

  Future<void> checkCampayBalance() async {
    setState(() => busy = true);
    try {
      final result = await api.campayGetBalance();
      final amount = result is Map
          ? (result['balance'] ?? result['available_balance'] ?? result['amount'])
          : result;
      notice('CamPay balance: ${amount ?? 0}');
    } catch (e) {
      notice('Unable to load CamPay balance: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> pollTopUp(String reference) async {
    for (var attempt = 0; attempt < 20; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      try {
        final result = await api.campayCheckStatus(reference);
        final status = result is Map
            ? '${result['status'] ?? result['state'] ?? ''}'.toLowerCase()
            : '$result'.toLowerCase();
        if (status.contains('success') || status.contains('complete') || status == 'paid') {
          campayStatus = 'Top-up confirmed.';
          reload();
          if (mounted) setState(() {});
          return;
        }
        if (status.contains('fail') || status.contains('cancel') || status.contains('reject')) {
          campayStatus = 'Top-up was not completed.';
          if (mounted) setState(() {});
          return;
        }
      } catch (_) {
        // Keep the request pending; the user can refresh transactions manually.
      }
    }
    if (mounted) {
      setState(() => campayStatus = 'Payment is still pending. Refresh later to check again.');
    }
  }

  Future<void> withdraw() async {
    final amount = TextEditingController();
    final phone = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw funds'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Payout phone/account'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirmed != true) return;
    final value = double.tryParse(amount.text.trim());
    if (value == null || value <= 0 || phone.text.trim().isEmpty) {
      notice('Enter a valid amount and payout account.');
      return;
    }
    setState(() => busy = true);
    try {
      await api.campayWithdraw({
        'amount': value,
        'phone_number': phone.text.trim(),
        'description': 'Company wallet withdrawal',
      });
      notice('Withdrawal request submitted.');
      reload();
    } catch (e) {
      notice('Withdrawal failed: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> topUp() async {
    final amount = TextEditingController();
    final phone = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add money'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Mobile Money number'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continue')),
        ],
      ),
    );
    if (confirmed != true) return;
    final value = double.tryParse(amount.text.trim());
    if (value == null || value <= 0 || phone.text.trim().isEmpty) {
      notice('Enter a valid amount and mobile money number.');
      return;
    }
    setState(() => busy = true);
    try {
      final result = await api.campayCollect({
        'amount': value,
        'phone_number': phone.text.trim(),
        'purpose': 'wallet_topup',
        'description': 'Company wallet top-up',
      });
      final reference = result is Map ? result['reference']?.toString() : null;
      if (reference == null || reference.isEmpty) {
        notice('The payment request did not return a reference.');
      } else {
        setState(() => campayStatus = 'Payment request sent. Waiting for confirmation...');
        notice('Complete the payment on your phone.');
        await pollTopUp(reference);
      }
      reload();
    } catch (e) {
      notice('Top-up failed: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Wallet'),
      foregroundColor: companyNavy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: companyBg,
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(
            child: CircularProgressIndicator(color: companyOrange),
          );
        final rows = snap.data!;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: api.wallet(),
              builder: (_, w) {
                final x = w.data ?? {};
                return Card(
                  color: companyNavy,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available balance',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${x['available_balance'] ?? x['balance'] ?? 0} ${x['currency'] ?? 'XAF'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                          ),
                        ),
                        if (campayStatus.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(campayStatus, style: const TextStyle(color: Colors.white70)),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: busy ? null : topUp,
                                child: const Text('Add money'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: busy ? null : withdraw,
                                style: FilledButton.styleFrom(backgroundColor: companyOrange),
                                child: const Text('Withdraw'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: busy ? null : checkCampayBalance,
                            icon: const Icon(Icons.sync_alt),
                            label: const Text('Check CamPay balance'),
                            style: TextButton.styleFrom(foregroundColor: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            const Text(
              'Transactions',
              style: TextStyle(
                color: companyNavy,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const Text(
                'No transactions yet.',
                style: TextStyle(color: companyMuted),
              ),
            ...rows.map((item) {
              final t = item as Map;
              return Card(
                elevation: 0,
                child: ListTile(
                  title: Text(
                    '${t['description'] ?? t['type'] ?? 'Transaction'}',
                  ),
                  subtitle: Text(
                    '${t['status'] ?? ''} • ${t['created_at'] ?? t['date'] ?? ''}',
                  ),
                  trailing: Text('${t['amount'] ?? 0}'),
                ),
              );
            }),
          ],
        );
      },
    ),
  );
}
