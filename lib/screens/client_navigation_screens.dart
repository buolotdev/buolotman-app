import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import '../core/api_service.dart';
import 'login_screen.dart';
import 'client_dashboard_screen.dart';
import 'client_task_management_screen.dart';
import 'client_messaging_screen.dart';
import 'client_payment_screen.dart';
import '../browse_professionals_screen.dart';
import '../profile_media_actions.dart';
import '../phone_validation.dart';

const clientNavy = Color(0xFF001F3F),
    clientOrange = Color(0xFFFF4500),
    clientMuted = Color(0xFF64748B),
    clientBg = Color(0xFFF5F7FA);
List<dynamic> clientItems(dynamic value) => value is List
    ? value
    : value is Map && value['results'] is List
    ? value['results'] as List
    : const [];

class ClientProfileOverviewScreen extends StatefulWidget {
  const ClientProfileOverviewScreen({
    super.key,
    this.withBottomNavigation = true,
  });
  final bool withBottomNavigation;
  @override
  State<ClientProfileOverviewScreen> createState() =>
      _ClientProfileOverviewState();
}

class _ClientProfileOverviewState extends State<ClientProfileOverviewScreen> {
  Map<String, dynamic> profile = {};
  Map<String, dynamic> local = {};
  bool loading = true;
  final api = ApiService();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final p = await api.profile();
      final prefs = await SharedPreferences.getInstance();
      local = {
        'about': prefs.getString('client_about') ?? '',
        'client_type': prefs.getString('client_type') ?? 'household',
        'industry': prefs.getString('client_industry') ?? '',
        'business_name': prefs.getString('client_business_name') ?? '',
        'business_email': prefs.getString('client_business_email') ?? '',
        'business_phone': prefs.getString('client_business_phone') ?? '',
        'tax_id': prefs.getString('client_tax_id') ?? '',
        'representative': prefs.getString('client_representative') ?? '',
        'website': prefs.getString('client_website') ?? '',
        'location_label': prefs.getString('client_location_label') ?? '',
        'location_category': prefs.getString('client_location_category') ?? '',
        'neighborhood': prefs.getString('client_location_neighborhood') ?? '',
        'access': prefs.getString('client_location_access') ?? '',
        'privacy': prefs.getString('client_privacy') ?? 'initial',
        'allow_offers': prefs.getBool('client_allow_offers') ?? true,
        'email_notifications':
            prefs.getBool('client_email_notifications') ?? true,
        'sms_notifications': prefs.getBool('client_sms_notifications') ?? true,
      };
      if (mounted)
        setState(() {
          profile = p;
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  String _value(String key) => '${profile[key] ?? ''}'.trim();
  String _local(String key) => '${local[key] ?? ''}'.trim();
  Widget _row(String label, String value) => value.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 145,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: clientMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: clientNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
  Widget _section(String title, List<Widget> children) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: clientNavy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    ),
  );
  Widget _verificationCard() {
    final verified = profile['is_verified'] == true;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  verified ? Icons.verified_user : Icons.pending_actions,
                  color: verified ? Colors.green : clientOrange,
                  size: 28,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Identity verification',
                    style: TextStyle(
                      color: clientNavy,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: verified
                        ? const Color(0xFFE8F7ED)
                        : const Color(0xFFFFF0E9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    verified ? 'Verified' : 'Pending',
                    style: TextStyle(
                      color: verified ? Colors.green.shade700 : clientOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              verified
                  ? 'Your identity has been approved by the Boulot Man administration team.'
                  : 'Submit one government ID so the administration team can review your account.',
              style: const TextStyle(color: clientMuted, height: 1.4),
            ),
            const SizedBox(height: 14),
            if (!verified)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientVerificationScreen(),
                    ),
                  ).then((_) => _load()),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Submit verification documents'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: clientOrange,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(46),
                  ),
                ),
              )
            else
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 19),
                  SizedBox(width: 8),
                  Text(
                    'Verified account benefits are unlocked.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _preview(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  url,
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
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await api.clearSession();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
  }

  Future<void> _delete() async {
    final input = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently removes your account. Type DELETE to confirm.',
            ),
            TextField(controller: input),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, input.text.trim() == 'DELETE'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await api.deleteAccount();
        if (mounted)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
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

  @override
  Widget build(BuildContext context) {
    if (loading)
      return Scaffold(
        appBar: AppBar(
          title: const Text('My profile'),
          foregroundColor: clientNavy,
          backgroundColor: Colors.white,
        ),
        backgroundColor: clientBg,
        body: const Center(
          child: CircularProgressIndicator(color: clientOrange),
        ),
        bottomNavigationBar: widget.withBottomNavigation
            ? _bottomNavigation(context)
            : null,
      );
    final avatar = api.resolveImageUrl(profile['avatar_url'] as String?);
    final banner = api.resolveImageUrl(
      (profile['banner_url'] ?? profile['cover_url']) as String?,
    );
    final type =
        {
          'household': 'Individual / Household',
          'business': 'Business Client',
          'ngo': 'Organization / NGO',
          'property_manager': 'Property Manager / Landlord',
        }[_local('client_type')] ??
        'Client';
    return Scaffold(
      appBar: AppBar(
        title: const Text('My profile'),
        foregroundColor: clientNavy,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ClientProfileScreen()),
            ).then((_) => _load()),
            icon: const Icon(Icons.edit_outlined, color: clientOrange),
          ),
        ],
      ),
      backgroundColor: clientBg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              SizedBox(
                width: double.infinity,
                height: 210,
                child: banner.isEmpty
                    ? Container(color: clientNavy)
                    : Image.network(banner, fit: BoxFit.cover),
              ),
              Positioned(
                bottom: -52,
                child: GestureDetector(
                  onTap: avatar.isEmpty ? null : () => _preview(avatar),
                  child: CircleAvatar(
                    radius: 58,
                    backgroundColor: clientBg,
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFFFFE8E0),
                      backgroundImage: avatar.isEmpty
                          ? null
                          : NetworkImage(avatar),
                      child: avatar.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: clientOrange,
                              size: 52,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 66),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                Text(
                  '${_value('first_name')} ${_value('last_name')}'.trim(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: clientNavy,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _value('email'),
                  style: const TextStyle(color: clientMuted),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ClientProfileScreen(),
                    ),
                  ).then((_) => _load()),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: clientOrange,
                    side: const BorderSide(color: clientOrange),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _section('Personal information', [
                  _row('First name', _value('first_name')),
                  _row('Last name', _value('last_name')),
                  _row('Phone', _value('phone')),
                  _row('Country', _value('country')),
                  _row('City', _value('city')),
                  _row('Address', _value('address')),
                  _row('About', _local('about')),
                ]),
                _section('Client & business', [
                  _row('Client type', type),
                  _row('Organization', _local('business_name')),
                  _row('Industry', _local('industry')),
                  _row('Business email', _local('business_email')),
                  _row('Business phone', _local('business_phone')),
                  _row('Registration / tax ID', _local('tax_id')),
                  _row('Representative', _local('representative')),
                  _row('Website', _local('website')),
                ]),
                _section('Saved service location', [
                  _row('Label', _local('location_label')),
                  _row('Type', _local('location_category')),
                  _row('Neighborhood', _local('neighborhood')),
                  _row('Access notes', _local('access')),
                ]),
                _section('Privacy & preferences', [
                  _row(
                    'Public name',
                    _local('privacy') == 'full'
                        ? 'Full name'
                        : 'Last-name initial',
                  ),
                  _row(
                    'Language',
                    _value('language_preference') == 'fr'
                        ? 'Français'
                        : 'English',
                  ),
                  _row('Direct offers', _local('allow_offers')),
                  _row('Email notifications', _local('email_notifications')),
                  _row('SMS notifications', _local('sms_notifications')),
                ]),
                _verificationCard(),
                const SizedBox(height: 4),
                OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Log out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: clientNavy,
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete account'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.withBottomNavigation
          ? _bottomNavigation(context)
          : null,
    );
  }

  Widget _bottomNavigation(BuildContext context) => BottomNavigationBar(
    currentIndex: 3,
    selectedItemColor: clientOrange,
    unselectedItemColor: clientMuted,
    onTap: (index) {
      if (index == 3) return;
      final page = index == 0
          ? const ClientDashboardScreen()
          : index == 1
          ? const ClientTasksScreen()
          : const ClientMessagesScreen();
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => page));
    },
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.dashboard_outlined),
        label: 'Home',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.assignment_outlined),
        label: 'Tasks',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.message_outlined),
        label: 'Messages',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
    ],
  );
}

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});
  @override
  State<ClientProfileScreen> createState() => _ClientProfileState();
}

