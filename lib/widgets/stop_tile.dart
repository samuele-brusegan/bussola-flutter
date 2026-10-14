import 'package:flutter/material.dart';

import '../services/stops_service.dart';
import '../theme/app_theme.dart';
import 'cards.dart';
import 'line_badge.dart';

/// Stop card matching `.stop-card` in the web app: stacked id badges,
/// name, subtitle and chevron.
class StopTile extends StatelessWidget {
  final StopGroup group;
  final String? subtitle;
  final double? distance;
  final VoidCallback? onTap;

  const StopTile({
    super.key,
    required this.group,
    this.subtitle,
    this.distance,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      onTap: onTap,
      child: Row(
        children: [
          Column(
            children: [
              for (final id in group.ids.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: StopIdBadge(id: id),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: TextStyle(
                    color: context.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (subtitle != null || distance != null)
                  Text(
                    distance != null
                        ? '${subtitle != null ? '$subtitle · ' : ''}${StopsService.formatDistance(distance!)}'
                        : subtitle!,
                    style: TextStyle(color: context.muted, fontSize: 13),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.muted),
        ],
      ),
    );
  }
}
