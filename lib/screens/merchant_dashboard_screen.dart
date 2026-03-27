import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../theme.dart';
import 'merchant_checkout_screen.dart';

/// Merchant dashboard — simple view of pending balance, transactions, and registration status.
class MerchantDashboardScreen extends StatefulWidget {
  final String merchantId;
  const MerchantDashboardScreen({super.key, required this.merchantId});

  @override
  State<MerchantDashboardScreen> createState() => _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  Map<String, dynamic>? _balance;
  List<dynamic>? _transactions;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        WalletService().getMerchantBalance(widget.merchantId),
        WalletService().getMerchantTransactions(widget.merchantId),
      ]);
      setState(() {
        _balance = results[0] as Map<String, dynamic>;
        _transactions = results[1] as List<dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchant Dashboard')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                        child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13)),
                      ),

                    // Balance cards
                    NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Pending Balance', style: TextStyle(fontSize: 13, color: NomadsColors.textMuted)),
                      const SizedBox(height: 4),
                      AmountDisplay(
                        currency: 'PHP',
                        amount: (_balance?['pending_balance'] ?? 0).toDouble(),
                        fontSize: 32,
                        color: NomadsColors.warning,
                      ),
                      const SizedBox(height: 4),
                      Text('Held until registration complete',
                          style: TextStyle(fontSize: 11, color: Colors.amber[700])),
                    ])),
                    const SizedBox(height: 8),

                    NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Released Balance', style: TextStyle(fontSize: 13, color: NomadsColors.textMuted)),
                      const SizedBox(height: 4),
                      AmountDisplay(
                        currency: 'PHP',
                        amount: (_balance?['released_balance'] ?? 0).toDouble(),
                        fontSize: 32,
                        color: NomadsColors.success,
                      ),
                    ])),
                    const SizedBox(height: 8),

                    NCard(child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      _stat('Total Sales', '${_balance?['total_checkouts'] ?? 0}'),
                      _stat('Currency', _balance?['currency'] ?? 'PHP'),
                    ])),

                    const SizedBox(height: 16),

                    // Accept payment button
                    PrimaryButton(
                      label: 'Accept New Payment',
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const MerchantCheckoutScreen())),
                    ),

                    const SizedBox(height: 24),

                    // Transactions
                    const Text('Recent Payments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    if (_transactions == null || _transactions!.isEmpty)
                      const EmptyState(icon: Icons.receipt_long, title: 'No payments yet',
                          subtitle: 'Accept your first payment to see it here.')
                    else
                      NCard(
                        padding: EdgeInsets.zero,
                        child: Column(children: _transactions!.asMap().entries.map((e) {
                          final tx = e.value as Map<String, dynamic>;
                          final isLast = e.key == _transactions!.length - 1;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: isLast ? null : const Border(bottom: BorderSide(color: NomadsColors.border, width: 0.5)),
                            ),
                            child: Row(children: [
                              Container(
                                width: 36, height: 36,
                                decoration: BoxDecoration(
                                  color: tx['status'] == 'paid' ? NomadsColors.successLight : NomadsColors.warningLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  tx['status'] == 'paid' ? Icons.check : Icons.schedule,
                                  color: tx['status'] == 'paid' ? NomadsColors.success : NomadsColors.warning,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(tx['note']?.toString() ?? 'Payment',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                Text(tx['created_at']?.toString().substring(0, 16) ?? '',
                                    style: const TextStyle(fontSize: 11, color: NomadsColors.textMuted)),
                              ])),
                              Text('₱${(tx['amount'] ?? 0).toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ]),
                          );
                        }).toList()),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
    ]);
  }
}
