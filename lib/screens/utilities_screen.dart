import 'package:flutter/material.dart';
import 'bills_screen.dart';
import 'passport_screen.dart';
import 'visa_screen.dart';

class UtilitiesScreen extends StatelessWidget {
  const UtilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Utilities')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _serviceTile(
            context,
            icon: Icons.receipt_long,
            title: 'Pay Bills',
            subtitle: 'Electric, water, internet, phone, insurance, government...',
            color: Colors.teal,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillsScreen())),
          ),
          const SizedBox(height: 12),
          _serviceTile(
            context,
            icon: Icons.flight,
            title: 'Digital Nomad Visa',
            subtitle: '12 countries — Portugal, Thailand, Indonesia, Colombia...',
            color: Colors.blue,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisaScreen())),
          ),
          const SizedBox(height: 12),
          _serviceTile(
            context,
            icon: Icons.badge,
            title: 'Passport Renewal',
            subtitle: '10 countries — UK, US, Ireland, Australia, Canada...',
            color: Colors.indigo,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PassportScreen())),
          ),
        ],
      ),
    );
  }

  Widget _serviceTile(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required MaterialColor color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ]),
      ),
    );
  }
}
