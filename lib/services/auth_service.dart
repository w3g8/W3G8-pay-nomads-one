import 'api_client.dart';

class AuthService {
  Future<Map<String, dynamic>?> getSession() async {
    try {
      final data = await ApiClient.get('/auth/me');
      return data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    // BIAN API accepts username OR email in the "username" field
    final data = await ApiClient.post('/auth/login', {
      'username': email,
      'password': password,
    });
    if (data['token'] != null) {
      await ApiClient.setToken(data['token']);
    }
    return data;
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    final username = email.contains('@') ? email.split('@').first : email;
    final data = await ApiClient.post('/auth/register', {
      'username': username,
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
      if (phone != null) 'phone': phone,
    });
    if (data['token'] != null) {
      await ApiClient.setToken(data['token']);
    }
    return data;
  }

  Future<void> logout() async {
    try {
      await ApiClient.post('/auth/logout', {});
    } catch (_) {}
    await ApiClient.clearToken();
  }

  /// Get SecureVault OIDC authorization URL for SSO login
  Future<String?> getSecureVaultAuthUrl() async {
    try {
      final data = await ApiClient.get('/auth/check-auth-methods');
      return data['oidc_auth_url'] ?? data['auth_url'];
    } catch (_) {
      // Fallback: construct the URL directly
      return 'https://vault.w3g8.com/oauth2/authorize?client_id=nomads&redirect_uri=https://pay.nomads.one/auth/callback&response_type=code&scope=openid+profile+email';
    }
  }

  /// Handle OIDC callback — exchange code for token
  Future<Map<String, dynamic>> handleOIDCCallback(String code) async {
    final data = await ApiClient.post('/auth/oidc/callback', {
      'code': code,
      'redirect_uri': 'https://pay.nomads.one/auth/callback',
    });
    if (data['token'] != null) {
      await ApiClient.setToken(data['token']);
    }
    return data;
  }
}
