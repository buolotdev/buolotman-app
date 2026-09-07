import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'login_screen.dart';
import 'company_dashboard_screen.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});
  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  static const navy = Color(0xFF001F3F),
      orange = Color(0xFFFF4500),
      bg = Color(0xFFF5F7FA),
      muted = Color(0xFF64748B);
  final api = ApiService();
  Map<String, dynamic> values = {};
  bool loading = true, saving = false;
  final responseTimes = const [
    '',
    'Within 24 hours',
    'Within 48 hours',
    'Within 72 hours',
  ];
  final currencies = const ['USD', 'EUR', 'RWF', 'XOF'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await api.companyProfile();
      if (mounted)
        setState(() {
          values = Map<String, dynamic>.from(data);
          loading = false;
        });
    } catch (_) {
      if (mounted) {
        setState(() => loading = false);
        _notice('Could not load company settings.');
      }
    }
  }

  void _set(String key, dynamic value) => setState(() => values[key] = value);
  Future<void> _save() async {
    setState(() => saving = true);
    try {
      final payload = <String, dynamic>{
        'currency': '${values['currency'] ?? 'USD'}',
        'response_time': '${values['response_time'] ?? ''}',
        'auto_accept_visits': values['auto_accept_visits'] == true,
        'notif_email': values['notif_email'] != false,
        'notif_sms': values['notif_sms'] == true,
        'notif_inapp': values['notif_inapp'] != false,
        'privacy_public': values['privacy_public'] != false,
        'privacy_show_phone': values['privacy_show_phone'] == true,
        'privacy_show_email': values['privacy_show_email'] == true,
        'privacy_search': values['privacy_search'] != false,
        'sec_2fa': values['sec_2fa'] == true,
      };
      await api.updateCompanyProfile(payload);
      await _load();
      if (mounted) _notice('Settings saved successfully.');
    } catch (e) {
      if (mounted)
        _notice(e is ApiException ? e.message : 'Could not save settings.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  Future<void> _password() async {
    final current = TextEditingController(),
        next = TextEditingController(),
        confirm = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Change password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(current, 'Current password', true),
            const SizedBox(height: 12),
            _dialogField(next, 'New password', true),
            const SizedBox(height: 12),
            _dialogField(confirm, 'Confirm new password', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (next.text.length < 8 || next.text != confirm.text) {
      _notice('Use at least 8 characters and make both new passwords match.');
      return;
    }
    try {
      await api.changePassword({
        'current_password': current.text,
        'new_password': next.text,
      });
      if (mounted) _notice('Password changed successfully.');
    } catch (e) {
      if (mounted)
        _notice(e is ApiException ? e.message : 'Could not change password.');
    }
  }

  Widget _dialogField(TextEditingController c, String label, bool obscure) =>
      TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
  Future<void> _delete() async {
    final first = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Delete company account?'),
        content: const Text(
          'This permanently deletes the account and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;
    final confirm = TextEditingController();
    final second = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: const Text('Final confirmation'),
        content: TextField(
          controller: confirm,
          decoration: const InputDecoration(
            labelText: 'Type DELETE to confirm',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(d, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(d, confirm.text.trim() == 'DELETE'),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (second != true) return;
    try {
      await api.deleteAccount();
      if (mounted)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
    } catch (e) {
      if (mounted)
        _notice(
          e is ApiException ? e.message : 'Could not delete this account.',
        );
    }
  }

  Future<void> _logout() async {
    await api.clearSession();
    if (mounted)
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    appBar: AppBar(
      backgroundColor: navy,
      foregroundColor: Colors.white,
      title: const Text('Company settings'),
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator(color: orange))
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _section('Business preferences', [
                _select('Response time', 'response_time', responseTimes),
                _select('Preferred currency', 'currency', currencies),
              ]),
              _section('Preferences', [
                _toggle('Auto-accept site visits', 'auto_accept_visits'),
                _toggle('Email notifications', 'notif_email'),
                _toggle('SMS notifications', 'notif_sms'),
                _toggle('In-app notifications', 'notif_inapp'),
              ]),
              _section('Privacy & visibility', [
                _toggle('Public profile visible', 'privacy_public'),
                _toggle('Show phone number', 'privacy_show_phone'),
                _toggle('Show email address', 'privacy_show_email'),
                _toggle('Appear in search results', 'privacy_search'),
              ]),
              _section('Security', [
                _toggle('Enable two-factor authentication', 'sec_2fa'),
                _button(
                  'Change password',
                  Icons.lock_outline,
                  _password,
                  outlined: true,
                ),
              ]),
              _section('Wallet', [
                const Text(
                  'Manage company payments and wallet activity.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 12),
                _button(
                  'Open wallet',
                  Icons.account_balance_wallet_outlined,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const CompanyPlaceholderScreen(title: 'Wallet'),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(saving ? 'Saving...' : 'Save all changes'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: navy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('Delete account permanently'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
  );
  Widget _section(String title, List<Widget> children) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: navy,
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
  Widget _select(String label, String key, List<String> options) {
    final current = options.contains('${values[key] ?? ''}')
        ? '${values[key] ?? ''}'
        : options.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: current,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items: options
            .map(
              (x) => DropdownMenuItem(
                value: x,
                child: Text(x.isEmpty ? 'Select time' : x),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) _set(key, v);
        },
      ),
    );
  }

  Widget _toggle(String label, String key) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    activeColor: orange,
    title: Text(
      label,
      style: const TextStyle(color: navy, fontWeight: FontWeight.w600),
    ),
    value: values[key] == true,
    onChanged: (v) => _set(key, v),
  );
  Widget _button(
    String label,
    IconData icon,
    VoidCallback action, {
    bool outlined = false,
  }) => SizedBox(
    width: double.infinity,
    child: outlined
        ? OutlinedButton.icon(
            onPressed: action,
            icon: Icon(icon),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          )
        : FilledButton.icon(
            onPressed: action,
            icon: Icon(icon),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
  );
}
