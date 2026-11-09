import 'package:flutter/material.dart';

import '../l10n/l10n_ext.dart';
import '../services/line_colors.dart';
import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/line_badge.dart';
import 'stop_detail_screen.dart';

class StopsScreen extends StatefulWidget {
  const StopsScreen({super.key});

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen> {
  List<StopGroup>? _groups;
  Object? _error;
  String _query = '';
  String _view = 'list'; // 'list' | 'zones'
  String? _zone;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final groups = await StopsService.catalog(forceRefresh: _groups != null);
      if (!mounted) return;
      setState(() => _groups = groups);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups ?? const <StopGroup>[];
    final busGroups =
        groups.where((g) => g.service != 'navigation').toList();
    final navGroups =
        groups.where((g) => g.service == 'navigation').toList();
    final filtered = _query.isEmpty
        ? null
        : StopsService.search(groups, _query);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
                showBack: true, title: context.l10n.stopsAllTitle),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Column(
                children: [
                  // Tabs Elenco / Per zona
                  Container(
                    decoration: BoxDecoration(
                      color: context.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        for (final (v, label) in [
                          ('list', context.l10n.viewList),
                          ('zones', context.l10n.viewZones),
                        ])
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() { _view = v; _zone = null; }),
                              child: AnimatedContainer(
                                duration:
                                    const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _view == v
                                      ? context.surface
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  border: _view == v
                                      ? Border.all(color: context.border)
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      color: _view == v
                                          ? context.ink
                                          : context.muted,
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
                  if (_view == 'list') ...[
                    const SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(
                        hintText: context.l10n.searchStopHint,
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_error != null)
            SliverFillRemaining(
              child: ErrorView(error: _error!, onRetry: _load),
            )
          else if (_groups == null)
            const SliverFillRemaining(child: LoadingView())
          else if (_view == 'zones')
            _zonesSliver(groups)
          else ...[
            if (filtered != null && filtered.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text(context.l10n.noStationFound,
                      style: TextStyle(color: context.muted)),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: SectionTitle(context.l10n.stopsListTitle),
                ),
              ),
              _listSliver(filtered ?? busGroups),
              if (navGroups.isNotEmpty && _query.isEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                    child: SectionTitle(context.l10n.navStopsTitle),
                  ),
                ),
                _listSliver(navGroups, navigation: true),
              ] else if (navGroups.isNotEmpty && _query.isNotEmpty)
                _listSliver(
                    filtered!.where((g) => g.service == 'navigation').toList(),
                    navigation: true),
            ],
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _listSliver(List<StopGroup> list, {bool navigation = false}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) => _StationCard(
            group: list[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => StopDetailScreen(group: list[i]),
              ),
            ),
          ),
          childCount: list.length,
        ),
      ),
    );
  }

  Widget _zonesSliver(List<StopGroup> groups) {
    final zones = <String, List<StopGroup>>{};
    for (final g in groups) {
      final first = g.name.split(RegExp(r'\s+')).first.toUpperCase();
      zones.putIfAbsent(first, () => []).add(g);
    }
    final keys = zones.keys.toList()..sort();
    if (_zone != null) {
      final list = zones[_zone] ?? [];
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, i) {
              if (i == 0) {
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  onTap: () => setState(() => _zone = null),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back, color: context.blue),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(context.l10n.zoneTitle(_zone!),
                            style: TextStyle(
                                color: context.ink,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                );
              }
              return _StationCard(
                group: list[i - 1],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StopDetailScreen(group: list[i - 1]),
                  ),
                ),
              );
            },
            childCount: list.length + 1,
          ),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SectionTitle(context.l10n.zonesTitle),
              );
            }
            final k = keys[i - 1];
            return AppCard(
              margin: const EdgeInsets.only(bottom: 10),
              onTap: () => setState(() => _zone = k),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      k[0] + k.substring(1).toLowerCase(),
                      style: TextStyle(
                          color: context.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
                  ),
                  Text('${zones[k]!.length}',
                      style: TextStyle(
                          color: context.muted,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, color: context.muted),
                ],
              ),
            );
          },
          childCount: keys.length + 1,
        ),
      ),
    );
  }
}

/// Station card: stacked id badges, name, colored line badges, chevron.
class _StationCard extends StatelessWidget {
  final StopGroup group;
  final VoidCallback onTap;
  const _StationCard({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final aliases = group.lines.map((l) => l.alias).take(4).toList();
    final overflow = group.lines.length > 4;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Column(
            children: [
              for (final id in group.ids.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: StopIdBadge(id: id),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 3),
                if (!group.realtime)
                  Text(context.l10n.notRealtime,
                      style:
                          TextStyle(color: context.muted, fontSize: 12))
                else if (group.service == 'navigation')
                  Text(context.l10n.navLine,
                      style:
                          TextStyle(color: context.muted, fontSize: 13))
                else
                  _LineBadges(
                      service: 'bus',
                      aliases: aliases,
                      overflow: overflow),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.muted),
        ],
      ),
    );
  }
}

class _LineBadges extends StatelessWidget {
  final String service;
  final List<String> aliases;
  final bool overflow;
  const _LineBadges(
      {required this.service,
      required this.aliases,
      required this.overflow});

  @override
  Widget build(BuildContext context) {
    if (aliases.isEmpty) {
      return Text(context.l10n.noLinesAvailable,
          style: TextStyle(color: context.muted, fontSize: 13));
    }
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(context.l10n.linesLabel,
            style: TextStyle(color: context.muted, fontSize: 13)),
        for (final a in aliases)
          FutureBuilder<(Color, Color)>(
            future: LineColors.badge(service, a),
            builder: (context, snap) {
              final (bg, fg) =
                  snap.data ?? LineColors.fallbackBadge(a);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  a,
                  style: TextStyle(
                      color: fg,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              );
            },
          ),
        if (overflow)
          Text('…', style: TextStyle(color: context.muted)),
      ],
    );
  }
}
