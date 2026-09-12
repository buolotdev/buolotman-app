import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_service.dart';
import '../verification_utils.dart';
import 'client_location_picker_screen.dart';
import '../discard_changes.dart';
import '../attachment_actions.dart';

class ClientTaskCreateScreen extends StatefulWidget {
  const ClientTaskCreateScreen({super.key});
  @override
  State<ClientTaskCreateScreen> createState() => _CreateTaskState();
}

class _CreateTaskState extends State<ClientTaskCreateScreen> {
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      muted = Color(0xFF64748B),
      bg = Color(0xFFF5F7FA);
  final api = ApiService();
  final title = TextEditingController(),
      description = TextEditingController(),
      city = TextEditingController(),
      location = TextEditingController(),
      budgetMin = TextEditingController(),
      budgetMax = TextEditingController(),
      skills = TextEditingController(),
      schedule = TextEditingController();
  List<dynamic> categories = [];
  List<dynamic> subcategories = [];
  List<PlatformFile> attachments = [];
  int? category, subcategory;
  double? latitude, longitude;
  String urgency = 'standard', serviceType = 'onsite', deadline = '';
  Set<String> contacts = {'in-app'};
  bool materials = false, saving = false, verified = false, checking = true;
  String? loadError, categoryError;
  bool _dirty = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      title,
      description,
      city,
      location,
      budgetMin,
      budgetMax,
      skills,
      schedule,
    ])
      c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        checking = true;
        loadError = null;
      });
    }
    try {
      // Verification comes from /auth/me/. A secondary categories failure
      // must never be presented as an account-verification failure.
      final p = await api.profile();
      List<dynamic> list = const [];
      try {
        list = await api.serviceCategories();
        if (mounted) setState(() => categoryError = null);
      } catch (error) {
        if (mounted) {
          setState(
            () => categoryError = error
                .toString()
                .replaceFirst('Exception: ', '')
                .trim(),
          );
        }
      }
      if (mounted)
        setState(() {
          verified = isVerifiedProfile(p);
          categories = list;
          checking = false;
          loadError = null;
        });
    } catch (error) {
      if (mounted) {
        setState(() {
          checking = false;
          verified = false;
          loadError = error.toString().replaceFirst('Exception: ', '').trim();
        });
      }
    }
  }

  void _notice(String text, {bool error = true}) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: error ? Colors.red.shade700 : navy,
          content: Text(text),
        ),
      );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: DateTime.now(),
    );
    if (d != null)
      setState(() {
        deadline =
            '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        _dirty = true;
      });
  }

  Future<void> _pickMapLocation() async {
    final s = await Navigator.push<SelectedTaskLocation>(
      context,
      MaterialPageRoute(
        builder: (_) => ClientLocationPickerScreen(
          initialLatitude: latitude,
          initialLongitude: longitude,
        ),
      ),
    );
    if (s == null || !mounted) return;
    setState(() {
      latitude = s.latitude;
      longitude = s.longitude;
      if ((s.address ?? '').isNotEmpty) location.text = s.address!;
      if ((s.city ?? '').isNotEmpty) city.text = s.city!;
    });
  }

  Future<void> _pickAttachments() async {
    final r = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
      allowMultiple: true,
      withData: true,
    );
    if (r == null) return;
    final valid = r.files
        .where((f) => f.bytes != null && f.size <= 25 * 1024 * 1024)
        .toList();
    if (valid.length != r.files.length)
      _notice(
        'Only JPG, PNG, WEBP, GIF, or PDF files up to 25 MB are allowed.',
      );
    setState(() {
      attachments = [...attachments, ...valid];
      _dirty = true;
    });
  }

  Future<void> _takeTaskPhoto() async {
    final file = await AttachmentActions.takePhoto(
      context,
      label: 'task attachment',
    );
    if (file == null || !mounted) return;
    if (file.size > 25 * 1024 * 1024) {
      _notice('Files must be 25 MB or smaller.');
      return;
    }
    setState(() {
      attachments = [...attachments, file];
      _dirty = true;
    });
  }

  Future<void> _pickTaskGallery() async {
    final file = await AttachmentActions.pickGallery();
    if (file == null || !mounted) return;
    if (file.size > 25 * 1024 * 1024) {
      _notice('Files must be 25 MB or smaller.');
      return;
    }
    setState(() {
      attachments = [...attachments, file];
      _dirty = true;
    });
  }

  Future<void> _showAttachmentActions() => AttachmentActions.show(
    context,
    label: 'task attachment',
    hasAttachment: attachments.isNotEmpty,
    onDevice: _pickAttachments,
    onGallery: _pickTaskGallery,
    onCamera: _takeTaskPhoto,
    onRemove: () => setState(() {
      attachments.clear();
      _dirty = true;
    }),
  );

  Future<void> _selectCategory(int? value) async {
    final selected = categories.whereType<Map>().cast<Map?>().firstWhere(
      (item) => item?['id']?.toString() == value?.toString(),
      orElse: () => null,
    );
    final nested = selected?['subcategories'];
    setState(() {
      category = value;
      subcategory = null;
      subcategories = nested is List ? nested : const [];
      _dirty = true;
    });
    if (value == null || subcategories.isNotEmpty) return;
    try {
      final loaded = await api.serviceSubcategories(value);
      if (mounted && category == value) {
        setState(() => subcategories = loaded);
      }
    } catch (_) {
      // The category remains selectable even when its optional child request
      // is unavailable; the backend contract does not support a fake fallback.
    }
  }

  Future<void> _save() async {
    final min = double.tryParse(budgetMin.text.trim()),
        max = double.tryParse(
          budgetMax.text.trim().isEmpty
              ? budgetMin.text.trim()
              : budgetMax.text.trim(),
        );
    if (title.text.trim().isEmpty ||
        description.text.trim().isEmpty ||
        category == null)
      return _notice('Enter a title, description, and select a category.');
    if (min == null || min <= 0 || max == null || max < min)
      return _notice('Enter a valid budget range.');
    final selectedSubcategoryName = subcategories
        .whereType<Map>()
        .where((item) => item['id']?.toString() == subcategory?.toString())
        .map((item) => '${item['name'] ?? item['title'] ?? ''}'.trim())
        .firstWhere((name) => name.isNotEmpty, orElse: () => '');
    final requestedSkills = skills.text
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    if (selectedSubcategoryName.isNotEmpty &&
        !requestedSkills.contains(selectedSubcategoryName)) {
      requestedSkills.insert(0, selectedSubcategoryName);
    }
    setState(() => saving = true);
    try {
      final r = await api.createTask({
        'title': title.text.trim(),
        'description': description.text.trim(),
        'category': category,
        'budget_min': min,
        'budget_max': max,
        'budget_mode': 'fixed',
        'urgency': urgency,
        'service_type': serviceType,
        'location': location.text.trim(),
        'city': city.text.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'schedule': schedule.text.trim(),
        'deadline': deadline.isEmpty ? null : deadline,
        'materials_provided': materials,
        'contact_methods': contacts.toList(),
        // The website persists the selected subcategory as a skill under the
        // selected category. Keep that same contract for mobile-created tasks.
        'skills': requestedSkills,
        'status': 'open',
      });
      final id = r is Map ? int.tryParse('${r['id']}') : null;
      if (id != null)
        for (final f in attachments)
          await api.uploadTaskAttachmentBytes(
            taskId: id,
            bytes: f.bytes!,
            filename: f.name,
          );
      if (mounted) {
        _notice('Task posted successfully.', error: false);
        Navigator.pop(context, true);
      }
    } catch (_) {
      _notice(
        'We could not post your task. Please check your details and attachments.',
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  InputDecoration _dec(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
  );
  Widget _field(
    TextEditingController c,
    String label, {
    int lines = 1,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      maxLines: lines,
      keyboardType: keyboard,
      inputFormatters: formatters,
      onChanged: (_) => setState(() => _dirty = true),
      decoration: _dec(label),
    ),
  );
  Widget _contact(String value, String label) {
    final selected = contacts.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFFFE0D6),
      checkmarkColor: orange,
      onSelected: (v) => setState(() {
        _dirty = true;
        if (v)
          contacts.add(value);
        else if (contacts.length > 1)
          contacts.remove(value);
      }),
    );
  }

  Widget _attachment(PlatformFile f) {
    final image = !f.name.toLowerCase().endsWith('.pdf');
    return Card(
      child: ListTile(
        leading: image
            ? SizedBox(
                width: 54,
                height: 54,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    Uint8List.fromList(f.bytes!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : const Icon(Icons.picture_as_pdf, color: orange),
        title: Text(f.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${(f.size / 1024 / 1024).toStringAsFixed(2)} MB'),
        trailing: IconButton(
          onPressed: () => setState(() => attachments.remove(f)),
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (checking)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: orange)),
      );
    final money = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))];
    if (loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Post a task'),
          foregroundColor: navy,
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Retry',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        backgroundColor: bg,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, color: orange, size: 36),
                const SizedBox(height: 12),
                const Text(
                  'We could not load your account verification status.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  loadError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final categoryItems = categories
        .whereType<Map>()
        .map((x) {
          final id = x['id'] is int
              ? x['id'] as int
              : int.tryParse('${x['id'] ?? ''}');
          final name = '${x['name'] ?? x['title'] ?? ''}'.trim();
          return (id: id, name: name);
        })
        .where((x) => x.id != null && x.name.isNotEmpty)
        .toList();
    final selectedCategory = categoryItems.any((x) => x.id == category)
        ? category
        : null;
    return PopScope(
      canPop: !_dirty && !saving,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || saving || !_dirty) return;
        if (await confirmDiscardChanges(
              context,
              message: 'Your task draft will be lost if you leave this page.',
            ) &&
            context.mounted) {
          Navigator.of(context).pop(result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Post a task'),
          foregroundColor: navy,
          backgroundColor: Colors.white,
          actions: [
            IconButton(
              tooltip: 'Refresh verification status',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        backgroundColor: bg,
        body: !verified
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'Task posting unlocks after your account is verified by an administrator.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted, fontSize: 16),
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                children: [
                  _field(title, 'Task title'),
                  _field(description, 'Describe the work', lines: 5),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: selectedCategory,
                    decoration: _dec('Category').copyWith(
                      helperText: categoryError == null && categoryItems.isEmpty
                          ? 'No categories are available yet.'
                          : categoryError,
                      helperStyle: const TextStyle(color: muted, fontSize: 12),
                    ),
                    items: categoryItems
                        .map(
                          (x) => DropdownMenuItem<int>(
                            value: x.id,
                            child: Text(
                              x.name,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: _selectCategory,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: subcategory,
                    decoration: _dec('Subcategory').copyWith(
                      helperText: category == null
                          ? 'Select a category first.'
                          : subcategories.isEmpty
                          ? 'No subcategories are available for this category.'
                          : null,
                    ),
                    items: subcategories
                        .whereType<Map>()
                        .map((x) {
                          final id = x['id'] is int
                              ? x['id'] as int
                              : int.tryParse('${x['id'] ?? ''}');
                          final name = '${x['name'] ?? x['title'] ?? ''}'
                              .trim();
                          return DropdownMenuItem<int>(
                            value: id,
                            child: Text(name, overflow: TextOverflow.ellipsis),
                          );
                        })
                        .where((item) => item.value != null)
                        .toList(),
                    onChanged: category == null || subcategories.isEmpty
                        ? null
                        : (value) => setState(() {
                            subcategory = value;
                            _dirty = true;
                          }),
                  ),
                  const SizedBox(height: 12),
                  _field(skills, 'Required skills (comma separated)'),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          budgetMin,
                          'Minimum budget',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          formatters: money,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _field(
                          budgetMax,
                          'Maximum budget',
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          formatters: money,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: urgency,
                    decoration: _dec('Urgency'),
                    items: const [
                      DropdownMenuItem(
                        value: 'standard',
                        child: Text('Standard / Flexible'),
                      ),
                      DropdownMenuItem(
                        value: 'urgent',
                        child: Text('Urgent (within 24 hours)'),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      urgency = v ?? urgency;
                      _dirty = true;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: serviceType,
                    decoration: _dec('Service type'),
                    items: const [
                      DropdownMenuItem(value: 'onsite', child: Text('On-site')),
                      DropdownMenuItem(value: 'remote', child: Text('Remote')),
                      DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                    ],
                    onChanged: (v) => setState(() {
                      serviceType = v ?? serviceType;
                      _dirty = true;
                    }),
                  ),
                  const SizedBox(height: 12),
                  _field(city, 'City'),
                  OutlinedButton.icon(
                    onPressed: _pickMapLocation,
                    icon: const Icon(Icons.pin_drop_outlined),
                    label: Text(
                      latitude == null
                          ? 'Choose exact location on map'
                          : 'Location pinned',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orange,
                      side: const BorderSide(color: orange),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  if (latitude != null && location.text.trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 12),
                      child: TextField(
                        controller: location,
                        readOnly: true,
                        decoration: _dec('Exact pinned location').copyWith(
                          prefixIcon: const Icon(Icons.location_on_outlined),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  _field(schedule, 'Time preference / schedule'),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.event),
                    label: Text(
                      deadline.isEmpty
                          ? 'Choose deadline'
                          : 'Deadline: $deadline',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orange,
                      side: const BorderSide(color: orange),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Materials provided by client',
                      style: TextStyle(color: navy),
                    ),
                    value: materials,
                    activeThumbColor: orange,
                    onChanged: (v) => setState(() {
                      materials = v;
                      _dirty = true;
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Contact preferences',
                    style: TextStyle(
                      color: navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    children: [
                      _contact('in-app', 'In-app messaging'),
                      _contact('phone', 'Phone call'),
                      _contact('whatsapp', 'WhatsApp'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _showAttachmentActions,
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach files'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: orange,
                      side: const BorderSide(color: orange),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                  ...attachments.map(_attachment),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(saving ? 'Posting...' : 'Post task'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
