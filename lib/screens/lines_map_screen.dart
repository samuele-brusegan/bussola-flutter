import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/line_badge.dart';

class LinesMapScreen extends StatefulWidget {
  const LinesMapScreen({super.key});

  @override
  State<LinesMapScreen> createState() => _LinesMapScreenState();
}

class _LinesMapScreenState extends State<LinesMapScreen> {
  List<LineShape>? _lines;
  Object? _error;
  String? _selected;
  String _service = 'automobilistico';
  bool _showStops = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({String? line}) async {
    setState(() {
      _error = null;
      if (line != _selected) _lines = null;
      _selected = line;
    });
    try {
      final q = <String, String>{'service': _service};
      if (line != null) q['line'] = line;
      final res = await ApiClient.get('/api/lines-shapes', q);
      if (!mounted) return;
      setState(() => _lines = [
            for (final l in (res as List)) LineShape.fromJson(l)
          ]);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            showBack: true,
            title: 'Mappa linee',
            subtitle:
                '${_lines?.length ?? 0} percorsi sulla mappa',
          ),
          Expanded(
            child: _error != null
                ? ErrorView(error: _error!, onRetry: () => _load(line: _selected))
                : _lines == null
                    ? const LoadingView()
                    : _buildMap(),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final lines = _lines!;
    final allPoints = <LatLng>[
      for (final l in lines)
        ...l.shape.map((p) => LatLng(p.lat, p.lng)),
      for (final l in lines)
        if (l.shape.isEmpty)
          ...l.path
              .where((s) => s.lat != null && s.lng != null)
              .map((s) => LatLng(s.lat!, s.lng!)),
    ];

    return Column(
      children: [
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              for (final (v, l) in [
                ('automobilistico', 'Autobus'),
                ('navigation', 'Vaporetti'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l),
                    selected: _service == v,
                    onSelected: (_) {
                      _service = v;
                      _load(line: _selected);
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: const Text('Mostra le fermate'),
                  selected: _showStops,
                  onSelected: (v) => setState(() => _showStops = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Tutte'),
                  selected: _selected == null,
                  onSelected: (_) => _load(),
                ),
              ),
              for (final l in lines.take(40))
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l.shortName),
                    selected: _selected == l.shortName,
                    onSelected: (_) => _load(line: l.shortName),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: FlutterMap(
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
              if (_showStops) MarkerLayer(
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
                              border:
                                  Border.all(color: l.color, width: 1.6),
                            ),
                          ),
                        ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            children: [
              for (final l in lines)
                AppCard(
                  margin: const EdgeInsets.only(right: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      LineBadge(
                          label: l.shortName.isEmpty ? '?' : l.shortName,
                          color: l.color),
                      const SizedBox(width: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          l.longName,
                          style: TextStyle(
                              color: context.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