class _ClientProfileState extends State<ClientProfileScreen> {
  final api = ApiService();
  final first = TextEditingController(),
      last = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      city = TextEditingController(),
      address = TextEditingController(),
      about = TextEditingController();
  final businessName = TextEditingController(),
      businessEmail = TextEditingController(),
      businessPhone = TextEditingController(),
      taxId = TextEditingController(),
      representative = TextEditingController(),
      website = TextEditingController();
  final locationLabel = TextEditingController(),
      neighborhood = TextEditingController(),
      accessNotes = TextEditingController();
  String country = 'Benin',
      language = 'en',
      clientType = 'household',
      industry = 'Hospitality & Services',
      privacy = 'initial',
      locationCategory = 'home';
  bool allowOffers = true,
      emailNotifications = true,
      smsNotifications = true,
      loading = true,
      saving = false,
      uploading = false;
  String? avatar, banner;
  static const countries = [
    'Benin',
    'Nigeria',
    'Rwanda',
    'Kenya',
    'Ghana',
    'South Africa',
    'Ivory Coast',
    'Togo',
    'Cameroon',
    'Senegal',
  ];

  void _previewAvatar() {
    final url = api.resolveImageUrl(avatar);
    if (url.isEmpty) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.network(
                  url,
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
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      first,
      last,
      email,
      phone,
      city,
      address,
      about,
      businessName,
      businessEmail,
      businessPhone,
      taxId,
      representative,
      website,
      locationLabel,
      neighborhood,
      accessNotes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await api.profile();
      final prefs = await SharedPreferences.getInstance();
      first.text = '${p['first_name'] ?? ''}';
      last.text = '${p['last_name'] ?? ''}';
      email.text = '${p['email'] ?? ''}';
      phone.text = '${p['phone'] ?? ''}';
      final signupCountry = prefs.getString('signup_country') ?? '';
      final signupCity = prefs.getString('signup_city') ?? '';
      final apiCountry = '${p['country'] ?? ''}'.trim();
      final apiCity = '${p['city'] ?? p['address'] ?? ''}'.trim();
      final apiHasOnlyDefaultCountry =
          apiCountry == 'Benin' &&
          signupCountry.isNotEmpty &&
          signupCountry != 'Benin';
      country =
          signupCountry.isNotEmpty &&
              (apiCountry.isEmpty || apiHasOnlyDefaultCountry)
          ? signupCountry
          : (apiCountry.isNotEmpty ? apiCountry : 'Benin');
      city.text = apiCity.isNotEmpty ? apiCity : signupCity;
      address.text = '${p['address'] ?? p['city'] ?? ''}';
      language = '${p['language_preference'] ?? 'en'}';
      avatar = api.resolveImageUrl(p['avatar_url'] as String?);
      banner = api.resolveImageUrl(
        (p['banner_url'] ?? p['cover_url']) as String?,
      );
      about.text = prefs.getString('client_about') ?? '';
      clientType = prefs.getString('client_type') ?? 'household';
      industry = prefs.getString('client_industry') ?? industry;
      businessName.text = prefs.getString('client_business_name') ?? '';
      businessEmail.text = prefs.getString('client_business_email') ?? '';
      businessPhone.text = prefs.getString('client_business_phone') ?? '';
      taxId.text = prefs.getString('client_tax_id') ?? '';
      representative.text = prefs.getString('client_representative') ?? '';
      website.text = prefs.getString('client_website') ?? '';
      locationLabel.text = prefs.getString('client_location_label') ?? '';
      neighborhood.text = prefs.getString('client_location_neighborhood') ?? '';
      accessNotes.text = prefs.getString('client_location_access') ?? '';
      locationCategory = prefs.getString('client_location_category') ?? 'home';
      privacy = prefs.getString('client_privacy') ?? 'initial';
      allowOffers = prefs.getBool('client_allow_offers') ?? true;
      emailNotifications = prefs.getBool('client_email_notifications') ?? true;
      smsNotifications = prefs.getBool('client_sms_notifications') ?? true;
    } catch (_) {
      if (mounted) _snack('Unable to load your profile.', error: true);
    }
    if (mounted) setState(() => loading = false);
  }

