import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// Beshariq markazi va chegarasi (haydovchi navigatsiyasi uchun).
const LatLng beshariqCenter = LatLng(40.4236, 70.6094);
final LatLngBounds beshariqBounds = LatLngBounds(
  const LatLng(40.30, 70.42),
  const LatLng(40.58, 70.86),
);

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

/// OSRM marshrut natijasi — geometriya + masofa + davomiylik.
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  const RouteResult(this.points, this.distanceMeters, this.durationSeconds);

  int get etaMinutes => (durationSeconds / 60).ceil().clamp(1, 999);
  String get distanceKm => (distanceMeters / 1000).toStringAsFixed(1);
}

/// Yo'l marshruti (OSRM) — haqiqiy yo'l ustidan.
class DriverRoutingService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  Future<RouteResult?> directions(LatLng from, LatLng to) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';
      final res = await _dio.get<Map<String, dynamic>>(url);
      final routes = res.data?['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final r = routes.first as Map;
      final coords = r['geometry']?['coordinates'] as List?;
      final pts = (coords ?? const [])
          .map((c) =>
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      return RouteResult(
        pts,
        (r['distance'] as num?)?.toDouble() ?? 0,
        (r['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

final driverRoutingServiceProvider =
    Provider<DriverRoutingService>((ref) => DriverRoutingService());
