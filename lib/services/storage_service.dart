import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Central access to every persisted key, mirroring the web app's
/// `localStorage`/`sessionStorage` keys (07-frontend.md).
class Storage {
  Storage._();

  // localStorage-equivalent keys
  static const theme = 'theme';
  static const cookieConsent = 'cookie_consent_accepted';
  static const favoriteStops = 'favorite_stops';
  static const recentStops = 'recent_stops';
  static const favoriteRoutes = 'favorite_routes';
  static const routeOrigin = 'route_origin';
  static const routeDestination = 'route_destination';
  static const routeDepartureDate = 'route_departure_date';
  static const routeDepartureTime = 'route_departure_time';
  static const routeReturnTime = 'route_return_time';
  static const routeOptimize = 'route_optimize';
  static const routeReturnTrip = 'route_return_trip';
  static const routeLastUsedAt = 'route_last_used_at';
  static const routeResultsCache = 'route_results_cache';
  static const notificationsEnabled = 'notifications_enabled';
  static const notificationDelayThreshold = 'notification_delay_threshold';
  static const monitoredStops = 'monitored_stops';
  static const delayHistory = 'delay_history';
  static const homeTutorialSeen = 'home_tutorial_seen';
  static const tripFinderState = 'actvLive.tripFinder';
  static const searchHistory = 'live_map_search_history';

  static String serviceKey(String page) => 'actv-$page-service';

  static Future<SharedPreferences> get _p => SharedPreferences.getInstance();

  static Future<String?> getString(String key) async =>
      (await _p).getString(key);

  static Future<void> setString(String key, String value) async =>
      (await _p).setString(key, value);

  static Future<void> remove(String key) async => (await _p).remove(key);

  static Future<dynamic> getJson(String key, [dynamic fallback]) async {
    try {
      final raw = (await _p).getString(key);
      if (raw == null) return fallback;
      return jsonDecode(raw);
    } catch (_) {
      return fallback;
    }
  }

  static Future<void> setJson(String key, dynamic value) async =>
      (await _p).setString(key, jsonEncode(value));

  static Future<bool> getBool(String key) async =>
      (await _p).getString(key) == 'true';

  static Future<void> setBool(String key, bool value) async =>
      (await _p).setString(key, value ? 'true' : 'false');
}
