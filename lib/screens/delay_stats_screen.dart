import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
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

  double _maxDelay() {
    if (_history == null || _history!.isEmpty) return 0;
    return _history!
            .map((r) => (r['delay'] as num? ?? 0).toInt())
            .reduce((a, b) => a > b ? a : b) /
        60;
  }

  static Color _delayColor(double avgMin) => avgMin > 10
      ? const Color(0xFFE30613)
      : avgMin > 5
          ? AppColors.orange
          : const Color(0xFF009E61);

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
          SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              title: context.l10n.moreDelayStats,
              subtitle: context.l10n.delayStatsSubtitle,
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
                    context.l10n.noDelaysRecorded,
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
                          label: context.l10n.observations,
                          value: '$totalRecords',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: context.l10n.avgDelay,
                          value: '${avgAll.toStringAsFixed(1)} min',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatCard(
                          label: context.l10n.maxDelay,
                          value: '${_maxDelay().toStringAsFixed(0)} min',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _QuickStats(stats: stats),
                  const SizedBox(height: 16),
                  SectionTitle(context.l10n.delaysByHour),
                  _HourlyChart(history: _history!),
                  const SizedBox(height: 20),
                  SectionTitle(context.l10n.perLine),
                  for (final s in stats)
                    AppCard(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              LineBadge(label: s.line),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context.l10n.avgDelayMin(s.avgDelay.toStringAsFixed(1)),
                                      style: TextStyle(
                                        color: context.ink,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${s.count} osservazioni · max ${s.maxDelay} min',
                                      style: TextStyle(
                                          color: context.muted,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _DelayBar(
                            fraction: s.avgDelay /
                                stats
                                    .map((x) => x.avgDelay)
                                    .fold<double>(
                                        0, (a, b) => a > b ? a : b)
                                    .clamp(1, 999),
                            color: _delayColor(s.avgDelay),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (d) => AlertDialog(
                            title: Text(context.l10n.clearHistory),
                            content: Text(context.l10n
                                .clearHistoryConfirm),
                            actions: [
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(d, false),
                                  child: Text(context.l10n.cancel)),
                              FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(d, true),
                                  child: Text(context.l10n.delete)),
                            ],
                          ),
                        );
                        if (ok == true) {
                          await DelayService.clear();
                          _load();
                        }
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: Text(context.l10n.clearHistory),
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

class _DelayBar extends StatelessWidget {
  final double fraction;
  final Color color;
  const _DelayBar({required this.fraction, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Stack(
          children: [
            Container(color: context.surface2),
            FractionallySizedBox(
              widthFactor: fraction.clamp(0.02, 1.0),
              child: Container(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick stats: worst line, best/worst hour (port of getOverallStats).
class _QuickStats extends StatelessWidget {
  final List<LineDelayStat> stats;
  const _QuickStats({required this.stats});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(context.l10n.worstLine),
                const SizedBox(height: 4),
                Text(
                  stats.isEmpty ? '-' : stats.first.line,
                  style: TextStyle(
                      color: context.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Hourly delay histogram with threshold colors.
class _HourlyChart extends StatelessWidget {
  final List<Map<String, dynamic>> history;
  const _HourlyChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final byHour = List<double>.filled(24, 0);
    final counts = List<int>.filled(24, 0);
    for (final r in history) {
      final h = (r['hour'] as num? ??
              (r['timestamp'] is num
                  ? DateTime.fromMillisecondsSinceEpoch(
                          (r['timestamp'] as num).toInt())
                      .hour
                  : 0))
          .toInt();
      if (h >= 0 && h < 24) {
        byHour[h] += (r['delay'] as num? ?? 0).toInt();
        counts[h]++;
      }
    }
    final avgs = [
      for (var i = 0; i < 24; i++)
        counts[i] == 0 ? 0.0 : byHour[i] / counts[i] / 60
    ];
    final maxAvg = avgs.fold(0.0, (a, b) => a > b ? a : b);
    return AppCard(
      child: SizedBox(
        height: 110,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < 24; i++)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: maxAvg == 0
                          ? 2
                          : (80 * avgs[i] / maxAvg).clamp(2, 80),
                      margin:
                          const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        color: counts[i] == 0
                            ? context.border
                            : _DelayStatsScreenState._delayColor(avgs[i]),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$i',
                        style: TextStyle(
                            color: context.muted, fontSize: 8)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
