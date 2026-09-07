import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'technician_navigation.dart';

class TechnicianProfileScreen extends StatefulWidget {
  const TechnicianProfileScreen({super.key});
  @override State<TechnicianProfileScreen> createState() => _TechnicianProfileScreenState();
}

class _TechnicianProfileScreenState extends State<TechnicianProfileScreen> {
  static const navy = Color(0xFF001F3F), orange = Color(0xFFFF4500), muted = Color(0xFF64748B);
  static const maxBytes = 25 * 1024 * 1024;
  final api = ApiService();
  final Map<String, PlatformFile> selected = {};
  List<dynamic> documents = [];
  bool loading = true, submitting = false;
  final slots = const [
    ('front', 'National ID — front', 'Front side of your national ID or passport.', 'id', Icons.badge_outlined),
    ('back', 'National ID — back', 'Back side of your national ID or passport.', 'id', Icons.badge_outlined),
    ('certificate', 'Professional certificate / license', 'Trade license, diploma, or professional certificate.', 'certificate', Icons.workspace_premium_outlined),
    ('selfie', 'Selfie / photo verification', 'Clear recent selfie. Backend stores this as an ID document.', 'id', Icons.camera_front_outlined),
  ];
  @override void initState() { super.initState(); _load(); }
  Future<void> _load() async { try { documents = await api.technicianDocuments(); } catch (_) {} if (mounted) setState(() => loading = false); }
  dynamic _doc(String key) { final words = key == 'front' ? ['front'] : key == 'back' ? ['back'] : key == 'certificate' ? ['certificate', 'license', 'trade'] : ['selfie', 'photo', 'portrait']; for (final d in documents) { final title = '${d['title'] ?? ''}'.toLowerCase(); if (words.any(title.contains)) return d; } return null; }
  bool _image(String name) => ['jpg', 'jpeg', 'png', 'webp', 'gif'].contains(name.toLowerCase().split('.').last);
  void _notice(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _pick(String key) async { final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'], withData: true); if (!mounted || result == null || result.files.isEmpty) return; final file = result.files.single; if (file.bytes == null) { _notice('Could not read that file. Please choose it again.'); return; } if (key == 'selfie' && !_image(file.name)) { _notice('Selfie verification must be an image.'); return; } if (file.bytes!.length > maxBytes) { _notice('This file is too large. The maximum is 25 MB.'); return; } setState(() => selected[key] = file); }
  Future<void> _submit() async { if (selected.isEmpty) { _notice('Attach at least one document first.'); return; } setState(() => submitting = true); try { for (final slot in slots) { final file = selected[slot.$1]; if (file == null) continue; final old = _doc(slot.$1); if (old != null && old['id'] != null) await api.deleteTechnicianDocument(old['id']); final upload = await api.uploadTechnicianDocumentBytes(bytes: file.bytes!, filename: file.name); final url = upload['file_url']; if (url is! String || url.isEmpty) throw const ApiException('Upload returned no file URL.', 500); await api.createTechnicianDocument(title: slot.$2, documentType: slot.$4, fileUrl: url); } selected.clear(); documents = await api.technicianDocuments(); if (mounted) { setState(() {}); _notice('Documents submitted for admin review.'); } } catch (e) { if (mounted) _notice(e is ApiException ? e.message : 'We could not submit the documents. Please try again.'); } finally { if (mounted) setState(() => submitting = false); } }
  Future<void> _delete(dynamic doc) async { final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: const Text('Delete document?'), content: const Text('You can upload a replacement later.'), actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete'))])); if (ok != true) return; try { await api.deleteTechnicianDocument(doc['id']); documents = await api.technicianDocuments(); if (mounted) setState(() {}); } catch (e) { if (mounted) _notice(e is ApiException ? e.message : 'We could not delete this document.'); } }
  @override Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFFF4F6F8), bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 3), appBar: AppBar(title: const Text('Verification'), backgroundColor: Colors.white, foregroundColor: navy, elevation: 0), body: loading ? const Center(child: CircularProgressIndicator(color: orange)) : ListView(padding: const EdgeInsets.all(18), children: [_status(), const SizedBox(height: 18), const Text('Verification documents', style: TextStyle(color: navy, fontSize: 22, fontWeight: FontWeight.w800)), const SizedBox(height: 6), const Text('Each document is reviewed separately by an administrator.', style: TextStyle(color: muted)), const SizedBox(height: 14), ...slots.map(_slot), const SizedBox(height: 8), FilledButton(onPressed: submitting ? null : _submit, style: FilledButton.styleFrom(backgroundColor: orange, minimumSize: const Size.fromHeight(52)), child: Text(submitting ? 'Submitting...' : 'Submit for admin review')), const SizedBox(height: 18), const Text('Accepted: JPG, JPEG, PNG, WEBP, GIF, PDF • Maximum 25 MB per file', textAlign: TextAlign.center, style: TextStyle(color: muted, fontSize: 12))]));
  Widget _status() { return FutureBuilder<Map<String, dynamic>>(future: api.profile(), builder: (_, snap) { final data = snap.data ?? {}; final verified = data['is_verified'] == true || data['technician_profile']?['is_verified'] == true; return Card(elevation: 0, child: Padding(padding: const EdgeInsets.all(18), child: Row(children: [Icon(verified ? Icons.verified : Icons.hourglass_top, color: verified ? Colors.green : const Color(0xFFD97706), size: 32), const SizedBox(width: 12), Expanded(child: Text(verified ? 'Verified by administrator' : 'Verification pending\nUpload documents for administrator review.', style: const TextStyle(color: navy, fontWeight: FontWeight.w700, height: 1.35)))]))); }); }
  Widget _slot((String, String, String, String, IconData) slot) {
    final file = selected[slot.$1];
    final doc = _doc(slot.$1);
    final status = doc == null ? 'Not submitted' : doc['is_verified'] == true ? 'Verified' : 'Under review';
    return Card(elevation: 0, margin: const EdgeInsets.only(bottom: 12), child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(slot.$5, color: orange), const SizedBox(width: 10), Expanded(child: Text(slot.$2, style: const TextStyle(color: navy, fontWeight: FontWeight.w800))), _chip(status)]),
      const SizedBox(height: 5), Text(slot.$3, style: const TextStyle(color: muted, fontSize: 12)), const SizedBox(height: 10),
      if (file != null) _local(file) else if (doc != null) _remote(doc),
      Row(children: [TextButton.icon(onPressed: submitting ? null : () => _pick(slot.$1), icon: Icon(doc == null ? Icons.attach_file : Icons.refresh, color: orange), label: Text(doc == null ? 'Attach' : 'Replace', style: const TextStyle(color: orange))), if (doc != null) TextButton.icon(onPressed: submitting ? null : () => _delete(doc), icon: const Icon(Icons.delete_outline, color: Colors.red), label: const Text('Delete', style: TextStyle(color: Colors.red)))])
    ])));
  }
  Widget _chip(String text) { final color = text == 'Verified' ? Colors.green : text == 'Not submitted' ? muted : const Color(0xFFD97706); return Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: .12), borderRadius: BorderRadius.circular(12)), child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700))); }
  Widget _local(PlatformFile f) => InkWell(onTap: () => _preview(f.name, _image(f.name) ? Image.memory(f.bytes!, fit: BoxFit.contain) : const Icon(Icons.picture_as_pdf, color: Colors.white, size: 90)), child: Row(children: [_image(f.name) ? Image.memory(f.bytes!, width: 74, height: 58, fit: BoxFit.cover) : const Icon(Icons.picture_as_pdf, color: orange, size: 42), const SizedBox(width: 10), Expanded(child: Text(f.name, overflow: TextOverflow.ellipsis, style: const TextStyle(color: navy, fontWeight: FontWeight.w600))), const Icon(Icons.open_in_full, color: muted)]));
  Widget _remote(dynamic d) { final path = '${d['file_url'] ?? ''}'; final url = api.resolveImageUrl(path); return InkWell(onTap: () => _preview('${d['title']}', _image(path) ? Image.network(url, fit: BoxFit.contain) : const Icon(Icons.picture_as_pdf, color: Colors.white, size: 90)), child: Row(children: [_image(path) ? Image.network(url, width: 74, height: 58, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)) : const Icon(Icons.picture_as_pdf, color: orange, size: 42), const SizedBox(width: 10), Expanded(child: Text('${d['title']}', style: const TextStyle(color: navy, fontWeight: FontWeight.w600))), const Icon(Icons.open_in_full, color: muted)])); }
  void _preview(String title, Widget child) => showDialog(context: context, builder: (_) => Dialog(backgroundColor: Colors.black, insetPadding: const EdgeInsets.all(10), child: Stack(children: [InteractiveViewer(child: Center(child: child)), Positioned(top: 4, right: 4, child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white, size: 30))), Positioned(left: 12, bottom: 12, child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)))])));
}
