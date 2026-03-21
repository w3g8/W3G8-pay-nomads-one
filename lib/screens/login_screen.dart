import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _ssoLoading = false;
  String? _error;
  bool _showEmailLogin = false;

  Future<void> _login() async {
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().login(_emailCtrl.text.trim(), _passCtrl.text);
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithSecureVault() async {
    setState(() { _ssoLoading = true; _error = null; });
    try {
      final authUrl = await AuthService().getSecureVaultAuthUrl();
      if (authUrl != null) {
        final uri = Uri.parse(authUrl);
        if (kIsWeb) {
          // On web, redirect in same window
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        } else {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } else {
        setState(() => _error = 'SecureVault SSO not available');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _ssoLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1a56db), Color(0xFF7c3aed)],
                    ),
                  ),
                  child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                Text('Pay Nomads', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Sign in to your wallet', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 32),

                // Error
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
                    ]),
                  ),

                // SecureVault SSO button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton(
                    onPressed: _ssoLoading ? null : _loginWithSecureVault,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF1a56db), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _ssoLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Container(
                              width: 24, height: 24,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                gradient: const LinearGradient(colors: [Color(0xFF10b981), Color(0xFF059669)]),
                              ),
                              child: const Icon(Icons.shield, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 10),
                            const Text('Sign in with SecureVault', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                          ]),
                  ),
                ),
                const SizedBox(height: 12),

                // Google SSO button
                SizedBox(
                  width: double.infinity, height: 52,
                  child: OutlinedButton(
                    onPressed: () {
                      // Google SSO goes through SecureVault as identity broker
                      _loginWithSecureVault();
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[300]!, width: 1),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      // Google "G" icon
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.white,
                        ),
                        child: Center(child: Text('G', style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          foreground: Paint()..shader = const LinearGradient(
                            colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335)],
                          ).createShader(const Rect.fromLTWH(0, 0, 24, 24)),
                        ))),
                      ),
                      const SizedBox(width: 10),
                      Text('Sign in with Google', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // Divider
                Row(children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('or', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ]),

                const SizedBox(height: 20),

                // Email/password toggle
                if (!_showEmailLogin)
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: TextButton(
                      onPressed: () => setState(() => _showEmailLogin = true),
                      child: Text('Sign in with email & password', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    ),
                  ),

                if (_showEmailLogin) ...[
                  TextField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passCtrl,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    obscureText: true,
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1a56db),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Sign up link
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text("Don't have an account? ", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  GestureDetector(
                    onTap: () {
                      // Sign up via SecureVault
                      _loginWithSecureVault();
                    },
                    child: const Text('Sign up', style: TextStyle(color: Color(0xFF1a56db), fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ]),

                const SizedBox(height: 16),
                Text('nomads.one', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
