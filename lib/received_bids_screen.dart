import 'package:flutter/material.dart';

import 'app_state.dart';
import 'company_profile_screen.dart';
import 'technician_public_profile_screen.dart';

class ReceivedBidsScreen extends StatelessWidget {
  const ReceivedBidsScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final task = appState.findTask(taskId)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text('Bids Received', style: TextStyle(color: Color(0xFF001F3F), fontSize: 16, fontWeight: FontWeight.bold)),
            Text(task.title, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ],
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: appState.bidsForTask(taskId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4500)),
              ),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'Error loading bids: ${snapshot.error.toString().replaceAll('Exception: ', '')}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            );
          }
          final bids = snapshot.data ?? [];
          if (bids.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  const Text(
                    'No bids received yet for this task.',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bids.length,
            itemBuilder: (context, index) => _buildBidCard(context, bids[index], taskId),
          );
        },
      ),
    );
  }

  Widget _buildBidCard(BuildContext context, dynamic bid, String taskId) {
    final appState = AppStateScope.of(context);
    final bool isBestValue = bid.isBestValue == true;
    final bool isAccepted = bid.isAccepted == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAccepted || isBestValue ? const Color(0xFFFF4500) : const Color(0xFFE2E8F0),
          width: isAccepted || isBestValue ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAccepted || isBestValue)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAccepted ? const Color(0xFF001F3F) : const Color(0xFFFF4500),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isAccepted ? 'ACCEPTED' : 'BEST VALUE',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: buildAvatarImage(
                  bid.avatar,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  fallback: Container(
                    width: 48,
                    height: 48,
                    color: const Color(0xFF001F3F),
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bid.bidderName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                    Text(bid.skill, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('\$${bid.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFF4500))),
                  Text(bid.timeline, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(bid.message, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final matchedPro = appState.publicPros.firstWhere(
                      (u) {
                        final String name = '${u['first_name'] ?? ''} ${u['last_name'] ?? ''}'.trim().isNotEmpty
                            ? '${u['first_name']} ${u['last_name']}'.trim()
                            : (u['username'] ?? '');
                        return name.toLowerCase() == bid.bidderName.toLowerCase();
                      },
                      orElse: () => <String, dynamic>{},
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => TechnicianPublicProfileScreen(
                          name: bid.bidderName,
                          skill: bid.skill,
                          avatar: bid.avatar,
                          price: '\$${bid.price.toStringAsFixed(0)}/hr',
                          rating: '${bid.rating} (${bid.reviews})',
                          rawData: matchedPro.isNotEmpty ? matchedPro : {
                            'id': bid.id,
                            'first_name': bid.bidderName,
                            'avatar_url': bid.avatar,
                            'bio': 'Registered professional technician.',
                            'skills': [bid.skill],
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('View Profile'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isAccepted
                      ? null
                      : () async {
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
                            await AppStateScope.of(context).acceptBid(taskId, bid.id);
                            if (context.mounted) {
                              Navigator.of(context).pop(); // Dismiss loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Bid accepted and task moved to In Progress.')),
                              );
                              Navigator.of(context).pop(); // Return to previous task view
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
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF001F3F), foregroundColor: Colors.white),
                  child: Text(isAccepted ? 'Accepted' : 'Accept Bid'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
