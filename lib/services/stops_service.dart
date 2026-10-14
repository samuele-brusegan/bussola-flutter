import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../models/models.dart';

/// Loads and caches the GTFS stop list, provides search and nearby queries.
class StopsService {
  StopsService._();

  static List<Stop>? _cache;

  static Future<List<Stop>> all({bool forceRefresh = false}) async {
    if (_cache != null && !forceRefresh) return _cache!;
    final results = await Future.wait([
      ApiClient.get('/api/stops'),
      ApiClient.get('/api/navigation/stops').catchError((_) => <dynamic>[]),
    ]);
    final stops = <Stop>[
      for (final j in (results[0] as List)) Stop.fromJson(j),
      for (final j in (results[1] as List)) Stop.fromJson(j),
    ];
    _cache = stops;
    return stops;
  }

  /// Groups stops by cleaned name, merging ids of stops that share it
  /// (mirrors the web app's merged station cards).
  static List<StopGroup> grouped(List<Stop> stops) {
    final map = <String, StopGroup>{};
    for (final s in stops) {
      final key = _normalizeName(s.name);
      if (key.isEmpty) continue;
      final group = map.putIfAbsent(
        key,
        () => StopGroup(name: s.name, service: s.service ?? 'automobilistico'),
      );
      if (!group.ids.contains(s.id)) group.ids.add(s.id);
      group.stops.add(s);
    }
    final groups = map.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }

  /// Tokenized search with prefix matching (port of `stopSearchScore`).
  static List<StopGroup> search(List<StopGroup> groups, String query) {
    final tokens = _tokens(query);
    if (tokens.isEmpty) return groups;
    final scored = <(int, StopGroup)>[];
    for (final g in groups) {
      final idHit = g.ids.any((id) => id.contains(query.trim()));
      var score = _score(_tokens(g.name), tokens);
      if (idHit) score = 0;
      if (score != -1) scored.add((score, g));
    }
    scored.sort((a, b) => a.$1.compareTo(b.$1));
    return scored.map((e) => e.$2).toList();
  }

  static List<StopGroup> nearby(
      List<StopGroup> groups, double lat, double lon, {int count = 5}) {
    double dist(StopGroup g) {
      var best = double.infinity;
      for (final s in g.stops) {
        if (s.lat == null || s.lon == null) continue;
        final d = _haversine(lat, lon, s.lat!, s.lon!);
        if (d < best) best = d;
      }
      return best;
    }

    final withDist = groups
        .map((g) => (dist(g), g))
        .where((e) => e.$1.isFinite)
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    return withDist.take(count).map((e) => e.$2).toList();
  }

  static double distanceTo(StopGroup g, double lat, double lon) {
    var best = double.infinity;
    for (final s in g.stops) {
      if (s.lat == null || s.lon == null) continue;
      final d = _haversine(lat, lon, s.lat!, s.lon!);
      if (d < best) best = d;
    }
    return best;
  }

  static String formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m';
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  static Future<Position?> locate() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.medium),
      );
    } catch (_) {
      return null;
    }
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _rad(double d) => d * pi / 180;

  static String _normalizeName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static List<String> _tokens(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r"[’'`.-]"), ' ')
      .replaceAll(RegExp(r'[^a-z0-9àèéìòù\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map((t) => switch (t) {
            'santa' || 'san' => 's',
            _ => t,
          })
      .toList();

  /// -1 = no match.
  static int _score(List<String> nameTokens, List<String> queryTokens) {
    var total = 0;
    for (final q in queryTokens) {
      var best = 1 << 30;
      for (final n in nameTokens) {
        if (n == q) {
          best = 0;
        } else if (n.startsWith(q) || q.startsWith(n)) {
          best = min(best, 1);
        } else if (q.length >= 4 && n.length >= 4) {
          if (_lev(q, n) <= max(1, q.length ~/ 4)) best = min(best, 2);
        }
      }
      if (best == 1 << 30) return -1;
      total += best;
    }
    return total;
  }

  static int _lev(String a, String b) {
    final row = List.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      var prev = row[0];
      row[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final cur = row[j];
        row[j] = min(row[j] + 1,
            min(row[j - 1] + 1, prev + (a[i - 1] == b[j - 1] ? 0 : 1)));
        prev = cur;
      }
    }
    return row[b.length];
  }
}

class StopGroup {
  final String name;
  final String service;
  final List<String> ids = [];
  final List<Stop> stops = [];

  StopGroup({required this.name, required this.service});

  String get idsParam => ids.take(2).join('-');
  Stop get first => stops.first;
  bool get isNavigation => service == 'navigation' || first.mode == 'water';
}

/// Favourite stops stored locally (replaces the web app's cookies).
class FavoritesService {
  FavoritesService._();
  static const _key = 'favorite_stops';

  static Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? []).toSet();
  }

  static Future<void> toggle(StopGroup group) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];
    final id = group.idsParam;
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.add(id);
    }
    await prefs.setStringList(_key, list);
  }

  static Future<bool> isFavorite(String idsParam) async =>
      (await load()).contains(idsParam);
}
