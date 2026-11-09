import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/l10n_ext.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/slim_header.dart';
import '../widgets/service_switch.dart';

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
          SlimHeader(
            showBack: true,
            title: context.l10n.moreLineSchedules,
            subtitle:
                _line == null ? context.l10n.chooseLine : context.l10n.lineDay(_line!, localizedDay(context, _day)),
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
            child: AppCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ServiceSwitch(
                        mode: _service,
                        allowBoth: false,
                        onChanged: (v) {
                          setState(() => _service = v);
                          _loadCatalog();
                        },
                      ),
                      const Spacer(),
                      if (_line != null)
                        TextButton.icon(
                          onPressed: () => setState(() {
                            _line = null;
                            _variants = null;
                            _schedule = null;
                          }),
                          icon: const Icon(Icons.arrow_back,
                              size: 16),
                          label: Text(context.l10n.linesChip),
                        ),
                    ],
                  ),
                  if (_line == null) ...[
                    const SizedBox(height: 10),
                    SectionLabel(context.l10n.lsSearchLabel),
                    const SizedBox(height: 6),
                    TextField(
                      decoration: InputDecoration(
                        hintText: context.l10n.searchLineHint,
                        prefixIcon: const Icon(Icons.search,
                            size: 20),
                        isDense: true,
                      ),
                      onChanged: (v) =>
                          setState(() => _search = v),
                    ),
                    const SizedBox(height: 10),
                    SectionLabel(context.l10n.lineLabel),
                    const SizedBox(height: 6),
                    _linePicker(),
                  ],
                ],
              ),
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
    if (_line == null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          _catalog == null
              ? context.l10n.loading
              : context.l10n.chooseLine,
          style: TextStyle(color: context.muted),
        ),
      ));
    }
    return const LoadingView();
  }

  /// `<select id="line-input">` populated from the catalog, filtered by
  /// the search field — mirrors `lineSchedule.js` line picker.
  Widget _linePicker() {
    final entries = _catalog ?? const <LineCatalogEntry>[];
    final filtered = _search.isEmpty
        ? entries
        : entries
            .where((e) =>
                e.line.toLowerCase().contains(_search.toLowerCase()) ||
                e.name.toLowerCase().contains(_search.toLowerCase()))
            .toList();
    return DropdownButtonFormField<String>(
      isExpanded: true,
      decoration: InputDecoration(
        hintText: _catalog == null
            ? context.l10n.loading
            : context.l10n.chooseLine,
        isDense: true,
      ),
      items: [
        for (final e in filtered)
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
    );
  }

  Widget _variantsView() {
    if (_variants!.isEmpty) {
      return Center(
          child: Text(context.l10n.noActiveVariants,
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
                context.l10n.variantInfo(v.origin, v.terminus, v.stopsCount, v.tripsCount),
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
          child: Text(context.l10n.noScheduleAvailable,
              style: TextStyle(color: context.muted)));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            context.l10n.scheduleSummary(stops.length, runs.length),
            style: TextStyle(color: context.muted, fontSize: 13),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 14,
          headingRowHeight: 40,
          dataRowMinHeight: 34,
          dataRowMaxHeight: 40,
          columns: [
            DataColumn(label: Text(context.l10n.stopColumn)),
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
        ),
        ),
      ],
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
