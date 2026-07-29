import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Beshariq tumani xarita chegarasi — chekka qishloqlar ham sig'ishi uchun keng.
final LatLngBounds beshariqBounds = LatLngBounds(
  const LatLng(40.30, 70.42),
  const LatLng(40.58, 70.86),
);

/// Yo'l turi uslubi — haqiqiy xarita ko'rinishi (to'ldirish + kontur/casing).
class RoadStyle {
  final Color fill;
  final Color casing;

  /// z15 da to'ldirish kengligi (piksel) — zoomga qarab masshtablanadi.
  final double baseWidth;

  const RoadStyle(this.fill, this.casing, this.baseWidth);
}

/// kind → uslub. center=magistral (to'q sariq), main=asosiy (sariq),
/// street=mahalla ko'chasi (oq) — Google/OSM uslubidagi ierarxiya.
const Map<String, RoadStyle> _roadStyles = {
  'center': RoadStyle(Color(0xFFF6A623), Color(0xFFB76E00), 9.5),
  'main': RoadStyle(Color(0xFFFFD24D), Color(0xFFCC9A1F), 7.0),
  // Oq yozilgan edi — Voyager och fonda ko'rinmaydi; light blue-grey ishlatiladi
  'street': RoadStyle(Color(0xFFCFD8DC), Color(0xFF607D8B), 4.5),
};

/// Admin/OSM yo'li (Beshariq xarita qatlami). Nuqtalar + bbox (culling uchun).
class MapRoad {
  final String id;
  final String name;
  final String kind;
  final List<LatLng> points;
  final double minLat, maxLat, minLng, maxLng;

  const MapRoad({
    required this.id,
    required this.name,
    required this.kind,
    required this.points,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  RoadStyle get style => _roadStyles[kind] ?? _roadStyles['street']!;

  /// Yo'lning bbox'i ko'rinadigan hudud bilan kesishadimi (viewport culling).
  bool visibleIn(LatLngBounds b) =>
      maxLat >= b.south &&
      minLat <= b.north &&
      maxLng >= b.west &&
      minLng <= b.east;

  factory MapRoad.fromJson(Map<String, dynamic> json) {
    final raw = (json['points'] as List?) ?? const [];
    final pts = <LatLng>[];
    double mnLa = 90, mxLa = -90, mnLn = 180, mxLn = -180;
    for (final p in raw) {
      final a = p as List;
      final la = (a[0] as num).toDouble();
      final ln = (a[1] as num).toDouble();
      pts.add(LatLng(la, ln));
      if (la < mnLa) mnLa = la;
      if (la > mxLa) mxLa = la;
      if (ln < mnLn) mnLn = ln;
      if (ln > mxLn) mxLn = ln;
    }
    return MapRoad(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'street',
      points: pts,
      minLat: mnLa,
      maxLat: mxLa,
      minLng: mnLn,
      maxLng: mxLn,
    );
  }
}
