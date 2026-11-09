import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import '../services/delay_service.dart';
import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/slim_header.dart';
import '../widgets/service_switch.dart';
import 'trip_details_screen.dart';

/// Port of `/live-map` (liveBusMap.js): toolbar with service switch, search
/// box, my-position/refresh/settings buttons; settings panel with search
/// fields + unidentified-vehicles toggle; bottom status bar with counter and
/// last-update time.
class LiveMapScreen extends StatefulWidget {
  const LiveMapScreen({super.key});

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  List<Vehicle> _vehicles = [];
  Object? _error;
  String _mode = 'both'; // 'both' | 'automobilistico' | 'navigation'
  String _query = '';
  DateTime? _lastUpdate;
  bool _showNd = true;
  bool _settingsOpen = false;
  bool _searchLine = true;
  bool _searchDest = true;
  bool _searchTrip = true;
  Timer? _timer;
  Vehicle? _selected;
  bool _firstLoad = true;
  bool _loading = false;
  int _loadToken = 0;
  LatLng? _userPos;

  final _mapCtl = MapController();
  final _searchCtl = TextEditingController();

  static const _venice = LatLng(45.485, 12.245);

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final saved = p.getString('live_map_service');
      if (saved != null &&
          ['both', 'automobilistico', 'navigation'].contains(saved) &&
          mounted) {
        setState(() => _mode = saved);
        _load();
      }
    });
    _load();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchCtl.dispose();
    _mapCtl.dispose();
    super.dispose();
  }

  List<String> get _activeServices => _mode == 'both'
      ? const ['automobilistico', 'navigation']
      : [_mode];

  /// Bus: `/api/realtime/vehicles?service=automobilistico` (Map with a
  /// `vehicles` list). Vaporetti: `/api/navigation/vehicles` (plain list).
  /// Each service is loaded independently so one failing endpoint does not
  /// blank the map (like `liveBusMap.js`).
  Future<List<Vehicle>> _fetchService(String service) async {
    try {
      if (service == 'navigation') {
        final res = await ApiClient.get('/api/navigation/vehicles');
        return [
          for (final v in (res as List? ?? []))
            if (v is Map)
              Vehicle.fromJson({
                'service': 'navigation',
                'status': 'realtime',
                ...Map<String, dynamic>.from(v)
              })
        ];
      }
      final res = await ApiClient.get(
          '/api/realtime/vehicles', {'service': service});
      // Every vehicle returned by realtime/vehicles is realtime by
      // definition — the payload has no `status` field (liveBusMap.js).
      return [
        for (final v in ((res as Map)['vehicles'] as List? ?? []))
          Vehicle.fromJson(
              {'status': 'realtime', ...Map<String, dynamic>.from(v)})
      ];
    } catch (_) {
      return [];
    }
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    setState(() => _loading = true);
    try {
      final results = await Future.wait(
          [for (final s in _activeServices) _fetchService(s)]);
      if (token != _loadToken || !mounted) return;
      final list = [for (final r in results) ...r];
      DelayService.recordVehicles(list);
      setState(() {
        _vehicles = list;
        _error = list.isEmpty ? 'empty' : null;
        _firstLoad = false;
        _loading = false;
        _lastUpdate = DateTime.now();
      });
    } catch (e) {
      if (mounted && token == _loadToken) {
        setState(() {
          _error = e;
          _firstLoad = false;
          _loading = false;
        });
      }
    }
  }

  Future<void> _setMode(String mode) async {
    setState(() => _mode = mode);
    final p = await SharedPreferences.getInstance();
    await p.setString('live_map_service', mode);
    _load();
  }

  Future<void> _goToUser() async {
    final pos = await StopsService.locate();
    if (pos == null || !mounted) return;
    final ll = LatLng(pos.latitude, pos.longitude);
    setState(() => _userPos = ll);
    _mapCtl.move(ll, 15);
  }

  String get _updated => _lastUpdate == null
      ? ''
      : '${_lastUpdate!.hour.toString().padLeft(2, '0')}:'
          '${_lastUpdate!.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    var located =
        _vehicles.where((v) => v.lat != null && v.lon != null);
    if (!_showNd) {
      located = located.where((v) => v.shortName.isNotEmpty);
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase().trim();
      located = located.where((v) =>
          (_searchLine && v.shortName.toLowerCase().contains(q)) ||
          (_searchTrip &&
              (v.tripId.toLowerCase().contains(q) ||
                  v.routeId.toLowerCase().contains(q))) ||
          (_searchDest && v.headsign.toLowerCase().contains(q)));
    }
    final locatedList = located.toList();
    final rt = locatedList.where((v) => v.isRealtime).length;

    return Scaffold(
      body: Column(
        children: [
          SlimHeader(
            showBack: true,
            title: l10n.liveBusesTitle,
          ),
          // Toolbar — `#filters-bar`: service switch + search + actions.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                ServiceSwitch(mode: _mode, onChanged: _setMode),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchCtl,
                    decoration: InputDecoration(
                      hintText: l10n.searchVehicleHint,
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                _searchCtl.clear();
                                setState(() => _query = '');
                              },
                            ),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                _ToolIcon(
                    icon: Icons.my_location,
                    tooltip: l10n.myPosition,
                    onTap: _goToUser),
                _ToolIcon(
                    icon: Icons.refresh,
                    tooltip: l10n.refreshTooltip,
                    onTap: _load),
                _ToolIcon(
                    icon: Icons.tune,
                    tooltip: l10n.mapSettings,
                    active: _settingsOpen,
                    onTap: () =>
                        setState(() => _settingsOpen = !_settingsOpen)),
              ],
            ),
          ),
          if (_settingsOpen) _settingsPanel(l10n),
          Expanded(
            child: _firstLoad
                ? const LoadingView()
                : _error != null && _vehicles.isEmpty
                    ? ErrorView(error: _error!, onRetry: _load)
                    : Stack(
                        children: [
                          FlutterMap(
                            mapController: _mapCtl,
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
                                userAgentPackageName:
                                    'it.brusegan.bussola',
                              ),
                              MarkerLayer(
                                markers: [
                                  for (final v in locatedList)
                                    Marker(
                                      point: LatLng(v.lat!, v.lon!),
                                      width: 34,
                                      height: 34,
                                      child: GestureDetector(
                                        onTap: () => setState(
                                            () => _selected = v),
                                        child: _BusMarker(vehicle: v),
                                      ),
                                    ),
                                  if (_userPos != null)
                                    Marker(
                                      point: _userPos!,
                                      width: 18,
                                      height: 18,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: context.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                              color: Colors.white,
                                              width: 3),
                                        ),
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
                                              tripId:
                                                  _selected!.tripId,
                                            ),
                                          ),
                                        ),
                              ),
                            ),
                        ],
                      ),
          ),
          // Status bar — `#status-bar`.
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: context.surface,
              border: Border(top: BorderSide(color: context.border)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      l10n.liveMapSubtitle(locatedList.length, rt),
                      style: TextStyle(
                          color: context.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (_lastUpdate != null)
                    Text(
                      l10n.updatedAt(_updated),
                      style: TextStyle(
                          color: context.muted, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsPanel(AppLocalizations l10n) {
    Widget row(String label, bool value, ValueChanged<bool> onChanged,
        {String? sub}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: context.ink)),
                  if (sub != null)
                    Text(sub,
                        style: TextStyle(
                            color: context.muted, fontSize: 11)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
    }

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
                  child: Text(l10n.mapSettings,
                      style: TextStyle(
                          color: context.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15)),
                ),
                InkWell(
                  onTap: () => setState(() => _settingsOpen = false),
                  child:
                      Icon(Icons.close, size: 20, color: context.muted),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SectionLabel(l10n.searchFields),
            row(l10n.searchFieldLine, _searchLine,
                (v) => setState(() => _searchLine = v)),
            row(l10n.searchFieldDest, _searchDest,
                (v) => setState(() => _searchDest = v)),
            row(l10n.searchFieldTrip, _searchTrip,
                (v) => setState(() => _searchTrip = v)),
            Divider(color: context.border, height: 20),
            row(l10n.noLineShown, _showNd,
                (v) => setState(() => _showNd = v),
                sub: l10n.noLineShownSub),
          ],
        ),
      ),
    );
  }
}

