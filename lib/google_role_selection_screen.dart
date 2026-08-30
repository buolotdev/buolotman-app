import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'api_service.dart';
import 'main_navigation_screen.dart';

class GoogleRoleSelectionScreen extends StatefulWidget {
  final String initialRole;
  const GoogleRoleSelectionScreen({super.key, this.initialRole = 'CLIENT'});

  @override
  State<GoogleRoleSelectionScreen> createState() => _GoogleRoleSelectionScreenState();
}

class _GoogleRoleSelectionScreenState extends State<GoogleRoleSelectionScreen> {
  late String _selectedRole;
  bool _isLoading = false;
  
  // Technician fields
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  // Company fields
  final _companyNameController = TextEditingController();
  final _regNumberController = TextEditingController();
  final _industryController = TextEditingController();
  final _websiteController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  void dispose() {
    _bioController.dispose();
    _phoneController.dispose();
    _hourlyRateController.dispose();
    _companyNameController.dispose();
    _regNumberController.dispose();
    _industryController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _submitProfile() async {
    if (_selectedRole != 'CLIENT' && !_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final body = <String, dynamic>{
        'role': _selectedRole,
      };

      if (_selectedRole == 'TECHNICIAN') {
        body['bio'] = _bioController.text;
        body['phone'] = _phoneController.text;
        body['hourly_rate'] = _hourlyRateController.text;
      } else if (_selectedRole == 'COMPANY') {
        body['company_name'] = _companyNameController.text;
        body['registration_number'] = _regNumberController.text;
        body['industry'] = _industryController.text;
        body['website'] = _websiteController.text;
      }

      await ApiService.instance.completeProfile(body);
      
      if (mounted) {
        // Refresh app state
        await AppStateScope.of(context).syncAll();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildRoleCard(String role, String title, String subtitle, IconData icon) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF4500).withValues(alpha: 0.05) : Colors.white,
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFF4500) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? const Color(0xFFFF4500) : const Color(0xFF001F3F),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFFFF4500)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint, IconData icon, {bool isNumber = false, int maxLines = 1, bool isRequired = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        validator: isRequired ? (v) => v == null || v.isEmpty ? 'This field is required' : null : null,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          hintText: hint,
          prefixIcon: maxLines == 1 ? Icon(icon, color: const Color(0xFF64748B)) : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Complete Your Profile", style: TextStyle(color: Color(0xFF001F3F))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500))))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "How do you want to use Boulot Man?",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001F3F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Please select a role to continue with your Google account.",
                        style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 24),
                      
                      _buildRoleCard('CLIENT', 'Client', 'I want to hire professionals', Icons.search),
                      const SizedBox(height: 12),
                      _buildRoleCard('TECHNICIAN', 'Technician', 'I want to offer my skills', Icons.handyman),
                      const SizedBox(height: 12),
                      _buildRoleCard('COMPANY', 'Company', 'I want to register my business', Icons.business),
                      
                      if (_selectedRole == 'TECHNICIAN') ...[
                        const SizedBox(height: 32),
                        const Text("Professional Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                        const SizedBox(height: 16),
                        _buildTextField(_phoneController, "Phone Number", "Enter your phone number", Icons.phone, isRequired: true),
                        _buildTextField(_hourlyRateController, "Hourly Rate", "Enter your hourly rate (e.g. 25.00)", Icons.attach_money, isNumber: true, isRequired: true),
                        _buildTextField(_bioController, "Bio", "Tell clients about your experience...", Icons.person, maxLines: 3, isRequired: true),
                      ],
                      
                      if (_selectedRole == 'COMPANY') ...[
                        const SizedBox(height: 32),
                        const Text("Company Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                        const SizedBox(height: 16),
                        _buildTextField(_companyNameController, "Company Name", "Enter company name", Icons.business, isRequired: true),
                        _buildTextField(_regNumberController, "Registration Number", "Enter legal registration number", Icons.numbers, isRequired: true),
                        _buildTextField(_industryController, "Industry", "e.g. Construction, IT Services", Icons.category),
                        _buildTextField(_websiteController, "Website", "https://...", Icons.language),
                      ],
                      
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _submitProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4500),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text(
                            "Complete Profile",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
