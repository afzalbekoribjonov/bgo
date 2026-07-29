import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/map_road.dart';
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
          m['category'] as String?,
        ));
      }
    }
    return places.isEmpty ? beshariqPlaces : places;
  }

  /// Admin chizgan yo'llar (Beshariq-maxsus xarita qatlami).
  Future<List<MapRoad>> fetchRoads() async {
    final res = await _dio.get('/geo/roads');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => MapRoad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Admin belgilagan xarita belgilari (do'kon/fermer/svetofor/...).
  Future<List<GeoMarker>> fetchMarkers() async {
    final res = await _dio.get('/geo/markers');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => GeoMarker.fromJson(e as Map<String, dynamic>))
        .toList();
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

/// Admin chizgan yo'llar (xato bo'lsa bo'sh).
final roadsProvider = FutureProvider<List<MapRoad>>((ref) async {
  try {
    return await ref.read(geoApiProvider).fetchRoads();
  } catch (_) {
    return const [];
  }
});

/// Admin xarita belgilari (xato bo'lsa bo'sh).
final geoMarkersProvider = FutureProvider<List<GeoMarker>>((ref) async {
  try {
    return await ref.read(geoApiProvider).fetchMarkers();
  } catch (_) {
    return const [];
  }
});
