import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/line_badge.dart';
import 'trip_details_screen.dart';

class StopDetailScreen extends StatefulWidget {
  final StopGroup group;
  const StopDetailScreen({super.key, required this.group});

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  List<StopLine>? _lines;
  Object? _error;
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    FavoritesService.isFavorite(widget.group.idsParam)
        .then((v) => mounted ? setState(() => _favorite = v) : null);
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final lines = <String, StopLine>{};
      if (widget.group.isNavigation) {
        for (final id in widget.group.ids) {
          final res = await ApiClient.get(
              '/api/navigation/passages', {'stop_id': id});
          for (final l in _extractLines(res)) {
            lines[l.shortName] = l;
          }
        }
      } else {
        for (final id in widget.group.ids) {
          final res =
              await ApiClient.get('/api/stop-lines', {'stop': id});
          if (res is Map && res['success'] == true) {
            for (final l in (res['lines'] as List? ?? [])) {
              final line = StopLine.fromJson(l);
              if (lines.containsKey(line.shortName)) {
                final existing = lines[line.shortName]!;
                lines[line.shortName] = StopLine(
                  routeId: existing.routeId,
                  shortName: existing.shortName,
                  longName: existing.longName,
                  service: existing.service,
                  mode: existing.mode,
                  color: existing.color,
                  textColor: existing.textColor,
                  departures: [...existing.departures, ...line.departures],
                );
              } else {
                lines[line.shortName] = line;
              }
            }
          }
        }
      }
      if (!mounted) return;
      setState(() => _lines = lines.values.toList());
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  List<StopLine> _extractLines(dynamic res) {
    final out = <StopLine>[];
    final list = res is Map ? (res['lines'] ?? res['passages'] ?? []) : res;
    if (list is List) {
      for (final l in list) {
        if (l is Map<String, dynamic>) {
          out.add(StopLine.fromJson(l));
        }
      }
    }
    return out;
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.toggle(widget.group);
    if (mounted) {
      setState(() => _favorite = !_favorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                showBack: true,
                title: g.name,
                subtitle: 'Fermata ${g.ids.join(', ')}',
                actions: [
                  _HeaderAction(
                    icon: _favorite ? Icons.star : Icons.star_border,
                    onTap: _toggleFavorite,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: const SectionTitle('Prossimi Passaggi'),
              ),
            ),
            if (_error != null)
              SliverFillRemaining(
                child: ErrorView(error: _error!, onRetry: _load),
              )
            else if (_lines == null)
              const SliverFillRemaining(
                  child: LoadingView(message: 'Caricamento passaggi...'))
            else if (_lines!.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Nessun passaggio previsto nelle prossime ore.',
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
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _LinePassageCard(line: _lines![i]),
                    childCount: _lines!.length,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Center(
                child: OutlinedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Aggiorna'),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HeaderAction({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _LinePassageCard extends StatelessWidget {
  final StopLine line;
  const _LinePassageCard({required this.line});

  @override
  Widget build(BuildContext context) {
    final departures = [...line.departures]..sort((a, b) => a.time.compareTo(b.time));
    final unique = <String>{};
    final times = <Departure>[];
    for (final d in departures) {
      if (unique.add('${d.time}|${d.tripId}')) times.add(d);
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LineBadge(
                label: line.shortName,
                color: line.color,
                textColor: line.textColor,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  times.isNotEmpty ? times.first.destination : line.longName,
                  style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in times.take(8))
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: d.tripId.isEmpty
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TripDetailsScreen(tripId: d.tripId),
                            ),
                          ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: context.border),
                    ),
                    child: Text(
                      '${d.time.substring(0, 5)}${d.inMin != null ? ' (${d.inMin} min)' : ''}',
                      style: TextStyle(
                        color: context.ink,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              if (times.isEmpty)
                Text('Nessuna partenza',
                    style: TextStyle(color: context.muted, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }
}
