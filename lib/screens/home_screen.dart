import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import 'scan_screen.dart';
import 'accounts_screen.dart';
import 'bills_screen.dart';
import 'merchant_qr_screen.dart';
import 'topup_screen.dart';
import 'send_screen.dart';
import 'bill_qr_generator_screen.dart';
import 'cards_screen.dart';
import 'utilities_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _dashboard;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await WalletService().getDashboard();
      setState(() { _dashboard = data; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildDashboard(),
      const AccountsScreen(),
      const ScanScreen(),
      const CardsScreen(),
      const MerchantQRScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Accounts'),
          NavigationDestination(icon: Icon(Icons.qr_code_scanner), selectedIcon: Icon(Icons.qr_code_scanner), label: 'Scan & Pay'),
          NavigationDestination(icon: Icon(Icons.credit_card_outlined), selectedIcon: Icon(Icons.credit_card), label: 'Cards'),
          NavigationDestination(icon: Icon(Icons.store_outlined), selectedIcon: Icon(Icons.store), label: 'My QR'),
        ],
      ),
    );
  }

  void _pushScreen(Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildDashboard() {
    final fmt = NumberFormat.currency(symbol: 'PHP ', decimalDigits: 2);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Pay Nomads', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  Text('nomads.one', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ]),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await AuthService().logout();
                    if (mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Balance card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1a56db), Color(0xFF7c3aed)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Balance', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  _loading
                      ? const SizedBox(height: 36, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          fmt.format(_dashboard?['total_balance'] ?? 0),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickAction(Icons.qr_code_scanner, 'Scan & Pay', () => setState(() => _currentIndex = 2)),
                _quickAction(Icons.add_card, 'Top Up', () => _pushScreen(const TopUpScreen())),
                _quickAction(Icons.build_outlined, 'Utilities', () => _pushScreen(const UtilitiesScreen())),
                _quickAction(Icons.currency_exchange, 'Exchange', () {}),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _quickAction(Icons.send, 'Send', () => _pushScreen(const SendScreen())),
                _quickAction(Icons.qr_code, 'Bill QR', () => _pushScreen(const BillQrGeneratorScreen())),
                _quickAction(Icons.store, 'My QR', () => setState(() => _currentIndex = 4)),
                _quickAction(Icons.credit_card, 'Cards', () => setState(() => _currentIndex = 3)),
              ],
            ),
            const SizedBox(height: 24),

            // Recent transactions
            Text('Recent Transactions', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_dashboard?['recent_transactions'] != null)
              ...(_dashboard!['recent_transactions'] as List).take(10).map((tx) => _txTile(tx, fmt))
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No transactions yet', style: TextStyle(color: Colors.grey[500])),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1a56db).withAlpha(25),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF1a56db)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _txTile(Map<String, dynamic> tx, NumberFormat fmt) {
    final isCredit = tx['type'] == 'credit' || tx['debit_credit'] == 'credit' || (tx['amount'] ?? 0) > 0;
    final txType = tx['transaction_type'] ?? tx['type'] ?? '';
    final canRepeat = ['qr_payment', 'invite_hold', 'transfer', 'card_funding', 'bill_payment'].contains(txType);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: isCredit ? Colors.green[50] : Colors.red[50],
        child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? Colors.green : Colors.red, size: 20),
      ),
      title: Text(tx['description'] ?? txType,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(tx['created_at']?.toString().substring(0, 10) ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      trailing: Text(
        '${isCredit ? '+' : '-'}${fmt.format(_parseAmount(tx['amount']).abs())}',
        style: TextStyle(fontWeight: FontWeight.w600, color: isCredit ? Colors.green : Colors.red[700]),
      ),
      onTap: () => _showTxDetail(tx, canRepeat),
    );
  }

  double _parseAmount(dynamic amount) {
    if (amount == null) return 0;
    if (amount is num) return amount.toDouble();
    if (amount is String) {
      // Handle base64 encoded amounts from BIAN API
      try {
        final decoded = String.fromCharCodes(Uri.parse('data:,${Uri.decodeComponent(amount)}').data?.contentAsBytes() ?? []);
        return double.tryParse(decoded) ?? double.tryParse(amount) ?? 0;
      } catch (_) {
        return double.tryParse(amount) ?? 0;
      }
    }
    return 0;
  }

  void _showTxDetail(Map<String, dynamic> tx, bool canRepeat) {
    final fmt = NumberFormat.currency(symbol: '${tx['currency'] ?? ''} ', decimalDigits: 2);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(tx['description'] ?? tx['transaction_type'] ?? 'Transaction', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _txDetailRow('Amount', fmt.format(_parseAmount(tx['amount']).abs())),
          _txDetailRow('Type', tx['transaction_type'] ?? tx['type'] ?? ''),
          _txDetailRow('Account', tx['account_name'] ?? tx['account_number'] ?? ''),
          _txDetailRow('Reference', tx['reference'] ?? ''),
          _txDetailRow('Date', tx['created_at']?.toString().substring(0, 19) ?? ''),
          if (canRepeat) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _repeatTransaction(tx);
                },
                icon: const Icon(Icons.replay, size: 18),
                label: const Text('Repeat Payment'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1a56db),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _txDetailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
      ]),
    );
  }

  void _repeatTransaction(Map<String, dynamic> tx) {
    // Navigate to appropriate screen based on transaction type
    final type = tx['transaction_type'] ?? '';
    switch (type) {
      case 'qr_payment':
        setState(() => _currentIndex = 2); // Scan & Pay
        break;
      case 'card_funding':
        setState(() => _currentIndex = 3); // Cards
        break;
      default:
        _pushScreen(const TopUpScreen()); // Default to top up
    }
  }
}
