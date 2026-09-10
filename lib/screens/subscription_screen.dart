import 'package:flutter/material.dart';
import '../core/api_service.dart';

const subscriptionNavy = Color(0xFF001F3F);
const subscriptionOrange = Color(0xFFFF4500);
const subscriptionBg = Color(0xFFF5F7FA);

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final api = ApiService();
  bool annual = false;
  bool loading = true;
  bool upgrading = false;
  Map<String, dynamic> wallet = {};
  String? currentTier;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([api.wallet(), api.profile()]);
      if (!mounted) return;
      final profile = results[1] as Map<String, dynamic>;
      setState(() {
        wallet = results[0] as Map<String, dynamic>;
        currentTier = _readTier(profile);
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  String? _readTier(Map<String, dynamic> profile) {
    final raw = profile['subscription_tier'] ??
        profile['tier'] ??
        profile['user']?['subscription_tier'];
    return raw?.toString().toUpperCase();
  }

  double get balance => double.tryParse(
        '${wallet['available_balance'] ?? wallet['balance'] ?? 0}',
      ) ??
      0;

  Future<void> upgrade(String tier, String name, double price) async {
    if (currentTier == tier) return;
    final cycle = annual ? 'yearly' : 'monthly';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to $name?'),
        content: Text(
          '${price.toStringAsFixed(0)} ${wallet['currency'] ?? 'XAF'} / $cycle\n\n'
          'The website will charge your wallet when sufficient balance is available, otherwise it will use the direct payment source.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => upgrading = true);
    try {
      await api.upgradeSubscriptionPlan({
        'tier': tier,
        'billing_cycle': cycle,
        'payment_source': balance >= price ? 'wallet' : 'direct',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name upgrade request submitted.')),
        );
        await load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upgrade failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => upgrading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = wallet['currency'] ?? 'XAF';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plans and subscriptions'),
        foregroundColor: subscriptionNavy,
        backgroundColor: Colors.white,
      ),
      backgroundColor: subscriptionBg,
      body: loading
          ? const Center(child: CircularProgressIndicator(color: subscriptionOrange))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: subscriptionNavy,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Wallet balance: ${balance.toStringAsFixed(2)} $currency',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          onPressed: load,
                          color: Colors.white,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  value: annual,
                  onChanged: upgrading ? null : (value) => setState(() => annual = value),
                  title: const Text('Annual billing'),
                  subtitle: const Text('Use the yearly prices shown on the website.'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                _plan('Free', 'FREE', 0, 'Current basic access', false),
                _plan('Pro Plan', 'PRO', annual ? 190 : 19, 'Professional access', true),
                _plan('Enterprise Plan', 'ENTERPRISE', annual ? 1490 : 149, 'Enterprise access', true),
              ],
            ),
    );
  }

  Widget _plan(String name, String tier, double price, String description, bool actionable) {
    final selected = currentTier == tier;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: const TextStyle(color: subscriptionNavy, fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 5),
            Text(description),
            const SizedBox(height: 8),
            Text(
              price == 0 ? 'Free' : '${price.toStringAsFixed(0)} / ${annual ? 'year' : 'month'}',
              style: const TextStyle(color: subscriptionNavy, fontSize: 18, fontWeight: FontWeight.w700),
            ),
            if (actionable) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: upgrading || selected ? null : () => upgrade(tier, name, price),
                  style: FilledButton.styleFrom(backgroundColor: subscriptionOrange),
                  child: Text(selected ? 'Current plan' : 'Upgrade'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
