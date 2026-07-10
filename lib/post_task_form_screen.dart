import 'package:flutter/material.dart';
import 'app_models.dart';
import 'post_task_step3_screen.dart';
import 'package:get/get.dart';
import 'app_state.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:convert';

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
  final _minBudgetController = TextEditingController(text: "100.00");
  final _maxBudgetController = TextEditingController(text: "250.00");
  final _locationController = TextEditingController(text: "");
  
  String _selectedCategory = "Plumbing & Repair";
  String _locationType = "On-site";
  String _timeline = "By Friday, Oct 25";
  String? _selectedDeadline;
  String _urgency = "Flexible"; // Added urgency §5.2.2
  String _selectedPaymentMethod = "Escrow / Wallet";
  String _budgetMode = "fixed"; // fixed or range
  String _selectedSubcategory = "";
  String? _base64Image;
  String? _base64ImageName;

  Map<String, List<String>> get _dynamicSubcategories {
    final Map<String, List<String>> map = {};
    final appState = AppStateScope.of(context);
    final roots = appState.apiCategories.where((c) => c['parent'] == null);
    for (var root in roots) {
      final name = root['name'].toString();
      final subs = appState.apiCategories
          .where((c) => c['parent'] == root['id'])
          .map((c) => c['name'].toString())
          .toList();
      map[name] = subs;
    }
    // Fallback if API hasn't loaded or is empty
    if (map.isEmpty) {
      map["Plumbing & Repair"] = ["Leak Repair", "Pipe Installation", "Water Heater", "Drain Cleaning", "Toilet Repair", "Faucet Install"];
      map["Electrical"] = ["Wiring & Rewiring", "Switchboard Repair", "Fan / AC Installation", "Generator Setup", "Light Fixtures", "Electrical Inspection"];
      map["Cleaning"] = ["Home Deep Clean", "Office Cleaning", "Carpet & Upholstery", "Post-Construction Clean", "Window Cleaning", "Disinfection"];
      map["Carpentry"] = ["Furniture Assembly", "Door & Window Frames", "Custom Shelving", "Cabinet Making", "Wood Repair", "Flooring"];
      map["Painting"] = ["Interior Painting", "Exterior Painting", "Wallpaper", "Surface Prep & Sanding", "Texture Coating", "Graffiti Removal"];
      map["Repair"] = ["Appliance Repair", "Roof Repair", "Wall Crack Repair", "Tile & Grout", "Window Repair", "Gate & Fence Repair"];
    }
    return map;
  }

  void _showCategoryPicker() {
    final categories = _dynamicSubcategories.keys.toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Select Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    return ListTile(
                      title: Text(cat, style: const TextStyle(fontWeight: FontWeight.w500)),
                      trailing: _selectedCategory == cat ? const Icon(Icons.check, color: Color(0xFFFF4500)) : null,
                      onTap: () {
                        setState(() {
                          _selectedCategory = cat;
                          _selectedSubcategory = ""; // reset subcategory when category changes
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showTimelinePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF4500),
              onPrimary: Colors.white,
              onSurface: Color(0xFF001F3F),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      final weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
      final formatted = "By ${weekdays[picked.weekday % 7]}, ${months[picked.month - 1]} ${picked.day}";
      setState(() {
        _timeline = formatted;
        _selectedDeadline = picked.toIso8601String().substring(0, 10);
      });
    }
  }

  void _showPaymentMethodPicker() {
    final methods = ["Escrow / Wallet", "Card Payment", "Bank Transfer", "Cash on Delivery"];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              const Text(
                "Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
              ),
              const SizedBox(height: 8),
              const Divider(),
              Column(
                children: methods.map((method) {
                  return ListTile(
                    title: Text(method, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: _selectedPaymentMethod == method ? const Icon(Icons.check, color: Color(0xFFFF4500)) : null,
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = method;
                      });
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
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
                      
                      _buildLabel("Category & Subcategory"),
                      _buildDropdownField(_selectedCategory, Icons.chevron_right, onTap: _showCategoryPicker),
                      const SizedBox(height: 10),
                      _buildDropdownField(
                        _selectedSubcategory.isEmpty ? "Select subcategory" : _selectedSubcategory,
                        Icons.chevron_right,
                        onTap: () {
                          if (_selectedCategory.isEmpty) return;
                          final subs = _dynamicSubcategories[_selectedCategory] ?? [];
                          if (subs.isEmpty) return;
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.white,
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            ),
                            builder: (ctx) => SafeArea(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(height: 16),
                                  const Text("Select Subcategory", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                                  const SizedBox(height: 8),
                                  const Divider(),
                                  Flexible(
                                    child: ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: subs.length,
                                      itemBuilder: (context, i) {
                                        final sub = subs[i];
                                        return ListTile(
                                          title: Text(sub, style: const TextStyle(fontWeight: FontWeight.w500)),
                                          trailing: _selectedSubcategory == sub ? const Icon(Icons.check, color: Color(0xFFFF4500)) : null,
                                          onTap: () {
                                            setState(() => _selectedSubcategory = sub);
                                            Navigator.pop(ctx);
                                          },
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          );
                        },
                        muted: _selectedSubcategory.isEmpty,
                      ),
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
                          final appState = Get.find<AppState>();
                          final detectedCountry = appState.currentUser.country.isNotEmpty ? appState.currentUser.country : "Nigeria";
                          final detectedCity = detectedCountry == "Pakistan" ? "Lahore"
                              : detectedCountry == "United States" ? "New York"
                              : detectedCountry == "Kenya" ? "Nairobi"
                              : detectedCountry == "South Africa" ? "Cape Town"
                              : detectedCountry == "Ghana" ? "Accra"
                              : "Lagos";
                          setState(() {
                            _locationController.text = detectedCountry == "Pakistan"
                                ? "Suite 205, Johar Town"
                                : "Suite 104, Lagos Wharf";
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Location detected: $detectedCity, $detectedCountry")),
                          );
                        },
                        child: Row(
                          children: const [
                            Icon(Icons.my_location, size: 14, color: Color(0xFFFF4500)),
                            SizedBox(width: 4),
                            Text("Detect My Location (IP-based)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFFF4500))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      
                      _buildLabel("Estimated Budget"),
                      _buildBudgetSection(),
                      const SizedBox(height: 28),
                      
                      _buildLabel("When do you need this done?"),
                      _buildDropdownField(_timeline, Icons.calendar_today_outlined, onTap: _showTimelinePicker),
                      const SizedBox(height: 28),

                      _buildLabel("Urgency"),
                      _buildUrgencySelector(),
                      const SizedBox(height: 28),
                      
                      _buildLabel("Preferred Payment Method"),
                      _buildDropdownField(_selectedPaymentMethod, Icons.payment_outlined, onTap: _showPaymentMethodPicker),
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
                "Step 1 of 2",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFFF4500),
                ),
              ),
              Text(
                "Task Details (Draft)",
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
              widthFactor: 0.5,
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

  Widget _buildDropdownField(String value, IconData icon, {VoidCallback? onTap, bool muted = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                style: TextStyle(
                  fontSize: 15,
                  color: muted ? const Color(0xFFADB5BD) : const Color(0xFF001F3F),
                  fontWeight: muted ? FontWeight.w400 : FontWeight.w500,
                ),
              ),
            ),
            Icon(icon, color: const Color(0xFF64748B), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadZone() {
    return GestureDetector(
      onTap: () async {
        try {
          final result = await fp.FilePicker.pickFiles(
            type: fp.FileType.image,
            withData: true,
          );
          if (result != null && result.files.isNotEmpty) {
            final file = result.files.first;
            final bytes = file.bytes;
            if (bytes != null) {
              final ext = file.extension ?? 'png';
              final b64 = base64Encode(bytes);
              setState(() {
                _base64Image = 'data:image/$ext;base64,$b64';
                _base64ImageName = file.name;
              });
            }
          }
        } catch (e) {
          debugPrint('Error picking file: $e');
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 2, style: BorderStyle.none), // Simplified
          borderRadius: BorderRadius.circular(12),
        ),
        width: double.infinity,
        child: Column(
          children: [
            const Icon(Icons.cloud_upload_outlined, color: Color(0xFFFF4500), size: 32),
            const SizedBox(height: 8),
            Text(
              _base64ImageName ?? "Tap to upload photos or videos",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
            ),
            const SizedBox(height: 4),
            Text(
              _base64Image != null ? "File attached successfully" : "Max file size 10MB",
              style: TextStyle(fontSize: 12, color: _base64Image != null ? const Color(0xFF1E8E3E) : const Color(0xFF64748B), fontWeight: _base64Image != null ? FontWeight.bold : FontWeight.normal),
            ),
            if (_base64Image != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 100,
                  width: 100,
                  child: buildAvatarImage(_base64Image!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _base64Image = null;
                    _base64ImageName = null;
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 16),
                label: const Text("Remove Attachment", style: TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold)),
              )
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTabs() {
    return Row(
      children: [
        Expanded(child: _buildLocationTab("On-site", Icons.location_on_outlined)),
        const SizedBox(width: 8),
        Expanded(child: _buildLocationTab("Remote", Icons.monitor)),
        const SizedBox(width: 8),
        Expanded(child: _buildLocationTab("Hybrid", Icons.business_outlined)),
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

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _budgetMode = "fixed"),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _budgetMode == "fixed" ? const Color(0xFF001F3F) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Fixed Budget",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _budgetMode == "fixed" ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _budgetMode = "range"),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _budgetMode == "range" ? const Color(0xFF001F3F) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Budget Range",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _budgetMode == "range" ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_budgetMode == "fixed")
          Row(
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
          )
        else
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Min Budget", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text("\$", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_minBudgetController, "Min")),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Max Budget", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Text("\$", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField(_maxBudgetController, "Max")),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
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
          // Read country from profile at submit time (profile is guaranteed loaded by now)
          final appState = Get.find<AppState>();
          final String userCountry = appState.currentUser.country.isNotEmpty ? appState.currentUser.country : 'Nigeria';
          final String userCity = userCountry == 'Pakistan' ? 'Lahore'
              : userCountry == 'United States' ? 'New York'
              : userCountry == 'Kenya' ? 'Nairobi'
              : userCountry == 'South Africa' ? 'Cape Town'
              : userCountry == 'Ghana' ? 'Accra'
              : 'Lagos';

          final isFixed = _budgetMode == "fixed";
          final double budgetVal = double.tryParse(isFixed ? _budgetController.text.trim() : _maxBudgetController.text.trim()) ?? 0.0;
          final double budgetMinVal = double.tryParse(isFixed ? _budgetController.text.trim() : _minBudgetController.text.trim()) ?? 0.0;
          final double budgetMaxVal = double.tryParse(isFixed ? _budgetController.text.trim() : _maxBudgetController.text.trim()) ?? 0.0;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostTaskStep3Screen(
                draft: TaskDraft(
                  title: _titleController.text.trim(),
                  description: _descriptionController.text.trim(),
                  category: _selectedCategory,
                  locationType: _locationType,
                  location: _locationController.text.trim(),
                  timeline: _timeline,
                  urgency: _urgency,
                  paymentMethod: _selectedPaymentMethod,
                  budget: budgetVal,
                  budgetMin: budgetMinVal,
                  budgetMax: budgetMaxVal,
                  budgetMode: _budgetMode,
                  city: userCity,
                  country: userCountry,
                  duration: '1 - 3 hrs',
                  isRecurring: false,
                  deadline: _selectedDeadline,
                  imageUrl: _base64Image,
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
            Text("Next (Preview)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
