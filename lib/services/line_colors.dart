import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// `/api/line-colors` cache: `bus|LINEA` / `navigation|LINEA` → colors.
class LineColors {
  LineColors._();

  static Map<String, dynamic>? _cache;
  static Future<Map<String, dynamic>>? _pending;

  static Future<Map<String, dynamic>> _load() {
    _pending ??= ApiClient.get('/api/line-colors')
        .then((res) => _cache = Map<String, dynamic>.from(res as Map))
        .catchError((_) {
          _pending = null;
          return _cache ?? <String, dynamic>{};
        });
    return _pending!;
  }

  /// Colors for a line in a service ('bus'|'navigation'), or null.
  static Future<(Color, Color)?> colorsFor(String service, String line) async {
    final colors = await _load();
    final entry = colors['$service|$line'] ?? colors['bus|$line'];
    if (entry is! Map) return null;
    return (
      parseColor(entry['route_color'], fallback: const Color(0xFF5B5B5B)),
      parseColor(entry['route_text_color'], fallback: Colors.white),
    );
  }

  /// Badge colors for a line, following the web app rules: `route_color`
  /// from `/api/line-colors` when present, otherwise US/UN/EN tags → blue,
  /// `N…` names → night blue, everything else → red.
  static Future<(Color, Color)> badge(String service, String rawLine) async {
    final remote = await colorsFor(service, rawLine);
    if (remote != null) return remote;
    return fallbackBadge(rawLine);
  }

  /// Synchronous fallback badge colors (same rules, no API colors).
  static (Color, Color) fallbackBadge(String rawLine) {
    final parts = rawLine.split('_');
    final name = parts.first;
    final tag = parts.length > 1 ? parts[1] : '';
    if (name.startsWith('N')) {
      return (AppColors.nightBlue, Colors.white);
    }
    if (['US', 'UN', 'EN'].contains(tag)) {
      return (const Color(0xFF0152BB), Colors.white);
    }
    return (AppColors.actvRed, Colors.white);
  }
}
