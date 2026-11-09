import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../l10n/l10n_ext.dart';
import '../main.dart';
import '../services/stops_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/home_shared.dart';
import '../widgets/qr_fab.dart';
import '../widgets/stop_tile.dart';
import 'delay_stats_screen.dart';
import 'feedback_screen.dart';
import 'line_schedule_screen.dart';
import 'route_finder_screen.dart';
import 'stop_detail_screen.dart';
import 'trip_finder_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<StopGroup> _groups = [];
  List<StopGroup> _nearby = [];
  Set<String> _favorites = {};
  LatLng? _userPos;
  String _status = 'waiting';
  bool _located = false;
  bool _showTutorial = false;
  Map<String, dynamic>? _journeyOrigin;
  Map<String, dynamic>? _journeyDestination;
  StrikeResult? _strike;

  // Tour anchors
  final _nearbyKey = GlobalKey();
  final _favoritesKey = GlobalKey();
  final _mapKey = GlobalKey();
  final _actionsKey = GlobalKey();
  final _ctaKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
    StrikeCheck.run().then((r) {
      if (r != null && mounted) setState(() => _strike = r);
    });
  }

  Future<void> _load() async {
    _favorites = await FavoritesService.loadIdParams();
    _showTutorial =
        (await Storage.getString(Storage.homeTutorialSeen)) == null;
    _journeyOrigin =
        await Storage.getJson(Storage.routeOrigin) as Map<String, dynamic>?;
    _journeyDestination =
        await Storage.getJson(Storage.routeDestination)
            as Map<String, dynamic>?;
    if (mounted) setState(() {});

    try {
      _groups = await StopsService.catalog();
      if (!mounted) return;
      setState(() {});
    } catch (_) {}

    final pos = await StopsService.locate();
    if (!mounted) return;
    if (pos != null) {
      setState(() {
        _userPos = LatLng(pos.latitude, pos.longitude);
        _located = true;
        _status = 'found';
        if (_groups.isNotEmpty) {
          _nearby = StopsService.nearby(_groups, pos.latitude, pos.longitude);
        }
      });
    } else {
      setState(() => _status = 'unavailable');
    }
  }

  String _statusText(BuildContext context) => switch (_status) {
        'found' => context.l10n.geoFound,
        'unavailable' => context.l10n.geoUnavailable,
        _ => context.l10n.geoWaiting,
      };

  void _startTour() {
    final l10n = context.l10n;
    final steps = <HomeTourStep>[
      if (_nearbyKey.currentContext != null)
        HomeTourStep(_nearbyKey, l10n.tourNearbyTitle,
            l10n.tourNearbyBody),
      if (_favoritesKey.currentContext != null)
        HomeTourStep(_favoritesKey, l10n.tourFavsTitle,
            l10n.tourFavsBody),
      HomeTourStep(_mapKey, l10n.tourMapTitle,
          l10n.tourMapBody),
      HomeTourStep(_actionsKey, l10n.tourMoreTitle,
          l10n.tourMoreBody),
      HomeTourStep(_ctaKey, l10n.tourCtaTitle,
          l10n.tourCtaBody),
    ];
    HomeTour.run(context, steps, onDone: _dismissTutorial);
  }

  Future<void> _dismissTutorial() async {
    setState(() => _showTutorial = false);
    await Storage.setString(Storage.homeTutorialSeen, '1');
  }

  void _openStop(StopGroup g) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StopDetailScreen(group: g)),
    ).then((_) async {
      _favorites = await FavoritesService.loadIdParams();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final favGroups = _groups
        .where((g) => _favorites.any((f) {
              final ids = g.idsParam.split('-');
              return f.split('-').any((i) => ids.contains(i));
            }))
        .toList();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                brand: 'Bussolà',
                title: context.l10n.homeTitle,
                subtitle: context.l10n.homeSubtitle,
                actions: [
                  ThemeToggleButton(
                    mode: BussolaApp.of(context).themeMode,
                    onChanged: BussolaApp.of(context).setThemeMode,
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (_showTutorial) _tutorialCard(),
                  SectionLabel(context.l10n.actvService),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.whereBus,
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryAction(
                    key: _ctaKey,
                    onTap: () => MainShell.of(context).select(1),
                  ),
                  const SizedBox(height: 24),
                  if (_journeyOrigin?['name'] != null &&
                      _journeyDestination?['name'] != null)
                    JourneyResumeCard(
                      origin: '${_journeyOrigin!['name']}',
                      destination: '${_journeyDestination!['name']}',
                      onResume: () => resumeJourney(
                          context, _journeyOrigin!, _journeyDestination!),
                      onModify: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RouteFinderScreen()),
                      ),
                    ),
                  if (favGroups.isNotEmpty) ...[
                    Container(
                      key: _favoritesKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionTitle(context.l10n.yourStops),
                          for (final g in favGroups)
                            StopTile(
                              group: g,
                              subtitle: context.l10n.favBadge,
                              onTap: () => _openStop(g),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                  ],
                  Container(
                    key: _nearbyKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(context.l10n.nearbyStops),
                        if (_nearby.isEmpty)
                          Text(
                            _userPos == null
                                ? _statusText(context)
                                : context.l10n.noNearbyStops,
                            style: TextStyle(
                                color: context.muted, fontSize: 14),
                          )
                        else
                          for (final g in _nearby)
                            StopTile(
                              group: g,
                              distance: _userPos == null
                                  ? null
                                  : StopsService.distanceTo(g,
                                      _userPos!.latitude,
                                      _userPos!.longitude),
                              onTap: () => _openStop(g),
                            ),
                      ],
                    ),
                  ),
                  const Divider(height: 32),
                  Container(
                    key: _mapKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(context.l10n.mapTitle),
                        HomeStatusBanner(
                            text: _statusText(context), success: _located),
                        HomeMap(
                          groups: _groups,
                          nearby: _nearby,
                          userPos: _userPos,
                          onOpenStop: _openStop,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(key: _actionsKey, child: _ActionGrid()),
                  const SizedBox(height: 32),
                  const HomeFooter(),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _strike != null
          ? StrikeFab(
              onTap: () => showStrikeDialog(context, _strike!))
          : const QrFab(),
    );
  }

  Widget _tutorialCard() {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(context.l10n.welcome),
          const SizedBox(height: 6),
          Text(
            context.l10n.tourQ,
            style: TextStyle(
              color: context.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.tourIntroBody,
            style: TextStyle(color: context.muted, fontSize: 14),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: _startTour,
                  style: FilledButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(context.l10n.startTour),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _dismissTutorial,
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    minimumSize: const Size(0, 44),
                  ),
                  child: Text(context.l10n.coachSkip),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Cerca una fermata" CTA card (`home-primary-action`).
class _PrimaryAction extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryAction({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.adjust,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.searchStop,
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    context.l10n.searchStopSub,
                    style:
                        TextStyle(color: context.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.blue),
          ],
        ),
      ),
    );
  }
}

