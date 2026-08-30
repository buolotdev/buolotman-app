import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'app_state.dart';
class TechnicianProfileSettingsScreen extends StatefulWidget {
  const TechnicianProfileSettingsScreen({super.key});

  @override
  State<TechnicianProfileSettingsScreen> createState() => _TechnicianProfileSettingsScreenState();
}

class _TechnicianProfileSettingsScreenState extends State<TechnicianProfileSettingsScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  bool _isLoading = false;

  File? _pickedImage;
  String? _base64Avatar;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
      final bytes = await _pickedImage!.readAsBytes();
      _base64Avatar = 'data:image/jpeg;base64,' + base64Encode(bytes);
    }
  }

  // Tab 1: Personal
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _taglineController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _languagesController;

  // Tab 2: Professional
  late TextEditingController _primaryOccupationController;
  late TextEditingController _yearsExpController;
  late TextEditingController _skillsController;
  late TextEditingController _certificationsController;
  late TextEditingController _licencesController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;

  // Tab 3: Work & Availability
  String _availabilityStatus = 'available';
  bool _availableNow = false;
  bool _acceptsOnsite = true;
  bool _acceptsRemote = false;
  bool _acceptsWeekends = false;
  bool _acceptsEmergency = false;
  bool _acceptsFullTime = false;
  bool _acceptsPartTime = true;
  bool _willingToTravel = false;
  int _serviceRadiusKm = 0;

  // Tab 4: Pricing
  late TextEditingController _startingPriceController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _dailyRateController;
  late TextEditingController _fixedPriceController;
  late TextEditingController _inspectionFeeController;

  // Tab 5: Tools & BM Eligibility
  bool _ownTools = false;
  bool _hasVehicle = false;
  bool _bmConcierge = false;
  bool _bmBuildTeam = false;
  bool _bmEmergency = false;
  bool _canSupervise = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    final appState = Get.find<AppState>();
    final u = appState.currentUser;
    
    // Tab 1
    _firstNameController = TextEditingController(text: u.firstName);
    _lastNameController = TextEditingController(text: u.lastName);
    _taglineController = TextEditingController(text: u.tagline);
    _phoneController = TextEditingController(text: u.phone);
    _countryController = TextEditingController(text: u.country);
    _cityController = TextEditingController(text: u.city);
    _languagesController = TextEditingController(text: u.preferredLanguages.join(', '));
    
    // Tab 2
    _primaryOccupationController = TextEditingController(text: u.primaryOccupation);
    _yearsExpController = TextEditingController(text: u.yearsExperience.toString());
    _skillsController = TextEditingController(text: u.skills.join(', '));
    _certificationsController = TextEditingController(text: u.certifications.join(', '));
    _licencesController = TextEditingController(text: u.licences.join(', '));
    _bioController = TextEditingController(text: u.bio);
    _experienceController = TextEditingController(text: u.experience);

    // Tab 3
    _availabilityStatus = u.availabilityStatus.isNotEmpty ? u.availabilityStatus : 'available';
    _availableNow = u.availableNow;
    _acceptsOnsite = u.acceptsOnsite;
    _acceptsRemote = u.acceptsRemote;
    _acceptsWeekends = u.acceptsWeekends;
    _acceptsEmergency = u.acceptsEmergency;
    _acceptsFullTime = u.acceptsFullTime;
    _acceptsPartTime = u.acceptsPartTime;
    _willingToTravel = u.willingToTravel;
    _serviceRadiusKm = u.serviceRadiusKm;

    // Tab 4
    _startingPriceController = TextEditingController(text: u.startingPrice.toString());
    _hourlyRateController = TextEditingController(text: u.hourlyRate.toString());
    _dailyRateController = TextEditingController(text: u.dailyRate.toString());
    _fixedPriceController = TextEditingController(text: u.fixedPrice.toString());
    _inspectionFeeController = TextEditingController(text: u.inspectionFee.toString());

    // Tab 5
    _ownTools = u.ownTools;
    _hasVehicle = u.hasVehicle;
    _bmConcierge = u.bmConcierge;
    _bmBuildTeam = u.bmBuildTeam;
    _bmEmergency = u.bmEmergency;
    _canSupervise = u.canSupervise;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _languagesController.dispose();
    _primaryOccupationController.dispose();
    _yearsExpController.dispose();
    _skillsController.dispose();
    _certificationsController.dispose();
    _licencesController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _startingPriceController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _fixedPriceController.dispose();
    _inspectionFeeController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final appState = Get.find<AppState>();
      
      await appState.updateProfile(
        avatarUrl: _base64Avatar,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        tagline: _taglineController.text.trim(),
        phone: _phoneController.text.trim(),
        country: _countryController.text.trim(),
        city: _cityController.text.trim(),
        preferredLanguages: _languagesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        
        primaryOccupation: _primaryOccupationController.text.trim(),
        yearsExperience: int.tryParse(_yearsExpController.text.trim()) ?? 0,
        skills: _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        certifications: _certificationsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        licences: _licencesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        bio: _bioController.text.trim(),
        experience: _experienceController.text.trim(),

        availabilityStatus: _availabilityStatus,
        availableNow: _availableNow,
        acceptsOnsite: _acceptsOnsite,
        acceptsRemote: _acceptsRemote,
        acceptsWeekends: _acceptsWeekends,
        acceptsEmergency: _acceptsEmergency,
        acceptsFullTime: _acceptsFullTime,
        acceptsPartTime: _acceptsPartTime,
        willingToTravel: _willingToTravel,
        serviceRadiusKm: _serviceRadiusKm,

        startingPrice: double.tryParse(_startingPriceController.text) ?? 0.0,
        hourlyRate: double.tryParse(_hourlyRateController.text) ?? 0.0,
        dailyRate: double.tryParse(_dailyRateController.text) ?? 0.0,
        fixedPrice: double.tryParse(_fixedPriceController.text) ?? 0.0,
        inspectionFee: double.tryParse(_inspectionFeeController.text) ?? 0.0,

        ownTools: _ownTools,
        hasVehicle: _hasVehicle,
        bmConcierge: _bmConcierge,
        bmBuildTeam: _bmBuildTeam,
        bmEmergency: _bmEmergency,
        canSupervise: _canSupervise,
      );
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: \$e')));
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

  Widget _buildSwitch(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFFF4500),
      contentPadding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFFFF4500),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFF4500),
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'Professional'),
            Tab(text: 'Work & Availability'),
            Tab(text: 'Pricing'),
            Tab(text: 'Tools & BM'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4500)))
          : Form(
              key: _formKey,
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundColor: const Color(0xFFF1F5F9),
                                backgroundImage: _pickedImage != null 
                                    ? FileImage(_pickedImage!) 
                                    : (Get.find<AppState>().currentUser.avatar.startsWith('data:image')
                                        ? MemoryImage(base64Decode(Get.find<AppState>().currentUser.avatar.split(',').last)) as ImageProvider
                                        : (Get.find<AppState>().currentUser.avatar.isNotEmpty && !Get.find<AppState>().currentUser.avatar.startsWith('assets')
                                            ? NetworkImage(Get.find<AppState>().currentUser.avatar) as ImageProvider
                                            : const AssetImage('assets/images/default_avatar.png'))),
                                child: _pickedImage == null && Get.find<AppState>().currentUser.avatar.isEmpty
                                    ? const Icon(Icons.person, size: 50, color: Colors.grey)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Color(0xFFFF4500), shape: BoxShape.circle),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(child: _buildTextField('First Name', _firstNameController)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildTextField('Last Name', _lastNameController)),
                        ],
                      ),
                      _buildTextField('Display / Professional Name (Tagline)', _taglineController, hint: 'e.g. Master Electrician'),
                      _buildTextField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
                      _buildTextField('Country', _countryController),
                      _buildTextField('City / Town', _cityController, hint: 'e.g., Lagos, Abuja'),
                      _buildTextField('Preferred Languages (comma separated)', _languagesController, hint: 'e.g., English, French'),
                    ],
                  ),
                  
                  // Tab 2
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildTextField('Primary Occupation', _primaryOccupationController, hint: 'e.g., Electrician, Plumber'),
                      _buildTextField('Years of Experience', _yearsExpController, keyboardType: TextInputType.number),
                      _buildTextField('Skills (comma separated)', _skillsController, hint: 'e.g., Plumbing, Electrical, HVAC'),
                      _buildTextField('Certifications (comma separated)', _certificationsController, hint: 'e.g., OSHA 30, Master Plumber'),
                      _buildTextField('Licences (comma separated)', _licencesController, hint: 'e.g., Electrical Licence No. 1234'),
                      _buildTextField('Professional Bio', _bioController, maxLines: 4, hint: 'Tell clients about yourself...'),
                      _buildTextField('Experience Description', _experienceController, maxLines: 3, hint: 'e.g., 5 years of plumbing...'),
                    ],
                  ),
                  
                  // Tab 3
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('Availability Status', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _availabilityStatus,
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSwitch('Available Now (Urgent)', _availableNow, (v) => setState(() => _availableNow = v)),
                      const Divider(),
                      _buildSwitch('Accepts On-site Work', _acceptsOnsite, (v) => setState(() => _acceptsOnsite = v)),
                      _buildSwitch('Accepts Remote Work', _acceptsRemote, (v) => setState(() => _acceptsRemote = v)),
                      _buildSwitch('Accepts Weekend Work', _acceptsWeekends, (v) => setState(() => _acceptsWeekends = v)),
                      _buildSwitch('Accepts Emergency Jobs', _acceptsEmergency, (v) => setState(() => _acceptsEmergency = v)),
                      _buildSwitch('Available Full-time', _acceptsFullTime, (v) => setState(() => _acceptsFullTime = v)),
                      _buildSwitch('Available Part-time', _acceptsPartTime, (v) => setState(() => _acceptsPartTime = v)),
                      const Divider(),
                      _buildSwitch('Willing to Travel', _willingToTravel, (v) => setState(() => _willingToTravel = v)),
                      if (_willingToTravel) ...[
                        const SizedBox(height: 8),
                        const Text('Service Radius (km)', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                        Slider(
                          value: _serviceRadiusKm.toDouble(),
                          min: 0, max: 100, divisions: 20,
                          activeColor: const Color(0xFFFF4500),
                          label: '\$_serviceRadiusKm km',
                          onChanged: (v) => setState(() => _serviceRadiusKm = v.toInt()),
                        ),
                      ]
                    ],
                  ),
                  
                  // Tab 4
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildTextField('Starting Price (\$)', _startingPriceController, keyboardType: TextInputType.number),
                      _buildTextField('Hourly Rate (\$)', _hourlyRateController, keyboardType: TextInputType.number),
                      _buildTextField('Daily Rate (\$)', _dailyRateController, keyboardType: TextInputType.number),
                      _buildTextField('Fixed Price (\$)', _fixedPriceController, keyboardType: TextInputType.number),
                      _buildTextField('Inspection Fee (\$)', _inspectionFeeController, keyboardType: TextInputType.number),
                    ],
                  ),
                  
                  // Tab 5
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildSwitch('Has Own Tools', _ownTools, (v) => setState(() => _ownTools = v)),
                      _buildSwitch('Has Work Vehicle', _hasVehicle, (v) => setState(() => _hasVehicle = v)),
                      const Divider(),
                      const Text('Boulot Man Special Eligibility', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      _buildSwitch('BM Concierge', _bmConcierge, (v) => setState(() => _bmConcierge = v)),
                      _buildSwitch('BM Build a Team', _bmBuildTeam, (v) => setState(() => _bmBuildTeam = v)),
                      _buildSwitch('BM Emergency', _bmEmergency, (v) => setState(() => _bmEmergency = v)),
                      _buildSwitch('Can Supervise Technicians', _canSupervise, (v) => setState(() => _canSupervise = v)),
                    ],
                  ),
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4500),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
