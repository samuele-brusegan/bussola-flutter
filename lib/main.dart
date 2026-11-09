import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api/api_client.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n_ext.dart';
import 'screens/credits_screen.dart';
import 'screens/delay_stats_screen.dart';
import 'screens/feedback_screen.dart';
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
  // I font Inter sono bundled in assets/google_fonts/: niente fetch a runtime.
  GoogleFonts.config.allowRuntimeFetching = false;
  await ApiClient.init();
  unawaited(NotificationsService.init());
  final themeMode = await _loadThemeMode();
  final locale = await _loadLocale();
  runApp(BussolaApp(themeMode: themeMode, locale: locale));
}

Future<ThemeMode> _loadThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  return switch (prefs.getString('theme_mode')) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

Future<Locale?> _loadLocale() async {
  final prefs = await SharedPreferences.getInstance();
  return switch (prefs.getString('app_locale')) {
    'it' => const Locale('it'),
    'en' => const Locale('en'),
    _ => null,
  };
}

class BussolaApp extends StatefulWidget {
  final ThemeMode themeMode;
  final Locale? locale;
  const BussolaApp({super.key, required this.themeMode, this.locale});

  static BussolaAppState of(BuildContext context) =>
      context.findAncestorStateOfType<BussolaAppState>()!;

  @override
  State<BussolaApp> createState() => BussolaAppState();
}

class BussolaAppState extends State<BussolaApp> {
  late ThemeMode _mode = widget.themeMode;
  late Locale? _locale = widget.locale;

  ThemeMode get themeMode => _mode;
  Locale? get locale => _locale;

  Future<void> setLocale(String? code) async {
    setState(() => _locale = code == null ? null : Locale(code));
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove('app_locale');
    } else {
      await prefs.setString('app_locale', code);
    }
  }

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
      locale: _locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
    final l10n = ctx.l10n;
    showModalBottomSheet(
      context: ctx,
      showDragHandle: true,
      builder: (sheetCtx) {
        Widget item(IconData icon, String label, Widget? screen,
            {Color? color, VoidCallback? onTap}) {
          return ListTile(
            leading: Icon(icon, color: color ?? ctx.muted),
            title: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color ?? ctx.ink,
              ),
            ),
            onTap: onTap ??
                () {
                  Navigator.pop(sheetCtx);
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(builder: (_) => screen!),
                  );
                },
          );
        }

        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              item(Icons.directions_bus, l10n.moreLiveVehicles,
                  const LiveMapScreen()),
              item(Icons.map_outlined, l10n.moreLinesMap,
                  const LinesMapScreen()),
              item(Icons.schedule, l10n.moreLineSchedules,
                  const LineScheduleScreen()),
              item(Icons.insights, l10n.moreDelayStats,
                  const DelayStatsScreen()),
              const Divider(height: 16),
              item(Icons.edit_outlined, l10n.moreFeedback,
                  const FeedbackScreen(),
                  color: ctx.green),
              item(Icons.language, l10n.moreLanguage, null,
                  onTap: () => _pickLanguage(sheetCtx)),
              const Divider(height: 16),
              item(Icons.privacy_tip_outlined, l10n.morePrivacy,
                  const PrivacyScreen()),
              item(Icons.info_outline, l10n.moreCredits,
                  const CreditsScreen()),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _pickLanguage(BuildContext sheetCtx) {
    final l10n = context.l10n;
    Navigator.pop(sheetCtx);
    showDialog(
      context: context,
      builder: (dlgCtx) => SimpleDialog(
        title: Text(l10n.languageTitle),
        children: [
          for (final (code, label) in [
            (null, l10n.languageSystem),
            ('it', 'Italiano'),
            ('en', 'English'),
          ])
            SimpleDialogOption(
              onPressed: () {
                BussolaApp.of(context).setLocale(code);
                Navigator.pop(dlgCtx);
              },
              child: Text(label),
            ),
        ],
      ),
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
              _navItem(0, Icons.home_rounded, context.l10n.navHome),
              _navItem(1, Icons.place_outlined, context.l10n.navStops),
              _navItem(2, Icons.swap_horiz_rounded, context.l10n.navRoutes),
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
                context.l10n.navMore,
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
