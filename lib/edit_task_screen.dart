import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'dart:convert';

import 'app_state.dart';

class EditTaskScreen extends StatefulWidget {
  final TaskItem task;
  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _budgetController;
  late final TextEditingController _locationController;

  late String _selectedCategory;
  late String _selectedSubcategory;
  late String _locationType;
  late String _timeline;
  late String _urgency;
  late String _selectedPaymentMethod;
  String? _selectedDeadline;
  String? _base64Image;
  String? _base64ImageName;

  static const Map<String, List<String>> _subcategoryMap = {
    "Plumbing & Repair": ["Pipe Leakage", "Drain Cleaning", "Water Heater", "Toilet Repair", "Faucet Installation", "Sewage Issues"],
    "Electrical": ["Wiring & Rewiring", "Switchboard Repair", "Fan / AC Installation", "Generator Setup", "Light Fixtures", "Electrical Inspection"],
    "Cleaning": ["Home Deep Clean", "Office Cleaning", "Carpet & Upholstery", "Post-Construction Clean", "Window Cleaning", "Disinfection"],
    "Carpentry": ["Furniture Assembly", "Door & Window Frames", "Custom Shelving", "Cabinet Making", "Wood Repair", "Flooring"],
    "Painting": ["Interior Painting", "Exterior Painting", "Wallpaper", "Surface Prep & Sanding", "Texture Coating", "Graffiti Removal"],
    "Repair": ["Appliance Repair", "Roof Repair", "Wall Crack Repair", "Tile & Grout", "Window Repair", "Gate & Fence Repair"],
  };

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _budgetController = TextEditingController(text: widget.task.budget.toStringAsFixed(2));
    _locationController = TextEditingController(text: widget.task.location);

    // Map database category string back to UI standard
    final dbCat = widget.task.category.toLowerCase();
    if (dbCat.contains('elec')) {
      _selectedCategory = "Electrical";
    } else if (dbCat.contains('clean')) {
      _selectedCategory = "Cleaning";
    } else if (dbCat.contains('carp')) {
      _selectedCategory = "Carpentry";
    } else if (dbCat.contains('paint')) {
      _selectedCategory = "Painting";
    } else if (dbCat.contains('repair') || dbCat.contains('plumb')) {
      _selectedCategory = "Plumbing & Repair";
    } else {
      _selectedCategory = "Repair";
    }

    _selectedSubcategory = "";
    _locationType = widget.task.tags.contains('Remote') ? 'Remote'
        : widget.task.tags.contains('Hybrid') ? 'Hybrid'
        : 'On-site';
    _timeline = widget.task.schedule;
    _selectedDeadline = widget.task.deadline;
    _base64Image = widget.task.imageUrl;
    if (_base64Image != null && _base64Image!.isNotEmpty) {
      _base64ImageName = "Attached Image";
    }
    _urgency = widget.task.urgency;
    _selectedPaymentMethod = widget.task.paymentMethod.isNotEmpty ? widget.task.paymentMethod : "Escrow / Wallet";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _showCategoryPicker() {
    final categories = _subcategoryMap.keys.toList();
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
                          _selectedSubcategory = "";
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

  void _showUrgencyPicker() {
    final urgencies = ["Flexible", "Standard", "Urgent"];
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
              const Text("Select Urgency Level", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
              const SizedBox(height: 8),
              const Divider(),
              Column(
                children: urgencies.map((urg) {
                  return ListTile(
                    title: Text(urg, style: const TextStyle(fontWeight: FontWeight.w500)),
                    trailing: _urgency == urg ? const Icon(Icons.check, color: Color(0xFFFF4500)) : null,
                    onTap: () {
                      setState(() {
                        _urgency = urg;
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
              const Text("Select Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
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

  Future<void> _saveChanges() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final location = _locationController.text.trim();
    final budgetVal = double.tryParse(_budgetController.text.trim()) ?? 0.0;

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task title is required.")));
      return;
    }
    if (description.length < 30) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a longer description (min 30 characters).")));
      return;
    }
    if (location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Location address is required.")));
      return;
    }
    if (budgetVal <= 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please specify a valid budget.")));
      return;
    }

    final draft = TaskDraft(
      title: title,
      description: description,
      category: _selectedCategory,
      location: location,
      city: "",
      locationType: _locationType,
      budgetMin: budgetVal,
      budgetMax: budgetVal,
      budgetMode: "fixed",
      timeline: _timeline,
      urgency: _urgency,
      paymentMethod: _selectedPaymentMethod,
      budget: budgetVal,
      country: "",
      duration: "Flexible",
      isRecurring: false,
      deadline: _selectedDeadline,
      imageUrl: _base64Image,
    );

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF4500)))),
      );

      final appState = AppStateScope.of(context);
      await appState.updateTaskItem(widget.task.id, draft);

      Navigator.pop(context); // Pop loading dialog
      Navigator.pop(context); // Pop edit screen

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Task updated successfully!"), backgroundColor: Color(0xFF1E8E3E)),
      );
    } catch (e) {
      Navigator.pop(context); // Pop loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update task: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
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
                      const SizedBox(height: 24),

                      _buildLabel("Category & Subcategory"),
                      _buildDropdownField(_selectedCategory, Icons.chevron_right, onTap: _showCategoryPicker),
                      const SizedBox(height: 10),
                      _buildDropdownField(
                        _selectedSubcategory.isEmpty ? "Select subcategory" : _selectedSubcategory,
                        Icons.chevron_right,
                        onTap: () {
                          final subs = _subcategoryMap[_selectedCategory] ?? [];
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
                      const SizedBox(height: 24),

                      _buildLabel("Description"),
                      _buildTextArea(_descriptionController, "Provide as much detail as possible..."),
                      const SizedBox(height: 24),

                      _buildLabel("Attachment (Optional)"),
                      const SizedBox(height: 8),
                      _buildUploadZone(),
                      const SizedBox(height: 24),

                      _buildLabel("Location"),
                      _buildLocationTabs(),
                      const SizedBox(height: 12),
                      _buildTextField(_locationController, "Enter address", icon: Icons.map),
                      const SizedBox(height: 24),

                      _buildLabel("Budget (USD)"),
                      _buildTextField(_budgetController, "Enter estimated budget", icon: Icons.attach_money, keyboardType: TextInputType.number),
                      const SizedBox(height: 24),

                      _buildLabel("Schedule Timeline"),
                      _buildDropdownField(_timeline, Icons.calendar_today_outlined, onTap: _showTimelinePicker),
                      const SizedBox(height: 24),

                      _buildLabel("Urgency Level"),
                      _buildDropdownField(_urgency, Icons.speed_outlined, onTap: _showUrgencyPicker),
                      const SizedBox(height: 24),

                      _buildLabel("Payment Method"),
                      _buildDropdownField(_selectedPaymentMethod, Icons.payment_outlined, onTap: _showPaymentMethodPicker),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF4500),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              const Text(
                "Edit Task Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? icon, TextInputType? keyboardType}) {
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
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF64748B), size: 20),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF001F3F)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                border: InputBorder.none,
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
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        maxLines: 5,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF001F3F)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildLocationTabs() {
    final tabs = ["On-site", "Remote", "Hybrid"];
    return Row(
      children: tabs.map((tab) {
        final active = _locationType == tab;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _locationType = tab),
            child: Container(
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF001F3F) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: active ? const Color(0xFF001F3F) : const Color(0xFFE2E8F0)),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: active ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
}
