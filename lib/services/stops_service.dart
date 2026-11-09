import 'dart:math';

import 'package:geolocator/geolocator.dart';


import '../api/api_client.dart';
import '../models/models.dart';
import '../utils.dart';
import 'actv_realtime.dart';
import 'storage_service.dart';

/// Loads and caches stops, provides search and nearby queries.
///
/// Primary source is the ACTV realtime catalog
/// (`oraritemporeale.actv.it/aut/backend/page/stops`), like the web app;
/// `/api/gtfs-stops` is the offline fallback. Navigation stops come from
/// `/api/navigation/stops`.
class StopsService {
  StopsService._();

  static List<StopGroup>? _catalogCache;
  static List<Stop>? _allCache;

  /// Merged station groups (realtime catalog + navigation).
  static Future<List<StopGroup>> catalog({bool forceRefresh = false}) async {
    if (_catalogCache != null && !forceRefresh) return _catalogCache!;
    final groups = <StopGroup>[];

    List<Map<String, dynamic>> catalog = [];
    try {
      catalog = await ActvRealtime.stopsCatalog();
    } catch (_) {}

    if (catalog.isNotEmpty) {
      groups.addAll(_mergeCatalog(catalog));
    } else {
      // Offline fallback: GTFS stops, dedup by data_url.
      try {
        final res = await ApiClient.get('/api/gtfs-stops', {'return': 'true'});
        final seen = <String>{};
        for (final s in (res as List? ?? [])) {
          if (s is! Map) continue;
          final dataUrl = '${s['data_url'] ?? ''}';
          if (dataUrl.isNotEmpty && !seen.add(dataUrl)) continue;
          groups.add(StopGroup.fromGtfsStop(Map<String, dynamic>.from(s)));
        }
      } catch (_) {}
    }

    // Navigation stops appended as their own section.
    try {
      final nav = await ApiClient.get('/api/navigation/stops');
      groups.addAll(_mergeNavigation((nav as List? ?? [])));
    } catch (_) {}

    _catalogCache = groups;
    return groups;
  }

