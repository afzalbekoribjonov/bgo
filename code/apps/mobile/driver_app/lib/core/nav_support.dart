import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';

/// Beshariq markazi va chegarasi (haydovchi navigatsiyasi uchun).
const LatLng beshariqCenter = LatLng(40.4236, 70.6094);
final LatLngBounds beshariqBounds = LatLngBounds(
  const LatLng(40.30, 70.42),
  const LatLng(40.58, 70.86),
);

/// Haydovchining joriy joylashuvi + yo'nalishi (heading) + tezligi.
class DriverFix {
  final LatLng pos;
  final double heading; // gradus (0 = shimol)
  final double speedKmh; // km/soat
  const DriverFix(this.pos, this.heading, this.speedKmh);
}

/// Joriy GPS o'qishi (joylashuv + heading + tezlik). Yo'q bo'lsa null.
Future<DriverFix?> driverCurrentFix() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    final kmh = (p.speed.isNaN || p.speed < 0 ? 0.0 : p.speed) * 3.6;
    final heading = p.heading.isNaN ? 0.0 : p.heading;
    return DriverFix(LatLng(p.latitude, p.longitude), heading, kmh);
  } catch (_) {
    return null;
  }
}

/// Haydovchining joriy GPS joylashuvi (yo'q bo'lsa null).
Future<LatLng?> driverCurrentLatLng() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      return null;
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(pos.latitude, pos.longitude);
  } catch (_) {
    return null;
  }
}

/// Bitta burilish (maneuver) — backend orqali OSRM `steps`dan keladi.
/// Turn-by-turn ogohlantirish shu ma'lumot asosida beriladi.
class RouteStep {
  /// OSRM maneuver.type: depart|turn|new name|merge|fork|roundabout|arrive...
  final String type;

  /// OSRM maneuver.modifier: left|right|slight left|sharp right|straight|uturn
  /// (ba'zi turlarda bo'lmaydi — null).
  final String? modifier;

  /// SHU qadam uzunligi — burilishgacha bosib o'tiladigan masofa (metr).
  final double distanceMeters;
  final double durationSeconds;

  /// Burilish nuqtasi.
  final LatLng location;
  final String? streetName;

  /// Aylanma yo'ldan chiqish raqami (bo'lmasa null).
  final int? exit;

  const RouteStep({
    required this.type,
    required this.modifier,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.location,
    this.streetName,
    this.exit,
  });

  factory RouteStep.fromJson(Map<String, dynamic> j) {
    final loc = (j['location'] as List?) ?? const [];
    return RouteStep(
      type: (j['type'] as String?) ?? 'turn',
      modifier: j['modifier'] as String?,
      distanceMeters: (j['distanceMeters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (j['durationSeconds'] as num?)?.toDouble() ?? 0,
      location: loc.length >= 2
          ? LatLng((loc[0] as num).toDouble(), (loc[1] as num).toDouble())
          : const LatLng(0, 0),
      streetName: j['streetName'] as String?,
      exit: (j['exit'] as num?)?.toInt(),
    );
  }
}

/// OSRM marshrut natijasi — geometriya + masofa + davomiylik + burilishlar.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  /// Burilishlar ro'yxati. Zaxira (to'g'ri chiziq) holatida bo'sh bo'ladi —
  /// bunda turn-by-turn ogohlantirish ishlamaydi, qolgani ishlaydi.
  final List<RouteStep> steps;

  const RouteResult(
    this.points,
    this.distanceMeters,
    this.durationSeconds, {
    this.steps = const [],
  });

  bool get hasSteps => steps.isNotEmpty;
  int get etaMinutes => (durationSeconds / 60).ceil().clamp(1, 999);
  String get distanceKm => (distanceMeters / 1000).toStringAsFixed(1);
}

/// Yo'l marshruti — backend (`GET /driver/route`) orqali O'ZIMIZNING
/// self-hosted OSRM'dan olinadi (ochiq demo-serverga chiqilmaydi) va
/// burilishlar (`steps`) bilan birga keladi.
///
/// Xato/timeout/OSRM ishlamasa — `null` qaytaradi; chaqiruvchilar mavjud
/// "to'g'ri chiziq" zaxirasiga tushadi (`dir?.points ?? [me, target]`).
class DriverRoutingService {
  final Dio _dio;
  DriverRoutingService(this._dio);

  Future<RouteResult?> directions(LatLng from, LatLng to) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/driver/route',
        queryParameters: {
          'fromLat': from.latitude,
          'fromLng': from.longitude,
          'toLat': to.latitude,
          'toLng': to.longitude,
        },
      );
      final data = res.data?['data'] as Map<String, dynamic>?;
      if (data == null) return null; // OSRM javob bermadi — zaxiraga tushamiz
      final pts = ((data['points'] as List?) ?? const [])
          .whereType<List>()
          .where((c) => c.length >= 2)
          .map((c) =>
              LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble()))
          .toList();
      if (pts.length < 2) return null;
      final steps = ((data['steps'] as List?) ?? const [])
          .whereType<Map>()
          .map((s) => RouteStep.fromJson(s.cast<String, dynamic>()))
          .toList();
      return RouteResult(
        pts,
        (data['distanceMeters'] as num?)?.toDouble() ?? 0,
        (data['durationSeconds'] as num?)?.toDouble() ?? 0,
        steps: steps,
      );
    } catch (_) {
      return null;
    }
  }
}

final driverRoutingServiceProvider = Provider<DriverRoutingService>(
  (ref) => DriverRoutingService(ref.read(dioProvider)),
);
