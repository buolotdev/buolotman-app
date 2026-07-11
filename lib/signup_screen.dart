import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

import 'app_state.dart';
import 'login_screen.dart';
import 'otp_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  String _selectedRole = 'Client'; // 'Client', 'Technician', 'Company'
  bool _obscurePassword = true;
  bool _termsAccepted = true;
  String _phoneNumber = '';
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _regNumController = TextEditingController();
  final TextEditingController _taxIdController = TextEditingController();
  final TextEditingController _industryController = TextEditingController();
  int _passwordStrength = 0;
  String _passwordStrengthText = "";
  Color _passwordStrengthColor = const Color(0xFFE2E8F0);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _regNumController.dispose();
    _taxIdController.dispose();
    _industryController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength(String password) {
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = 0;
        _passwordStrengthText = "";
      } else if (password.length < 6) {
        _passwordStrength = 1;
        _passwordStrengthText = "Weak password";
        _passwordStrengthColor = const Color(0xFFEF4444); // Red
      } else if (password.length < 8) {
        _passwordStrength = 2;
        _passwordStrengthText = "Fair password";
        _passwordStrengthColor = const Color(0xFFF59E0B); // Orange
      } else if (password.length >= 10 && password.contains(RegExp(r'[0-9]'))) {
        _passwordStrength = 4;
        _passwordStrengthText = "Strong password";
        _passwordStrengthColor = const Color(0xFF10B981); // Green
      } else {
        _passwordStrength = 3;
        _passwordStrengthText = "Good password";
        _passwordStrengthColor = const Color(0xFF10B981); // Green
      }
    });
  }

  Widget _buildRoleOption(String title, IconData icon) {
    final bool isActive = _selectedRole == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 88,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF4500).withOpacity(0.04) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? const Color(0xFFFF4500) : const Color(0xFF64748B),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFFFF4500) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
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
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back,
                size: 20,
                color: Color(0xFF001F3F),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                      // Header Text
                      const Text(
                        "Create Account",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF001F3F),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Join Boulot Man to find trusted professionals or start earning today.",
                        style: TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Role Selector
                      const Text(
                        "I want to join as a",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF001F3F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildRoleOption("Client", Icons.person_outline)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildRoleOption("Technician", Icons.build_outlined)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildRoleOption("Company", Icons.domain)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Full Name
                      RichText(
                        text: TextSpan(
                          text: _selectedRole == "Company" ? "Company Name" : "Full Name",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                          children: [
                            TextSpan(text: " *", style: TextStyle(color: Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: _selectedRole == "Company" ? "e.g. Acme Corp" : "e.g. John Doe",
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                          prefixIcon: Icon(_selectedRole == "Company" ? Icons.business : Icons.person_outline, color: const Color(0xFF64748B)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_selectedRole == "Company") ...[
                        // Registration Number
                        RichText(
                          text: const TextSpan(
                            text: "Registration Number",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _regNumController,
                          decoration: InputDecoration(
                            hintText: "e.g. RC-123456",
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                            prefixIcon: const Icon(Icons.numbers, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tax ID
                        RichText(
                          text: const TextSpan(
                            text: "Tax ID (Optional)",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _taxIdController,
                          decoration: InputDecoration(
                            hintText: "e.g. 000-111-222",
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                            prefixIcon: const Icon(Icons.receipt_long, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Industry
                        RichText(
                          text: const TextSpan(
                            text: "Industry",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _industryController,
                          decoration: InputDecoration(
                            hintText: "e.g. Real Estate, Plumbing, Tech",
                            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                            prefixIcon: const Icon(Icons.category_outlined, color: Color(0xFF64748B)),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Email Address
                      RichText(
                        text: const TextSpan(
                          text: "Email Address",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                          children: [
                            TextSpan(text: " *", style: TextStyle(color: Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: "name@example.com",
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15),
                          prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phone Number
                      const Text(
                        "Phone Number",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                      ),
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

                      // Password
                      RichText(
                        text: const TextSpan(
                          text: "Password",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                          children: [
                            TextSpan(text: " *", style: TextStyle(color: Color(0xFFEF4444))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        onChanged: _checkPasswordStrength,
                        decoration: InputDecoration(
                          hintText: "••••••••",
                          hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 15, letterSpacing: 2),
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: const Color(0xFF64748B),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF001F3F))),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Password Strength
                      Row(
                        children: [
                          Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 4, decoration: BoxDecoration(color: _passwordStrength >= 1 ? _passwordStrengthColor : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(width: 6),
                          Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 4, decoration: BoxDecoration(color: _passwordStrength >= 2 ? _passwordStrengthColor : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(width: 6),
                          Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 4, decoration: BoxDecoration(color: _passwordStrength >= 3 ? _passwordStrengthColor : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                          const SizedBox(width: 6),
                          Expanded(child: AnimatedContainer(duration: const Duration(milliseconds: 300), height: 4, decoration: BoxDecoration(color: _passwordStrength >= 4 ? _passwordStrengthColor : const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2)))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_passwordStrengthText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _passwordStrengthColor)),
                      const SizedBox(height: 24),

                      // Checkbox
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _termsAccepted = !_termsAccepted;
                          });
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: _termsAccepted ? const Color(0xFFFF4500) : Colors.white,
                                border: Border.all(
                                  color: _termsAccepted ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: _termsAccepted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: RichText(
                                text: const TextSpan(
                                  text: "By creating an account, you agree to our ",
                                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
                                  children: [
                                    TextSpan(text: "Terms of Service", style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w600)),
                                    TextSpan(text: " and "),
                                    TextSpan(text: "Privacy Policy", style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w600)),
                                    TextSpan(text: "."),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            final fullName = _nameController.text.trim();
                            final email = _emailController.text.trim();
                            final password = _passwordController.text.trim();
                            final phone = _phoneNumber.trim();

                            if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill in all required fields.')),
                              );
                              return;
                            }

                            if (!_termsAccepted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please accept the Terms of Service.')),
                              );
                              return;
                            }

                            final parts = fullName.split(' ');
                            final firstName = parts.first;
                            final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';

                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) => const Center(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
                                ),
                              ),
                            );

                            try {
                              final otpRes = await AppStateScope.of(context).registerUser(
                                firstName: firstName,
                                lastName: lastName,
                                email: email,
                                password: password,
                                phone: phone,
                                role: _selectedRole,
                                registrationNumber: _selectedRole == 'Company' ? _regNumController.text.trim() : null,
                                taxId: _selectedRole == 'Company' ? _taxIdController.text.trim() : null,
                                industry: _selectedRole == 'Company' ? _industryController.text.trim() : null,
                              );
                              final challengeId = otpRes['challenge_id'] as int;
                              final otpCode = otpRes['code']?.toString();

                              if (context.mounted) {
                                Navigator.of(context).pop(); // Dismiss loading
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => OTPScreen(
                                      email: email,
                                      role: _selectedRole,
                                      challengeId: challengeId,
                                      otpCode: otpCode,
                                      purpose: 'register',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.of(context).pop(); // Dismiss loading
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4500),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 8,
                            shadowColor: const Color(0xFFFF4500).withOpacity(0.2),
                          ),
                          child: const Text(
                            "Create Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Login Prompt
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Already have an account?",
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => const LoginScreen()),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "Log In",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF4500),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
