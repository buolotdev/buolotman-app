import 'package:flutter/material.dart';
import 'app_models.dart';
import 'post_task_step3_screen.dart';

class PostTaskStep2Screen extends StatefulWidget {
  const PostTaskStep2Screen({super.key, required this.draft});

  final TaskDraft draft;

  @override
  State<PostTaskStep2Screen> createState() => _PostTaskStep2ScreenState();
}

class _PostTaskStep2ScreenState extends State<PostTaskStep2Screen> {
  String _urgency = "Flexible";
  String _duration = "1 - 3 hrs";
  bool _isRecurring = false;
  
  final String _location = "124 Main Street, Downtown";
  final String _preferredDate = "Oct 24, 2023";
  final String _preferredTime = "10:00 AM";

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
                      _buildLabel("Task Location"),
                      _buildLocationInput(),
                      const SizedBox(height: 12),
                      _buildMapPreview(),
                      const SizedBox(height: 28),
                      
                      _buildLabel("How soon do you need this done?"),
                      _buildUrgencyOptions(),
                      const SizedBox(height: 28),
                      
                      _buildDateTimeSection(),
                      const SizedBox(height: 28),
                      
                      _buildLabel("Estimated Duration"),
                      _buildDurationChips(),
                      const SizedBox(height: 28),
                      
                      _buildRecurringToggle(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
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
                "Step 2 of 3",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFF4500)),
              ),
              Text(
                "Location & Schedule",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.66,
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFFF4500), borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
    );
  }

  Widget _buildLocationInput() {
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
          const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _location,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF001F3F)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.my_location, color: Color(0xFFFF4500), size: 20),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              "https://images.unsplash.com/photo-1524661135-423995f22d0b?ixlib=rb-4.0.3&auto=format&fit=crop&w=900&q=80",
              width: double.infinity,
              height: 140,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
              ),
              child: Row(
                children: const [
                  Icon(Icons.map_outlined, size: 16, color: Color(0xFFFF4500)),
                  SizedBox(width: 6),
                  Text("Edit Map", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyOptions() {
    return Column(
      children: [
        _buildChoiceItem("Urgent", "As soon as possible"),
        const SizedBox(height: 12),
        _buildChoiceItem("Flexible", "Timing is flexible (within a few days)"),
        const SizedBox(height: 12),
        _buildChoiceItem("Scheduled", "Pick a specific date"),
      ],
    );
  }

  Widget _buildChoiceItem(String title, String desc) {
    final bool isActive = _urgency == title;
    return GestureDetector(
      onTap: () => setState(() => _urgency = title),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white,
          border: Border.all(color: isActive ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isActive ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0), width: 2),
              ),
              alignment: Alignment.center,
              child: isActive ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFFF4500), shape: BoxShape.circle)) : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Preferred Date"),
              _buildSmallDropdown(_preferredDate, Icons.calendar_today_outlined),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Preferred Time"),
              _buildSmallDropdown(_preferredTime, Icons.access_time),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallDropdown(String value, IconData icon) {
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
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF001F3F)),
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 18, color: Color(0xFF64748B)),
        ],
      ),
    );
  }

  Widget _buildDurationChips() {
    final List<String> durations = ["< 1 hr", "1 - 3 hrs", "Half day", "Full day"];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: durations.map((d) => _buildChip(d)).toList(),
    );
  }

  Widget _buildChip(String text) {
    final bool isActive = _duration == text;
    return GestureDetector(
      onTap: () => setState(() => _duration = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF001F3F) : Colors.white,
          border: Border.all(color: isActive ? const Color(0xFF001F3F) : const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isActive ? Colors.white : const Color(0xFF001F3F)),
        ),
      ),
    );
  }

  Widget _buildRecurringToggle() {
    return GestureDetector(
      onTap: () => setState(() => _isRecurring = !_isRecurring),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text("Recurring Task?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                  SizedBox(height: 4),
                  Text("Do you need this done regularly?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Container(
              width: 44,
              height: 28,
              decoration: BoxDecoration(
                color: _isRecurring ? const Color(0xFFFF4500) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn,
                    left: _isRecurring ? 18 : 2,
                    top: 2,
                    child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PostTaskStep3Screen(
                draft: widget.draft.copyWith(
                  location: _location,
                  timeline: '$_preferredDate · $_preferredTime',
                  urgency: _urgency,
                  duration: _duration,
                  isRecurring: _isRecurring,
                ),
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4500),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text("Next", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
