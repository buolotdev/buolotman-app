import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../phone_validation.dart';
import 'technician_navigation.dart';
import 'subscription_screen.dart';

class TechnicianWalletScreen extends StatefulWidget {
  const TechnicianWalletScreen({super.key, this.withBottomNavigation = true});

  final bool withBottomNavigation;

  @override
  State<TechnicianWalletScreen> createState() => _WalletState();
}

class _WalletState extends State<TechnicianWalletScreen> {
  static const navy = Color(0xFF001F3F);
  static const orange = Color(0xFFFF4500);
  static const muted = Color(0xFF64748B);
  final api = ApiService();
  late Future<Map<String, dynamic>> walletFuture = api.wallet();
  late Future<List<dynamic>> transactionsFuture = api.walletTransactions();

  void refresh() {
    setState(() {
      walletFuture = api.wallet();
      transactionsFuture = api.walletTransactions();
    });
  }

  Future<void> withdraw() async {
    final amount = TextEditingController();
    final phone = TextEditingController();
    final bankName = TextEditingController();
    final accountNumber = TextEditingController();
    var method = 'mobile';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw funds'),
        content: StatefulBuilder(
          builder: (context, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount (XAF)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: method,
                decoration: const InputDecoration(
                  labelText: 'Withdrawal method',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'mobile',
                    child: Text('Mobile Money'),
                  ),
                  DropdownMenuItem(
                    value: 'bank',
                    child: Text('Direct bank transfer'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => method = value ?? 'mobile'),
              ),
              const SizedBox(height: 12),
              if (method == 'mobile')
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [phoneInputFormatter('Cameroon')],
                  decoration: const InputDecoration(
                    labelText: 'Cameroon Mobile Money number',
                    prefixText: '+237 ',
                  ),
                )
              else ...[
                TextField(
                  controller: bankName,
                  decoration: const InputDecoration(labelText: 'Bank name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: accountNumber,
                  decoration: const InputDecoration(
                    labelText: 'Account number / IBAN',
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Request withdrawal'),
          ),
        ],
      ),
    );
    final value = double.tryParse(amount.text.trim());
    final validMobile =
        method == 'mobile' &&
        validPhoneForCountry(phone.text.trim(), 'Cameroon');
    final validBank =
        method == 'bank' &&
        bankName.text.trim().isNotEmpty &&
        accountNumber.text.trim().isNotEmpty;
    if (submitted != true ||
        value == null ||
        value <= 0 ||
        (method == 'mobile' && (!validMobile || value < 500)) ||
        (method == 'bank' && !validBank)) {
      if (submitted == true && mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a valid amount and payout details. Mobile Money withdrawals require at least 500 XAF.',
            ),
          ),
        );
      return;
    }
    try {
      if (method == 'mobile') {
        await api.campayWithdraw({
          'amount': value,
          'phone_number': internationalPhone(
            phone.text.trim(),
            'Cameroon',
          ).replaceAll(RegExp(r'[^0-9]'), ''),
          'description': 'Technician wallet withdrawal',
        });
      } else {
        await api.withdrawFunds({
          'amount': value,
          'method': 'bank_transfer',
          'account_details': {
            'method': 'Direct bank transfer',
            'bank_name': bankName.text.trim(),
            'account_number_or_iban': accountNumber.text.trim(),
          },
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal request submitted.')),
      );
      refresh();
    } catch (_) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not submit the withdrawal request.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.withBottomNavigation
          ? const TechnicianBottomNavigation(selectedIndex: 2)
          : null,
      appBar: AppBar(
        title: const Text('Wallet'),
        foregroundColor: navy,
        backgroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F7FA),
      body: FutureBuilder<Map<String, dynamic>>(
        future: walletFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(
              child: CircularProgressIndicator(color: orange),
            );
          if (snapshot.hasError)
            return const Center(
              child: Text(
                'Wallet information is temporarily unavailable.',
                style: TextStyle(color: muted),
              ),
            );
          final wallet = snapshot.data ?? <String, dynamic>{};
          final currency = '${wallet['currency'] ?? 'XAF'}';
          return RefreshIndicator(
            onRefresh: () async => refresh(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _balance(
                  'Available balance',
                  wallet['available_balance'] ?? 0,
                  currency,
                ),
                _balance(
                  'Pending escrow',
                  wallet['pending_escrow'] ?? 0,
                  currency,
                ),
                _balance(
                  'Total earned',
                  wallet['total_earnings'] ?? 0,
                  currency,
                ),
                _balance(
                  'Total withdrawn',
                  wallet['total_withdrawn'] ?? 0,
                  currency,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: withdraw,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Request withdrawal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.stars_outlined),
                    label: const Text('Plans and subscriptions'),
                  ),
                ),
                const SizedBox(height: 22),
                const Text(
                  'Transactions',
                  style: TextStyle(
                    color: navy,
                    fontSize: 19,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                FutureBuilder<List<dynamic>>(
                  future: transactionsFuture,
                  builder: (context, tx) {
                    if (tx.connectionState != ConnectionState.done)
                      return const Center(
                        child: CircularProgressIndicator(color: orange),
                      );
                    final rows = tx.data ?? const <dynamic>[];
                    if (rows.isEmpty)
                      return const Text(
                        'No transactions yet.',
                        style: TextStyle(color: muted),
                      );
                    return Column(
                      children: rows.map<Widget>((item) {
                        final x = item is Map ? item : <String, dynamic>{};
                        return Card(
                          elevation: 0,
                          child: ListTile(
                            title: Text(
                              '${x['description'] ?? x['category'] ?? 'Transaction'}',
                              style: const TextStyle(color: navy),
                            ),
                            subtitle: Text(
                              '${x['status'] ?? ''} • ${x['created_at'] ?? ''}',
                              style: const TextStyle(color: muted),
                            ),
                            trailing: Text(
                              '${x['amount'] ?? 0} $currency',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: navy,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _balance(String label, dynamic value, String currency) => Card(
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: const Icon(Icons.account_balance_wallet_outlined, color: orange),
      title: Text(label, style: const TextStyle(color: muted)),
      subtitle: Text(
        '$value $currency',
        style: const TextStyle(
          color: navy,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
