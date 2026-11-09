import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../utils.dart';
import 'actv_realtime.dart';

/// A single passage (realtime or scheduled) shown on the stop page.
/// Mirrors the shape produced by the web app's `stop.js`.
class Passage {
  final Map<String, dynamic> raw;

  Passage(this.raw);

  factory Passage.fromJson(Map<String, dynamic> j) => Passage(Map.of(j));

  String get rawLine => '${raw['line'] ?? ''}';
  String get line => rawLine.split('_').first;
  String? get lineTag {
    final p = rawLine.split('_');
    return p.length > 1 ? p[1] : null;
  }

  String get destination => '${raw['destination'] ?? ''}';
  String get time => '${raw['time'] ?? ''}';
  bool get real => raw['real'] == true;
  String get stop => '${raw['stop'] ?? ''}';
  String? get tripId => raw['trip_id']?.toString();
  String? get gtfsStopId => raw['gtfs_stop_id']?.toString();
  dynamic get lineId => raw['lineId'];
  String get service => '${raw['service'] ?? 'automobilistico'}';
  String get scheduledTime => '${raw['scheduled_time'] ?? ''}';
  double? get stopLat => _num(raw['stop_lat']);
  double? get stopLon => _num(raw['stop_lon']);
  Color? get routeColor => raw['route_color'] == null
      ? null
      : parseColor(raw['route_color'], fallback: const Color(0xFF5B5B5B));
  Color? get routeTextColor => raw['route_text_color'] == null
      ? null
      : parseColor(raw['route_text_color'], fallback: const Color(0xFFFFFFFF));

  // Vehicle enrichment (filled later)
  Map<String, dynamic>? get vehicleInfo =>
      raw['vehicle_info'] as Map<String, dynamic>?;
  double? get vehicleDistanceM => _num(raw['vehicle_distance_m']);
  Map<String, dynamic>? get vehicleProgress =>
      raw['vehicle_progress'] as Map<String, dynamic>?;

  List<Map<String, dynamic>> get timingPoints => [
        for (final t in (raw['timingPoints'] as List? ?? []))
          if (t is Map) Map<String, dynamic>.from(t)
      ];

