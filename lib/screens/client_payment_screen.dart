import 'dart:async';
import 'package:flutter/material.dart';
import '../core/api_service.dart';

const payNavy = Color(0xFF001F3F),
    payOrange = Color(0xFFFF4500),
    payMuted = Color(0xFF64748B),
    payBg = Color(0xFFF5F7FA);

class ClientWalletScreen extends StatefulWidget {
  const ClientWalletScreen({super.key});
  @override
  State<ClientWalletScreen> createState() => _ClientWalletState();
}

class _ClientWalletState extends State<ClientWalletScreen> {
  final api = ApiService();
  Map<String, dynamic> wallet = {};
  List<dynamic> transactions = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<dynamic>([
        api.wallet(),
        api.walletTransactions(),
      ]);
      if (mounted)
        setState(() {
          wallet = values[0] is Map ? values[0] as Map<String, dynamic> : {};
          transactions = values[1] is List ? values[1] as List : [];
          loading = false;
        });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Payments and wallet'),
      foregroundColor: payNavy,
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh, color: payNavy),
        ),
      ],
    ),
    backgroundColor: payBg,
    body: loading
        ? const Center(child: CircularProgressIndicator(color: payOrange))
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _card(
                  'Available balance',
                  '${wallet['available_balance'] ?? 0} ${wallet['currency'] ?? 'XAF'}',
                  Icons.account_balance_wallet_outlined,
                ),
                _card(
                  'Escrow held',
                  '${wallet['pending_escrow'] ?? wallet['escrow_balance'] ?? 0} ${wallet['currency'] ?? 'XAF'}',
                  Icons.lock_outline,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Transactions',
                  style: TextStyle(
                    color: payNavy,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (transactions.isEmpty)
                  const Card(
                    elevation: 0,
                    child: Padding(
                      padding: EdgeInsets.all(18),
                      child: Text(
                        'No transactions yet.',
                        style: TextStyle(color: payMuted),
                      ),
                    ),
                  )
                else
                  ...transactions.map((raw) {
                    final x = raw is Map ? raw : <String, dynamic>{};
                    return Card(
                      elevation: 0,
                      child: ListTile(
                        leading: Icon(
                          Icons.receipt_long_outlined,
                          color: x['type'] == 'refund'
                              ? Colors.green
                              : payOrange,
                        ),
                        title: Text(
                          '${x['description'] ?? x['category'] ?? 'Transaction'}',
                          style: const TextStyle(
                            color: payNavy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${x['status'] ?? ''} • ${x['created_at'] ?? ''}',
                          style: const TextStyle(color: payMuted),
                        ),
                        trailing: Text(
                          '${x['amount'] ?? ''}',
                          style: const TextStyle(
                            color: payNavy,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
  );
  Widget _card(String title, String value, IconData icon) => Card(
    elevation: 0,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: payOrange, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: payMuted)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: payNavy,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class ClientEscrowPaymentScreen extends StatefulWidget {
  const ClientEscrowPaymentScreen({
    super.key,
    required this.taskId,
    required this.amount,
    this.bidId,
  });
  final dynamic taskId, amount, bidId;
  @override
  State<ClientEscrowPaymentScreen> createState() => _EscrowPaymentState();
}

class _EscrowPaymentState extends State<ClientEscrowPaymentScreen> {
  final api = ApiService();
  final phone = TextEditingController();
  String method = 'mobile';
  bool processing = false;
  String status = '';
  Timer? timer;
  @override
  void dispose() {
    timer?.cancel();
    phone.dispose();
    super.dispose();
  }

  void _notice(String value) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(value)));
  Future<void> _pay() async {
    final amount = num.tryParse('${widget.amount}') ?? 0;
    if (amount <= 0) return _notice('The escrow amount is invalid.');
    if (method == 'mobile' && phone.text.trim().isEmpty)
      return _notice('Enter the Cameroon Mobile Money number.');
    setState(() {
      processing = true;
      status = '';
    });
    try {
      if (method == 'wallet') {
        await api.depositEscrow({
          'task_id': widget.taskId,
          if (widget.bidId != null) 'bid_id': widget.bidId,
          'amount': amount,
        });
        _notice('Escrow funded successfully.');
        if (mounted) Navigator.pop(context, true);
        return;
      }
      final clean = phone.text.replaceAll(RegExp(r'[^0-9]'), '');
      final result = await api.campayCollect({
        'amount': amount,
        'phone_number': clean.startsWith('237') ? clean : '237$clean',
        'task_id': widget.taskId,
        if (widget.bidId != null) 'bid_id': widget.bidId,
        'purpose': 'escrow_deposit',
        'description': 'Escrow deposit',
      });
      final reference = result is Map ? result['reference'] : null;
      if (reference == null)
        throw Exception('Mobile Money request could not be started.');
      setState(
        () => status = 'Payment request sent. Confirm it on your phone.',
      );
      timer = Timer.periodic(
        const Duration(seconds: 3),
        (_) => _check(reference.toString()),
      );
    } catch (e) {
      _notice(e.toString());
      setState(() => processing = false);
    }
  }

  Future<void> _check(String reference) async {
    try {
      final result = await api.campayCheckStatus(reference);
      final value =
          '${result is Map ? result['status'] ?? result['state'] ?? '' : ''}'
              .toUpperCase();
      if (value == 'SUCCESSFUL' || value == 'SUCCESS' || value == 'COMPLETED') {
        timer?.cancel();
        if (mounted) {
          setState(() {
            processing = false;
            status = 'Payment confirmed and escrow funded.';
          });
          _notice(status);
        }
      } else if (value == 'FAILED' || value == 'CANCELLED') {
        timer?.cancel();
        if (mounted)
          setState(() {
            processing = false;
            status = 'Payment was not completed.';
          });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Fund escrow'),
      foregroundColor: payNavy,
      backgroundColor: Colors.white,
    ),
    backgroundColor: payBg,
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escrow deposit',
                  style: TextStyle(
                    color: payNavy,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Amount: ${widget.amount} XAF',
                  style: const TextStyle(color: payMuted),
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(
                    labelText: 'Payment method',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'mobile',
                      child: Text('CamPay Mobile Money'),
                    ),
                    DropdownMenuItem(
                      value: 'wallet',
                      child: Text('Wallet balance'),
                    ),
                  ],
                  onChanged: processing
                      ? null
                      : (value) => setState(() => method = value ?? 'mobile'),
                ),
                if (method == 'mobile') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile Money number',
                      hintText: '237 6XX XXX XXX',
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (status.isNotEmpty)
                  Text(
                    status,
                    style: const TextStyle(
                      color: payNavy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: processing ? null : _pay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: payOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: Text(
                      processing ? 'Waiting for payment...' : 'Fund escrow',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
