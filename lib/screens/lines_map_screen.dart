import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/slim_header.dart';
import '../widgets/service_switch.dart';

/// Port of `/lines-map` (linesMap.js): toolbar with service switch, filter
/// summary + collapsible filters panel (line/trips, show stops), fullscreen
/// map with per-service requests and `cache=1` for the unfiltered view.
class LinesMapScreen extends StatefulWidget {
  const LinesMapScreen({super.key});

  @override
  State<LinesMapScreen> createState() => _LinesMapScreenState();
}

class _LinesMapScreenState extends State<LinesMapScreen> {
  List<LineShape>? _lines;
  Object? _error;
  bool _loading = true;

  String _mode = 'both'; // 'both' | 'automobilistico' | 'navigation'
  String _filterMode = 'line'; // 'line' | 'trips'
  String _query = '';
  bool _showStops = false;
  bool _filtersOpen = false;

  final _queryCtl = TextEditingController();
  String _formMode = 'line';
  bool _formStops = false;

  int _loadToken = 0;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final saved = p.getString('lines_map_service');
      if (saved != null &&
          ['both', 'automobilistico', 'navigation'].contains(saved) &&
          mounted) {
        setState(() => _mode = saved);
        _load();
      }
    });
    _load();
  }

  @override
  void dispose() {
    _queryCtl.dispose();
    super.dispose();
  }

  List<String> get _queryValues => [
        ...{
          for (final v in _query.split(RegExp(r'[,;\n]+')))
            if (v.trim().isNotEmpty) v.trim()
        }
      ];

  List<String> get _activeServices => _mode == 'both'
      ? const ['automobilistico', 'navigation']
      : [_mode];

  /// One request per (service, line) — like `linesMapRequests` in the web app.
  Future<void> _load() async {
    final token = ++_loadToken;
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      final values = _queryValues;
      final out = <LineShape>[];
      for (final service in _activeServices) {
        final requests = <Map<String, String>>[];
        if (_filterMode == 'trips' && values.isNotEmpty) {
          requests.add(
              {'service': service, 'tripIds': values.join(',')});
        } else if (_filterMode == 'line' && values.isNotEmpty) {
          for (final line in values) {
            requests.add({'service': service, 'line': line});
          }
        } else {
          requests.add({
            'service': service,
            if (!_showStops) 'cache': '1',
            if (_showStops) 'showStops': '1',
          });
        }
        for (final q in requests) {
          final res = await ApiClient.get('/api/lines-shapes', q);
          if (token != _loadToken || !mounted) return;
          if (res is List) {
            out.addAll([for (final l in res) LineShape.fromJson(l)]);
          }
        }
      }
      if (token != _loadToken || !mounted) return;
      setState(() {
        _lines = out;
        _loading = false;
      });
    } catch (e) {
      if (mounted && token == _loadToken) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  String get _summary {
    final values = _queryValues;
    final l10n = context.l10n;
    String base;
    if (_filterMode == 'trips' && values.isNotEmpty) {
      base = l10n.lmLineTripsCount(values.length);
    } else if (_filterMode == 'line' && values.isNotEmpty) {
      base = values.length == 1
          ? '${l10n.lmByLine} ${values.join(', ')}'
          : '${l10n.lmLinesLabel} ${values.join(', ')}';
    } else {
      base = l10n.lmAllLines;
    }
    return _showStops ? '$base · ${l10n.lmStopsSuffix}' : base;
  }

  int get _filterCount =>
      (_queryValues.isNotEmpty ? 1 : 0) + (_showStops ? 1 : 0);

  void _applyFilters() {
    setState(() {
      _filterMode = _formMode;
      _query = _queryCtl.text;
      _showStops = _formStops;
      _filtersOpen = false;
    });
    _load();
  }

  void _resetFilters() {
    setState(() {
      _formMode = 'line';
      _queryCtl.text = '';
      _formStops = false;
      _filterMode = 'line';
      _query = '';
      _showStops = false;
      _filtersOpen = false;
    });
    _load();
  }

  Future<void> _setMode(String mode) async {
    setState(() => _mode = mode);
    final p = await SharedPreferences.getInstance();
    await p.setString('lines_map_service', mode);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: Column(
        children: [
          SlimHeader(
            showBack: true,
            title: l10n.moreLinesMap,
          ),
          // Toolbar: service switch + filter summary + filters button.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                ServiceSwitch(mode: _mode, onChanged: _setMode),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _summary,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: context.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _filtersOpen = !_filtersOpen;
                      if (_filtersOpen) {
                        _formMode = _filterMode;
                        _queryCtl.text = _query;
                        _formStops = _showStops;
                      }
                    });
                  },
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(l10n.lmFilters +
                      (_filterCount > 0 ? ' ($_filterCount)' : '')),
                ),
              ],
            ),
          ),
          if (_filtersOpen) _filtersPanel(),
          Expanded(
            child: _error != null && (_lines == null || _lines!.isEmpty)
                ? ErrorView(error: _error!, onRetry: _load)
                : Stack(
                    children: [
                      _buildMap(),
                      if (_loading)
                        Container(
                          color: context.surface.withValues(alpha: 0.55),
                          child: const Center(
                              child: CircularProgressIndicator()),
                        ),
                    ],
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.surface,
              border: Border(top: BorderSide(color: context.border)),
            ),
            child: SafeArea(
              top: false,
              child: Text(
                _loading
                    ? l10n.loading
                    : l10n.pathsOnMap(_lines?.length ?? 0),
                style: TextStyle(color: context.muted, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filtersPanel() {
    final l10n = context.l10n;
    final trips = _formMode == 'trips';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(l10n.lmFilters,
                      style: TextStyle(
                          color: context.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
                InkWell(
                  onTap: () => setState(() => _filtersOpen = false),
                  child: Icon(Icons.close,
                      size: 20, color: context.muted),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SectionLabel(l10n.lmSearchBy),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _formMode,
              decoration: const InputDecoration(isDense: true),
              items: [
                DropdownMenuItem(
                    value: 'line', child: Text(l10n.lmByLine)),
                DropdownMenuItem(
                    value: 'trips', child: Text(l10n.lmByTrip)),
              ],
              onChanged: (v) => setState(() {
                _formMode = v ?? 'line';
                _queryCtl.text = '';
              }),
            ),
            const SizedBox(height: 10),
            SectionLabel(trips ? l10n.lmTripsLabel : l10n.lmLinesLabel),
            const SizedBox(height: 6),
            TextField(
              controller: _queryCtl,
              decoration: InputDecoration(
                hintText: trips ? 'ID corsa, ID corsa…' : '5E, 21',
                isDense: true,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              trips ? l10n.lmTripHelp : l10n.lmQueryHelp,
              style: TextStyle(color: context.muted, fontSize: 12),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.showStops,
                  style: TextStyle(color: context.ink)),
              value: _formStops,
              onChanged: (v) => setState(() => _formStops = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _resetFilters,
                  child: Text(l10n.lmReset),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _applyFilters,
                  child: Text(l10n.lmApply),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    final lines = _lines ?? const <LineShape>[];
    final allPoints = <LatLng>[
      for (final l in lines)
        ...l.shape.map((p) => LatLng(p.lat, p.lng)),
      for (final l in lines)
        if (l.shape.isEmpty)
          ...l.path
              .where((s) => s.lat != null && s.lng != null)
              .map((s) => LatLng(s.lat!, s.lng!)),
    ];

    return FlutterMap(
      options: MapOptions(
        initialCameraFit: allPoints.isNotEmpty
            ? CameraFit.bounds(
                bounds: LatLngBounds.fromPoints(allPoints),
                padding: const EdgeInsets.all(32),
              )
            : null,
        initialCenter: const LatLng(45.485, 12.245),
        initialZoom: 12,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'it.brusegan.bussola',
        ),
        PolylineLayer(
          polylines: [
            for (final l in lines)
              if (l.shape.isNotEmpty)
                Polyline(
                  points: [
                    for (final p in l.shape) LatLng(p.lat, p.lng)
                  ],
                  color: l.color,
                  strokeWidth: 4,
                )
              else if (l.path.length > 1)
                Polyline(
                  points: [
                    for (final s in l.path)
                      if (s.lat != null && s.lng != null)
                        LatLng(s.lat!, s.lng!)
                  ],
                  color: l.color,
                  strokeWidth: 4,
                ),
          ],
        ),
        if (_showStops)
          MarkerLayer(
            markers: [
              for (final l in lines)
                for (final s in l.path)
                  if (s.lat != null && s.lng != null)
                    Marker(
                      point: LatLng(s.lat!, s.lng!),
                      width: 8,
                      height: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: l.color, width: 1.6),
                        ),
                      ),
                    ),
            ],
          ),
      ],
    );
  }
}
