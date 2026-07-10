import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';
import 'chat_screen.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Default FAQs (used if no backend data)
  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I post a task?',
      'answer':
          'Go to the Home screen and tap the + button at the bottom. Follow the steps to provide task details, location, and budget.'
    },
    {
      'question': 'How does escrow work?',
      'answer':
          'When you accept a bid, your funds are held securely by Boulot Man. Once the task is completed and you confirm it, the funds are released to the professional.'
    },
    {
      'question': 'What if I\'m not happy with the work?',
      'answer':
          'You can initiate a dispute through the task management screen. Our support team will mediate and help reach a resolution within 24-48 hours.'
    },
    {
      'question': 'How do I withdraw my earnings?',
      'answer':
          'Go to your Wallet tab and tap "Withdraw Funds". Choose your preferred method. Funds are processed within 1-3 business days.'
    },
    {
      'question': 'How do I get verified as a technician?',
      'answer':
          'Go to your Profile screen and tap "Get Verified". Submit your ID, skills, and certifications for our team to review.'
    },
    {
      'question': 'Can I cancel a task after posting?',
      'answer':
          'Yes, you can cancel a task before a bid is accepted. Once a bid is accepted and escrow is funded, cancellation may incur a fee.'
    },
  ];

  final List<Map<String, dynamic>> _guides = [
    {
      'title': 'Getting Started as a Client',
      'desc': 'Learn how to post tasks, receive bids, and hire professionals.',
      'icon': Icons.person_outline,
      'color': const Color(0xFF2563EB),
      'steps': [
        'Create your account and complete your profile.',
        'Tap the + button on the home screen to post a task.',
        'Describe the task, set a budget and location.',
        'Review bids from verified professionals.',
        'Accept the best offer and fund escrow.',
        'Track progress and confirm completion to release payment.',
      ],
    },
    {
      'title': 'Getting Started as a Technician',
      'desc': 'Set up your profile, get verified, and start winning bids.',
      'icon': Icons.engineering_outlined,
      'color': const Color(0xFFFF4500),
      'steps': [
        'Sign up as a Technician and complete your profile.',
        'Upload your skills, portfolio, and certifications.',
        'Get verified to unlock more visibility.',
        'Browse tasks in the Task Feed matching your skills.',
        'Submit competitive bids with clear proposals.',
        'Complete work and get paid through secure escrow.',
      ],
    },
    {
      'title': 'Company Onboarding Guide',
      'desc': 'Register your company, build a team, and manage contracts.',
      'icon': Icons.business_outlined,
      'color': const Color(0xFF7C3AED),
      'steps': [
        'Register your company with legal details.',
        'Upload business registration and trade license for verification.',
        'Set up your company profile with services and team members.',
        'Post service offerings in your service catalog.',
        'Create long-term contracts and track milestones.',
        'Manage project progress and escrow payments.',
      ],
    },
    {
      'title': 'Understanding Escrow & Payments',
      'desc': 'How Boulot Man keeps your money safe.',
      'icon': Icons.account_balance_wallet_outlined,
      'color': const Color(0xFF16A34A),
      'steps': [
        'Client posts a task and a budget.',
        'Client accepts a bid and funds are deposited into escrow.',
        'Funds are locked and held by Boulot Man.',
        'Technician completes the work.',
        'Client reviews and confirms completion.',
        'Escrow is released to the technician\'s wallet.',
      ],
    },
  ];

  final List<Map<String, dynamic>> _policies = [
    {
      'title': 'Terms of Service',
      'icon': Icons.description_outlined,
      'content':
          'By using Boulot Man, you agree to our Terms of Service. You must be at least 18 years old to use this platform. You agree to provide accurate information and to use the platform only for lawful purposes.\n\nBoulot Man reserves the right to suspend or terminate accounts that violate these terms. All transactions are subject to our payment policies and escrow conditions.',
    },
    {
      'title': 'Privacy Policy',
      'icon': Icons.privacy_tip_outlined,
      'content':
          'We collect personal information necessary to provide our services, including name, email, phone number, location, and payment details. This information is used solely to facilitate transactions and improve the platform.\n\nWe do not sell your personal data to third parties. Your data is encrypted and stored securely. You may request deletion of your account and data at any time.',
    },
    {
      'title': 'Payment & Escrow Policy',
      'icon': Icons.account_balance_outlined,
      'content':
          'All payments are processed through our internal escrow system. Funds are held until job completion is confirmed by the client. Disputes about payment must be raised within 7 days of task completion.\n\nWithdrawals are processed within 1-3 business days. Platform fees apply to each transaction and are deducted automatically.',
    },
    {
      'title': 'Dispute Resolution Policy',
      'icon': Icons.gavel_outlined,
      'content':
          'Disputes must be opened within 7 days of task completion. Both parties are required to provide evidence (photos, messages, documents). Our mediation team will review all evidence within 48 hours.\n\nBoulot Man\'s decision in disputes is final. Repeated false disputes may result in account suspension.',
    },
    {
      'title': 'Verification Policy',
      'icon': Icons.verified_outlined,
      'content':
          'All professionals must submit valid government-issued ID and relevant certifications. Company accounts require business registration documents.\n\nVerification review takes 24-72 hours. Unverified accounts have limited platform access. False documents lead to immediate account termination.',
    },
  ];

  final List<Map<String, dynamic>> _safetyRules = [
    {
      'icon': Icons.shield_outlined,
      'title': 'Always Use Escrow',
      'desc':
          'Never pay a professional directly outside the platform. Escrow protects both parties and guarantees payment on completion.',
      'color': const Color(0xFF16A34A),
    },
    {
      'icon': Icons.chat_outlined,
      'title': 'Communicate Within the App',
      'desc':
          'Use Boulot Man\'s messaging system for all job-related communication. This creates a record in case of disputes.',
      'color': const Color(0xFF2563EB),
    },
    {
      'icon': Icons.verified_user_outlined,
      'title': 'Hire Verified Professionals',
      'desc':
          'Look for the verified badge on technician and company profiles. Verified users have passed our identity and skill checks.',
      'color': const Color(0xFFFF4500),
    },
    {
      'icon': Icons.report_problem_outlined,
      'title': 'Report Suspicious Activity',
      'desc':
          'Report any user asking for payment outside the platform or displaying suspicious behaviour. Use the "Report" option on any profile.',
      'color': const Color(0xFFDC2626),
    },
    {
      'icon': Icons.location_on_outlined,
      'title': 'Meet in Safe Locations',
      'desc':
          'For on-site tasks, meet in accessible, public-adjacent areas first. Share job location only with confirmed, verified professionals.',
      'color': const Color(0xFF7C3AED),
    },
    {
      'icon': Icons.photo_camera_outlined,
      'title': 'Document Your Work',
      'desc':
          'Technicians should take before/after photos of every job. Clients should review work before confirming completion and releasing escrow.',
      'color': const Color(0xFF0284C7),
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            title: const Text('Help Center',
                style: TextStyle(
                    color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
            centerTitle: true,
            bottom: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF4500),
              unselectedLabelColor: const Color(0xFF94A3B8),
              indicatorColor: const Color(0xFFFF4500),
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'FAQs'),
                Tab(text: 'Guides'),
                Tab(text: 'Policies'),
                Tab(text: 'Safety'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildFaqTab(appState),
              _buildGuidesTab(),
              _buildPoliciesTab(),
              _buildSafetyTab(),
            ],
          ),
        );
      },
    );
  }

  // ── FAQ Tab ───────────────────────────────────────────────────────────────

  Widget _buildFaqTab(AppState appState) {
    final query = _searchController.text.trim().toLowerCase();
    final List<Map<String, String>> faqs = appState.faqPages.isNotEmpty
        ? appState.faqPages.map((page) => {
              'question': page['title']?.toString() ?? '',
              'answer':
                  page['content']?.toString() ?? page['excerpt']?.toString() ?? '',
            }).toList()
        : _faqs;

    final filtered = faqs
        .where((f) =>
            query.isEmpty ||
            f['question']!.toLowerCase().contains(query) ||
            f['answer']!.toLowerCase().contains(query))
        .toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Search bar
        Container(
          color: const Color(0xFF001F3F),
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search FAQs...',
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Color(0xFF64748B)),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Text('Frequently Asked Questions',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001F3F))),
        ),
        ...filtered.map((faq) => ExpansionTile(
              title: Text(faq['question']!,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF001F3F))),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(faq['answer']!,
                      style: const TextStyle(
                          color: Color(0xFF64748B), height: 1.6)),
                ),
              ],
            )),
        const SizedBox(height: 24),
        _buildContactSupport(),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── Guides Tab ────────────────────────────────────────────────────────────

  Widget _buildGuidesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Step-by-Step Guides',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F3F))),
        const SizedBox(height: 4),
        const Text('Everything you need to get the most out of Boulot Man.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 16),
        ..._guides.map((guide) => _buildGuideCard(guide)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildGuideCard(Map<String, dynamic> guide) {
    final color = guide['color'] as Color;
    return GestureDetector(
      onTap: () => _showGuideDetail(guide),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF001F3F).withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(guide['icon'] as IconData, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guide['title'] as String,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF001F3F))),
                  const SizedBox(height: 3),
                  Text(guide['desc'] as String,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  void _showGuideDetail(Map<String, dynamic> guide) {
    final color = guide['color'] as Color;
    final steps = guide['steps'] as List<String>;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(guide['icon'] as IconData,
                                color: color, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(guide['title'] as String,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF001F3F))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(guide['desc'] as String,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF64748B))),
                      const SizedBox(height: 24),
                      const Text('Steps',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF001F3F))),
                      const SizedBox(height: 16),
                      ...steps.asMap().entries.map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text('${e.key + 1}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(e.value,
                                        style: const TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF001F3F),
                                            height: 1.5)),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Policies Tab ──────────────────────────────────────────────────────────

  Widget _buildPoliciesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Platform Policies',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF001F3F))),
        const SizedBox(height: 4),
        const Text('Legal terms and conditions governing use of Boulot Man.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 16),
        ..._policies.map((policy) => _buildPolicyCard(policy)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPolicyCard(Map<String, dynamic> policy) {
    return GestureDetector(
      onTap: () => _showPolicyDetail(policy),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(policy['icon'] as IconData,
                  color: const Color(0xFF001F3F), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(policy['title'] as String,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF001F3F))),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  void _showPolicyDetail(Map<String, dynamic> policy) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Row(
                  children: [
                    Icon(policy['icon'] as IconData,
                        color: const Color(0xFF001F3F), size: 24),
                    const SizedBox(width: 12),
                    Text(policy['title'] as String,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF001F3F))),
                  ],
                ),
              ),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Text(policy['content'] as String,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF334155),
                          height: 1.8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Safety Tab ────────────────────────────────────────────────────────────

  Widget _buildSafetyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Safety header banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF001F3F), Color(0xFF003366)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Safety First',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 6),
                    Text(
                      'Follow these rules to keep every transaction safe and secure on Boulot Man.',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.security, color: Colors.white, size: 40),
            ],
          ),
        ),
        ..._safetyRules.map((rule) => _buildSafetyCard(rule)),
        const SizedBox(height: 24),
        _buildContactSupport(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSafetyCard(Map<String, dynamic> rule) {
    final color = rule['color'] as Color;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(rule['icon'] as IconData, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rule['title'] as String,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF001F3F))),
                const SizedBox(height: 5),
                Text(rule['desc'] as String,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact Support (shared) ───────────────────────────────────────────────

  Widget _buildContactSupport() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4500).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: const Color(0xFFFF4500).withValues(alpha: 0.15)),
        ),
        child: Column(
          children: [
            const Text('Still need help?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001F3F))),
            const SizedBox(height: 6),
            const Text('Our support team is available 24/7 to assist you.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                AppStateScope.of(context).createOrOpenThread(
                  otherPartyName: 'Boulot Support',
                  otherPartyImage: 'assets/images/boulotman-logo.png',
                  initialMessage: 'Hi, I need help with my account.',
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(
                        name: 'Boulot Support',
                        image: 'assets/images/boulotman-logo.png'),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Chat with Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
