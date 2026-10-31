import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Direct client for the ACTV realtime backend (`oraritemporeale.actv.it`),
/// the same endpoints the web app calls from the browser.
class ActvRealtime {
  ActvRealtime._();

  static const _base = 'https://oraritemporeale.actv.it/aut/backend';

  static final http.Client _client = _createClient();

  static http.Client _createClient() {
    if (kIsWeb) return http.Client();
    final io = HttpClient();
    if (kDebugMode) {
      io.badCertificateCallback = (cert, host, port) => true;
    }
    return IOClient(io);
  }

  static Future<dynamic> rawGet(String path, {Duration? timeout}) async {
    final res =
        await _client.get(Uri.parse('$_base$path')).timeout(timeout ?? const Duration(seconds: 10));
    if (res.statusCode != 200) {
      throw ActvRealtimeException('HTTP ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Full realtime stops catalog (`/page/stops`). Entries have
  /// `name` ("4824-4825-web-aut"), `description` ("Nome [id] [id]"),
  /// `latitude`, `longitude`, `lines` ([{alias, tags, ...}]).
  static Future<List<Map<String, dynamic>>> stopsCatalog() async {
    final data = await rawGet('/page/stops');
    return [
      for (final s in (data as List? ?? []))
        if (s is Map) Map<String, dynamic>.from(s)
    ];
  }

  /// Realtime passages for a merged station id ("4824-4825").
  /// Returns null on network error (distinguishes "no data" from "error").
  static Future<List<Map<String, dynamic>>?> passages(String stationId,
      {Duration timeout = const Duration(milliseconds: 2500)}) async {
    try {
      final data = await rawGet('/passages/$stationId-web-aut', timeout: timeout);
      return [
        for (final p in (data as List? ?? []))
          if (p is Map) Map<String, dynamic>.from(p)
      ];
    } catch (_) {
      return null;
    }
  }

  /// Notice board text for a stop (`/page/{id}-web-aut` → `text`).
  static Future<String?> noticeboard(String stationId) async {
    try {
      final data = await rawGet('/page/$stationId-web-aut');
      if (data is Map && data['text'] != null && '${data['text']}'.isNotEmpty) {
        return '${data['text']}';
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class ActvRealtimeException implements Exception {
  final String message;
  ActvRealtimeException(this.message);
  @override
  String toString() => message;
}
