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
    // BIAN API expects "username" field — extract username from email
    final username = email.contains('@') ? email.split('@').first : email;
    final data = await ApiClient.post('/auth/login', {
      'username': username,
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
}
