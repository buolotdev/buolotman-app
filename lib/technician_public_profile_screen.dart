import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'api_service.dart';
import 'app_state.dart';
import 'chat_screen.dart';

class TechnicianPublicProfileScreen extends StatefulWidget {
  final String name;
  final String skill;
  final String avatar;
  final String price;
  final String rating;
  final Map<String, dynamic> rawData;

  const TechnicianPublicProfileScreen({
    super.key,
    required this.name,
    required this.skill,
    required this.avatar,
    required this.price,
    required this.rating,
    required this.rawData,
  });

  @override
  State<TechnicianPublicProfileScreen> createState() => _TechnicianPublicProfileScreenState();
}

class _TechnicianPublicProfileScreenState extends State<TechnicianPublicProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _fullData = {};

  @override
  void initState() {
    super.initState();
    _fetchFullProfile();
  }

  Future<void> _fetchFullProfile() async {
    try {
      final String techId = widget.rawData['id']?.toString() ?? '';
      if (techId.isNotEmpty) {
        final response = await ApiService.instance.get('/auth/users/$techId/');
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (mounted) {
            setState(() {
              _fullData = data is Map<String, dynamic> ? data : {};
              _isLoading = false;
            });
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching full profile: $e');
    }
    if (mounted) {
      setState(() {
        _fullData = widget.rawData;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dataMap = _isLoading ? widget.rawData : _fullData;

    final String bio = dataMap['bio']?.toString().trim().isNotEmpty == true
        ? dataMap['bio'].toString().trim()
        : "This professional hasn't uploaded a bio yet.";

    final List<dynamic> dbSkills = dataMap['skills'] is List ? dataMap['skills'] : [];
    final List<String> specialties = dbSkills.isNotEmpty
        ? dbSkills.map((s) => s.toString().trim()).where((s) => s.isNotEmpty).toList()
        : [widget.skill];

    final List<dynamic> dbPortfolio = dataMap['portfolio'] is List ? dataMap['portfolio'] : [];
    final List<dynamic> dbReviews = dataMap['reviews'] is List ? dataMap['reviews'] : [];
    final List<dynamic> certifications = dataMap['certifications'] is List ? dataMap['certifications'] : [];
    final String experience = dataMap['experience']?.toString().trim() ?? '';

    final double ratingVal = double.tryParse(dataMap['average_rating']?.toString() ?? '') ?? 0.0;
    final int reviewsVal = int.tryParse(dataMap['completed_jobs']?.toString() ?? '') ?? 0;
    final String ratingStr = ratingVal > 0 ? ratingVal.toStringAsFixed(1) : '0.0';
    final String ratingText = '$ratingStr ($reviewsVal)';

    final double hourlyRateVal = double.tryParse(dataMap['hourly_rate']?.toString() ?? '') ?? 0.0;
    final String priceText = _isLoading
        ? (hourlyRateVal > 0 ? '\$${hourlyRateVal.toStringAsFixed(0)}/hr' : '...')
        : (hourlyRateVal > 0 ? '\$${hourlyRateVal.toStringAsFixed(0)}/hr' : 'Rate not set');

    final String avatarUrl = (dataMap['avatar_url']?.toString().isNotEmpty == true)
        ? dataMap['avatar_url']
        : widget.avatar;

    final String availability = (dataMap['availability_status']?.toString() ?? 'available').toLowerCase();
    Color availColor = const Color(0xFF16A34A); // Green
    String availText = 'Available';
    if (availability == 'busy') {
      availColor = const Color(0xFFEF4444); // Red
      availText = 'Busy';
    } else if (availability == 'away') {
      availColor = const Color(0xFFF59E0B); // Orange
      availText = 'Away';
    }

    return GetBuilder<AppState>(
      builder: (appState) {
        final String techId = dataMap['id']?.toString() ?? widget.rawData['id']?.toString() ?? '';
        final bool isSaved = appState.isTechSaved(techId);

        return Scaffold(
          backgroundColor: const Color(0xFFFEFEFF),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.name,
              style: const TextStyle(color: Color(0xFF001F3F), fontWeight: FontWeight.w700, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? const Color(0xFFFF5500) : const Color(0xFF001F3F),
                ),
                onPressed: () {
                  appState.toggleSavedTech(techId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        !isSaved ? 'Added ${widget.name} to saved professionals.' : 'Removed ${widget.name} from saved professionals.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(avatarUrl, ratingText, priceText, availColor, availText),
                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildActionButtons(),
                      const SizedBox(height: 28),
                      _buildSectionHeader("About Professional"),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500))),
                              ),
                            )
                          : Text(
                              bio,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.6),
                            ),
                      const SizedBox(height: 28),
                      _buildSectionHeader("Personal Details"),
                      const SizedBox(height: 12),
                      _buildPersonalDetailRow(Icons.email_outlined, "Email", dataMap['email']?.toString() ?? 'N/A'),
                      const SizedBox(height: 8),
                      _buildPersonalDetailRow(Icons.location_on_outlined, "Location", dataMap['country']?.toString() ?? 'N/A'),
                      const SizedBox(height: 28),
                      _buildSectionHeader("Specialties"),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500))),
                            )
                          : _buildSpecialtyTags(specialties),
                      const SizedBox(height: 28),
                      _buildSectionHeader("Experience"),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8.0),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500))),
                              ),
                            )
                          : Text(
                              experience.isNotEmpty ? experience : "No experience history uploaded.",
                              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.6),
                            ),
                      const SizedBox(height: 28),
                      _buildSectionHeader("Certifications"),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500))),
                            )
                          : _buildCertificationsSection(certifications),
                      const SizedBox(height: 28),
                      _buildSectionHeader("Portfolio"),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const SizedBox(
                              height: 100,
                              child: Center(
                                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500))),
                              ),
                            )
                          : _buildPortfolioSection(dbPortfolio),
                      const SizedBox(height: 28),
                      _buildSectionHeader("Client Reviews"),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const SizedBox(
                              height: 60,
                              child: Center(
                                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500))),
                              ),
                            )
                          : _buildReviewsSection(dbReviews),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroHeader(String avatarUrl, String rating, String price, Color availColor, String availText) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF001F3F),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: const Color(0xFFF1F5F9),
            backgroundImage: (avatarUrl.isNotEmpty && !avatarUrl.contains('onboard'))
                ? getAvatarImageProvider(avatarUrl)
                : null,
            child: (avatarUrl.isEmpty || avatarUrl.contains('onboard'))
                ? const Icon(Icons.person, size: 48, color: Color(0xFF94A3B8))
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            widget.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: availColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                availText,
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.skill,
            style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMetricBadge(Icons.star, const Color(0xFFFFB020), rating),
              const SizedBox(width: 12),
              _buildMetricBadge(Icons.monetization_on, const Color(0xFF1E8E3E), price),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, Color iconColor, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          "$label: ",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationsSection(List<dynamic> certs) {
    if (certs.isEmpty) {
      return const Text(
        "No certifications listed.",
        style: TextStyle(fontSize: 14, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
      );
    }
    return Column(
      children: certs.map((c) {
        final String name = c is Map ? (c['name'] ?? '').toString() : c.toString();
        final String authority = c is Map ? (c['authority'] ?? '').toString() : '';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user, color: Color(0xFFFF4500), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                    if (authority.isNotEmpty)
                      Text(authority, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
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
                final appState = AppStateScope.of(context);
                await appState.createOrOpenThread(
                  otherPartyName: widget.name,
                  otherPartyImage: widget.avatar,
                );
                if (context.mounted) {
                  Navigator.of(context).pop(); // dismiss loading
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(name: widget.name, image: widget.avatar),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop(); // dismiss loading
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error opening chat: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.chat_bubble_outline, size: 18, color: Colors.white),
            label: const Text("Message", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5500),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text("Hire Professional", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                  content: Text("Do you want to send a job offer invitation to ${widget.name}? they will receive a notification to connect with you."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Hiring invitation sent successfully to ${widget.name}!")),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5500), foregroundColor: Colors.white),
                      child: const Text("Send Offer"),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.handshake_outlined, size: 18, color: Color(0xFFFF5500)),
            label: const Text("Hire Now", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFFF5500))),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFFF5500)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F)),
    );
  }

  Widget _buildSpecialtyTags(List<String> specialties) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: specialties.map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            tag,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPortfolioSection(List<dynamic> portfolio) {
    if (portfolio.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          "No portfolio projects uploaded yet.",
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontStyle: FontStyle.italic),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: portfolio.length,
        itemBuilder: (context, index) {
          final item = portfolio[index];
          final String title = item['title']?.toString() ?? 'Project Title';
          final String desc = item['description']?.toString() ?? 'Woodwork / Electric Project Details';
          final String imageUrl = item['image_url']?.toString() ?? '';

          return Container(
            width: 220,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: imageUrl.isNotEmpty
                          ? buildAvatarImage(imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: const Color(0xFFF1F5F9),
                              child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
                            ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001F3F)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewsSection(List<dynamic> reviews) {
    if (reviews.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          "No reviews received yet.",
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontStyle: FontStyle.italic),
        ),
      );
    }

    return Column(
      children: reviews.map((item) {
        final reviewer = item['reviewer_name']?.toString() ?? 'Client';
        final double score = double.tryParse(item['rating']?.toString() ?? '5.0') ?? 5.0;
        final comment = item['comment']?.toString() ?? 'No comment provided';

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(reviewer, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFB020), size: 14),
                        const SizedBox(width: 4),
                        Text(score.toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(comment, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
