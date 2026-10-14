import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/line_badge.dart';
import 'route_details_screen.dart';

class RouteResultsScreen extends StatefulWidget {
  final StopGroup origin;
  final StopGroup destination;
  final DateTime date;
  final TimeOfDay time;
  final String optimize;
  final TimeOfDay? returnTime;

  const RouteResultsScreen({
    super.key,
    required this.origin,
    required this.destination,
    required this.date,
    required this.time,
    required this.optimize,
    this.returnTime,
  });

  @override
  State<RouteResultsScreen> createState() => _RouteResultsScreenState();
}

class _RouteResultsScreenState extends State<RouteResultsScreen> {
  List<PlannedRoute>? _routes;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _hhmm(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final res = await ApiClient.get('/api/plan-route', {
        'from': widget.origin.first.id,
        'to': widget.destination.first.id,
        'date': DateFormat('yyyy-MM-dd').format(widget.date),
        'time': _hhmm(widget.time),
        'optimize': widget.optimize,
        if (widget.origin.isNavigation)
          'from_service': 'navigation',
        if (widget.destination.isNavigation)
          'to_service': 'navigation',
      });
      if (!mounted) return;
      if (res is Map && res['success'] == true) {
        setState(() => _routes = [
              for (final r in (res['routes'] as List? ?? []))
                PlannedRoute.fromJson(r)
            ]);
      } else {
        setState(() => _error =
            ApiException(res is Map ? '${res['error'] ?? 'Errore'}' : 'Errore'));
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  String _short(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('dd/MM/yyyy');
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: AppHeader(
                showBack: true,
                title: 'Soluzioni di viaggio',
                subtitle:
                    '${widget.origin.name} → ${widget.destination.name}\n${df.format(widget.date)} · ${_hhmm(widget.time)}',
              ),
            ),
            if (_error != null)
              SliverFillRemaining(
                child: ErrorView(error: _error!, onRetry: _load),
              )
            else if (_routes == null)
              const SliverFillRemaining(
                  child: LoadingView(message: 'Ricerca percorsi...'))
            else if (_routes!.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.route_outlined,
                            size: 44, color: context.muted),
                        const SizedBox(height: 12),
                        Text(
                          'Nessun percorso trovato',
                          style: TextStyle(
                            color: context.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Prova a cambiare orario o fermate.',
                          style: TextStyle(color: context.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _RouteCard(
                      route: _routes![i],
                      index: i,
                      short: _short,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RouteDetailsScreen(
                            route: _routes![i],
                            origin: widget.origin,
                            destination: widget.destination,
                          ),
                        ),
                      ),
                    ),
                    childCount: _routes!.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  final PlannedRoute route;
  final int index;
  final String Function(String) short;
  final VoidCallback onTap;

  const _RouteCard({
    required this.route,
    required this.index,
    required this.short,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final transitLegs =
        route.legs.where((l) => l.type != 'walking').toList();
    final transfers = transitLegs.isEmpty ? 0 : transitLegs.length - 1;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SectionLabel('Soluzione ${index + 1}'),
              const Spacer(),
              Text(
                '${route.duration} min',
                style: TextStyle(
                  color: context.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                short(route.departureTime),
                style: TextStyle(
                  color: context.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.arrow_forward,
                    size: 18, color: context.muted),
              ),
              Text(
                short(route.arrivalTime),
                style: TextStyle(
                  color: context.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                transfers == 0
                    ? 'Diretto'
                    : '$transfers cambi${transfers == 1 ? 'o' : ''}',
                style: TextStyle(color: context.muted, fontSize: 13),
              ),
            ],
          ),
          if (transitLegs.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final leg in route.legs)
                  if (leg.type == 'walking')
                    Icon(Icons.directions_walk,
                        size: 20, color: context.muted)
                  else
                    LineBadge(
                      label: leg.line.isEmpty ? '?' : leg.line,
                      color: leg.color,
                    ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
