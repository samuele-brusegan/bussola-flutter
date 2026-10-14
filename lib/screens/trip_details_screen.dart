import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';

class TripDetailsScreen extends StatefulWidget {
  final String tripId;
  const TripDetailsScreen({super.key, required this.tripId});

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  List<TripStop>? _stops;
  List<ShapePoint> _shape = [];
  Object? _error;
  LatLng? _vehiclePos;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final res = await ApiClient.get(
          '/api/bus-position', {'tripId': widget.tripId});
      if (res is Map && res['stops'] is List) {
        _stops = [
          for (final s in (res['stops'] as List)) TripStop.fromJson(s)
        ];
        _shape = [
          for (final p in ((res['shape'] as List?) ?? []))
            ShapePoint.fromJson(p)
        ];
      } else {
        throw ApiException(
            res is Map ? '${res['error'] ?? 'Corsa non trovata'}' : 'Errore');
      }
      // Realtime position (best effort).
      try {
        final rt = await ApiClient.get('/api/realtime/vehicles', {
          'service': 'automobilistico',
          'tripId': widget.tripId,
        });
        final vehicles = (rt as Map)['vehicles'] as List? ?? [];
        if (vehicles.isNotEmpty) {
          final v = Vehicle.fromJson(vehicles.first);
          if (v.lat != null) _vehiclePos = LatLng(v.lat!, v.lon!);
        }
      } catch (_) {}
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMap = _shape.isNotEmpty ||
        (_stops?.any((s) => s.lat != null && s.lng != null) ?? false);
    final points = _shape.isNotEmpty
        ? _shape.map((p) => LatLng(p.lat, p.lng)).toList()
        : [
            for (final s in _stops ?? <TripStop>[])
              if (s.lat != null && s.lng != null) LatLng(s.lat!, s.lng!)
          ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(showBack: true, title: 'Dettaglio corsa'),
          ),
          if (_error != null)
            SliverFillRemaining(
              child: ErrorView(error: _error!, onRetry: _load),
            )
          else if (_stops == null)
            const SliverFillRemaining(child: LoadingView())
          else ...[
            if (hasMap)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    child: SizedBox(
                      height: 260,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCameraFit: points.length > 1
                              ? CameraFit.bounds(
                                  bounds: LatLngBounds.fromPoints(points),
                                  padding: const EdgeInsets.all(24),
                                )
                              : null,
                          initialCenter:
                              points.isNotEmpty ? points.first : LatLng(45.485, 12.245),
                          initialZoom: 12,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'it.brusegan.bussola',
                          ),
                          if (points.length > 1)
                            PolylineLayer(polylines: [
                              Polyline(
                                points: points,
                                color: context.blue,
                                strokeWidth: 4,
                              ),
                            ]),
                          MarkerLayer(markers: [
                            for (final s in _stops!)
                              if (s.lat != null && s.lng != null)
                                Marker(
                                  point: LatLng(s.lat!, s.lng!),
                                  width: 10,
                                  height: 10,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: context.surface,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: context.blue, width: 2),
                                    ),
                                  ),
                                ),
                            if (_vehiclePos != null)
                              Marker(
                                point: _vehiclePos!,
                                width: 30,
                                height: 30,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.green,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(Icons.directions_bus,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SectionTitle('Fermate (${_stops!.length})'),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _StopRow(
                    stop: _stops![i],
                    isFirst: i == 0,
                    isLast: i == _stops!.length - 1,
                  ),
                  childCount: _stops!.length,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  final TripStop stop;
  final bool isFirst;
  final bool isLast;

  const _StopRow({
    required this.stop,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final time = stop.departureTime ?? stop.arrivalTime ?? stop.time ?? '';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              time.length >= 5 ? time.substring(0, 5) : time,
              style: TextStyle(
                color: context.ink,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isFirst || isLast ? context.green : context.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.green, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 2, color: context.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                stop.name,
                style: TextStyle(
                  color: context.ink,
                  fontWeight:
                      isFirst || isLast ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
