import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_state.dart';
import 'phone_validation.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  String _selectedMethod = 'Mobile Money';
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppState>(
      builder: (appState) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF001F3F)),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              "Withdraw Funds",
              style: TextStyle(
                color: Color(0xFF001F3F),
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBalanceCard(appState),
                const SizedBox(height: 32),
                const Text(
                  "Withdrawal Amount",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF001F3F),
                  ),
                ),
                const SizedBox(height: 12),
                _buildAmountInput(),
                const SizedBox(height: 32),
                const Text(
                  "Select Method",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF001F3F),
                  ),
                ),
                const SizedBox(height: 16),
                _buildMethodItem(
                  "Mobile Money",
                  "MTN, Orange, Airtel",
                  Icons.phone_android_outlined,
                ),
                _buildMethodItem(
                  "Bank Transfer",
                  "Direct to your bank account",
                  Icons.account_balance_outlined,
                ),
                if (_selectedMethod == 'Mobile Money') ...[
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [phoneInputFormatter('Cameroon')],
                    decoration: const InputDecoration(
                      labelText: 'Cameroon Mobile Money number',
                      prefixText: '+237 ',
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                _buildWithdrawButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBalanceCard(AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Available Balance",
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 4),
              Text(
                "\$${appState.walletBalance.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF001F3F),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              "Escrow Protected",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return TextField(
      controller: _amountController,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: Color(0xFF001F3F),
      ),
      decoration: InputDecoration(
        prefixText: "\$ ",
        prefixStyle: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Color(0xFF001F3F),
        ),
        hintText: "0.00",
        hintStyle: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF001F3F).withValues(alpha: 0.2),
        ),
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 20,
        ),
      ),
    );
  }

  Widget _buildMethodItem(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedMethod == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = title),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF001F3F).withValues(alpha: 0.02)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF001F3F)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF001F3F), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF001F3F),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Color(0xFF001F3F))
            else
              const Icon(Icons.radio_button_off, color: Color(0xFFE2E8F0)),
          ],
        ),
      ),
    );
  }

  Widget _buildWithdrawButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          final amount = double.tryParse(_amountController.text.trim()) ?? 0;
          if (amount <= 0 ||
              (_selectedMethod == 'Mobile Money' &&
                  (amount < 500 ||
                      !validPhoneForCountry(
                        _phoneController.text.trim(),
                        'Cameroon',
                      )))) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Enter a valid amount and Cameroon payout number. Mobile Money withdrawals require at least 500 XAF.',
                ),
              ),
            );
            return;
          }
          try {
            await AppStateScope.of(context).requestWithdrawal(
              amount: amount,
              method: _selectedMethod,
              phoneNumber: _selectedMethod == 'Mobile Money'
                  ? internationalPhone(
                      _phoneController.text.trim(),
                      'Cameroon',
                    ).replaceAll(RegExp(r'[^0-9]'), '')
                  : null,
            );
            if (mounted) _showSuccessDialog();
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Withdrawal failed: $error')),
              );
            }
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF4500),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: const Text(
          "Confirm Withdrawal",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Color(0xFF1E8E3E),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Withdrawal Initiated",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF001F3F),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Your funds are on the way! It usually takes 1-3 business days to process.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001F3F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text("Back to Wallet"),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
