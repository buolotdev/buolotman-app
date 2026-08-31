import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';
import 'api_service.dart';

class ReferencesManagementScreen extends StatefulWidget {
  const ReferencesManagementScreen({Key? key}) : super(key: key);

  @override
  State<ReferencesManagementScreen> createState() => _ReferencesManagementScreenState();
}

class _ReferencesManagementScreenState extends State<ReferencesManagementScreen> {
  bool _isLoading = true;
  List<dynamic> _references = [];

  final _formKey = GlobalKey<FormState>();
  String _employerName = '';
  String _referenceName = '';
  String _relationship = '';
  String _contactInfo = '';
  String _docUrl = '';
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadReferences();
  }

  Future<void> _loadReferences() async {
    setState(() => _isLoading = true);
    try {
      _references = await ApiService.instance.fetchReferences();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading references: \$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addReference() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isAdding = true);
    try {
      await ApiService.instance.addReference({
        'employer_name': _employerName,
        'reference_name': _referenceName,
        'relationship': _relationship,
        'contact_info': _contactInfo,
        'recommendation_document_url': _docUrl,
      });
      _formKey.currentState!.reset();
      _employerName = '';
      _referenceName = '';
      _relationship = '';
      _contactInfo = '';
      _docUrl = '';
      await _loadReferences();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reference added successfully for internal review.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding reference: \$e')));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteReference(int id) async {
    try {
      await ApiService.instance.deleteReference(id);
      await _loadReferences();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reference deleted.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting reference: \$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Professional References', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4500)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add a Professional Reference',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These contacts remain private and are only used by Boulot Man for professional verification.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Previous Employer / Client Name', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            onSaved: (v) => _employerName = v!,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Reference Person Name', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            onSaved: (v) => _referenceName = v!,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Relationship (e.g. Supervisor, Client)', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            onSaved: (v) => _relationship = v!,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Contact Information (Email/Phone)', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                            onSaved: (v) => _contactInfo = v!,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            decoration: InputDecoration(labelText: 'Document/Recommendation Letter URL (Optional)', filled: true, fillColor: const Color(0xFFF8FAFC), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none)),
                            onSaved: (v) => _docUrl = v ?? '',
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isAdding ? null : _addReference,
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                              child: _isAdding
                                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Text('Submit Reference', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text('My References', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                  const SizedBox(height: 16),
                  if (_references.isEmpty)
                    const Text('No references added yet.', style: TextStyle(color: Colors.grey))
                  else
                    ..._references.map((r) {
                      Color statusColor = Colors.orange;
                      if (r['status'] == 'Verified') statusColor = Colors.green;
                      if (r['status'] == 'Rejected') statusColor = Colors.red;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text('\${r["reference_name"]} (\${r["employer_name"]})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('Relationship: \${r["relationship"]}'),
                              Text('Contact: \${r["contact_info"]}'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                                child: Text(r['status'] ?? 'Under Review', style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Reference'),
                                  content: const Text('Are you sure you want to remove this reference?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _deleteReference(r['id']);
                                      },
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }
}
