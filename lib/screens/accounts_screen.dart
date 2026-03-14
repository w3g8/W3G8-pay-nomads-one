import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  List<dynamic> _accounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final accounts = await WalletService().getAccounts();
      setState(() { _accounts = accounts; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: '', decimalDigits: 2);
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _accounts.length,
                itemBuilder: (ctx, i) {
                  final a = _accounts[i];
                  final currency = a['currency'] ?? 'PHP';
                  final balance = a['available_balance'] ?? a['balance'] ?? 0;
                  final isActive = a['status'] == 'active';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8)],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: isActive ? const Color(0xFF1a56db).withAlpha(25) : Colors.grey[100],
                        child: Text(currency, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold,
                            color: isActive ? const Color(0xFF1a56db) : Colors.grey)),
                      ),
                      title: Text(a['name'] ?? a['account_number'] ?? 'Account',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(a['account_number'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$currency ${fmt.format(balance)}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(isActive ? 'Active' : (a['status'] ?? ''),
                              style: TextStyle(fontSize: 11, color: isActive ? Colors.green : Colors.grey)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
