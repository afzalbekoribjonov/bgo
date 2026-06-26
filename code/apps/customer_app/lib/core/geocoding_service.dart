import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Qidiruv natijasi — joy nomi + koordinata.
class GeoResult {
  final String label;
  final double lat;
  final double lng;
  const GeoResult(this.label, this.lat, this.lng);
}

/// Manzil qidirish (geocoding) — OpenStreetMap Nominatim, Beshariq doirasida.
/// plan/12-maps-navigation.md
class GeocodingService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
    // Nominatim foydalanish shartlari uchun User-Agent talab qilinadi.
    headers: {'User-Agent': 'BeshariqFood/1.0 (beshariq super-app)'},
  ));

  Future<List<GeoResult>> search(String query) async {
    final q = query.trim();
    if (q.length < 2) return const [];
    try {
      final res = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'format': 'jsonv2',
          'q': q,
          'limit': 7,
          'accept-language': 'uz',
          // Beshariq bbox: left,top,right,bottom = minLon,maxLat,maxLon,minLat
          'viewbox': '70.52,40.52,70.74,40.36',
          'bounded': 1,
          'addressdetails': 0,
        },
      );
      final list = res.data ?? const [];
      return list
          .map((e) {
            final m = e as Map<String, dynamic>;
            return GeoResult(
              _shortLabel('${m['display_name'] ?? ''}'),
              double.tryParse('${m['lat']}') ?? 0,
              double.tryParse('${m['lon']}') ?? 0,
            );
          })
          .where((r) => r.lat != 0 && r.lng != 0 && r.label.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Uzun "display_name"dan qisqa, o'qiladigan nom (birinchi 2 qism).
  String _shortLabel(String displayName) {
    return displayName
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(2)
        .join(', ');
  }
}

final geocodingServiceProvider =
    Provider<GeocodingService>((ref) => GeocodingService());
