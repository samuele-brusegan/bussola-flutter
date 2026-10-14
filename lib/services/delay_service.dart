import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// Local delay history, port of the web app's `delayHistory.js`
/// (localStorage → SharedPreferences).
class DelayService {
  DelayService._();

  static const _key = 'delay_history';
  static const _max = 500;

  static Future<List<Map<String, dynamic>>> history() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return [for (final e in jsonDecode(raw) as List) Map<String, dynamic>.from(e)];
    } catch (_) {
      return [];
    }
  }

  static Future<void> record({
    required String line,
    String destination = '',
    String stop = '',
    String stopName = '',
    required int delaySeconds,
  }) async {
    if (line.isEmpty) return;
    final list = await history();
    list.add({
      'line': line,
      'destination': destination,
      'stop': stop,
      'stopName': stopName,
      'delay': delaySeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'hour': DateTime.now().hour,
    });
    final trimmed =
        list.length > _max ? list.sublist(list.length - _max) : list;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(trimmed));
  }

  /// Records observed realtime vehicles.
  static Future<void> recordVehicles(List<Vehicle> vehicles) async {
    for (final v in vehicles) {
      if (v.isRealtime && v.shortName.isNotEmpty && v.delaySeconds != 0) {
        await record(
          line: v.shortName,
          destination: v.headsign,
          delaySeconds: v.delaySeconds,
        );
      }
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

class LineDelayStat {
  final String line;
  final int count;
  final double avgDelay;
  final int maxDelay;

  const LineDelayStat({
    required this.line,
    required this.count,
    required this.avgDelay,
    required this.maxDelay,
  });
}
