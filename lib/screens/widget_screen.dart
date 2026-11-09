import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/api_client.dart';
import '../l10n/l10n_ext.dart';
import '../services/actv_realtime.dart';
import '../services/line_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/line_badge.dart';

/// Port of `/widget` — standalone stop board (no app-shell):
/// green header with stop name + id, passage list, poll every 30 s,
/// "Apri su ACTV Live" footer. Params: stop (required), name, max (8),
/// theme.
class WidgetScreen extends StatefulWidget {
  final String stopId;
  final String name;
  final int max;

  const WidgetScreen({
    super.key,
    required this.stopId,
    this.name = '',
    this.max = 8,
  });

  @override
  State<WidgetScreen> createState() => _WidgetScreenState();
}

class _WidgetScreenState extends State<WidgetScreen> {
  List<Map<String, dynamic>> _passages = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final data = await ActvRealtime.passages(widget.stopId);
    if (!mounted || data == null) return;
    setState(() => _passages = data.take(widget.max).toList());
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF1A1A1A) : Colors.white,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: dark ? const Color(0xFF004D30) : const Color(0xFF009E61),
            padding: EdgeInsets.fromLTRB(
                14, MediaQuery.of(context).padding.top + 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name.isEmpty
                      ? context.l10n.stopDefaultName(widget.stopId)
                      : widget.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 17),
                ),
                Text(widget.stopId,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Expanded(
            child: _passages.isEmpty
                ? Center(
                    child: Text(context.l10n.noPassagesScheduled,
                        style: TextStyle(color: context.muted)),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _passages.length,
                    itemBuilder: (context, i) {
                      final p = _passages[i];
                      final line = '${p['line'] ?? ''}';
                      final real = p['real'] == true;
                      return FutureBuilder<(Color, Color)>(
                        future: LineColors.badge('bus', line),
                        builder: (context, snap) {
                          final (bg, fg) = snap.data ??
                              LineColors.fallbackBadge(line);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(children: [
                              LineBadge(
                                  label: line.split('_').first,
                                  color: bg,
                                  textColor: fg),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${p['destination'] ?? ''}',
                                  style: TextStyle(
                                      color: dark
                                          ? Colors.white
                                          : const Color(0xFF333333),
                                      fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${p['time'] == 'departure' ? context.l10n.now : p['time']}',
                                style: TextStyle(
                                  color: real
                                      ? const Color(0xFF009E61)
                                      : dark
                                          ? Colors.white
                                          : const Color(0xFF333333),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ]),
                          );
                        },
                      );
                    },
                  ),
          ),
          InkWell(
            onTap: () => launchUrl(Uri.parse(ApiClient.baseUrl)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                context.l10n.openOnActvLive,
                style: TextStyle(
                    color: const Color(0xFF009E61),
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
