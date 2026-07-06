import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'main_navigation_screen.dart';
import 'withdraw_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppStateScope.of(context).syncWallet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        final transactions = appState.walletTransactions;
        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBalanceCard(context, appState),
                        const SizedBox(height: 20),
                        _buildEarningsRow(appState),
                        const SizedBox(height: 20),
                        const Text('Recent Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
                        const SizedBox(height: 12),
                        if (transactions.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Text('No transactions recorded.', style: TextStyle(color: Color(0xFF64748B))),
                            ),
                          )
                        else
                          for (final transaction in transactions) ...[
                            _buildTransactionItem(transaction),
                            const SizedBox(height: 12),
                          ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    final role = AppStateScope.of(context).currentRole;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => MainNavigationScreen(role: role, initialIndex: 0)),
                (route) => false,
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_back, color: Color(0xFF001F3F), size: 20),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Wallet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, AppState appState) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white70)),
          const SizedBox(height: 8),
          Text('\$${appState.walletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const WithdrawScreen()),
                ).then((_) {
                  // Refresh wallet state upon returning from withdrawal screen
                  AppStateScope.of(context).syncWallet();
                });
              },
              icon: const Icon(Icons.arrow_outward, size: 18),
              label: const Text('Withdraw Funds'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4500), foregroundColor: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsRow(AppState appState) {
    return Row(
      children: [
        _buildEarningCard('Pending', '\$${appState.pendingBalance.toStringAsFixed(2)}'),
        const SizedBox(width: 16),
        _buildEarningCard('Transactions', appState.walletTransactions.length.toString()),
      ],
    );
  }

  Widget _buildEarningCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic transaction) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(transaction.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF001F3F))),
                const SizedBox(height: 4),
                Text(transaction.date, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(transaction.amount, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF001F3F))),
              const SizedBox(height: 4),
              Text(transaction.status, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}
