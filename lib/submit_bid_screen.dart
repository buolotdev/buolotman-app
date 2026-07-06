import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';

class SubmitBidScreen extends StatefulWidget {
  const SubmitBidScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<SubmitBidScreen> createState() => _SubmitBidScreenState();
}

class _SubmitBidScreenState extends State<SubmitBidScreen> {
  String _completionTime = '1 day';
  final TextEditingController _amountController = TextEditingController(text: '420');
  final TextEditingController _messageController = TextEditingController(
    text: 'I can complete this safely with a clear checklist, material coordination, and daily progress updates.',
  );

  @override
  void initState() {
    super.initState();
    final appState = Get.find<AppState>();
    final existingBid = appState.bids.firstWhere(
      (b) => b.taskId == widget.taskId,
      orElse: () => const BidItem(
        id: '',
        taskId: '',
        bidderName: '',
        skill: '',
        rating: 0,
        reviews: 0,
        price: 0,
        timeline: '1 day',
        message: 'I can complete this safely with a clear checklist, material coordination, and daily progress updates.',
        avatar: '',
        role: '',
      ),
    );
    if (existingBid.id.isNotEmpty) {
      _amountController.text = existingBid.price.toStringAsFixed(0);
      _completionTime = existingBid.timeline;
      _messageController.text = existingBid.message;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final task = appState.findTask(widget.taskId)!;
        final hasBid = appState.bids.any((b) => b.taskId == widget.taskId);
        return Scaffold(
          backgroundColor: const Color(0xFFF1F5F9),
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(hasBid ? 'Update Bid' : 'Submit a Bid', style: const TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTaskCard(task),
                const SizedBox(height: 16),
                _buildFieldLabel('Your bid amount'),
                _buildTextField(_amountController, prefix: '\$'),
                const SizedBox(height: 8),
                Text(
                  'Task budget: up to \$${task.budget.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Estimated completion'),
                Wrap(
                  spacing: 8,
                  children: ['1 day', '2 days', '3+ days'].map(_buildChoicePill).toList(),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Cover message'),
                _buildTextField(_messageController, maxLines: 6),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _submitBid(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4500),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(hasBid ? 'Update Bid' : 'Send Bid'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(dynamic task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          const SizedBox(height: 8),
          Text(task.description, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
    );
  }

  Widget _buildTextField(TextEditingController controller, {String? prefix, int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: prefix == null ? TextInputType.multiline : TextInputType.number,
      decoration: InputDecoration(
        prefixText: prefix,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildChoicePill(String text) {
    final isActive = _completionTime == text;
    return GestureDetector(
      onTap: () => setState(() => _completionTime = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFF4500).withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? const Color(0xFFFF4500) : const Color(0xFF001F3F),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _submitBid(BuildContext context) async {
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid bid amount.')),
      );
      return;
    }
    
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write a pitch or message.')),
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
      final appState = AppStateScope.of(context);
      await appState.submitBid(
        taskId: widget.taskId,
        price: amount,
        timeline: _completionTime,
        message: message,
      );
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bid submitted successfully.')),
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
}
