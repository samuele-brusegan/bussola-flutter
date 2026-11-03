import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../screens/credits_screen.dart';
import '../screens/route_results_screen.dart';
import '../screens/stop_detail_screen.dart';
import '../services/actv_realtime.dart';
import '../services/stops_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'cards.dart';

/// Venice city centre — fallback map position.
const veniceCenter = LatLng(45.4384, 12.3359);

// ──────────────────────────────── Strike ────────────────────────────────

class StrikeResult {
  final String notice;
  final List<({String id, String name})> emptyStops;
  const StrikeResult({required this.notice, required this.emptyStops});
}

/// Port of `checkImportantNotices` in script-home.js: samples 15 stops and
/// flags a likely strike when no sampled stop has realtime passages or a
/// noticeboard mentions "sciopero".
class StrikeCheck {
  static const sampleSize = 15;

  static Future<StrikeResult?> run() async {
    // Realtime ACTV stops transmitting between 00:00 and 05:00 anyway.
    if (DateTime.now().hour < 5) return null;
    try {
      final catalog = await ActvRealtime.stopsCatalog();
      final stops = [
        for (final s in catalog)
          if ('${s['name'] ?? ''}'.isNotEmpty)
            (
              id: '${s['name']}'.replaceAll(RegExp(r'-web-aut$'), ''),
              name: '${s['description'] ?? ''}'
                  .replaceAll(RegExp(r'\[\d+\]'), '')
                  .trim(),
            )
      ];
      if (stops.isEmpty) return null;
      final step =
          (stops.length / sampleSize).floor().clamp(1, stops.length);
      final sample = <({String id, String name})>[];
      for (var i = 0;
          i < stops.length && sample.length < sampleSize;
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
          .firstWhere(
              (t) =>
                  RegExp('sciopero', caseSensitive: false).hasMatch(t),
              orElse: () => '');
      final noneHasPassages = valid.length == sample.length &&
          valid.every((r) => r.hasPassages == false);
      if (notice.isEmpty && !noneHasPassages) return null;
      return StrikeResult(
        notice: notice,
        emptyStops: [
          for (final r in valid)
            if (r.hasPassages == false)
              (id: r.stop.id, name: r.stop.name)
        ],
      );
    } catch (_) {
      return null;
    }
  }
}

/// Red "!" FAB shown when a strike is detected.
class StrikeFab extends StatelessWidget {
  final VoidCallback onTap;
  const StrikeFab({super.key, required this.onTap});

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

/// `strike-card` modal: notice text + list of stops without passages.
void showStrikeDialog(BuildContext context, StrikeResult result) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: ctx.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.actvRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              result.notice.isNotEmpty
                  ? 'Sciopero'
                  : 'Possibile sciopero in corso',
              style: TextStyle(
                  color: ctx.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.notice.isNotEmpty)
              Text(result.notice, style: TextStyle(color: ctx.ink))
            else
              Text(
                'Il servizio in tempo reale non risponde su '
                '${result.emptyStops.length} fermate controllate: è probabile '
                'uno sciopero o un\'interruzione del servizio. Gli orari '
                'previsti potrebbero non essere rispettati.',
                style: TextStyle(color: ctx.ink),
              ),
            if (result.emptyStops.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Fermate senza passaggi rilevati:',
                  style: TextStyle(color: ctx.muted, fontSize: 13)),
              const SizedBox(height: 6),
              for (final s in result.emptyStops)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      final g = StopGroup(
                          name: s.name.isEmpty
                              ? 'Fermata ${s.id}'
                              : s.name,
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
                            s.name.isEmpty
                                ? 'Fermata ${s.id}'
                                : s.name,
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

// ─────────────────────────── Status banner ──────────────────────────────

/// Geolocation status banner (`#status`): info while waiting, turns green
/// on success then fades out after ~3 s (like the web app).
class HomeStatusBanner extends StatefulWidget {
  final String text;
  final bool success;
  const HomeStatusBanner(
      {super.key, required this.text, this.success = false});

  @override
  State<HomeStatusBanner> createState() => _HomeStatusBannerState();
}

class _HomeStatusBannerState extends State<HomeStatusBanner> {
  bool _hidden = false;

  @override
  void didUpdateWidget(HomeStatusBanner old) {
    super.didUpdateWidget(old);
    if (widget.success && !old.success) {
      Future.delayed(const Duration(milliseconds: 3000), () {
        if (mounted) setState(() => _hidden = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 350),
      child: _hidden
          ? const SizedBox.shrink()
          : AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    widget.success
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    color: widget.success
                        ? context.green
                        : context.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.text,
                        style: TextStyle(color: context.ink)),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────── Home map ───────────────────────────────

double _radiusForZoom(double zoom) =>
    (zoom.round() - 9).clamp(2, 12).toDouble();

/// Shared home map: all stop markers (radius scales with zoom), nearby
/// stops highlighted in red, user marker, popup card, fitBounds to the
/// user + nearby stops, fullscreen button.
class HomeMap extends StatefulWidget {
  final List<StopGroup> groups;
  final List<StopGroup> nearby;
  final LatLng? userPos;
  final void Function(StopGroup) onOpenStop;
  final double height;

  const HomeMap({
    super.key,
    required this.groups,
    required this.nearby,
    required this.userPos,
    required this.onOpenStop,
    this.height = 300,
  });

  @override
  State<HomeMap> createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  final _controller = MapController();
  StopGroup? _selected;
  double _zoom = 12;
  bool _fitted = false;

  @override
  void didUpdateWidget(HomeMap old) {
    super.didUpdateWidget(old);
    // Port of map.fitBounds(userPos + nearby) on locationfound.
    if (!_fitted && widget.userPos != null) {
      _fitted = true;
      final points = [
        widget.userPos!,
        for (final g in widget.nearby)
          if (g.lat != null && g.lon != null) LatLng(g.lat!, g.lon!),
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || points.isEmpty) return;
        try {
          _controller.fitCamera(CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(40),
          ));
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = _radiusForZoom(_zoom);
    final markers = <Marker>[
      for (final g in widget.groups)
        if (g.lat != null && g.lon != null)
          _stopMarker(g, widget.nearby.contains(g), r),
      if (widget.userPos != null)
        Marker(
          point: widget.userPos!,
          width: 18,
          height: 18,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF009E61).withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
            ),
          ),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radius),
      child: SizedBox(
        height: widget.height,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _controller,
              options: MapOptions(
                initialCenter: widget.userPos ?? veniceCenter,
                initialZoom: _zoom,
                onTap: (_, _) => setState(() => _selected = null),
                onMapEvent: (e) {
                  if (e.camera.zoom != _zoom) {
                    setState(() => _zoom = e.camera.zoom);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'it.brusegan.bussola',
                ),
                MarkerLayer(markers: markers),
              ],
            ),
            // Fullscreen button (leaflet-fullscreen equivalent)
            Positioned(
              top: 8,
              right: 8,
              child: _MapButton(
                icon: Icons.fullscreen,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HomeMapFullscreen(
                      groups: widget.groups,
                      nearby: widget.nearby,
                      userPos: widget.userPos,
                      onOpenStop: widget.onOpenStop,
                    ),
                  ),
                ),
              ),
            ),
            if (_selected != null)
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: _MapPopup(
                  group: _selected!,
                  isNear: widget.nearby.contains(_selected),
                  userPos: widget.userPos,
                  onOpen: () => widget.onOpenStop(_selected!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Marker _stopMarker(StopGroup g, bool near, double r) {
    final d = (r + (near ? 1 : 0)) * 2;
    final color =
        near ? const Color(0xFFE60000) : const Color(0xFF0078A8);
    return Marker(
      point: LatLng(g.lat!, g.lon!),
      width: d + 8,
      height: d + 8,
      child: GestureDetector(
        onTap: () => setState(() => _selected = g),
        child: Center(
          child: Container(
            width: d,
            height: d,
            decoration: BoxDecoration(
              color: color.withValues(alpha: near ? 0.7 : 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}

class _MapPopup extends StatelessWidget {
  final StopGroup group;
  final bool isNear;
  final LatLng? userPos;
  final VoidCallback onOpen;

  const _MapPopup({
    required this.group,
    required this.isNear,
    required this.userPos,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text.rich(
            TextSpan(
              style: TextStyle(color: context.ink),
              children: [
                const TextSpan(
                    text: 'Stazione: ',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: group.name),
              ],
            ),
          ),
          if (userPos != null)
            Text(
              'Distanza: ${(StopsService.distanceTo(group, userPos!.latitude, userPos!.longitude) / 1000).toStringAsFixed(2)} km',
              style: TextStyle(color: context.muted, fontSize: 12),
            ),
          const SizedBox(height: 6),
          InkWell(
            onTap: onOpen,
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
    );
  }
}

/// Fullscreen version of the home map.
class HomeMapFullscreen extends StatelessWidget {
  final List<StopGroup> groups;
  final List<StopGroup> nearby;
  final LatLng? userPos;
  final void Function(StopGroup) onOpenStop;

  const HomeMapFullscreen({
    super.key,
    required this.groups,
    required this.nearby,
    required this.userPos,
    required this.onOpenStop,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Mappa delle fermate'),
      ),
      body: HomeMap(
        groups: groups,
        nearby: nearby,
        userPos: userPos,
        onOpenStop: onOpenStop,
        height: MediaQuery.of(context).size.height,
      ),
    );
  }
}

// ─────────────────────────── Journey resume ─────────────────────────────

/// "Il tuo ultimo viaggio" card (`#journey-resume`).
class JourneyResumeCard extends StatelessWidget {
  final String origin;
  final String destination;
  final VoidCallback onResume;
  final VoidCallback onModify;

  const JourneyResumeCard({
    super.key,
    required this.origin,
    required this.destination,
    required this.onResume,
    required this.onModify,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Il tuo ultimo viaggio'),
            const SizedBox(height: 6),
            Text(
              '$origin → $destination',
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
                    onPressed: onResume,
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
                    onPressed: onModify,
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
}

/// "Riprendi viaggio": updates departure date/time to *now* (rounded to
/// the next 5 minutes) and opens the results screen.
Future<void> resumeJourney(
  BuildContext context,
  Map<String, dynamic> origin,
  Map<String, dynamic> destination,
) async {
  final now = DateTime.now();
  final rounded = DateTime(now.year, now.month, now.day, now.hour,
      ((now.minute + 4) ~/ 5) * 5);
  await Storage.setString(Storage.routeDepartureDate,
      '${rounded.year}-${rounded.month.toString().padLeft(2, '0')}-${rounded.day.toString().padLeft(2, '0')}');
  await Storage.setString(Storage.routeDepartureTime,
      '${rounded.hour.toString().padLeft(2, '0')}:${rounded.minute.toString().padLeft(2, '0')}');
  if (!context.mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => RouteResultsScreen(
        origin: origin,
        destination: destination,
        date: rounded,
        time: TimeOfDay.fromDateTime(rounded),
        optimize: 'time',
      ),
    ),
  );
}

// ───────────────────────────── Guided tour ──────────────────────────────

class HomeTourStep {
  final GlobalKey key;
  final String title;
  final String text;
  const HomeTourStep(this.key, this.title, this.text);
}

/// Spotlight tour (`ACTVTour`): highlights each keyed section in order.
class HomeTour {
  static Future<void> run(
      BuildContext context, List<HomeTourStep> steps,
      {required VoidCallback onDone}) {
    return _show(context, steps, 0, onDone);
  }

  static Future<void> _show(BuildContext context,
      List<HomeTourStep> steps, int index, VoidCallback onDone) async {
    if (index >= steps.length) {
      onDone();
      return;
    }
    final step = steps[index];
    final ctx = step.key.currentContext;
    if (ctx == null) {
      return _show(context, steps, index + 1, onDone);
    }
    await Scrollable.ensureVisible(ctx,
        duration: const Duration(milliseconds: 350), alignment: 0.3);
    if (!context.mounted) return;
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
          _show(context, steps, index + 1, onDone);
        },
        onSkip: () {
          entry.remove();
          onDone();
        },
      ),
    );
    Overlay.of(context).insert(entry);
  }
}

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

// ─────────────────────────────── Footer ─────────────────────────────────

/// MIT + authors + GitHub/credits + disclaimer.
/// [compact] renders the single-line `ha-footer` variant used by home-alt.
class HomeFooter extends StatelessWidget {
  final bool compact;
  const HomeFooter({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: context.muted, fontSize: 12);
    final link = TextStyle(
        color: context.blue,
        fontSize: 12,
        decoration: TextDecoration.underline);

    InlineSpan author(String name, String url) => WidgetSpan(
          alignment: PlaceholderAlignment.baseline,
          baseline: TextBaseline.alphabetic,
          child: GestureDetector(
            onTap: () => launchUrl(Uri.parse(url)),
            child: Text(name, style: link),
          ),
        );

    final ghLink = GestureDetector(
      onTap: () => launchUrl(
          Uri.parse('https://github.com/samuele-brusegan/actv-live')),
      child: Text('GitHub', style: link),
    );
    final creditsLink = GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreditsScreen()),
      ),
      child: Text('Crediti e licenze', style: link),
    );

    if (compact) {
      return Column(
        children: [
          Text.rich(
            TextSpan(style: style, children: [
              const TextSpan(
                  text: 'MIT License (2025–2026) · App di '),
              author('Samuele Brusegan',
                  'https://github.com/samuele-brusegan'),
              const TextSpan(text: ' e '),
              author('Andrea Davanzo',
                  'https://github.com/andreadavanzo09-bit'),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [ghLink, Text(' · ', style: style), creditsLink],
          ),
          const SizedBox(height: 4),
          Text(
            'Progetto non ufficiale, non affiliato ad ACTV S.p.A. — dati mappe © OpenStreetMap contributors',
            style: style.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      children: [
        Text('MIT License (2025–2026)',
            style: style, textAlign: TextAlign.center),
        Divider(color: context.border, height: 24),
        Text.rich(
          TextSpan(style: style, children: [
            const TextSpan(text: 'App sviluppata da '),
            author('Samuele Brusegan',
                'https://github.com/samuele-brusegan'),
          ]),
          textAlign: TextAlign.center,
        ),
        Text.rich(
          TextSpan(style: style, children: [
            const TextSpan(text: 'Grafica e design da '),
            author('Andrea Davanzo',
                'https://github.com/andreadavanzo09-bit'),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ghLink, Text(' · ', style: style), creditsLink],
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
