import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/emvco_parser.dart';
import '../services/wallet_service.dart';

class MerchantQRScreen extends StatefulWidget {
  const MerchantQRScreen({super.key});

  @override
  State<MerchantQRScreen> createState() => _MerchantQRScreenState();
}

class _MerchantQRScreenState extends State<MerchantQRScreen> {
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Puerto Princesa');
  final _amountCtrl = TextEditingController();
  String _mcc = '5999';
  String? _accountNumber;
  List<dynamic> _accounts = [];
  String? _qrData;
  bool _includeDeepLink = true;

  final _mccOptions = [
    ('5812', 'Restaurant'),
    ('5814', 'Fast Food'),
    ('5411', 'Grocery'),
    ('5499', 'Convenience Store'),
    ('7011', 'Hotel & Lodging'),
    ('7230', 'Barber & Beauty'),
    ('7297', 'Massage & Spa'),
    ('4121', 'Taxi & Rideshare'),
    ('5999', 'General Retail'),
    ('8999', 'Services'),
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      _accounts = await WalletService().getAccounts();
      setState(() {});
    } catch (_) {}
  }

  void _generate() {
    if (_nameCtrl.text.isEmpty || _accountNumber == null) return;

    final amount = _amountCtrl.text.isNotEmpty ? double.tryParse(_amountCtrl.text) : null;

    final emvco = generateQRPh(
      merchantName: _nameCtrl.text,
      merchantCity: _cityCtrl.text,
      merchantId: _accountNumber!,
      acquirerBIC: 'PNBMPHMM',
      mcc: _mcc,
      amount: amount,
    );

    setState(() {
      _qrData = _includeDeepLink
          ? 'https://pay.nomads.one/pay?qr=${Uri.encodeComponent(emvco)}'
          : emvco;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Merchant QR')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Form
            _section('Business Details', Icons.store, [
              _field('Business Name', _nameCtrl, maxLength: 25),
              _field('City', _cityCtrl, maxLength: 15),
              const SizedBox(height: 8),
              const Text('Receiving Account', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _accountNumber,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                ),
                items: _accounts.where((a) => a['status'] == 'active').map<DropdownMenuItem<String>>((a) =>
                  DropdownMenuItem(value: a['account_number'].toString(),
                      child: Text('${a['name'] ?? a['account_number']} — ${a['currency']}', style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (v) => setState(() => _accountNumber = v),
              ),
              const SizedBox(height: 12),
              const Text('Business Type', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(spacing: 6, runSpacing: 6, children: _mccOptions.map((m) =>
                ChoiceChip(
                  label: Text(m.$2, style: const TextStyle(fontSize: 12)),
                  selected: _mcc == m.$1,
                  onSelected: (_) => setState(() => _mcc = m.$1),
                  selectedColor: const Color(0xFF1a56db).withAlpha(25),
                )).toList()),
              const SizedBox(height: 12),
              _field('Fixed Amount (optional)', _amountCtrl, keyboardType: TextInputType.number, prefix: 'PHP '),
              CheckboxListTile(
                value: _includeDeepLink,
                onChanged: (v) => setState(() => _includeDeepLink = v ?? true),
                title: const Text('Include app download link', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Non-users see a download page', style: TextStyle(fontSize: 11)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ]),

            const SizedBox(height: 16),
            _gradientButton('Generate QR Code', () => _generate(),
                enabled: _nameCtrl.text.isNotEmpty && _accountNumber != null),

            if (_qrData != null) ...[
              const SizedBox(height: 24),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: QrImageView(data: _qrData!, size: 240, version: QrVersions.auto),
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text(_nameCtrl.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
              Center(child: Text('${_cityCtrl.text} — ${mccMap[_mcc] ?? 'Merchant'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
              if (_amountCtrl.text.isNotEmpty)
                Center(child: Text('PHP ${double.tryParse(_amountCtrl.text)?.toStringAsFixed(2) ?? _amountCtrl.text}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1a56db)))),

              // Short code
              if (_accountNumber != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(children: [
                    Text('Short Code', style: TextStyle(fontSize: 11, color: Colors.blue[600])),
                    Text('PAY-${_accountNumber!.substring(_accountNumber!.length > 6 ? _accountNumber!.length - 6 : 0).toUpperCase()}',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue[800], letterSpacing: 2)),
                  ]),
                ),

              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _qrData!));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied!')));
                  },
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Link'),
                )),
                const SizedBox(width: 12),
                Expanded(child: OutlinedButton.icon(
                  onPressed: () {
                    // Share functionality via platform channel
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share via Android share sheet')));
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share'),
                )),
              ]),

              const SizedBox(height: 16),
              _section('How to use', Icons.help_outline, [
                _step(1, 'Print this QR or display at your counter'),
                _step(2, 'Customer scans with Nomads, GCash, Maya, or any QR Ph app'),
                _step(3, 'Payment goes directly to your Nomads account'),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(8)),
                  child: Text('Tip: Share the QR image or payment link on Facebook, Viber, or SMS.',
                      style: TextStyle(fontSize: 12, color: Colors.amber[800])),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 20, color: const Color(0xFF1a56db)),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {int? maxLength, TextInputType? keyboardType, String? prefix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLength: maxLength,
          keyboardType: keyboardType,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            prefixText: prefix,
            counterText: maxLength != null ? '${ctrl.text.length}/$maxLength' : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ]),
    );
  }

  Widget _step(int n, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        CircleAvatar(radius: 12, backgroundColor: Colors.blue[100],
            child: Text('$n', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue[700]))),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ]),
    );
  }

  Widget _gradientButton(String text, VoidCallback onTap, {bool enabled = true}) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48, width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(colors: enabled
              ? [const Color(0xFF1a56db), const Color(0xFF7c3aed)]
              : [Colors.grey[400]!, Colors.grey[400]!]),
        ),
        child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
      ),
    );
  }
}