  void _snack(String message, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: error ? Colors.red.shade700 : clientNavy,
          content: Text(message),
        ),
      );
  Future<void> _save() async {
    final site = website.text.trim().isEmpty
        ? ''
        : (website.text.trim().startsWith(RegExp(r'https?://'))
              ? website.text.trim()
              : 'https://${website.text.trim()}');
    if (site.isNotEmpty &&
        (Uri.tryParse(site)?.hasScheme != true ||
            Uri.tryParse(site)?.host.isEmpty != false)) {
      _snack(
        'Enter a valid website address, for example https://example.com.',
        error: true,
      );
      return;
    }
    if (clientType != 'household') {
      if (businessName.text.trim().isEmpty) {
        _snack('Enter the company or organization name.', error: true);
        return;
      }
      if (businessEmail.text.trim().isNotEmpty &&
          !RegExp(
            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
          ).hasMatch(businessEmail.text.trim())) {
        _snack('Enter a valid business email.', error: true);
        return;
      }
      if (businessPhone.text.trim().isNotEmpty &&
          !validPhoneForCountry(businessPhone.text.trim(), country)) {
        _snack('Enter a valid $country business phone number.', error: true);
        return;
      }
    }
    if (phone.text.trim().isNotEmpty &&
        !validPhoneForCountry(phone.text.trim(), country)) {
      _snack('Enter a valid $country phone number.', error: true);
      return;
    }
    setState(() => saving = true);
    try {
      await api.updateProfile({
        'first_name': first.text.trim(),
        'last_name': last.text.trim(),
        'phone': phone.text.trim(),
        'country': country,
        'city': city.text.trim(),
        'address': address.text.trim().isEmpty
            ? city.text.trim()
            : address.text.trim(),
        'about': about.text.trim(),
        'language_preference': language,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('client_about', about.text.trim());
      await prefs.setString('signup_country', country);
      await prefs.setString('signup_city', city.text.trim());
      await prefs.setString('client_type', clientType);
      await prefs.setString('client_industry', industry);
      await prefs.setString('client_business_name', businessName.text.trim());
      await prefs.setString('client_business_email', businessEmail.text.trim());
      await prefs.setString('client_business_phone', businessPhone.text.trim());
      await prefs.setString('client_tax_id', taxId.text.trim());
      await prefs.setString(
        'client_representative',
        representative.text.trim(),
      );
      await prefs.setString('client_website', site);
      await prefs.setString('client_privacy', privacy);
      await prefs.setBool('client_allow_offers', allowOffers);
      await prefs.setBool('client_email_notifications', emailNotifications);
      await prefs.setBool('client_sms_notifications', smsNotifications);
      await prefs.setString('client_location_label', locationLabel.text.trim());
      await prefs.setString(
        'client_location_neighborhood',
        neighborhood.text.trim(),
      );
      await prefs.setString('client_location_access', accessNotes.text.trim());
      await prefs.setString('client_location_category', locationCategory);
      if (mounted) _snack('Profile saved successfully.');
    } catch (_) {
      if (mounted)
        _snack(
          'We could not save your profile. Please try again.',
          error: true,
        );
    }
    if (mounted) setState(() => saving = false);
  }

  Future<void> _pickAvatar() async => _showMediaActions(false);

  Future<void> _showMediaActions(bool isBanner) async {
    await ProfileMediaActions.show(
      context,
      label: isBanner ? 'cover photo' : 'profile photo',
      hasImage: (isBanner ? banner : avatar)?.isNotEmpty == true,
      onRemove: () => _clearMedia(isBanner),
      onDefault: () => _clearMedia(isBanner),
      onGallery: () => _uploadMedia(isBanner, ImageSource.gallery),
      onCamera: () => _uploadMedia(isBanner, ImageSource.camera),
    );
  }

  Future<void> _clearMedia(bool isBanner) async {
    setState(() => uploading = true);
    try {
      await api.updateProfile({(isBanner ? 'banner_url' : 'avatar_url'): ''});
      if (!mounted) return;
      setState(() => isBanner ? banner = null : avatar = null);
      _snack('${isBanner ? 'Cover' : 'Profile'} photo removed.');
    } catch (_) {
      if (mounted) _snack('We could not update your photo.', error: true);
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _uploadMedia(bool isBanner, ImageSource source) async {
    final file = await ProfileMediaActions.pick(
      context,
      source: source,
      label: isBanner ? 'cover photo' : 'profile photo',
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final validation = ProfileMediaActions.validate(
      file,
      bytes,
      isBanner ? 'Cover photo' : 'Profile photo',
    );
    if (validation != null) {
      if (mounted) _snack(validation, error: true);
      return;
    }
    setState(() => uploading = true);
    try {
      final url = isBanner
          ? await api.uploadBannerBytes(bytes: bytes, filename: file.name)
          : await api.uploadAvatarBytes(bytes: bytes, filename: file.name);
      await api.updateProfile({(isBanner ? 'banner_url' : 'avatar_url'): url});
      if (mounted) {
        setState(
          () => isBanner
              ? banner = api.resolveImageUrl(url)
              : avatar = api.resolveImageUrl(url),
        );
        _snack('${isBanner ? 'Cover' : 'Profile'} photo updated.');
      }
    } catch (_) {
      if (mounted)
        _snack(
          'We could not upload your ${isBanner ? 'cover' : 'profile'} photo.',
          error: true,
        );
    }
    if (mounted) setState(() => uploading = false);
  }

  Future<void> _pickBanner() async => _showMediaActions(true);

  InputDecoration _dec(String label, {IconData? icon}) => InputDecoration(
    labelText: label,
    prefixIcon: icon == null ? null : Icon(icon, color: clientMuted),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: clientOrange, width: 1.5),
    ),
  );
  Widget _section(String title, List<Widget> children) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: clientNavy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children.asMap().entries.expand(
            (entry) => [
              if (entry.key > 0) const SizedBox(height: 12),
              entry.value,
            ],
          ),
        ],
      ),
    ),
  );
  Widget _text(
    TextEditingController c,
    String label, {
    IconData? icon,
    TextInputType? type,
    int maxLines = 1,
    bool enabled = true,
    List<TextInputFormatter>? formatters,
  }) => Padding(
    padding: EdgeInsets.zero,
    child: TextField(
      controller: c,
      enabled: enabled,
      keyboardType: type,
      inputFormatters: formatters,
      maxLines: maxLines,
      decoration: _dec(label, icon: icon),
    ),
  );
  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          label,
          style: const TextStyle(
            color: clientNavy,
            fontWeight: FontWeight.w600,
          ),
        ),
        value: value,
        activeColor: clientOrange,
        onChanged: onChanged,
      );

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: clientOrange)),
      );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client profile'),
        foregroundColor: clientNavy,
        backgroundColor: Colors.white,
      ),
      backgroundColor: clientBg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
        children: [
          _section('Cover image', [
            if (banner != null && banner!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  banner!,
                  width: double.infinity,
                  height: 140,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 140,
                alignment: Alignment.center,
                color: const Color(0xFFE2E8F0),
                child: const Text('No cover image yet'),
              ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: uploading ? null : _pickBanner,
              icon: const Icon(Icons.image_outlined),
              label: Text(uploading ? 'Uploading...' : 'Choose cover image'),
            ),
          ]),
          _section('Profile photo', [
            Center(
              child: GestureDetector(
                onTap: uploading ? null : _pickAvatar,
                onLongPress: avatar == null ? null : _previewAvatar,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFFFE8E0),
                      backgroundImage: avatar == null
                          ? null
                          : NetworkImage(avatar!),
                      child: avatar == null
                          ? const Icon(
                              Icons.person,
                              color: clientOrange,
                              size: 48,
                            )
                          : null,
                    ),
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: clientOrange,
                      child: uploading
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              avatar == null
                                  ? Icons.camera_alt
                                  : Icons.open_in_full,
                              color: Colors.white,
                              size: 17,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text(
                'Tap photo to choose or replace it; long-press to preview full screen',
                style: TextStyle(color: clientMuted),
              ),
            ),
          ]),
          _section('Personal details & contact', [
            _text(first, 'First name', icon: Icons.person_outline),
            _text(last, 'Last name', icon: Icons.person_outline),
            _text(
              email,
              'Email address',
              icon: Icons.email_outlined,
              enabled: false,
            ),
            _text(
              phone,
              'Phone number',
              icon: Icons.phone_outlined,
              type: TextInputType.phone,
              formatters: [phoneInputFormatter(country)],
            ),
            DropdownButtonFormField<String>(
              value: countries.contains(country) ? country : null,
              decoration: _dec('Country', icon: Icons.public),
              items: countries
                  .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                  .toList(),
              onChanged: (x) => setState(() => country = x ?? country),
            ),
            const SizedBox(height: 12),
            _text(city, 'City / Town', icon: Icons.location_city),
            _text(
              address,
              'Default address / neighborhood',
              icon: Icons.location_on_outlined,
            ),
            _text(
              about,
              'About you / note for technicians',
              icon: Icons.notes,
              maxLines: 3,
            ),
          ]),
          _section('Client type & business', [
            DropdownButtonFormField<String>(
              value: clientType,
              decoration: _dec('How you hire'),
              items: const [
                DropdownMenuItem(
                  value: 'household',
                  child: Text('Individual / Household'),
                ),
                DropdownMenuItem(
                  value: 'business',
                  child: Text('Business Client'),
                ),
                DropdownMenuItem(
                  value: 'ngo',
                  child: Text('Organization / NGO'),
                ),
                DropdownMenuItem(
                  value: 'property_manager',
                  child: Text('Property Manager / Landlord'),
                ),
              ],
              onChanged: (x) => setState(() => clientType = x ?? clientType),
            ),
            if (clientType != 'household') ...[
              _text(
                businessName,
                'Company / organization name',
                icon: Icons.business,
              ),
              _text(
                businessEmail,
                'Corporate billing email',
                icon: Icons.alternate_email,
                type: TextInputType.emailAddress,
              ),
              _text(
                businessPhone,
                'Business phone',
                icon: Icons.phone,
                type: TextInputType.phone,
                formatters: [phoneInputFormatter(country)],
              ),
              _text(
                taxId,
                'Business registration / tax ID',
                icon: Icons.receipt_long,
              ),
              _text(
                representative,
                'Authorized representative',
                icon: Icons.person_pin,
              ),
              _text(
                website,
                'Company website',
                icon: Icons.language,
                type: TextInputType.url,
              ),
              DropdownButtonFormField<String>(
                value: industry,
                decoration: _dec('Industry / sector'),
                items:
                    const [
                          'Hospitality & Services',
                          'Real Estate & Facilities',
                          'Retail & Commercial',
                          'Construction & Engineering',
                          'Logistics & Transport',
                          'Healthcare & Education',
                          'NGO & Non-Profit',
                          'Corporate / Tech',
                        ]
                        .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                        .toList(),
                onChanged: (x) => setState(() => industry = x ?? industry),
              ),
            ],
          ]),
          _section('Saved service locations', [
            _text(locationLabel, 'Location label', icon: Icons.bookmark_border),
            DropdownButtonFormField<String>(
              value: locationCategory,
              decoration: _dec('Location type', icon: Icons.category_outlined),
              items: const [
                DropdownMenuItem(value: 'home', child: Text('Home')),
                DropdownMenuItem(value: 'office', child: Text('Office')),
                DropdownMenuItem(
                  value: 'site',
                  child: Text('Construction site'),
                ),
                DropdownMenuItem(
                  value: 'rental',
                  child: Text('Rental property'),
                ),
                DropdownMenuItem(value: 'other', child: Text('Other')),
              ],
              onChanged: (x) =>
                  setState(() => locationCategory = x ?? locationCategory),
            ),
            _text(
              neighborhood,
              'Neighborhood / street details',
              icon: Icons.location_on_outlined,
            ),
            _text(
              accessNotes,
              'Access notes',
              icon: Icons.info_outline,
              maxLines: 2,
            ),
            const Text(
              'Exact service addresses are shared only with the assigned professional after confirmation.',
              style: TextStyle(color: clientMuted, fontSize: 12, height: 1.35),
            ),
          ]),
          _section('Identity & escrow trust', [
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                Icons.admin_panel_settings_outlined,
                color: clientOrange,
              ),
              title: Text(
                'Admin-reviewed verification',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: clientNavy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                'Status shown below.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: clientMuted),
              ),
            ),
            FutureBuilder<Map<String, dynamic>>(
              future: api.profile(),
              builder: (context, snapshot) {
                final verified = snapshot.data?['is_verified'] == true;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    verified ? Icons.verified : Icons.pending_actions,
                    color: verified ? Colors.green : clientOrange,
                  ),
                  title: Text(
                    verified ? 'Verified client' : 'Verification pending',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: clientNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ClientVerificationScreen(),
                      ),
                    ),
                    child: const Text('View status'),
                  ),
                );
              },
            ),
          ]),
          _section('Privacy & preferences', [
            DropdownButtonFormField<String>(
              value: privacy,
              decoration: _dec('Public name format'),
              items: const [
                DropdownMenuItem(
                  value: 'initial',
                  child: Text(
                    'Show last-name initial',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'full',
                  child: Text(
                    'Show full name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (x) => setState(() => privacy = x ?? privacy),
            ),
            DropdownButtonFormField<String>(
              value: language,
              decoration: _dec('Language'),
              items: const [
                DropdownMenuItem(
                  value: 'en',
                  child: Text(
                    'English',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: 'fr',
                  child: Text(
                    'Français',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (x) => setState(() => language = x ?? language),
            ),
            _switch(
              'Allow direct offers',
              allowOffers,
              (x) => setState(() => allowOffers = x),
            ),
            _switch(
              'Email notifications',
              emailNotifications,
              (x) => setState(() => emailNotifications = x),
            ),
            _switch(
              'SMS notifications',
              smsNotifications,
              (x) => setState(() => smsNotifications = x),
            ),
          ]),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton.icon(
          onPressed: saving ? null : _save,
          icon: saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(saving ? 'Saving...' : 'Save profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: clientOrange,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ),
    );
  }
}

class ClientSavedScreen extends StatefulWidget {
  const ClientSavedScreen({super.key});
  @override
  State<ClientSavedScreen> createState() => _SavedState();
}

class _SavedState extends State<ClientSavedScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = api.savedProfessionals();
  Future<void> remove(dynamic id) async {
    try {
      await api.unsaveProfessional(id);
      if (mounted) {
        setState(() => future = api.savedProfessionals());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Professional removed from saved list.'),
          ),
        );
      }
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not update your saved professionals.'),
          ),
        );
    }
  }

  void openProfile(dynamic person) {
    final id = person['id'];
    if (id != null)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientPublicProfessionalScreen(userId: id),
        ),
      );
  }

  void message(dynamic person) {
    final id = person['id'];
    if (id != null)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ClientMessagesScreen(
            participantId: id,
            participantName: '${person['name'] ?? ''}',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Saved professionals'),
      foregroundColor: clientNavy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: clientBg,
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(
            child: CircularProgressIndicator(color: clientOrange),
          );
        final list = snapshot.data ?? const [];
        if (list.isEmpty)
          return const Center(
            child: Text(
              'No saved professionals yet.',
              style: TextStyle(color: clientMuted),
            ),
          );
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: list.length,
          itemBuilder: (_, i) {
            final x = list[i] is Map ? list[i] as Map : <String, dynamic>{};
            final person = x['professional'] is Map
                ? Map<String, dynamic>.from(x['professional'] as Map)
                : Map<String, dynamic>.from(x);
            final name =
                '${person['name'] ?? '${person['first_name'] ?? ''} ${person['last_name'] ?? ''}'}'
                    .trim();
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () => openProfile(person),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFFFE8E0),
                        backgroundImage:
                            api
                                .resolveImageUrl(
                                  person['avatar_url'] as String?,
                                )
                                .isEmpty
                            ? null
                            : NetworkImage(
                                api.resolveImageUrl(
                                  person['avatar_url'] as String?,
                                ),
                              ),
                        child:
                            api
                                .resolveImageUrl(
                                  person['avatar_url'] as String?,
                                )
                                .isEmpty
                            ? const Icon(
                                Icons.person_outline,
                                color: clientOrange,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isEmpty ? 'Professional' : name,
                              style: const TextStyle(
                                color: clientNavy,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${person['role'] ?? 'Professional'} • ${person['city'] ?? ''}',
                              style: const TextStyle(color: clientMuted),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => openProfile(person),
                                  icon: const Icon(
                                    Icons.person_outline,
                                    size: 16,
                                  ),
                                  label: const Text('View profile'),
                                ),
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: () => message(person),
                                  icon: const Icon(
                                    Icons.message_outlined,
                                    size: 16,
                                  ),
                                  label: const Text('Message'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: x['id'] == null
                            ? null
                            : () => remove(person['id']),
                        icon: const Icon(Icons.bookmark, color: clientOrange),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ),
  );
}

class ClientPublicProfessionalScreen extends StatefulWidget {
  const ClientPublicProfessionalScreen({super.key, required this.userId});
  final dynamic userId;
  @override
  State<ClientPublicProfessionalScreen> createState() =>
      _PublicProfessionalState();
}

class _PublicProfessionalState extends State<ClientPublicProfessionalScreen> {
  final api = ApiService();
  late Future<dynamic> future = ApiService().publicUserProfile(widget.userId);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Professional profile'),
      foregroundColor: clientNavy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: clientBg,
    body: FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(
            child: CircularProgressIndicator(color: clientOrange),
          );
        final p = snapshot.data is Map
            ? snapshot.data as Map
            : <String, dynamic>{};
        final name =
            '${p['name'] ?? '${p['first_name'] ?? ''} ${p['last_name'] ?? ''}'}'
                .trim();
        final avatar = api.resolveImageUrl(p['avatar_url'] as String?);
        final banner = api.resolveImageUrl(
          (p['banner_url'] ?? p['cover_url']) as String?,
        );
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (banner.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 156,
                child: Image.network(banner, fit: BoxFit.cover),
              ),
            if (banner.isNotEmpty) const SizedBox(height: 14),
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFFFFE8E0),
                      backgroundImage: avatar.isEmpty
                          ? null
                          : NetworkImage(avatar),
                      child: avatar.isEmpty
                          ? const Icon(
                              Icons.person,
                              color: clientOrange,
                              size: 48,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name.isEmpty ? 'Professional' : name,
                      style: const TextStyle(
                        color: clientNavy,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${p['role'] ?? 'Professional'} • ${p['city'] ?? ''}',
                      style: const TextStyle(color: clientMuted),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientMessagesScreen(
                            participantId: widget.userId,
                            participantName: name,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.message_outlined),
                      label: const Text('Start conversation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: clientOrange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _publicSection('About', p['bio'] ?? p['about']),
            _publicSection(
              'Services',
              p['services'] ?? p['technician_services'],
            ),
            _publicSection('Portfolio', p['portfolio']),
          ],
        );
      },
    ),
  );
  Widget _publicSection(String title, dynamic value) {
    if (value == null || '$value'.trim().isEmpty)
      return const SizedBox.shrink();
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: clientNavy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$value',
              style: const TextStyle(color: clientMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientSettingsScreen extends StatefulWidget {
  const ClientSettingsScreen({super.key});
  @override
  State<ClientSettingsScreen> createState() => _ClientSettingsState();
}

class _ClientSettingsState extends State<ClientSettingsScreen> {
  final api = ApiService();
  final current = TextEditingController(),
      next = TextEditingController(),
      confirm = TextEditingController();
  String language = 'en';
  bool saving = false;
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  void _notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  Future<void> _password() async {
    if (next.text.length < 8)
      return _notice('New password must be at least 8 characters.');
    if (next.text != confirm.text)
      return _notice('New passwords do not match.');
    setState(() => saving = true);
    try {
      await api.changePassword({
        'current_password': current.text,
        'new_password': next.text,
      });
      current.clear();
      next.clear();
      confirm.clear();
      _notice('Password changed successfully.');
    } catch (e) {
      _notice(e.toString());
    }
    if (mounted) setState(() => saving = false);
  }

  Future<void> _logout() async {
    await api.clearSession();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
  }

  Future<void> _delete() async {
    final input = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This permanently removes your account. Type DELETE to confirm.',
            ),
            TextField(controller: input),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(d, input.text.trim() == 'DELETE'),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    input.dispose();
    if (ok != true) return;
    try {
      await api.deleteAccount();
      if (mounted)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
    } catch (e) {
      _notice(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Settings'),
      foregroundColor: clientNavy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: clientBg,
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change password',
                  style: TextStyle(
                    color: clientNavy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: current,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: next,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password (minimum 8 characters)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: confirm,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm new password',
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving ? null : _password,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: clientOrange,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(saving ? 'Changing...' : 'Change password'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Card(
          elevation: 0,
          child: ListTile(
            title: const Text(
              'Language',
              style: TextStyle(color: clientNavy, fontWeight: FontWeight.w700),
            ),
            trailing: DropdownButton<String>(
              value: language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'fr', child: Text('Français')),
              ],
              onChanged: (v) async {
                setState(() => language = v ?? 'en');
                try {
                  await api.updateProfile({'language_preference': language});
                } catch (_) {}
              },
            ),
          ),
        ),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.logout, color: clientOrange),
            title: const Text('Log out'),
            onTap: _logout,
          ),
        ),
        Card(
          elevation: 0,
          child: ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text(
              'Delete account',
              style: TextStyle(color: Colors.red),
            ),
            subtitle: const Text(
              'Type DELETE to permanently remove your account.',
            ),
            onTap: _delete,
          ),
        ),
      ],
    ),
  );
}

