import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/api_service.dart';
import 'technician_profile_screen.dart';
import 'onboarding_screen.dart';
import 'technician_portfolio_screen.dart';
import 'technician_navigation.dart';

class TechnicianProfileDetailsScreen extends StatefulWidget {
  const TechnicianProfileDetailsScreen({super.key});
  @override
  State<TechnicianProfileDetailsScreen> createState() => _State();
}

class _PhoneFormatter extends TextInputFormatter {
  _PhoneFormatter(this.groups, {required this.dialCode});
  final List<int> groups;
  final String dialCode;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final max = groups.fold<int>(0, (sum, size) => sum + size);
    final raw = newValue.text.trim();
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    final code = dialCode.replaceAll(RegExp(r'\D'), '');

    // The country code is rendered by the field prefix and must never become
    // part of the editable national-number value when a number is pasted.
    if (raw.startsWith('+') && digits.startsWith(code)) {
      digits = digits.substring(code.length);
    } else if (raw.startsWith('00') && digits.startsWith('00$code')) {
      digits = digits.substring(code.length + 2);
    }
    if (digits.startsWith('0') && digits.length > max) {
      digits = digits.substring(1);
    }
    final limited = digits.substring(0, digits.length.clamp(0, max));
    final parts = <String>[];
    var offset = 0;
    for (final size in groups) {
      if (offset >= limited.length) break;
      final end = (offset + size).clamp(0, limited.length);
      parts.add(limited.substring(offset, end));
      offset = end;
    }
    final formatted = parts.join(' ');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _State extends State<TechnicianProfileDetailsScreen> {
  static const countries = [
    'Nigeria',
    'Rwanda',
    'Kenya',
    'Ghana',
    'South Africa',
    'Ivory Coast',
    'Cameroon',
  ];
  static const dialCodes = <String, String>{
    'Nigeria': '+234',
    'Rwanda': '+250',
    'Kenya': '+254',
    'Ghana': '+233',
    'South Africa': '+27',
    'Ivory Coast': '+225',
    'Cameroon': '+237',
  };
  static const phoneLengths = <String, int>{
    'Nigeria': 10,
    'Rwanda': 9,
    'Kenya': 9,
    'Ghana': 9,
    'South Africa': 9,
    'Ivory Coast': 10,
    'Cameroon': 9,
  };
  static const phoneGroups = <String, List<int>>{
    'Nigeria': [3, 3, 4],
    'Rwanda': [3, 3, 3],
    'Kenya': [3, 3, 3],
    'Ghana': [3, 3, 3],
    'South Africa': [2, 3, 4],
    'Ivory Coast': [2, 2, 2, 2, 2],
    'Cameroon': [3, 2, 2, 2],
  };
  final api = ApiService();
  late Future<Map<String, dynamic>> future = api.profile();
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      muted = Color(0xFF64748B);
  String? avatarUrl, bannerUrl;
  final first = TextEditingController(),
      last = TextEditingController(),
      displayName = TextEditingController(),
      phone = TextEditingController(),
      country = TextEditingController(),
      city = TextEditingController(),
      address = TextEditingController(),
      dateOfBirth = TextEditingController(),
      headline = TextEditingController(),
      occupation = TextEditingController(),
      bio = TextEditingController(),
      experience = TextEditingController(),
      emergencyName = TextEditingController(),
      emergencyPhone = TextEditingController(),
      languages = TextEditingController(),
      education = TextEditingController(),
      expertise = TextEditingController(),
      hourly = TextEditingController(),
      daily = TextEditingController(),
      starting = TextEditingController(),
      inspection = TextEditingController(),
      skills = TextEditingController(),
      tools = TextEditingController(),
      portfolio = TextEditingController(),
      payoutMethod = TextEditingController(),
      payoutNumber = TextEditingController(),
      payoutName = TextEditingController();
  bool availableNow = false, negotiable = false;
  String availability = 'available';
  bool hydrated = false;
  List<dynamic> savedPortfolio = [];
  @override
  void initState() {
    super.initState();
    api
        .portfolioItems()
        .then((items) {
          if (mounted) setState(() => savedPortfolio = items);
        })
        .catchError((_) {});
  }

  bool saving = false;
  bool avatarBusy = false;
  final ImagePicker _imagePicker = ImagePicker();
  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 3),
    appBar: AppBar(
      title: const Text('Expert profile'),
      backgroundColor: navy,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    backgroundColor: const Color(0xFFF4F6F8),
    body: FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError)
          return const Center(
            child: Text('Profile details are temporarily unavailable.'),
          );
        final user = snapshot.data ?? {};
        final profile = user['technician_profile'] is Map
            ? user['technician_profile'] as Map
            : user;
        if (!hydrated) {
          if (avatarUrl == null)
            avatarUrl = _imageUrl(user['avatar_url'] as String?);
          if (bannerUrl == null)
            bannerUrl = _imageUrl(user['banner_url'] as String?);
          first.text = '${user['first_name'] ?? ''}';
          last.text = '${user['last_name'] ?? ''}';
          country.text = countries.contains('${user['country'] ?? ''}')
              ? '${user['country'] ?? ''}'
              : countries.first;
          phone.text = _formatPhone(
            _nationalDigits('${user['phone'] ?? ''}', country.text),
            country.text,
          );
          city.text = '${user['city'] ?? ''}';
          address.text = '${user['address'] ?? ''}';
          dateOfBirth.text = '${user['date_of_birth'] ?? ''}';
          headline.text = '${profile['headline'] ?? user['headline'] ?? ''}';
          occupation.text =
              '${profile['primary_occupation'] ?? user['primary_occupation'] ?? ''}';
          bio.text = '${profile['bio'] ?? user['bio'] ?? ''}';
          experience.text =
              '${user['experience_years'] ?? profile['experience_years'] ?? ''}';
          emergencyName.text =
              '${user['emergency_contact_name'] ?? profile['emergency_contact_name'] ?? ''}';
          emergencyPhone.text =
              '${user['emergency_contact_phone'] ?? profile['emergency_contact_phone'] ?? ''}';
          languages.text = _comma(user['languages']);
          education.text = '${user['education_level'] ?? ''}';
          expertise.text = '${user['expertise_level'] ?? ''}';
          hourly.text =
              '${user['hourly_rate'] ?? profile['hourly_rate'] ?? ''}';
          daily.text = '${user['daily_rate'] ?? ''}';
          starting.text = '${user['starting_price'] ?? ''}';
          inspection.text = '${user['inspection_fee'] ?? ''}';
          skills.text = _comma(user['skills']);
          tools.text = _comma(user['tools']);
          portfolio.text = _comma(user['portfolio']);
          final payout = user['payout'] is Map ? user['payout'] as Map : {};
          payoutMethod.text = '${payout['method'] ?? ''}';
          payoutNumber.text = '${payout['account_number'] ?? ''}';
          payoutName.text = '${payout['account_name'] ?? ''}';
          availability = '${user['availability_status'] ?? 'available'}';
          availableNow = user['available_now'] == true;
          negotiable = user['is_negotiable'] == true;
          hydrated = true;
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 14, 0, 28),
          children: [
            if (bannerUrl != null && bannerUrl!.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 156,
                child: Image.network(
                  bannerUrl!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (bannerUrl != null && bannerUrl!.isNotEmpty)
              const SizedBox(height: 14),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: avatarUrl == null || avatarUrl!.isEmpty
                          ? null
                          : _showAvatarPreview,
                      child: CircleAvatar(
                        key: ValueKey(avatarUrl),
                        radius: 62,
                        backgroundColor: const Color(0xFFFFE8E0),
                        backgroundImage: avatarUrl == null || avatarUrl!.isEmpty
                            ? null
                            : NetworkImage(avatarUrl!),
                        child: avatarUrl == null || avatarUrl!.isEmpty
                            ? const Icon(
                                Icons.person,
                                size: 62,
                                color: Color(0xFFFF4500),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${first.text} ${last.text}'.trim().isEmpty
                          ? 'Your professional profile'
                          : '${first.text} ${last.text}',
                      style: const TextStyle(
                        color: navy,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      headline.text.isEmpty
                          ? 'Complete your professional information'
                          : headline.text,
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: avatarBusy ? null : _changeAvatar,
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Profile picture'),
                        ),
                        OutlinedButton.icon(
                          onPressed: avatarBusy ? null : _changeBanner,
                          icon: const Icon(Icons.panorama_outlined),
                          label: const Text('Banner'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            _publicSummary(user, profile),
            if (savedPortfolio.isNotEmpty) _portfolioGallery(),
            const SizedBox(height: 16),
            _section('Personal information', [
              _input('First name', first),
              _input('Last name', last),
              _input('Display / privacy name', displayName),
              _phoneInput(),
              _dropdown('Country', country.text, countries, (v) {
                if (v == null) return;
                setState(() {
                  final digits = _nationalDigits(phone.text, country.text);
                  country.text = v;
                  phone.text = _formatPhone(digits, v);
                });
              }),
              _input('City', city),
              _input('Address', address),
              _input(
                'Date of birth (YYYY-MM-DD)',
                dateOfBirth,
                keyboardType: TextInputType.datetime,
              ),
            ]),
            _section('Professional information', [
              _input('Professional headline', headline),
              _input('Primary occupation', occupation),
              _input('Bio', bio, lines: 3),
              _input(
                'Experience years',
                experience,
                keyboardType: TextInputType.number,
              ),
              _input('Education level', education),
              _dropdown(
                'Expertise level',
                expertise.text,
                ['Junior', 'Intermediate', 'Senior', 'Expert'],
                (v) => setState(() => expertise.text = v!),
              ),
            ]),
            _section('Contact and languages', [
              _input('Emergency contact name', emergencyName),
              _input(
                'Emergency contact phone',
                emergencyPhone,
                keyboardType: TextInputType.phone,
              ),
              _input('Languages (comma separated)', languages),
            ]),
            _section('Availability', [
              _dropdown(
                'Availability status',
                availability,
                ['available', 'busy', 'offline'],
                (v) => setState(() => availability = v!),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Available now',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w600),
                ),
                value: availableNow,
                activeColor: const Color(0xFFFF4500),
                onChanged: (v) => setState(() => availableNow = v),
              ),
            ]),
            _section('Pricing', [
              _input('Hourly rate', hourly, keyboardType: TextInputType.number),
              _input('Daily rate', daily, keyboardType: TextInputType.number),
              _input(
                'Starting price',
                starting,
                keyboardType: TextInputType.number,
              ),
              _input(
                'Inspection fee',
                inspection,
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Price is negotiable',
                  style: TextStyle(color: navy, fontWeight: FontWeight.w600),
                ),
                value: negotiable,
                activeColor: const Color(0xFFFF4500),
                onChanged: (v) => setState(() => negotiable = v),
              ),
            ]),
            _section('Skills, tools and portfolio', [
              _input('Skills (comma separated)', skills, lines: 2),
              _input('Tools and equipment (comma separated)', tools, lines: 2),
              _input(
                'Portfolio projects (comma separated)',
                portfolio,
                lines: 2,
              ),
            ]),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TechnicianPortfolioScreen(),
                  ),
                ),
                icon: const Icon(Icons.collections_outlined),
                label: const Text('Manage portfolio projects'),
              ),
            ),
            _section('Payout details', [
              _input('Payout method', payoutMethod),
              _input(
                'Account number',
                payoutNumber,
                keyboardType: TextInputType.phone,
              ),
              _input('Account name', payoutName),
            ]),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4500),
                  side: const BorderSide(color: Color(0xFFFF4500), width: 1.5),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TechnicianProfileScreen(),
                  ),
                ),
                icon: const Icon(Icons.verified_user_outlined),
                label: const Text('Verify your account'),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4500),
                  minimumSize: const Size.fromHeight(50),
                ),
                onPressed: saving ? null : _save,
                child: Text(saving ? 'Saving...' : 'Save profile'),
              ),
            ),
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: TextButton.icon(
                onPressed: _deleteAccount,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                ),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Delete account permanently'),
              ),
            ),
          ],
        );
      },
    ),
  );
  Widget _section(String title, List<Widget> children) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );
  Widget _publicSummary(Map user, Map profile) {
    final skillList = user['skills'] is List
        ? (user['skills'] as List)
              .map((e) => '$e')
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];
    final toolList = user['tools'] is List
        ? (user['tools'] as List)
              .map((e) => '$e')
              .where((e) => e.isNotEmpty)
              .toList()
        : <String>[];
    final verified =
        user['is_verified'] == true || profile['is_verified'] == true;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Public profile summary',
              style: TextStyle(
                color: navy,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _badge(
                  verified ? 'Verified professional' : 'Identity pending',
                  verified ? Colors.green : const Color(0xFFD97706),
                ),
                _badge(
                  availableNow ? 'Available now' : 'Busy / offline',
                  availableNow ? Colors.green : muted,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat(
                  'Rating',
                  '${user['average_rating'] ?? profile['average_rating'] ?? '0.0'}',
                ),
                _stat('Reviews', '${user['review_count'] ?? '0'}'),
                _stat(
                  'Completed jobs',
                  '${user['completed_jobs'] ?? profile['completed_jobs'] ?? '0'}',
                ),
              ],
            ),
            if (skillList.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Skills',
                style: TextStyle(color: navy, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              _chips(skillList),
            ],
            if (toolList.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Tools and equipment',
                style: TextStyle(color: navy, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 7),
              _chips(toolList),
            ],
            const SizedBox(height: 14),
            const Text(
              'Pricing',
              style: TextStyle(color: navy, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '${user['hourly_rate'] ?? profile['hourly_rate'] ?? 'Not provided'} hourly  •  ${user['daily_rate'] ?? 'Daily rate not provided'}',
              style: const TextStyle(color: muted),
            ),
            if (savedPortfolio.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Portfolio',
                style: TextStyle(color: navy, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              ...savedPortfolio.map(
                (item) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.work_outline, color: orange),
                  title: Text(
                    '${item['title'] ?? 'Project'}',
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${item['description'] ?? ''}',
                    style: const TextStyle(color: muted),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
    ),
  );
  Widget _portfolioGallery() => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 16),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Portfolio projects',
            style: TextStyle(
              color: navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...savedPortfolio.map((item) => _portfolioCard(item as Map)),
        ],
      ),
    ),
  );
  Widget _portfolioCard(Map item) {
    final image = _imageUrl(item['image_url'] as String?);
    return Card(
      color: const Color(0xFFF8FAFC),
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProject(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (image != null && image.isNotEmpty)
              Image.network(
                image,
                height: 150,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 80,
                  child: Icon(Icons.broken_image_outlined),
                ),
              )
            else
              const SizedBox(
                height: 70,
                child: Icon(Icons.work_outline, color: orange, size: 34),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item['title'] ?? 'Project'}',
                      style: const TextStyle(
                        color: navy,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.expand_more, color: muted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProject(Map item) => showDialog<void>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('${item['title'] ?? 'Project'}'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_imageUrl(item['image_url'] as String?) != null)
              Image.network(
                _imageUrl(item['image_url'] as String)!,
                fit: BoxFit.contain,
              ),
            const SizedBox(height: 12),
            Text(
              '${item['category'] ?? ''}',
              style: const TextStyle(color: muted, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text('${item['description'] ?? 'No description provided.'}'),
          ],
        ),
      ),
    ),
  );
  Widget _stat(String label, String value) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: navy,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: muted, fontSize: 11),
      ),
    ],
  );
  Widget _chips(List<String> values) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: values
        .map(
          (v) => Chip(
            label: Text(v),
            labelStyle: const TextStyle(color: navy, fontSize: 12),
            backgroundColor: const Color(0xFFF1F5F9),
            side: BorderSide.none,
          ),
        )
        .toList(),
  );
  Widget _field(String label, dynamic value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 135,
          child: Text(
            label,
            style: const TextStyle(color: muted, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value == null || '$value'.isEmpty ? 'Not provided' : '$value',
            style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
  Widget _input(
    String label,
    TextEditingController controller, {
    int lines = 1,
    TextInputType? keyboardType,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(
      controller: controller,
      maxLines: lines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD7DEE8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFF4500), width: 1.5),
        ),
      ),
    ),
  );
  Widget _phoneInput() {
    final selectedCountry = countries.contains(country.text)
        ? country.text
        : countries.first;
    final dialCode = dialCodes[selectedCountry] ?? '+234';
    final groups = phoneGroups[selectedCountry] ?? phoneGroups['Nigeria']!;
    final maxLength = phoneLengths[selectedCountry] ?? 10;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: phone,
        keyboardType: TextInputType.phone,
        maxLength: maxLength + (groups.length - 1),
        buildCounter:
            (_, {required currentLength, required isFocused, maxLength}) =>
                null,
        inputFormatters: [_PhoneFormatter(groups, dialCode: dialCode)],
        decoration: InputDecoration(
          labelText: 'Phone number ($dialCode)',
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Align(
              widthFactor: 1,
              alignment: Alignment.centerLeft,
              child: Text(
                dialCode,
                style: const TextStyle(
                  color: navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD7DEE8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFFF4500), width: 1.5),
          ),
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> values,
    ValueChanged<String?> onChanged,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: DropdownButtonFormField<String>(
      initialValue: values.contains(value) ? value : values.first,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: onChanged,
    ),
  );
  String _comma(dynamic value) => value is List
      ? value
            .map((item) => item is Map ? '${item['title'] ?? ''}' : '$item')
            .where((item) => item.isNotEmpty)
            .join(', ')
      : value is String
      ? value
      : '';
  Future<void> _save() async {
    final digits = _nationalDigits(phone.text, country.text);
    final expected = phoneLengths[country.text] ?? 10;
    if (digits.length != expected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Enter a valid ${dialCodes[country.text]} phone number for ${country.text}.',
          ),
        ),
      );
      return;
    }
    final dob = dateOfBirth.text.trim();
    if (dob.isNotEmpty && DateTime.tryParse(dob) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Date of birth must use YYYY-MM-DD.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      await api.updateProfile({
        'first_name': first.text.trim(),
        'last_name': last.text.trim(),
        'phone': '${dialCodes[country.text]}$digits',
        'country': country.text.trim(),
        'city': city.text.trim(),
        'address': address.text.trim(),
        'date_of_birth': dob.isEmpty ? null : dob,
        'headline': headline.text.trim(),
        'primary_occupation': occupation.text.trim(),
        'bio': bio.text.trim(),
        'experience_years': experience.text.trim(),
        'emergency_contact_name': emergencyName.text.trim(),
        'emergency_contact_phone': emergencyPhone.text.trim(),
        'languages': _list(languages.text),
        'education_level': education.text.trim(),
        'expertise_level': expertise.text.trim(),
        'availability_status': availability,
        'available_now': availableNow,
        'hourly_rate': hourly.text.trim(),
        'daily_rate': daily.text.trim(),
        'starting_price': starting.text.trim(),
        'inspection_fee': inspection.text.trim(),
        'is_negotiable': negotiable,
        'skills': _list(skills.text),
        'tools': _list(tools.text),
        'portfolio': _list(portfolio.text),
        'payout': {
          'method': payoutMethod.text.trim(),
          'account_number': payoutNumber.text.trim(),
          'account_name': payoutName.text.trim(),
        },
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully.')),
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not save your profile. Please try again.'),
          ),
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  String _nationalDigits(String raw, String selectedCountry) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    final code = (dialCodes[selectedCountry] ?? '+234').substring(1);
    if (digits.startsWith(code)) digits = digits.substring(code.length);
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits.substring(
      0,
      digits.length.clamp(0, phoneLengths[selectedCountry] ?? 10),
    );
  }

  String _formatPhone(String digits, String selectedCountry) {
    final groups = phoneGroups[selectedCountry] ?? phoneGroups['Nigeria']!;
    final parts = <String>[];
    var offset = 0;
    for (final size in groups) {
      if (offset >= digits.length) break;
      final end = (offset + size).clamp(0, digits.length);
      parts.add(digits.substring(offset, end));
      offset = end;
    }
    return parts.join(' ');
  }

  List<String> _list(String value) =>
      value.split(',').map((v) => v.trim()).where((v) => v.isNotEmpty).toList();
  String? _imageUrl(String? value) {
    if (value == null || value.isEmpty) return value;
    if (value.startsWith('http://') || value.startsWith('https://'))
      return value;
    return 'http://BoulotMan-API-env.eba-exncce63.eu-north-1.elasticbeanstalk.com$value';
  }

  void _showAvatarPreview() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black87,
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    avatarUrl!,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white,
                      size: 64,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close, color: Colors.white, size: 34),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _changeAvatar() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.length > 10 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture must be 10 MB or smaller.'),
        ),
      );
      return;
    }
    setState(() => avatarBusy = true);
    try {
      final url = await api.uploadAvatarBytes(
        bytes: bytes,
        filename: image.name,
      );
      if (mounted) {
        setState(() => avatarUrl = _imageUrl(url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully.'),
          ),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'We could not update your profile picture. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => avatarBusy = false);
    }
  }

  Future<void> _changeBanner() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.length > 25 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner must be 25 MB or smaller.')),
      );
      return;
    }
    setState(() => avatarBusy = true);
    try {
      final url = await api.uploadBannerBytes(
        bytes: bytes,
        filename: image.name,
      );
      if (mounted) {
        setState(() => bannerUrl = _imageUrl(url));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner updated successfully.')),
        );
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is ApiException
                  ? error.message
                  : 'We could not update your banner. Please try again.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => avatarBusy = false);
    }
  }

  Future<void> _logout() async {
    await api.clearSession();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (_) => false,
      );
  }

  Future<void> _deleteAccount() async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete account permanently?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This permanently deletes your account, profile, documents, and history. This cannot be undone.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Type DELETE to confirm',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, controller.text.trim() == 'DELETE'),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await api.deleteAccount();
      if (mounted)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
          (_) => false,
        );
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'We could not delete your account. Please try again.',
            ),
          ),
        );
    }
  }
}
