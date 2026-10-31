import 'dart:math';
import 'package:flutter/material.dart';

/// Port of the web app's `utils.js`.

/// "HH:MM:SS" or "HH:MM" → seconds since midnight (normalizes 24:xx).
int timeToSec(String? t) {
  if (t == null || t.isEmpty) return 0;
  final p = t.split(':');
  final sec = (int.tryParse(p[0]) ?? 0) * 3600 +
      (int.tryParse(p.length > 1 ? p[1] : '0') ?? 0) * 60 +
      (p.length > 2 ? (int.tryParse(p[2]) ?? 0) : 0);
  return sec % 86400;
}

/// Seconds since midnight → "HH:MM:SS".
String secToTime(int t) {
  final hours = t ~/ 3600;
  final minutes = (t % 3600) ~/ 60;
  final seconds = t % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

/// Haversine distance in meters.
double getDist(double lat1, double lon1, double lat2, double lon2) {
  const r = 6371e3;
  final dLat = (lat2 - lat1) * pi / 180;
  final dLon = (lon2 - lon1) * pi / 180;
  final a = sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * pi / 180) * cos(lat2 * pi / 180) * sin(dLon / 2) * sin(dLon / 2);
  return r * 2 * atan2(sqrt(a), sqrt(1 - a));
}

/// Parses ACTV realtime strings: "HH:MM", "MM min", "MM'" → seconds since
/// midnight (relative times resolved against [now]).
int? parseRealTime(String? rtStr, [DateTime? now]) {
  if (rtStr == null) return null;
  final s = rtStr.trim();
  if (s.contains("'") || s.contains('min')) {
    final minutes = int.tryParse(s.replaceAll(RegExp(r'[^0-9]'), ''));
    if (minutes == null) return null;
    final d = (now ?? DateTime.now()).add(Duration(minutes: minutes));
    return d.hour * 3600 + d.minute * 60 + d.second;
  }
  if (s.contains(':')) return timeToSec('$s:00');
  return null;
}

/// 14 deterministic line colors, same palette as `liveBusMap.js`.
const busColors = [
  '#FF5722', '#2196F3', '#4CAF50', '#9C27B0', '#FF9800', '#00BCD4',
  '#E91E63', '#3F51B5', '#8BC34A', '#FFC107', '#795548', '#607D8B',
  '#F44336', '#009688',
];

Color deterministicColor(String name, {bool colored = true}) {
  if (!colored) return const Color(0xFFAAAAAA);
  var hash = 0;
  for (var i = 0; i < name.length; i++) {
    hash = name.codeUnitAt(i) + ((hash << 5) - hash);
    hash = hash.toSigned(32);
  }
  final hex = busColors[hash.abs() % busColors.length];
  return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
}

/// Filters vehicles by search query (line, trip id, route id, headsign).
bool vehicleMatches(VehicleLike v, String q) {
  if (q.isEmpty) return true;
  final l = q.toLowerCase().trim();
  return v.shortName.toLowerCase().contains(l) ||
      v.tripId.toLowerCase().contains(l) ||
      v.routeId.toLowerCase().contains(l) ||
      v.headsign.toLowerCase().contains(l);
}

abstract class VehicleLike {
  String get shortName;
  String get tripId;
  String get routeId;
  String get headsign;
}
