import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'actv_realtime.dart';
import 'storage_service.dart';

/// Delay notifications for monitored stops — port of `notifications.js`.
/// Checks realtime passages every 60s while the app runs and posts a local
/// notification when a delay ≥ threshold is observed, or when a bus that
/// was imminent disappears ("bus passato").
class NotificationsService {
  NotificationsService._();

  static const checkInterval = Duration(seconds: 60);
  static const _imminentThresholdMin = 1;
  static const _notifyCooldownMs = 300000;

  static Timer? _timer;
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _pluginReady = false;

  /// Last notified timestamps ("stopId_line_dest" → ms epoch).
  static final Map<String, int> _lastNotified = {};

  /// Imminent state per stop ("line|dest" → minutes).
  static final Map<String, Map<String, int>> _imminentState = {};

  static Future<void> init() async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        macOS: DarwinInitializationSettings(),
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      );
      _pluginReady = await _plugin.initialize(settings: settings) ?? false;
    } catch (_) {
      _pluginReady = false;
    }
    if (await isEnabled()) startMonitoring();
  }

  static Future<bool> _requestPermission() async {
    if (!_pluginReady) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
      }
      final mac = _plugin.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      if (mac != null) {
        return await mac.requestPermissions(
                alert: true, badge: true, sound: true) ??
            false;
      }
      return true; // Linux/Windows: no runtime permission
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isEnabled() async =>
      Storage.getBool(Storage.notificationsEnabled);

  static Future<int> getThreshold() async {
    final v = await Storage.getString(Storage.notificationDelayThreshold);
    return v == null ? 5 : int.tryParse(v) ?? 5;
  }

  static Future<void> setThreshold(int minutes) =>
      Storage.setString(Storage.notificationDelayThreshold, '$minutes');

  static Future<List<Map<String, dynamic>>> monitoredStops() async {
    final data = await Storage.getJson(Storage.monitoredStops, <dynamic>[]);
    if (data is! List) return [];
    return [for (final s in data) if (s is Map) Map<String, dynamic>.from(s)];
  }

  static Future<void> addMonitoredStop(String id, String name) async {
    final stops = await monitoredStops();
    if (stops.any((s) => s['id'] == id)) return;
    stops.add({'id': id, 'name': name});
    await Storage.setJson(Storage.monitoredStops, stops);
  }

  static Future<void> removeMonitoredStop(String id) async {
    final stops = (await monitoredStops()).where((s) => s['id'] != id).toList();
    await Storage.setJson(Storage.monitoredStops, stops);
  }

  static Future<bool> isStopMonitored(String id) async =>
      (await monitoredStops()).any((s) => s['id'] == id);

  /// Toggles global notifications; returns true if now enabled.
  static Future<bool> toggle() async {
    if (await isEnabled()) {
      await Storage.setBool(Storage.notificationsEnabled, false);
      stopMonitoring();
      return false;
    }
    if (!await _requestPermission()) return false;
    await Storage.setBool(Storage.notificationsEnabled, true);
    startMonitoring();
    return true;
  }

  static void startMonitoring() {
    if (_timer != null) return;
    checkDelays();
    _timer = Timer.periodic(checkInterval, (_) => checkDelays());
  }

  static void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _notify(String title, String body, String tag) async {
    if (!_pluginReady) return;
    try {
      await _plugin.show(
        id: tag.hashCode,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'delays',
            'Ritardi ACTV',
            channelDescription: 'Avvisi ritardi sulle fermate monitorate',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
          linux: LinuxNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  /// `time` → minutes ("departure"→0, "5'"→5).
  static int? passageMinutes(String? timeStr) {
    if (timeStr == 'departure') return 0;
    final m = RegExp(r'(\d+)').firstMatch('${timeStr ?? ''}');
    return m == null ? null : int.parse(m.group(1)!);
  }

  /// Detects buses that were imminent and just departed.
  /// Returns (departed, newState) — pure function for testability.
  static (List<({String line, String dest})>, Map<String, int>)
      detectDepartures(
          Map<String, int>? prevState, List<Map<String, dynamic>> passages) {
    final current = <String, int>{};
    for (final p in passages) {
      if (p['real'] != true) continue;
      final min = passageMinutes('${p['time'] ?? ''}');
      if (min == null) continue;
      final line = '${p['line'] ?? ''}'.split('_').first;
      final dest = '${p['destination'] ?? ''}'.trim();
      final key = '$line|$dest';
      if (!current.containsKey(key) || min < current[key]!) {
        current[key] = min;
      }
    }
    final departed = <({String line, String dest})>[];
    for (final e in (prevState ?? {}).entries) {
      if (e.value > _imminentThresholdMin) continue;
      final now = current[e.key];
      if (now == null || now > e.value) {
        final parts = e.key.split('|');
        departed.add((line: parts.first, dest: parts.length > 1 ? parts[1] : ''));
      }
    }
    return (departed, current);
  }

  static Future<void> checkDelays() async {
    if (!await isEnabled()) return;
    final stops = await monitoredStops();
    final threshold = await getThreshold();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    for (final stop in stops) {
      final stopId = '${stop['id']}';
      final passages = await ActvRealtime.passages(stopId);
      if (passages == null) continue;

      for (final p in passages) {
        if (p['real'] != true || p['time'] == null) continue;
        final delayMin = passageMinutes('${p['time']}');
        if (delayMin == null || delayMin < threshold) continue;
        final key = '${stopId}_${p['line']}_${p['destination']}';
        final last = _lastNotified[key];
        if (last != null && nowMs - last <= _notifyCooldownMs) continue;
        final lineName = '${p['line'] ?? ''}'.split('_').first;
        await _notify(
          'Ritardo Linea $lineName',
          '$lineName verso ${p['destination']} - ritardo $delayMin min (fermata ${stop['name']})',
          key,
        );
        _lastNotified[key] = nowMs;
      }

      final hadState = _imminentState.containsKey(stopId);
      final (departed, state) =
          detectDepartures(_imminentState[stopId], passages);
      _imminentState[stopId] = state;
      if (hadState) {
        for (final d in departed) {
          await _notify(
            'Bus passato',
            'Il bus ${d.line} verso ${d.dest} è appena passato a ${stop['name']}',
            'passed_${stopId}_${d.line}_${d.dest}',
          );
        }
      }
    }
  }
}
