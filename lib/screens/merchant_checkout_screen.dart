import 'dart:async';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/wallet_service.dart';
import '../theme.dart';

/// Merchant checkout screen — ultra-light "enter amount → generate QR" flow.
/// Payment-led merchant acquisition: the payment creates the merchant account.
///
/// UX flow:
///   1. Merchant enters amount + business name + website/FB
///   2. QR generated (EMVCo + deep link)
///   3. Tourist scans with Nomads → pays
///   4. Merchant sees "Payment received! Claim your business"
///
/// Three merchant states: GUEST → CLAIMED → ACTIVE
class MerchantCheckoutScreen extends StatefulWidget {
  const MerchantCheckoutScreen({super.key});

  @override
  State<MerchantCheckoutScreen> createState() => _MerchantCheckoutScreenState();
}

enum CheckoutStep { form, qr, success }

class _MerchantCheckoutScreenState extends State<MerchantCheckoutScreen> {
  CheckoutStep _step = CheckoutStep.form;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  // Checkout state
  String? _checkoutId;
  String? _qrPayload;
  String? _merchantId;
  Map<String, dynamic>? _paymentResult;
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _nameCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _generateCheckout() async {
    final amount = double.tryParse(_amountCtrl.text);
    final name = _nameCtrl.text.trim();
    if (amount == null || amount <= 0 || name.isEmpty) return;

    setState(() { _loading = true; _error = null; });

    try {
      // Create provisional merchant
      final merchant = await WalletService().createProvisionalMerchant(
        businessName: name,
        websiteOrFacebook: _websiteCtrl.text.trim().isNotEmpty ? _websiteCtrl.text.trim() : null,
      );
      _merchantId = merchant['provisional_merchant_id'];

      // Create checkout
      final checkout = await WalletService().createMerchantCheckout(
        provisionalMerchantId: _merchantId!,
        amount: amount,
        currency: 'PHP',
        note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      );

      _checkoutId = checkout['checkout_id'];
      _qrPayload = checkout['qr_payload'] ??
          'https://pay.nomads.one/pay?checkout=${checkout['checkout_id']}';

      setState(() { _step = CheckoutStep.qr; _loading = false; });

      // Start polling for payment
      _startPolling();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_checkoutId == null) return;
      try {
        final status = await WalletService().getMerchantCheckoutStatus(_checkoutId!);
        if (status['status'] == 'paid') {
          _pollTimer?.cancel();
          setState(() {
            _paymentResult = status;
            _step = CheckoutStep.success;
          });
        }
      } catch (_) {}
    });
  }

  void _reset() {
    _pollTimer?.cancel();
    setState(() {
      _step = CheckoutStep.form;
      _amountCtrl.clear();
      _noteCtrl.clear();
      _checkoutId = null;
      _qrPayload = null;
      _paymentResult = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accept Payment'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_error != null) _errorBanner(),
            if (_step == CheckoutStep.form) _buildForm(),
            if (_step == CheckoutStep.qr) _buildQR(),
            if (_step == CheckoutStep.success) _buildSuccess(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final amount = double.tryParse(_amountCtrl.text);
    final canGenerate = (amount != null && amount > 0) && _nameCtrl.text.trim().isNotEmpty;

    return Column(children: [
      // Amount card
      NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.payments, size: 20, color: NomadsColors.primary),
          const SizedBox(width: 8),
          const Text('Payment Amount', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            prefixText: '₱ ',
            prefixStyle: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        // Quick amount buttons
        Row(children: [100, 500, 1000, 2500].map((v) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: OutlinedButton(
              onPressed: () { _amountCtrl.text = '$v'; setState(() {}); },
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
              child: Text('₱$v', style: const TextStyle(fontSize: 12)),
            ),
          ),
        )).toList()),
      ])),

      const SizedBox(height: 12),

      // Details card
      NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.edit_note, size: 20, color: NomadsColors.primary),
          const SizedBox(width: 8),
          const Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 12),
        _field('Note (optional)', _noteCtrl, hint: 'e.g. Dinner for 2', maxLength: 100),
        _field('Business Name', _nameCtrl, hint: 'e.g. Juan\'s Grill', maxLength: 25, required: true),
        _field('Website or Facebook', _websiteCtrl, hint: 'e.g. facebook.com/JuansGrill'),
      ])),

      const SizedBox(height: 16),

      PrimaryButton(
        label: _loading ? 'Creating...' : 'Generate QR Code',
        onTap: canGenerate && !_loading ? _generateCheckout : null,
      ),
      const SizedBox(height: 8),
      Center(child: Text('No registration required for first payment',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
    ]);
  }

  Widget _buildQR() {
    return Column(children: [
      NCard(child: Column(children: [
        Text('Show this to your customer',
            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 12),
        if (_qrPayload != null)
          QrImageView(data: _qrPayload!, size: 220, version: QrVersions.auto),
        const SizedBox(height: 12),
        Text(_nameCtrl.text.trim(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text('₱${(double.tryParse(_amountCtrl.text) ?? 0).toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: NomadsColors.primary)),
        if (_noteCtrl.text.trim().isNotEmpty)
          Text(_noteCtrl.text.trim(),
              style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ])),

      const SizedBox(height: 16),

      // Waiting indicator
      NCard(child: Row(children: [
        SizedBox(width: 24, height: 24,
            child: CircularProgressIndicator(strokeWidth: 2, color: NomadsColors.primary)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Waiting for payment...', style: TextStyle(fontWeight: FontWeight.w500)),
          Text('Customer scans QR with Nomads app',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
        ])),
      ])),

      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: _reset,
        child: const Text('Cancel & New Payment'),
      ),
    ]);
  }

  Widget _buildSuccess() {
    final amount = _paymentResult?['amount'] ?? double.tryParse(_amountCtrl.text) ?? 0;

    return Column(children: [
      const SizedBox(height: 24),
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
        child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
      ),
      const SizedBox(height: 16),
      const Text('Payment Received!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.green)),
      const SizedBox(height: 8),
      Text('₱${(amount is num ? amount.toDouble() : double.tryParse(amount.toString()) ?? 0).toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),

      // Pending notice
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber[50],
          border: Border.all(color: Colors.amber[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.lock, size: 18, color: Colors.amber[800]),
            const SizedBox(width: 8),
            Text('Funds safely held', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.amber[800])),
          ]),
          const SizedBox(height: 8),
          Text('Complete registration to unlock payout to your GCash, Maya, or bank account.',
              style: TextStyle(fontSize: 13, color: Colors.amber[900])),
        ]),
      ),

      const SizedBox(height: 16),

      // Claim button
      Container(
        width: double.infinity, height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF059669)]),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              // Navigate to claim screen
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => _ClaimPlaceholder(merchantId: _merchantId),
              ));
            },
            child: const Center(child: Text('Claim Your Business →',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16))),
          ),
        ),
      ),

      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: _reset,
        child: const Text('Accept Another Payment'),
      ),
    ]);
  }

  Widget _errorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(Icons.error_outline, color: Colors.red[700], size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: () => setState(() => _error = null),
        ),
      ]),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, int? maxLength, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLength: maxLength,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
      ]),
    );
  }
}

/// Placeholder for claim flow — will be replaced by merchant_claim_screen.dart in Phase 2
class _ClaimPlaceholder extends StatelessWidget {
  final String? merchantId;
  const _ClaimPlaceholder({this.merchantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim Your Business')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.store, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('Business Claim', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Merchant ID: ${merchantId ?? "unknown"}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Text('Coming in Phase 2:\n• Phone OTP verification\n• Business details\n• Payout setup',
                textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          ]),
        ),
      ),
    );
  }
}