  static double? _num(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

/// Loads and merges realtime + scheduled + navigation passages for a stop,
/// detects strikes and enriches with live vehicle positions.
/// Port of `stop.js` data flow.
class PassagesService {
  PassagesService._();

  /// Scheduled GTFS passages (next ~2 hours), `/api/gtfs-passages`.
  static Future<List<Passage>> fetchScheduled(String stationId) async {
    try {
      final res = await ApiClient.get(
          '/api/gtfs-passages', {'stop': stationId, 'return': 'true'});
      final list = res is List ? res : <dynamic>[];
      final nextHour =
          DateTime.now().add(const Duration(hours: 2)).toUtc();
      final nextHourStr =
          '${nextHour.hour.toString().padLeft(2, '0')}:${nextHour.minute.toString().padLeft(2, '0')}';
      return [
        for (final p in list)
          if (p is Map &&
              '${p['time'] ?? ''}'.compareTo(nextHourStr) < 0)
            Passage.fromJson(Map<String, dynamic>.from(p))
      ];
    } catch (_) {
      return [];
    }
  }

  /// Navigation passages from `/api/navigation/passages` (always scheduled).
  static Future<List<Passage>> fetchNavigation(String stationId,
      String stopName) async {
    final ids = stationId.split('-').where((s) => s.isNotEmpty).toList();
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    final result = <Passage>[];
    await Future.wait(ids.map((id) async {
      try {
        final data = await ApiClient.get(
            '/api/navigation/passages', {'stop_id': id, 'time': time});
        for (final line in (data as List? ?? [])) {
          if (line is! Map) continue;
          for (final dep in (line['departures'] as List? ?? [])) {
            result.add(Passage({
              'line': '${line['route_short_name'] ?? line['route_id'] ?? '?'}',
              'trip_id': dep['trip_id'],
              'gtfs_stop_id': id,
              'destination': '${dep['destination'] ?? 'Navigazione'}',
              'time': '${dep['time'] ?? ''}',
              'real': false,
              'service': 'navigation',
              'route_color': line['route_color'],
              'route_text_color': line['route_text_color'],
              'stop_lat': line['stop_lat'],
              'stop_lon': line['stop_lon'],
              'stop': stopName.isNotEmpty ? stopName : stationId,
            }));
          }
        }
      } catch (_) {}
    }));
    return result;
  }

  /// Merge realtime + scheduled, assigning GTFS trip_ids to realtime
  /// passages and adding uncovered scheduled runs (port of `mergePassages`).
  static List<Passage> mergePassages(
    List<Passage>? realtime,
    List<Passage> scheduled,
    String stationId, {
    Set<String>? activeTripIds,
  }) {
    final result = [
      for (final p in realtime ?? <Passage>[]) Passage(Map.of(p.raw))
    ];
    final active = activeTripIds ?? <String>{};
    final scheduledByKey = <String, List<Passage>>{};
    for (final p in scheduled) {
      scheduledByKey.putIfAbsent(lineDestKey(p), () => []).add(p);
    }
    final stationStopIds =
        stationId.split('-').where((s) => s.isNotEmpty).toSet();
    final usedTripIds = result
        .map((p) => p.tripId ?? '')
        .where((s) => s.isNotEmpty)
        .toSet();
    final assignedTripIds = <String>{};

    for (final p in result) {
      if (p.tripId != null && p.tripId!.isNotEmpty) {
        assignedTripIds.add(p.tripId!);
        continue;
      }
      var candidates = (scheduledByKey[lineDestKey(p)] ?? <Passage>[])
          .where((c) =>
              c.tripId != null && !usedTripIds.contains(c.tripId))
          .toList();
      final target = passageMinutes(p);
      candidates = candidates.where((c) {
        final d = minutesDistance(passageMinutes(c), target);
        return d != null && d <= 10;
      }).toList();
      final activeCandidates = candidates
          .where((c) => active.contains(c.tripId))
          .toList();
      Passage? candidate;
      if (activeCandidates.isNotEmpty) {
        activeCandidates.sort((a, b) => (passageMinutes(a) ?? 1 << 30)
            .compareTo(passageMinutes(b) ?? 1 << 30));
        candidate = activeCandidates.first;
      } else {
        candidates.sort((a, b) {
          final da = minutesDistance(passageMinutes(a), target) ?? 1 << 30;
          final db = minutesDistance(passageMinutes(b), target) ?? 1 << 30;
          if (da != db) return da.compareTo(db);
          final sa = stationStopIds.contains(
                  '${a.gtfsStopId ?? a.stop}')
              ? 0
              : 1;
          final sb = stationStopIds.contains(
                  '${b.gtfsStopId ?? b.stop}')
              ? 0
              : 1;
          return sa.compareTo(sb);
        });
        candidate = candidates.isEmpty ? null : candidates.first;
      }
      if (candidate != null) {
        usedTripIds.add(candidate.tripId!);
        assignedTripIds.add(candidate.tripId!);
        p.raw['trip_id'] = candidate.tripId;
        p.raw['gtfs_stop_id'] = candidate.gtfsStopId;
        p.raw['stop_lat'] = candidate.raw['stop_lat'];
        p.raw['stop_lon'] = candidate.raw['stop_lon'];
        p.raw['scheduled_time'] = candidate.time;
      }
    }

    const coverTolerance = 10;
    final now = DateTime.now();
    final nowMin = now.hour * 60 + now.minute;
    final added = <String>{};
    for (final p in scheduled) {
      final ld = lineDestKey(p);
      if (p.tripId != null && assignedTripIds.contains(p.tripId)) continue;
      final pMin = passageMinutes(p);
      if (pMin != null) {
        final signedDiff = ((pMin - nowMin + 720) % 1440 + 1440) % 1440 - 720;
        if (signedDiff < -5) continue;
      }
      final covered = result.any((r) =>
          r.real &&
          lineDestKey(r) == ld &&
          (passageMinutes(r) == null ||
              (minutesDistance(passageMinutes(r), pMin) ?? 1 << 30) <=
                  coverTolerance));
      if (covered) continue;

      var time = p.time;
      if (time.contains("'")) {
        final minutes = int.tryParse(time.replaceAll("'", '')) ?? 0;
        final target = DateTime.now().add(Duration(minutes: minutes));
        time =
            '${target.hour.toString().padLeft(2, '0')}:${target.minute.toString().padLeft(2, '0')}';
      }
      final full = '$ld|$time';
      if (!added.add(full)) continue;
      result.add(p);
    }
    return result;
  }

  /// Likely strike: realtime answered OK but empty, ≥2 scheduled, not <5am.
  static bool isLikelyStrike(
      List<Passage>? realtime, List<Passage> scheduled) {
    if (realtime == null || realtime.isNotEmpty) return false;
    if (scheduled.length < 2) return false;
    if (DateTime.now().hour < 5) return false;
    return true;
  }

  /// Cross-check: sample other realtime stops; strike only if all empty.
  static Future<bool> confirmStrikeCrossCheck(String stationId,
      {int sampleSize = 3}) async {
    try {
      final catalog = await ActvRealtime.stopsCatalog();
      final allIds = [
        for (final s in catalog) '${s['name'] ?? ''}'
      ].where((s) => s.isNotEmpty).toList();
      final current = stationId.split('-').where((s) => s.isNotEmpty).toSet();
      final pool = allIds
          .where((id) =>
              !current.contains(id.replaceAll(RegExp(r'-web-aut$'), '')))
          .toList();
      if (pool.isEmpty) return false;
      final step = (pool.length / sampleSize).floor().clamp(1, pool.length);
      final sample = <String>[];
      for (var i = 0; i < pool.length && sample.length < sampleSize; i += step) {
        sample.add(pool[i]);
      }
      final results = await Future.wait(sample.map((id) async {
        try {
          final data = await ActvRealtime.rawGet('/passages/$id',
              timeout: const Duration(milliseconds: 2500));
          return (data as List? ?? []).isEmpty ? 'empty' : 'has';
        } catch (_) {
          return 'error';
        }
      }));
      return results.isNotEmpty && results.every((r) => r == 'empty');
    } catch (_) {
      return false;
    }
  }

  /// Coordinates of the station's sub-stops (`/api/stops?stop=`).
  static Future<List<(double, double)>> fetchStopCoords(
      String stationId) async {
    try {
      final res = await ApiClient.get('/api/stops', {'stop': stationId});
      return [
        for (final s in (res as List? ?? []))
          if (Passage._num(s['stop_lat'] ?? s['lat']) != null &&
              Passage._num(s['stop_lon'] ?? s['lng'] ?? s['lon']) != null)
            (
              Passage._num(s['stop_lat'] ?? s['lat'])!,
              Passage._num(s['stop_lon'] ?? s['lng'] ?? s['lon'])!,
            )
      ];
    } catch (_) {
      return [];
    }
  }

  /// Vehicles for the given trip ids (both services).
  static Future<List<Vehicle>> fetchStopVehicles(
      List<String?> tripIds) async {
    final ids = tripIds
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toSet()
        .join(',');
    if (ids.isEmpty) return [];
    final results = await Future.wait([
      ApiClient.get('/api/realtime/vehicles',
              {'service': 'automobilistico', 'tripIds': ids})
          .then((res) => (res as Map)['vehicles'] as List? ?? [])
          .catchError((_) => <dynamic>[]),
      ApiClient.get('/api/navigation/vehicles', {'tripIds': ids})
          .then((res) => res is List ? res : <dynamic>[])
          .catchError((_) => <dynamic>[]),
    ]);
    return [
      for (final list in results)
        for (final v in list)
          if (v is Map) Vehicle.fromJson(Map<String, dynamic>.from(v))
    ];
  }

  /// Attaches vehicle position/distance to passages (mutates `raw`).
  static void attachVehicles(
      List<Passage> passages, List<Vehicle> vehicles,
      {List<(double, double)> stationCoords = const []}) {
    final byTrip = {
      for (final v in vehicles)
        if (v.tripId.isNotEmpty && v.lat != null) v.tripId: v
    };
    for (final p in passages) {
      final v = byTrip[p.tripId ?? ''];
      if (v == null) continue;
      p.raw['vehicle_info'] = {'lat': v.lat, 'lon': v.lon};
      var d = (p.stopLat != null && p.stopLon != null)
          ? getDist(v.lat!, v.lon!, p.stopLat!, p.stopLon!)
          : null;
      d ??= stationCoords.isEmpty
          ? null
          : stationCoords
              .map((c) => getDist(v.lat!, v.lon!, c.$1, c.$2))
              .reduce((a, b) => a < b ? a : b);
      p.raw['vehicle_distance_m'] = d;
    }
  }

  /// Loads shapes for the passage trips and computes progress
  /// (stops to boarding / already passed).
  static Future<void> enrichProgress(List<Passage> passages) async {
    final groups = <String, Set<String>>{};
    for (final p in passages) {
      if (p.vehicleInfo == null || p.tripId == null) continue;
      final service = p.service == 'navigation' ? 'navigation' : 'automobilistico';
      groups.putIfAbsent(service, () => {}).add(p.tripId!);
    }
    if (groups.isEmpty) return;
    final shapes = <Map<String, dynamic>>[];
    await Future.wait(groups.entries.map((e) async {
      try {
        final q = {'tripIds': e.value.join(','), 'cache': '1'};
        if (e.key == 'navigation') q['service'] = 'navigation';
        final res = await ApiClient.get('/api/lines-shapes', q);
        for (final s in (res as List? ?? [])) {
          if (s is Map) shapes.add(Map<String, dynamic>.from(s));
        }
      } catch (_) {}
    }));
    final byTrip = {
      for (final s in shapes) '${s['trip_id'] ?? ''}': s
    };
    for (final p in passages) {
      p.raw['vehicle_progress'] =
          _progress(p, byTrip[p.tripId ?? '']);
    }
  }

  static Map<String, dynamic>? _progress(
      Passage p, Map<String, dynamic>? shape) {
    final stops = (shape?['stops'] as List? ?? shape?['path'] as List? ?? []);
    if (p.vehicleInfo == null) return null;
    final boarding = stops.indexWhere((s) =>
        '${s['id'] ?? s['stop_id']}' == '${p.gtfsStopId}');
    if (boarding < 0) return null;
    var nearest = -1;
    var nearestD = double.infinity;
    final vLat = Passage._num(p.vehicleInfo!['lat']);
    final vLon = Passage._num(p.vehicleInfo!['lon']);
    if (vLat == null || vLon == null) return null;
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      final lat = Passage._num(s['lat'] ?? s['stop_lat']);
      final lon = Passage._num(s['lng'] ?? s['lon'] ?? s['stop_lon']);
      if (lat == null || lon == null) continue;
      final d = getDist(vLat, vLon, lat, lon);
      if (d < nearestD) {
        nearestD = d;
        nearest = i;
      }
    }
    if (nearest < 0) return null;
    final bs = stops[boarding];
    final bLat = Passage._num(bs['lat'] ?? bs['stop_lat']);
    final bLon = Passage._num(bs['lng'] ?? bs['lon'] ?? bs['stop_lon']);
    final boardingD = (bLat != null && bLon != null)
        ? getDist(vLat, vLon, bLat, bLon)
        : null;
    return {
      'stopsToBoarding': boarding - nearest,
      'boardingPassed':
          nearest > boarding && (boardingD ?? 0) > 150,
    };
  }

  /// Normalizes a destination for realtime↔scheduled matching.
  static String normalizeDestination(String dest) {
    return dest
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '')
        .replaceAll(RegExp(r'\s+[a-z]\d+$'), '')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static String lineDestKey(Passage p) =>
      '${p.line.toUpperCase()}|${normalizeDestination(p.destination)}';

  /// Minutes of day for a passage time ("24:15" → 75, "8'" → now+8,
  /// "departure" → now).
  static int? passageMinutes(Passage p) {
    final time = p.time;
    if (time == 'departure') {
      final n = DateTime.now();
      return n.hour * 60 + n.minute;
    }
    final rel = RegExp(r"^\s*(\d+)\s*'\s*$").firstMatch(time);
    if (rel != null) {
      final target =
          DateTime.now().add(Duration(minutes: int.parse(rel.group(1)!)));
      return target.hour * 60 + target.minute;
    }
    final parts = time.split(':').map(int.tryParse).toList();
    if (parts.isEmpty || parts[0] == null ||
        (parts.length > 1 && parts[1] == null)) {
      return null;
    }
    return (parts[0]! * 60 + (parts.length > 1 ? parts[1]! : 0)) % 1440;
  }

  /// Circular distance in minutes over a 24h clock.
  static int? minutesDistance(int? a, int? b) {
    if (a == null || b == null) return null;
    final d = (a - b).abs() % 1440;
    return d < 1440 - d ? d : 1440 - d;
  }

  /// Label for the vehicle distance ("a 350 m" / "a 1,2 km").
  static String vehicleLabel(double? meters,
      {String detected = 'Posizione rilevata', String at = 'a'}) {
    if (meters == null || !meters.isFinite) return detected;
    if (meters < 950) {
      return '$at ${(meters / 10).round().clamp(1, 100000) * 10} m';
    }
    return '$at ${(meters / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
  }
}
