import 'package:flutter/material.dart';
import 'app_models.dart';
import 'post_task_step2_screen.dart';

class PostTaskFormScreen extends StatefulWidget {
  const PostTaskFormScreen({super.key});

  @override
  State<PostTaskFormScreen> createState() => _PostTaskFormScreenState();
}

class _PostTaskFormScreenState extends State<PostTaskFormScreen> {
  final _titleController = TextEditingController(text: "Fix a leaking kitchen sink pipe");
  final _descriptionController = TextEditingController(
    text: "The pipe under the kitchen sink is leaking heavily and causing water damage to the cabinet. I need someone to come fix or replace it as soon as possible. I can provide pictures if needed.",
  );
  final _budgetController = TextEditingController(text: "150.00");
  final _locationController = TextEditingController(text: "123 Main St, New York, NY");
  
  String _selectedCategory = "Plumbing & Repair";
  String _locationType = "On-site";
  String _timeline = "By Friday, Oct 25";
  String _urgency = "Flexible"; // Added urgency §5.2.2
  String _selectedPaymentMethod = "Escrow / Wallet";

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Task Title"),
                      _buildTextField(_titleController, "Enter task title"),
                      const SizedBox(height: 28),
                      
                      _buildLabel("Category"),
                      _buildDropdownField(_selectedCategory, Icons.chevron_right),
                      const SizedBox(height: 28),
                      
                      _buildLabel("Description"),
                      _buildTextArea(_descriptionController, "Provide as much detail as possible..."),
                      const SizedBox(height: 8),
                      const Text(
                        "Please provide as much detail as possible. Minimum 50 characters.",
                        style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 28),
                      
                      _buildLabel("Attachments (Optional)"),
                      _buildUploadZone(),
                      const SizedBox(height: 28),
                      
                      _buildLabel("Location"),
                      _buildLocationTabs(),
                      const SizedBox(height: 12),
                      _buildTextField(_locationController, "Enter address", icon: Icons.map),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          setState(() => _locationController.text = "Lagos, Nigeria");
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.my_location, size: 14, color: Color(0xFFFF4500)),
                            SizedBox(width: 4),
                            Text("Detect My Location", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      _buildLabel("Estimated Budget"),
                      _buildBudgetField(),
                      const SizedBox(height: 28),
                      
                      _buildLabel("When do you need this done?"),
                      _buildDropdownField(_timeline, Icons.calendar_today_outlined),
                      const SizedBox(height: 28),

                      _buildLabel("Urgency"),
                      _buildUrgencySelector(),
                      const SizedBox(height: 28),
                      
                      _buildLabel("Preferred Payment Method"),
                      _buildDropdownField(_selectedPaymentMethod, Icons.payment_outlined),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
          ),
          const Text(
            "Post a Task",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF001F3F),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Icon(Icons.close, color: Color(0xFF001F3F)),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Step 1 of 3",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF4500),
                ),
              ),
              Text(
                "Task Details",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF001F3F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.33,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4500),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF001F3F),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF64748B), size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              style: const TextStyle(fontSize: 15, color: Color(0xFF001F3F), fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextArea(TextEditingController controller, String hint) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        maxLines: 5,
        style: const TextStyle(fontSize: 15, color: Color(0xFF001F3F), fontWeight: FontWeight.w500, height: 1.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF64748B)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String value, IconData icon) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, color: Color(0xFF001F3F), fontWeight: FontWeight.w500),
            ),
          ),
          Icon(icon, color: const Color(0xFF64748B), size: 20),
        ],
      ),
    );
  }

  Widget _buildUploadZone() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2, style: BorderStyle.none), // Simplified
        borderRadius: BorderRadius.circular(12),
      ),
      width: double.infinity,
      child: Column(
        children: const [
          Icon(Icons.cloud_upload_outlined, color: Color(0xFFFF4500), size: 32),
          SizedBox(height: 8),
          Text(
            "Tap to upload photos or videos",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
          ),
          SizedBox(height: 4),
          Text(
            "Max file size 10MB",
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationTabs() {
    return Row(
      children: [
        Expanded(child: _buildLocationTab("On-site", Icons.map_outlined)),
        const SizedBox(width: 12),
        Expanded(child: _buildLocationTab("Remote", Icons.monitor)),
      ],
    );
  }

  Widget _buildLocationTab(String type, IconData icon) {
    final bool isActive = _locationType == type;
    return GestureDetector(
      onTap: () => setState(() => _locationType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF0EB) : Colors.white,
          border: Border.all(color: isActive ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isActive ? const Color(0xFFFF4500) : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFFFF4500) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetField() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Text(
            "\$",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: _buildTextField(_budgetController, "0.00")),
      ],
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ElevatedButton(
        onPressed: () {
          final budget = double.tryParse(_budgetController.text.trim()) ?? 0;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostTaskStep2Screen(
                draft: TaskDraft(
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim(),
                  category: _selectedCategory,
                  locationType: _locationType,
                  location: _locationController.text.trim(),
                  timeline: _timeline,
                  urgency: _urgency,
                  paymentMethod: _selectedPaymentMethod,
                  budget: budget,
                  duration: '1 - 3 hrs',
                  isRecurring: false,
                ),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4500),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Next", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 12),
            Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencySelector() {
    final options = ["Urgent", "Flexible", "Programmed"];
    return Row(
      children: options.map((opt) {
        final isActive = _urgency == opt;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _urgency = opt),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFF001F3F) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                opt,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
