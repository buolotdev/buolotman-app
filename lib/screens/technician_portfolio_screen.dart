import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../attachment_actions.dart';

class TechnicianPortfolioScreen extends StatefulWidget {
  const TechnicianPortfolioScreen({super.key});
  @override
  State<TechnicianPortfolioScreen> createState() => _State();
}

class _State extends State<TechnicianPortfolioScreen> {
  final api = ApiService();
  final title = TextEditingController(),
      description = TextEditingController(),
      category = TextEditingController(),
      location = TextEditingController(),
      value = TextEditingController(),
      completionDate = TextEditingController();
  String? imageUrl;
  PlatformFile? preview;
  bool saving = false;
  List<dynamic> projects = [];
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      muted = Color(0xFF64748B);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Portfolio'),
      backgroundColor: navy,
      foregroundColor: Colors.white,
    ),
    backgroundColor: const Color(0xFFF4F6F8),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Add completed work',
                  style: TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _input('Project title', title),
                _input('Category', category),
                _input('Description', description, lines: 3),
                _input('Location', location),
                _input(
                  'Project value',
                  value,
                  keyboardType: TextInputType.number,
                ),
                _input(
                  'Completion date (YYYY-MM-DD)',
                  completionDate,
                  keyboardType: TextInputType.datetime,
                ),
                if (preview != null)
                  GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: Image.memory(
                          preview!.bytes!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    child: Image.memory(
                      preview!.bytes!,
                      height: 170,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Add project image'),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: orange,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: saving ? null : _save,
                  child: Text(saving ? 'Saving...' : 'Save project'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        FutureBuilder<List<dynamic>>(
          future: api.portfolioItems(),
          builder: (_, snap) {
            final items = snap.data ?? const [];
            if (items.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saved projects',
                  style: TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ...items.map((item) => _project(item)),
              ],
            );
          },
        ),
      ],
    ),
  );
  Widget _input(
    String label,
    TextEditingController c, {
    int lines = 1,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: c,
      maxLines: lines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
  Future<void> _pickFromDevice() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );
    if (!mounted || result == null || result.files.single.bytes == null) return;
    setState(() => preview = result.files.single);
  }

  Future<void> _pickFromGallery() async {
    final file = await AttachmentActions.pickGallery();
    if (!mounted || file == null) return;
    setState(() => preview = file);
  }

  Future<void> _pickFromCamera() async {
    final file = await AttachmentActions.takePhoto(
      context,
      label: 'project image',
    );
    if (!mounted || file == null) return;
    setState(() => preview = file);
  }

  Future<void> _pick() => AttachmentActions.show(
    context,
    label: 'project image',
    hasAttachment: preview != null,
    onDevice: _pickFromDevice,
    onGallery: _pickFromGallery,
    onCamera: _pickFromCamera,
    onRemove: () => setState(() => preview = null),
  );

  Widget _project(dynamic item) {
    final image = '${item['image_url'] ?? ''}';
    return Card(
      elevation: 0,
      child: ListTile(
        leading: image.isEmpty
            ? const Icon(Icons.work_outline, color: orange)
            : Image.network(
                api.resolveImageUrl(image),
                width: 58,
                height: 58,
                fit: BoxFit.cover,
              ),
        title: Text(
          '${item['title'] ?? 'Project'}',
          style: const TextStyle(color: navy, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${item['category'] ?? ''} • ${item['completed_date'] ?? 'Date not provided'}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () async {
            try {
              await api.deletePortfolio(item['id']);
              if (mounted) setState(() {});
            } catch (e) {
              if (mounted)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('We could not delete this project.'),
                  ),
                );
            }
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project title.')),
      );
      return;
    }
    final date = completionDate.text.trim();
    if (date.isNotEmpty && DateTime.tryParse(date) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Completion date must use YYYY-MM-DD.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      if (preview != null)
        imageUrl = await api.uploadPortfolioBytes(
          bytes: preview!.bytes!,
          filename: preview!.name,
        );
      await api.createPortfolio({
        'title': title.text.trim(),
        'description':
            '${description.text.trim()}${location.text.trim().isEmpty ? '' : '\nLocation: ${location.text.trim()}'}',
        'category': category.text.trim(),
        'project_value': value.text.trim().isEmpty
            ? null
            : double.tryParse(value.text.trim()),
        'completed_date': date.isEmpty ? null : date,
        'image_url': imageUrl ?? '',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Portfolio project saved.')),
        );
        title.clear();
        description.clear();
        category.clear();
        location.clear();
        value.clear();
        completionDate.clear();
        setState(() {
          preview = null;
          imageUrl = null;
        });
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'We could not save this project. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }
}