/// Small square icon button for the map toolbar (`.filter-btn`).
class _ToolIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _ToolIcon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active ? context.surface2 : context.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: context.border),
            ),
            child: Icon(icon,
                size: 18,
                color: active ? context.blue : context.ink),
          ),
        ),
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
          BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2))
        ],
      ),
      alignment: Alignment.center,
      child: vehicle.service == 'navigation'
          ? const Icon(Icons.directions_boat,
              color: Colors.white, size: 14)
          : Text(
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: vehicle.isRealtime
                  ? vehicle.color
                  : context.muted,
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
                      ? context.l10n.vehicle
                      : context.l10n.lineN(vehicle.shortName),
                  style: TextStyle(
                      color: context.ink,
                      fontWeight: FontWeight.w700),
                ),
                Text(
                  [
                    if (vehicle.headsign.isNotEmpty) vehicle.headsign,
                    vehicle.isRealtime
                        ? context.l10n.realtimeLabel
                        : context.l10n.scheduledLabel,
                    if (vehicle.isRealtime && delayMin != 0)
                      delayMin > 0
                          ? '+$delayMin min'
                          : '$delayMin min',
                  ].join(' · '),
                  style:
                      TextStyle(color: context.muted, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onOpen != null)
            TextButton(
                onPressed: onOpen, child: Text(context.l10n.trip)),
          IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}
