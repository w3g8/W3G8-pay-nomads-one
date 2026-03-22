import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/wallet_service.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

enum SendStep { method, amount, confirm, done }

class _SendScreenState extends State<SendScreen> {
  SendStep _step = SendStep.method;
  String _channel = 'email';
  final _addressCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  double _sliderValue = 50;
  int? _selectedAccountId;
  String _currency = 'EUR';
  List<dynamic> _accounts = [];
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _receipt;

  static const channels = [
    ('email', Icons.email, 'Email', 'friend@email.com'),
    ('sms', Icons.sms, 'SMS', '+44 7700 900000'),
    ('whatsapp', Icons.chat, 'WhatsApp', '+44 7700 900000'),
    ('facebook', Icons.facebook, 'Facebook', 'username or URL'),
    ('telegram', Icons.send, 'Telegram', '@username'),
    ('qr', Icons.qr_code, 'SecureVault QR', 'Scan or paste ID'),
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
        final active = _accounts.where((a) => a['status'] == 'active').toList();
        if (active.isNotEmpty) {
          _selectedAccountId = active.first['id'];
          _currency = active.first['currency'] ?? 'EUR';
        }
      }
      setState(() {});
    } catch (_) {}
  }

  Future<void> _send() async {
    if (_selectedAccountId == null || _amountCtrl.text.isEmpty || _addressCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final channel = _channel == 'qr' ? 'email' : _channel; // QR resolves to email
      final result = await WalletService().sendPaymentInvite(
        accountId: _selectedAccountId!,
        amount: double.parse(_amountCtrl.text),
        currency: _currency,
        channel: channel,
        address: _addressCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        message: _messageCtrl.text.trim(),
      );
      setState(() { _receipt = result; _step = SendStep.done; });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _step = SendStep.method;
      _addressCtrl.clear();
      _amountCtrl.clear();
      _messageCtrl.clear();
      _nameCtrl.clear();
      _receipt = null;
      _error = null;
      _sliderValue = 50;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Send Money'),
        leading: _step != SendStep.method
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () {
                setState(() {
                  if (_step == SendStep.done) { _reset(); return; }
                  if (_step == SendStep.confirm) { _step = SendStep.amount; }
                  else if (_step == SendStep.amount) { _step = SendStep.method; }
                });
              })
            : null,
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_step) {
      case SendStep.method: return _buildMethod();
      case SendStep.amount: return _buildAmount();
      case SendStep.confirm: return _buildConfirm();
      case SendStep.done: return _buildDone();
    }
  }

  Widget _buildMethod() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) _errorBanner(),
        const Text('Send via', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ...channels.map((ch) => _channelTile(ch.$1, ch.$2, ch.$3, ch.$4)),
      ],
    );
  }

  Widget _channelTile(String id, IconData icon, String label, String hint) {
    final selected = _channel == id;
    return GestureDetector(
      onTap: () => setState(() => _channel = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? const Color(0xFF1a56db) : Colors.grey[200]!, width: selected ? 2 : 1),
          color: selected ? const Color(0xFF1a56db).withAlpha(12) : Colors.white,
        ),
        child: Row(children: [
          Icon(icon, color: selected ? const Color(0xFF1a56db) : Colors.grey, size: 24),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: selected ? const Color(0xFF1a56db) : null)),
            if (selected) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _addressCtrl,
                decoration: InputDecoration(
                  hintText: hint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
                keyboardType: id == 'email' ? TextInputType.emailAddress : id == 'sms' || id == 'whatsapp' ? TextInputType.phone : TextInputType.text,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  hintText: 'Name (optional)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  isDense: true,
                ),
              ),
            ],
          ])),
          if (selected) const Icon(Icons.check_circle, color: Color(0xFF1a56db), size: 20),
        ]),
      ),
    );
  }

  Widget _buildAmount() {
    final fmt = NumberFormat.currency(symbol: '$_currency ', decimalDigits: 2);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) _errorBanner(),

        // Recipient summary
        _card(child: Row(children: [
          Icon(_getChannelIcon(), color: const Color(0xFF1a56db), size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_nameCtrl.text.isNotEmpty ? _nameCtrl.text : _addressCtrl.text, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('via ${_getChannelLabel()}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
        ])),
        const SizedBox(height: 20),

        // Amount with slider
        _card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Amount', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
              child: DropdownButton<String>(
                value: _currency,
                underline: const SizedBox(),
                items: _accounts.where((a) => a['status'] == 'active').map<DropdownMenuItem<String>>((a) =>
                  DropdownMenuItem(value: a['currency'], child: Text(a['currency'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)))).toSet().toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _currency = v;
                    _selectedAccountId = _accounts.firstWhere((a) => a['currency'] == v && a['status'] == 'active')['id'];
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              decoration: InputDecoration(hintText: '0.00', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              onChanged: (v) {
                final val = double.tryParse(v) ?? 0;
                if (val <= 1000) setState(() => _sliderValue = val);
              },
            )),
          ]),
          const SizedBox(height: 8),
          Slider(
            value: _sliderValue.clamp(0, 1000),
            min: 0, max: 1000, divisions: 100,
            activeColor: const Color(0xFF1a56db),
            label: '$_currency ${_sliderValue.round()}',
            onChanged: (v) => setState(() { _sliderValue = v; _amountCtrl.text = v.round().toString(); }),
          ),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [10, 25, 50, 100, 250].map((a) =>
            ActionChip(label: Text('$_currency $a'), onPressed: () => setState(() { _amountCtrl.text = a.toString(); _sliderValue = a.toDouble(); })),
          ).toList()),
        ])),
        const SizedBox(height: 16),

        // Message
        TextField(
          controller: _messageCtrl,
          decoration: InputDecoration(
            hintText: 'Add a message (optional)',
            prefixIcon: const Icon(Icons.message_outlined),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 24),

        _gradientButton('Review', _amountCtrl.text.isNotEmpty ? () => setState(() => _step = SendStep.confirm) : null),
      ],
    );
  }

  Widget _buildConfirm() {
    final fmt = NumberFormat.currency(symbol: '$_currency ', decimalDigits: 2);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_error != null) _errorBanner(),
        _card(child: Column(children: [
          const Text('Confirm Payment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const Divider(height: 24),
          _detailRow('To', _nameCtrl.text.isNotEmpty ? _nameCtrl.text : _addressCtrl.text),
          _detailRow('Via', _getChannelLabel()),
          _detailRow('Address', _addressCtrl.text),
          if (_messageCtrl.text.isNotEmpty) _detailRow('Message', _messageCtrl.text),
          const Divider(),
          _detailRow('Amount', fmt.format(double.tryParse(_amountCtrl.text) ?? 0), bold: true, fontSize: 18),
        ])),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => setState(() => _step = SendStep.amount), child: const Text('Back'))),
          const SizedBox(width: 12),
          Expanded(child: _gradientButton(_loading ? 'Sending...' : 'Send Now', _loading ? null : _send)),
        ]),
      ],
    );
  }

  Widget _buildDone() {
    final fmt = NumberFormat.currency(symbol: '$_currency ', decimalDigits: 2);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 40),
        const Center(child: CircleAvatar(radius: 36, backgroundColor: Color(0xFFE8F5E9),
            child: Icon(Icons.check_circle, color: Colors.green, size: 40))),
        const SizedBox(height: 16),
        const Center(child: Text('Money Sent!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
        const SizedBox(height: 20),
        _card(child: Column(children: [
          _detailRow('To', _nameCtrl.text.isNotEmpty ? _nameCtrl.text : _addressCtrl.text),
          _detailRow('Via', _getChannelLabel()),
          _detailRow('Amount', fmt.format(double.tryParse(_amountCtrl.text) ?? 0), bold: true),
          _detailRow('Reference', _receipt?['reference'] ?? _receipt?['invite_id']?.toString() ?? ''),
          _detailRow('Status', _receipt?['status'] ?? 'sent'),
        ])),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12)),
          child: Text(
            _channel == 'email'
                ? 'An email has been sent to ${_addressCtrl.text} with a link to claim the payment.'
                : 'A notification has been sent via ${_getChannelLabel()}.',
            style: TextStyle(fontSize: 13, color: Colors.blue[700]),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 24),
        _gradientButton('Done', _reset),
      ],
    );
  }

  IconData _getChannelIcon() {
    return channels.firstWhere((c) => c.$1 == _channel, orElse: () => channels.first).$2;
  }

  String _getChannelLabel() {
    return channels.firstWhere((c) => c.$1 == _channel, orElse: () => channels.first).$3;
  }

  Widget _errorBanner() => Container(
    padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(Icons.error_outline, color: Colors.red[700], size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
      IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => setState(() => _error = null)),
    ]),
  );

  Widget _card({required Widget child}) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[200]!),
      boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _detailRow(String label, String value, {bool bold = false, double fontSize = 14}) {
    if (value.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: fontSize)),
        Flexible(child: Text(value, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.w500, fontSize: fontSize), textAlign: TextAlign.right)),
      ]),
    );
  }

  Widget _gradientButton(String text, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48, width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(colors: onTap == null ? [Colors.grey[400]!, Colors.grey[400]!] : [const Color(0xFF1a56db), const Color(0xFF7c3aed)]),
      ),
      child: Center(child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15))),
    ),
  );
}
