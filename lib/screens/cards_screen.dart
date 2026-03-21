import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  List<dynamic> _cards = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await WalletService().getCards();
      setState(() { _cards = cards; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cards')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _cards.isEmpty
                  ? ListView(children: [
                      const SizedBox(height: 100),
                      Center(child: Column(children: [
                        Icon(Icons.credit_card_off, size: 48, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('No cards yet', style: TextStyle(color: Colors.grey[500])),
                      ])),
                    ])
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _cards.length,
                      itemBuilder: (ctx, i) => _cardWidget(_cards[i]),
                    ),
            ),
    );
  }

  Widget _cardWidget(dynamic card) {
    final number = card['card_number'] ?? card['last_four'] ?? '****';
    final currency = card['currency'] ?? '';
    final status = card['card_status'] ?? card['status'] ?? '';
    final isActive = status == 'active';
    final type = card['card_type'] ?? card['type'] ?? 'Virtual';
    final balance = card['balance'] ?? card['available_balance'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isActive
              ? [const Color(0xFF1a56db), const Color(0xFF7c3aed)]
              : [Colors.grey[400]!, Colors.grey[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isActive ? const Color(0xFF1a56db) : Colors.grey).withAlpha(60),
            blurRadius: 16, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(type, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                Text(currency, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              '**** **** **** $number',
              style: const TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 3, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('BALANCE', style: TextStyle(color: Colors.white54, fontSize: 10)),
                  Text('$currency ${(balance is num ? balance : 0).toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ]),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : status.toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
