import 'public_technician_profile_screen.dart' as public_profile;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:buolot_man_app/app_state.dart';

class TechnicianProfileSettingsScreen extends StatefulWidget {
  const TechnicianProfileSettingsScreen({Key? key}) : super(key: key);

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
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 60,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();
      setState(() {
        _pickedImage = file;
        _base64Avatar = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
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
  
  
  late TextEditingController _emergencyContactNameController;
  late TextEditingController _emergencyContactPhoneController;

  // Tab 2: Professional
  late TextEditingController _primaryOccupationController;
  late TextEditingController _yearsExpController;
  late TextEditingController _skillsController;
  late TextEditingController _certificationsController;
  late TextEditingController _licencesController;
  late TextEditingController _bioController;
  late TextEditingController _experienceController;
  late TextEditingController _workPreferencesController;
  late TextEditingController _educationLevelController;
  late TextEditingController _expertiseLevelController;
  late TextEditingController _nationalIdNumberController;

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
  List<String> _preferredWorkingDays = [];
  late TextEditingController _preferredWorkingHoursController;
  
  String _businessType = 'Individual technician';
  bool _acceptsIndividualJobs = true;
  bool _acceptsTeamProjects = true;
  bool _acceptsLongTermContracts = true;
  bool _acceptsShortTermJobs = true;
  bool _interestedInLongTermPlacement = false;

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
  late TextEditingController _toolsAndEquipmentController;
  
  bool _canTransportEquipment = false;
  bool _hasPpe = false;
  bool _hasSpecialistMachinery = false;
  bool _hasDrivingLicence = false;
  bool _bmContractorProjects = false;
  bool _teamLeaderExperience = false;
  bool _projectManagementExperience = false;

  // Tab 6: Verification Docs
  File? _pickedNationalIdFront;
  String? _base64NationalIdFront;
  File? _pickedNationalIdBack;
  String? _base64NationalIdBack;
  File? _pickedSelfie;
  String? _base64Selfie;
  File? _pickedCv;
  String? _base64Cv;

  // Tab 7: Payout Settings
  String _preferredPayoutMethod = 'Bank Transfer';
  late TextEditingController _bankAccountNameController;
  late TextEditingController _bankAccountNumberController;
  late TextEditingController _bankNameController;
  late TextEditingController _mobileMoneyNumberController;
  late TextEditingController _payoutCurrencyController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    
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
    
    
    _emergencyContactNameController = TextEditingController(text: u.emergencyContactName);
    _emergencyContactPhoneController = TextEditingController(text: u.emergencyContactPhone);
    
    // Tab 2
    _primaryOccupationController = TextEditingController(text: u.primaryOccupation);
    _yearsExpController = TextEditingController(text: u.yearsExperience.toString());
    _skillsController = TextEditingController(text: u.skills.join(', '));
    _certificationsController = TextEditingController(text: u.certifications.join(', '));
    _licencesController = TextEditingController(text: u.licences.join(', '));
    _bioController = TextEditingController(text: u.bio);
    _experienceController = TextEditingController(text: u.experience);
    _workPreferencesController = TextEditingController(text: u.workPreferences.join(', '));
    _educationLevelController = TextEditingController(text: u.educationLevel);
    _expertiseLevelController = TextEditingController(text: u.expertiseLevel);
    _nationalIdNumberController = TextEditingController(text: u.nationalIdNumber);

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
    _preferredWorkingDays = List.from(u.preferredWorkingDays);
    _preferredWorkingHoursController = TextEditingController(text: u.preferredWorkingHours);
    _businessType = u.businessType.isNotEmpty ? u.businessType : 'Individual technician';
    _acceptsIndividualJobs = u.acceptsIndividualJobs;
    _acceptsTeamProjects = u.acceptsTeamProjects;
    _acceptsLongTermContracts = u.acceptsLongTermContracts;
    _acceptsShortTermJobs = u.acceptsShortTermJobs;
    _interestedInLongTermPlacement = u.interestedInLongTermPlacement;

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
    _toolsAndEquipmentController = TextEditingController(text: u.toolsAndEquipment.join(', '));
    _canTransportEquipment = u.canTransportEquipment;
    _hasPpe = u.hasPpe;
    _hasSpecialistMachinery = u.hasSpecialistMachinery;
    _hasDrivingLicence = u.hasDrivingLicence;
    _bmContractorProjects = u.bmContractorProjects;
    _teamLeaderExperience = u.teamLeaderExperience;
    _projectManagementExperience = u.projectManagementExperience;

    // Tab 6 (Files already mapped if we want to show previews, but typically Base64 URLs)
    _base64NationalIdFront = u.nationalIdFront;
    _base64NationalIdBack = u.nationalIdBack;
    _base64Selfie = u.selfieUrl;
    _base64Cv = u.cvResumeUrl;

    // Tab 7
    _preferredPayoutMethod = u.preferredPayoutMethod.isNotEmpty ? u.preferredPayoutMethod : 'Bank Transfer';
    _bankAccountNameController = TextEditingController(text: u.bankAccountName);
    _bankAccountNumberController = TextEditingController(text: u.bankAccountNumber);
    _bankNameController = TextEditingController(text: u.bankName);
    _mobileMoneyNumberController = TextEditingController(text: u.mobileMoneyNumber);
    _payoutCurrencyController = TextEditingController(text: u.payoutCurrency.isNotEmpty ? u.payoutCurrency : 'XOF');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _taglineController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _languagesController.dispose();
    
    
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    _primaryOccupationController.dispose();
    _yearsExpController.dispose();
    _skillsController.dispose();
    _certificationsController.dispose();
    _licencesController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    _workPreferencesController.dispose();
    _educationLevelController.dispose();
    _expertiseLevelController.dispose();
    _nationalIdNumberController.dispose();
    _startingPriceController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _fixedPriceController.dispose();
    _inspectionFeeController.dispose();
    _toolsAndEquipmentController.dispose();
    _preferredWorkingHoursController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    _bankNameController.dispose();
    _mobileMoneyNumberController.dispose();
    _payoutCurrencyController.dispose();
    _tabController.dispose();
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
        
        
        emergencyContactName: _emergencyContactNameController.text.trim(),
        emergencyContactPhone: _emergencyContactPhoneController.text.trim(),
        
        primaryOccupation: _primaryOccupationController.text.trim(),
        yearsExperience: int.tryParse(_yearsExpController.text.trim()) ?? 0,
        skills: _skillsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        certifications: _certificationsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        licences: _licencesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        workPreferences: _workPreferencesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        bio: _bioController.text.trim(),
        experience: _experienceController.text.trim(),
        educationLevel: _educationLevelController.text.trim(),
        expertiseLevel: _expertiseLevelController.text.trim(),
        nationalIdNumber: _nationalIdNumberController.text.trim(),

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
        businessType: _businessType,
        acceptsIndividualJobs: _acceptsIndividualJobs,
        acceptsTeamProjects: _acceptsTeamProjects,
        acceptsLongTermContracts: _acceptsLongTermContracts,
        acceptsShortTermJobs: _acceptsShortTermJobs,
        interestedInLongTermPlacement: _interestedInLongTermPlacement,

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
        toolsAndEquipment: _toolsAndEquipmentController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        canTransportEquipment: _canTransportEquipment,
        hasPpe: _hasPpe,
        hasSpecialistMachinery: _hasSpecialistMachinery,
        hasDrivingLicence: _hasDrivingLicence,
        bmContractorProjects: _bmContractorProjects,
        teamLeaderExperience: _teamLeaderExperience,
        projectManagementExperience: _projectManagementExperience,
        
        preferredWorkingDays: _preferredWorkingDays,
        preferredWorkingHours: _preferredWorkingHoursController.text.trim(),
        preferredPayoutMethod: _preferredPayoutMethod,
        bankAccountName: _bankAccountNameController.text.trim(),
        bankAccountNumber: _bankAccountNumberController.text.trim(),
        bankName: _bankNameController.text.trim(),
        mobileMoneyNumber: _mobileMoneyNumberController.text.trim(),
        payoutCurrency: _payoutCurrencyController.text.trim(),

        nationalIdFront: _base64NationalIdFront,
        nationalIdBack: _base64NationalIdBack,
        selfieUrl: _base64Selfie,
        cvResumeUrl: _base64Cv,
      );
      
      await appState.syncAll(); // wait for all fields to reload from server
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

  Widget _buildDatePickerField(String label, TextEditingController controller, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: true,
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                controller.text = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
              }
            },
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFFF1F5F9),
              suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF001F3F)),
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

  Widget _buildFilePicker(String label, File? currentFile, String? currentBase64, Function(File?, String?) onPicked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              FilePickerResult? result = await FilePicker.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['jpg', 'png', 'jpeg', 'pdf'],
              );
              if (result != null && result.files.single.path != null) {
                final file = File(result.files.single.path!);
                final bytes = await file.readAsBytes();
                final ext = file.path.split('.').last.toLowerCase();
                final mimeType = ext == 'pdf' ? 'application/pdf' : 'image/$ext';
                final b64 = 'data:$mimeType;base64,' + base64Encode(bytes);
                onPicked(file, b64);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currentFile != null ? currentFile.path.split('/').last : (currentBase64 != null && currentBase64.isNotEmpty ? 'Document Uploaded' : 'Tap to upload document'),
                      style: TextStyle(color: (currentFile != null || (currentBase64 != null && currentBase64.isNotEmpty)) ? Colors.black : Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (currentFile != null || (currentBase64 != null && currentBase64.isNotEmpty))
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => onPicked(null, null),
                    )
                ],
              ),
            ),
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
        title: const Text('Edit Profile', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
          actions: [
            TextButton.icon(
              onPressed: () {
                Get.to(() => public_profile.PublicTechnicianProfileScreen(
                  technicianData: {
                    'first_name': Get.find<AppState>().currentUser.firstName,
                    'last_name': Get.find<AppState>().currentUser.lastName,
                    'username': Get.find<AppState>().currentUser.name,
                    'avatar_url': Get.find<AppState>().currentUser.avatar,
                    'primary_occupation': Get.find<AppState>().currentUser.primaryOccupation,
                    'verification_badge': Get.find<AppState>().currentUser.verificationBadge,
                    'average_rating': '4.9',
                    'city': Get.find<AppState>().currentUser.city,
                    'identity_verified': Get.find<AppState>().currentUser.verificationBadge.contains('Identity') || Get.find<AppState>().currentUser.verificationBadge.contains('Boulot Man'),
                    'professional_verified': Get.find<AppState>().currentUser.verificationBadge.contains('Professional') || Get.find<AppState>().currentUser.verificationBadge.contains('Boulot Man'),
                    'boulotman_verified': Get.find<AppState>().currentUser.verificationBadge.contains('Boulot Man'),
                    'years_experience': Get.find<AppState>().currentUser.yearsExperience,
                    'completed_jobs': 94,
                    'bio': Get.find<AppState>().currentUser.bio,
                    'hourly_rate': Get.find<AppState>().currentUser.hourlyRate,
                    'daily_rate': Get.find<AppState>().currentUser.dailyRate,
                    'starting_price': Get.find<AppState>().currentUser.startingPrice,
                  },
                ));
              },
              icon: const Icon(Icons.remove_red_eye, color: Color(0xFFFF4500), size: 18),
              label: const Text('Preview', style: TextStyle(color: Color(0xFFFF4500), fontWeight: FontWeight.bold)),
            ),
          ],
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
            Tab(text: 'Verification'),
            Tab(text: 'Payout Settings'),
            Tab(text: 'References'),
              Tab(text: 'Portfolio'),
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
                      
                      const Divider(height: 32),
                      const Text('Emergency Contact', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                      const SizedBox(height: 16),
                      _buildTextField('Contact Name', _emergencyContactNameController),
                      _buildTextField('Contact Phone', _emergencyContactPhoneController, keyboardType: TextInputType.phone),
                    ],
                  ),
                  
                  // Tab 2
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildTextField('Primary Occupation', _primaryOccupationController, hint: 'e.g., Electrician, Plumber'),
                      _buildTextField('Years of Experience', _yearsExpController, keyboardType: TextInputType.number),
                      _buildTextField('Skills (comma separated)', _skillsController, hint: 'e.g., Plumbing, Electrical, HVAC'),
                      _buildTextField('Expertise Level', _expertiseLevelController, hint: 'e.g. Beginner, Intermediate, Expert'),
                      _buildTextField('Education / Training Institution', _educationLevelController, hint: 'e.g. Technical College'),
                      _buildTextField('Certifications (Comma separated)', _certificationsController),
                      _buildTextField('Licences (Comma separated)', _licencesController),
                      _buildTextField('Work Preferences (Comma separated)', _workPreferencesController, hint: 'e.g. On-site, Remote'),
                      const SizedBox(height: 8),
                      const Text('Business Type', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _businessType,
                        items: const [
                          DropdownMenuItem(value: 'Individual technician', child: Text('Individual technician')),
                          DropdownMenuItem(value: 'Registered business/sole proprietor', child: Text('Registered business/sole proprietor')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _businessType = v);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('Brief Bio', _bioController, maxLines: 4),
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
                      _buildSwitch('Accepts Individual Jobs', _acceptsIndividualJobs, (v) => setState(() => _acceptsIndividualJobs = v)),
                      _buildSwitch('Accepts Team Projects', _acceptsTeamProjects, (v) => setState(() => _acceptsTeamProjects = v)),
                      _buildSwitch('Accepts Long Term Contracts', _acceptsLongTermContracts, (v) => setState(() => _acceptsLongTermContracts = v)),
                      _buildSwitch('Accepts Short Term Jobs', _acceptsShortTermJobs, (v) => setState(() => _acceptsShortTermJobs = v)),
                      _buildSwitch('Interested in Long Term Placement', _interestedInLongTermPlacement, (v) => setState(() => _interestedInLongTermPlacement = v)),
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
                          label: '${_serviceRadiusKm} km',
                          onChanged: (v) => setState(() => _serviceRadiusKm = v.toInt()),
                        ),
                      ],
                      const Divider(height: 32),
                      const Text('Preferred Working Days', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) {
                          final isSelected = _preferredWorkingDays.contains(day);
                          return FilterChip(
                            label: Text(day),
                            selected: isSelected,
                            selectedColor: const Color(0xFFFF4500).withOpacity(0.2),
                            checkmarkColor: const Color(0xFFFF4500),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _preferredWorkingDays.add(day);
                                } else {
                                  _preferredWorkingDays.remove(day);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField('Preferred Working Hours', _preferredWorkingHoursController, hint: 'e.g., 9AM - 5PM'),
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
                      const Text('Tools & Equipment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                      const SizedBox(height: 16),
                      _buildTextField('Tools (comma separated)', _toolsAndEquipmentController),
                      _buildSwitch('I have my own tools', _ownTools, (v) => setState(() => _ownTools = v)),
                      _buildSwitch('I have a vehicle/motorcycle', _hasVehicle, (v) => setState(() => _hasVehicle = v)),
                      _buildSwitch('I can transport equipment', _canTransportEquipment, (v) => setState(() => _canTransportEquipment = v)),
                      _buildSwitch('I have PPE (Safety Gear)', _hasPpe, (v) => setState(() => _hasPpe = v)),
                      _buildSwitch('I have specialist machinery', _hasSpecialistMachinery, (v) => setState(() => _hasSpecialistMachinery = v)),
                      _buildSwitch('I have a valid driving licence', _hasDrivingLicence, (v) => setState(() => _hasDrivingLicence = v)),
                      const Divider(height: 32),
                      const Text('Boulot Man Eligibility', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                      const SizedBox(height: 16),
                      _buildSwitch('Available for Concierge assignments', _bmConcierge, (v) => setState(() => _bmConcierge = v)),
                      _buildSwitch('Available for Build a Team', _bmBuildTeam, (v) => setState(() => _bmBuildTeam = v)),
                      _buildSwitch('Available for Emergency Projects', _bmEmergency, (v) => setState(() => _bmEmergency = v)),
                      _buildSwitch('Open to BM Contractor Projects', _bmContractorProjects, (v) => setState(() => _bmContractorProjects = v)),
                      _buildSwitch('Can supervise other technicians', _canSupervise, (v) => setState(() => _canSupervise = v)),
                      _buildSwitch('Has Team Leader Experience', _teamLeaderExperience, (v) => setState(() => _teamLeaderExperience = v)),
                      _buildSwitch('Has Project Management Experience', _projectManagementExperience, (v) => setState(() => _projectManagementExperience = v)),
                    ],
                  ),

                  // Tab 6: Verification
                  ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text('Identity Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                      const SizedBox(height: 16),
                      _buildTextField('National ID Number', _nationalIdNumberController),
                      const SizedBox(height: 16),
                      _buildFilePicker('National ID (Front)', _pickedNationalIdFront, _base64NationalIdFront, (file, b64) {
                        setState(() {
                          _pickedNationalIdFront = file;
                          _base64NationalIdFront = b64;
                        });
                      }),
                      const SizedBox(height: 16),
                      _buildFilePicker('National ID (Back)', _pickedNationalIdBack, _base64NationalIdBack, (file, b64) {
                        setState(() {
                          _pickedNationalIdBack = file;
                          _base64NationalIdBack = b64;
                        });
                      }),
                      const SizedBox(height: 16),
                      _buildFilePicker('Selfie (Live Identity)', _pickedSelfie, _base64Selfie, (file, b64) {
                        setState(() {
                          _pickedSelfie = file;
                          _base64Selfie = b64;
                        });
                      }),
                      const Divider(height: 32),
                      const Text('Professional Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                      const SizedBox(height: 16),
                      _buildFilePicker('CV / Resume', _pickedCv, _base64Cv, (file, b64) {
                        setState(() {
                          _pickedCv = file;
                          _base64Cv = b64;
                        });
                      }),
                    ],
                  ),

                  // Tab 7: Payout Settings
                  _buildPayoutSettingsTab(),

                  // Tab 8: References
                  _buildReferencesTab(),
                    // Tab 9: Portfolio
                    _buildPortfolioTab(),
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


  Widget _buildPortfolioTab() {
    return GetBuilder<AppState>(
      builder: (appState) {
        final items = appState.portfolioItems;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Portfolio & Previous Work', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 8),
            const Text('Add projects to prove your skills to clients.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No portfolio items added yet.')))
            else
              ...items.map((item) => Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(item['title'] ?? 'Project', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(item['description'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {},
                  ),
                ),
              )).toList(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Get.snackbar('Coming Soon', 'Portfolio management will be fully integrated in the next update!');
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500)),
              child: const Text('Add Portfolio Project'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPayoutSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Payout Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
        const SizedBox(height: 8),
        const Text('Configure how you receive your earnings. These details remain private and are only used for processing payments.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        const Text('Preferred Payout Method', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _preferredPayoutMethod,
          items: const [
            DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
            DropdownMenuItem(value: 'Mobile Money', child: Text('Mobile Money')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _preferredPayoutMethod = v);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),
        if (_preferredPayoutMethod == 'Bank Transfer') ...[
          _buildTextField('Bank Name', _bankNameController),
          _buildTextField('Account Name', _bankAccountNameController),
          _buildTextField('Account Number', _bankAccountNumberController, keyboardType: TextInputType.number),
        ] else ...[
          _buildTextField('Mobile Money Provider', _bankNameController, hint: 'e.g. MTN, Orange, Wave'),
          _buildTextField('Registered Name', _bankAccountNameController),
          _buildTextField('Mobile Money Number', _mobileMoneyNumberController, keyboardType: TextInputType.phone),
        ],
        _buildTextField('Preferred Currency', _payoutCurrencyController, hint: 'e.g. XOF, USD, NGN'),
      ],
    );
  }

  Widget _buildReferencesTab() {
    return GetBuilder<AppState>(
      builder: (appState) {
        final refs = appState.technicianReferences;
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Professional References', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                ElevatedButton.icon(
                  onPressed: () => _showAddReferenceModal(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001F3F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Add references or recommendations from past employers or clients. This builds trust and helps verification.', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            if (refs.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('No references added yet. Click Add to create one.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ...refs.map((r) => Card(
                elevation: 0,
                color: const Color(0xFFF8FAFC),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(r['reference_name'] ?? 'Unknown Reference', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Relationship: ${r["relationship"] ?? ""}'),
                      Text('Contact: ${r["contact_info"] ?? ""}'),
                      if (r['employer_name'] != null && r['employer_name'].toString().isNotEmpty)
                        Text('Employer: ${r["employer_name"]}'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: r['status'] == 'Verified' ? Colors.green.shade100 : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r['status'] ?? 'Pending',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: r['status'] == 'Verified' ? Colors.green.shade800 : Colors.orange.shade800,
                          ),
                        ),
                      )
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete Reference?'),
                          content: const Text('Are you sure you want to remove this reference?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        try {
                          await appState.removeReference(r['id']);
                          Get.snackbar('Success', 'Reference removed.');
                        } catch (e) {
                          Get.snackbar('Error', 'Failed to remove reference.');
                        }
                      }
                    },
                  ),
                ),
              )).toList(),
          ],
        );
      },
    );
  }

  void _showAddReferenceModal(BuildContext context) {
    final nameCtrl = TextEditingController();
    final relCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final empCtrl = TextEditingController();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Reference', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Reference Name')),
              const SizedBox(height: 12),
              TextField(controller: relCtrl, decoration: const InputDecoration(labelText: 'Relationship (e.g. Manager)')),
              const SizedBox(height: 12),
              TextField(controller: contactCtrl, decoration: const InputDecoration(labelText: 'Contact Info (Phone/Email)')),
              const SizedBox(height: 12),
              TextField(controller: empCtrl, decoration: const InputDecoration(labelText: 'Employer/Company (Optional)')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4500),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty || contactCtrl.text.isEmpty) {
                      Get.snackbar('Error', 'Name and Contact Info are required');
                      return;
                    }
                    try {
                      await Get.find<AppState>().addReference({
                        'reference_name': nameCtrl.text.trim(),
                        'relationship': relCtrl.text.trim(),
                        'contact_info': contactCtrl.text.trim(),
                        'employer_name': empCtrl.text.trim(),
                        'recommendation_document_url': '',
                      });
                      Navigator.pop(ctx);
                      Get.snackbar('Success', 'Reference added successfully.');
                    } catch (e) {
                      Get.snackbar('Error', 'Failed to add reference.');
                    }
                  },
                  child: const Text('Add Reference', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
