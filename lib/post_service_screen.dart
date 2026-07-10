import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';

class PostServiceScreen extends StatefulWidget {
  const PostServiceScreen({super.key});

  @override
  State<PostServiceScreen> createState() => _PostServiceScreenState();
}

class _PostServiceScreenState extends State<PostServiceScreen> {
  int _currentStep = 1;
  final int _totalSteps = 3;

  // Step 1 – Service Catalog
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _selectedCategory = 'General';

  // Step 2 – Pricing Model
  String _pricingModel = 'Fixed';          // Fixed | Hourly | Project
  final TextEditingController _priceMinController = TextEditingController();
  final TextEditingController _priceMaxController = TextEditingController();
  final TextEditingController _priceLabelController = TextEditingController();

  // Step 3 – Availability & Coverage
  String _serviceType = 'onsite';          // onsite | remote | both
  final TextEditingController _coverageController = TextEditingController();
  final List<String> _workDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  String _timeFrom = '9:00 AM';
  String _timeTo = '6:00 PM';
  final List<String> _allDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _timeSlots = [
    '6:00 AM', '7:00 AM', '8:00 AM', '9:00 AM', '10:00 AM', '11:00 AM',
    '12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM', '4:00 PM', '5:00 PM',
    '6:00 PM', '7:00 PM', '8:00 PM', '9:00 PM', '10:00 PM',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _priceLabelController.dispose();
    _coverageController.dispose();
    super.dispose();
  }

  String _buildAvailabilityString() {
    final days = _workDays.join(', ');
    return '$days · $_timeFrom – $_timeTo';
  }