/// `.home-actions` — compact icon tiles (icon + title + subtitle).
class _ActionGrid extends StatelessWidget {
  void _push(BuildContext context, Widget screen) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final actions = <(IconData, String, String, VoidCallback, Color?)>[
      (Icons.adjust, l10n.searchStop, l10n.searchStopSub,
          () => MainShell.of(context).select(1), null),
      (Icons.route_rounded, l10n.navRoutes, l10n.actRoutesSub,
          () => MainShell.of(context).select(2), null),
      (Icons.schedule, l10n.actSchedules, l10n.actSchedulesSub,
          () => _push(context, const LineScheduleScreen()), null),
      (Icons.directions_bus, l10n.actTripSearch, l10n.actTripSearchSub,
          () => _push(context, const TripFinderScreen()), null),
      (Icons.bar_chart, l10n.actDelays, l10n.actDelaysSub,
          () => _push(context, const DelayStatsScreen()), null),
      (Icons.edit_outlined, l10n.moreFeedback, l10n.feedbackTileSub,
          () => _push(context, const FeedbackScreen()), context.green),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final cols = constraints.maxWidth > 520 ? 3 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
        children: [
          for (final (icon, label, sub, action, color) in actions)
            AppCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onTap: action,
              child: Row(
                children: [
                  Icon(icon, color: color ?? context.ink, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: color ?? context.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.muted,
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }
}
