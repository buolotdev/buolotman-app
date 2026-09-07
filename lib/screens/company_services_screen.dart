import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'company_profile_screen.dart';

class CompanyServicesScreen extends StatefulWidget {
  const CompanyServicesScreen({super.key});
  @override
  State<CompanyServicesScreen> createState() => _CompanyServicesScreenState();
}

class _CompanyServicesScreenState extends State<CompanyServicesScreen> {
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      bg = Color(0xFFF5F7FA),
      muted = Color(0xFF64748B);
  final api = ApiService();
  final title = TextEditingController(), description = TextEditingController();
  String category = 'Construction', pricing = 'Quote-based', status = 'Active';
  List<dynamic> services = [];
  bool verified = false, loading = true, saving = false;
  final categories = const [
    'Construction',
    'Engineering',
    'Renovation',
    'Project Management',
    'IT & Networking',
  ];
  final pricingModels = const ['Quote-based', 'Fixed Price', 'Hourly'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<dynamic>([
        api.companyProfile(),
        api.companyServices(),
      ]);
      if (!mounted) return;
      final profile = values[0] is Map
          ? Map<String, dynamic>.from(values[0])
          : {};
      setState(() {
        verified = profile['is_verified'] == true;
        services = values[1] is List ? values[1] : [];
        loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
        _notice('Could not load company services.');
      }
    }
  }

  Future<void> _create() async {
    if (!verified) {
      _notice(
        'Please wait for administrator verification before publishing services.',
      );
      return;
    }
    if (title.text.trim().isEmpty) {
      _notice('Please enter a service name.');
      return;
    }
    setState(() => saving = true);
    try {
      await api.createCompanyService({
        'title': title.text.trim(),
        'category': category,
        'pricing_model': pricing,
        'description': description.text.trim(),
        'status': status,
      });
      title.clear();
      description.clear();
      setState(() {
        category = 'Construction';
        pricing = 'Quote-based';
        status = 'Active';
      });
      await _load();
      if (mounted) _notice('Service saved successfully.');
    } catch (e) {
      if (mounted)
        _notice(e is ApiException ? e.message : 'Could not save the service.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _deactivate(dynamic id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Deactivate service?'),
        content: const Text(
          'This will remove the service from your active profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.deleteCompanyService(id);
      await _load();
      if (mounted) _notice('Service deactivated.');
    } catch (e) {
      if (mounted) _notice(e is ApiException ? e.message : 'Action failed.');
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) {
    final active = services
        .where((s) => s is Map && s['status'] == 'Active')
        .length;
    final inactive = services
        .where((s) => s is Map && s['status'] == 'Inactive')
        .length;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: navy,
        foregroundColor: Colors.white,
        title: const Text('Manage services'),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: orange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _header(),
                if (!verified) _verificationNotice(),
                _stats(services.length, active, inactive),
                _form(),
                _list(),
              ],
            ),
    );
  }

  Widget _header() => const Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Services Management',
          style: TextStyle(
            color: navy,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Manage Services',
          style: TextStyle(
            color: navy,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 5),
        Text(
          'Publish the services your company offers. Clients will see these on your public profile.',
          style: TextStyle(color: muted),
        ),
      ],
    ),
  );
  Widget _verificationNotice() => Card(
    color: const Color(0xFFFFFBEB),
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706)),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Your company registration documents are under administrative review. Publishing and managing services will unlock upon admin verification.',
              style: TextStyle(color: Color(0xFF92400E)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyProfileScreen()),
            ),
            child: const Text('Company profile'),
          ),
        ],
      ),
    ),
  );
  Widget _stats(int total, int active, int inactive) => Row(
    children: [
      _stat('Total services', total),
      _stat('Active services', active),
      _stat('Inactive services', inactive),
    ],
  );
  Widget _stat(String label, int value) => Expanded(
    child: Card(
      elevation: 0,
      margin: const EdgeInsets.only(right: 8, bottom: 14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: navy,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _form() => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add New Service',
            style: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _input('Service name', title),
          _select(
            'Category',
            category,
            categories,
            (v) => setState(() => category = v!),
          ),
          _select(
            'Pricing model',
            pricing,
            pricingModels,
            (v) => setState(() => pricing = v!),
          ),
          TextField(
            controller: description,
            maxLines: 4,
            decoration: _decoration('Description'),
          ),
          _select('Status', status, const [
            'Active',
            'Inactive',
          ], (v) => setState(() => status = v!)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: saving ? null : _create,
              style: FilledButton.styleFrom(
                backgroundColor: orange,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text(saving ? 'Saving...' : 'Save service'),
            ),
          ),
        ],
      ),
    ),
  );
  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
  Widget _input(String label, TextEditingController c) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(controller: c, decoration: _decoration(label)),
  );
  Widget _select(
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _decoration(label),
      items: items
          .map((x) => DropdownMenuItem(value: x, child: Text(x)))
          .toList(),
      onChanged: onChanged,
    ),
  );
  Widget _list() => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Existing Services',
            style: TextStyle(
              color: navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          if (services.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No services found. Add your first corporate service above.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ),
            )
          else
            ...services.map(_service),
        ],
      ),
    ),
  );
  Widget _service(dynamic raw) {
    final s = raw is Map ? raw : <String, dynamic>{};
    final current = '${s['status'] ?? 'Active'}';
    return Card(
      elevation: 0,
      color: bg,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s['title'] ?? ''}',
              style: const TextStyle(
                color: navy,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${s['category'] ?? 'Construction'} • ${s['pricing_model'] ?? 'Quote-based'}',
              style: const TextStyle(color: muted),
            ),
            if ('${s['description'] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${s['description']}',
                  style: const TextStyle(color: muted),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(current),
                  backgroundColor: current == 'Inactive'
                      ? Colors.grey.shade200
                      : const Color(0xFFDCFCE7),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () =>
                      _notice('Editing services will be available soon.'),
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () => current == 'Active'
                      ? _deactivate(s['id'])
                      : _notice('Editing services will be available soon.'),
                  child: Text(
                    current == 'Inactive' ? 'Activate' : 'Deactivate',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
