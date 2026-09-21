import 'package:flutter/material.dart';

import 'app_state.dart';

class CompanyReviewsScreen extends StatefulWidget {
  const CompanyReviewsScreen({super.key});

  @override
  State<CompanyReviewsScreen> createState() => _CompanyReviewsScreenState();
}

class _CompanyReviewsScreenState extends State<CompanyReviewsScreen> {
  Map<String, dynamic>? data;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = AppStateScope.of(context).companyProfile;
      if (profile == null) throw Exception('Company profile is unavailable.');
      final result = Map<String, dynamic>.from(profile);
      if (mounted) setState(() => data = result);
    } catch (e) {
      if (mounted)
        setState(() => error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviews = data?['reviews'] is List
        ? List<dynamic>.from(data!['reviews'])
        : const <dynamic>[];
    final average = data?['average_rating']?.toString() ?? '0.00';
    final count =
        data?['review_count']?.toString() ?? reviews.length.toString();
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Reviews & ratings'),
        backgroundColor: const Color(0xFF062B52),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      average,
                      style: const TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF062B52),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '★ ★ ★ ★ ★',
                      style: TextStyle(color: Color(0xFFF59E0B), fontSize: 20),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Based on $count reviews',
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            if (error == null && data != null && reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'No reviews yet. When clients rate your services, they will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ...reviews.map(_reviewCard),
          ],
        ),
      ),
    );
  }

  Widget _reviewCard(dynamic review) {
    final text = review['text']?.toString() ?? '';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    review['reviewer_name']?.toString() ?? 'Client',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF062B52),
                    ),
                  ),
                ),
                Text(
                  '${review['rating'] ?? 0}/5',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              review['service']?.toString() ?? 'Service',
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
            if (text.isNotEmpty) ...[const SizedBox(height: 10), Text(text)],
            const SizedBox(height: 6),
            Text(
              review['created_at']?.toString() ?? '',
              style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}
