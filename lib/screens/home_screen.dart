import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

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
  String _status = 'In attesa di geolocalizzazione...';
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
        _status = 'Posizione trovata. Ecco le stazioni più vicine.';
        if (_groups.isNotEmpty) {
          _nearby = StopsService.nearby(_groups, pos.latitude, pos.longitude);
        }
      });
    } else {
      setState(() => _status = 'Geolocalizzazione non disponibile');
    }
  }

  void _startTour() {
    final steps = <HomeTourStep>[
      if (_nearbyKey.currentContext != null)
        HomeTourStep(_nearbyKey, 'Fermate vicine',
            'Con la geolocalizzazione attiva, qui compaiono le fermate più vicine a te.'),
      if (_favoritesKey.currentContext != null)
        HomeTourStep(_favoritesKey, 'Le tue fermate',
            'Le fermate che salvi con la stella le ritrovi sempre qui.'),
      HomeTourStep(_mapKey, 'La mappa',
          'Ogni pallino è una fermata: toccalo per aprire i passaggi in tempo reale.'),
      HomeTourStep(_actionsKey, 'Tutto il resto',
          'Da qui: percorsi con cambio, orari delle linee, statistiche sui ritardi e ricerca di una corsa. Le altre funzioni sono nel menu "Altro" in basso.'),
      HomeTourStep(_ctaKey, 'Cerca una fermata',
          'Tutto parte da qui: tocca il pulsante per aprire l\'elenco delle fermate.'),
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
                title: 'Il tuo viaggio,\nin tempo reale.',
                subtitle: 'Orari, fermate e percorsi ACTV a Venezia',
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
                  const SectionLabel('Servizio ACTV'),
                  const SizedBox(height: 6),
                  Text(
                    'Dove passa il tuo bus?',
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
                          const SectionTitle('Le tue fermate'),
                          for (final g in favGroups)
                            StopTile(
                              group: g,
                              subtitle: '★ Preferita',
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
                        const SectionTitle('Fermate vicine'),
                        if (_nearby.isEmpty)
                          Text(
                            _userPos == null
                                ? _status
                                : 'Nessuna fermata trovata nelle vicinanze.',
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
                        const SectionTitle('Mappa'),
                        HomeStatusBanner(
                            text: _status, success: _located),
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
          const SectionLabel('Benvenuto'),
          const SizedBox(height: 6),
          Text(
            'Vuoi fare un giro?',
            style: TextStyle(
              color: context.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ti mostro in pochi secondi dove sono fermate, mappa, preferiti '
            'e tutte le altre funzioni dell\'app.',
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
                  child: const Text('Inizia il tour'),
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
                  child: const Text('Salta'),
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
                    'Cerca una fermata',
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Passaggi in tempo reale per ogni fermata',
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

/// `.home-actions` — text-only pill buttons, 2 cols (1 ≤ 430px).
class _ActionGrid extends StatelessWidget {
  void _push(BuildContext context, Widget screen) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ('Cerca una fermata', () => MainShell.of(context).select(1), false),
      ('Percorsi', () => MainShell.of(context).select(2), false),
      ('Statistiche ritardi',
          () => _push(context, const DelayStatsScreen()), false),
      ('Orari delle linee',
          () => _push(context, const LineScheduleScreen()), false),
      ('Cerca una corsa',
          () => _push(context, const TripFinderScreen()), false),
      ('Invia feedback',
          () => _push(context, const FeedbackScreen()), true),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final twoCols = constraints.maxWidth > 430;
      return GridView.count(
        crossAxisCount: twoCols ? 2 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: twoCols ? 4.2 : 5.2,
        children: [
          for (final (label, action, isFeedback) in buttons)
            FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isFeedback ? context.greenDark : context.blue,
                shape: const StadiumBorder(),
              ),
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      );
    });
  }
}
