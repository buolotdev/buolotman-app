import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:country_picker/country_picker.dart';

import 'app_state.dart';
import 'login_screen.dart';
import 'otp_screen.dart';
import 'main_navigation_screen.dart';
import 'google_role_selection_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Step 1 Fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  Country? _selectedCountry;
  String _phoneNumber = '';
  bool _obscurePassword = true;

  // Step 2 Fields
  String _selectedIntent = 'Hire a technician';
  
  final Map<String, String> _intentToRole = {
    'Hire a technician': 'Client',
    'Hire a company': 'Client',
    'Post a task': 'Client',
    'Offer my services': 'Technician',
    'Register my business': 'Company',
  };

  // Step 3 Fields
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _serviceLocationController = TextEditingController();
  bool _termsAccepted = true;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _serviceLocationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty || 
          _emailController.text.trim().isEmpty || 
          _passwordController.text.trim().isEmpty ||
          _phoneNumber.isEmpty ||
          _selectedCountry == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
        return;
      }
    }
    
    if (_currentStep < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep++);
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _currentStep--);
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _submitRegistration() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please accept the Terms of Service.')));
      return;
    }

    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your city.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500))),
      ),
    );

    try {
      final role = _intentToRole[_selectedIntent] ?? 'Client';

      final otpRes = await AppStateScope.of(context).registerUser(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        phone: _phoneNumber.trim(),
        role: role,
        // Optional fields originally used for Company are ignored here per new progressive flow
      );

      final challengeId = otpRes['challenge_id'] as int;
      final otpCode = otpRes['code']?.toString();

      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              email: _emailController.text.trim(),
              role: role,
              challengeId: challengeId,
              otpCode: otpCode,
              purpose: 'register',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required String hint, IconData? icon, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
              children: const [
                TextSpan(text: " *", style: TextStyle(color: Color(0xFFEF4444))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword ? _obscurePassword : false,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
              prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF64748B)) : null,
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: const Color(0xFF64748B)),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Create Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          const Text("Let's get started. Enter your basic information.", style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(child: _buildTextField(controller: _firstNameController, label: "First Name", hint: "John", icon: Icons.person_outline)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(controller: _lastNameController, label: "Last Name", hint: "Doe", icon: null)),
            ],
          ),
          _buildTextField(controller: _emailController, label: "Email Address", hint: "name@example.com", icon: Icons.email_outlined),
          
          const Text("Phone Number", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          IntlPhoneField(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
            ),
            initialCountryCode: 'US',
            onChanged: (phone) {
              _phoneNumber = phone.completeNumber;
            },
          ),
          const SizedBox(height: 20),
          
          _buildTextField(controller: _passwordController, label: "Password", hint: "••••••••", icon: Icons.lock_outline, isPassword: true),
          
          RichText(
            text: const TextSpan(
              text: "Country",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
              children: [
                TextSpan(text: " *", style: TextStyle(color: Color(0xFFEF4444))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              showCountryPicker(
                context: context,
                showPhoneCode: false,
                onSelect: (Country country) {
                  setState(() {
                    _selectedCountry = country;
                  });
                },
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (_selectedCountry != null) ...[
                    Text(_selectedCountry!.flagEmoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_selectedCountry!.name, style: const TextStyle(fontSize: 15, color: Color(0xFF001F3F)))),
                  ] else ...[
                    const Icon(Icons.public, color: Color(0xFF64748B)),
                    const SizedBox(width: 12),
                    const Expanded(child: Text("Select Country", style: TextStyle(color: Color(0xFF64748B), fontSize: 15))),
                  ],
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
          
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Next", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Already have an account?", style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const LoginScreen())),
                child: const Text("Log In", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("What are you looking for?", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          const Text("Select how you intend to use Boulot Man.", style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          
          ..._intentToRole.keys.map((intent) {
            final isSelected = _selectedIntent == intent;
            return GestureDetector(
              onTap: () => setState(() => _selectedIntent = intent),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFFFF4500).withOpacity(0.05) : Colors.white,
                  border: Border.all(color: isSelected ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0), width: isSelected ? 2 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? const Color(0xFFFF4500) : const Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 16),
                    Text(intent, style: TextStyle(fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF001F3F))),
                  ],
                ),
              ),
            );
          }).toList(),
          
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Next", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text("Location", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          const Text("Where are you located?", style: TextStyle(fontSize: 15, color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          
          _buildTextField(controller: _cityController, label: "City", hint: "e.g. Douala", icon: Icons.location_city),
          
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Service Location / Address (Optional)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                const SizedBox(height: 8),
                TextField(
                  controller: _serviceLocationController,
                  decoration: InputDecoration(
                    hintText: "e.g. Akwa",
                    hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                    prefixIcon: const Icon(Icons.map, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _termsAccepted = !_termsAccepted),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _termsAccepted ? const Color(0xFFFF4500) : Colors.white,
                    border: Border.all(color: _termsAccepted ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: _termsAccepted ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text("By creating an account, you agree to our Terms of Service and Privacy Policy.", style: TextStyle(color: Color(0xFF64748B), height: 1.5)),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _submitRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Create Account", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFEFEFF),
        elevation: 0,
        leading: Center(
          child: GestureDetector(
            onTap: _prevPage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_back, size: 20, color: Color(0xFF001F3F)),
            ),
          ),
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: Text(
                "Step ${_currentStep + 1} of 3",
                style: const TextStyle(color: Color(0xFFFF4500), fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_currentStep + 1) / 3,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
              minHeight: 4,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
