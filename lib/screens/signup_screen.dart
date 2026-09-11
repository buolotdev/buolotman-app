import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';

const supportedCountries = [
  'Nigeria',
  'Rwanda',
  'Kenya',
  'Ghana',
  'South Africa',
  'Ivory Coast',
  'Cameroon',
];

const countryFlags = <String, String>{
  'Nigeria': '🇳🇬',
  'Rwanda': '🇷🇼',
  'Kenya': '🇰🇪',
  'Ghana': '🇬🇭',
  'South Africa': '🇿🇦',
  'Ivory Coast': '🇨🇮',
  'Cameroon': '🇨🇲',
};

const countryDialCodes = <String, String>{
  'Nigeria': '+234',
  'Rwanda': '+250',
  'Kenya': '+254',
  'Ghana': '+233',
  'South Africa': '+27',
  'Ivory Coast': '+225',
  'Cameroon': '+237',
};

const countryNationalLengths = <String, int>{
  'Nigeria': 10,
  'Rwanda': 9,
  'Kenya': 9,
  'Ghana': 9,
  'South Africa': 9,
  'Ivory Coast': 10,
  'Cameroon': 9,
};

const countryPhoneGroups = <String, List<int>>{
  'Nigeria': [3, 3, 4],
  'Rwanda': [3, 3, 3],
  'Kenya': [3, 3, 3],
  'Ghana': [3, 3, 3],
  'South Africa': [2, 3, 4],
  'Ivory Coast': [2, 2, 2, 2, 2],
  'Cameroon': [3, 2, 2, 2],
};

class _PhoneFormatter extends TextInputFormatter {
  _PhoneFormatter(this.groups);
  final List<int> groups;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.substring(
      0,
      digits.length.clamp(0, groups.fold(0, (sum, size) => sum + size)),
    );
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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _first = TextEditingController(),
      _last = TextEditingController(),
      _company = TextEditingController(),
      _email = TextEditingController(),
      _confirmEmail = TextEditingController(),
      _phone = TextEditingController(),
      _city = TextEditingController(),
      _region = TextEditingController(),
      _password = TextEditingController(),
      _confirmPassword = TextEditingController();
  final _api = ApiService();
  String _role = '', _country = supportedCountries[0];
  bool _terms = false,
      _hidePassword = true,
      _hideConfirm = true,
      _loading = false;

