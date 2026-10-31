import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../services/line_colors.dart';
import '../theme/app_theme.dart';
import '../utils.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/line_badge.dart';

/// Port of `/trip-details` (tripDetails.js): header badge + direction,
/// countdown + delay, stop timeline with passed/next states, fullscreen
/// map with realtime vehicle position and nearby vehicles.
class TripDetailsScreen extends StatefulWidget {
  final String tripId;
  final String? stopId;
  final String? line;
  final String? dest;
  final String? time;
  final bool realtime;
  final String? contextStop;

  const TripDetailsScreen({
    super.key,
    required this.tripId,
    this.stopId,
    this.line,
    this.dest,
    this.time,
    this.realtime = false,
    this.contextStop,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  List<TripStop>? _stops;
  List<ShapePoint> _shape = [];
  Object? _error;
  LatLng? _vehiclePos;
  Vehicle? _vehicle;
  List<Vehicle> _nearby = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(
        const Duration(seconds: 15), (_) => _loadVehicle());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
      await _loadVehicle();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadVehicle() async {
    try {
      final rt = await ApiClient.get('/api/realtime/vehicles', {
        'service': 'automobilistico',
        'tripId': widget.tripId,
        'nearby': '800',
      });
      final vehicles = [
        for (final v in ((rt as Map)['vehicles'] as List? ?? []))
          if (v is Map) Vehicle.fromJson(Map<String, dynamic>.from(v))
      ];
      if (vehicles.isNotEmpty) {
        final v = vehicles.firstWhere(
            (x) => x.tripId == widget.tripId,
            orElse: () => vehicles.first);
        if (v.lat != null && mounted) {
          setState(() {
            _vehicle = v;
            _vehiclePos = LatLng(v.lat!, v.lon!);
            _nearby = vehicles
                .where((x) => x.tripId != v.tripId && x.lat != null)
                .toList();
          });
        }
      }
    } catch (_) {}
  }

  /// Index of the next stop the vehicle will reach (with delay).
  int? _nextStopIndex() {
    if (_stops == null || _stops!.isEmpty) return null;
    final now = DateTime.now();
    final nowSec = now.hour * 3600 + now.minute * 60 + now.second;
    final delay = _vehicle?.delaySeconds ?? 0;
    final virtualNow = nowSec - delay;
    for (var i = 0; i < _stops!.length - 1; i++) {
      var a = timeToSec(_stops![i].arrivalTime ?? _stops![i].time);
      var b = timeToSec(
          _stops![i + 1].arrivalTime ?? _stops![i + 1].time);
      if (b < a) b += 86400;
      if (virtualNow <= a || (virtualNow >= a && virtualNow <= b)) {
        return virtualNow <= a ? i : i + 1;
      }
    }
    if (virtualNow <
        timeToSec(
            _stops!.last.arrivalTime ?? _stops!.last.time)) {
      return _stops!.length - 1;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nextIdx = _nextStopIndex();
    final line = widget.line ??
        _vehicle?.shortName ??
        widget.tripId.split('_').elementAtOrNull(2) ??
        '';
    final headsign = widget.dest ?? _vehicle?.headsign ?? '';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              title: headsign.isEmpty
                  ? 'Dettaglio corsa'
                  : 'DIREZIONE $headsign',
              subtitle: _subtitle(),
              brand: line.isEmpty ? null : null,
              actions: [
                if (line.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 0),
                    child: FutureBuilder<(Color, Color)>(
                      future: LineColors.badge('bus', line),
                      builder: (context, snap) {
                        final (bg, fg) = snap.data ??
                            LineColors.fallbackBadge(line);
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: LineBadge(
                              label: line,
                              color: bg,
                              textColor: fg,
                              large: true),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          if (_error != null)
            SliverFillRemaining(
              child: ErrorView(error: _error!, onRetry: _load),
            )
          else if (_stops == null)
            const SliverFillRemaining(child: LoadingView())
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_vehicle != null)
                      _vehicleInfo(context, nextIdx),
                    SectionTitle('Fermate (${_stops!.length})'),
                  ],
                ),
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
                    passed: nextIdx != null && i < nextIdx,
                    isNext: nextIdx != null && i == nextIdx,
                  ),
                  childCount: _stops!.length,
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton:
          _stops != null ? _MapFab(onTap: _openMap) : null,
    );
  }

  String _subtitle() {
    final v = _vehicle;
    if (v == null) return widget.time ?? '';
    final delayMin = (v.delaySeconds / 60).round();
    final delayText = delayMin > 0
        ? '· ritardo +$delayMin min'
        : delayMin < 0
            ? '· anticipo ${-delayMin} min'
            : '· in orario';
    return '${widget.time ?? ''} $delayText';
  }

  Widget _vehicleInfo(BuildContext context, int? nextIdx) {
    String countdown = '';
    if (nextIdx != null) {
      final t = _stops![nextIdx].arrivalTime ?? _stops![nextIdx].time;
      final sec = timeToSec(t) +
          (_vehicle?.delaySeconds ?? 0) -
          (DateTime.now().hour * 3600 +
              DateTime.now().minute * 60 +
              DateTime.now().second);
      final min = (sec / 60).round();
      countdown =
          'Prossima fermata: ${_stops![nextIdx].name}${min > 0 ? ' tra $min min' : ' ora'}';
    }
    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.gps_fixed, color: context.green),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              countdown.isEmpty
                  ? 'Posizione in tempo reale attiva'
                  : countdown,
              style: TextStyle(
                  color: context.ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _openMap() {
    final points = _shape.isNotEmpty
        ? _shape.map((p) => LatLng(p.lat, p.lng)).toList()
        : [
            for (final s in _stops ?? <TripStop>[])
              if (s.lat != null && s.lng != null) LatLng(s.lat!, s.lng!)
          ];
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'mappa',
      pageBuilder: (ctx, _, _) => Material(
        child: SafeArea(
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCameraFit: points.length > 1
                      ? CameraFit.bounds(
                          bounds: LatLngBounds.fromPoints(points),
                          padding: const EdgeInsets.all(40))
                      : null,
                  initialCenter: _vehiclePos ??
                      (points.isNotEmpty
                          ? points.first
                          : const LatLng(45.485, 12.245)),
                  initialZoom: 13,
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
                          color: ctx.blue,
                          strokeWidth: 4),
                    ]),
                  MarkerLayer(markers: [
                    for (var i = 0; i < (_stops?.length ?? 0); i++)
                      if (_stops![i].lat != null &&
                          _stops![i].lng != null)
                        Marker(
                          point:
                              LatLng(_stops![i].lat!, _stops![i].lng!),
                          width: 10,
                          height: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _nextStopIndex() != null &&
                                      i < _nextStopIndex()!
                                  ? ctx.muted
                                  : ctx.surface,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: ctx.blue, width: 2),
                            ),
                          ),
                        ),
                    for (final v in _nearby)
                      if (v.lat != null)
                        Marker(
                          point: LatLng(v.lat!, v.lon!),
                          width: 24,
                          height: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              color: ctx.muted,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.directions_bus,
                                color: Colors.white, size: 12),
                          ),
                        ),
                    if (_vehiclePos != null)
                      Marker(
                        point: _vehiclePos!,
                        width: 32,
                        height: 32,
                        child: Container(
                          decoration: BoxDecoration(
                            color: ctx.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.directions_bus,
                              color: Colors.white, size: 17),
                        ),
                      ),
                  ]),
                ],
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapFab extends StatelessWidget {
  final VoidCallback onTap;
  const _MapFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'trip-map-fab',
      onPressed: onTap,
      backgroundColor: context.greenDark,
      shape: const CircleBorder(),
      child: const Icon(Icons.map_outlined, color: Colors.white),
    );
  }
}

