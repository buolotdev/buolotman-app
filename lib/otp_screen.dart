import 'package:flutter/material.dart';
import 'app_state.dart';
import 'main_navigation_screen.dart';
import 'notification_helper.dart';

class OTPScreen extends StatefulWidget {
  final String email;
  final String role;
  final int challengeId;
  final String? otpCode;
  final String purpose;

  const OTPScreen({
    super.key,
    required this.email,
    this.role = 'Client',
    required this.challengeId,
    this.otpCode,
    this.purpose = 'register',
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (index) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (index) => FocusNode());
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  late int _activeChallengeId;

  @override
  void initState() {
    super.initState();
    _activeChallengeId = widget.challengeId;
    if (widget.otpCode != null && widget.otpCode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // 1. Auto-fill the inputs
        for (int i = 0; i < widget.otpCode!.length && i < 4; i++) {
          _controllers[i].text = widget.otpCode![i];
        }
        // 2. Trigger native OS/system tray notification
        NotificationHelper.showNotification(
          'Boulot Man',
          'Your simulated OTP code is ${widget.otpCode}',
        );
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isForgotPassword = widget.purpose == 'forgot_password';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isForgotPassword ? "Reset Password" : "Verification Code",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
              ),
              const SizedBox(height: 12),
              Text(
                "Enter the 4-digit code sent to ${widget.email}",
                style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(4, (index) => _buildOTPBox(index)),
              ),
              if (isForgotPassword) ...[
                const SizedBox(height: 32),
                const Text(
                  "New Password",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF64748B),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Confirm New Password",
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Confirm new password',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () async {
                    final code = _controllers.map((c) => c.text.trim()).join();
                    if (code.length < 4) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a 4-digit code.')),
                      );
                      return;
                    }

                    if (isForgotPassword) {
                      final newPassword = _newPasswordController.text.trim();
                      final confirmPassword = _confirmPasswordController.text.trim();

                      if (newPassword.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a new password.')),
                        );
                        return;
                      }

                      if (newPassword != confirmPassword) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Passwords do not match.')),
                        );
                        return;
                      }

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
                        await AppStateScope.of(context).resetPassword(
                          challengeId: _activeChallengeId,
                          code: code,
                          newPassword: newPassword,
                        );
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Pop loader
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password reset successfully. Please log in.')),
                          );
                          Navigator.of(context).pop(); // Back to Login Screen
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Pop loader
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                          );
                        }
                      }
                    } else {
                      // Regular flow
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
                        await AppStateScope.of(context).verifyOTPAndLogin(_activeChallengeId, code);
                        if (context.mounted) {
                          Navigator.of(context).pop(); // Dismiss loading
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => MainNavigationScreen(
                                role: AppStateScope.of(context).currentRole,
                              ),
                            ),
                            (route) => false,
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
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4500),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    isForgotPassword ? "Reset Password" : "Verify & Continue",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () async {
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
                      final otpRes = await AppStateScope.of(context).requestOTP(widget.email, widget.purpose);
                      final newChallengeId = otpRes['challenge_id'] as int;
                      final newOtpCode = otpRes['code']?.toString();

                      if (context.mounted) {
                        Navigator.of(context).pop(); // Dismiss loading
                        
                        setState(() {
                          _activeChallengeId = newChallengeId;
                          if (newOtpCode != null && newOtpCode.isNotEmpty) {
                            for (int i = 0; i < newOtpCode.length && i < 4; i++) {
                              _controllers[i].text = newOtpCode[i];
                            }
                          }
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('A new verification code was sent.')),
                        );

                        if (newOtpCode != null && newOtpCode.isNotEmpty) {
                          NotificationHelper.showNotification(
                            'Boulot Man',
                            'Your new simulated OTP code is $newOtpCode',
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        Navigator.of(context).pop(); // Dismiss loading
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to resend code: ${e.toString().replaceAll('Exception: ', '')}')),
                        );
                      }
                    }
                  },
                  child: const Text("Resend Code", style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOTPBox(int index) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
          decoration: const InputDecoration(counterText: "", border: InputBorder.none),
          onChanged: (value) {
            if (value.isNotEmpty && index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}
