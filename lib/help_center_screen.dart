import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';
import 'chat_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, String>> _faqs = [
    {
      "question": "How do I post a task?",
      "answer": "Go to the Home screen and tap the 'Post a Task' banner. Follow the steps to provide details, location, and budget."
    },
    {
      "question": "How does escrow work?",
      "answer": "When you accept a bid, your funds are held securely by Boulot Man. Once the task is completed and you confirm it, the funds are released to the professional."
    },
    {
      "question": "What if I'm not happy with the work?",
      "answer": "You can initiate a dispute through the task management screen. Our support team will mediate and help reach a resolution."
    },
    {
      "question": "How do I withdraw my earnings?",
      "answer": "Go to your Wallet in the Profile section and tap 'Withdraw Funds'. You can choose between Mobile Money, Bank Transfer, or Card."
    }
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text("Help Center", style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildSearchHeader(),
                _buildCategories(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 32, 20, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Frequently Asked Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                  ),
                ),
                _buildFaqList(),
                const SizedBox(height: 32),
                _buildContactSupport(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: const Color(0xFF001F3F),
      child: Column(
        children: [
          const Text("How can we help you?", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "Search for articles, guides...",
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final List<Map<String, dynamic>> categories = [
      {"icon": Icons.assignment_outlined, "label": "Getting Started"},
      {"icon": Icons.account_balance_wallet_outlined, "label": "Payments"},
      {"icon": Icons.verified_user_outlined, "label": "Trust & Safety"},
      {"icon": Icons.work_outline, "label": "Pro Center"},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(categories[index]['icon'], color: const Color(0xFFFF4500), size: 28),
                const SizedBox(height: 12),
                Text(categories[index]['label'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFaqList() {
    final appState = AppStateScope.of(context);
    final query = _searchController.text.trim().toLowerCase();
    final List<Map<String, String>> faqs = appState.faqPages.isNotEmpty
        ? appState.faqPages.map((page) {
            return {
              "question": page['title']?.toString() ?? '',
              "answer": page['content']?.toString() ?? page['excerpt']?.toString() ?? '',
            };
          }).toList()
        : _faqs;

    final filteredFaqs = faqs.where((faq) {
      return query.isEmpty ||
          faq['question']!.toLowerCase().contains(query) ||
          faq['answer']!.toLowerCase().contains(query);
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredFaqs.length,
      itemBuilder: (context, index) {
        return ExpansionTile(
          title: Text(filteredFaqs[index]['question']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(filteredFaqs[index]['answer']!, style: const TextStyle(color: Color(0xFF64748B), height: 1.5)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactSupport() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFF4500).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF4500).withValues(alpha: 0.1)),
          ),
        child: Column(
          children: [
            const Text("Still need help?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
            const SizedBox(height: 8),
            const Text("Our support team is available 24/7 to assist you.", textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                AppStateScope.of(context).createOrOpenThread(
                  otherPartyName: 'Boulot Support',
                  otherPartyImage: 'assets/images/boulotman-logo.png',
                  initialMessage: 'Hi, I need help with my account.',
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(name: 'Boulot Support', image: 'assets/images/boulotman-logo.png'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Chat with Support"),
            ),
          ],
        ),
      ),
    );
  }
}
