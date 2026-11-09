import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import '../services/stops_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import 'route_results_screen.dart';

/// Port of `/route-details` (routeDetails.js): full legs timeline,
/// map modal, "parti da qui" hint, save to favorite_routes.
class RouteDetailsScreen extends StatefulWidget {
  final PlannedRoute route;
  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;

  const RouteDetailsScreen({
    super.key,
    required this.route,
    required this.origin,
    required this.destination,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  bool _saved = false;
  bool _nearOrigin = false;

  String _short(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  @override
  void initState() {
    super.initState();
    Storage.setJson('selected_route', widget.route.raw);
    FavoriteRoutesService.isFavorite(widget.origin, widget.destination)
        .then((v) => mounted ? setState(() => _saved = v) : null);
    _checkProximity();
  }

  /// "Parti da qui" if the user is within ~500 m of the origin.
  Future<void> _checkProximity() async {
    final lat = widget.origin['lat'];
    final lng = widget.origin['lng'];
    if (lat == null || lng == null) return;
    final pos = await StopsService.locate();
    if (pos == null || !mounted) return;
    final d = getDist(
        pos.latitude,
        pos.longitude,
        (lat as num).toDouble(),
        (lng as num).toDouble());
    if (d <= 500) setState(() => _nearOrigin = true);
  }

  Future<void> _toggleSave() async {
    final now = await FavoriteRoutesService.toggle(
        widget.origin, widget.destination,
        line: widget.route.legs
            .firstWhere((l) => l.type != 'walking',
                orElse: () => widget.route.legs.first)
            .line);
    if (mounted) {
      setState(() => _saved = now);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(now
              ? context.l10n.routeSaved
              : context.l10n.routeRemoved)));
    }
  }

  void _showMap() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _RouteMapModal(route: widget.route),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.route;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              title:
                  '${_short(r.departureTime)} → ${_short(r.arrivalTime)}',
              subtitle:
                  '${r.duration} min · ${widget.origin['name']} → ${widget.destination['name']}',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_nearOrigin)
                  AppCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.near_me,
                            color: context.green, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.l10n.nearOriginHint,
                            style: TextStyle(color: context.ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                RouteTimeline(route: r, short: _short),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _toggleSave,
                        icon: Icon(
                            _saved ? Icons.star : Icons.star_border),
                        label: Text(
                            _saved ? context.l10n.saved : context.l10n.saveRoute),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _showMap,
                        icon: const Icon(Icons.map_outlined),
                        label: Text(context.l10n.viewOnMap),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fullscreen-ish map modal with legs polylines and stop markers.
class _RouteMapModal extends StatelessWidget {
  final PlannedRoute route;
  const _RouteMapModal({required this.route});

  @override
  Widget build(BuildContext context) {
    // Collect coordinates from leg endpoints/stops when available.
    final points = <LatLng>[];
    final markers = <LatLng>[];
    for (final leg in route.legs) {
      for (final key in ['origin', 'destination']) {
        final s = leg.raw['${key}_lat'] ?? leg.raw['${key}Lat'];
        final o = leg.raw['${key}_lon'] ??
            leg.raw['${key}_lng'] ??
            leg.raw['${key}Lng'];
        if (s is num && o is num) {
          final p = LatLng(s.toDouble(), o.toDouble());
          points.add(p);
          markers.add(p);
        }
      }
      for (final s in (leg.raw['stops'] as List? ?? [])) {
        final la = s['lat'] ?? s['stop_lat'];
        final lo = s['lng'] ?? s['lon'] ?? s['stop_lon'];
        if (la is num && lo is num) {
          final p = LatLng(la.toDouble(), lo.toDouble());
          points.add(p);
          markers.add(p);
        }
      }
    }
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(context.l10n.yourRoute,
                      style: TextStyle(
                          color: context.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 17)),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCameraFit: points.length > 1
                    ? CameraFit.bounds(
                        bounds: LatLngBounds.fromPoints(points),
                        padding: const EdgeInsets.all(40))
                    : null,
                initialCenter: points.isNotEmpty
                    ? points.first
                    : const LatLng(45.485, 12.245),
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
                  for (final p in markers)
                    Marker(
                      point: p,
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
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
