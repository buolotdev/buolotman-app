import 'package:flutter/material.dart';

import 'app_state.dart';

class EditCompanyProfileScreen extends StatefulWidget {
  const EditCompanyProfileScreen({super.key});

  @override
  State<EditCompanyProfileScreen> createState() => _EditCompanyProfileScreenState();
}

class _EditCompanyProfileScreenState extends State<EditCompanyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _companyNameCtrl;
  late TextEditingController _aboutCtrl;
  late TextEditingController _headquartersCtrl;
  late TextEditingController _websiteCtrl;
  late TextEditingController _teamSizeCtrl;
  late TextEditingController _industryCtrl;
  late TextEditingController _servicesOfferedCtrl; // comma-separated

  @override
  void initState() {
    super.initState();
    final profile = AppStateScope.of(context).companyProfile ?? {};
    _companyNameCtrl = TextEditingController(text: profile['company_name']?.toString() ?? '');
    _aboutCtrl = TextEditingController(text: profile['about']?.toString() ?? '');
    _headquartersCtrl = TextEditingController(text: profile['headquarters']?.toString() ?? '');
    _websiteCtrl = TextEditingController(text: profile['website']?.toString() ?? '');
    _teamSizeCtrl = TextEditingController(text: profile['team_size']?.toString() ?? '');
    _industryCtrl = TextEditingController(text: profile['industry']?.toString() ?? '');

    final offered = profile['services_offered'];
    final offeredStr = offered is List
        ? offered.join(', ')
        : offered?.toString() ?? '';
    _servicesOfferedCtrl = TextEditingController(text: offeredStr);
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _aboutCtrl.dispose();
    _headquartersCtrl.dispose();
    _websiteCtrl.dispose();
    _teamSizeCtrl.dispose();
    _industryCtrl.dispose();
    _servicesOfferedCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);

    try {
      final servicesOffered = _servicesOfferedCtrl.text
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final data = <String, dynamic>{
        'company_name': _companyNameCtrl.text.trim(),
        'about': _aboutCtrl.text.trim(),
        'headquarters': _headquartersCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
        'industry': _industryCtrl.text.trim(),
        'services_offered': servicesOffered,
      };
      if (_teamSizeCtrl.text.trim().isNotEmpty) {
        data['team_size'] = int.tryParse(_teamSizeCtrl.text.trim()) ?? 0;
      }

      await AppStateScope.of(context).updateCompanyProfile(data);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF001F3F),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Edit Company Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── BASIC INFO ──────────────────────────────────────────────
              _sectionLabel('Basic Information'),
              const SizedBox(height: 12),
              _field(
                controller: _companyNameCtrl,
                label: 'Company Name',
                icon: Icons.business,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _industryCtrl,
                label: 'Industry',
                icon: Icons.category_outlined,
                hint: 'e.g. Real Estate, HVAC, Tech',
              ),
              const SizedBox(height: 14),
              _field(
                controller: _headquartersCtrl,
                label: 'Headquarters / City',
                icon: Icons.location_on_outlined,
                hint: 'e.g. Lagos, Nigeria',
              ),
              const SizedBox(height: 14),
              _field(
                controller: _websiteCtrl,
                label: 'Website',
                icon: Icons.language_outlined,
                hint: 'https://yourcompany.com',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _teamSizeCtrl,
                label: 'Team Size',
                icon: Icons.group_outlined,
                hint: 'e.g. 10',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 28),

              // ── ABOUT ────────────────────────────────────────────────────
              _sectionLabel('About Company'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _aboutCtrl,
                minLines: 4,
                maxLines: 8,
                decoration: _inputDecoration(
                  label: 'Company Description',
                  icon: Icons.description_outlined,
                  hint: 'Tell clients what your company does, your values, and your experience...',
                ),
              ),
              const SizedBox(height: 28),

              // ── SERVICES ─────────────────────────────────────────────────
              _sectionLabel('Services Offered'),
              const SizedBox(height: 6),
              const Text(
                'Enter services separated by commas',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _servicesOfferedCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: _inputDecoration(
                  label: 'Services',
                  icon: Icons.home_repair_service_outlined,
                  hint: 'e.g. Plumbing, Electrical, HVAC, Painting',
                ),
              ),
              const SizedBox(height: 40),

              // ── SAVE BUTTON ──────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4500),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF001F3F),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: _inputDecoration(label: label, icon: icon, hint: hint),
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF001F3F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
