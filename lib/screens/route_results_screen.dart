import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/line_badge.dart';
import 'route_details_screen.dart';

/// Port of `/route-results` (routeResults.js): andata/ritorno tabs,
/// compare mode, details modal, realtime enrich, "(N min da ora)".
class RouteResultsScreen extends StatefulWidget {
  final Map<String, dynamic> origin;
  final Map<String, dynamic> destination;
  final DateTime date;
  final TimeOfDay time;
  final String optimize;
  final TimeOfDay? returnTime;

  const RouteResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
    required this.time,
    required this.optimize,
    this.returnTime,
  });

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  List<PlannedRoute>? _routes;
  List<PlannedRoute>? _returnRoutes;
  Object? _error;
  bool _returnTab = false;
  bool _comparing = false;
  final Set<int> _compareSelection = {};
  Map<String, Map<String, dynamic>> _vehicleByTrip = {};

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.returnTime != null) _loadReturn();
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _apiValue(Map<String, dynamic> p) =>
      p['type'] == 'stop' && p['id'] != null
          ? '${p['id']}'.split('-').first
          : '${p['lat']},${p['lng']}';

  Future<List<PlannedRoute>?> _plan(
      String from, String to, String date, String time,
      {String? fromService, String? toService}) async {
    final res = await ApiClient.get('/api/plan-route', {
      'from': from,
      'to': to,
      'date': date,
      'time': time,
      'optimize': widget.optimize,
      if (fromService == 'navigation') 'from_service': 'navigation',
      if (toService == 'navigation') 'to_service': 'navigation',
    });
    if (res is Map && res['success'] == true) {
      return [
        for (final r in (res['routes'] as List? ?? []))
          PlannedRoute.fromJson(r)
      ];
    }
    throw ApiException(
        res is Map ? '${res['error'] ?? 'Errore'}' : 'Errore');
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final routes = await _plan(
        _apiValue(widget.origin),
        _apiValue(widget.destination),
        DateFormat('yyyy-MM-dd').format(widget.date),
        _hhmm(widget.time),
        fromService: '${widget.origin['service']}',
        toService: '${widget.destination['service']}',
      );
      if (!mounted) return;
      setState(() => _routes = routes);
      _enrichRealtime(routes ?? []);
      Storage.setJson(Storage.routeResultsCache, {
        'routes': [for (final r in routes ?? []) r.raw],
        'ts': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _loadReturn() async {
    try {
      final routes = await _plan(
        _apiValue(widget.destination),
        _apiValue(widget.origin),
        DateFormat('yyyy-MM-dd').format(widget.date),
        _hhmm(widget.returnTime!),
        fromService: '${widget.destination['service']}',
        toService: '${widget.origin['service']}',
      );
      if (!mounted) return;
      setState(() => _returnRoutes = routes);
      _enrichRealtime(routes ?? []);
    } catch (_) {}
  }

  /// Realtime vehicle position per transit-leg trip_id.
  Future<void> _enrichRealtime(List<PlannedRoute> routes) async {
    final ids = <String>{
      for (final r in routes)
        for (final l in r.legs)
          if (l.type != 'walking' && l.tripId.isNotEmpty) l.tripId,
    };
    if (ids.isEmpty) return;
    for (final service in ['automobilistico', 'navigation']) {
      try {
        final res = await ApiClient.get('/api/realtime/vehicles',
            {'service': service, 'tripIds': ids.join(',')});
        if (!mounted) return;
        final map = <String, Map<String, dynamic>>{..._vehicleByTrip};
        for (final v in ((res as Map)['vehicles'] as List? ?? [])) {
          if (v is Map) {
            map['${v['trip_id']}'] = Map<String, dynamic>.from(v);
          }
        }
        setState(() => _vehicleByTrip = map);
      } catch (_) {}
    }
  }

  String _short(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  String _inMinutes(PlannedRoute r) {
    final parts = r.departureTime.split(':');
    if (parts.length < 2) return '';
    final now = DateTime.now();
    var dep = DateTime(now.year, now.month, now.day,
        int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
    if (widget.date.day == now.day && dep.isBefore(now)) {
      dep = dep.add(const Duration(days: 1));
    }
    final diff = dep.difference(DateTime.now()).inMinutes;
    if (diff < 0) return '';
    return '($diff min da ora)';
  }

  List<PlannedRoute>? get _current =>
      _returnTab ? _returnRoutes : _routes;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    final routes = _current;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                showBack: true,
                title: 'Soluzioni di viaggio',
                subtitle:
                    '${widget.origin['name']} → ${widget.destination['name']}\n${df.format(widget.date)} · ${_hhmm(widget.time)}',
              ),
            ),
            if (widget.returnTime != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: Row(
                    children: [
                      for (final (v, label) in [
                        (false, 'Andata'),
                        (true, 'Ritorno'),
                      ])
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _returnTab = v),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 150),
                              margin: EdgeInsets.only(
                                  right: v ? 0 : 8),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10),
                              decoration: BoxDecoration(
                                color: _returnTab == v
                                    ? context.blue
                                    : context.surface,
                                borderRadius:
                                    BorderRadius.circular(12),
                                border: Border.all(
                                    color: _returnTab == v
                                        ? context.blue
                                        : context.border),
                              ),
                              child: Center(
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: _returnTab == v
                                        ? Colors.white
                                        : context.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            if (_error != null)
              SliverFillRemaining(
                child: ErrorView(error: _error!, onRetry: _load),
              )
            else if (routes == null)
              const SliverFillRemaining(
                  child:
                      LoadingView(message: 'Ricerca percorsi in corso…'))
            else if (routes.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block,
                            size: 44, color: context.muted),
                        const SizedBox(height: 12),
                        Text(
                          'Nessun percorso trovato per i parametri specificati',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Indietro'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _RouteCard(
                      route: routes[i],
                      index: i,
                      short: _short,
                      inMinutes: _inMinutes(routes[i]),
                      comparing: _comparing,
                      selected: _compareSelection.contains(i),
                      onCompareToggle: () => setState(() {
                        _compareSelection.contains(i)
                            ? _compareSelection.remove(i)
                            : _compareSelection.add(i);
                      }),
                      onDetails: () =>
                          _showDetails(routes[i]),
                      onSelect: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteDetailsScreen(
                            route: routes[i],
                            origin: widget.origin,
                            destination: widget.destination,
                          ),
                        ),
                      ),
                      vehicleByTrip: _vehicleByTrip,
                    ),
                    childCount: routes.length,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: routes != null && routes.length > 1
          ? SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: _comparing
                    ? Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                _comparing = false;
                                _compareSelection.clear();
                              }),
                              child: const Text('Annulla'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: FilledButton(
                              onPressed:
                                  _compareSelection.length >= 2
                                      ? _showCompare
                                      : null,
                              child: const Text(
                                  'Confronta percorsi'),
                            ),
                          ),
                        ],
                      )
                    : OutlinedButton.icon(
                        onPressed: () =>
                            setState(() => _comparing = true),
                        icon: const Icon(Icons.compare_arrows),
                        label: const Text('Confronta'),
                      ),
              ),
            )
          : null,
    );
  }

  void _showDetails(PlannedRoute route) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: RouteTimeline(route: route, short: _short),
        ),
      ),
    );
  }

  void _showCompare() {
    final selected =
        _compareSelection.map((i) => _current![i]).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (_, scroll) => SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Confronta percorsi',
                  style: TextStyle(
                      color: ctx.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              const SizedBox(height: 14),
              for (var i = 0; i < selected.length; i++) ...[
                Text('Soluzione ${_compareSelection.elementAt(i) + 1}',
                    style: TextStyle(
                        color: ctx.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
                const SizedBox(height: 6),
                RouteTimeline(route: selected[i], short: _short),
                const SizedBox(height: 16),
              ],
              AppCard(
                child: Column(
                  children: [
                    for (final r in selected)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_short(r.departureTime)} → ${_short(r.arrivalTime)}',
                                style: TextStyle(
                                    color: ctx.ink,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Text('${r.duration} min',
                                style:
                                    TextStyle(color: ctx.ink)),
                            const SizedBox(width: 12),
                            Text(
                              '${r.legs.where((l) => l.type != 'walking').length - 1 <= 0 ? 'Diretto' : '${r.legs.where((l) => l.type != 'walking').length - 1} cambi'}',
                              style: TextStyle(
                                  color: ctx.muted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Complete legs timeline (shared by details modal + route-details page).
class RouteTimeline extends StatelessWidget {
  final PlannedRoute route;
  final String Function(String) short;
  const RouteTimeline(
      {super.key, required this.route, required this.short});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${short(route.departureTime)} → ${short(route.arrivalTime)} · ${route.duration} min',
          style: TextStyle(
              color: context.ink,
              fontWeight: FontWeight.w800,
              fontSize: 17),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < route.legs.length; i++)
          _TimelineLeg(
            leg: route.legs[i],
            isLast: i == route.legs.length - 1,
            short: short,
          ),
      ],
    );
  }
}

class _TimelineLeg extends StatelessWidget {
  final RouteLeg leg;
  final bool isLast;
  final String Function(String) short;
  const _TimelineLeg(
      {required this.leg, required this.isLast, required this.short});

  @override
  Widget build(BuildContext context) {
    final walking = leg.type == 'walking';
    final color = walking ? context.muted : leg.color;
    final distance = leg.raw['distance'];
    final stopsCount = leg.raw['stops_count'];
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: context.surface, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(child: Container(width: 3, color: color)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (walking)
                        Icon(Icons.directions_walk,
                            color: context.muted, size: 20)
                      else
                        LineBadge(
                          label: leg.line.isEmpty ? '?' : leg.line,
                          color: leg.color,
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          walking
                              ? 'Cammina${distance != null ? ' per $distance m' : ''}${leg.raw['duration'] != null ? ' (${leg.raw['duration']} min)' : ''}'
                              : '${leg.headsign.isEmpty ? leg.toName : leg.headsign}${stopsCount != null ? ' · $stopsCount fermate' : ''}',
                          style: TextStyle(
                              color: context.ink,
                              fontWeight: FontWeight.w600,
                              fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${leg.fromName}  ${short(leg.departure)} → ${leg.toName}  ${short(leg.arrival)}',
                    style: TextStyle(
                        color: context.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final PlannedRoute route;
  final int index;
  final String Function(String) short;
  final String inMinutes;
  final bool comparing;
  final bool selected;
  final VoidCallback onCompareToggle;
  final VoidCallback onDetails;
  final VoidCallback onSelect;
  final Map<String, Map<String, dynamic>> vehicleByTrip;

  const _RouteCard({
    required this.route,
    required this.index,
    required this.short,
    required this.inMinutes,
    required this.comparing,
    required this.selected,
    required this.onCompareToggle,
    required this.onDetails,
    required this.onSelect,
    required this.vehicleByTrip,
  });

  @override
  Widget build(BuildContext context) {
    final transitLegs =
        route.legs.where((l) => l.type != 'walking').toList();
    final transfers =
        transitLegs.isEmpty ? 0 : transitLegs.length - 1;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: comparing ? onCompareToggle : onSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (comparing)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: selected ? context.green : context.muted,
                  ),
                ),
              SectionLabel('Soluzione ${index + 1}'),
              const Spacer(),
              Text(
                '${route.duration} min',
                style: TextStyle(
                  color: context.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                short(route.departureTime),
                style: TextStyle(
                  color: context.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    size: 18, color: context.muted),
              ),
              Text(
                short(route.arrivalTime),
                style: TextStyle(
                  color: context.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    transfers == 0
                        ? 'Diretto'
                        : '$transfers cambi${transfers == 1 ? 'o' : ''}',
                    style: TextStyle(
                        color: context.muted, fontSize: 13),
                  ),
                  if (inMinutes.isNotEmpty)
                    Text(inMinutes,
                        style: TextStyle(
                            color: context.muted, fontSize: 12)),
                ],
              ),
            ],
          ),
          if (transitLegs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final leg in route.legs)
                  if (leg.type == 'walking')
                    Icon(Icons.directions_walk,
                        size: 20, color: context.muted)
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        LineBadge(
                          label:
                              leg.line.isEmpty ? '?' : leg.line,
                          color: leg.color,
                        ),
                        if (vehicleByTrip[leg.tripId]
                                ?['vehicle_position'] !=
                            null)
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 4),
                            child: Icon(Icons.gps_fixed,
                                size: 12, color: context.green),
                          ),
                      ],
                    ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onDetails,
                child: const Text('Dettagli'),
              ),
              const SizedBox(width: 8),
              Text(
                'Seleziona →',
                style: TextStyle(
                  color: context.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
