import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/cards.dart';
import '../widgets/line_badge.dart';
import 'trip_details_screen.dart';

class RouteDetailsScreen extends StatelessWidget {
  final PlannedRoute route;
  final StopGroup origin;
  final StopGroup destination;

  const RouteDetailsScreen({
    super.key,
    required this.route,
    required this.origin,
    required this.destination,
  });

  String _short(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: AppHeader(
              showBack: true,
              title: '${_short(route.departureTime)} → ${_short(route.arrivalTime)}',
              subtitle: '${route.duration} min · ${origin.name} → ${destination.name}',
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _LegTile(
                  leg: route.legs[i],
                  isLast: i == route.legs.length - 1,
                  short: _short,
                ),
                childCount: route.legs.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegTile extends StatelessWidget {
  final RouteLeg leg;
  final bool isLast;
  final String Function(String) short;

  const _LegTile({
    required this.leg,
    required this.isLast,
    required this.short,
  });

  @override
  Widget build(BuildContext context) {
    final walking = leg.type == 'walking';
    final stops = (leg.raw['stops'] as List? ?? []);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 20),
                decoration: BoxDecoration(
                  color: walking ? context.muted : leg.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.surface, width: 2),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    color: walking ? context.muted : leg.color,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              onTap: (!walking && leg.tripId.isNotEmpty)
                  ? () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              TripDetailsScreen(tripId: leg.tripId),
                        ),
                      )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (walking)
                        Icon(Icons.directions_walk,
                            color: context.muted, size: 20)
                      else
                        LineBadge(
                          label: leg.line.isEmpty ? '?' : leg.line,
                          color: leg.color,
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          walking
                              ? 'A piedi'
                              : (leg.headsign.isEmpty
                                  ? leg.toName
                                  : leg.headsign),
                          style: TextStyle(
                            color: context.ink,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (leg.departure.isNotEmpty)
                        Text(
                          '${short(leg.departure)} – ${short(leg.arrival)}',
                          style: TextStyle(
                            color: context.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _legRow(context, 'Da', leg.fromName),
                  if (leg.toName.isNotEmpty)
                    _legRow(context, 'A', leg.toName),
                  if (stops.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${stops.length} fermate',
                      style: TextStyle(color: context.muted, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legRow(BuildContext context, String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(label,
                style: TextStyle(color: context.muted, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(color: context.ink, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
