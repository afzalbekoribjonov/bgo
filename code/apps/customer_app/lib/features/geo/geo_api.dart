import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/places.dart';

/// Xizmat hududlari + joylarni backend'dan oladi (admin boshqaradi).
/// plan/12-maps-navigation.md
class GeoApi {
  final Dio _dio;
  GeoApi(this._dio);

  /// Barcha faol hududlardagi joylar (xaritada tanlash uchun).
  Future<List<GeoPlace>> fetchPlaces() async {
    final res = await _dio.get('/geo/areas');
    final areas = (res.data['data'] as List?) ?? const [];
    final places = <GeoPlace>[];
    for (final a in areas) {
      for (final p in (a['places'] as List? ?? const [])) {
        final m = p as Map<String, dynamic>;
        places.add(GeoPlace(
          m['label'] as String,
          (m['lat'] as num).toDouble(),
          (m['lng'] as num).toDouble(),
        ));
      }
    }
    return places.isEmpty ? beshariqPlaces : places;
  }
}

final geoApiProvider =
    Provider<GeoApi>((ref) => GeoApi(ref.read(dioProvider)));

/// Tanlanadigan joylar — API'dan; xato/bo'sh bo'lsa beshariqPlaces zaxira.
final placesProvider = FutureProvider<List<GeoPlace>>((ref) async {
  ref.watch(localeProvider);
  try {
    return await ref.read(geoApiProvider).fetchPlaces();
  } catch (_) {
    return beshariqPlaces;
  }
});
