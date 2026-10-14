import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import 'route_results_screen.dart';
import 'stop_picker_sheet.dart';

class RouteFinderScreen extends StatefulWidget {
  const RouteFinderScreen({super.key});

  @override
  State<RouteFinderScreen> createState() => _RouteFinderScreenState();
}

class _RouteFinderScreenState extends State<RouteFinderScreen> {
  StopGroup? _origin;
  StopGroup? _destination;
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _optimize = 'time';
  bool _return = false;
  TimeOfDay? _returnTime;

  Future<void> _pickStation(bool isOrigin) async {
    final g = await showStopPicker(context);
    if (g == null) return;
    setState(() {
      if (isOrigin) {
        _origin = g;
      } else {
        _destination = g;
      }
    });
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_journey', '${_origin!.name} → ${_destination!.name}');

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteResultsScreen(
          origin: _origin!,
          destination: _destination!,
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
    fmt(TimeOfDay t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

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
                  value: _destination?.name ?? 'Seleziona destinazione',
                  selected: _destination != null,
                  onTap: () => _pickStation(false),
                ),
                const SizedBox(height: 20),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionLabel('Seleziona data e ora partenza'),
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
                              text: fmt(_time),
                              onTap: () => _pickTime(false),
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
                              selected: _optimize == value,
                              onSelected: (_) =>
                                  setState(() => _optimize = value),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Material(
                        color: Colors.transparent,
                        child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Ritorno',
                            style: TextStyle(
                                color: context.ink,
                                fontWeight: FontWeight.w600)),
                        value: _return,
                        onChanged: (v) => setState(() => _return = v),
                        ),
                      ),
                      if (_return)
                        _Trigger(
                          text: _returnTime == null
                              ? '--:--'
                              : fmt(_returnTime!),
                          onTap: () => _pickTime(true),
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
                    color: selected ? context.ink : context.muted,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    color: context.ink, fontWeight: FontWeight.w600)),
            Icon(Icons.chevron_right, size: 18, color: context.muted),
          ],
        ),
      ),
    );
  }
}
