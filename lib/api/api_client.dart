import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP client for the existing PHP API (`/api/*`).
class ApiClient {
  ApiClient._();

  static const String defaultBaseUrl = 'https://actv-live.test';
  static const String _prefKey = 'api_base_url';

  static String _baseUrl = defaultBaseUrl;
  static String get baseUrl => _baseUrl;

  /// Trusts self-signed certificates in debug builds so the local
  /// `actv-live.test` virtual host works.
  static final http.Client _client = _createClient();

  static http.Client _createClient() {
    if (kIsWeb) return http.Client();
    final io = HttpClient();
    if (kDebugMode) {
      io.badCertificateCallback = (cert, host, port) => true;
    }
    return IOClient(io);
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_prefKey) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _baseUrl);
  }

  static Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$_baseUrl$path').replace(queryParameters: query);

  /// GET expecting a JSON object or array. Throws [ApiException] on errors.
  static Future<dynamic> get(String path, [Map<String, String>? query]) async {
    final res = await _client.get(_uri(path, query)).timeout(
          const Duration(seconds: 20),
        );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}', statusCode: res.statusCode);
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(_uri(path),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body))
        .timeout(const Duration(seconds: 20));
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException('HTTP ${res.statusCode}', statusCode: res.statusCode);
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
