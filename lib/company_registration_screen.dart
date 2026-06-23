import 'package:flutter/material.dart';

import 'app_state.dart';

class CompanyRegistrationScreen extends StatefulWidget {
  const CompanyRegistrationScreen({super.key});

  @override
  State<CompanyRegistrationScreen> createState() => _CompanyRegistrationScreenState();
}

class _CompanyRegistrationScreenState extends State<CompanyRegistrationScreen> {
  int _currentStep = 1;
  bool _isLoading = false;
  final _companyNameController = TextEditingController(text: 'BuildRight Construction');
  final _industryController = TextEditingController(text: 'Construction & Engineering');
  final _emailController = TextEditingController(text: 'contact@company.com');
  final _websiteController = TextEditingController(text: 'www.company.com');
  final _registrationNumberController = TextEditingController(text: 'REG-123456789');
  final _taxIdController = TextEditingController(text: 'TAX-987654321');
  final _addressController = TextEditingController(text: '123 Market Road, Lagos, Nigeria');

  @override
  void dispose() {
    _companyNameController.dispose();
    _industryController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _registrationNumberController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
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
          icon: const Icon(Icons.close, color: Color(0xFF001F3F)),
          onPressed: _isLoading ? null : () => Navigator.pop(context),
        ),
        title: const Text("Register Business", style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
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
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStepCircle(1),
          _buildStepLine(1),
          _buildStepCircle(2),
          _buildStepLine(2),
          _buildStepCircle(3),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step) {
    bool isActive = _currentStep >= step;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF001F3F) : const Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          step.toString(),
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStepLine(int step) {
    bool isActive = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        color: isActive ? const Color(0xFF001F3F) : const Color(0xFFF1F5F9),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Business Details", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          const Text("Provide the legal name and basic information of your company.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          _buildLabel("Company Name"),
          _buildTextField(_companyNameController, "e.g. Boulot Services Ltd."),
          const SizedBox(height: 24),
          _buildLabel("Industry"),
          _buildTextField(_industryController, "e.g. Construction & Engineering"),
          const SizedBox(height: 24),
          _buildLabel("Business Email"),
          _buildTextField(_emailController, "e.g. contact@company.com"),
          const SizedBox(height: 24),
          _buildLabel("Company Website (Optional)"),
          _buildTextField(_websiteController, "e.g. www.company.com"),
        ],
      );
    } else if (_currentStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Legal & Tax", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          const Text("Enter your business registration and tax details.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          _buildLabel("Registration Number"),
          _buildTextField(_registrationNumberController, "e.g. REG-123456789"),
          const SizedBox(height: 24),
          _buildLabel("Tax ID / VAT Number"),
          _buildTextField(_taxIdController, "e.g. TAX-987654321"),
          const SizedBox(height: 24),
          _buildLabel("Registered Office Address"),
          _buildTextField(_addressController, "Full address...", maxLines: 2),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Document Upload", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          const Text("Upload legal documents for business verification.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          _buildUploadBox("Certificate of Incorporation", Icons.file_present_outlined),
          const SizedBox(height: 16),
          _buildUploadBox("Business License", Icons.verified_user_outlined),
          const SizedBox(height: 16),
          _buildUploadBox("Tax Clearance Certificate", Icons.receipt_long_outlined),
          const SizedBox(height: 12),
          const Text("Allowed formats: PDF, JPG, PNG (Max 10MB per file)", style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      );
    }
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

  Widget _buildUploadBox(String label, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: Icon(icon, color: const Color(0xFF001F3F), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          ),
          const Icon(Icons.upload_file, color: Color(0xFFFF4500), size: 20),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
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
                ),
                child: const Text("Previous", style: TextStyle(color: Color(0xFF001F3F))),
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
                          await AppStateScope.of(context).submitCompanyRegistration(
                            details: {
                              'companyName': _companyNameController.text.trim(),
                              'industry': _industryController.text.trim(),
                              'email': _emailController.text.trim(),
                              'website': _websiteController.text.trim(),
                              'registrationNumber': _registrationNumberController.text.trim(),
                              'taxId': _taxIdController.text.trim(),
                              'address': _addressController.text.trim(),
                            },
                          );
                          _showSuccessDialog();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Registration failed: ${e.toString().replaceAll('Exception: ', '')}'),
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
                  : Text(_currentStep == 3 ? "Submit Application" : "Next Step"),
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
              child: const Icon(Icons.check, color: Color(0xFF1E8E3E), size: 32),
            ),
            const SizedBox(height: 24),
            const Text("Application Submitted", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 12),
            const Text(
              "Your company registration is now being reviewed by our compliance team. We'll get back to you within 3-5 business days.",
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
