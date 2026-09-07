import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'login_screen.dart';
import 'technician_navigation.dart';
import 'technician_wallet_screen.dart';

class TechnicianSettingsScreen extends StatefulWidget {
  const TechnicianSettingsScreen({super.key});
  @override State<TechnicianSettingsScreen> createState() => _TechnicianSettingsState();
}

class _TechnicianSettingsState extends State<TechnicianSettingsScreen> {
  static const navy = Color(0xFF001F3F), orange = Color(0xFFFF4500), muted = Color(0xFF64748B);
  final api = ApiService();
  final first = TextEditingController(), last = TextEditingController(), phone = TextEditingController();
  final profession = TextEditingController(), currentPassword = TextEditingController(), newPassword = TextEditingController(), confirmPassword = TextEditingController();
  String email = '', responseTime = 'Within 24 hours', availability = 'available';
  bool availableForJobs = true, loading = true, saving = false, changingPassword = false;
  // These controls exist on the website, but the current API has no fields for them.
  bool visibleInSearch = true, showPhone = false, showEmail = false, acceptUrgent = false, emailNotifications = true, smsNotifications = false, inAppNotifications = true, twoFactor = false;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { for (final c in [first,last,phone,profession,currentPassword,newPassword,confirmPassword]) c.dispose(); super.dispose(); }

