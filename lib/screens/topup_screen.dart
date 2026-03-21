import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wallet_service.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _amountCtrl = TextEditingController();
  String _currency = 'EUR';
  String _method = 'bank'; // bank (GoCardless) or card (Flutterwave)
  bool _loading = false;
  String? _error;
  String? _success;
  List<dynamic> _accounts = [];
  int? _selectedAccountId;
  List<dynamic> _banks = [];
  String? _selectedBankId;
  String _country = 'GB';

  final _currencies = ['EUR', 'GBP', 'USD', 'PHP', 'CHF'];
  final _countries = [
    ('GB', 'United Kingdom'),
    ('IE', 'Ireland'),
    ('DE', 'Germany'),
    ('FR', 'France'),
    ('NL', 'Netherlands'),
    ('ES', 'Spain'),
    ('IT', 'Italy'),
    ('PH', 'Philippines'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      _accounts = await WalletService().getAccounts();
      if (_accounts.isNotEmpty) {
        _selectedAccountId = _accounts.first['id'];
        _currency = _accounts.first['currency'] ?? 'EUR';
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _loadBanks() async {
    setState(() { _loading = true; _banks = []; _selectedBankId = null; });
    try {
      _banks = await WalletService().getInstitutions(_country);
      setState(() { _loading = false; });
    } catch (e) {
      setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _topUpViaBank() async {
    if (_amountCtrl.text.isEmpty || _selectedAccountId == null) return;
    if (_selectedBankId == null) {
      setState(() => _error = 'Select a bank first');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final result = await WalletService().initiateOpenBankingTopUp(
        accountId: _selectedAccountId!,
        amount: double.parse(_amountCtrl.text),
        currency: _currency,
        institutionId: _selectedBankId!,
      );

      // Open the bank authorization URL
      final authUrl = result['authorization_url'] ?? result['link'];
      if (authUrl != null) {
        final uri = Uri.parse(authUrl);
        if (kIsWeb) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
        setState(() => _success = 'Complete the payment in your banking app. Your wallet will be credited automatically.');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Top Up Wallet')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
                  IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _error = null)),
                ]),
              ),
            if (_success != null)
              Container(
                padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                child: Row(children: [
                  Icon(Icons.check_circle, color: Colors.green[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_success!, style: TextStyle(color: Colors.green[700], fontSize: 13))),
                ]),
              ),

            // Method selector
            Row(children: [
              Expanded(child: _methodChip('Bank Transfer', 'bank', Icons.account_balance)),
              const SizedBox(width: 8),
              Expanded(child: _methodChip('Card Payment', 'card', Icons.credit_card)),
            ]),
            const SizedBox(height: 20),

            // Amount
            _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _currency,
                    underline: const SizedBox(),
                    items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (v) => setState(() => _currency = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [10, 25, 50, 100, 250, 500].map((a) =>
                ActionChip(
                  label: Text('$_currency $a'),
                  onPressed: () => setState(() => _amountCtrl.text = a.toString()),
                ),
              ).toList()),
            ])),
            const SizedBox(height: 16),

            // Credit to account
            if (_accounts.isNotEmpty)
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Credit to', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedAccountId,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: _accounts.where((a) => a['status'] == 'active').map<DropdownMenuItem<int>>((a) =>
                    DropdownMenuItem(value: a['id'], child: Text(
                      '${a['name'] ?? a['account_number']} (${a['currency']})',
                      style: const TextStyle(fontSize: 14),
                    ))).toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                ),
              ])),
            const SizedBox(height: 16),

            if (_method == 'bank') ...[
              // GoCardless Open Banking
              _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.account_balance, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 8),
                  const Text('Open Banking', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ]),
                const SizedBox(height: 4),
                Text('Instant bank transfer via GoCardless', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 12),

                // Country selector
                const Text('Country', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _country,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                  items: _countries.map((c) => DropdownMenuItem(value: c.$1, child: Text(c.$2))).toList(),
                  onChanged: (v) {
                    setState(() => _country = v!);
                    _loadBanks();
                  },
                ),
                const SizedBox(height: 12),

                // Bank selector
                if (_banks.isEmpty && !_loading)
                  OutlinedButton.icon(
                    onPressed: _loadBanks,
                    icon: const Icon(Icons.search),
                    label: const Text('Load Banks'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                if (_loading && _banks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),

                if (_banks.isNotEmpty) ...[
                  const Text('Select Bank', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: _banks.length,
                      itemBuilder: (ctx, i) {
                        final bank = _banks[i];
                        final selected = _selectedBankId == bank['id'];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: selected ? const Color(0xFF1a56db) : Colors.grey[200]!, width: selected ? 2 : 1),
                            color: selected ? const Color(0xFF1a56db).withAlpha(12) : null,
                          ),
                          child: ListTile(
                            dense: true,
                            leading: bank['logo'] != null
                                ? Image.network(bank['logo'], width: 28, height: 28, errorBuilder: (_, __, ___) => const Icon(Icons.account_balance, size: 24))
                                : const Icon(Icons.account_balance, size: 24),
                            title: Text(bank['name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                            trailing: selected ? const Icon(Icons.check_circle, color: Color(0xFF1a56db), size: 20) : null,
                            onTap: () => setState(() => _selectedBankId = bank['id']),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ])),
              const SizedBox(height: 16),

              // Payment methods info
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('How it works', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue[800], fontSize: 13)),
                  const SizedBox(height: 6),
                  _infoRow('1', 'Select your bank above'),
                  _infoRow('2', 'Authorize the payment in your banking app'),
                  _infoRow('3', 'Funds arrive in your wallet instantly'),
                ]),
              ),
              const SizedBox(height: 16),

              // Supported payment rails
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Supported Rails', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green[800], fontSize: 13)),
                  const SizedBox(height: 6),
                  _railRow(Icons.flash_on, 'Faster Payments (UK) — instant'),
                  _railRow(Icons.euro, 'SEPA Instant (EU) — seconds'),
                  _railRow(Icons.account_balance, 'SEPA Credit Transfer — same day'),
                  _railRow(Icons.public, 'Open Banking (PSD2) — 6000+ banks'),
                ]),
              ),
            ],

            if (_method == 'card') ...[
              // Card payment via Flutterwave
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.purple[50], borderRadius: BorderRadius.circular(12)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Card Payment', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.purple[800])),
                  const SizedBox(height: 8),
                  _railRow(Icons.credit_card, 'Visa, Mastercard, Amex'),
                  _railRow(Icons.phone_android, 'Mobile Money (M-Pesa, MTN)'),
                  _railRow(Icons.sync, 'USSD'),
                  const SizedBox(height: 8),
                  Text('Powered by Flutterwave', style: TextStyle(fontSize: 11, color: Colors.purple[400])),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            // Top Up button
            GestureDetector(
              onTap: _loading ? null : _topUpViaBank,
              child: Container(
                height: 52, width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: _loading
                    ? [Colors.grey[400]!, Colors.grey[400]!]
                    : [const Color(0xFF1a56db), const Color(0xFF7c3aed)]),
                ),
                child: Center(child: Text(
                  _loading ? 'Processing...' : (_method == 'bank' ? 'Pay via Open Banking' : 'Pay via Card'),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodChip(String label, String value, IconData icon) {
    final selected = _method == value;
    return GestureDetector(
      onTap: () => setState(() => _method = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? const Color(0xFF1a56db) : Colors.grey[300]!, width: selected ? 2 : 1),
          color: selected ? const Color(0xFF1a56db).withAlpha(15) : Colors.white,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 20, color: selected ? const Color(0xFF1a56db) : Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? const Color(0xFF1a56db) : Colors.grey[700])),
        ]),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: child,
    );
  }

  Widget _infoRow(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        CircleAvatar(radius: 10, backgroundColor: Colors.blue[100],
            child: Text(num, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue[700]))),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.blue[700])),
      ]),
    );
  }

  Widget _railRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        Icon(icon, size: 16, color: Colors.green[700]),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(fontSize: 12, color: Colors.green[700]))),
      ]),
    );
  }
}