class ClientSupportScreen extends StatefulWidget {
  const ClientSupportScreen({super.key});
  @override
  State<ClientSupportScreen> createState() => _SupportState();
}

class _SupportState extends State<ClientSupportScreen> {
  final api = ApiService();
  late Future<List<dynamic>> future = ApiService().supportTickets();
  dynamic active;
  final reply = TextEditingController();
  bool sending = false;
  @override
  void dispose() {
    reply.dispose();
    super.dispose();
  }

  void _notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  Future<void> _create() async {
    final subject = TextEditingController(), body = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('New support ticket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subject,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            TextField(
              controller: body,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe your issue',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(
              d,
              subject.text.trim().isNotEmpty && body.text.trim().isNotEmpty,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (ok != true) {
      subject.dispose();
      body.dispose();
      return;
    }
    try {
      final created = await api.createSupportTicket({
        'subject': subject.text.trim(),
        'body': body.text.trim(),
      });
      if (mounted) {
        setState(() {
          active = created;
          future = api.supportTickets();
        });
        _notice('Support ticket submitted.');
      }
    } catch (e) {
      _notice(e.toString());
    }
    subject.dispose();
    body.dispose();
  }

  Future<void> _send() async {
    if (active == null || reply.text.trim().isEmpty || sending) return;
    setState(() => sending = true);
    try {
      await api.replySupportTicket(
        active['db_id'] ?? active['id'],
        reply.text.trim(),
      );
      reply.clear();
      setState(() => future = api.supportTickets());
      _notice('Reply sent.');
    } catch (e) {
      _notice(e.toString());
    }
    if (mounted) setState(() => sending = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Support'),
      foregroundColor: clientNavy,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _create,
          icon: const Icon(Icons.add, color: clientOrange),
        ),
      ],
    ),
    backgroundColor: clientBg,
    body: FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Center(
            child: CircularProgressIndicator(color: clientOrange),
          );
        final tickets = snapshot.data ?? const [];
        active ??= tickets.isNotEmpty ? tickets.first : null;
        if (active == null)
          return Center(
            child: ElevatedButton.icon(
              onPressed: _create,
              icon: const Icon(Icons.add),
              label: const Text('Create support ticket'),
            ),
          );
        final messages = active['messages'] is List
            ? active['messages'] as List
            : const [];
        return Column(
          children: [
            SizedBox(
              height: 86,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: tickets.length,
                itemBuilder: (_, i) {
                  final t = tickets[i] as Map;
                  return Padding(
                    padding: const EdgeInsets.all(8),
                    child: ChoiceChip(
                      label: Text(t['subject'].toString()),
                      selected: active['db_id'] == t['db_id'],
                      onSelected: (_) => setState(() => active = t),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    active['subject'].toString(),
                    style: const TextStyle(
                      color: clientNavy,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Status: ' + active['status'].toString(),
                    style: const TextStyle(color: clientMuted),
                  ),
                  const Divider(),
                  ...messages.map(
                    (m) => Card(
                      elevation: 0,
                      child: ListTile(
                        title: Text(m['sender'].toString()),
                        subtitle: Text(m['body'].toString()),
                        trailing: Text(
                          m['time'].toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: reply,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Reply to Support',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: const EdgeInsets.all(12),
                    onPressed: sending ? null : _send,
                    icon: const Icon(Icons.send, color: clientOrange),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );
}

class ClientPaymentsScreen extends ClientWalletScreen {
  const ClientPaymentsScreen({super.key});
}

class ClientExploreScreen extends StatelessWidget {
  const ClientExploreScreen({super.key});
  @override
  Widget build(BuildContext context) => const BrowseProfessionalsScreen();
}

class ClientVerificationScreen extends StatefulWidget {
  const ClientVerificationScreen({super.key});
  @override
  State<ClientVerificationScreen> createState() => _ClientVerificationState();
}

class _ClientVerificationState extends State<ClientVerificationScreen> {
  final api = ApiService();
  // The website does not expose a client document-upload contract. Client
  // verification is an account/admin status, so never send client data to the
  // technician-document endpoint.
  static const clientDocumentSubmissionEnabled = false;
  final idNumber = TextEditingController();
  String idType = 'national_id';
  String? filename;
  List<int>? bytes;
  bool loading = true, submitting = false, submitted = false, verified = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    idNumber.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final p = await api.profile();
      if (mounted)
        setState(() {
          verified = p['is_verified'] == true;
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _pick() async {
    _notice('Client identity documents are reviewed by the administrator.');
  }

  void _notice(String message, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: error ? Colors.red.shade700 : clientNavy,
          content: Text(message),
        ),
      );
  Future<void> _submit() async {
    _notice('Client identity verification is managed by the administrator.');
  }

  @override
  Widget build(BuildContext context) {
    if (loading)
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: clientOrange)),
      );
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identity verification'),
        foregroundColor: clientNavy,
        backgroundColor: Colors.white,
      ),
      backgroundColor: clientBg,
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    verified ? Icons.verified_user : Icons.pending_actions,
                    color: verified ? Colors.green : clientOrange,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    verified ? 'Verified client' : 'Verification pending',
                    style: const TextStyle(
                      color: clientNavy,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    verified
                        ? 'Your identity has been approved by an administrator.'
                        : 'Your account is awaiting administrator verification. The status will update here after review.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: clientMuted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
          if (clientDocumentSubmissionEnabled && !verified && !submitted) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: idType,
              decoration: const InputDecoration(
                labelText: 'Identification document type',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'national_id',
                  child: Text('National ID Card (CNI / CIP)'),
                ),
                DropdownMenuItem(
                  value: 'passport',
                  child: Text('International Passport'),
                ),
                DropdownMenuItem(
                  value: 'drivers_license',
                  child: Text("Driver's License (Permis de Conduire)"),
                ),
                DropdownMenuItem(
                  value: 'residence_permit',
                  child: Text('Residence Permit / Carte de Séjour'),
                ),
              ],
              onChanged: (x) => setState(() => idType = x ?? idType),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: idNumber,
              decoration: const InputDecoration(
                labelText: 'Document / ID number',
                hintText: 'Enter letters and numbers as printed',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.upload_file),
              label: Text(filename == null ? 'Attach ID document' : filename!),
              style: OutlinedButton.styleFrom(
                foregroundColor: clientOrange,
                side: const BorderSide(color: clientOrange),
                minimumSize: const Size.fromHeight(50),
              ),
            ),
            if (bytes != null && filename != null) ...[
              const SizedBox(height: 12),
              _documentPreview(bytes!, filename!),
            ],
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: submitting ? null : _submit,
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.shield_outlined),
              label: Text(
                submitting ? 'Submitting...' : 'Submit for verification',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: clientOrange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _documentPreview(List<int> data, String name) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              Uint8List.fromList(data),
              height: 220,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 120,
                child: Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: clientOrange,
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(
              color: clientNavy,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ClientListScreen extends StatelessWidget {
  const _ClientListScreen({
    required this.title,
    required this.icon,
    required this.empty,
    required this.request,
    required this.line,
  });
  final String title, empty;
  final IconData icon;
  final Future<dynamic> Function() request;
  final String Function(Map) line;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        foregroundColor: clientNavy,
        backgroundColor: Colors.white,
      ),
      backgroundColor: clientBg,
      body: FutureBuilder<dynamic>(
        future: request(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(
              child: CircularProgressIndicator(color: clientOrange),
            );
          final list = clientItems(snapshot.data);
          if (list.isEmpty)
            return Center(
              child: Text(empty, style: const TextStyle(color: clientMuted)),
            );
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: list.length,
            itemBuilder: (_, i) {
              final x = list[i] is Map ? list[i] as Map : <String, dynamic>{};
              return Card(
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xFFFFE8E0),
                    child: Icon(icon, color: clientOrange),
                  ),
                  title: Text(
                    '${x['title'] ?? 'Project'}',
                    style: const TextStyle(
                      color: clientNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    line(x),
                    style: const TextStyle(color: clientMuted),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
