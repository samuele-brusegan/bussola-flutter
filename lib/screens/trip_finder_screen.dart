import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_ext.dart';
import '../models/models.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/slim_header.dart';
import 'trip_details_screen.dart';

/// Port of `/trip-finder` (tripFinder.js): finder card (line select + date,
/// origin → destination selects) and results card (count, trip list,
/// pagination with page/time jump, "open trip" button).
class TripFinderScreen extends StatefulWidget {
  const TripFinderScreen({super.key});

  @override
  State<TripFinderScreen> createState() => _TripFinderScreenState();
}

class _TripFinderScreenState extends State<TripFinderScreen> {
  DateTime _date = DateTime.now();
  List<LineCatalogEntry>? _catalog;
  String? _line;

  List<LineVariant>? _variants;
  String? _origin;
  String? _destination;

  List<dynamic>? _trips;
  String? _selectedTripId;
  bool _loading = false;
  Object? _error;
  int _page = 0;
  static const _perPage = 10;

  final _pageCtl = TextEditingController();
  final _timeCtl = TextEditingController();

  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  String get _day => _days[_date.weekday - 1];
  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _pageCtl.dispose();
    _timeCtl.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final res = await ApiClient.get('/api/line-catalog',
          {'service': 'automobilistico', 'date': _dateStr, 'day': _day});
      if (!mounted) return;
      setState(() {
        _catalog = [
          for (final l in ((res as Map)['lines'] as List? ?? []))
            LineCatalogEntry.fromJson(l)
        ];
      });
    } catch (_) {}
  }

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

  Future<void> _loadVariants(String line) async {
    setState(() {
      _loading = true;
      _error = null;
      _line = line;
      _variants = null;
      _trips = null;
      _selectedTripId = null;
      _origin = null;
      _destination = null;
    });
    try {
      final res = await ApiClient.get('/api/line-variants', {
        'line': line,
        'service': 'automobilistico',
        'date': _dateStr,
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
    setState(() {
      _loading = true;
      _error = null;
      _trips = null;
      _selectedTripId = null;
    });
    try {
      final res = await ApiClient.get('/api/line-trips', {
        'line': _line!,
        'origin': _origin!,
        'destination': _destination!,
        'date': _dateStr,
        'day': _day,
      });
      if (!mounted) return;
      if (res is Map && res['success'] == true) {
        setState(() {
          _trips = res['trips'] as List? ?? [];
          _loading = false;
          _page = 0;
        });
        Storage.setJson(Storage.tripFinderState, {
          'line': _line,
          'origin': _origin,
          'destination': _destination,
        });
      } else {
        throw ApiException('${res is Map ? res['error'] : 'Errore'}');
      }
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  int get _pageCount =>
      _trips == null || _trips!.isEmpty ? 1 : ((_trips!.length - 1) ~/ _perPage) + 1;

  void _jumpToPage() {
    final p = int.tryParse(_pageCtl.text.trim());
    if (p == null || p < 1 || p > _pageCount) return;
    setState(() => _page = p - 1);
  }

  void _jumpToTime() {
    final t = _timeCtl.text.trim();
    if (_trips == null || t.length < 4) return;
    final idx = _trips!.indexWhere((trip) {
      final start =
          '${trip['start'] ?? trip['departure_time'] ?? trip['departure'] ?? ''}';
      return start.length >= 5 && start.substring(0, 5).compareTo(t) >= 0;
    });
    if (idx < 0) return;
    setState(() {
      _page = idx ~/ _perPage;
      _selectedTripId = '${_trips![idx]['trip_id'] ?? ''}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SlimHeader(
              showBack: true,
              title: l10n.searchTrip,
              subtitle: l10n.tripFinderSubtitle,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _finderCard(l10n),
                const SizedBox(height: 16),
                _tripsCard(l10n),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _finderCard(AppLocalizations l10n) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.busService),
          const SizedBox(height: 4),
          Text(
            l10n.findTrip,
            style: TextStyle(
              color: context.ink,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.lineLabel),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _line,
                      isExpanded: true,
                      decoration: InputDecoration(
                        hintText: _catalog == null
                            ? l10n.loading
                            : l10n.pickLineFirst,
                        isDense: true,
                      ),
                      items: [
                        for (final e in _catalog ?? <LineCatalogEntry>[])
                          DropdownMenuItem(
                            value: e.line,
                            child: Text(
                              '${e.line} · ${e.name}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _catalog == null
                          ? null
                          : (v) {
                              if (v != null) _loadVariants(v);
                            },
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.lineHelp,
                        style: TextStyle(
                            color: context.muted, fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.dateLabel),
                    const SizedBox(height: 6),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate: _date,
                          firstDate: DateTime.now().subtract(
                              const Duration(days: 30)),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 90)),
                        );
                        if (d != null) {
                          setState(() => _date = d);
                          _loadCatalog();
                          if (_line != null) _loadVariants(_line!);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: context.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                DateFormat.yMd(
                                        Localizations.localeOf(
                                                context)
                                            .toLanguageTag())
                                    .format(_date),
                                style: TextStyle(
                                    color: context.ink,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            Icon(Icons.calendar_today,
                                size: 16, color: context.muted),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SectionLabel(l10n.departure),
          const SizedBox(height: 6),
          _stopDropdown(
            value: _origin,
            items: _allStops,
            hint: _variants == null
                ? l10n.pickLineFirst
                : l10n.selectDeparture,
            onChanged: _variants == null
                ? null
                : (v) => setState(() {
                      _origin = v;
                      _destination = null;
                      _trips = null;
                      _selectedTripId = null;
                    }),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child:
                  Icon(Icons.arrow_downward, color: context.muted),
            ),
          ),
          SectionLabel(l10n.destination),
          const SizedBox(height: 6),
          _stopDropdown(
            value: _destination,
            items: _destinations,
            hint: _origin == null
                ? l10n.pickOriginFirst
                : l10n.selectDestination,
            onChanged: _origin == null
                ? null
                : (v) {
                    setState(() => _destination = v);
                    _loadTrips();
                  },
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text('$_error',
                style: const TextStyle(
                    color: Colors.red, fontSize: 13)),
          ],
        ],
      ),
    );
  }

  Widget _stopDropdown({
    required String? value,
    required List<TripStop> items,
    required String hint,
    required ValueChanged<String?>? onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(hintText: hint, isDense: true),
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

  Widget _tripsCard(AppLocalizations l10n) {
    final trips = _trips;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionLabel(l10n.tripsResults),
                    const SizedBox(height: 4),
                    Text(
                      l10n.selectLeg,
                      style: TextStyle(
                        color: context.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (trips != null && trips.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.surface2,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.tripsCount(trips.length),
                    style: TextStyle(
                        color: context.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: LoadingView(),
            )
          else if (trips == null)
            Text(l10n.tripsEmptyState,
                style: TextStyle(color: context.muted))
          else if (trips.isEmpty)
            Text(l10n.noTripsFound,
                style: TextStyle(color: context.muted))
          else ...[
            for (final t
                in trips.skip(_page * _perPage).take(_perPage))
              _tripTile(t),
            if (_pageCount > 1) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _page > 0
                        ? () => setState(() => _page--)
                        : null,
                    child: const Text('‹'),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12),
                    child: Text(
                      l10n.pageOf(_page + 1, _pageCount),
                      style: TextStyle(
                          color: context.muted, fontSize: 13),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _page + 1 < _pageCount
                        ? () => setState(() => _page++)
                        : null,
                    child: const Text('›'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.goToPage,
                          style: TextStyle(
                              color: context.muted,
                              fontSize: 12)),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 56,
                        child: TextField(
                          controller: _pageCtl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              isDense: true),
                          onSubmitted: (_) => _jumpToPage(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: _jumpToPage,
                        child: Text(l10n.go),
                      ),
                    ],
                  ),
                  Text(l10n.orWord,
                      style: TextStyle(
                          color: context.muted, fontSize: 12)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.goToTime,
                          style: TextStyle(
                              color: context.muted,
                              fontSize: 12)),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 76,
                        child: TextField(
                          controller: _timeCtl,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                              hintText: 'HH:MM', isDense: true),
                          onSubmitted: (_) => _jumpToTime(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      OutlinedButton(
                        onPressed: _jumpToTime,
                        child: Text(l10n.go),
                      ),
                    ],
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedTripId == null
                    ? null
                    : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailsScreen(
                                tripId: _selectedTripId!),
                          ),
                        ),
                child: Text(l10n.openTrip),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _tripTile(dynamic trip) {
    final tripId = '${trip['trip_id'] ?? ''}';
    final start =
        '${trip['start'] ?? trip['departure_time'] ?? trip['departure'] ?? ''}';
    final end =
        '${trip['end'] ?? trip['arrival_time'] ?? trip['arrival'] ?? ''}';
    final headsign =
        '${trip['headsign'] ?? trip['trip_headsign'] ?? ''}';
    final selected = _selectedTripId == tripId && tripId.isNotEmpty;
    bool moving = false;
    if (start.length >= 5 && end.length >= 5) {
      final now = DateTime.now();
      final nowMin = now.hour * 60 + now.minute;
      int? toMin(String t) {
        final p = t.split(':');
        return p.length < 2
            ? null
            : int.tryParse(p[0])! * 60 + int.tryParse(p[1])!;
      }

      final a = toMin(start), b = toMin(end);
      if (a != null && b != null) {
        moving = nowMin >= a - 30 && nowMin <= b + 30;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: selected
          ? BoxDecoration(
              color: context.green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: context.green, width: 1.5),
            )
          : null,
      child: AppCard(
        margin: EdgeInsets.zero,
        onTap: tripId.isEmpty
            ? null
            : () => setState(() => _selectedTripId = tripId),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? context.green : context.muted,
              size: 20,
            ),
            const SizedBox(width: 10),
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
                        color: context.ink,
                        fontWeight: FontWeight.w700),
                  ),
                  if (headsign.isNotEmpty)
                    Text(headsign,
                        style: TextStyle(
                            color: context.muted, fontSize: 13)),
                  if (moving)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color:
                            context.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                          context.l10n.movingPerSchedule,
                          style: TextStyle(
                              color: context.green,
                              fontSize: 11)),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
