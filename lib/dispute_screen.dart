import 'package:flutter/material.dart';

import 'app_state.dart';

class DisputeScreen extends StatefulWidget {
  final String? taskId;
  final String? taskTitle;
  const DisputeScreen({super.key, this.taskId, this.taskTitle});

  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  String _selectedReason = 'Poor Work Quality';
  final TextEditingController _explanationController = TextEditingController();

  @override
  void dispose() {
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final String selectedTaskTitle = widget.taskTitle ?? (appState.clientTasks.isNotEmpty ? appState.clientTasks.first.title : 'Recent Task');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF001F3F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Open a Dispute", style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What went wrong?", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 12),
            Text("We're sorry to hear there's an issue with '$selectedTaskTitle'. Please tell us more so we can help.", style: const TextStyle(color: Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 32),
            _buildLabel("Select Reason"),
            _buildDropdown(['Poor Work Quality', 'Unfinished Task', 'Pricing Discrepancy', 'Communication Issues', 'Other']),
            const SizedBox(height: 24),
            _buildLabel("Explain the Situation"),
            _buildTextField("Provide details about the issue...", maxLines: 5),
            const SizedBox(height: 24),
            _buildLabel("Evidence (Photos/Documents)"),
            _buildUploadBox("Upload Evidence", Icons.add_photo_alternate_outlined),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
    );
  }

  Widget _buildDropdown(List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedReason,
          isExpanded: true,
          onChanged: (val) => setState(() => _selectedReason = val!),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, {int maxLines = 1}) {
    return TextField(
      controller: _explanationController,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final appState = AppStateScope.of(context);
    final String selectedTaskId = widget.taskId ?? (appState.clientTasks.isNotEmpty ? appState.clientTasks.first.id : '');
    final String selectedTaskTitle = widget.taskTitle ?? (appState.clientTasks.isNotEmpty ? appState.clientTasks.first.title : 'Recent Task');

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          if (_explanationController.text.trim().isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Add a short explanation before submitting.')),
            );
            return;
          }
          if (selectedTaskId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('You must have an active task to open a dispute.')),
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
            await appState.createDispute(
              taskId: selectedTaskId,
              reason: _selectedReason,
              title: 'Dispute: $selectedTaskTitle',
              description: _explanationController.text.trim(),
            );
            if (mounted) {
              Navigator.pop(context); // Dismiss loading
              // Also open support thread as a communication channel
              await appState.createOrOpenThread(
                otherPartyName: 'Dispute Mediation',
                otherPartyImage: 'assets/images/onboard1.jpg',
                initialMessage:
                    'Dispute opened for "$selectedTaskTitle". Reason: $_selectedReason. Details: ${_explanationController.text.trim()}',
              );
              _showSuccessDialog();
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context); // Dismiss loading
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to submit dispute: $e')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4500),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: const Text("Submit Dispute", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              decoration: const BoxDecoration(color: Color(0xFFFEF3C7), shape: BoxShape.circle),
              child: const Icon(Icons.gavel_outlined, color: Color(0xFFB45309), size: 32),
            ),
            const SizedBox(height: 24),
            const Text("Dispute Opened", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 12),
            const Text(
              "Our mediation team has been notified. We will review your evidence and contact both parties shortly.",
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
                child: const Text("Understood"),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
