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
  bool _submitted = false;
  String _referenceId = '';

  @override
  void dispose() {
    _explanationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _buildStatusScreen();

    final appState = AppStateScope.of(context);
    final String selectedTaskTitle = widget.taskTitle ??
        (appState.clientTasks.isNotEmpty
            ? appState.clientTasks.first.title
            : 'Recent Task');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF001F3F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Open a Dispute',
            style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What went wrong?',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 12),
            Text(
              "We're sorry to hear there's an issue with '$selectedTaskTitle'. Please tell us more so we can help.",
              style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildLabel('Select Reason'),
            _buildDropdown([
              'Poor Work Quality',
              'Unfinished Task',
              'Pricing Discrepancy',
              'Communication Issues',
              'No Show / Abandonment',
              'Fraudulent Activity',
              'Other'
            ]),
            const SizedBox(height: 24),
            _buildLabel('Explain the Situation'),
            _buildTextField('Provide details about the issue...', maxLines: 5),
            const SizedBox(height: 24),
            _buildLabel('Evidence (Photos/Documents)'),
            _buildUploadBox('Upload Evidence', Icons.add_photo_alternate_outlined),
            const SizedBox(height: 40),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  // ── Post-submission status screen ─────────────────────────────────────────

  Widget _buildStatusScreen() {
    final statusSteps = [
      {'label': 'Dispute Submitted', 'desc': 'Your dispute has been received.', 'done': true, 'active': false},
      {'label': 'Under Review', 'desc': 'Our team is reviewing the case.', 'done': false, 'active': true},
      {'label': 'In Mediation', 'desc': 'Both parties will be contacted.', 'done': false, 'active': false},
      {'label': 'Final Resolution', 'desc': 'A decision will be made and communicated.', 'done': false, 'active': false},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Dispute Status',
            style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                        color: Color(0xFFFEF3C7), shape: BoxShape.circle),
                    child: const Icon(Icons.gavel_outlined, color: Color(0xFFB45309), size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Dispute Opened',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                  const SizedBox(height: 8),
                  const Text(
                    'Our mediation team has been notified and will review your case within 24-48 hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reference number
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Reference Number',
                            style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                        const SizedBox(height: 2),
                        Text(_referenceId,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF001F3F),
                                letterSpacing: 1)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8)),
                    child: const Text('Under Review',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Status timeline
            const Text('Dispute Timeline',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 16),

            ...statusSteps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              final isDone = step['done'] as bool;
              final isActive = step['active'] as bool;
              final isLast = i == statusSteps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF16A34A)
                              : isActive
                                  ? const Color(0xFFFF4500)
                                  : const Color(0xFFE2E8F0),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isDone ? Icons.check : Icons.circle,
                          color: isDone || isActive ? Colors.white : const Color(0xFF94A3B8),
                          size: isDone ? 16 : 8,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: isDone ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 28, top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(step['label'] as String,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDone || isActive
                                      ? const Color(0xFF001F3F)
                                      : const Color(0xFF94A3B8))),
                          const SizedBox(height: 2),
                          Text(step['desc'] as String,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: isDone || isActive
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFFCBD5E1))),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 32),

            // What to expect
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What to Expect',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0284C7))),
                  SizedBox(height: 10),
                  Text(
                    '• Our team will contact both parties within 24-48 hours.\n'
                    '• Keep checking your inbox for updates.\n'
                    '• Any escrow funds remain on hold until resolved.\n'
                    '• Save your reference number for future communication.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF0369A1), height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back to App',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Form helpers ───────────────────────────────────────────────────────────

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
    );
  }

  Widget _buildDropdown(List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
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
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF64748B)),
          const SizedBox(height: 12),
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          const SizedBox(height: 4),
          const Text('Tap to attach files (PNG, JPG, PDF)',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final appState = AppStateScope.of(context);
    final String selectedTaskId = widget.taskId ??
        (appState.clientTasks.isNotEmpty ? appState.clientTasks.first.id : '');
    final String selectedTaskTitle = widget.taskTitle ??
        (appState.clientTasks.isNotEmpty ? appState.clientTasks.first.title : 'Recent Task');

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
              const SnackBar(
                  content: Text('You must have an active task to open a dispute.')),
            );
            return;
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500))),
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
              Navigator.pop(context); // dismiss loading
              final refId =
                  'BM-DSP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
              setState(() {
                _submitted = true;
                _referenceId = refId;
              });
            }
          } catch (e) {
            if (mounted) {
              Navigator.pop(context);
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
        child: const Text('Submit Dispute',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
