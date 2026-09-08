import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/api_service.dart';
import 'technician_dashboard_screen.dart';
import 'company_dashboard_screen.dart';
import 'client_dashboard_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  final _api = ApiService();
  bool _obscure = true, _loading = false;

  Future<void> _googleLogin() async {
    setState(() => _loading = true);
    try {
      final google = GoogleSignIn(
        serverClientId:
            '1090108678391-00u5aomsoh2gu7rqk2vnfldt9cs4fovq.apps.googleusercontent.com',
        clientId:
            '1090108678391-ehsc9ee5k8r9tskdv15ammmmdsic3rnc.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      );
      await google.signOut();
      final account = await google.signIn();
      if (account == null) return;
      final auth = await account.authentication;
      final token = auth.accessToken;
      if (token == null)
        throw const ApiException('Google did not return an access token.', 401);
      final data = await _api.googleLogin(token: token);
      if (mounted) _handleSuccessfulLogin(data);
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException ? e.message : 'Google sign-in failed.',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_identifier.text.trim().isEmpty || _password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your email or username and password.'),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final data = await _api.login(_identifier.text, _password.text);
      if (mounted) _handleSuccessfulLogin(data);
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = TextEditingController();
    final code = TextEditingController();
    final newPassword = TextEditingController();
    try {
      final requested = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reset password'),
          content: TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Send code'),
            ),
          ],
        ),
      );
      if (requested != true || email.text.trim().isEmpty) return;

      setState(() => _loading = true);
      final reset = await _api.requestPasswordReset(email.text);
      final challengeId = reset['challenge_id'] is int
          ? reset['challenge_id'] as int
          : null;
      if (!mounted) return;
      setState(() => _loading = false);

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Enter reset code'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Check your email for the six-digit code.'),
              const SizedBox(height: 12),
              TextField(
                controller: code,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPassword,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset password'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      setState(() => _loading = true);
      await _api.confirmPasswordReset(
        email: email.text,
        code: code.text,
        newPassword: newPassword.text,
        challengeId: challengeId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully. You can now sign in.'),
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      email.dispose();
      code.dispose();
      newPassword.dispose();
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSignedInMessage(Map<String, dynamic> data) {
    final role = (data['role'] ?? 'CLIENT').toString().toLowerCase();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Signed in as $role.')));
  }

  void _handleSuccessfulLogin(Map<String, dynamic> data) {
    final role = (data['role'] ?? 'CLIENT').toString().toUpperCase();
    if (role == 'TECHNICIAN') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const TechnicianDashboardScreen()),
        (_) => false,
      );
      return;
    }
    if (role == 'CLIENT') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ClientDashboardScreen()),
        (_) => false,
      );
      return;
    }
    if (role == 'COMPANY') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CompanyDashboardScreen()),
        (_) => false,
      );
      return;
    }
    _showSignedInMessage(data);
  }

  InputDecoration _input(String hint, IconData icon, {Widget? suffix}) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8)),
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
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFEFEFF),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        children: [
          const SizedBox(height: 16),
          Center(
            child: Image.asset(
              'assets/images/boulotman-logo.png',
              width: 140,
              height: 140,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome Back',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Color(0xFF001F3F),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sign in to your Boulot Man account to continue',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),
          const Text(
            'Email or Username',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF001F3F),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _identifier,
            decoration: _input(
              'Enter your email or username',
              Icons.email_outlined,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Password',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF001F3F),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _password,
            obscureText: _obscure,
            onSubmitted: (_) => _login(),
            decoration: _input(
              '••••••••',
              Icons.lock_outline,
              suffix: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _forgotPassword,
              child: const Text(
                'Forgot password?',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF001F3F),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4500),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _loading ? 'Signing in...' : 'Login',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _loading ? null : _googleLogin,
            icon: Image.asset(
              'assets/images/google_logo.png',
              width: 20,
              height: 20,
            ),
            label: const Text('Continue with Google'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF001F3F),
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: Color(0xFFD7DEE8)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account?",
                style: TextStyle(color: Color(0xFF64748B)),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF4500),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
