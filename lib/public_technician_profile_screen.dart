import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';

class PublicTechnicianProfileScreen extends StatelessWidget {
  final Map<String, dynamic> technicianData;

  const PublicTechnicianProfileScreen({Key? key, required this.technicianData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
        title: const Text('Technician Profile', style: TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF001F3F)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildTrustIndicators(),
            const SizedBox(height: 8),
            _buildStats(),
            const SizedBox(height: 8),
            _buildTabs(context),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF001F3F),
                    side: const BorderSide(color: Color(0xFF001F3F)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Message'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4500),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Hire Me'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: (technicianData['avatar_url'] != null && technicianData['avatar_url'].toString().isNotEmpty)
                ? NetworkImage(technicianData['avatar_url'])
                : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${technicianData['first_name'] ?? ''} ${technicianData['last_name'] ?? ''}'.trim().isEmpty
                    ? (technicianData['username'] ?? 'Technician')
                    : '${technicianData['first_name'] ?? ''} ${technicianData['last_name'] ?? ''}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
              ),
              const SizedBox(width: 8),
              if (technicianData['verification_badge'] != 'Unverified')
                const Icon(Icons.verified, color: Colors.blue, size: 24),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            technicianData['primary_occupation'] ?? technicianData['tagline'] ?? 'Professional Technician',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text('${technicianData['average_rating'] ?? '0.0'} (127 reviews)', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 12),
              const Icon(Icons.location_on, color: Colors.grey, size: 18),
              const SizedBox(width: 4),
              Text(technicianData['city'] ?? 'Douala', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrustIndicators() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTrustBadge(Icons.fingerprint, 'Identity Verified', technicianData['identity_verified'] == true),
            const SizedBox(width: 12),
            _buildTrustBadge(Icons.workspace_premium, 'Professional Verified', technicianData['professional_verified'] == true),
            const SizedBox(width: 12),
            _buildTrustBadge(Icons.verified_user, 'Boulot Man Verified', technicianData['boulotman_verified'] == true),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String text, bool verified) {
    if (!verified) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('${technicianData['years_experience'] ?? 0} yrs', 'Experience'),
          _buildStatItem('${technicianData['completed_jobs'] ?? 0}', 'Jobs Completed'),
          _buildStatItem('96%', 'Completion Rate'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildTabs(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              isScrollable: true,
              labelColor: Color(0xFFFF4500),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFFFF4500),
              tabs: [
                Tab(text: 'About'),
                Tab(text: 'Services'),
                Tab(text: 'Portfolio'),
                Tab(text: 'Reviews'),
                Tab(text: 'Availability'),
              ],
            ),
          ),
          Container(
            color: Colors.white,
            height: 400, // Fixed height for demo
            child: TabBarView(
              children: [
                _buildAboutTab(),
                const Center(child: Text('Services Listing')),
                const Center(child: Text('Portfolio & Work Gallery')),
                const Center(child: Text('Client Reviews')),
                const Center(child: Text('Availability Calendar')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('About Me', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
        const SizedBox(height: 12),
        Text(
          technicianData['bio']?.toString().isNotEmpty == true
              ? technicianData['bio']
              : 'This professional has not written an "About me" summary yet.',
          style: const TextStyle(color: Colors.black87, height: 1.5),
        ),
        const SizedBox(height: 24),
        const Text('Pricing', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
        const SizedBox(height: 12),
        if (technicianData['hourly_rate'] != null) Text('• Hourly Rate: \$${technicianData['hourly_rate']}'),
        if (technicianData['daily_rate'] != null) Text('• Daily Rate: \$${technicianData['daily_rate']}'),
        if (technicianData['starting_price'] != null) Text('• Starting Price: \$${technicianData['starting_price']}'),
      ],
    );
  }
}