class _StopRow extends StatelessWidget {
  final TripStop stop;
  final bool isFirst;
  final bool isLast;
  final bool passed;
  final bool isNext;

  const _StopRow({
    required this.stop,
    required this.isFirst,
    required this.isLast,
    required this.passed,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    final time =
        stop.departureTime ?? stop.arrivalTime ?? stop.time ?? '';
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time.length >= 5 ? time.substring(0, 5) : time,
                  style: TextStyle(
                    color: passed ? context.muted : context.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (passed)
                  Text('TRASCORSO',
                      style: TextStyle(
                          color: context.muted, fontSize: 8)),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: isNext
                      ? context.green
                      : passed
                          ? context.muted
                          : isFirst || isLast
                              ? context.green
                              : context.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: passed
                        ? context.muted
                        : context.green,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                    child: Container(
                        width: 2,
                        color: passed
                            ? context.muted
                            : context.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: isNext
                  ? const EdgeInsets.all(8)
                  : EdgeInsets.zero,
              decoration: isNext
                  ? BoxDecoration(
                      color: context.green
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Text(
                stop.name,
                style: TextStyle(
                  color: passed ? context.muted : context.ink,
                  fontWeight: isFirst || isLast || isNext
                      ? FontWeight.w700
                      : FontWeight.w500,
                  decoration: passed
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
