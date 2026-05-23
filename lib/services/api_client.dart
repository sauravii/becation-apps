import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Shared client untuk Express REST API.
/// Setiap request otomatis attach Firebase ID token sebagai Bearer.
class ApiClient {
  static const String _baseUrl =
      'https://asia-southeast2-becation-eac04.cloudfunctions.net/api';

  static String get baseUrl => _baseUrl;

  static Future<Map<String, String>> _authHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw ApiException(401, 'Not signed in');
    }
    final token = await user.getIdToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static dynamic _decode(http.Response res) {
    if (res.statusCode >= 400) {
      String msg = 'HTTP ${res.statusCode}';
      try {
        final body = jsonDecode(res.body);
        if (body is Map && body['error'] is String) {
          msg = body['error'] as String;
        }
      } catch (_) {}
      throw ApiException(res.statusCode, msg);
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  static Future<dynamic> get(String path) async {
    final headers = await _authHeaders();
    final res = await http.get(Uri.parse('$_baseUrl$path'), headers: headers);
    return _decode(res);
  }

  static Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    final headers = await _authHeaders();
    final res = await http.post(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<dynamic> patch(
      String path, [Map<String, dynamic>? body]) async {
    final headers = await _authHeaders();
    final res = await http.patch(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(res);
  }

  static Future<dynamic> delete(String path) async {
    final headers = await _authHeaders();
    final res = await http.delete(
      Uri.parse('$_baseUrl$path'),
      headers: headers,
    );
    return _decode(res);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}
