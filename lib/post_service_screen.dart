import 'package:flutter/material.dart';
import 'app_state.dart';

class PostServiceScreen extends StatefulWidget {
  const PostServiceScreen({super.key});

  @override
  State<PostServiceScreen> createState() => _PostServiceScreenState();
}

class _PostServiceScreenState extends State<PostServiceScreen> {
  int _currentStep = 1;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _coverageController = TextEditingController();
  final TextEditingController _availabilityController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  String _selectedCategory = 'Electrical';
  String _serviceType = 'On-site';
  String _pricingModel = 'Fixed Price';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _coverageController.dispose();
    _availabilityController.dispose();
    _rateController.dispose();
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Post a Service", style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(24),
              child: _buildStepContent(),
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
        color: isActive ? const Color(0xFFFF4500) : const Color(0xFFF1F5F9),
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
        color: isActive ? const Color(0xFFFF4500) : const Color(0xFFF1F5F9),
      ),
    );
  }

  Widget _buildStepContent() {
    if (_currentStep == 1) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Service Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          const Text("Give your service a catchy title and category.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          _buildLabel("Service Title"),
          _buildTextField("e.g. Professional Home Electrical Wiring", _titleController),
          const SizedBox(height: 24),
          _buildLabel("Category"),
          _buildDropdown(['Electrical', 'Plumbing', 'Cleaning', 'Tech', 'Carpentry']),
          const SizedBox(height: 24),
          _buildLabel("Description"),
          _buildTextField("Describe what you offer in detail...", _descController, maxLines: 5),
        ],
      );
    } else if (_currentStep == 2) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Location & Type", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          const Text("Where and how do you provide this service?", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          _buildLabel("Service Type"),
          Row(
            children: [
              _buildOptionChip("On-site", _serviceType == "On-site"),
              const SizedBox(width: 12),
              _buildOptionChip("Remote", _serviceType == "Remote"),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel("Coverage Area"),
          _buildTextField("e.g. Brooklyn, Queens, Manhattan", _coverageController),
          const SizedBox(height: 24),
          _buildLabel("Availability"),
          _buildTextField("e.g. Weekdays 9 AM - 6 PM", _availabilityController),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Pricing & Preview", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          const Text("Set your rates and review your listing.", style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 32),
          _buildLabel("Pricing Model"),
          Row(
            children: [
              _buildOptionChip("Fixed Price", _pricingModel == "Fixed Price"),
              const SizedBox(width: 12),
              _buildOptionChip("Hourly Rate", _pricingModel == "Hourly Rate"),
            ],
          ),
          const SizedBox(height: 24),
          _buildLabel("Rate"),
          _buildTextField("\$ Amount", _rateController, keyboardType: TextInputType.number),
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

  Widget _buildTextField(String hint, TextEditingController? controller, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
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

  Widget _buildDropdown(List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCategory,
          isExpanded: true,
          onChanged: (val) => setState(() => _selectedCategory = val!),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildOptionChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == "On-site" || label == "Remote") _serviceType = label;
          if (label == "Fixed Price" || label == "Hourly Rate") _pricingModel = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF001F3F) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.w600),
        ),
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
                onPressed: () => setState(() => _currentStep--),
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
              onPressed: () async {
                if (_currentStep < 3) {
                  setState(() => _currentStep++);
                } else {
                  final rateValue = _rateController.text.trim();
                  final priceLabel = rateValue.isEmpty
                      ? (_pricingModel == 'Hourly Rate' ? 'From \$45/hr' : 'Fixed price')
                      : (_pricingModel == 'Hourly Rate'
                          ? 'From \$$rateValue/hr'
                          : '\$$rateValue');

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
                    await AppStateScope.of(context).publishService(
                      title: _titleController.text.trim().isEmpty ? 'Untitled Service' : _titleController.text.trim(),
                      category: _selectedCategory,
                      description: _descController.text.trim().isEmpty ? 'No description provided.' : _descController.text.trim(),
                      priceLabel: priceLabel,
                      providerName: AppStateScope.of(context).currentUser.name,
                      providerAvatar: AppStateScope.of(context).currentUser.avatar,
                      providerRole: AppStateScope.of(context).currentUser.role,
                      serviceType: _serviceType,
                      coverageArea: _coverageController.text.trim().isEmpty ? 'Coverage area not specified' : _coverageController.text.trim(),
                      availability: _availabilityController.text.trim().isEmpty ? 'Availability not specified' : _availabilityController.text.trim(),
                      pricingModel: _pricingModel,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(); // Dismiss loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Service published successfully.')),
                      );
                      Navigator.pop(context);
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
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              child: Text(_currentStep == 3 ? "Publish Service" : "Next Step"),
            ),
          ),
        ],
      ),
    );
  }
}
