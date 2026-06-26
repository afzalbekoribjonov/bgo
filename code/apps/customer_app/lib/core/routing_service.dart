import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Marshrut natijasi — geometriya + masofa + davomiylik (ETA uchun).
class RouteResult {
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;

  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  /// ETA (daqiqa, kamida 1).
  int get etaMinutes => (durationSeconds / 60).ceil().clamp(1, 999);
}

/// Yo'l marshruti (OSRM) — ikki nuqta orasidagi haqiqiy yo'l geometriyasi.
/// Xaritada to'g'ri chiziq emas, yo'llar ustidan chizish uchun.
/// plan/12-maps-navigation.md
class RoutingService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  String _url(LatLng from, LatLng to) =>
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson';

  /// Marshrut nuqtalari (LatLng ro'yxati). Xato bo'lsa bo'sh ro'yxat.
  Future<List<LatLng>> route(LatLng from, LatLng to) async {
    final r = await directions(from, to);
    return r?.points ?? const [];
  }

  /// To'liq marshrut (geometriya + masofa + ETA). Xato bo'lsa null.
  Future<RouteResult?> directions(LatLng from, LatLng to) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(_url(from, to));
      final routes = res.data?['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;
      final r = routes.first as Map;
      final coords = r['geometry']?['coordinates'] as List?;
      final pts = (coords ?? const [])
          .map((c) =>
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
      return RouteResult(
        points: pts,
        distanceMeters: (r['distance'] as num?)?.toDouble() ?? 0,
        durationSeconds: (r['duration'] as num?)?.toDouble() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

final routingServiceProvider =
    Provider<RoutingService>((ref) => RoutingService());
