import 'package:flutter/material.dart';

/// GTFS stop.
class Stop {
  final String id;
  final String code;
  final String name;
  final String? desc;
  final double? lat;
  final double? lon;
  final String? dataUrl;
  final String? service;
  final String? mode;

  const Stop({
    required this.id,
    required this.code,
    required this.name,
    this.desc,
    this.lat,
    this.lon,
    this.dataUrl,
    this.service,
    this.mode,
  });

  factory Stop.fromJson(Map<String, dynamic> j) => Stop(
        id: '${j['stop_id'] ?? ''}',
        code: '${j['stop_code'] ?? j['stop_id'] ?? ''}',
        name: j['stop_name'] ?? '',
        desc: j['stop_desc'],
        lat: _d(j['stop_lat']),
        lon: _d(j['stop_lon']),
        dataUrl: j['data_url'],
        service: j['service'],
        mode: j['mode'],
      );
}

/// A departure of a line at a stop.
class Departure {
  final String tripId;
  final String time;
  final String destination;
  final int? inMin;

  const Departure({
    required this.tripId,
    required this.time,
    required this.destination,
    this.inMin,
  });

  factory Departure.fromJson(Map<String, dynamic> j) => Departure(
        tripId: '${j['trip_id'] ?? ''}',
        time: '${j['time'] ?? ''}',
        destination: '${j['destination'] ?? j['trip_headsign'] ?? ''}',
        inMin: j['in_min'] is num ? (j['in_min'] as num).toInt() : null,
      );
}

/// A line serving a stop with its next departures.
class StopLine {
  final String routeId;
  final String shortName;
  final String longName;
  final String service;
  final String mode;
  final Color color;
  final Color textColor;
  final List<Departure> departures;

  const StopLine({
    required this.routeId,
    required this.shortName,
    required this.longName,
    required this.service,
    required this.mode,
    required this.color,
    required this.textColor,
    required this.departures,
  });

  factory StopLine.fromJson(Map<String, dynamic> j) => StopLine(
        routeId: '${j['route_id'] ?? ''}',
        shortName: '${j['route_short_name'] ?? ''}',
        longName: '${j['route_long_name'] ?? ''}',
        service: '${j['service'] ?? ''}',
        mode: '${j['mode'] ?? ''}',
        color: parseColor(j['route_color'], fallback: const Color(0xFF0759B8)),
        textColor: parseColor(j['route_text_color'], fallback: Colors.white),
        departures: [
          for (final d in (j['departures'] as List? ?? []))
            Departure.fromJson(d)
        ],
      );
}

/// Realtime vehicle position.
class Vehicle {
  final String tripId;
  final String routeId;
  final String shortName;
  final String headsign;
  final String status;
  final int delaySeconds;
  final double? lat;
  final double? lon;
  final Color color;
  final String service;

  const Vehicle({
    required this.tripId,
    required this.routeId,
    required this.shortName,
    required this.headsign,
    required this.status,
    required this.delaySeconds,
    this.lat,
    this.lon,
    required this.color,
    required this.service,
  });

  bool get isRealtime => status == 'realtime';

  factory Vehicle.fromJson(Map<String, dynamic> j) {
    final pos = j['vehicle_position'] as Map<String, dynamic>?;
    return Vehicle(
      tripId: '${j['trip_id'] ?? ''}',
      routeId: '${j['route_id'] ?? ''}',
      shortName: '${j['route_short_name'] ?? ''}',
      headsign: '${j['trip_headsign'] ?? ''}',
      status: '${j['status'] ?? 'scheduled'}',
      delaySeconds:
          j['delay_seconds'] is num ? (j['delay_seconds'] as num).toInt() : 0,
      lat: _d(pos?['lat']),
      lon: _d(pos?['lon']),
      color: parseColor(j['route_color'], fallback: const Color(0xFF9E9E9E)),
      service: '${j['service'] ?? ''}',
    );
  }
}

/// Entry of `/api/line-catalog`.
class LineCatalogEntry {
  final String line;
  final String name;
  final int variantsCount;
  final int tripsCount;

  const LineCatalogEntry({
    required this.line,
    required this.name,
    required this.variantsCount,
    required this.tripsCount,
  });

  factory LineCatalogEntry.fromJson(Map<String, dynamic> j) => LineCatalogEntry(
        line: '${j['line'] ?? ''}',
        name: '${j['name'] ?? ''}',
        variantsCount: _i(j['variants_count']),
        tripsCount: _i(j['trips_count']),
      );
}

/// A stop belonging to a trip/variant.
class TripStop {
  final String id;
  final String name;
  final double? lat;
  final double? lng;
  final int seq;
  final String? time;
  final String? arrivalTime;
  final String? departureTime;

  const TripStop({
    required this.id,
    required this.name,
    this.lat,
    this.lng,
    required this.seq,
    this.time,
    this.arrivalTime,
    this.departureTime,
  });

