import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_html/flutter_html.dart';

import '../api/api_client.dart';
import '../services/actv_realtime.dart';
import '../services/delay_service.dart';
import '../services/line_colors.dart';
import '../services/notifications_service.dart';
import '../services/passages_service.dart';
import '../services/stops_service.dart';
import '../services/storage_service.dart';
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
  String get _stationId => widget.group.idsParam;

  List<Passage>? _passages;
  List<Passage> _navPassages = [];
  Object? _error;
  bool _favorite = false;
  bool _monitored = false;
  bool _strike = false;
  String? _noticeHtml;
  bool _boardCollapsed = false;
  int _loadToken = 0;
  Timer? _refreshTimer;

  // Filters (persisted per session like `stop_filter`/`filter`).
  List<String> _lineFilter = [];
  List<String> _stopFilter = [];

  @override
  void initState() {
    super.initState();
    FavoritesService.isFavorite(_stationId)
        .then((v) => mounted ? setState(() => _favorite = v) : null);
    NotificationsService.isStopMonitored(_stationId)
        .then((v) => mounted ? setState(() => _monitored = v) : null);
    Storage.getString('board_collapsed').then(
        (v) => mounted ? setState(() => _boardCollapsed = v == '1') : null);
    _restoreFilters();
    _load();
    _refreshTimer =
        Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreFilters() async {
    _lineFilter = await _filterSelection('filter');
    _stopFilter = await _filterSelection('stop_filter');
  }

  Future<List<String>> _filterSelection(String key) async {
    final raw = await Storage.getJson(key);
    if (raw is List) {
      return [for (final v in raw) '$v'];
    }
    if (raw is String && raw.isNotEmpty) return [raw];
    return [];
  }

  Future<void> _setFilterSelection(String key, List<String> values) async {
    if (values.isEmpty) {
      await Storage.remove(key);
    } else {
      await Storage.setJson(key, values);
    }
  }

  Future<void> _load() async {
    final token = ++_loadToken;
    if (mounted) setState(() => _error = null);

    final noticeFuture = ActvRealtime.noticeboard(_stationId);
    final results = await Future.wait([
      ActvRealtime.passages(_stationId),
      PassagesService.fetchScheduled(_stationId),
      PassagesService.fetchNavigation(
          widget.group.allIdsParam, widget.group.name),
    ]);
    if (token != _loadToken || !mounted) return;

    final realtime = results[0] as List<Map<String, dynamic>>?;
    final scheduled = results[1] as List<Passage>;
    final navigation = results[2] as List<Passage>;
    final realtimePassages =
        realtime?.map((p) => Passage(p)).toList();

    var strike = PassagesService.isLikelyStrike(realtimePassages, scheduled);
    if (strike) {
      strike = await PassagesService.confirmStrikeCrossCheck(_stationId);
      if (token != _loadToken || !mounted) return;
    }

    final merged =
        PassagesService.mergePassages(realtimePassages, scheduled, _stationId);

    setState(() {
      _strike = strike;
      _passages = merged;
      _navPassages = navigation;
      _error = (realtime == null && scheduled.isEmpty && navigation.isEmpty)
          ? 'network'
          : null;
    });

    DelayService.recordPassages(merged, _stationId, widget.group.name);

    noticeFuture.then((text) {
      if (token != _loadToken || !mounted) return;
      setState(() {
        _noticeHtml = text;
        if (text != null &&
            RegExp('sciopero', caseSensitive: false).hasMatch(text)) {
          _strike = true;
        }
      });
    });

    // Progressive enrichment with realtime vehicle positions.
    final candidateIds = [
      ...scheduled.map((p) => p.tripId),
      ...navigation.map((p) => p.tripId),
    ];
    PassagesService.fetchStopVehicles(candidateIds).then((vehicles) async {
      if (token != _loadToken || !mounted) return;
      final activeIds =
          vehicles.map((v) => v.tripId).where((s) => s.isNotEmpty).toSet();
      List<Passage> list = _passages ?? [];
      if (activeIds.isNotEmpty && realtime != null) {
        list = PassagesService.mergePassages(
            realtimePassages, scheduled, _stationId,
            activeTripIds: activeIds);
      }
      final coords = await PassagesService.fetchStopCoords(_stationId);
      PassagesService.attachVehicles(list, vehicles, stationCoords: coords);
      PassagesService.attachVehicles(navigation, vehicles,
          stationCoords: coords);
      await PassagesService.enrichProgress([...list, ...navigation]);
      if (token != _loadToken || !mounted) return;
      setState(() {
        _passages = list;
        _navPassages = navigation;
      });
    });
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.toggle(widget.group);
    if (mounted) setState(() => _favorite = !_favorite);
  }

  Future<void> _toggleNotifications() async {
    if (_monitored) {
      await NotificationsService.removeMonitoredStop(_stationId);
      if (mounted) setState(() => _monitored = false);
    } else {
      final enabled = await NotificationsService.isEnabled() ||
          await NotificationsService.toggle();
      if (!enabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Permesso notifiche negato')));
        }
        return;
      }
      await NotificationsService.addMonitoredStop(
          _stationId, widget.group.name);
      if (mounted) setState(() => _monitored = true);
    }
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => _NotificationPanel(stopName: widget.group.name),
    );
  }

  void _showShareSheet() {
    final url =
        '/widget?stop=$_stationId&name=${Uri.encodeComponent(widget.group.name)}';
    final full = webUrl(url);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Condividi questa fermata',
                  style: TextStyle(
                      color: ctx.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
              const SizedBox(height: 12),
              SelectableText(full,
                  style: TextStyle(color: ctx.muted, fontSize: 13)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: full));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Link widget copiato')));
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copia URL widget'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(
                            text:
                                '<iframe src="$full" style="border:0;width:100%;max-width:400px;height:500px"></iframe>'));
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Codice embed copiato')));
                      },
                      icon: const Icon(Icons.code, size: 18),
                      label: const Text('Copia iframe'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPassage(Passage p) async {
    final timingPoint =
        p.timingPoints.isEmpty ? null : p.timingPoints.last;
    var tripId = p.tripId;
    if (tripId == null || tripId.isEmpty) {
      // Fallback: resolve via gtfs-identify.
      try {
        final resolution =
            p.timingPoints.isNotEmpty ? p.timingPoints.first : null;
        final dow = [
          'sunday', 'monday', 'tuesday', 'wednesday', 'thursday',
          'friday', 'saturday'
        ];
        final day = dow[DateTime.now().weekday % 7];
        final res = await ApiClient.get('/api/gtfs-identify', {
          'return': 'true',
          'time': '${resolution?['time'] ?? ''}',
          'busTrack': p.line,
          'busDirection': p.destination,
          'day': day,
          'stop': '${resolution?['stop'] ?? ''}',
          'lineId': '${p.lineId ?? ''}',
          'stopId': _stationId,
        });
        if (res is Map && res['trip_id'] != null) {
          tripId = '${res['trip_id']}';
        }
      } catch (_) {}
    }
    if (!mounted) return;
    if (tripId == null || tripId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Impossibile identificare con certezza questa corsa.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailsScreen(
          tripId: tripId!,
          stopId: _stationId,
          line: p.line,
          dest: p.destination,
          time: '${timingPoint?['time'] ?? p.time}',
          realtime: p.real,
          contextStop: '${timingPoint?['stop'] ?? ''}',
        ),
      ),
    );
  }

  List<Passage> _visible(List<Passage> list) => list
      .where((p) =>
          (_lineFilter.isEmpty || _lineFilter.contains(p.line)) &&
          (_stopFilter.isEmpty ||
              _stopFilter.contains(p.gtfsStopId ?? p.stop)))
      .toList();

  @override
  Widget build(BuildContext context) {
    final g = widget.group;
    final passages = _visible(_passages ?? []);
    final navPassages = _visible(_navPassages);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                showBack: true,
                title: g.name,
                subtitle: _stationId,
                actions: [
                  _HeaderAction(
                    icon: _favorite ? Icons.star : Icons.star_border,
                    onTap: _toggleFavorite,
                  ),
                  _HeaderAction(
                    icon: _monitored
                        ? Icons.notifications_active
                        : Icons.notifications_none,
                    onTap: () async {
                      await _toggleNotifications();
                      if (_monitored) _showNotificationPanel();
                    },
                  ),
                  _HeaderAction(
                    icon: Icons.share,
                    onTap: _showShareSheet,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _buildFilters(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: _buildBoard(),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SectionTitle('Prossimi Passaggi'),
              ),
            ),
            if (_error != null)
              const SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Errore nel caricamento dei dati.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              )
            else if (_passages == null)
              const SliverFillRemaining(
                  child: LoadingView(message: 'Caricamento passaggi...'))
            else if (passages.isEmpty && navPassages.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _strike
                          ? 'Nessun passaggio in tempo reale (possibile sciopero). Vedi la bacheca.'
                          : 'Nessun passaggio previsto.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.muted),
                    ),
                  ),
                ),
              )
            else ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) =>
                        _PassageCard(passage: passages[i], onTap: () => _openPassage(passages[i])),
                    childCount: passages.length,
                  ),
                ),
              ),
              if (navPassages.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      '⛴ Navigazione',
                      style: TextStyle(
                        color: context.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => _PassageCard(
                          passage: navPassages[i],
                          navigation: true,
                          onTap: () => _openPassage(navPassages[i])),
                      childCount: navPassages.length,
                    ),
                  ),
                ),
              ],
            ],
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Center(
                  child: OutlinedButton(
                    onPressed: _load,
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                    ),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      child: Text('Aggiorna'),
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final all = [...?_passages, ..._navPassages];
    final lines = <String>{};
    final stops = <String>{};
    for (final p in all) {
      if (p.line.isNotEmpty) lines.add(p.line);
      final sid = p.gtfsStopId ?? p.stop;
      if (sid.isNotEmpty) stops.add(sid);
    }
    final showLines = lines.length > 1;
    final showStops = stops.length > 1;
    if (!showLines && !showStops) return const SizedBox.shrink();

    // Prune stale selections.
    _lineFilter = _lineFilter.where((v) => lines.contains(v)).toList();
    _stopFilter = _stopFilter.where((v) => stops.contains(v)).toList();

    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          if (showLines)
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterBox(
                  label: l,
                  selected: _lineFilter.contains(l),
                  onTap: () => setState(() {
                    _lineFilter = _lineFilter.contains(l)
                        ? _lineFilter.where((v) => v != l).toList()
                        : [..._lineFilter, l];
                    _setFilterSelection('filter', _lineFilter);
                  }),
                ),
              ),
          if (showLines && showStops)
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
              color: context.border,
            ),
          if (showStops)
            for (final s in stops)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterBox(
                  label: '#$s',
                  selected: _stopFilter.contains(s),
                  onTap: () => setState(() {
                    _stopFilter = _stopFilter.contains(s)
                        ? _stopFilter.where((v) => v != s).toList()
                        : [..._stopFilter, s];
                    _setFilterSelection('stop_filter', _stopFilter);
                  }),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    final notes = <(String type, String content)>[];
    if (_strike) {
      notes.add((
        'strike',
        '<strong>Possibile sciopero o servizio non monitorato.</strong><br>'
            'I passaggi in tempo reale non sono disponibili: gli orari '
            'mostrati sono quelli <em>previsti</em> e i bus potrebbero '
            'non passare.'
      ));
    }
    if (_noticeHtml != null && _noticeHtml!.isNotEmpty) {
      notes.add((
        RegExp('sciopero', caseSensitive: false).hasMatch(_noticeHtml!)
            ? 'strike'
            : 'notice',
        _noticeHtml!
      ));
    }
    if (notes.isEmpty) return const SizedBox.shrink();

    if (_boardCollapsed) {
      return Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          onTap: () {
            Storage.setString('board_collapsed', '0');
            setState(() => _boardCollapsed = false);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.surface,
              shape: BoxShape.circle,
              border: Border.all(color: context.border),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6)
              ],
            ),
            child: Badge(
              label: Text('${notes.length}'),
              child: Icon(Icons.assignment_outlined, color: context.ink),
            ),
          ),
        ),
      );
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined,
                  size: 20, color: context.ink),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Bacheca',
                  style: TextStyle(
                      color: context.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15),
                ),
              ),
              InkWell(
                onTap: () {
                  Storage.setString('board_collapsed', '1');
                  setState(() => _boardCollapsed = true);
                },
                child: Icon(Icons.remove, color: context.muted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final (type, html) in notes)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: type == 'strike'
                    ? AppColors.orange.withValues(alpha: 0.12)
                    : context.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: type == 'strike'
                      ? AppColors.orange
                      : context.border,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    type == 'strike'
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline,
                    size: 18,
                    color: type == 'strike'
                        ? AppColors.orange
                        : context.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Html(
                      data: html,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          color: context.ink,
                          fontSize: FontSize(14),
                        ),
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Full URL on the configured web server for a path.
String webUrl(String path) => '${ApiClient.baseUrl}$path';

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

class _FilterBox extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterBox(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? context.blue : context.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? context.blue : context.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : context.ink,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

/// A single passage card: line badge, destination + 'Presso id',
/// realtime dot + time or scheduled time, optional vehicle info.
class _PassageCard extends StatelessWidget {
  final Passage passage;
  final bool navigation;
  final VoidCallback onTap;
  const _PassageCard(
      {required this.passage, this.navigation = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = passage;
    final isReal = p.real;
    final timeDisplay = p.time == 'departure' ? 'Ora' : p.time;

    final progress = p.vehicleProgress;
    String? vehicleText;
    if (p.vehicleInfo != null) {
      vehicleText = progress?['boardingPassed'] == true
          ? 'Il mezzo ha già superato questa fermata'
          : PassagesService.vehicleLabel(p.vehicleDistanceM) +
              ((progress?['stopsToBoarding'] as int? ?? 0) > 0
                  ? ' · ${progress?['stopsToBoarding']} fermat${progress?['stopsToBoarding'] == 1 ? 'a' : 'e'}'
                  : '');
    }

    return FutureBuilder<(Color, Color)>(
      future: LineColors.badge(
          navigation ? 'navigation' : 'bus', p.rawLine),
      builder: (context, snap) {
        final (bg, fg) = snap.data ??
            LineColors.fallbackBadge(p.rawLine);
        return AppCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          onTap: onTap,
          child: Row(
            children: [
              LineBadge(
                label: navigation ? '⛴ ${p.line}' : p.line,
                color: bg,
                textColor: fg,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.destination.isEmpty
                          ? 'Destinazione ignota'
                          : p.destination,
                      style: TextStyle(
                        color: context.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      navigation
                          ? 'Navigazione'
                          : 'Presso ${p.stop.isEmpty ? p.gtfsStopId ?? '' : p.stop}',
                      style:
                          TextStyle(color: context.muted, fontSize: 13),
                    ),
                    if (vehicleText != null)
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: context.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              vehicleText,
                              style: TextStyle(
                                  color: context.green, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isReal)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: context.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    timeDisplay,
                    style: TextStyle(
                      color: isReal ? context.green : context.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet with delay threshold options (3/5/10/15 min).
class _NotificationPanel extends StatefulWidget {
  final String stopName;
  const _NotificationPanel({required this.stopName});

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  int _threshold = 5;

  @override
  void initState() {
    super.initState();
    NotificationsService.getThreshold()
        .then((v) => mounted ? setState(() => _threshold = v) : null);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifiche Ritardi',
                style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 18)),
            const SizedBox(height: 14),
            Text('Avvisa per ritardi superiori a:',
                style: TextStyle(color: context.ink)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final m in [3, 5, 10, 15])
                  ChoiceChip(
                    label: Text('$m min'),
                    selected: _threshold == m,
                    onSelected: (_) {
                      NotificationsService.setThreshold(m);
                      setState(() => _threshold = m);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Riceverai una notifica quando una linea che passa da questa '
              'fermata ha un ritardo superiore alla soglia impostata.',
              style: TextStyle(color: context.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
