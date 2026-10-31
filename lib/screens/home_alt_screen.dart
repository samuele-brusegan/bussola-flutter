import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart';
import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/cards.dart';
import '../widgets/qr_fab.dart';
import 'credits_screen.dart';
import 'delay_stats_screen.dart';
import 'lines_map_screen.dart';
import 'line_schedule_screen.dart';
import 'live_map_screen.dart';
import 'route_finder_screen.dart';
import 'stop_detail_screen.dart';
import 'trip_finder_screen.dart';

/// Port of `/home-alt` — "product hero" variant: hero verde con barra
/// di ricerca finta, griglia 6 action card, sezioni preferiti/vicini.
class HomeAltScreen extends StatefulWidget {
  const HomeAltScreen({super.key});

  @override
  State<HomeAltScreen> createState() => _HomeAltScreenState();
}

class _HomeAltScreenState extends State<HomeAltScreen> {
  List<StopGroup> _groups = [];
  List<StopGroup> _nearby = [];
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _favorites = await FavoritesService.loadIdParams();
    try {
      _groups = await StopsService.catalog();
      if (mounted) setState(() {});
    } catch (_) {}
    final pos = await StopsService.locate();
    if (pos != null && mounted) {
      setState(() =>
          _nearby = StopsService.nearby(_groups, pos.latitude, pos.longitude));
    }
  }

  void _openStop(StopGroup g) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => StopDetailScreen(group: g)));

  @override
  Widget build(BuildContext context) {
    final favs = _groups.where((g) => _favorites.any((f) {
          final ids = g.idsParam.split('-');
          return f.split('-').any((i) => ids.contains(i));
        })).toList();
    final actions = [
      (Icons.swap_horiz_rounded, 'Percorsi', const RouteFinderScreen()),
      (Icons.directions_bus, 'Mappa live', const LiveMapScreen()),
      (Icons.schedule, 'Orari linee', const LineScheduleScreen()),
      (Icons.search, 'Cerca corsa', const TripFinderScreen()),
      (Icons.insights, 'Ritardi', const DelayStatsScreen()),
      (Icons.map_outlined, 'Rete', const LinesMapScreen()),
    ];
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF006E46), Color(0xFF008F5B)],
              ),
            ),
            padding: EdgeInsets.fromLTRB(
                20, MediaQuery.of(context).padding.top + 24, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACTV Live',
                    style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 12),
                const Text('Il tuo viaggio, in tempo reale.',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 30,
                        height: 1.1,
                        letterSpacing: -0.8)),
                const SizedBox(height: 6),
                Text('Orari, fermate e percorsi ACTV a Venezia',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 15)),
                const SizedBox(height: 18),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => MainShell.of(context).select(1),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Icon(Icons.search, color: Color(0xFF0759B8)),
                        SizedBox(width: 10),
                        Text('Cerca una fermata…',
                            style: TextStyle(
                                color: Color(0xFF64736F),
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              LayoutBuilder(builder: (context, c) {
                final cols = c.maxWidth > 430 ? 3 : 2;
                return GridView.count(
                  crossAxisCount: cols,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.15,
                  children: [
                    for (final (icon, label, screen) in actions)
                      AppCard(
                        padding: const EdgeInsets.all(12),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => screen)),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: context.green, size: 28),
                            const SizedBox(height: 8),
                            Text(label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: context.ink,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                  ],
                );
              }),
              const SizedBox(height: 20),
              if (favs.isNotEmpty) ...[
                const SectionTitle('Le tue fermate'),
                for (final g in favs)
                  _StopRow(g: g, onTap: () => _openStop(g)),
              ],
              if (_nearby.isNotEmpty) ...[
                const SectionTitle('Fermate vicine'),
                for (final g in _nearby)
                  _StopRow(g: g, onTap: () => _openStop(g)),
              ],
              const SectionTitle('Mappa'),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                child: SizedBox(
                  height: 240,
                  child: FlutterMap(
                    options: const MapOptions(
                        initialCenter: LatLng(45.4384, 12.3359),
                        initialZoom: 12),
                    children: [
                      TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'it.brusegan.bussola'),
                      MarkerLayer(markers: [
                        for (final g in _groups)
                          if (g.lat != null && g.lon != null)
                            Marker(
                              point: LatLng(g.lat!, g.lon!),
                              width: 8,
                              height: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0078A8)
                                      .withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                      ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const CreditsScreen())),
                  child: Text('Crediti e licenze',
                      style: TextStyle(color: context.muted)),
                ),
              ),
            ]),
          ),
        ),
      ]),
      floatingActionButton: const QrFab(url: '/home-alt'),
    );
  }
}

class _StopRow extends StatelessWidget {
  final StopGroup g;
  final VoidCallback onTap;
  const _StopRow({required this.g, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(children: [
        Expanded(
          child: Text(g.name,
              style: TextStyle(
                  color: context.ink, fontWeight: FontWeight.w600)),
        ),
        Icon(Icons.chevron_right, color: context.muted),
      ]),
    );
  }
}
