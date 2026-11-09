import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../l10n/l10n_ext.dart';
import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/stop_tile.dart';

/// A route endpoint: a GTFS stop or a geocoded address — same shape the
/// web app stores in `route_origin`/`route_destination`.
class RoutePoint {
  final String type; // 'stop' | 'address'
  final String name;
  final String? id;
  final double? lat;
  final double? lng;
  final String service;

  const RoutePoint({
    required this.type,
    required this.name,
    this.id,
    this.lat,
    this.lng,
    this.service = 'automobilistico',
  });

  factory RoutePoint.fromStop(StopGroup g) => RoutePoint(
        type: 'stop',
        name: g.name,
        id: g.idsParam,
        lat: g.lat,
        lng: g.lon,
        service: g.service,
      );

  factory RoutePoint.fromJson(Map<String, dynamic> j) => RoutePoint(
        type: '${j['type'] ?? 'stop'}',
        name: '${j['name'] ?? ''}',
        id: j['id']?.toString(),
        lat: (j['lat'] is num) ? (j['lat'] as num).toDouble() : double.tryParse('${j['lat']}'),
        lng: (j['lng'] is num) ? (j['lng'] as num).toDouble() : double.tryParse('${j['lng'] ?? j['lon']}'),
        service: '${j['service'] ?? 'automobilistico'}',
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'name': name,
        if (id != null) 'id': id,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'service': service,
      };

  /// `from`/`to` value for `/api/plan-route` (first stop id or "lat,lon").
  /// La API non accetta l'id composto "a-b" dei gruppi: usa `ids[0]` come
  /// la web app.
  String get apiValue =>
      type == 'stop' && id != null ? id!.split('-').first : '$lat,$lng';
}

/// Bottom-sheet station selector — port of `/station-selector`:
/// fuzzy search + Nominatim geocoding + Recenti/Preferite/Tutte sections.
Future<RoutePoint?> showStationSelector(BuildContext context,
    {String type = 'destination'}) {
  return showModalBottomSheet<RoutePoint>(
    context: context,
    isScrollControlled: true,
    showDragHandle: false,
    builder: (_) => _StationSelectorSheet(type: type),
  );
}

class _StationSelectorSheet extends StatefulWidget {
  final String type;
  const _StationSelectorSheet({required this.type});

  @override
  State<_StationSelectorSheet> createState() => _StationSelectorSheetState();
}

class _StationSelectorSheetState extends State<_StationSelectorSheet> {
  List<StopGroup>? _groups;
  Set<String> _favorites = {};
  List<Map<String, dynamic>> _recent = [];
  String _query = '';
  List<Map<String, dynamic>> _geocoded = [];
  Timer? _debounce;
  RoutePoint? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    _favorites = await FavoritesService.loadIdParams();
    _recent = await RecentStopsService.load();
    try {
      final groups = await StopsService.catalog();
      if (mounted) setState(() => _groups = groups);
    } catch (_) {
      if (mounted) setState(() => _groups = []);
    }
  }

  void _onQuery(String q) {
    setState(() => _query = q);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () => _geocode(q));
  }

  /// Nominatim geocoding, viewbox on Venice, bounded, limit 5.
  Future<void> _geocode(String q) async {
    if (q.trim().length < 3) {
      if (mounted) setState(() => _geocoded = []);
      return;
    }
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': q,
        'format': 'json',
        'limit': '5',
        'bounded': '1',
        'viewbox': '12.15,45.65,12.60,45.30',
        'accept-language': Localizations.localeOf(context).languageCode,
      });
      final res = await http.get(uri, headers: {
        'User-Agent': 'bussola-flutter (ACTV Live port)',
      });
      if (!mounted) return;
      final data = jsonDecode(res.body) as List;
      setState(() => _geocoded = [
            for (final e in data)
              if (e is Map)
                {
                  'name': e['display_name'],
                  'lat': e['lat'],
                  'lon': e['lon'],
                }
          ]);
    } catch (_) {}
  }

  StopGroup? _groupById(String idsParam) {
    for (final g in _groups ?? <StopGroup>[]) {
      if (g.idsParam == idsParam || g.allIdsParam == idsParam) return g;
    }
    return null;
  }

  void _select(RoutePoint p) async {
    if (p.type == 'stop') {
      final g = _groupById(p.id ?? '');
      if (g != null) await RecentStopsService.push(g);
    }
    if (mounted) Navigator.pop(context, p);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'origin'
        ? context.l10n.originTitle
        : context.l10n.destinationTitle;
    final groups = _groups;
    final filtered = groups == null
        ? <StopGroup>[]
        : StopsService.search(groups, _query);
    final favGroups = _query.isEmpty
        ? groups
            ?.where((g) => _favorites.any((f) {
                  final ids = g.idsParam.split('-');
                  return f.split('-').any((i) => ids.contains(i));
                }))
            .toList()
        : null;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: context.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.l10n.cancel),
                  ),
                  if (_selected != null)
                    TextButton(
                      onPressed: () => Navigator.pop(context, _selected),
                      child: Text(context.l10n.done),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: context.l10n.searchStopOrAddress,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: _onQuery,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: groups == null
                  ? const LoadingView()
                  : ListView(
                      controller: scrollController,
                      padding:
                          const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        if (_query.isEmpty && _recent.isNotEmpty) ...[
                          _SheetLabel(context.l10n.recentStops),
                          for (final r in _recent)
                            _recentTile(r),
                        ],
                        if (favGroups != null &&
                            favGroups.isNotEmpty) ...[
                          _SheetLabel(context.l10n.favStops),
                          for (final g in favGroups)
                            _stopTile(g),
                        ],
                        if (_geocoded.isNotEmpty) ...[
                          _SheetLabel(context.l10n.addresses),
                          for (final a in _geocoded) _addressTile(a),
                        ],
                        _SheetLabel(context.l10n.allStops),
                        if (filtered.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                                context.l10n.noStationFound,
                                style:
                                    TextStyle(color: context.muted)),
                          )
                        else
                          for (final g in filtered.take(60))
                            _stopTile(g),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentTile(Map<String, dynamic> r) {
    final g = _groupById('${r['id']}');
    if (g == null) return const SizedBox.shrink();
    return _stopTile(g);
  }

  Widget _stopTile(StopGroup g) {
    final selected =
        _selected?.type == 'stop' && _selected?.id == g.idsParam;
    return Container(
      decoration: selected
          ? BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.green, width: 1.5),
            )
          : null,
      child: StopTile(
        group: g,
        onTap: () => _select(RoutePoint.fromStop(g)),
      ),
    );
  }

  Widget _addressTile(Map<String, dynamic> a) {
    final lat = double.tryParse('${a['lat']}');
    final lon = double.tryParse('${a['lon']}');
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: () => _select(RoutePoint(
          type: 'address',
          name: '${a['name']}',
          lat: lat,
          lng: lon)),
      child: Row(
        children: [
          Icon(Icons.place_outlined, color: context.green),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '${a['name']}',
              style: TextStyle(color: context.ink, fontSize: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: SectionLabel(text),
    );
  }
}
