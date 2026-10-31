import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/stops_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import 'route_results_screen.dart';
import 'stop_picker_sheet.dart';

/// Port of `/route-finder` (routeFinder.js): selection cards, swap,
/// options (date/time/optimize/ritorno), favorite routes, persisted state.
class RouteFinderScreen extends StatefulWidget {
  const RouteFinderScreen({super.key});

  @override
  State<RouteFinderScreen> createState() => _RouteFinderScreenState();
}

class _RouteFinderScreenState extends State<RouteFinderScreen> {
  RoutePoint? _origin;
  RoutePoint? _destination;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _optimize = 'time';
  bool _return = false;
  TimeOfDay? _returnTime;
  bool _optionsOpen = false;
  List<Map<String, dynamic>> _favRoutes = [];

  @override
  void initState() {
    super.initState();
    _restore();
  }

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _restore() async {
    final o = await Storage.getJson(Storage.routeOrigin);
    final d = await Storage.getJson(Storage.routeDestination);
    final optimize = await Storage.getString(Storage.routeOptimize);
    final ret = await Storage.getBool(Storage.routeReturnTrip);
    final dateStr = await Storage.getString(Storage.routeDepartureDate);
    final timeStr = await Storage.getString(Storage.routeDepartureTime);
    final retTime = await Storage.getString(Storage.routeReturnTime);
    _favRoutes = await FavoriteRoutesService.load();
    if (!mounted) return;
    setState(() {
      if (o is Map) {
        _origin = RoutePoint.fromJson(Map<String, dynamic>.from(o));
      }
      if (d is Map) {
        _destination =
            RoutePoint.fromJson(Map<String, dynamic>.from(d));
      }
      if (optimize != null) _optimize = optimize;
      _return = ret;
      if (dateStr != null) {
        _date = DateTime.tryParse(dateStr) ?? _date;
      }
      if (timeStr != null) {
        final p = timeStr.split(':');
        _time = TimeOfDay(
            hour: int.tryParse(p[0]) ?? 0,
            minute: int.tryParse(p[1]) ?? 0);
      }
      if (retTime != null) {
        final p = retTime.split(':');
        _returnTime = TimeOfDay(
            hour: int.tryParse(p[0]) ?? 0,
            minute: int.tryParse(p[1]) ?? 0);
      }
    });
  }

  Future<void> _save() async {
    if (_origin != null) {
      await Storage.setJson(Storage.routeOrigin, _origin!.toJson());
    }
    if (_destination != null) {
      await Storage.setJson(
          Storage.routeDestination, _destination!.toJson());
    }
    await Storage.setString(Storage.routeDepartureDate,
        DateFormat('yyyy-MM-dd').format(_date));
    await Storage.setString(
        Storage.routeDepartureTime, _fmtTime(_time));
    await Storage.setString(Storage.routeOptimize, _optimize);
    await Storage.setBool(Storage.routeReturnTrip, _return);
    if (_returnTime != null) {
      await Storage.setString(
          Storage.routeReturnTime, _fmtTime(_returnTime!));
    }
    await Storage.setString(Storage.routeLastUsedAt,
        '${DateTime.now().millisecondsSinceEpoch}');
  }

  Future<void> _pickStation(bool isOrigin) async {
    final p = await showStationSelector(context,
        type: isOrigin ? 'origin' : 'destination');
    if (p == null) return;
    setState(() {
      if (isOrigin) {
        _origin = p;
      } else {
        _destination = p;
      }
    });
    await _save();
  }

  void _swap() => setState(() {
        final t = _origin;
        _origin = _destination;
        _destination = t;
      });

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('it'),
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _pickTime(bool isReturn) async {
    final t = await showTimePicker(
      context: context,
      initialTime: isReturn ? (_returnTime ?? _time) : _time,
    );
    if (t != null) {
      setState(() {
        if (isReturn) {
          _returnTime = t;
        } else {
          _time = t;
        }
      });
    }
  }

