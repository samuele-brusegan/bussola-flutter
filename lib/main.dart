import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'screens/credits_screen.dart';
import 'screens/delay_stats_screen.dart';
import 'screens/feedback_screen.dart';
import 'screens/home_alt_screen.dart';
import 'screens/home_screen.dart';
import 'screens/line_schedule_screen.dart';
import 'screens/lines_map_screen.dart';
import 'screens/live_map_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/route_finder_screen.dart';
import 'screens/stops_screen.dart';
import 'services/notifications_service.dart';
import 'theme/app_theme.dart';
import 'widgets/cookie_banner.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiClient.init();
  unawaited(NotificationsService.init());
  final themeMode = await _loadThemeMode();
  runApp(BussolaApp(themeMode: themeMode));
}

Future<ThemeMode> _loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  return switch (prefs.getString('theme_mode')) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

class BussolaApp extends StatefulWidget {
  final ThemeMode themeMode;
  const BussolaApp({super.key, required this.themeMode});

  static BussolaAppState of(BuildContext context) =>
      context.findAncestorStateOfType<BussolaAppState>()!;

  @override
  State<BussolaApp> createState() => BussolaAppState();
}

class BussolaAppState extends State<BussolaApp> {
  late ThemeMode _mode = widget.themeMode;

  ThemeMode get themeMode => _mode;

  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() => _mode = mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bussolà',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _mode,
      home: const CookieBanner(
        child: OfflineIndicator(child: MainShell()),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  static MainShellState of(BuildContext context) =>
      context.findAncestorStateOfType<MainShellState>()!;

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _index = 0;

  void select(int index) => setState(() => _index = index);

  final _pages = const [
    HomeScreen(),
    StopsScreen(),
    RouteFinderScreen(),
  ];

  void _openMore() {
    final ctx = context;
    showModalBottomSheet(
      context: ctx,
      showDragHandle: true,
      builder: (sheetCtx) {
        Widget item(IconData icon, String label, Widget screen,
            {Color? color}) {
          return ListTile(
            leading: Icon(icon, color: color ?? ctx.muted),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color ?? ctx.ink,
              ),
            ),
            onTap: () {
              Navigator.pop(sheetCtx);
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => screen),
              );
            },
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              item(Icons.map_outlined, 'Mappa linee', const LinesMapScreen()),
              item(Icons.schedule, 'Orari delle linee',
                  const LineScheduleScreen()),
              item(Icons.directions_bus, 'Bus in servizio',
                  const LiveMapScreen()),
              item(Icons.insights, 'Statistiche ritardi',
                  const DelayStatsScreen()),
              item(Icons.edit_outlined, 'Invia feedback',
                  const FeedbackScreen(),
                  color: ctx.green),
              item(Icons.privacy_tip_outlined, 'Privacy e dati',
                  const PrivacyScreen()),
              item(Icons.info_outline, 'Crediti',
                  const CreditsScreen()),
              item(Icons.home_outlined, 'Home alternativa',
                  const HomeAltScreen()),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.surface.withValues(alpha: 0.96),
          border: Border(top: BorderSide(color: context.border)),
        ),
        child: SafeArea(
          child: Row(
            children: [
              _navItem(0, Icons.home_rounded, 'Home'),
              _navItem(1, Icons.place_outlined, 'Fermate'),
              _navItem(2, Icons.swap_horiz_rounded, 'Percorsi'),
              _moreItem(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _index == index;
    final color = active ? context.greenDark : context.muted;
    return Expanded(
      child: InkWell(
        onTap: () => select(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _moreItem() {
    return Expanded(
      child: InkWell(
        onTap: _openMore,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.more_horiz, color: context.muted, size: 22),
              const SizedBox(height: 2),
              Text(
                'Altro',
                style: TextStyle(
                  color: context.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