  Future<void> _googleSignup() async {
    if (_role.isEmpty) {
      _error('Please select Client, Technician, or Company first.');
      return;
    }
    if (!_terms) {
      _error('Please accept the Terms of Service and Privacy Policy.');
      return;
    }
    setState(() => _loading = true);
    try {
      final google = GoogleSignIn(
        serverClientId:
            '1090108678391-00u5aomsoh2gu7rqk2vnfldt9cs4fovq.apps.googleusercontent.com',
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? '1090108678391-nb89l4orlsf8kpvj52gunjs2c437t7ia.apps.googleusercontent.com'
            : null,
        scopes: ['email', 'profile'],
      );
      await google.signOut();
      final account = await google.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final token = auth.accessToken;
      if (token == null)
        throw const ApiException('Google did not return an access token.', 401);
      await _api.googleLogin(
        token: token,
        role: _role.toUpperCase(),
        signup: true,
      );
      final location = await _api.updateProfile({
        'country': _country,
        'city': _city.text.trim(),
        'address':
            '${_city.text.trim()}${_region.text.trim().isEmpty ? '' : ', ${_region.text.trim()}'}',
      });
      _verifySavedLocation(location, googleSignup: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('signup_country', _country);
      await prefs.setString('signup_city', _city.text.trim());
      if (mounted) {
        _error('Account created. It is pending admin verification.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        _error(e is ApiException ? e.message : 'Google sign-up failed.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _first,
      _last,
      _company,
      _email,
      _confirmEmail,
      _phone,
      _city,
      _region,
      _password,
      _confirmPassword,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  InputDecoration _dec(
    String label,
    IconData? icon, {
    Widget? suffix,
    String? prefixText,
  }) => InputDecoration(
    labelText: label,
    prefixIcon: icon == null
        ? null
        : Icon(icon, color: const Color(0xFF94A3B8)),
    prefixText: prefixText,
    prefixStyle: const TextStyle(
      color: Color(0xFF001F3F),
      fontWeight: FontWeight.w600,
    ),
    suffixIcon: suffix,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFFF5500), width: 1.5),
    ),
  );

  String? _normalisePhone() {
    final code = countryDialCodes[_country]!;
    final digits = _phone.text.replaceAll(RegExp(r'[\s\-().]'), '');
    var international = digits;
    if (international.startsWith('00')) {
      international = '+${international.substring(2)}';
    } else if (international.startsWith('0')) {
      international = '$code${international.substring(1)}';
    } else if (international.startsWith(code.substring(1))) {
      international = '+$international';
    }
    final expected = countryNationalLengths[_country]!;
    if (international.length == expected) {
      international = '${countryDialCodes[_country]}$international';
    }
    final pattern = RegExp('^\\${code}\\d{$expected}\$');
    return pattern.hasMatch(international) ? international : null;
  }

  Future<void> _submit() async {
    if (_role.isEmpty) {
      _error('Please select an account type first.');
      return;
    }
    final phone = _normalisePhone();
    if (phone == null) {
      _error(
        'Enter a valid ${countryDialCodes[_country]} phone number for $_country.',
      );
      return;
    }
    if (_email.text.trim().toLowerCase() !=
        _confirmEmail.text.trim().toLowerCase()) {
      _error('Email addresses do not match.');
      return;
    }
    if (_password.text.length < 8 || _password.text != _confirmPassword.text) {
      _error(
        _password.text.length < 8
            ? 'Password must be at least 8 characters.'
            : 'Passwords do not match.',
      );
      return;
    }
    if (!_terms) {
      _error('Please accept the Terms of Service and Privacy Policy.');
      return;
    }
    if (_role == 'company' && _company.text.trim().isEmpty) {
      _error('Please enter your company name.');
      return;
    }
    if (_city.text.trim().isEmpty) {
      _error('Please enter your city or town.');
      return;
    }
    if (_role != 'company' &&
        (_first.text.trim().isEmpty || _last.text.trim().isEmpty)) {
      _error('Please enter your first and last name.');
      return;
    }
    setState(() => _loading = true);
    try {
      final data = <String, dynamic>{
        'email': _email.text.trim().toLowerCase(),
        'password': _password.text,
        'phone': phone,
      };
      if (_role == 'company') {
        data['company_name'] = _company.text.trim();
      } else {
        data['first_name'] = _first.text.trim();
        data['last_name'] = _last.text.trim();
      }
      if (_role == 'technician') {
        data['country'] = _country;
        data['address'] =
            '${_city.text.trim()}${_region.text.trim().isEmpty ? '' : ', ${_region.text.trim()}'}';
      }
      await _api.register(role: _role, data: data);
      final login = await _api.login(_email.text, _password.text);
      // The registration serializers differ by role. Persist the common
      // location fields after authentication so client and company accounts
      // receive the same profile data as technicians.
      final location = await _api.updateProfile({
        'country': _country,
        'city': _city.text.trim(),
        'address':
            '${_city.text.trim()}${_region.text.trim().isEmpty ? '' : ', ${_region.text.trim()}'}',
      });
      _verifySavedLocation(location);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('signup_country', _country);
      await prefs.setString('signup_city', _city.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Account created. ${(login['role'] ?? _role).toString()} account is pending admin verification.',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      _error(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _verifySavedLocation(
    Map<String, dynamic> profile, {
    bool googleSignup = false,
  }) {
    final savedCountry = profile['country']?.toString() ?? '';
    final savedCity = (profile['city'] ?? profile['address'])?.toString() ?? '';
    if (savedCountry != _country || !savedCity.contains(_city.text.trim())) {
      throw ApiException(
        googleSignup
            ? 'Google account created, but its location could not be saved. Update it from Profile.'
            : 'Account created, but its location could not be saved. Update it from Profile.',
        500,
      );
    }
  }

  void _error(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  Widget _roleCard(String value, String label, IconData icon) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _role = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: _role == value ? const Color(0xFFFFE8DF) : Colors.white,
          border: Border.all(
            color: _role == value
                ? const Color(0xFFFF4500)
                : const Color(0xFFD7DEE8),
            width: 1.3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: _role == value
                  ? const Color(0xFFFF4500)
                  : const Color(0xFF001F3F),
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _role == value
                    ? const Color(0xFFFF4500)
                    : const Color(0xFF001F3F),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  TextSpan _linkSpan(String label, String url) => TextSpan(
    text: label,
    style: const TextStyle(
      color: Color(0xFFFF4500),
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    ),
    recognizer: TapGestureRecognizer()
      ..onTap = () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
  );

  Widget _termsConsent() => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Checkbox(
        value: _terms,
        onChanged: (value) => setState(() => _terms = value ?? false),
        activeColor: const Color(0xFFFF4500),
        visualDensity: VisualDensity.compact,
      ),
      Expanded(
        child: RichText(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          text: TextSpan(
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            children: [
              const TextSpan(text: 'I agree to the '),
              _linkSpan('Terms of Service', 'https://boulotman.com/terms'),
              const TextSpan(text: ' and '),
              _linkSpan('Privacy Policy', 'https://boulotman.com/privacy'),
              const TextSpan(text: '.'),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _countrySelector() => GestureDetector(
    onTap: () => showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select your country',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF001F3F),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: supportedCountries
                      .map(
                        (country) => ListTile(
                          dense: true,
                          leading: Text(
                            countryFlags[country] ?? '🌍',
                            style: const TextStyle(fontSize: 25),
                          ),
                          title: Text(country),
                          trailing: _country == country
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFFFF4500),
                                )
                              : null,
                          onTap: () {
                            setState(() => _country = country);
                            Navigator.pop(sheetContext);
                          },
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    ),
    child: InputDecorator(
      decoration: _dec(
        'Country',
        null,
        suffix: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF64748B)),
      ),
      child: Row(
        children: [
          Text(
            countryFlags[_country] ?? '🌍',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 10),
          Text(
            _country,
            style: const TextStyle(fontSize: 16, color: Color(0xFF001F3F)),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFEFEFF),
    appBar: AppBar(
      title: const Text('Create your account'),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: const Color(0xFF001F3F),
    ),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Join Boulot Man',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF001F3F),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Choose an account type and get started.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _roleCard('client', 'Client', Icons.person_outline),
            _roleCard('technician', 'Technician', Icons.handyman_outlined),
            _roleCard('company', 'Company', Icons.business_center_outlined),
          ],
        ),
        if (_role.isEmpty) ...[
          const SizedBox(height: 10),
          const Text(
            'Select an account type to continue',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
          ),
        ],
        const SizedBox(height: 20),
        if (_role == 'company')
          TextField(
            controller: _company,
            decoration: _dec('Company name', Icons.business_outlined),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _first,
                  decoration: _dec('First name', Icons.person_outline),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _last,
                  decoration: _dec('Last name', Icons.person_outline),
                ),
              ),
            ],
          ),
        const SizedBox(height: 16),
        _countrySelector(),
        const SizedBox(height: 16),
        TextField(
          controller: _city,
          decoration: _dec('City / Town', Icons.location_city),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _region,
          decoration: _dec('Region / State', Icons.map_outlined),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: _dec('Email', Icons.email_outlined),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmEmail,
          keyboardType: TextInputType.emailAddress,
          decoration: _dec('Confirm email', Icons.mark_email_read_outlined),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [_PhoneFormatter(countryPhoneGroups[_country]!)],
          decoration: _dec(
            'Phone number (${countryDialCodes[_country]})',
            Icons.phone_outlined,
            prefixText: '${countryDialCodes[_country]} ',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _password,
          obscureText: _hidePassword,
          decoration: _dec(
            'Password (minimum 8 characters)',
            Icons.lock_outline,
            suffix: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(
                _hidePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmPassword,
          obscureText: _hideConfirm,
          decoration: _dec(
            'Confirm password',
            Icons.lock_outline,
            suffix: IconButton(
              onPressed: () => setState(() => _hideConfirm = !_hideConfirm),
              icon: Icon(
                _hideConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _termsConsent(),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: _loading ? null : _googleSignup,
          icon: Image.asset(
            'assets/images/google_logo.png',
            width: 20,
            height: 20,
          ),
          label: Text(
            _role.isEmpty
                ? 'Continue with Google'
                : 'Continue with Google as ${_role[0].toUpperCase()}${_role.substring(1)}',
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF001F3F),
            minimumSize: const Size.fromHeight(52),
            side: const BorderSide(color: Color(0xFFD7DEE8)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4500),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(_loading ? 'Creating account...' : 'Create Account'),
          ),
        ),
      ],
    ),
  );
}
