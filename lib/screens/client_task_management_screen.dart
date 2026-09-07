import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import '../core/api_service.dart';
import 'client_messaging_screen.dart';
import 'client_location_picker_screen.dart';
import 'client_dashboard_screen.dart';
import 'client_navigation_screens.dart';

const taskNavy = Color(0xFF001F3F),
    taskOrange = Color(0xFFFF4500),
    taskMuted = Color(0xFF64748B),
    taskBg = Color(0xFFF5F7FA);
List<dynamic> taskItems(dynamic v) => v is List
    ? v
    : v is Map && v['results'] is List
    ? v['results'] as List
    : const [];

class ClientTasksScreen extends StatefulWidget {
  const ClientTasksScreen({super.key, this.withBottomNavigation = true});
  final bool withBottomNavigation;
  @override
  State<ClientTasksScreen> createState() => _ClientTasksState();
}

class _ClientTasksState extends State<ClientTasksScreen> {
  final api = ApiService();
  List<dynamic> tasks = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final x = await api.myTasks();
      if (mounted)
        setState(() {
          tasks = taskItems(x);
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('My tasks'),
      foregroundColor: taskNavy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: taskBg,
    body: RefreshIndicator(
      onRefresh: _load,
      child: loading
          ? const Center(child: CircularProgressIndicator(color: taskOrange))
          : tasks.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 180),
                Center(
                  child: Text(
                    'No tasks yet.',
                    style: TextStyle(color: taskMuted),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (_, i) {
                final x = tasks[i] is Map ? tasks[i] as Map : {};
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    isThreeLine: true,
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFFE8E0),
                      child: Icon(Icons.assignment_outlined, color: taskOrange),
                    ),
                    title: Text(
                      '${x['title'] ?? 'Task'}',
                      style: const TextStyle(
                        color: taskNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${x['status'] ?? 'open'} • ${x['city'] ?? x['location'] ?? 'Location not specified'}\n${x['bids_count'] ?? 0} proposals',
                      style: const TextStyle(color: taskMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right, color: taskNavy),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ClientTaskDetailScreen(taskId: x['id']),
                        ),
                      );
                      _load();
                    },
                  ),
                );
              },
            ),
    ),
    bottomNavigationBar: widget.withBottomNavigation ? _bottomNavigation(context) : null,
  );

  Widget _bottomNavigation(BuildContext context) => BottomNavigationBar(
    currentIndex: 1,
    selectedItemColor: taskOrange,
    unselectedItemColor: taskMuted,
    onTap: (index) {
      if (index == 1) return;
      final page = index == 0
          ? const ClientDashboardScreen()
          : index == 2
              ? const ClientMessagesScreen()
              : const ClientProfileOverviewScreen();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => page));
    },
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Tasks'),
      BottomNavigationBarItem(icon: Icon(Icons.message_outlined), label: 'Messages'),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
    ],
  );
}

class ClientTaskDetailScreen extends StatefulWidget {
  const ClientTaskDetailScreen({super.key, required this.taskId});
  final dynamic taskId;
  @override
  State<ClientTaskDetailScreen> createState() => _ClientTaskDetailState();
}

