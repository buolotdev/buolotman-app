import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_state.dart';
import 'api_service.dart';

class TechnicianPayoutSettingsScreen extends StatefulWidget {
  const TechnicianPayoutSettingsScreen({super.key});

  @override
  State<TechnicianPayoutSettingsScreen> createState() => _TechnicianPayoutSettingsScreenState();
}

class _TechnicianPayoutSettingsScreenState extends State<TechnicianPayoutSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  String _preferredPayoutMethod = 'Bank Account';
  String _bankAccountName = '';
  String _bankAccountNumber = '';
  String _bankName = '';
  String _mobileMoneyNumber = '';
  String _payoutCurrency = 'USD';
  String _verificationStatus = 'Unverified';

  @override
  void initState() {
    super.initState();
    final appState = Get.find<AppState>();
    final prof = appState.currentUser;
    _preferredPayoutMethod = prof?.preferredPayoutMethod ?? 'Bank Account';
    if (_preferredPayoutMethod.isEmpty) _preferredPayoutMethod = 'Bank Account';
    
    _bankAccountName = prof?.bankAccountName ?? '';
    _bankAccountNumber = prof?.bankAccountNumber ?? '';
    _bankName = prof?.bankName ?? '';
    _mobileMoneyNumber = prof?.mobileMoneyNumber ?? '';
    _payoutCurrency = prof?.payoutCurrency ?? 'USD';
    if (_payoutCurrency.isEmpty) _payoutCurrency = 'USD';
    
    _verificationStatus = prof?.paymentVerificationStatus ?? 'Unverified';
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);
    try {
      final appState = Get.find<AppState>();
      await ApiService.instance.updateTechnicianProfile({
        'preferred_payout_method': _preferredPayoutMethod,
        'bank_account_name': _bankAccountName,
        'bank_account_number': _bankAccountNumber,
        'bank_name': _bankName,
        'mobile_money_number': _mobileMoneyNumber,
        'payout_currency': _payoutCurrency,
      });
      await appState.syncProfile(); // refresh
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payout settings saved securely.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: \$e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Payout Settings', style: TextStyle(color: Color(0xFF001F3F))),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Color(0xFF001F3F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Payment Verification Status', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(
                      _verificationStatus == 'Verified' ? Icons.check_circle : Icons.pending,
                      color: _verificationStatus == 'Verified' ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _verificationStatus,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _verificationStatus == 'Verified' ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('Your financial details remain completely private and are used only for Boulot Man payouts.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              const Text('Payout Method', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _preferredPayoutMethod,
                decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                items: ['Bank Account', 'Mobile Money'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _preferredPayoutMethod = v!),
              ),
              const SizedBox(height: 16),
              const Text('Payout Currency', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _payoutCurrency,
                decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                items: ['USD', 'EUR', 'GBP', 'XAF'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _payoutCurrency = v!),
              ),
              const SizedBox(height: 24),
              if (_preferredPayoutMethod == 'Bank Account') ...[
                const Text('Bank Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _bankName,
                  decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                  onSaved: (v) => _bankName = v ?? '',
                ),
                const SizedBox(height: 16),
                const Text('Account Holder Name', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _bankAccountName,
                  decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                  onSaved: (v) => _bankAccountName = v ?? '',
                ),
                const SizedBox(height: 16),
                const Text('Bank Account Number', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _bankAccountNumber,
                  decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                  onSaved: (v) => _bankAccountNumber = v ?? '',
                ),
              ],
              if (_preferredPayoutMethod == 'Mobile Money') ...[
                const Text('Mobile Money Number', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _mobileMoneyNumber,
                  decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                  onSaved: (v) => _mobileMoneyNumber = v ?? '',
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500), padding: const EdgeInsets.all(16)),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Payout Settings', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
