import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';

class TechnicianProfileSettingsScreen extends StatefulWidget {
  const TechnicianProfileSettingsScreen({super.key});

  @override
  State<TechnicianProfileSettingsScreen> createState() => _TechnicianProfileSettingsScreenState();
}

class _TechnicianProfileSettingsScreenState extends State<TechnicianProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _bioController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _skillsController;
  late TextEditingController _certificationsController;
  late TextEditingController _experienceController;
  
  String _availabilityStatus = 'available';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final appState = Get.find<AppState>();
    final u = appState.currentUser;
    _firstNameController = TextEditingController(text: u.firstName);
    _lastNameController = TextEditingController(text: u.lastName);
    _phoneController = TextEditingController(text: u.phone);
    _countryController = TextEditingController(text: u.country);
    _bioController = TextEditingController(text: u.bio);
    _hourlyRateController = TextEditingController(text: u.hourlyRate.toString());
    _skillsController = TextEditingController(text: u.skills.join(', '));
    _certificationsController = TextEditingController(text: u.certifications.join(', '));
    _experienceController = TextEditingController(text: u.experience);
    _availabilityStatus = u.availabilityStatus.isNotEmpty ? u.availabilityStatus : 'available';
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _bioController.dispose();
    _hourlyRateController.dispose();
    _skillsController.dispose();
    _certificationsController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final appState = Get.find<AppState>();
      
      final skillsList = _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final certsList = _certificationsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      final hr = double.tryParse(_hourlyRateController.text) ?? 0.0;

      await appState.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        country: _countryController.text.trim(),
        bio: _bioController.text.trim(),
        hourlyRate: hr,
        availabilityStatus: _availabilityStatus,
        skills: skillsList,
        certifications: certsList,
        experience: _experienceController.text.trim(),
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, TextInputType? keyboardType, String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            validator: (v) => v!.trim().isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Technician Settings', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4500)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Personal Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('First Name', _firstNameController)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildTextField('Last Name', _lastNameController)),
                      ],
                    ),
                    _buildTextField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
                    _buildTextField('Country', _countryController),
                    _buildTextField('Bio / Summary', _bioController, maxLines: 3, hint: 'Briefly describe your experience and skills.'),
                    _buildTextField('Experience Description', _experienceController, maxLines: 3, hint: 'e.g., 5 years of plumbing, worked at local agency.'),
                    
                    const Divider(height: 32, thickness: 1, color: Color(0xFFE2E8F0)),
                    
                    const Text('Professional Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                    const SizedBox(height: 16),
                    _buildTextField('Skills (comma separated)', _skillsController, hint: 'e.g., Plumbing, Electrical, HVAC'),
                    _buildTextField('Certifications (comma separated)', _certificationsController, hint: 'e.g., OSHA 30, Master Plumber'),
                    _buildTextField('Hourly Rate (\$)', _hourlyRateController, keyboardType: TextInputType.number),
                    
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('Availability', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: _availabilityStatus,
                      items: const [
                        DropdownMenuItem(value: 'available', child: Text('Available')),
                        DropdownMenuItem(value: 'busy', child: Text('Busy')),
                        DropdownMenuItem(value: 'offline', child: Text('Offline')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _availabilityStatus = v);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF1F5F9),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4500),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                        child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
