import 'dart:async';
import 'package:flutter/material.dart';
import '../services/wallet_service.dart';
import '../theme.dart';

/// Merchant claim flow — Phase 2
/// After first payment, merchant claims their business:
///   1. Enter phone number → receive OTP
///   2. Verify OTP → profile claimed
///   3. Enter business details (legal entity, payout info)
///   4. Submit for review → unlock payout when approved
class MerchantClaimScreen extends StatefulWidget {
  final String? merchantId;
  const MerchantClaimScreen({super.key, this.merchantId});

  @override
  State<MerchantClaimScreen> createState() => _MerchantClaimScreenState();
}

enum ClaimStep { phone, otp, details, submitted }

class _MerchantClaimScreenState extends State<MerchantClaimScreen> {
  ClaimStep _step = ClaimStep.phone;
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _legalNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _payoutMethodCtrl = TextEditingController(text: 'GCash');
  final _payoutAccountCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  int _otpCountdown = 0;
  Timer? _otpTimer;

  @override
  void dispose() {
    _otpTimer?.cancel();
    for (final c in [_phoneCtrl, _otpCtrl, _emailCtrl, _legalNameCtrl, _ownerNameCtrl, _payoutMethodCtrl, _payoutAccountCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (_phoneCtrl.text.trim().length < 10) {
      setState(() => _error = 'Enter a valid phone number');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      // TODO: Call /merchant/send-otp endpoint (via md-mail-sms SMS service)
      // For now, simulate OTP sent
      await Future.delayed(const Duration(seconds: 1));
      setState(() {
        _step = ClaimStep.otp;
        _loading = false;
        _otpCountdown = 60;
      });
      _startOTPTimer();
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _startOTPTimer() {
    _otpTimer?.cancel();
    _otpTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_otpCountdown <= 0) {
        _otpTimer?.cancel();
      } else {
        setState(() => _otpCountdown--);
      }
    });
  }

  Future<void> _verifyOTP() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await WalletService().claimMerchant(
        provisionalMerchantId: widget.merchantId ?? '',
        mobile: _phoneCtrl.text.trim(),
        otpCode: _otpCtrl.text.trim(),
        email: _emailCtrl.text.trim().isNotEmpty ? _emailCtrl.text.trim() : null,
      );
      setState(() { _step = ClaimStep.details; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _submitDetails() async {
    setState(() { _loading = true; _error = null; });
    try {
      await WalletService().completeMerchantOnboarding(
        merchantId: widget.merchantId ?? '',
        details: {
          'legal_name': _legalNameCtrl.text.trim(),
          'owner_name': _ownerNameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'payout_method': _payoutMethodCtrl.text.trim(),
          'payout_account': _payoutAccountCtrl.text.trim(),
        },
      );
      setState(() { _step = ClaimStep.submitted; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Claim Your Business')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Progress indicator
            _progressBar(),
            const SizedBox(height: 20),

            if (_error != null) _errorBanner(),

            if (_step == ClaimStep.phone) _buildPhoneStep(),
            if (_step == ClaimStep.otp) _buildOTPStep(),
            if (_step == ClaimStep.details) _buildDetailsStep(),
            if (_step == ClaimStep.submitted) _buildSubmittedStep(),
          ],
        ),
      ),
    );
  }

  Widget _progressBar() {
    final steps = ['Phone', 'Verify', 'Details', 'Done'];
    final currentIdx = ClaimStep.values.indexOf(_step);

    return Row(children: List.generate(steps.length, (i) {
      final isActive = i <= currentIdx;
      final isLast = i == steps.length - 1;
      return Expanded(
        child: Row(children: [
          Expanded(
            child: Column(children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? NomadsColors.primary : Colors.grey[300],
                ),
                child: Center(child: Text('${i + 1}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: isActive ? Colors.white : Colors.grey[600]))),
              ),
              const SizedBox(height: 4),
              Text(steps[i], style: TextStyle(fontSize: 10,
                  color: isActive ? NomadsColors.primary : Colors.grey[500])),
            ]),
          ),
          if (!isLast) Expanded(child: Container(height: 2,
              color: i < currentIdx ? NomadsColors.primary : Colors.grey[300])),
        ]),
      );
    }));
  }

  Widget _buildPhoneStep() {
    return Column(children: [
      NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Verify your phone number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('We\'ll send a 6-digit code to verify your business.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 16),
        const Text('Phone Number', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixText: '+63 ',
            hintText: '917 123 4567',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Email (optional)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            hintText: 'your@email.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ])),
      const SizedBox(height: 16),
      PrimaryButton(
        label: _loading ? 'Sending...' : 'Send Verification Code',
        onTap: _loading ? null : _sendOTP,
        loading: _loading,
      ),
    ]);
  }

  Widget _buildOTPStep() {
    return Column(children: [
      NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Enter verification code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Sent to +63 ${_phoneCtrl.text}',
            style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        const SizedBox(height: 16),
        TextField(
          controller: _otpCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 8),
          decoration: InputDecoration(
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        if (_otpCountdown > 0) ...[
          const SizedBox(height: 8),
          Center(child: Text('Resend in ${_otpCountdown}s',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]))),
        ] else ...[
          const SizedBox(height: 8),
          Center(child: TextButton(
            onPressed: _sendOTP,
            child: const Text('Resend Code'),
          )),
        ],
      ])),
      const SizedBox(height: 16),
      PrimaryButton(
        label: _loading ? 'Verifying...' : 'Verify',
        onTap: _loading ? null : _verifyOTP,
        loading: _loading,
      ),
    ]);
  }

  Widget _buildDetailsStep() {
    return Column(children: [
      NCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          const Text('Phone verified!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 16),
        const Text('Complete your business profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        _field('Legal Business Name', _legalNameCtrl, hint: 'e.g. Juan\'s Beach Grill'),
        _field('Owner Full Name', _ownerNameCtrl, hint: 'e.g. Juan Dela Cruz'),
        const Text('Payout Method', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _payoutMethodCtrl.text,
          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: ['GCash', 'Maya', 'BDO', 'BPI', 'UnionBank', 'PNB'].map((m) =>
            DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) => _payoutMethodCtrl.text = v ?? 'GCash',
        ),
        const SizedBox(height: 12),
        _field('Payout Account Number', _payoutAccountCtrl, hint: 'e.g. 0917 123 4567', keyboard: TextInputType.number),
      ])),
      const SizedBox(height: 16),
      PrimaryButton(
        label: _loading ? 'Submitting...' : 'Submit for Review',
        onTap: _loading ? null : _submitDetails,
        loading: _loading,
      ),
    ]);
  }

  Widget _buildSubmittedStep() {
    return Column(children: [
      const SizedBox(height: 32),
      Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
        child: const Icon(Icons.check_circle, color: Colors.green, size: 48),
      ),
      const SizedBox(height: 16),
      const Text('Business Claimed!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Text('Your profile is under review. We\'ll notify you when payout is unlocked.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      const SizedBox(height: 24),
      NCard(child: Column(children: [
        DetailRow(label: 'Business', value: _legalNameCtrl.text),
        DetailRow(label: 'Owner', value: _ownerNameCtrl.text),
        DetailRow(label: 'Phone', value: '+63 ${_phoneCtrl.text}'),
        DetailRow(label: 'Payout', value: '${_payoutMethodCtrl.text} — ${_payoutAccountCtrl.text}'),
        DetailRow(label: 'Status', value: 'Under Review'),
      ])),
      const SizedBox(height: 16),
      PrimaryButton(
        label: 'Go to Merchant Dashboard',
        onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
      ),
    ]);
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboard}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ]),
    );
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
        IconButton(icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _error = null)),
      ]),
    );
  }
}