  factory TripStop.fromJson(Map<String, dynamic> j) => TripStop(
        id: '${j['id'] ?? j['stop_id'] ?? ''}',
        name: '${j['name'] ?? j['stop_name'] ?? ''}',
        lat: _d(j['lat'] ?? j['stop_lat']),
        lng: _d(j['lng'] ?? j['stop_lon']),
        seq: _i(j['seq'] ?? j['stop_sequence']),
        time: j['time'],
        arrivalTime: j['arrival_time'],
        departureTime: j['departure_time'],
      );
}

/// A route variant (`/api/line-variants`).
class LineVariant {
  final String shapeId;
  final String headsign;
  final String? tripId;
  final int stopsCount;
  final int tripsCount;
  final String origin;
  final String terminus;
  final List<TripStop> stops;

  const LineVariant({
    required this.shapeId,
    required this.headsign,
    this.tripId,
    required this.stopsCount,
    required this.tripsCount,
    required this.origin,
    required this.terminus,
    required this.stops,
  });

  factory LineVariant.fromJson(Map<String, dynamic> j) => LineVariant(
        shapeId: '${j['shape_id'] ?? ''}',
        headsign: '${j['headsign'] ?? ''}',
        tripId: j['trip_id']?.toString(),
        stopsCount: _i(j['stops_count']),
        tripsCount: _i(j['trips_count']),
        origin: '${j['origin'] ?? ''}',
        terminus: '${j['terminus'] ?? ''}',
        stops: [
          for (final s in (j['stops'] as List? ?? [])) TripStop.fromJson(s)
        ],
      );
}

/// A planned route (`/api/plan-route`).
class PlannedRoute {
  final String departureTime;
  final String arrivalTime;
  final int duration;
  final List<RouteLeg> legs;
  final Map<String, dynamic> raw;

  const PlannedRoute({
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.legs,
    required this.raw,
  });

  factory PlannedRoute.fromJson(Map<String, dynamic> j) => PlannedRoute(
        departureTime: '${j['departure_time'] ?? ''}',
        arrivalTime: '${j['arrival_time'] ?? ''}',
        duration: _i(j['duration']),
        legs: [
          for (final l in (j['legs'] as List? ?? [])) RouteLeg.fromJson(l)
        ],
        raw: j,
      );
}

class RouteLeg {
  final String type; // 'transit', 'walking', ...
  final Map<String, dynamic> raw;

  const RouteLeg({required this.type, required this.raw});

  String get line =>
      '${raw['route_short_name'] ?? raw['line'] ?? raw['route_id'] ?? ''}';
  String get headsign => '${raw['headsign'] ?? raw['trip_headsign'] ?? ''}';
  String get fromName =>
      '${raw['from_name'] ?? raw['from'] ?? raw['origin'] ?? ''}';
  String get toName =>
      '${raw['to_name'] ?? raw['to'] ?? raw['destination'] ?? ''}';
  String get departure => '${raw['departure_time'] ?? raw['departure'] ?? ''}';
  String get arrival => '${raw['arrival_time'] ?? raw['arrival'] ?? ''}';
  String get tripId => '${raw['trip_id'] ?? ''}';
  Color get color =>
      parseColor(raw['route_color'], fallback: const Color(0xFF0759B8));

  factory RouteLeg.fromJson(Map<String, dynamic> j) =>
      RouteLeg(type: '${j['type'] ?? 'transit'}', raw: j);
}

/// Shape point.
class ShapePoint {
  final double lat;
  final double lng;
  const ShapePoint(this.lat, this.lng);

  factory ShapePoint.fromJson(Map<String, dynamic> j) =>
      ShapePoint(_d(j['lat']) ?? 0, _d(j['lng'] ?? j['lon']) ?? 0);
}

/// Line path from `/api/lines-shapes`.
class LineShape {
  final String routeId;
  final String? tripId;
  final String shortName;
  final String longName;
  final Color color;
  final List<TripStop> path;
  final List<ShapePoint> shape;

  const LineShape({
    required this.routeId,
    this.tripId,
    required this.shortName,
    required this.longName,
    required this.color,
    required this.path,
    required this.shape,
  });

  factory LineShape.fromJson(Map<String, dynamic> j) => LineShape(
        routeId: '${j['route_id'] ?? ''}',
        tripId: j['trip_id']?.toString(),
        shortName: '${j['route_short_name'] ?? ''}',
        longName: '${j['route_long_name'] ?? ''}',
        color: parseColor(j['route_color'], fallback: const Color(0xFF0759B8)),
        path: [
          for (final p in (j['path'] as List? ?? [])) TripStop.fromJson(p)
        ],
        shape: [
          for (final p in (j['shape'] as List? ?? [])) ShapePoint.fromJson(p)
        ],
      );
}

Color parseColor(dynamic value, {required Color fallback}) {
  if (value == null) return fallback;
  var s = value.toString().trim();
  if (s.isEmpty) return fallback;
  if (s.startsWith('#')) s = s.substring(1);
  if (s.length == 3) s = s.split('').map((c) => '$c$c').join();
  if (s.length != 6) return fallback;
  final v = int.tryParse(s, radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}

double? _d(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int _i(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}
