import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';

/// Admin belgilagan joy (oshxona/mahalla/...). Xaritada belgi sifatida.
class GeoPlace {
  final String label;
  final double lat;
  final double lng;
  final String? category;
  const GeoPlace(this.label, this.lat, this.lng, this.category);
}

/// Admin yo'li (navigator qatlam) — nuqtalar ketma-ketligi.
class GeoRoad {
  final List<LatLng> points;
  final String kind; // center | main | street
  const GeoRoad(this.points, this.kind);
}

/// Admin belgilagan joylar (/geo/areas -> places, xato bo'lsa bo'sh).
final geoPlacesProvider = FutureProvider<List<GeoPlace>>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/geo/areas');
    final areas = (res.data['data'] as List?) ?? const [];
    final places = <GeoPlace>[];
    for (final a in areas) {
      for (final p in ((a as Map)['places'] as List?) ?? const []) {
        places.add(GeoPlace(
          ((p as Map)['label'] as String?) ?? '',
          (p['lat'] as num).toDouble(),
          (p['lng'] as num).toDouble(),
          p['category'] as String?,
        ));
      }
    }
    return places;
  } catch (_) {
    return const [];
  }
});

/// Admin yo'llari (/geo/roads) — navigator uchun sariq chetli qatlam
/// (xato bo'lsa bo'sh, xarita baribir ishlayveradi).
final geoRoadsProvider = FutureProvider<List<GeoRoad>>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/geo/roads');
    final list = (res.data['data'] as List?) ?? const [];
    return list.map((r) {
      final pts = (((r as Map)['points'] as List?) ?? const [])
          .map((c) => LatLng((c[0] as num).toDouble(), (c[1] as num).toDouble()))
          .toList();
      return GeoRoad(pts, (r['kind'] as String?) ?? 'street');
    }).toList();
  } catch (_) {
    return const [];
  }
});

/// Admin xarita belgisi (do'kon/fermer/svetofor/...) — /geo/markers.
class GeoMapMarker {
  final double lat;
  final double lng;
  final String kind;
  final String? label;
  const GeoMapMarker(this.lat, this.lng, this.kind, this.label);
}

/// Admin belgilari (xato bo'lsa bo'sh) — xaritada kichik chip sifatida.
final geoMarkersProvider = FutureProvider<List<GeoMapMarker>>((ref) async {
  try {
    final dio = ref.read(dioProvider);
    final res = await dio.get('/geo/markers');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((m) => GeoMapMarker(
              ((m as Map)['lat'] as num).toDouble(),
              (m['lng'] as num).toDouble(),
              (m['kind'] as String?) ?? 'sticker',
              m['label'] as String?,
            ))
        .toList();
  } catch (_) {
    return const [];
  }
});
