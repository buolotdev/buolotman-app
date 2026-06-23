import 'package:flutter/material.dart';

import 'app_state.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  int _currentStep = 1;
  bool _isLoading = false;
  final _experienceController = TextEditingController(text: '5 years');
  final _specializationController = TextEditingController(text: 'Industrial Electrical Systems');
  final _bioController = TextEditingController(
    text: 'Certified technician with field experience in wiring, repairs, and compliance-ready installations.',
  );
  final _licenseController = TextEditingController(text: '#NY-89402');

  @override
  void dispose() {
    _experienceController.dispose();
    _specializationController.dispose();
    _bioController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text("Get Verified", style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: IgnorePointer(
                ignoring: _isLoading,
                child: _buildStepContent(),
              ),
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepDot(1),
          _buildStepLine(1),
          _buildStepDot(2),
          _buildStepLine(2),
          _buildStepDot(3),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step) {
    bool isActive = _currentStep >= step;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStepLine(int step) {
    bool isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Identity Verification", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 12),
          const Text("Upload a valid government-issued ID to confirm your identity.", style: TextStyle(color: Color(0xFF64748B), height: 1.5)),
          const SizedBox(height: 32),
          _buildUploadBox("Front of ID", Icons.credit_card_outlined),
          const SizedBox(height: 20),
          _buildUploadBox("Back of ID", Icons.credit_card_outlined),
          const SizedBox(height: 20),
          _buildUploadBox("Selfie with ID", Icons.face_outlined),
        ],
      );
    } else if (_currentStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Skill Screening", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 12),
          const Text("Tell us more about your professional background and skills.", style: TextStyle(color: Color(0xFF64748B), height: 1.5)),
          const SizedBox(height: 32),
          _buildLabel("Years of Experience"),
          _buildTextField(_experienceController, "e.g. 5 years"),
          const SizedBox(height: 24),
          _buildLabel("Core Specialization"),
          _buildTextField(_specializationController, "e.g. Industrial Electrical Systems"),
          const SizedBox(height: 24),
          _buildLabel("Brief Professional Bio"),
          _buildTextField(_bioController, "Write a short summary of your work...", maxLines: 4),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Certifications", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 12),
          const Text("Add any relevant licenses or professional certifications.", style: TextStyle(color: Color(0xFF64748B), height: 1.5)),
          const SizedBox(height: 32),
          _buildUploadBox("Upload Certificate", Icons.workspace_premium_outlined),
          const SizedBox(height: 12),
          const Text("PNG, JPG or PDF (Max 5MB)", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
          const SizedBox(height: 32),
          _buildLabel("License Number (Optional)"),
          _buildTextField(_licenseController, "e.g. #NY-89402"),
        ],
      );
    }
  }

  Widget _buildUploadBox(String label, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: const Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          const SizedBox(height: 4),
          const Text("Tap to upload", style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          if (_currentStep > 1)
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Back", style: TextStyle(color: Color(0xFF001F3F))),
              ),
            ),
          if (_currentStep > 1) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : () async {
                      if (_currentStep < 3) {
                        setState(() => _currentStep++);
                      } else {
                        setState(() {
                          _isLoading = true;
                        });
                        try {
                          await AppStateScope.of(context).submitVerification(
                            details: {
                              'experience': _experienceController.text.trim(),
                              'specialization': _specializationController.text.trim(),
                              'bio': _bioController.text.trim(),
                              'license': _licenseController.text.trim(),
                            },
                          );
                          _showSuccessDialog();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Verification submission failed: ${e.toString().replaceAll('Exception: ', '')}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(_currentStep == 3 ? "Submit for Review" : "Continue"),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: Color(0xFFE6F4EA), shape: BoxShape.circle),
              child: const Icon(Icons.access_time, color: Color(0xFF1E8E3E), size: 32),
            ),
            const SizedBox(height: 24),
            const Text("Under Review", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 12),
            const Text(
              "Your verification documents have been submitted. We'll notify you once our team has reviewed them (usually within 24-48 hours).",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Done"),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