class _ClientTaskDetailState extends State<ClientTaskDetailScreen> {
  final api = ApiService();
  Map<String, dynamic> task = {};
  List<dynamic> bids = [];
  bool loading = true, acting = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await Future.wait<dynamic>([
        api.task(widget.taskId),
        api.taskBids(widget.taskId),
      ]);
      if (mounted)
        setState(() {
          task = v[0] is Map ? Map<String, dynamic>.from(v[0]) : {};
          bids = taskItems(v[1]);
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  void _notice(String x, {bool error = true}) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: error ? Colors.red.shade700 : taskNavy,
          content: Text(x),
        ),
      );
  }

  Future<void> _cancel() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Cancel task?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (yes != true) return;
    setState(() => acting = true);
    try {
      await api.cancelTask(widget.taskId);
      _notice('Task cancelled.', error: false);
      await _load();
    } catch (e) {
      _notice('$e');
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _complete() async {
    setState(() => acting = true);
    try {
      await api.completeTask(widget.taskId);
      _notice('Task marked completed.', error: false);
      await _load();
    } catch (e) {
      _notice('$e');
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _bidAction(dynamic id, bool accept) async {
    setState(() => acting = true);
    try {
      if (accept) {
        final yes = await showDialog<bool>(
          context: context,
          builder: (d) => AlertDialog(
            title: const Text('Accept proposal?'),
            content: const Text(
              'The task will move to in progress. Payment/escrow is the next step.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d),
                child: const Text('Back'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(d, true),
                child: const Text('Accept'),
              ),
            ],
          ),
        );
        if (yes != true) return;
        await api.acceptBid(id);
        _notice('Proposal accepted.', error: false);
      } else {
        await api.rejectBid(id);
        _notice('Proposal rejected.', error: false);
      }
      await _load();
    } catch (e) {
      _notice('$e');
    } finally {
      if (mounted) setState(() => acting = false);
    }
  }

  Future<void> _messageTech(dynamic id) async {
    if (id == null) return _notice('Technician information is unavailable.');
    try {
      await api.createConversation(id, taskId: widget.taskId);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ClientMessagesScreen(taskId: widget.taskId, participantId: id)));
    } catch (e) {
      _notice('$e');
    }
  }

  Future<void> _edit() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ClientTaskEditScreen(task: task)),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: taskOrange)),
      );
    final status = '${task['status'] ?? 'open'}';
    final attachments = task['attachments'] is List
        ? task['attachments'] as List
        : const [];
    final lat = double.tryParse('${task['latitude'] ?? ''}');
    final lng = double.tryParse('${task['longitude'] ?? ''}');
    final skills = task['skills_list'] is List
        ? task['skills_list'] as List
        : task['skills'] is List
        ? task['skills'] as List
        : const [];
    final contacts = task['contact_methods'] is List
        ? task['contact_methods'] as List
        : const [];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task details'),
        foregroundColor: taskNavy,
        backgroundColor: Colors.white,
        actions: [
          if (status == 'open' || status == 'draft')
            IconButton(
              onPressed: _edit,
              icon: const Icon(Icons.edit_outlined, color: taskOrange),
            ),
        ],
      ),
      backgroundColor: taskBg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _card('${task['title'] ?? 'Task'}', [
              Row(children: [
                _pill(status),
                const Spacer(),
                if (task['created_at'] != null)
                  Text(_date(task['created_at']), style: const TextStyle(color: taskMuted, fontSize: 12)),
              ]),
              const SizedBox(height: 16),
              const Text('Description', style: TextStyle(color: taskNavy, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text('${task['description'] ?? 'No description provided.'}', style: const TextStyle(color: taskMuted, height: 1.5)),
              const SizedBox(height: 18),
              _info('Category', _categoryLabel()),
              _info('Budget', _budgetLabel()),
              _info('Urgency', _label(task['urgency'], fallback: 'Standard')),
              _info('Service type', _label(task['service_type'], fallback: 'On-site')),
            ]),
            _card('Requirements and logistics', [
              _info('City', '${task['city'] ?? 'Not specified'}'),
              _info('Address', '${task['location'] ?? 'Pinned location'}'),
              _info('Schedule', '${task['schedule'] ?? 'Flexible'}'),
              _info('Deadline', '${task['deadline'] ?? 'Not specified'}'),
              _info('Materials', task['materials_provided'] == true ? 'Provided by client' : 'Technician to provide'),
              _info('Contact', contacts.isEmpty ? 'In-app messaging' : contacts.map((x) => _label(x)).join(', ')),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text('Required skills', style: TextStyle(color: taskNavy, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Wrap(spacing: 8, runSpacing: 8, children: skills.map((x) => _tag('${x is Map ? x['name'] ?? x['title'] ?? '' : x}')).toList()),
              ],
            ]),
            if (lat != null && lng != null)
              _card('Pinned service location', [
                const Text('This is the exact location selected on the map.', style: TextStyle(color: taskMuted)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    height: 210,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(target: LatLng(lat, lng), zoom: 15),
                      markers: {Marker(markerId: const MarkerId('task-location'), position: LatLng(lat, lng))},
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _info('Coordinates', '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'),
              ]),
            if (attachments.isNotEmpty)
              _card(
                'Attachments (${attachments.length})',
                attachments
                    .map(_attachment)
                    .toList(),
              ),
            _card(
              'Proposals (${bids.length})',
              bids.isEmpty
                  ? [
                      const Text(
                        'No proposals yet.',
                        style: TextStyle(color: taskMuted),
                      ),
                    ]
                  : bids.map(_bid).toList(),
            ),
            _card('Status actions', [
              if (status == 'open' ||
                  status == 'draft' ||
                  status == 'in_progress')
                OutlinedButton.icon(
                  onPressed: acting ? null : _cancel,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel task'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              if (status == 'in_progress')
                ElevatedButton.icon(
                  onPressed: acting ? null : _complete,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: taskOrange,
                    foregroundColor: Colors.white,
                  ),
                ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: taskNavy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    ),
  );
  Widget _info(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: taskMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: taskNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
  String _label(dynamic value, {String fallback = 'Not specified'}) {
    final text = '${value ?? ''}'.trim();
    if (text.isEmpty) return fallback;
    return text.replaceAll('_', ' ').split(' ').map((x) => x.isEmpty ? x : '${x[0].toUpperCase()}${x.substring(1)}').join(' ');
  }
  String _categoryLabel() {
    final named = task['category_name'];
    if (named != null && '$named'.trim().isNotEmpty) return '$named';
    final raw = task['category'];
    if (raw is Map) return _label(raw['name'] ?? raw['title']);
    return _label(raw);
  }
  String _budgetLabel() {
    final min = task['budget_min'];
    final max = task['budget_max'];
    if (min == null && max == null) return 'Not specified';
    if (max == null || '$max' == '$min') return '$min XOF';
    return '$min - $max XOF';
  }
  String _date(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    return parsed == null ? '$value' : '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
  }
  Widget _tag(String text) => Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7), decoration: BoxDecoration(color: const Color(0xFFFFE8E0), borderRadius: BorderRadius.circular(20)), child: Text(text, style: const TextStyle(color: taskNavy, fontWeight: FontWeight.w700, fontSize: 12)));
  Widget _attachment(dynamic raw) {
    final a = raw is Map ? raw : <String, dynamic>{};
    final name = '${a['file_name'] ?? 'Attachment'}';
    final url = api.resolveImageUrl('${a['file_url'] ?? a['url'] ?? ''}');
    final contentType = '${a['content_type'] ?? ''}'.toLowerCase();
    final image = contentType.startsWith('image/') || ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(name.toLowerCase().split('.').last);
    if (!image || url.isEmpty) return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.insert_drive_file_outlined, color: taskOrange), title: Text(name), subtitle: Text(_label(a['file_type'], fallback: 'File'), style: const TextStyle(color: taskMuted)));
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: InteractiveViewer(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(40),
                child: Icon(Icons.broken_image_outlined, size: 48),
              ),
            ),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                url,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 150,
                  child: Center(child: Icon(Icons.broken_image_outlined, color: taskMuted)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(color: taskNavy, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
  Widget _pill(String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFFFE8E0),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      value.replaceAll('_', ' ').toUpperCase(),
      style: const TextStyle(
        color: taskOrange,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    ),
  );
  Widget _bid(dynamic raw) {
    final b = raw is Map ? raw : <String, dynamic>{};
    final accepted = '${b['status']}' == 'accepted';
    return Card(
      color: const Color(0xFFF8FAFC),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${b['technician_name'] ?? b['bidder'] ?? 'Technician'}',
              style: const TextStyle(
                color: taskNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${b['amount'] ?? '—'} ${b['amount_type'] ?? ''}',
              style: const TextStyle(
                color: taskOrange,
                fontWeight: FontWeight.w700,
              ),
            ),
            if ('${b['message'] ?? ''}'.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  '${b['message']}',
                  style: const TextStyle(color: taskMuted),
                ),
              ),
            Wrap(
              spacing: 8,
              children: [
                if (!accepted && task['status'] == 'open')
                  TextButton(
                    onPressed: acting ? null : () => _bidAction(b['id'], true),
                    child: const Text('Accept'),
                  ),
                if (!accepted && task['status'] == 'open')
                  TextButton(
                    onPressed: acting ? null : () => _bidAction(b['id'], false),
                    child: const Text('Reject'),
                  ),
                if (b['technician'] != null)
                  TextButton(
                    onPressed: () => _messageTech(b['technician']),
                    child: const Text('Message'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClientTaskEditScreen extends StatefulWidget {
  const ClientTaskEditScreen({super.key, required this.task});
  final Map<String, dynamic> task;
  @override
  State<ClientTaskEditScreen> createState() => _ClientTaskEditState();
}

class _ClientTaskEditState extends State<ClientTaskEditScreen> {
  final api = ApiService();
  late final TextEditingController title,
      description,
      city,
      location,
      min,
      max,
      schedule,
      skills;
  List<dynamic> categories = [];
  List<PlatformFile> attachments = [];
  int? category;
  double? latitude, longitude;
  String urgency = 'standard', serviceType = 'onsite', deadline = '';
  Set<String> contacts = {'in-app'};
  bool materials = false;
  bool saving = false;
  @override
  void initState() {
    super.initState();
    final t = widget.task;
    title = TextEditingController(text: '${t['title'] ?? ''}');
    description = TextEditingController(text: '${t['description'] ?? ''}');
    city = TextEditingController(text: '${t['city'] ?? ''}');
    location = TextEditingController(text: '${t['location'] ?? ''}');
    min = TextEditingController(text: '${t['budget_min'] ?? ''}');
    max = TextEditingController(
      text: '${t['budget_max'] ?? t['budget_min'] ?? ''}',
    );
    schedule = TextEditingController(text: '${t['schedule'] ?? ''}');
    skills = TextEditingController(text: _skillText(t['skills_list'] ?? t['skills']));
    final rawCategory = t['category_id'] ?? t['category'];
    category = rawCategory is Map ? int.tryParse('${rawCategory['id']}') : int.tryParse('$rawCategory');
    latitude = double.tryParse('${t['latitude'] ?? ''}');
    longitude = double.tryParse('${t['longitude'] ?? ''}');
    urgency = '${t['urgency'] ?? urgency}';
    serviceType = '${t['service_type'] ?? serviceType}';
    deadline = '${t['deadline'] ?? ''}';
    materials = t['materials_provided'] == true;
    if (t['contact_methods'] is List && (t['contact_methods'] as List).isNotEmpty) contacts = (t['contact_methods'] as List).map((x) => '$x').toSet();
    _loadCategories();
  }

  String _skillText(dynamic value) => value is List ? value.map((x) => x is Map ? '${x['name'] ?? x['title'] ?? ''}' : '$x').where((x) => x.trim().isNotEmpty).join(', ') : '';

  Future<void> _loadCategories() async {
    try {
      final x = await api.serviceCategories();
      if (mounted) setState(() => categories = x);
    } catch (_) {}
  }

  @override
  void dispose() {
    for (final c in [title, description, city, location, min, max, schedule, skills])
      c.dispose();
    super.dispose();
  }

  InputDecoration _dec(String x) => InputDecoration(
    labelText: x,
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
    TextInputType? type,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: c,
      maxLines: lines,
      keyboardType: type,
      decoration: _dec(label),
    ),
  );
  Future<void> _pickDate() async {
    final initial = DateTime.tryParse(deadline) ?? DateTime.now();
    final picked = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)), initialDate: initial.isBefore(DateTime.now()) ? DateTime.now() : initial);
    if (picked != null) setState(() => deadline = '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}');
  }
  Future<void> _pickMapLocation() async {
    final picked = await Navigator.push<SelectedTaskLocation>(context, MaterialPageRoute(builder: (_) => ClientLocationPickerScreen(initialLatitude: latitude, initialLongitude: longitude)));
    if (picked == null || !mounted) return;
    setState(() { latitude = picked.latitude; longitude = picked.longitude; if ((picked.address ?? '').isNotEmpty) location.text = picked.address!; if ((picked.city ?? '').isNotEmpty) city.text = picked.city!; });
  }
  Future<void> _pickAttachments() async {
    final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'], allowMultiple: true, withData: true);
    if (result == null) return;
    final valid = result.files.where((f) => f.bytes != null && f.size <= 25 * 1024 * 1024).toList();
    setState(() => attachments = [...attachments, ...valid]);
  }
  Future<void> _save() async {
    final low = double.tryParse(min.text.trim()),
        high = double.tryParse(max.text.trim());
    if (title.text.trim().isEmpty ||
        description.text.trim().isEmpty ||
        low == null ||
        high == null ||
        high < low)
      return _notice('Enter a valid title, description, and budget range.');
    setState(() => saving = true);
    try {
      await api.updateTask(widget.task['id'], {
        'title': title.text.trim(),
        'description': description.text.trim(),
        'category': category,
        'budget_min': low,
        'budget_max': high,
        'budget_mode': 'fixed',
        'urgency': urgency,
        'service_type': serviceType,
        'location': location.text.trim(),
        'city': city.text.trim(),
        'schedule': schedule.text.trim(),
        'deadline': deadline.isEmpty ? null : deadline,
        'latitude': latitude,
        'longitude': longitude,
        'materials_provided': materials,
        'contact_methods': contacts.toList(),
        'skills': skills.text.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toList(),
      });
      for (final file in attachments) {
        if (file.bytes != null) await api.uploadTaskAttachmentBytes(taskId: widget.task['id'], bytes: file.bytes!, filename: file.name);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _notice('$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _notice(String x) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(x)));
  Widget _contact(String value, String label) {
    final selected = contacts.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFFFFE0D6),
      checkmarkColor: taskOrange,
      onSelected: (enabled) => setState(() {
        if (enabled) {
          contacts.add(value);
        } else if (contacts.length > 1) {
          contacts.remove(value);
        }
      }),
    );
  }
  Widget _newAttachment(PlatformFile file) {
    final isPdf = file.name.toLowerCase().endsWith('.pdf');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: isPdf
          ? const Icon(Icons.picture_as_pdf, color: taskOrange)
          : SizedBox(
              width: 48,
              height: 48,
              child: Image.memory(Uint8List.fromList(file.bytes!), fit: BoxFit.cover),
            ),
      title: Text(file.name),
      trailing: IconButton(
        onPressed: () => setState(() => attachments.remove(file)),
        icon: const Icon(Icons.close),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Edit task'),
      foregroundColor: taskNavy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: taskBg,
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _field(title, 'Task title'),
        _field(description, 'Description', lines: 5),
        DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: category,
          decoration: _dec('Category'),
          items: categories
              .map(
                (x) => DropdownMenuItem<int>(
                  value: x is Map ? int.tryParse('${x['id']}') : null,
                  child: Text('${x is Map ? x['name'] ?? '' : x}'),
                ),
              )
              .toList(),
          onChanged: (v) => setState(() => category = v),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _field(
                min,
                'Minimum budget',
                type: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _field(
                max,
                'Maximum budget',
                type: const TextInputType.numberWithOptions(decimal: true),
              ),
            ),
          ],
        ),
        _field(skills, 'Required skills (comma separated)'),
        DropdownButtonFormField<String>(
          initialValue: urgency,
          decoration: _dec('Urgency'),
          items: const [
            DropdownMenuItem(
              value: 'standard',
              child: Text('Standard / Flexible'),
            ),
            DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
          ],
          onChanged: (v) => setState(() => urgency = v ?? urgency),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: serviceType,
          decoration: _dec('Service type'),
          items: const [
            DropdownMenuItem(value: 'onsite', child: Text('On-site')),
            DropdownMenuItem(value: 'remote', child: Text('Remote')),
            DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
          ],
          onChanged: (v) => setState(() => serviceType = v ?? serviceType),
        ),
        const SizedBox(height: 12),
        _field(city, 'City'),
        OutlinedButton.icon(onPressed: _pickMapLocation, icon: const Icon(Icons.pin_drop_outlined), label: Text(latitude == null && location.text.trim().isEmpty ? 'Choose exact location on map' : 'Update pinned location'), style: OutlinedButton.styleFrom(foregroundColor: taskOrange, side: const BorderSide(color: taskOrange), minimumSize: const Size.fromHeight(48))),
        const SizedBox(height: 16),
        if (latitude != null && longitude != null) Padding(padding: const EdgeInsets.only(top: 10, bottom: 12), child: TextField(controller: location, readOnly: true, decoration: _dec('Exact pinned location').copyWith(prefixIcon: const Icon(Icons.location_on_outlined)))),
        if (latitude == null || longitude == null) _field(location, 'Location / address'),
        const SizedBox(height: 4),
        _field(schedule, 'Time preference / schedule'),
        OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.event), label: Text(deadline.isEmpty ? 'Choose deadline' : 'Deadline: $deadline'), style: OutlinedButton.styleFrom(foregroundColor: taskOrange, side: const BorderSide(color: taskOrange), minimumSize: const Size.fromHeight(48))),
        const SizedBox(height: 10),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Materials provided by client', style: TextStyle(color: taskNavy)), value: materials, activeThumbColor: taskOrange, onChanged: (v) => setState(() => materials = v)),
        const SizedBox(height: 8),
        const Text('Contact preferences', style: TextStyle(color: taskNavy, fontSize: 16, fontWeight: FontWeight.w700)),
        Wrap(spacing: 8, children: [_contact('in-app', 'In-app messaging'), _contact('phone', 'Phone call'), _contact('whatsapp', 'WhatsApp')]),
        const SizedBox(height: 12),
        if (widget.task['attachments'] is List && (widget.task['attachments'] as List).isNotEmpty) ...[
          const Text('Existing attachments', style: TextStyle(color: taskNavy, fontWeight: FontWeight.w700)),
          ...(widget.task['attachments'] as List).map((a) => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.attach_file, color: taskOrange), title: Text('${a['file_name'] ?? 'Attachment'}'))),
        ],
        OutlinedButton.icon(onPressed: _pickAttachments, icon: const Icon(Icons.attach_file), label: const Text('Add attachments'), style: OutlinedButton.styleFrom(foregroundColor: taskOrange, side: const BorderSide(color: taskOrange), minimumSize: const Size.fromHeight(48))),
        ...attachments.map(_newAttachment),
        const SizedBox(height: 24),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: taskOrange,
              foregroundColor: Colors.white,
            ),
            child: Text(saving ? 'Saving...' : 'Save changes'),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
