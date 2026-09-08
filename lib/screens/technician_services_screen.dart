import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'technician_navigation.dart';

class TechnicianServicesScreen extends StatefulWidget {
  const TechnicianServicesScreen({super.key});
  @override
  State<TechnicianServicesScreen> createState() => _ServicesState();
}

class _ServicesState extends State<TechnicianServicesScreen> {
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      bg = Color(0xFFF5F7FA),
      muted = Color(0xFF64748B);
  final api = ApiService();
  late Future<dynamic> future = api.technicianServices();
  bool verified = false;
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    try {
      final p = await api.profile();
      if (mounted)
        setState(
          () => verified =
              p['is_verified'] == true ||
              p['technician_profile']?['is_verified'] == true,
        );
    } catch (_) {}
  }

  List<dynamic> _items(dynamic v) => v is List
      ? v
      : v is Map && v['results'] is List
      ? v['results']
      : const [];
  void _notice(String s) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  Future<void> _edit([Map? item]) async {
    if (!verified && item == null) {
      _notice('Publishing services unlocks after admin verification.');
      return;
    }
    final title = TextEditingController(text: '${item?['title'] ?? ''}');
    final category = TextEditingController(text: '${item?['category'] ?? ''}');
    final description = TextEditingController(
      text: '${item?['description'] ?? ''}',
    );
    final coverage = TextEditingController(
      text: '${item?['coverage_area'] ?? ''}',
    );
    final min = TextEditingController(text: '${item?['pricing_min'] ?? ''}');
    final max = TextEditingController(text: '${item?['pricing_max'] ?? ''}');
    String type = '${item?['service_type'] ?? 'onsite'}';
    String pricing = '${item?['pricing_model'] ?? 'fixed'}';
    bool active = item?['is_active'] != false;
    List<dynamic> media = List<dynamic>.from(
      item?['media'] is List ? item!['media'] : const [],
    );
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (_, setDialog) => AlertDialog(
          title: Text(item == null ? 'New service' : 'Edit service'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(title, 'Service title'),
                _field(category, 'Category / specializations'),
                _field(description, 'Description', lines: 4),
                _field(coverage, 'Coverage area'),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Service type'),
                  items: const [
                    DropdownMenuItem(value: 'onsite', child: Text('On-site')),
                    DropdownMenuItem(value: 'remote', child: Text('Remote')),
                  ],
                  onChanged: (v) => setDialog(() => type = v ?? 'onsite'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: pricing,
                  decoration: const InputDecoration(labelText: 'Pricing model'),
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('Fixed')),
                    DropdownMenuItem(value: 'hourly', child: Text('Hourly')),
                    DropdownMenuItem(value: 'range', child: Text('Range')),
                  ],
                  onChanged: (v) => setDialog(() => pricing = v ?? 'fixed'),
                ),
                _field(
                  min,
                  pricing == 'fixed' ? 'Price (XOF)' : 'Minimum price (XOF)',
                  keyboard: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (pricing == 'range')
                  _field(
                    max,
                    'Maximum price (XOF)',
                    keyboard: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active / visible listing'),
                  value: active,
                  activeThumbColor: orange,
                  onChanged: (v) => setDialog(() => active = v),
                ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await FilePicker.pickFiles(
                      type: FileType.any,
                      allowMultiple: true,
                      withData: true,
                    );
                    if (picked == null) return;
                    for (final f in picked.files) {
                      if (f.bytes == null || f.bytes!.length > 50 * 1024 * 1024)
                        continue;
                      try {
                        final u = await api.uploadServiceMedia(
                          bytes: f.bytes!,
                          filename: f.name,
                        );
                        media.add({
                          'file_url': u['file_url'],
                          'file_name': u['file_name'] ?? f.name,
                          'media_type': u['media_type'],
                          'content_type': u['content_type'],
                        });
                      } catch (_) {}
                    }
                    setDialog(() {});
                  },
                  icon: const Icon(Icons.attach_file),
                  label: const Text('Add images, videos, or documents'),
                ),
                ...media.map(
                  (m) => ListTile(
                    dense: true,
                    title: Text(
                      '${m['file_name'] ?? 'Media'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setDialog(() => media.remove(m)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || title.text.trim().isEmpty) return;
    final low = double.tryParse(min.text.trim());
    final high = double.tryParse(max.text.trim());
    if (low == null ||
        low < 0 ||
        (pricing == 'range' && (high == null || high < low))) {
      _notice('Enter valid numeric pricing.');
      return;
    }
    final data = {
      'title': title.text.trim(),
      'category': int.tryParse(category.text.trim()),
      'description': description.text.trim(),
      'service_type': type,
      'coverage_area': coverage.text.trim(),
      'pricing_model': pricing,
      'pricing_min': low,
      'pricing_max': pricing == 'range' ? high : null,
      'media': media,
      'is_active': active,
    };
    try {
      if (item == null)
        await api.createTechnicianService(data);
      else
        await api.updateTechnicianService(item['id'], data);
      if (mounted) {
        setState(() => future = api.technicianServices());
        _notice('Service saved successfully.');
      }
    } catch (e) {
      _notice(
        e is ApiException ? e.message : 'We could not save this service.',
      );
    }
  }

  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 1,
    TextInputType? keyboard,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
  Widget _card(Map item) {
    final media = item['media'] is List ? item['media'] as List : const [];
    final image = media.isNotEmpty && '${media.first['media_type']}' == 'image';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _edit(item),
        leading: image
            ? Image.network(
                api.resolveImageUrl('${media.first['file_url']}'),
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              )
            : const CircleAvatar(
                backgroundColor: Color(0xFFFFE8E0),
                child: Icon(Icons.build_outlined, color: orange),
              ),
        title: Text(
          '${item['title'] ?? 'Service'}',
          style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item['is_active'] == true ? 'Active' : 'Inactive'} • ${item['coverage_area'] ?? 'Coverage not set'}\n${item['description'] ?? ''}',
          maxLines: 3,
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            try {
              await api.deleteTechnicianService(item['id']);
              if (mounted) setState(() => future = api.technicianServices());
            } catch (_) {
              _notice('We could not delete this service.');
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 0),
    appBar: AppBar(
      title: const Text('My Services'),
      foregroundColor: navy,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () => _edit(),
          icon: const Icon(Icons.add, color: orange),
        ),
      ],
    ),
    body: FutureBuilder<dynamic>(
      future: future,
      builder: (_, snap) {
        if (snap.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator(color: orange));
        final items = _items(snap.data);
        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (!verified)
              const Card(
                color: Color(0xFFFFFBEB),
                child: ListTile(
                  leading: Icon(Icons.lock_outline, color: Color(0xFFD97706)),
                  title: Text('Publishing is locked'),
                  subtitle: Text(
                    'Admin verification is required before creating public services.',
                  ),
                ),
              ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(
                  child: Text(
                    'No services yet.',
                    style: TextStyle(color: muted),
                  ),
                ),
              )
            else
              ...items.map((x) => _card(x as Map)),
          ],
        );
      },
    ),
  );
}
