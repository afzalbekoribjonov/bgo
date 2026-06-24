import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Yo'l marshruti (OSRM) — ikki nuqta orasidagi haqiqiy yo'l geometriyasi.
/// Xaritada to'g'ri chiziq emas, yo'llar ustidan chizish uchun.
/// plan/12-maps-navigation.md
class RoutingService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  /// Marshrut nuqtalari (LatLng ro'yxati). Xato bo'lsa bo'sh ro'yxat.
  Future<List<LatLng>> route(LatLng from, LatLng to) async {
    try {
      final url = 'https://router.project-osrm.org/route/v1/driving/'
          '${from.longitude},${from.latitude};${to.longitude},${to.latitude}'
          '?overview=full&geometries=geojson';
      final res = await _dio.get<Map<String, dynamic>>(url);
      final routes = res.data?['routes'] as List?;
      if (routes == null || routes.isEmpty) return const [];
      final coords =
          (routes.first as Map)['geometry']?['coordinates'] as List?;
      if (coords == null) return const [];
      return coords
          .map((c) =>
              LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}

final routingServiceProvider =
    Provider<RoutingService>((ref) => RoutingService());
