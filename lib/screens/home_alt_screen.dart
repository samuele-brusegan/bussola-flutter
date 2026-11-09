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
import 'lines_map_screen.dart';
import 'line_schedule_screen.dart';
import 'live_map_screen.dart';
import 'route_finder_screen.dart';
import 'stop_detail_screen.dart';
import 'trip_finder_screen.dart';

/// Port of `/home-alt` — "product hero" variant: hero verde arrotondato con
/// barra di ricerca finta, card tutorial/resume, griglia 6 action card,
/// sezioni preferiti/vicini, mappa condivisa e footer compatto.
class HomeAltScreen extends StatefulWidget {
  const HomeAltScreen({super.key});

  @override
  State<HomeAltScreen> createState() => _HomeAltScreenState();
}

class _HomeAltScreenState extends State<HomeAltScreen> {
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

  final _actionsKey = GlobalKey();
  final _nearbyKey = GlobalKey();
  final _mapKey = GlobalKey();

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
      if (mounted) setState(() {});
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

  void _goToStops() {
    MainShell.of(context).select(1);
    Navigator.pop(context);
  }

  String _statusText(BuildContext context) => switch (_status) {
        'found' => context.l10n.geoFound,
        'unavailable' => context.l10n.geoUnavailable,
        _ => context.l10n.geoWaiting,
      };

  void _startTour() {
    final l10n = context.l10n;
    final steps = <HomeTourStep>[
      HomeTourStep(_actionsKey, l10n.tourActionsTitle,
          l10n.tourActionsBody),
      if (_nearbyKey.currentContext != null)
        HomeTourStep(_nearbyKey, l10n.tourNearbyTitle,
            l10n.tourNearbyBody),
      HomeTourStep(_mapKey, l10n.tourMapTitle,
          l10n.tourMapBody),
    ];
    HomeTour.run(context, steps, onDone: _dismissTutorial);
  }

  Future<void> _dismissTutorial() async {
    setState(() => _showTutorial = false);
    await Storage.setString(Storage.homeTutorialSeen, '1');
  }

  void _openStop(StopGroup g) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => StopDetailScreen(group: g)));

  @override
  Widget build(BuildContext context) {
    final favs = _groups.where((g) => _favorites.any((f) {
          final ids = g.idsParam.split('-');
          return f.split('-').any((i) => ids.contains(i));
        })).toList();

    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(child: _hero()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_showTutorial) _tutorialCard(),
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
              Container(key: _actionsKey, child: _actionGrid()),
              const SizedBox(height: 20),
              if (favs.isNotEmpty) ...[
                SectionTitle(context.l10n.yourStops),
                for (final g in favs)
                  StopTile(
                      group: g,
                      subtitle: context.l10n.favBadge,
                      onTap: () => _openStop(g)),
                const Divider(height: 28),
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
                              : StopsService.distanceTo(
                                  g,
                                  _userPos!.latitude,
                                  _userPos!.longitude),
                          onTap: () => _openStop(g),
                        ),
                  ],
                ),
              ),
              const Divider(height: 28),
              Container(
                key: _mapKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(context.l10n.stopsMapTitle),
                    HomeStatusBanner(text: _statusText(context), success: _located),
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
              const HomeFooter(compact: true),
            ]),
          ),
        ),
      ]),
      floatingActionButton: _strike != null
          ? StrikeFab(onTap: () => showStrikeDialog(context, _strike!))
          : const QrFab(url: '/home-alt'),
    );
  }

  /// `ha-hero` — green rounded hero with pill brand, theme toggle and the
  /// fake search bar linking to the stops list.
  Widget _hero() {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + 12, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: context.isDark
                ? const [Color(0xFF0E5A3C), Color(0xFF15935E)]
                : const [AppColors.lightGreenDark, AppColors.lightGreen],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.55)),
                  ),
                  child: const Text(
                    'Bussolà',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Spacer(),
                ThemeToggleButton(
                  mode: BussolaApp.of(context).themeMode,
                  onChanged: BussolaApp.of(context).setThemeMode,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              context.l10n.homeTitleAlt,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 30,
                height: 1.1,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.homeSubtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.82),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 18),
            // ha-search — fake search bar
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _goToStops,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: Color(0xFF64736F), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.l10n.searchStop,
                          style: TextStyle(
                            color: Color(0xFF64736F),
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppColors.lightGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chevron_right,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tutorialCard() {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.tourQ,
            style: TextStyle(
              color: context.ink,
              fontSize: 20,
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
                    backgroundColor: context.greenDark,
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

  /// `ha-actions` — 6 tiles with icon, title and subtitle.
  Widget _actionGrid() {
    final l10n = context.l10n;
    final actions = <(IconData, String, String, Widget)>[
      (Icons.route_rounded, l10n.navRoutes, l10n.actRoutesSub,
          const RouteFinderScreen()),
      (Icons.radar, l10n.actLiveMap, l10n.actLiveMapSub,
          const LiveMapScreen()),
      (Icons.schedule, l10n.actSchedules, l10n.actSchedulesSub,
          const LineScheduleScreen()),
      (Icons.directions_bus, l10n.actTripSearch, l10n.actTripSearchSub,
          const TripFinderScreen()),
      (Icons.bar_chart, l10n.actDelays, l10n.actDelaysSub,
          const DelayStatsScreen()),
      (Icons.map_outlined, l10n.actNetwork, l10n.actNetworkSub,
          const LinesMapScreen()),
    ];
    return LayoutBuilder(builder: (context, c) {
      final cols = c.maxWidth > 520 ? 3 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.9,
        children: [
          for (final (icon, label, sub, screen) in actions)
            AppCard(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              onTap: () => Navigator.push(
                  context, MaterialPageRoute(builder: (_) => screen)),
              child: Row(
                children: [
                  Icon(icon, color: context.ink, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: context.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.muted,
                            fontSize: 12,
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