  Future<void> _search() async {
    if (_origin == null || _destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Seleziona partenza e destinazione')),
      );
      return;
    }
    await _save();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteResultsScreen(
          origin: _origin!.toJson(),
          destination: _destination!.toJson(),
          date: _date,
          time: _time,
          optimize: _optimize,
          returnTime: _return ? _returnTime : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(title: 'Trova\nPercorso'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_favRoutes.isNotEmpty) ...[
                  const SectionLabel('Tragitti preferiti'),
                  const SizedBox(height: 8),
                  for (final r in _favRoutes) _favRouteTile(r),
                  const SizedBox(height: 12),
                ],
                _SelectionCard(
                  icon: Icons.trip_origin,
                  label: 'Partenza',
                  value: _origin?.name ?? 'Seleziona partenza',
                  selected: _origin != null,
                  onTap: () => _pickStation(true),
                ),
                Center(
                  child: IconButton(
                    onPressed: _swap,
                    icon: Icon(Icons.swap_vert,
                        color: context.green, size: 30),
                  ),
                ),
                _SelectionCard(
                  icon: Icons.place_outlined,
                  label: 'Destinazione',
                  value:
                      _destination?.name ?? 'Seleziona destinazione',
                  selected: _destination != null,
                  onTap: () => _pickStation(false),
                ),
                const SizedBox(height: 20),
                AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      InkWell(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radius),
                        onTap: () => setState(
                            () => _optionsOpen = !_optionsOpen),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Opzioni di partenza e ritorno',
                                  style: TextStyle(
                                    color: context.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Icon(
                                _optionsOpen
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: context.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_optionsOpen)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              16, 0, 16, 16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              const SectionLabel(
                                  'Seleziona data e ora partenza'),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: _Trigger(
                                      text: df.format(_date),
                                      onTap: _pickDate,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _Trigger(
                                      text: _fmtTime(_time),
                                      onTap: () =>
                                          _pickTime(false),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 18),
                              const SectionLabel('Ottimizza per'),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                children: [
                                  for (final (value, label) in [
                                    ('time', 'tempo'),
                                    ('transfers', 'cambi'),
                                    ('walking', 'a piedi'),
                                  ])
                                    ChoiceChip(
                                      label: Text(label),
                                      selected:
                                          _optimize == value,
                                      onSelected: (_) => setState(
                                          () => _optimize = value),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('Ritorno',
                                    style: TextStyle(
                                        color: context.ink,
                                        fontWeight:
                                            FontWeight.w600)),
                                value: _return,
                                onChanged: (v) => setState(
                                    () => _return = v),
                              ),
                              if (_return)
                                _Trigger(
                                  text: _returnTime == null
                                      ? '--:--'
                                      : _fmtTime(_returnTime!),
                                  onTap: () => _pickTime(true),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _search,
                  child: const Text('Ricerca soluzioni'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _favRouteTile(Map<String, dynamic> r) {
    final o = r['origin'] as Map?;
    final d = r['destination'] as Map?;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () {
        if (o == null || d == null) return;
        setState(() {
          _origin =
              RoutePoint.fromJson(Map<String, dynamic>.from(o));
          _destination =
              RoutePoint.fromJson(Map<String, dynamic>.from(d));
        });
      },
      child: Row(
        children: [
          Icon(Icons.star, color: AppColors.gold, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${o?['name'] ?? ''} → ${d?['name'] ?? ''}',
              style: TextStyle(
                  color: context.ink,
                  fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          InkWell(
            onTap: () async {
              await FavoriteRoutesService.remove('${r['key']}');
              _favRoutes = await FavoriteRoutesService.load();
              if (mounted) setState(() {});
            },
            child: Icon(Icons.close,
                size: 18, color: context.muted),
          ),
        ],
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: context.green, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(label),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color:
                        selected ? context.ink : context.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.muted),
        ],
      ),
    );
  }
}

class _Trigger extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _Trigger({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text,
                style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w600)),
            Icon(Icons.chevron_right,
                size: 18, color: context.muted),
          ],
        ),
      ),
    );
  }
}
