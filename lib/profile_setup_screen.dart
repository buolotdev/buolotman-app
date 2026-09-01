import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'app_state.dart';
import 'api_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Shared fields
  final _addressController = TextEditingController();
  final _dobController = TextEditingController();
  
  // Technician fields
  String? _educationLevel;
  String? _expertiseLevel;
  final _hourlyRateController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _fixedPriceController = TextEditingController();
  final _inspectionFeeController = TextEditingController();
  final _bioController = TextEditingController();

  bool _prefOnSite = true;
  bool _prefRemote = false;
  bool _prefEmergency = false;
  bool _prefWeekends = true;
  bool _hasTools = true;
  bool _hasVehicle = false;

  // Document fields
  String? _nationalIdFrontUrl;
  String? _nationalIdBackUrl;
  String? _selfieUrl;
  String? _businessRegistrationUrl;
  String? _taxIdUrl;
  String? _operatingLicenceUrl;

  final ImagePicker _picker = ImagePicker();

  // Company fields
  final _companyNameController = TextEditingController();
  final _aboutController = TextEditingController();
  final _headquartersController = TextEditingController();
  final _companySizeController = TextEditingController();
  final _maxProjectCapacityController = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = Get.find<AppState>();
      _addressController.text = (appState.currentUser.address.isNotEmpty) ? appState.currentUser.address : appState.currentUser.location;
      _dobController.text = appState.currentUser.dateOfBirth;
      _educationLevel = appState.currentUser.educationLevel.isNotEmpty ? appState.currentUser.educationLevel : null;
      _expertiseLevel = appState.currentUser.expertiseLevel.isNotEmpty ? appState.currentUser.expertiseLevel : null;
      _bioController.text = appState.currentUser.tagline;
      _hourlyRateController.text = (appState.currentUser.startingPrice).toString();
      _companyNameController.text = appState.currentUser.name;
    });
  }

  Future<String?> _pickAndUploadImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => _isSaving = true);
        final bytes = await image.readAsBytes();
        final base64String = base64Encode(bytes);
        final extension = image.name.split('.').last;
        
        final api = Get.find<ApiService>();
        final response = await api.post('/upload/', {
          'base64_file': base64String,
          'extension': extension,
        });
        
        setState(() => _isSaving = false);
        final responseBody = jsonDecode(response.body);
        if (response.statusCode == 200) {
          return responseBody['url'] as String?;
        } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: ${responseBody['detail'] ?? responseBody['error']}')));
        }
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload error: $e')));
    }
    return null;
  }

  Future<void> _submitProfile(AppState appState) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    try {
      final role = appState.currentRole;
      
      // Update accounts_user fields
      final Map<String, dynamic> userUpdates = {
        'address': _addressController.text.trim(),
        'date_of_birth': _dobController.text.trim(),
      };
      
      if (role == 'Technician') {
        userUpdates['education_level'] = _educationLevel ?? 'High School';
        userUpdates['expertise_level'] = _expertiseLevel ?? 'Beginner';
        userUpdates['bio'] = _bioController.text.trim();
        userUpdates['hourly_rate'] = double.tryParse(_hourlyRateController.text.trim()) ?? 0.0;
        userUpdates['daily_rate'] = double.tryParse(_dailyRateController.text.trim()) ?? 0.0;
        userUpdates['fixed_price'] = double.tryParse(_fixedPriceController.text.trim()) ?? 0.0;
        userUpdates['inspection_fee'] = double.tryParse(_inspectionFeeController.text.trim()) ?? 0.0;
        userUpdates['work_preferences'] = {
          'on_site': _prefOnSite,
          'remote': _prefRemote,
          'emergency': _prefEmergency,
          'weekends': _prefWeekends,
        };
        userUpdates['tools_and_equipment'] = {
          'owns_tools': _hasTools,
          'has_vehicle': _hasVehicle,
        };
        if (_nationalIdFrontUrl != null) userUpdates['national_id_front'] = _nationalIdFrontUrl;
        if (_nationalIdBackUrl != null) userUpdates['national_id_back'] = _nationalIdBackUrl;
        if (_selfieUrl != null) userUpdates['selfie_url'] = _selfieUrl;
      }
      
      // We need to use AppState.apiService or make request manually
      // Wait, what does AppState use for requests? Let's assume there's a global ApiService or we can make http call.
      // Let's check AppState to see how it makes requests. I'll just use ApiService.instance if it's available.
      // Wait, I will use `await appState.syncAll()` later, but first I need ApiService.
      // I will replace this with a proper API call.
      // For now, I'll use the getx ApiService or the standard http client used in the app.
      final api = Get.find<ApiService>();
      await api.patch('/auth/me/', userUpdates);

      if (role == 'Company') {
        final Map<String, dynamic> companyUpdates = {
          'company_name': _companyNameController.text.trim(),
          'about': _aboutController.text.trim(),
          'headquarters': _headquartersController.text.trim(),
          'company_size': _companySizeController.text.trim(),
          'capabilities': {
            'max_project_capacity': _maxProjectCapacityController.text.trim(),
          }
        };
        if (_businessRegistrationUrl != null) companyUpdates['business_registration_url'] = _businessRegistrationUrl;
        if (_taxIdUrl != null) companyUpdates['tax_id_url'] = _taxIdUrl;
        if (_operatingLicenceUrl != null) companyUpdates['operating_licence_url'] = _operatingLicenceUrl;

        await api.patch('/company/profile/', companyUpdates);
      }

      await appState.syncAll();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final role = appState.currentRole;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Complete Your Profile'),
            backgroundColor: const Color(0xFF001F3F),
            foregroundColor: Colors.white,
          ),
          body: _isSaving
              ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500))))
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      const Text(
                        'Almost there!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please provide the required $role details to activate your account.',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),
                      
                      // Client & Shared fields
                      _buildTextField(_addressController, 'Address / Location', Icons.location_on),
                      const SizedBox(height: 16),
                      _buildTextField(_dobController, 'Date of Birth (YYYY-MM-DD)', Icons.calendar_today),
                      
                      // Technician fields
                      if (role == 'Technician') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _educationLevel,
                          decoration: _inputDecoration('Education Level', Icons.school),
                          items: ['High School', 'Associate Degree', 'Bachelor', 'Master', 'PhD']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => _educationLevel = val),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _expertiseLevel,
                          decoration: _inputDecoration('Expertise Level', Icons.star),
                          items: ['Beginner', 'Intermediate', 'Expert']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) => setState(() => _expertiseLevel = val),
                          validator: (val) => val == null ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(_hourlyRateController, 'Hourly Rate (\$)', Icons.attach_money, isNumber: true),
                        const SizedBox(height: 16),
                        _buildTextField(_dailyRateController, 'Daily Rate (\$)', Icons.money, isNumber: true),
                        const SizedBox(height: 16),
                        _buildTextField(_fixedPriceController, 'Fixed Starting Price (\$)', Icons.price_check, isNumber: true),
                        const SizedBox(height: 16),
                        _buildTextField(_inspectionFeeController, 'Inspection/Call-out Fee (\$)', Icons.search, isNumber: true),
                        const SizedBox(height: 16),
                        const Text('Work Preferences', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SwitchListTile(title: const Text('Available for On-site jobs'), value: _prefOnSite, onChanged: (v) => setState(() => _prefOnSite = v), activeColor: const Color(0xFFFF5500)),
                        SwitchListTile(title: const Text('Available for Remote jobs'), value: _prefRemote, onChanged: (v) => setState(() => _prefRemote = v), activeColor: const Color(0xFFFF5500)),
                        SwitchListTile(title: const Text('Available on Weekends'), value: _prefWeekends, onChanged: (v) => setState(() => _prefWeekends = v), activeColor: const Color(0xFFFF5500)),
                        SwitchListTile(title: const Text('Available for Emergency/Urgent jobs'), value: _prefEmergency, onChanged: (v) => setState(() => _prefEmergency = v), activeColor: const Color(0xFFFF5500)),
                        const SizedBox(height: 16),
                        const Text('Tools & Equipment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        CheckboxListTile(title: const Text('I own the necessary tools (including PPE)'), value: _hasTools, onChanged: (v) => setState(() => _hasTools = v ?? false), activeColor: const Color(0xFFFF5500)),
                        CheckboxListTile(title: const Text('I have a reliable vehicle for transit'), value: _hasVehicle, onChanged: (v) => setState(() => _hasVehicle = v ?? false), activeColor: const Color(0xFFFF5500)),
                        const SizedBox(height: 16),
                        _buildTextField(_bioController, 'Professional Bio', Icons.person, maxLines: 3),
                        const SizedBox(height: 16),
                        const Text('Identity Verification Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        _buildDocUploader('National ID (Front)', _nationalIdFrontUrl, (url) => setState(() => _nationalIdFrontUrl = url)),
                        _buildDocUploader('National ID (Back)', _nationalIdBackUrl, (url) => setState(() => _nationalIdBackUrl = url)),
                        _buildDocUploader('Live Selfie', _selfieUrl, (url) => setState(() => _selfieUrl = url)),
                      ],
                      
                      // Company fields
                      if (role == 'Company') ...[
                        const SizedBox(height: 16),
                        _buildTextField(_companyNameController, 'Company Name', Icons.business),
                        const SizedBox(height: 16),
                        _buildTextField(_headquartersController, 'Headquarters / Industry', Icons.map),
                        const SizedBox(height: 16),
                        _buildTextField(_companySizeController, 'Company Size (e.g., 10-50 employees)', Icons.people),
                        const SizedBox(height: 16),
                        _buildTextField(_maxProjectCapacityController, 'Max Project Capacity (e.g., \$1M+)', Icons.monetization_on),
                        const SizedBox(height: 16),
                        _buildTextField(_aboutController, 'Company About', Icons.info, maxLines: 3),
                        const SizedBox(height: 16),
                        const Text('Verification Documents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        _buildDocUploader('Business Registration Document', _businessRegistrationUrl, (url) => setState(() => _businessRegistrationUrl = url)),
                        _buildDocUploader('Tax ID Certificate', _taxIdUrl, (url) => setState(() => _taxIdUrl = url)),
                        _buildDocUploader('Operating Licence', _operatingLicenceUrl, (url) => setState(() => _operatingLicenceUrl = url)),
                      ],
                      
                      const SizedBox(height: 48),
                      ElevatedButton(
                        onPressed: () => _submitProfile(appState),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4500),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
        );
      }
    );
  }

  Widget _buildDocUploader(String label, String? url, Function(String) onUploaded) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final uploadedUrl = await _pickAndUploadImage();
            if (uploadedUrl != null) {
              onUploaded(uploadedUrl);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
              color: url != null ? Colors.green.shade50 : Colors.grey.shade50,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(url != null ? Icons.check_circle : Icons.upload_file, color: url != null ? Colors.green : Colors.grey),
                const SizedBox(width: 8),
                Text(url != null ? 'Document Uploaded' : 'Tap to Upload', style: TextStyle(color: url != null ? Colors.green : Colors.grey.shade700)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNumber = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      validator: (val) => val == null || val.isEmpty ? 'Required field' : null,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFFFF5500)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF5500), width: 2)),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