  Map<String, dynamic> _profile(dynamic value) => value is Map<String, dynamic> ? value : <String, dynamic>{};
  bool _bool(dynamic value) => value == true || value == 1 || '$value'.toLowerCase() == 'true';
  Future<void> _load() async {
    try {
      final u = _profile(await api.profile());
      final p = u['technician_profile'] is Map ? Map<String, dynamic>.from(u['technician_profile']) : u;
      first.text = '${u['first_name'] ?? ''}'; last.text = '${u['last_name'] ?? ''}'; phone.text = '${u['phone'] ?? ''}'; email = '${u['email'] ?? ''}';
      profession.text = '${u['primary_occupation'] ?? p['primary_occupation'] ?? u['headline'] ?? p['headline'] ?? ''}';
      responseTime = '${u['response_time'] ?? p['response_time'] ?? responseTime}';
      availability = '${u['availability_status'] ?? p['availability_status'] ?? u['availability'] ?? 'available'}';
      availableForJobs = _bool(u['available_now'] ?? p['available_now']) || availability == 'available';
      if (!mounted) return; setState(() => loading = false);
    } catch (_) { if (mounted) setState(() => loading = false); }
  }
  Future<void> _save() async {
    if (first.text.trim().isEmpty || last.text.trim().isEmpty) return _notice('Enter both first and last name.');
    setState(() => saving = true);
    try {
      await api.updateProfile({
        'first_name': first.text.trim(), 'last_name': last.text.trim(), 'phone': phone.text.trim(),
        'primary_occupation': profession.text.trim(), 'response_time': responseTime,
        'availability_status': availableForJobs ? availability : 'offline', 'available_now': availableForJobs,
      });
      _notice('Settings saved successfully.');
    } catch (e) { _notice('We could not save settings. Please check your details.'); }
    finally { if (mounted) setState(() => saving = false); }
  }
  Future<void> _changePassword() async {
    if (currentPassword.text.isEmpty || newPassword.text.length < 8 || newPassword.text != confirmPassword.text) return _notice('Enter your current password, then a matching new password of at least 8 characters.');
    setState(() => changingPassword = true);
    try { await api.changePassword({'current_password': currentPassword.text, 'new_password': newPassword.text}); currentPassword.clear(); newPassword.clear(); confirmPassword.clear(); _notice('Password changed successfully.'); }
    catch (_) { _notice('We could not change the password. Check your current password.'); }
    finally { if (mounted) setState(() => changingPassword = false); }
  }
  void _notice(String message) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  Future<void> _logout() async { await api.clearSession(); if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); }
  Future<void> _delete() async {
    final c = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (d) => AlertDialog(title: const Text('Delete account permanently?'), content: Column(mainAxisSize: MainAxisSize.min, children: [const Text('This cannot be undone. Type DELETE to confirm.'), TextField(controller: c, decoration: const InputDecoration(labelText: 'Confirmation'))]), actions: [TextButton(onPressed: () => Navigator.pop(d), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(d, c.text.trim() == 'DELETE'), child: const Text('Delete account'))]));
    c.dispose(); if (confirmed != true) return;
    try { await api.deleteAccount(); if (mounted) Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false); }
    catch (_) { _notice('We could not delete your account.'); }
  }
  @override Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.white, foregroundColor: navy), backgroundColor: const Color(0xFFF5F7FA),
    bottomNavigationBar: const TechnicianBottomNavigation(selectedIndex: 3),
    body: loading ? const Center(child: CircularProgressIndicator(color: orange)) : ListView(padding: const EdgeInsets.fromLTRB(18, 18, 18, 30), children: [
      _card('Account information', [TextField(controller: first, decoration: const InputDecoration(labelText: 'First name')), TextField(controller: last, decoration: const InputDecoration(labelText: 'Last name')), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')), TextField(readOnly: true, controller: TextEditingController(text: email), decoration: const InputDecoration(labelText: 'Email'))]),
      _card('Professional preferences', [TextField(controller: profession, decoration: const InputDecoration(labelText: 'Primary profession')), DropdownButtonFormField<String>(initialValue: responseTime, decoration: const InputDecoration(labelText: 'Response time'), items: const ['Within 1 hour','Within 2 hours','Within 12 hours','Within 24 hours','Within 48 hours','Within 72 hours'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => responseTime = v ?? responseTime)), SwitchListTile(title: const Text('Available for jobs'), value: availableForJobs, activeColor: orange, onChanged: (v) => setState(() => availableForJobs = v)), DropdownButtonFormField<String>(initialValue: availability, decoration: const InputDecoration(labelText: 'Availability status'), items: const ['available','busy','offline'].map((v) => DropdownMenuItem(value: v, child: Text(v[0].toUpperCase()+v.substring(1)))).toList(), onChanged: (v) => setState(() => availability = v ?? availability))]),
      _card('Privacy and notifications', [_unsupported('Visible in technician search', visibleInSearch, (v) => setState(() => visibleInSearch = v)), _unsupported('Show phone to clients', showPhone, (v) => setState(() => showPhone = v)), _unsupported('Show email to clients', showEmail, (v) => setState(() => showEmail = v)), _unsupported('Accept urgent jobs', acceptUrgent, (v) => setState(() => acceptUrgent = v)), _unsupported('Email notifications', emailNotifications, (v) => setState(() => emailNotifications = v)), _unsupported('SMS notifications', smsNotifications, (v) => setState(() => smsNotifications = v)), _unsupported('In-app notifications', inAppNotifications, (v) => setState(() => inAppNotifications = v)), _unsupported('Two-factor authentication', twoFactor, (v) => setState(() => twoFactor = v)), const Padding(padding: EdgeInsets.only(top: 8), child: Text('These controls are displayed by the website, but the current backend does not expose persistence fields for them.', style: TextStyle(color: muted, fontSize: 12)))]),
      SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: saving ? null : _save, icon: const Icon(Icons.save_outlined), label: Text(saving ? 'Saving...' : 'Save settings'), style: FilledButton.styleFrom(backgroundColor: orange, padding: const EdgeInsets.symmetric(vertical: 15)))),
      _card('Password', [TextField(controller: currentPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Current password')), TextField(controller: newPassword, obscureText: true, decoration: const InputDecoration(labelText: 'New password (minimum 8 characters)')), TextField(controller: confirmPassword, obscureText: true, decoration: const InputDecoration(labelText: 'Confirm new password')), SizedBox(width: double.infinity, child: OutlinedButton(onPressed: changingPassword ? null : _changePassword, child: Text(changingPassword ? 'Updating...' : 'Change password')))]),
      _card('Wallet', [ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.account_balance_wallet_outlined, color: orange), title: const Text('Manage wallet and payouts'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TechnicianWalletScreen())))]),
      _card('Account controls', [ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.logout, color: orange), title: const Text('Log out'), onTap: _logout), ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.delete_forever, color: Colors.red), title: const Text('Delete account permanently', style: TextStyle(color: Colors.red)), onTap: _delete)]),
    ]));
  Widget _card(String title, List<Widget> children) => Card(elevation: 0, margin: const EdgeInsets.only(bottom: 16), child: Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 16), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text(title, style: const TextStyle(color: navy, fontSize: 19, fontWeight: FontWeight.w800)), const SizedBox(height: 8), ...children.map((w) => Padding(padding: const EdgeInsets.only(top: 8), child: w))])));
  Widget _unsupported(String label, bool value, ValueChanged<bool> onChanged) => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(label), subtitle: const Text('Unavailable until the backend adds this preference.', style: TextStyle(color: muted, fontSize: 11)), value: value, activeColor: orange, onChanged: null);
}
