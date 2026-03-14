import 'api_client.dart';

class AuthService {
  Future<Map<String, dynamic>?> getSession() async {
    try {
      final data = await ApiClient.authGet('/v1/session');
      return data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await ApiClient.authPost('/v1/auth/login', {
      'email': email,
      'password': password,
    });
    if (data['token'] != null) {
      await ApiClient.setToken(data['token']);
    }
    return data;
  }

  Future<void> logout() async {
    try {
      await ApiClient.authPost('/v1/logout', {});
    } catch (_) {}
    await ApiClient.clearToken();
  }
}
