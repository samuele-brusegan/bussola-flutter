import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import 'trip_details_screen.dart';

class TripFinderScreen extends StatefulWidget {
  const TripFinderScreen({super.key});

  @override
  State<TripFinderScreen> createState() => _TripFinderScreenState();
}

class _TripFinderScreenState extends State<TripFinderScreen> {
  final _lineController = TextEditingController();
  final _date = DateTime.now();

  List<LineVariant>? _variants;
  String? _origin;
  String? _destination;
  List<dynamic>? _trips;
  bool _loading = false;
  Object? _error;

  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  String get _day => _days[_date.weekday - 1];

  List<TripStop> get _allStops {
    final seen = <String>{};
    final out = <TripStop>[];
    for (final v in _variants ?? []) {
      for (final s in v.stops) {
        if (seen.add(s.id)) out.add(s);
      }
    }
    return out;
  }

  List<TripStop> get _destinations {
    if (_origin == null) return [];
    final out = <String, TripStop>{};
    for (final v in _variants!) {
      final idx = v.stops.indexWhere((s) => s.id == _origin);
      if (idx < 0) continue;
      for (var i = idx + 1; i < v.stops.length; i++) {
        out[v.stops[i].id] = v.stops[i];
      }
    }
    return out.values.toList();
  }

  Future<void> _loadVariants() async {
    final line = _lineController.text.trim();
    if (line.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _variants = null;
      _trips = null;
      _origin = null;
      _destination = null;
    });
    try {
      final res = await ApiClient.get('/api/line-variants', {
        'line': line,
        'service': 'automobilistico',
        'date': DateFormat('yyyy-MM-dd').format(_date),
        'day': _day,
      });
      if (!mounted) return;
      if (res is Map && res['success'] == true) {
        setState(() {
          _variants = [
            for (final v in (res['variants'] as List? ?? []))
              LineVariant.fromJson(v)
          ];
          _loading = false;
        });
      } else {
        throw ApiException('${res is Map ? res['error'] : 'Errore'}');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  Future<void> _loadTrips() async {
    if (_origin == null || _destination == null) return;
    setState(() { _loading = true; _error = null; _trips = null; });
    try {
      final res = await ApiClient.get('/api/line-trips', {
        'line': _lineController.text.trim(),
        'origin': _origin!,
        'destination': _destination!,
        'date': DateFormat('yyyy-MM-dd').format(_date),
        'day': _day,
      });
      if (!mounted) return;
      if (res is Map && res['success'] == true) {
        setState(() {
          _trips = res['trips'] as List? ?? [];
          _loading = false;
        });
      } else {
        throw ApiException('${res is Map ? res['error'] : 'Errore'}');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              title: 'Cerca una corsa',
              subtitle: 'Trova una corsa per linea e tratta',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _lineController,
                              decoration: const InputDecoration(
                                labelText: 'Linea',
                                hintText: 'es. 5E',
                              ),
                              onSubmitted: (_) => _loadVariants(),
                            ),
                          ),
                          const SizedBox(width: 10),
                          FilledButton(
                            onPressed: _loadVariants,
                            child: const Text('Cerca'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_variants != null) ...[
                        _dropdown(
                          label: 'Partenza',
                          value: _origin,
                          items: _allStops,
                          onChanged: (v) => setState(() {
                            _origin = v;
                            _destination = null;
                            _trips = null;
                          }),
                        ),
                        const SizedBox(height: 10),
                        _dropdown(
                          label: 'Destinazione',
                          value: _destination,
                          items: _destinations,
                          onChanged: (v) {
                            setState(() => _destination = v);
                            _loadTrips();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: LoadingView(),
                  )
                else if (_error != null)
                  ErrorView(
                      error: _error!,
                      onRetry: _variants == null ? _loadVariants : _loadTrips)
                else if (_trips != null && _trips!.isEmpty)
                  Center(
                    child: Text('Nessuna corsa trovata per questa tratta.',
                        style: TextStyle(color: context.muted)),
                  )
                else if (_trips != null)
                  for (final t in _trips!) _TripCard(trip: t),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<TripStop> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final s in items)
          DropdownMenuItem(
            value: s.id,
            child: Text(s.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _TripCard extends StatelessWidget {
  final dynamic trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    final tripId = '${trip['trip_id'] ?? ''}';
    final start = '${trip['start'] ?? trip['departure_time'] ?? trip['departure'] ?? ''}';
    final end = '${trip['end'] ?? trip['arrival_time'] ?? trip['arrival'] ?? ''}';
    final headsign = '${trip['headsign'] ?? trip['trip_headsign'] ?? ''}';

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      onTap: tripId.isEmpty
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => TripDetailsScreen(tripId: tripId)),
              ),
      child: Row(
        children: [
          Icon(Icons.directions_bus, color: context.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${start.length >= 5 ? start.substring(0, 5) : start}'
                  '${end.isNotEmpty ? ' → ${end.substring(0, 5)}' : ''}',
                  style: TextStyle(
                      color: context.ink, fontWeight: FontWeight.w700),
                ),
                if (headsign.isNotEmpty)
                  Text(headsign,
                      style:
                          TextStyle(color: context.muted, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.muted),
        ],
      ),
    );
  }
}