  String _buildPriceLabel() {
    final min = _priceMinController.text.trim();
    final max = _priceMaxController.text.trim();
    if (_priceLabelController.text.trim().isNotEmpty) {
      return _priceLabelController.text.trim();
    }
    switch (_pricingModel) {
      case 'Hourly':
        return min.isNotEmpty ? '\$$min/hr' : 'Contact for rate';
      case 'Project':
        if (min.isNotEmpty && max.isNotEmpty) return '\$$min – \$$max / project';
        if (min.isNotEmpty) return 'From \$$min / project';
        return 'Contact for quote';
      default: // Fixed
        return min.isNotEmpty ? '\$$min' : 'Contact for pricing';
    }
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
        title: const Text(
          'Post a Service',
          style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildStepIndicator(),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: _buildStepContent(),
            ),
          ),
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Step indicator ─────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    const labels = ['Service Catalog', 'Pricing', 'Availability'];
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: List.generate(_totalSteps * 2 - 1, (i) {
          if (i.isOdd) {
            return Expanded(
              child: Container(
                height: 2,
                color: _currentStep > i ~/ 2 + 1
                    ? const Color(0xFFFF4500)
                    : const Color(0xFFE2E8F0),
              ),
            );
          }
          final step = i ~/ 2 + 1;
          final isActive = _currentStep >= step;
          final isDone = _currentStep > step;
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFF4500) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: isActive ? null : Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Center(
                  child: isDone
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          step.toString(),
                          style: TextStyle(
                            color: isActive ? Colors.white : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels[step - 1],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
                  color: isActive ? const Color(0xFF001F3F) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ── Step content ───────────────────────────────────────────────────────────

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildCatalogStep();
      case 2:
        return _buildPricingStep();
      default:
        return _buildAvailabilityStep();
    }
  }

  // Step 1 ─ Service Catalog
  Widget _buildCatalogStep() {
    final appState = AppStateScope.of(context);
    final categories = appState.apiCategories;
    final categoryNames = categories.isNotEmpty
        ? categories.map((c) => c['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList()
        : ['General', 'Electrical', 'Plumbing', 'HVAC', 'Carpentry', 'Painting', 'Cleaning', 'Security', 'IT & Tech', 'Landscaping'];

    if (!categoryNames.contains(_selectedCategory)) {
      _selectedCategory = categoryNames.first;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Service Catalog', 'Define your service offering'),
        const SizedBox(height: 24),
        _label('Service Title *'),
        _textField('e.g. Professional Office Deep Cleaning', _titleController),
        const SizedBox(height: 20),
        _label('Category *'),
        _buildCategoryDropdown(categoryNames),
        const SizedBox(height: 20),
        _label('Service Description *'),
        _textField(
          'Describe what you offer, your process, and what clients can expect...',
          _descController,
          maxLines: 5,
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(List<String> names) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: names.contains(_selectedCategory) ? _selectedCategory : names.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
          onChanged: (v) => setState(() => _selectedCategory = v!),
          items: names
              .map((n) => DropdownMenuItem(
                    value: n,
                    child: Text(n, style: const TextStyle(fontSize: 14, color: Color(0xFF001F3F))),
                  ))
              .toList(),
        ),
      ),
    );
  }

  // Step 2 ─ Pricing Model
  Widget _buildPricingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Pricing Model', 'How do you charge for this service?'),
        const SizedBox(height: 24),
        _label('Pricing Model *'),
        const SizedBox(height: 8),
        _buildPricingModelSelector(),
        const SizedBox(height: 24),
        _buildPricingFields(),
        const SizedBox(height: 20),
        _label('Custom Price Label (optional)'),
        _textField(
          'e.g. "From \$500" or "Call for Quote"',
          _priceLabelController,
        ),
        const SizedBox(height: 8),
        const Text(
          'Leave empty to auto-generate from the amounts above.',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 24),
        _buildPricePreviewCard(),
      ],
    );
  }

  Widget _buildPricingModelSelector() {
    final models = [
      {'key': 'Fixed', 'label': 'Fixed Price', 'icon': Icons.price_check, 'desc': 'One set price for the whole service'},
      {'key': 'Hourly', 'label': 'Hourly Rate', 'icon': Icons.timer_outlined, 'desc': 'Charge per hour of work'},
      {'key': 'Project', 'label': 'Project-Based', 'icon': Icons.assignment_outlined, 'desc': 'Quote per project scope'},
    ];
    return Column(
      children: models.map((m) {
        final isSelected = _pricingModel == m['key'];
        return GestureDetector(
          onTap: () => setState(() => _pricingModel = m['key'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF001F3F) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF001F3F) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Icon(m['icon'] as IconData,
                    color: isSelected ? const Color(0xFFFF4500) : const Color(0xFF94A3B8),
                    size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m['label'] as String,
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : const Color(0xFF001F3F),
                              fontSize: 14)),
                      Text(m['desc'] as String,
                          style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white54 : const Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(Icons.check_circle, color: Color(0xFFFF4500), size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPricingFields() {
    if (_pricingModel == 'Project') {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Min Price (\$)'),
                _textField('0', _priceMinController, keyboardType: TextInputType.number),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Max Price (\$)'),
                _textField('0', _priceMaxController, keyboardType: TextInputType.number),
              ],
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(_pricingModel == 'Hourly' ? 'Hourly Rate (\$)' : 'Price (\$)'),
        _textField(
          _pricingModel == 'Hourly' ? 'e.g. 75' : 'e.g. 500',
          _priceMinController,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildPricePreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBAE6FD)),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: Color(0xFF0284C7), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Price Preview',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0284C7),
                        fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  _buildPriceLabel(),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001F3F),
                      fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Step 3 ─ Availability & Coverage
  Widget _buildAvailabilityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Availability', 'When and where is your service available?'),
        const SizedBox(height: 24),
        _label('Service Delivery Type *'),
        const SizedBox(height: 8),
        _buildServiceTypeSelector(),
        if (_serviceType != 'remote') ...[
          const SizedBox(height: 20),
          _label('Coverage Area'),
          _textField(
            'e.g. Lagos Island, Victoria Island, Lekki',
            _coverageController,
          ),
        ],
        const SizedBox(height: 20),
        _label('Working Days'),
        const SizedBox(height: 8),
        _buildDayPicker(),
        const SizedBox(height: 20),
        _label('Working Hours'),
        const SizedBox(height: 8),
        _buildHoursPicker(),
        const SizedBox(height: 24),
        _buildServicePreviewCard(),
      ],
    );
  }

  Widget _buildServiceTypeSelector() {
    final types = [
      {'key': 'onsite', 'label': 'On-Site', 'icon': Icons.location_on_outlined, 'desc': 'You visit the client'},
      {'key': 'remote', 'label': 'Remote', 'icon': Icons.wifi_outlined, 'desc': 'Service provided remotely'},
      {'key': 'both', 'label': 'Both', 'icon': Icons.swap_horiz, 'desc': 'On-site and remote available'},
    ];
    return Row(
      children: types.map((t) {
        final isSelected = _serviceType == t['key'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _serviceType = t['key'] as String),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF001F3F) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? const Color(0xFF001F3F) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Column(
                children: [
                  Icon(t['icon'] as IconData,
                      color: isSelected ? const Color(0xFFFF4500) : const Color(0xFF94A3B8),
                      size: 20),
                  const SizedBox(height: 4),
                  Text(t['label'] as String,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : const Color(0xFF001F3F))),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDayPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _allDays.map((day) {
        final isSelected = _workDays.contains(day);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              _workDays.remove(day);
            } else {
              _workDays.add(day);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFF4500) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              day,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHoursPicker() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('From', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              _timeDropdown(_timeFrom, (v) => setState(() => _timeFrom = v!)),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 22, left: 12, right: 12),
          child: Text('–', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('To', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 6),
              _timeDropdown(_timeTo, (v) => setState(() => _timeTo = v!)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
          onChanged: onChanged,
          items: _timeSlots
              .map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: const TextStyle(fontSize: 13, color: Color(0xFF001F3F))),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildServicePreviewCard() {
    final priceLabel = _buildPriceLabel();
    final availability = _buildAvailabilityString();
    final deliveryLabel = _serviceType == 'onsite'
        ? 'On-Site'
        : _serviceType == 'remote'
            ? 'Remote'
            : 'On-Site & Remote';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: const Color(0xFF001F3F).withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  _titleController.text.isNotEmpty ? _titleController.text : 'Service Title',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(priceLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF4500), fontSize: 15)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_selectedCategory,
                style: const TextStyle(fontSize: 12, color: Colors.white70, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          _previewRow(Icons.local_shipping_outlined, deliveryLabel),
          const SizedBox(height: 6),
          if (_serviceType != 'remote' && _coverageController.text.isNotEmpty)
            _previewRow(Icons.location_on_outlined, _coverageController.text),
          if (_serviceType != 'remote' && _coverageController.text.isNotEmpty)
            const SizedBox(height: 6),
          _previewRow(Icons.schedule_outlined, availability),
        ],
      ),
    );
  }

  Widget _previewRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 14),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
    );
  }

  Widget _textField(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF001F3F), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(14),
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          if (_currentStep > 1) ...[
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                _currentStep == _totalSteps ? 'Publish Service' : 'Next',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    // Validate current step
    if (_currentStep == 1) {
      if (_titleController.text.trim().isEmpty) {
        _showError('Please enter a service title.');
        return;
      }
      if (_descController.text.trim().isEmpty) {
        _showError('Please add a description for your service.');
        return;
      }
      setState(() => _currentStep++);
      return;
    }

    if (_currentStep == 2) {
      if (_priceMinController.text.trim().isEmpty && _priceLabelController.text.trim().isEmpty) {
        _showError('Please enter a price or a custom price label.');
        return;
      }
      setState(() => _currentStep++);
      return;
    }

    // Step 3 – Publish
    if (_workDays.isEmpty) {
      _showError('Please select at least one working day.');
      return;
    }

    final appState = AppStateScope.of(context);
    final priceLabel = _buildPriceLabel();
    final availability = _buildAvailabilityString();
    final coverageArea = _coverageController.text.trim().isEmpty
        ? 'Nationwide'
        : _coverageController.text.trim();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
        ),
      ),
    );

    try {
      await appState.publishService(
        title: _titleController.text.trim(),
        category: _selectedCategory,
        description: _descController.text.trim(),
        priceLabel: priceLabel,
        providerName: appState.currentUser.name,
        providerAvatar: appState.currentUser.avatar,
        providerRole: appState.currentUser.role,
        serviceType: _serviceType,
        coverageArea: coverageArea,
        availability: availability,
        pricingModel: _pricingModel,
      );
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        Get.snackbar(
          'Service Published',
          '"${_titleController.text.trim()}" is now live.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF001F3F),
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 12,
          duration: const Duration(seconds: 3),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // dismiss loading
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
