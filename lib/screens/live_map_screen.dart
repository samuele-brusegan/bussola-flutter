import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../services/delay_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import 'trip_details_screen.dart';

class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  List<Vehicle> _vehicles = [];
  Object? _error;
  String _service = 'automobilistico';
  Timer? _timer;
  Vehicle? _selected;
  bool _firstLoad = true;

  static const _venice = LatLng(45.485, 12.245);

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.get(
          '/api/realtime/vehicles', {'service': _service});
      if (!mounted) return;
      final list = <Vehicle>[
        for (final v in ((res as Map)['vehicles'] as List? ?? []))
          Vehicle.fromJson(v)
      ];
      DelayService.recordVehicles(list);
      setState(() {
        _vehicles = list;
        _error = null;
        _firstLoad = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _firstLoad = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final located = _vehicles.where((v) => v.lat != null && v.lon != null);
    final rt = located.where((v) => v.isRealtime).length;

    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            showBack: true,
            title: 'Bus in servizio',
            subtitle: '${located.length} veicoli · $rt in tempo reale',
            actions: [
              _HeaderIconButton(
                  icon: Icons.refresh, onTap: _load),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final (value, label) in [
                  ('automobilistico', 'Autobus'),
                  ('navigation', 'Navigazione'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(label),
                      selected: _service == value,
                      onSelected: (_) {
                        setState(() {
                          _service = value;
                          _firstLoad = true;
                          _vehicles = [];
                        });
                        _load();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _firstLoad
                ? const LoadingView()
                : _error != null && _vehicles.isEmpty
                    ? ErrorView(error: _error!, onRetry: _load)
                    : Stack(
                        children: [
                          FlutterMap(
                            options: MapOptions(
                              initialCenter: _venice,
                              initialZoom: 12,
                              onTap: (_, _) =>
                                  setState(() => _selected = null),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'it.brusegan.bussola',
                              ),
                              MarkerLayer(
                                markers: [
                                  for (final v in located)
                                    Marker(
                                      point: LatLng(v.lat!, v.lon!),
                                      width: 34,
                                      height: 34,
                                      child: GestureDetector(
                                        onTap: () =>
                                            setState(() => _selected = v),
                                        child: _BusMarker(vehicle: v),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          if (_selected != null)
                            Positioned(
                              left: 12,
                              right: 12,
                              bottom: 12,
                              child: _VehicleCard(
                                vehicle: _selected!,
                                onClose: () =>
                                    setState(() => _selected = null),
                                onOpen: _selected!.tripId.isEmpty
                                    ? null
                                    : () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                TripDetailsScreen(
                                              tripId: _selected!.tripId,
                                            ),
                                          ),
                                        ),
                              ),
                            ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _BusMarker extends StatelessWidget {
  final Vehicle vehicle;
  const _BusMarker({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    final realtime = vehicle.isRealtime;
    final color = realtime
        ? vehicle.color
        : (vehicle.status == 'scheduled-api'
            ? const Color(0xFF616161)
            : const Color(0xFF9E9E9E));
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        vehicle.shortName,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final VoidCallback onClose;
  final VoidCallback? onOpen;

  const _VehicleCard({
    required this.vehicle,
    required this.onClose,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final delayMin = (vehicle.delaySeconds / 60).round();
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: vehicle.isRealtime
                  ? vehicle.color
                  : const Color(0xFF9E9E9E),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              vehicle.shortName,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.shortName.isEmpty
                      ? 'Veicolo'
                      : 'Linea ${vehicle.shortName}',
                  style: TextStyle(
                      color: context.ink, fontWeight: FontWeight.w700),
                ),
                Text(
                  [
                    if (vehicle.headsign.isNotEmpty) vehicle.headsign,
                    vehicle.isRealtime ? 'tempo reale' : 'programmato',
                    if (vehicle.isRealtime && delayMin != 0)
                      delayMin > 0 ? '+$delayMin min' : '$delayMin min',
                  ].join(' · '),
                  style: TextStyle(color: context.muted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onOpen != null)
            TextButton(onPressed: onOpen, child: const Text('Corsa')),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: Colors.white)),
      ),
    );
  }
}
