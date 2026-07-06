import 'package:flutter/material.dart';
import 'app_state.dart';
import 'post_task_success_screen.dart';

class PostTaskStep3Screen extends StatelessWidget {
  const PostTaskStep3Screen({super.key, required this.draft});

  final TaskDraft draft;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEFEFF),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildIntro(),
                      const SizedBox(height: 20),
                      _buildStatusCard(),
                      const SizedBox(height: 20),
                      _buildTaskOverviewCard(),
                      const SizedBox(height: 20),
                      _buildChecklistCard(),
                      const SizedBox(height: 20),
                      _buildSafetyNote(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
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
                "Step 2 of 2",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFF4500)),
              ),
              Text(
                "Preview & Publish",
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
              widthFactor: 1.0,
              child: Container(
                decoration: BoxDecoration(color: const Color(0xFFFF4500), borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          "Review your task before publishing",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF001F3F), height: 1.2),
        ),
        SizedBox(height: 8),
        Text(
          "Make sure the details below are accurate so trusted professionals can send the right offers quickly.",
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.5),
        ),
      ],
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFFFF4500), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4500),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Ready to publish",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Your task includes location, schedule, budget, and supporting photos. Publishing will make it visible to verified technicians and companies.",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Task overview", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 10),
          Text(
            draft.title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF001F3F), height: 1.3),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildMetaPill(draft.category, isAccent: true),
              _buildMetaPill(draft.locationType),
              _buildMetaPill(draft.paymentMethod),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 16),
          const Text("Description", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 8),
          Text(
            draft.description,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF001F3F), height: 1.5),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.2,
            children: [
              _buildInfoCard(
                "Budget",
                draft.budgetMode == "fixed"
                    ? '\$${draft.budgetMin.toStringAsFixed(0)}'
                    : '\$${draft.budgetMin.toStringAsFixed(0)} - \$${draft.budgetMax.toStringAsFixed(0)}',
              ),
              _buildInfoCard("Schedule", draft.timeline),
              _buildInfoCard("Location", '${draft.location}\n(${draft.city}, ${draft.country})'),
              _buildInfoCard("Type & Urgency", '${draft.locationType} (${draft.urgency})'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetaPill(String text, {bool isAccent = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: isAccent ? const Color(0xFFFF4500).withOpacity(0.12) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isAccent ? const Color(0xFFFF4500) : const Color(0xFF001F3F),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFF),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF001F3F), height: 1.2),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Reference photos", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPhotoItem("https://storage.googleapis.com/banani-generated-images/generated-images/e7bcd2fb-cd81-46b2-84d7-7145885d2e66.jpg"),
              const SizedBox(width: 12),
              _buildPhotoItem("https://storage.googleapis.com/banani-generated-images/generated-images/c1331a10-1c33-4849-a713-151cb9b1f5a6.jpg"),
              const SizedBox(width: 12),
              _buildPhotoItem("https://storage.googleapis.com/banani-generated-images/generated-images/3948d46f-cc6c-4419-a395-442518fe4307.jpg"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(String url) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.cover),
        ),
      ),
    );
  }

  Widget _buildRequirementsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Requirements", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          _buildRowItem(Icons.check, "Bring installation tools and safety gear"),
          const SizedBox(height: 10),
          _buildRowItem(Icons.check, "Cleanup after the task is completed"),
          const SizedBox(height: 10),
          _buildRowItem(Icons.check, "Apartment access is available from 9:00 AM to 5:00 PM"),
        ],
      ),
    );
  }

  Widget _buildChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("What professionals will see", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          _buildRowItem(Icons.map_outlined, "Job location and preferred appointment time"),
          const SizedBox(height: 10),
          _buildRowItem(Icons.account_balance_wallet_outlined, "Budget range and hiring preference"),
          const SizedBox(height: 10),
          _buildRowItem(Icons.image_outlined, "Reference photos and notes to clarify scope"),
        ],
      ),
    );
  }

  Widget _buildRowItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFF),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: Icon(icon, size: 12, color: const Color(0xFFFF4500)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF001F3F), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("Secure hiring note", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          SizedBox(height: 8),
          Text(
            "Boulot Man recommends communicating through in-app messages and using platform payments for escrow protection and payout tracking.",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF64748B), height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 56),
                backgroundColor: const Color(0xFFF1F5F9),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.edit_outlined, size: 18, color: Color(0xFF001F3F)),
                  SizedBox(width: 8),
                  Text("Edit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () async {
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
                  final task = await AppStateScope.of(context).publishTask(draft);
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Dismiss loading
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => PostTaskSuccessScreen(taskId: task.id)),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop(); // Dismiss loading
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                minimumSize: const Size(0, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text("Publish Task", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