  /// Merges catalog entries by clean name (description without `[ids]`).
  static List<StopGroup> _mergeCatalog(List<Map<String, dynamic>> catalog) {
    final merged = <String, StopGroup>{};
    for (final station in catalog) {
      final description = '${station['description'] ?? ''}';
      final ids = RegExp(r'\[(\d+)\]')
          .allMatches(description)
          .map((m) => m.group(1)!)
          .toList();
      if (ids.isEmpty) continue;
      final cleanName =
          description.replaceAll(RegExp(r'\[\d+\]'), '').trim();
      final g = merged.putIfAbsent(
        cleanName,
        () => StopGroup(
          name: cleanName,
          service: 'automobilistico',
          realtime: true,
          lat: _d(station['latitude']),
          lon: _d(station['longitude']),
        ),
      );
      for (final id in ids) {
        if (!g.ids.contains(id)) g.ids.add(id);
      }
      final aliases = g.lines.map((l) => l.alias).toList();
      for (final l in (station['lines'] as List? ?? [])) {
        if (l is! Map) continue;
        final alias = '${l['alias'] ?? l['line'] ?? ''}';
        if (alias.isEmpty || aliases.contains(alias)) continue;
        aliases.add(alias);
        g.lines.add(LineAlias(
          alias: alias,
          tags: [
            for (final t in (l['tags'] as List? ?? [])) '$t'
          ],
        ));
      }
    }
    final out = merged.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  static List<StopGroup> _mergeNavigation(List<dynamic> stops) {
    final merged = <String, StopGroup>{};
    for (final s in stops) {
      if (s is! Map) continue;
      final id = '${s['stop_id'] ?? ''}';
      final name = '${s['stop_name'] ?? ''}'.trim();
      if (id.isEmpty || name.isEmpty) continue;
      final key = name.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
      final g = merged.putIfAbsent(
        key,
        () => StopGroup(
          name: name,
          service: 'navigation',
          realtime: true,
          lat: _d(s['stop_lat']),
          lon: _d(s['stop_lon']),
        ),
      );
      if (!g.ids.contains(id)) g.ids.add(id);
      g.lat ??= _d(s['stop_lat']);
      g.lon ??= _d(s['stop_lon']);
    }
    return merged.values.toList();
  }

  /// Flat stop list (`/api/stops` + `/api/navigation/stops`), for pickers
  /// that need individual stop ids and coordinates.
  static Future<List<Stop>> all({bool forceRefresh = false}) async {
    if (_allCache != null && !forceRefresh) return _allCache!;
    final results = await Future.wait([
      ApiClient.get('/api/stops'),
      ApiClient.get('/api/navigation/stops').catchError((_) => <dynamic>[]),
    ]);
    final stops = <Stop>[
      for (final j in (results[0] as List)) Stop.fromJson(j),
      for (final j in (results[1] as List)) Stop.fromJson(j),
    ];
    _allCache = stops;
    return stops;
  }

  /// Groups stops by cleaned name (used by pickers working on flat stops).
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
      group.lat ??= s.lat;
      group.lon ??= s.lon;
    }
    final groups = map.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return groups;
  }

  /// Tokenized fuzzy search (port of `stopSearchScore`), sorted by score.
  static List<StopGroup> search(List<StopGroup> groups, String query) {
    final q = query.trim();
    if (q.isEmpty) return groups;
    final scored = <(double, StopGroup)>[];
    for (final g in groups) {
      final idHit = g.ids.any((id) => id.toLowerCase().contains(q.toLowerCase()));
      var score = _score(_tokens(g.name), _tokens(q));
      if (score == -1 && !idHit) continue;
      if (idHit && score == -1) score = 0;
      scored.add((score.toDouble(), g));
    }
    scored.sort((a, b) => a.$1.compareTo(b.$1));
    return scored.map((e) => e.$2).toList();
  }

  /// First word of each stop name → zone with its stops (zones view).
  static Map<String, List<StopGroup>> zones(List<StopGroup> groups) {
    final map = <String, List<StopGroup>>{};
    final seen = <String>{};
    for (final g in groups) {
      final key = g.name.toUpperCase();
      if (!seen.add(key)) continue;
      final first = g.name.split(RegExp(r'\s+')).first;
      map.putIfAbsent(first.toUpperCase(), () => []).add(g);
    }
    final sorted = Map.fromEntries(map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key)));
    return {for (final e in sorted.entries) e.value.first.name.split(RegExp(r'\s+')).first: e.value};
  }

  static List<StopGroup> nearby(
      List<StopGroup> groups, double lat, double lon, {int count = 5}) {
    final withDist = groups
        .map((g) => (distanceTo(g, lat, lon), g))
        .where((e) => e.$1.isFinite)
        .toList()
      ..sort((a, b) => a.$1.compareTo(b.$1));
    return withDist.take(count).map((e) => e.$2).toList();
  }

  static double distanceTo(StopGroup g, double lat, double lon) {
    var best = double.infinity;
    if (g.lat != null && g.lon != null) {
      best = getDist(lat, lon, g.lat!, g.lon!);
    }
    for (final s in g.stops) {
      if (s.lat == null || s.lon == null) continue;
      final d = getDist(lat, lon, s.lat!, s.lon!);
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
        // forceLocationManager: su Android usa LocationManager invece dei
        // Google Play Services (necessario per il flavor F-Droid, innocuo
        // altrove; i parametri Android-specific sono ignorati su altre OS).
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.medium,
          forceLocationManager: true,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  static String _normalizeName(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static List<String> _tokens(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[àáâãäå]'), 'a')
      .replaceAll(RegExp(r'[èéêë]'), 'e')
      .replaceAll(RegExp(r'[ìíîï]'), 'i')
      .replaceAll(RegExp(r'[òóôõö]'), 'o')
      .replaceAll(RegExp(r'[ùúûü]'), 'u')
      .replaceAll(RegExp(r'[ñ]'), 'n')
      .replaceAll(RegExp(r'[ç]'), 'c')
      .replaceAll(RegExp(r"[’'`.-]"), ' ')
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((t) => t.isNotEmpty)
      .map((t) => switch (t) {
            'santa' || 'san' => 's',
            _ => t,
          })
      .toList();

  /// -1 = no match (exact 0, prefix 1, fuzzy 2+distance — like the web app).
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
          final d = _lev(q, n);
          if (d <= max(1, q.length ~/ 4)) best = min(best, 2 + d);
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

  static double? _d(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

/// A line alias serving a stop (from the realtime catalog).
class LineAlias {
  final String alias;
  final List<String> tags;
  const LineAlias({required this.alias, this.tags = const []});
}

/// A merged station (one or more stop ids sharing the clean name).
class StopGroup {
  final String name;
  final String service;
  final bool realtime;
  double? lat;
  double? lon;
  final List<String> ids = [];
  final List<LineAlias> lines = [];
  final List<Stop> stops = [];

  StopGroup({
    required this.name,
    required this.service,
    this.realtime = false,
    this.lat,
    this.lon,
  });

  /// GTFS-fallback group (single stop, "Servizio non in tempo reale").
  factory StopGroup.fromGtfsStop(Map<String, dynamic> s) {
    final g = StopGroup(
      name: '${s['stop_name'] ?? ''}',
      service: 'automobilistico',
      lat: _d(s['stop_lat']),
      lon: _d(s['stop_lon']),
    );
    final dataUrl = '${s['data_url'] ?? ''}';
    if (dataUrl.isNotEmpty) {
      final parts = dataUrl.split('-');
      g.ids.addAll(parts.sublist(0, max(0, parts.length - 2)));
    } else {
      g.ids.add('${s['stop_id'] ?? ''}');
    }
    g.stops.add(Stop.fromJson(s));
    return g;
  }

  static double? _d(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// `id1-id2` used for the realtime passages endpoint and detail page.
  String get idsParam => ids.take(2).join('-');
  String get allIdsParam => ids.join('-');
  Stop? get first => stops.isEmpty ? null : stops.first;
  bool get isNavigation => service == 'navigation';

  /// `name-web-aut` token used by the realtime backend.
  String get dataUrlToken => '$allIdsParam-web-aut';
}

/// Favourite stops stored locally — same shape as the web app:
/// `[{id, ids[], name}]`.
class FavoritesService {
  FavoritesService._();
  static const _key = Storage.favoriteStops;

  static Future<List<Map<String, dynamic>>> load() async {
    final data = await Storage.getJson(_key, <dynamic>[]);
    if (data is! List) return [];
    return [
      for (final f in data)
        if (f is Map) Map<String, dynamic>.from(f)
        else if (f is String) {'id': f, 'ids': f.split('-'), 'name': ''}
    ];
  }

  /// Set of `id1-id2` params for quick lookup.
  static Future<Set<String>> loadIdParams() async =>
      (await load()).map((f) => '${f['ids'] is List ? (f['ids'] as List).take(2).join('-') : f['id']}').toSet();

  static Future<bool> isFavorite(String stationId) async {
    final currentIds = stationId.split('-');
    return (await load()).any((fav) {
      final favIds = fav['ids'];
      if (favIds is List) {
        return favIds.any((id) => currentIds.contains('$id'));
      }
      return fav['id'] == stationId || currentIds.contains('${fav['id']}');
    });
  }

  static Future<void> toggle(StopGroup group) async {
    var favorites = await load();
    final currentIds = group.idsParam.split('-');
    final isFav = await isFavorite(group.idsParam);
    if (isFav) {
      favorites = favorites.where((fav) {
        final favIds = fav['ids'];
        if (favIds is List) {
          return !favIds.any((id) => currentIds.contains('$id'));
        }
        return fav['id'] != group.idsParam &&
            !currentIds.contains('${fav['id']}');
      }).toList();
    } else {
      favorites.add({
        'id': group.idsParam.split('-').first,
        'ids': group.idsParam.split('-'),
        'name': group.name,
      });
    }
    await Storage.setJson(_key, favorites);
  }
}

/// Recently picked stops (`recent_stops`), max 8, most recent first.
class RecentStopsService {
  RecentStopsService._();
  static const _max = 8;

  static Future<List<Map<String, dynamic>>> load() async {
    final data = await Storage.getJson(Storage.recentStops, <dynamic>[]);
    if (data is! List) return [];
    return [for (final e in data) if (e is Map) Map<String, dynamic>.from(e)];
  }

  static Future<void> push(StopGroup g) async {
    final list = await load();
    list.removeWhere((e) => '${e['id']}' == g.idsParam);
    list.insert(0, {'id': g.idsParam, 'name': g.name, 'service': g.service});
    await Storage.setJson(Storage.recentStops, list.take(_max).toList());
  }
}

/// Saved journeys (`favorite_routes`), like `favoriteRoutes.js`.
class FavoriteRoutesService {
  FavoriteRoutesService._();
  static const _max = 20;

  static Future<List<Map<String, dynamic>>> load() async {
    final data = await Storage.getJson(Storage.favoriteRoutes, <dynamic>[]);
    if (data is! List) return [];
    return [for (final e in data) if (e is Map) Map<String, dynamic>.from(e)];
  }

  static String keyOf(Map<String, dynamic>? origin,
          Map<String, dynamic>? destination) =>
      '${origin?['id'] ?? origin?['name'] ?? ''}=>${destination?['id'] ?? destination?['name'] ?? ''}';

  static Future<bool> isFavorite(Map<String, dynamic>? origin,
      Map<String, dynamic>? destination) async {
    final key = keyOf(origin, destination);
    return (await load()).any((r) => r['key'] == key);
  }

  static Future<bool> toggle(Map<String, dynamic> origin,
      Map<String, dynamic> destination, {String? line}) async {
    final key = keyOf(origin, destination);
    var routes = await load();
    if (routes.any((r) => r['key'] == key)) {
      routes = routes.where((r) => r['key'] != key).toList();
      await Storage.setJson(Storage.favoriteRoutes, routes);
      return false;
    }
    routes.insert(0, {
      'key': key,
      'origin': origin,
      'destination': destination,
      'line': line,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    await Storage.setJson(Storage.favoriteRoutes, routes.take(_max).toList());
    return true;
  }

  static Future<void> remove(String key) async {
    final routes = (await load()).where((r) => r['key'] != key).toList();
    await Storage.setJson(Storage.favoriteRoutes, routes);
  }
}
