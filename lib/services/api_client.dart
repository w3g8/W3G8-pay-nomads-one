import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // Same backend as pay.nomads.one web app
  static const String baseUrl = 'https://pay.nomads.one/api/v1';
  static const _storage = FlutterSecureStorage();

  static Future<String?> get token async => await _storage.read(key: 'auth_token');

  static Future<void> setToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: 'auth_token');
  }

  static Future<Map<String, String>> _headers() async {
    final t = await token;
    return {
      'Content-Type': 'application/json',
      if (t != null) 'Authorization': 'Bearer $t',
    };
  }

  static Future<dynamic> get(String path) async {
    final resp = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    if (resp.statusCode == 401) throw AuthException('Session expired');
    if (resp.statusCode >= 400) throw ApiException(resp.statusCode, resp.body);
    return jsonDecode(resp.body);
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final resp = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (resp.statusCode == 401) throw AuthException('Session expired');
    if (resp.statusCode >= 400) throw ApiException(resp.statusCode, resp.body);
    return jsonDecode(resp.body);
  }

  static Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final resp = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    if (resp.statusCode == 401) throw AuthException('Session expired');
    if (resp.statusCode >= 400) throw ApiException(resp.statusCode, resp.body);
    return jsonDecode(resp.body);
  }

  static Future<dynamic> delete(String path) async {
    final resp = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: await _headers(),
    );
    if (resp.statusCode == 401) throw AuthException('Session expired');
    if (resp.statusCode >= 400) throw ApiException(resp.statusCode, resp.body);
    if (resp.body.isEmpty) return {};
    return jsonDecode(resp.body);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String body;
  ApiException(this.statusCode, this.body);

  String get message {
    try {
      final decoded = jsonDecode(body);
      return decoded['error'] ?? decoded['message'] ?? 'Request failed ($statusCode)';
    } catch (_) {
      return 'Request failed ($statusCode)';
    }
  }

  @override
  String toString() => message;
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}
