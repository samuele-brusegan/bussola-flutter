import 'package:flutter/material.dart';

import '../services/delay_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/line_badge.dart';

class DelayStatsScreen extends StatefulWidget {
  const DelayStatsScreen({super.key});

  @override
  State<DelayStatsScreen> createState() => _DelayStatsScreenState();
}

class _DelayStatsScreenState extends State<DelayStatsScreen> {
  List<Map<String, dynamic>>? _history;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final h = await DelayService.history();
    if (mounted) setState(() => _history = h);
  }

  List<LineDelayStat> _stats() {
    final byLine = <String, List<int>>{};
    for (final r in _history!) {
      final line = '${r['line'] ?? ''}'.split('_').first;
      final delay = (r['delay'] as num? ?? 0).toInt();
      if (line.isEmpty) continue;
      byLine.putIfAbsent(line, () => []).add(delay);
    }
    final stats = byLine.entries
        .map((e) => LineDelayStat(
              line: e.key,
              count: e.value.length,
              avgDelay: e.value.reduce((a, b) => a + b) / e.value.length / 60,
              maxDelay: e.value.reduce((a, b) => a > b ? a : b) ~/ 60,
            ))
        .toList()
      ..sort((a, b) => b.avgDelay.compareTo(a.avgDelay));
    return stats;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _history == null ? null : _stats();
    final totalRecords = _history?.length ?? 0;
    final avgAll = _history == null || _history!.isEmpty
        ? 0.0
        : _history!
                .map((r) => (r['delay'] as num? ?? 0).toInt())
                .reduce((a, b) => a + b) /
            _history!.length /
            60;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              title: 'Statistiche ritardi',
              subtitle: 'Ritardi osservati su questo dispositivo',
            ),
          ),
          if (stats == null)
            const SliverFillRemaining(child: LoadingView())
          else if (stats.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Nessun ritardo registrato.\nI dati vengono raccolti mentre usi la mappa dei bus.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.muted),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Ritardo medio',
                          value: '${avgAll.toStringAsFixed(1)} min',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: 'Osservazioni',
                          value: '$totalRecords',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const SectionTitle('Per linea'),
                  for (final s in stats)
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          LineBadge(label: s.line),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Media ${s.avgDelay.toStringAsFixed(1)} min',
                                  style: TextStyle(
                                    color: context.ink,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${s.count} osservazioni · max ${s.maxDelay} min',
                                  style: TextStyle(
                                      color: context.muted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          _DelayDot(avgMin: s.avgDelay),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        await DelayService.clear();
                        _load();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Cancella storico'),
                    ),
                  ),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: context.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DelayDot extends StatelessWidget {
  final double avgMin;
  const _DelayDot({required this.avgMin});

  @override
  Widget build(BuildContext context) {
    final color = avgMin >= 10
        ? AppColors.red
        : avgMin >= 5
            ? AppColors.orange
            : context.green;
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
