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

class _TechnicianPublicProfileScreenState extends State<TechnicianPublicProfileScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic> _fullData = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _fetchFullProfile();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchFullProfile() async {
    try {
      final String techId = widget.rawData['id']?.toString() ?? '';
      if (techId.isNotEmpty) {
        final response = await ApiService.instance.get('/auth/users/\$techId/');
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
      debugPrint('Error fetching full profile: \$e');
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
    final String ratingText = '\$ratingStr (\$reviewsVal)';

    final double startingPriceVal = double.tryParse(dataMap['starting_price']?.toString() ?? '') ?? 0.0;
    final double hourlyRateVal = double.tryParse(dataMap['hourly_rate']?.toString() ?? '') ?? 0.0;
    final double dailyRateVal = double.tryParse(dataMap['daily_rate']?.toString() ?? '') ?? 0.0;
    final double fixedPriceVal = double.tryParse(dataMap['fixed_price']?.toString() ?? '') ?? 0.0;
    final double inspectionFeeVal = double.tryParse(dataMap['inspection_fee']?.toString() ?? '') ?? 0.0;
    final List<dynamic> toolsList = dataMap['tools_and_equipment'] is List ? dataMap['tools_and_equipment'] : [];
    final List<dynamic> prefsList = dataMap['work_preferences'] is List ? dataMap['work_preferences'] : [];
    final List<dynamic> languages = dataMap['preferred_languages'] is List ? dataMap['preferred_languages'] : [];
    final List<dynamic> licences = dataMap['licences'] is List ? dataMap['licences'] : [];

    final String priceText = _isLoading
        ? (hourlyRateVal > 0 ? '\$\${hourlyRateVal.toStringAsFixed(0)}/hr' : '...')
        : (hourlyRateVal > 0 ? '\$\${hourlyRateVal.toStringAsFixed(0)}/hr' : 'Rate not set');

    final String avatarUrl = (dataMap['avatar_url']?.toString().isNotEmpty == true)
        ? dataMap['avatar_url']
        : widget.avatar;

    final String availability = (dataMap['availability_status']?.toString() ?? 'available').toLowerCase();
    Color availColor = const Color(0xFF16A34A);
    String availText = 'Available';
    if (availability == 'busy') {
      availColor = const Color(0xFFEF4444);
      availText = 'Busy';
    } else if (availability == 'offline') {
      availColor = const Color(0xFF94A3B8);
      availText = 'Offline';
    }

    final String verificationBadge = dataMap['verification_badge']?.toString() ?? 'Unverified';
    final String tagline = dataMap['tagline']?.toString().trim().isNotEmpty == true 
        ? dataMap['tagline'].toString() 
        : (dataMap['primary_occupation']?.toString().isNotEmpty == true ? dataMap['primary_occupation']! : 'Technician');
    final String city = dataMap['city']?.toString() ?? '';
    final String primaryOccupation = dataMap['primary_occupation']?.toString() ?? '';
    final int yearsExp = int.tryParse(dataMap['years_experience']?.toString() ?? '0') ?? 0;

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
                        !isSaved ? 'Added \${widget.name} to saved professionals.' : 'Removed \${widget.name} from saved professionals.',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: const Color(0xFFFF4500),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFFFF4500),
              tabs: const [
                Tab(text: 'About'),
                Tab(text: 'Services'),
                Tab(text: 'Portfolio'),
                Tab(text: 'Reviews'),
                Tab(text: 'Availability & Rates'),
              ],
            ),
          ),
          body: Column(
            children: [
              _buildHeroHeader(avatarUrl, ratingText, tagline, availColor, availText, verificationBadge, city),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
                child: _buildActionButtons(),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: About
                    ListView(
                      padding: const EdgeInsets.all(20.0),
                      children: [
                        _buildSectionHeader("About Professional"),
                        const SizedBox(height: 10),
                        _isLoading
                            ? _buildLoading()
                            : Text(bio, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.6)),
                        const SizedBox(height: 28),
                        _buildSectionHeader("Personal Details"),
                        const SizedBox(height: 12),
                        _buildPersonalDetailRow(Icons.email_outlined, "Email", dataMap['email']?.toString() ?? 'N/A'),
                        _buildPersonalDetailRow(Icons.location_on_outlined, "Location", [if (city.isNotEmpty) city, dataMap['country']?.toString() ?? ''].where((e) => e.isNotEmpty).join(', ')),
                        if (primaryOccupation.isNotEmpty) ...[const SizedBox(height: 8), _buildPersonalDetailRow(Icons.work_outline, "Occupation", primaryOccupation)],
                        if (yearsExp > 0) ...[const SizedBox(height: 8), _buildPersonalDetailRow(Icons.access_time_outlined, "Experience", '\$yearsExp years')],
                        if (languages.isNotEmpty) ...[const SizedBox(height: 8), _buildPersonalDetailRow(Icons.language_outlined, "Languages", languages.join(', ')),],
                        const SizedBox(height: 28),
                        _buildSectionHeader("Experience"),
                        const SizedBox(height: 10),
                        _isLoading
                            ? _buildLoading()
                            : Text(experience.isNotEmpty ? experience : 'No specific experience documented.', style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.6)),
                        const SizedBox(height: 28),
                        _buildVerificationBadges(verificationBadge),
                      ],
                    ),
                    
                    // Tab 2: Services
                    ListView(
                      padding: const EdgeInsets.all(20.0),
                      children: [
                        _buildSectionHeader("Specialties"),
                        const SizedBox(height: 12),
                        _isLoading ? _buildLoading() : _buildSpecialtyTags(specialties),
                        const SizedBox(height: 28),
                        _buildSectionHeader("Certifications & Licences"),
                        const SizedBox(height: 12),
                        _isLoading ? _buildLoading() : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (certifications.isEmpty && licences.isEmpty)
                              const Text('No certifications or licences provided.', style: TextStyle(color: Color(0xFF64748B))),
                            if (certifications.isNotEmpty) ...certifications.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(children: [
                                const Icon(Icons.verified_outlined, size: 16, color: Color(0xFFFF4500)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(c.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF001F3F)))),
                              ]),
                            )),
                            if (licences.isNotEmpty) ...licences.map((l) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(children: [
                                const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF2563EB)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(l.toString(), style: const TextStyle(fontSize: 13, color: Color(0xFF001F3F)))),
                              ]),
                            )),
                          ]
                        ),
                        const SizedBox(height: 28),
                        _buildSectionHeader("Tools & Equipment"),
                        const SizedBox(height: 12),
                        _isLoading ? _buildLoading() : _buildSpecialtyTags(toolsList.map((e) => e.toString()).toList()),
                        const SizedBox(height: 28),
                        _buildSectionHeader("Boulot Man Eligibility"),
                        const SizedBox(height: 12),
                        if (_isLoading) _buildLoading()
                        else Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildToggleRow('BM Concierge', dataMap['bm_concierge'] == true || dataMap['bm_concierge'] == 'true'),
                            _buildToggleRow('BM Build a Team', dataMap['bm_build_team'] == true || dataMap['bm_build_team'] == 'true'),
                            _buildToggleRow('BM Emergency', dataMap['bm_emergency'] == true || dataMap['bm_emergency'] == 'true'),
                            _buildToggleRow('Can Supervise Technicians', dataMap['can_supervise'] == true || dataMap['can_supervise'] == 'true'),
                          ]
                        )
                      ],
                    ),
                    
                    // Tab 3: Portfolio
                    ListView(
                      padding: const EdgeInsets.all(20.0),
                      children: [
                        _buildPortfolioSection(dbPortfolio),
                      ],
                    ),

                    // Tab 4: Reviews
                    ListView(
                      padding: const EdgeInsets.all(20.0),
                      children: [
                        _buildReviewsSection(dbReviews),
                      ],
                    ),

                    // Tab 5: Availability & Rates
                    ListView(
                      padding: const EdgeInsets.all(20.0),
                      children: [
                        _buildSectionHeader("Availability"),
                        const SizedBox(height: 12),
                        if (_isLoading) _buildLoading()
                        else Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildToggleRow('Available Now (Urgent)', dataMap['available_now'] == true || dataMap['available_now'] == 'true'),
                            _buildToggleRow('Accepts On-site Work', dataMap['accepts_onsite'] != false && dataMap['accepts_onsite'] != 'false'),
                            _buildToggleRow('Accepts Remote Work', dataMap['accepts_remote'] == true || dataMap['accepts_remote'] == 'true'),
                            _buildToggleRow('Accepts Weekend Work', dataMap['accepts_weekends'] == true || dataMap['accepts_weekends'] == 'true'),
                            _buildToggleRow('Accepts Emergency Jobs', dataMap['accepts_emergency'] == true || dataMap['accepts_emergency'] == 'true'),
                            _buildToggleRow('Available Full-time', dataMap['accepts_full_time'] == true || dataMap['accepts_full_time'] == 'true'),
                            _buildToggleRow('Available Part-time', dataMap['accepts_part_time'] != false && dataMap['accepts_part_time'] != 'false'),
                            const Divider(),
                            _buildToggleRow('Willing to Travel', dataMap['willing_to_travel'] == true || dataMap['willing_to_travel'] == 'true'),
                            if (dataMap['willing_to_travel'] == true || dataMap['willing_to_travel'] == 'true')
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 8),
                                child: Text('Service Radius: ${dataMap["service_radius_km"] ?? 0} km', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F3F))),
                              ),
                          ]
                        ),
                        const SizedBox(height: 28),
                        _buildSectionHeader("Work Preferences"),
                        const SizedBox(height: 12),
                        _isLoading ? _buildLoading() : _buildSpecialtyTags(prefsList.map((e) => e.toString()).toList()),
                        const SizedBox(height: 28),
                        _buildSectionHeader("Rates & Fees"),
                        const SizedBox(height: 12),
                        _isLoading
                            ? _buildLoading()
                            : Column(
                                children: [
                                  if (startingPriceVal > 0) _buildPersonalDetailRow(Icons.monetization_on_outlined, "Starting Price", "\$\${startingPriceVal.toStringAsFixed(2)}"),
                                  if (startingPriceVal > 0) const SizedBox(height: 8),
                                  if (hourlyRateVal > 0) _buildPersonalDetailRow(Icons.payments_outlined, "Hourly Rate", "\$\${hourlyRateVal.toStringAsFixed(2)}"),
                                  if (hourlyRateVal > 0) const SizedBox(height: 8),
                                  if (dailyRateVal > 0) _buildPersonalDetailRow(Icons.calendar_today_outlined, "Daily Rate", "\$\${dailyRateVal.toStringAsFixed(2)}"),
                                  if (dailyRateVal > 0) const SizedBox(height: 8),
                                  if (fixedPriceVal > 0) _buildPersonalDetailRow(Icons.handshake_outlined, "Fixed Price", "\$\${fixedPriceVal.toStringAsFixed(2)}"),
                                  if (fixedPriceVal > 0) const SizedBox(height: 8),
                                  if (inspectionFeeVal > 0) _buildPersonalDetailRow(Icons.search_outlined, "Inspection Fee", "\$\${inspectionFeeVal.toStringAsFixed(2)}"),
                                  if (startingPriceVal == 0 && hourlyRateVal == 0 && dailyRateVal == 0 && fixedPriceVal == 0 && inspectionFeeVal == 0)
                                    const Text("No rates specified.", style: TextStyle(color: Color(0xFF64748B))),
                                ],
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF5500))),
      ),
    );
  }

  Widget _buildToggleRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(value ? Icons.check_circle : Icons.cancel, color: value ? Colors.green : Colors.grey, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF001F3F)))),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(String avatarUrl, String ratingText, String tagline, Color availColor, String availText, String verificationBadge, String city) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: avatarUrl.isNotEmpty 
                      ? DecorationImage(
                          image: avatarUrl.startsWith('data:image') 
                              ? MemoryImage(base64Decode(avatarUrl.split(',').last))
                              : getAvatarImageProvider(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: const Color(0xFFF1F5F9),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                ),
                child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Color(0xFF94A3B8)) : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: availColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF001F3F)),
                ),
                const SizedBox(height: 4),
                Text(
                  tagline,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFFFF5500)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Color(0xFFFFB020), size: 16),
                        const SizedBox(width: 4),
                        Text(ratingText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    if (city.isNotEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF64748B), size: 16),
                          const SizedBox(width: 4),
                          Text(city, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: verificationBadge == 'Unverified' ? const Color(0xFFF1F5F9) : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        verificationBadge == 'Unverified' ? Icons.info_outline : Icons.verified,
                        size: 12,
                        color: verificationBadge == 'Unverified' ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        verificationBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: verificationBadge == 'Unverified' ? const Color(0xFF64748B) : const Color(0xFF0284C7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
                    SnackBar(content: Text('Error opening chat: \$e')),
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
                  content: Text("Do you want to send a job offer invitation to \${widget.name}? they will receive a notification to connect with you."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Hiring invitation sent successfully to \${widget.name}!")),
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

  Widget _buildPersonalDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 14, color: Color(0xFF001F3F), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadges(String verificationBadge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Verification"),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              _buildVerifItem("Identity Verified", verificationBadge != 'Unverified'),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),
              _buildVerifItem("Professional Qualifications Verified", verificationBadge == 'Professional Verified' || verificationBadge == 'BM Verified Professional'),
              const Divider(height: 24, color: Color(0xFFE2E8F0)),
              _buildVerifItem("Background Check Passed", verificationBadge == 'BM Verified Professional'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifItem(String label, bool isVerified) {
    return Row(
      children: [
        Icon(
          isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isVerified ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isVerified ? FontWeight.w600 : FontWeight.w400,
              color: isVerified ? const Color(0xFF001F3F) : const Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpecialtyTags(List<String> specialties) {
    if (specialties.isEmpty) {
      return const Text("None specified.", style: TextStyle(color: Color(0xFF64748B)));
    }
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

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: portfolio.length,
      itemBuilder: (context, index) {
        final item = portfolio[index];
        final String title = item['title']?.toString() ?? 'Project Title';
        final String desc = item['description']?.toString() ?? 'Woodwork / Electric Project Details';
        final String imageUrl = item['image_url']?.toString() ?? '';

        return Container(
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
                        maxLines: 2,
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
