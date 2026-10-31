import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/line_badge.dart';

class LineScheduleScreen extends StatefulWidget {
  const LineScheduleScreen({super.key});

  @override
  State<LineScheduleScreen> createState() => _LineScheduleScreenState();
}

class _LineScheduleScreenState extends State<LineScheduleScreen> {
  String _service = 'automobilistico';
  DateTime _date = DateTime.now();
  List<LineCatalogEntry>? _catalog;
  List<LineVariant>? _variants;
  Map<String, dynamic>? _schedule;
  String? _line;
  Object? _error;
  bool _loading = false;
  String _search = '';

  static const _days = [
    'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'
  ];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  String get _day => _days[_date.weekday - 1];
  String get _dateStr => DateFormat('yyyy-MM-dd').format(_date);

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
      _catalog = null;
      _variants = null;
      _schedule = null;
      _line = null;
    });
    try {
      final res = await ApiClient.get('/api/line-catalog',
          {'service': _service, 'date': _dateStr});
      if (!mounted) return;
      setState(() {
        _catalog = [
          for (final l in ((res as Map)['lines'] as List? ?? []))
            LineCatalogEntry.fromJson(l)
        ];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  Future<void> _loadVariants(String line) async {
    setState(() {
      _line = line;
      _loading = true;
      _variants = null;
      _schedule = null;
      _error = null;
    });
    try {
      final res = await ApiClient.get('/api/line-variants',
          {'line': line, 'day': _day, 'date': _dateStr});
      if (!mounted) return;
      setState(() {
        _variants = [
          for (final v in (((res as Map)['variants']) as List? ?? []))
            LineVariant.fromJson(v)
        ];
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  Future<void> _loadSchedule(LineVariant v) async {
    if (v.tripId == null) return;
    setState(() { _loading = true; _schedule = null; _error = null; });
    try {
      final res = await ApiClient.get('/api/line-schedule', {
        'line': _line!,
        'trips': v.tripId!,
        'day': _day,
        'date': _dateStr,
      });
      if (!mounted) return;
      setState(() {
        _schedule = res as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            showBack: true,
            title: 'Orari delle linee',
            subtitle:
                _line == null ? 'Scegli una linea' : 'Linea $_line · $_day',
            actions: [
              _HeaderIcon(
                icon: Icons.calendar_today,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (d != null) {
                    setState(() => _date = d);
                    _loadCatalog();
                  }
                },
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                        setState(() => _service = value);
                        _loadCatalog();
                      },
                    ),
                  ),
                if (_line != null)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _line = null;
                      _variants = null;
                      _schedule = null;
                    }),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Linee'),
                  ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();
    if (_error != null) {
      return ErrorView(
          error: _error!,
          onRetry: _line == null ? _loadCatalog : () => _loadVariants(_line!));
    }
    if (_schedule != null) return _scheduleView();
    if (_variants != null) return _variantsView();
    if (_catalog != null) return _catalogView();
    return const LoadingView();
  }

  Widget _catalogView() {
    if (_catalog!.isEmpty) {
      return Center(
          child: Text('Nessuna linea per questa data.',
              style: TextStyle(color: context.muted)));
    }
    final entries = _search.isEmpty
        ? _catalog!
        : _catalog!
            .where((e) =>
                e.line.toLowerCase().contains(_search.toLowerCase()) ||
                e.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: entries.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Cerca per numero o destinazione…',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          );
        }
        final e = entries[i - 1];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          onTap: () => _loadVariants(e.line),
          child: Row(
            children: [
              LineBadge(label: e.line),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  e.name,
                  style: TextStyle(
                      color: context.ink, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('${e.tripsCount} corse',
                  style: TextStyle(color: context.muted, fontSize: 12)),
              Icon(Icons.chevron_right, color: context.muted),
            ],
          ),
        );
      },
    );
  }

  Widget _variantsView() {
    if (_variants!.isEmpty) {
      return Center(
          child: Text('Nessuna variante attiva.',
              style: TextStyle(color: context.muted)));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _variants!.length,
      itemBuilder: (context, i) {
        final v = _variants![i];
        return AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          onTap: () => _loadSchedule(v),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.headsign.isEmpty
                    ? '${v.origin} → ${v.terminus}'
                    : v.headsign,
                style: TextStyle(
                    color: context.ink, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '${v.origin} → ${v.terminus} · ${v.stopsCount} fermate · ${v.tripsCount} corse',
                style: TextStyle(color: context.muted, fontSize: 13),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _scheduleView() {
    final stops = (_schedule!['stops'] as List? ?? []);
    final runs = (_schedule!['runs'] as List? ?? []);
    if (stops.isEmpty || runs.isEmpty) {
      return Center(
          child: Text('Nessun orario disponibile.',
              style: TextStyle(color: context.muted)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 14,
          headingRowHeight: 40,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 40,
          columns: [
            const DataColumn(label: Text('Fermata')),
            for (final r in runs)
              DataColumn(
                label: Text(
                  '${r['start'] ?? ''}'.substring(0, 5),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
          rows: [
            for (var i = 0; i < stops.length; i++)
              DataRow(cells: [
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      '${stops[i]['name'] ?? ''}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                for (final r in runs)
                  DataCell(Text(
                    '${(r['times'] as List? ?? [])[i] ?? '—'}'
                        .substring(0, 5),
                    style: TextStyle(color: context.muted),
                  )),
              ]),
          ],
        ),
      ),
    );
  }
}

class _HeaderIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
            width: 44, height: 44, child: Icon(icon, color: Colors.white, size: 20)),
      ),
    );
  }
}
