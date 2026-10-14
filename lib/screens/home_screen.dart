import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';
import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/stop_tile.dart';
import 'delay_stats_screen.dart';
import 'feedback_screen.dart';
import 'line_schedule_screen.dart';
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

  static const _venice = LatLng(45.485, 12.245);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _favorites = await FavoritesService.load();
    try {
      final stops = await StopsService.all();
      if (!mounted) return;
      setState(() => _groups = StopsService.grouped(stops));
    } catch (_) {}

    final pos = await StopsService.locate();
    if (!mounted) return;
    if (pos != null) {
      setState(() {
        _userPos = LatLng(pos.latitude, pos.longitude);
        _status = 'Posizione rilevata';
        if (_groups.isNotEmpty) {
          _nearby = StopsService.nearby(_groups, pos.latitude, pos.longitude);
        }
      });
    } else {
      setState(() => _status = 'Geolocalizzazione non disponibile');
    }
  }

  void _openStop(StopGroup g) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StopDetailScreen(group: g)),
    ).then((_) async {
      _favorites = await FavoritesService.load();
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final favGroups =
        _groups.where((g) => _favorites.contains(g.idsParam)).toList();

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
                  const SectionLabel('Servizio ACTV'),
                  const SizedBox(height: 6),
                  Text(
                    'Da dove vuoi partire?',
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _PrimaryAction(
                    onTap: () => MainShell.of(context).select(2),
                  ),
                  const SizedBox(height: 24),
                  if (favGroups.isNotEmpty) ...[
                    const SectionTitle('Le tue fermate'),
                    for (final g in favGroups)
                      StopTile(group: g, onTap: () => _openStop(g)),
                    const Divider(height: 32),
                  ],
                  if (_nearby.isNotEmpty) ...[
                    const SectionTitle('Fermate vicine'),
                    for (final g in _nearby)
                      StopTile(
                        group: g,
                        distance: _userPos == null
                            ? null
                            : StopsService.distanceTo(
                                g, _userPos!.latitude, _userPos!.longitude),
                        onTap: () => _openStop(g),
                      ),
                    const Divider(height: 32),
                  ],
                  const SectionTitle('Mappa'),
                  _StatusBanner(text: _status),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radius),
                    child: SizedBox(
                      height: 300,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: _userPos ?? _venice,
                          initialZoom: 13,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'it.brusegan.bussola',
                          ),
                          if (_userPos != null)
                            MarkerLayer(markers: [
                              Marker(
                                point: _userPos!,
                                width: 20,
                                height: 20,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                  ),
                                ),
                              ),
                            ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ActionGrid(),
                  const SizedBox(height: 32),
                  const _Footer(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final VoidCallback onTap;
  const _PrimaryAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Icon(Icons.swap_horiz_rounded, color: context.green, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trova un percorso',
                    style: TextStyle(
                      color: context.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Partenza, destinazione e orario',
                    style: TextStyle(color: context.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.muted),
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
          () => MainShell.of(context).select(1)),
      (Icons.swap_horiz_rounded, 'Percorsi',
          () => MainShell.of(context).select(2)),
      (Icons.insights, 'Statistiche ritardi',
          () => _push(context, const DelayStatsScreen())),
      (Icons.schedule, 'Orari delle linee',
          () => _push(context, const LineScheduleScreen())),
      (Icons.directions_bus, 'Cerca una corsa',
          () => _push(context, const TripFinderScreen())),
      (Icons.edit_outlined, 'Invia feedback',
          () => _push(context, const FeedbackScreen())),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      final twoCols = constraints.maxWidth > 430;
      return GridView.count(
        crossAxisCount: twoCols ? 2 : 1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: twoCols ? 3.4 : 4.6,
        children: [
          for (final (icon, label, action) in buttons)
            FilledButton.icon(
              onPressed: action,
              icon: Icon(icon, size: 20),
              label: Text(label),
              style: FilledButton.styleFrom(
                backgroundColor: context.blue,
                alignment: Alignment.centerLeft,
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
    return Column(
      children: [
        Text('MIT License (2025–2026)', style: style, textAlign: TextAlign.center),
        Divider(color: context.border, height: 24),
        Text('App sviluppata da Samuele Brusegan',
            style: style, textAlign: TextAlign.center),
        Text('Grafica e design da Andrea Davanzo',
            style: style, textAlign: TextAlign.center),
      ],
    );
  }
}
