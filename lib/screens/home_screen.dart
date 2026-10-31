import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../services/actv_realtime.dart';
import '../services/stops_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/qr_fab.dart';
import '../widgets/stop_tile.dart';
import 'credits_screen.dart';
import 'delay_stats_screen.dart';
import 'feedback_screen.dart';
import 'line_schedule_screen.dart';
import 'route_finder_screen.dart';
import 'route_results_screen.dart';
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
  bool _showTutorial = false;
  Map<String, dynamic>? _journeyOrigin;
  Map<String, dynamic>? _journeyDestination;
  StopGroup? _mapSelected;

  static const _venice = LatLng(45.4384, 12.3359);

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
    _checkStrike();
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
        _status = 'Posizione trovata. Ecco le stazioni più vicine.';
        if (_groups.isNotEmpty) {
          _nearby = StopsService.nearby(_groups, pos.latitude, pos.longitude);
        }
      });
    } else {
      setState(() => _status = 'Geolocalizzazione non disponibile');
    }
  }

  // ── Rilevamento sciopero (port di checkImportantNotices) ──

  static const _strikeSampleSize = 15;
  List<({String id, String name})> _emptyStops = [];
  String _strikeNotice = '';
  bool _strike = false;

  Future<void> _checkStrike() async {
    if (DateTime.now().hour < 5) return;
    try {
      final catalog = await ActvRealtime.stopsCatalog();
      final stops = [
        for (final s in catalog)
          if ('${s['name'] ?? ''}'.isNotEmpty)
            (
              rawId: '${s['name']}',
              id: '${s['name']}'.replaceAll(RegExp(r'-web-aut$'), ''),
              name: '${s['description'] ?? ''}'
                  .replaceAll(RegExp(r'\[\d+\]'), '')
                  .trim(),
            )
      ];
      if (stops.isEmpty) return;
      final step =
          (stops.length / _strikeSampleSize).floor().clamp(1, stops.length);
      final sample = <({String rawId, String id, String name})>[];
      for (var i = 0;
          i < stops.length && sample.length < _strikeSampleSize;
          i += step) {
        sample.add(stops[i]);
      }
      final checks = await Future.wait(sample.map((stop) async {
        try {
          final results = await Future.wait([
            ActvRealtime.passages(stop.id,
                timeout: const Duration(seconds: 3)),
            ActvRealtime.noticeboard(stop.id),
          ]);
          return (
            stop: stop,
            hasPassages:
                results[0] == null ? null : (results[0] as List).isNotEmpty,
            text: '${results[1] ?? ''}',
          );
        } catch (_) {
          return null;
        }
      }));
      final valid = checks.whereType().toList();
      final notice = valid
              .map((r) => r.text)
              .firstWhere((t) => RegExp('sciopero', caseSensitive: false).hasMatch(t),
                  orElse: () => '');
      final noneHasPassages = valid.length == sample.length &&
          valid.every((r) => r.hasPassages == false);
      if (notice.isEmpty && !noneHasPassages) return;
      if (!mounted) return;
      setState(() {
        _strike = true;
        _strikeNotice = notice;
        _emptyStops = <({String id, String name})>[
          for (final r in valid)
            if (r.hasPassages == false)
              (id: r.stop.id, name: r.stop.name)
        ];
      });
    } catch (_) {}
  }

  void _showStrikeModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.actvRed),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _strikeNotice.isNotEmpty
                    ? 'Sciopero'
                    : 'Possibile sciopero in corso',
                style: TextStyle(
                    color: ctx.ink, fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_strikeNotice.isNotEmpty)
                Text(_strikeNotice, style: TextStyle(color: ctx.ink))
              else
                Text(
                  'Il servizio in tempo reale non risponde su '
                  '${_emptyStops.length} fermate controllate: è probabile '
                  'uno sciopero o un\'interruzione del servizio. Gli orari '
                  'previsti potrebbero non essere rispettati.',
                  style: TextStyle(color: ctx.ink),
                ),
              if (_emptyStops.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('Fermate senza passaggi rilevati:',
                    style: TextStyle(color: ctx.muted, fontSize: 13)),
                const SizedBox(height: 6),
                for (final s in _emptyStops)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(ctx);
                        final g = StopGroup(
                            name: s.name.isEmpty ? 'Fermata ${s.id}' : s.name,
                            service: 'automobilistico',
                            realtime: true)
                          ..ids.addAll(s.id.split('-'));
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => StopDetailScreen(group: g)),
                        );
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              s.name.isEmpty ? 'Fermata ${s.id}' : s.name,
                              style: TextStyle(
                                  color: ctx.blue,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text('#${s.id}',
                              style: TextStyle(
                                  color: ctx.muted, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ho capito'),
          ),
        ],
      ),
    );
  }

  // ── Tour guidato (port semplificato di ACTVTour) ──

  void _startTour() {
    final steps = <_TourStep>[
      if (_nearbyKey.currentContext != null)
        _TourStep(_nearbyKey, 'Fermate vicine',
            'Con la geolocalizzazione attiva, qui compaiono le fermate più vicine a te.'),
      if (_favoritesKey.currentContext != null)
        _TourStep(_favoritesKey, 'Le tue fermate',
            'Le fermate che salvi con la stella le ritrovi sempre qui.'),
      _TourStep(_mapKey, 'La mappa',
          'Ogni pallino è una fermata: toccalo per aprire i passaggi in tempo reale.'),
      _TourStep(_actionsKey, 'Tutto il resto',
          'Da qui: percorsi con cambio, orari delle linee, statistiche sui ritardi e ricerca di una corsa. Le altre funzioni sono nel menu "Altro" in basso.'),
      _TourStep(_ctaKey, 'Cerca una fermata',
          'Tutto parte da qui: tocca il pulsante per aprire l\'elenco delle fermate.'),
    ];
    _showTourStep(steps, 0);
  }

  void _showTourStep(List<_TourStep> steps, int index) async {
    if (index >= steps.length) {
      _dismissTutorial();
      return;
    }
    final step = steps[index];
    final ctx = step.key.currentContext;
    if (ctx == null) {
      _showTourStep(steps, index + 1);
      return;
    }
    await Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 350),
        alignment: 0.3);
    if (!mounted) return;
    final box = ctx.findRenderObject() as RenderBox;
    final rect = box.localToGlobal(Offset.zero) & box.size;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TourOverlay(
        rect: rect,
        title: step.title,
        text: step.text,
        isLast: index == steps.length - 1,
        onNext: () {
          entry.remove();
          _showTourStep(steps, index + 1);
        },
        onSkip: () {
          entry.remove();
          _dismissTutorial();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }

  Future<void> _dismissTutorial() async {
    setState(() => _showTutorial = false);
    await Storage.setString(Storage.homeTutorialSeen, '1');
  }

  // ── Journey resume ──

  Future<void> _resumeJourney() async {
    final now = DateTime.now();
    final rounded = DateTime(now.year, now.month, now.day, now.hour,
        ((now.minute + 4) ~/ 5) * 5);
    await Storage.setString(Storage.routeDepartureDate,
        '${rounded.year}-${rounded.month.toString().padLeft(2, '0')}-${rounded.day.toString().padLeft(2, '0')}');
    await Storage.setString(Storage.routeDepartureTime,
        '${rounded.hour.toString().padLeft(2, '0')}:${rounded.minute.toString().padLeft(2, '0')}');
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteResultsScreen(
          origin: _journeyOrigin!,
          destination: _journeyDestination!,
          date: rounded,
          time: TimeOfDay.fromDateTime(rounded),
          optimize: 'time',
        ),
      ),
    );
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

  // ── Build ──

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
                brand: 'ACTV Live',
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
                    _journeyResume(),
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
                            style:
                                TextStyle(color: context.muted, fontSize: 14),
                          )
                        else
                          for (final g in _nearby)
                            StopTile(
                              group: g,
                              distance: _userPos == null
                                  ? null
                                  : StopsService.distanceTo(g,
                                      _userPos!.latitude, _userPos!.longitude),
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
                        _StatusBanner(text: _status),
                        const SizedBox(height: 12),
                        _buildMap(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(key: _actionsKey, child: _ActionGrid()),
                  const SizedBox(height: 32),
                  const _Footer(),
                ]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _strike ? _StrikeFab(onTap: _showStrikeModal) : const QrFab(),
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

  Widget _journeyResume() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Il tuo ultimo viaggio'),
            const SizedBox(height: 6),
            Text(
              '${_journeyOrigin!['name']} → ${_journeyDestination!['name']}',
              style: TextStyle(
                color: context.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _resumeJourney,
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('Riprendi viaggio'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RouteFinderScreen()),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      minimumSize: const Size(0, 44),
                    ),
                    child: const Text('Modifica'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: SizedBox(
        height: 300,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: _userPos ?? _venice,
                initialZoom: 12,
                onTap: (_, _) => setState(() => _mapSelected = null),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'it.brusegan.bussola',
                ),
                MarkerLayer(
                  markers: [
                    for (final g in _groups)
                      if (g.lat != null && g.lon != null)
                        Marker(
                          point: LatLng(g.lat!, g.lon!),
                          width: 10,
                          height: 10,
                          child: GestureDetector(
                            onTap: () => setState(() => _mapSelected = g),
                            child: Container(
                              decoration: BoxDecoration(
                                color: _nearby.contains(g)
                                    ? const Color(0xFFE60000)
                                        .withValues(alpha: 0.7)
                                    : const Color(0xFF0078A8)
                                        .withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _nearby.contains(g)
                                      ? const Color(0xFFE60000)
                                      : const Color(0xFF0078A8),
                                ),
                              ),
                            ),
                          ),
                        ),
                    if (_userPos != null)
                      Marker(
                        point: _userPos!,
                        width: 18,
                        height: 18,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.lightGreen
                                .withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            if (_mapSelected != null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: AppCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _mapSelected!.name,
                        style: TextStyle(
                            color: context.ink,
                            fontWeight: FontWeight.w700),
                      ),
                      if (_userPos != null)
                        Text(
                          'Distanza: ${(StopsService.distanceTo(_mapSelected!, _userPos!.latitude, _userPos!.longitude) / 1000).toStringAsFixed(2)} km',
                          style: TextStyle(
                              color: context.muted, fontSize: 12),
                        ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () => _openStop(_mapSelected!),
                        child: Text(
                          'Vedi passaggi ›',
                          style: TextStyle(
                            color: context.blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TourStep {
  final GlobalKey key;
  final String title;
  final String text;
  const _TourStep(this.key, this.title, this.text);
}

/// Spotlight overlay for the guided tour.
class _TourOverlay extends StatelessWidget {
  final Rect rect;
  final String title;
  final String text;
  final bool isLast;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _TourOverlay({
    required this.rect,
    required this.title,
    required this.text,
    required this.isLast,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final top = rect.bottom + 12;
    final bottomSpace =
        MediaQuery.of(context).size.height - rect.top + 12;
    final showBelow = top + 180 < MediaQuery.of(context).size.height;
    return Material(
      color: Colors.black54,
      child: GestureDetector(
        onTap: onSkip,
        child: Stack(
          children: [
            Positioned.fromRect(
              rect: rect.inflate(6),
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              top: showBelow ? top : null,
              bottom: showBelow ? null : bottomSpace,
              child: GestureDetector(
                onTap: () {},
                child: AppCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: context.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(text, style: TextStyle(color: context.muted)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: onSkip,
                            child: const Text('Salta'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: onNext,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 40),
                            ),
                            child: Text(isLast ? 'Fine' : 'Avanti'),
                          ),
                        ],
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
}

/// Red "!" FAB for strike warnings.
class _StrikeFab extends StatelessWidget {
  final VoidCallback onTap;
  const _StrikeFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: AppColors.actvRed,
      shape: const CircleBorder(),
      child: const Text(
        '!',
        style: TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

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
              child: const Icon(Icons.adjust, color: Colors.white, size: 20),
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
                    style: TextStyle(color: context.muted, fontSize: 13),
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

class _StatusBanner extends StatelessWidget {
  final String text;
  const _StatusBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: context.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: context.ink)),
          ),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  void _push(BuildContext context, Widget screen) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    final buttons = [
      (Icons.place_outlined, 'Cerca una fermata',
          () => MainShell.of(context).select(1), false),
      (Icons.swap_horiz_rounded, 'Percorsi',
          () => MainShell.of(context).select(2), false),
      (Icons.insights, 'Statistiche ritardi',
          () => _push(context, const DelayStatsScreen()), false),
      (Icons.schedule, 'Orari delle linee',
          () => _push(context, const LineScheduleScreen()), false),
      (Icons.directions_bus, 'Cerca una corsa',
          () => _push(context, const TripFinderScreen()), false),
      (Icons.edit_outlined, 'Invia feedback',
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
          for (final (icon, label, action, isFeedback) in buttons)
            FilledButton.icon(
              onPressed: action,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor:
                    isFeedback ? context.greenDark : context.blue,
                alignment: Alignment.centerLeft,
                shape: const StadiumBorder(),
              ),
            ),
        ],
      );
    });
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: context.muted, fontSize: 12);
    final link = TextStyle(
        color: context.blue,
        fontSize: 12,
        decoration: TextDecoration.underline);
    return Column(
      children: [
        Text('MIT License (2025–2026)', style: style, textAlign: TextAlign.center),
        Divider(color: context.border, height: 24),
        Text.rich(
          TextSpan(
            style: style,
            children: [
              const TextSpan(text: 'App sviluppata da '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => launchUrl(
                      Uri.parse('https://github.com/samuele-brusegan')),
                  child: Text('Samuele Brusegan', style: link),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        Text.rich(
          TextSpan(
            style: style,
            children: [
              const TextSpan(text: 'Grafica e design da '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: GestureDetector(
                  onTap: () => launchUrl(Uri.parse(
                      'https://github.com/andreadavanzo09-bit')),
                  child: Text('Andrea Davanzo', style: link),
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => launchUrl(Uri.parse(
                  'https://github.com/samuele-brusegan/actv-live')),
              child: Text('GitHub', style: link),
            ),
            Text(' · ', style: style),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreditsScreen()),
              ),
              child: Text('Crediti e licenze', style: link),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Progetto non ufficiale, non affiliato ad ACTV S.p.A.\nDati mappe © OpenStreetMap contributors',
          style: style.copyWith(fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
