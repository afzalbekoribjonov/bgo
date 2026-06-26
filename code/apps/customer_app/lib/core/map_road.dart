import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'places.dart';

/// Beshariq tumani xarita chegarasi — kamera shu chegaradan chiqmaydi.
final LatLngBounds beshariqBounds = LatLngBounds(
  const LatLng(40.36, 70.52),
  const LatLng(40.52, 70.74),
);

/// Admin chizgan yo'l (Beshariq-maxsus xarita qatlami).
/// kind → rang: street/main = yashil, center = qizg'ish (markaziy ko'cha).
class MapRoad {
  final String id;
  final String name;
  final String kind; // street | main | center
  final List<LatLng> points;

  const MapRoad({
    required this.id,
    required this.name,
    required this.kind,
    required this.points,
  });

  /// Barcha yo'llar YASHIL — tur faqat soyani belgilaydi (ierarxiya uchun).
  Color get color {
    switch (kind) {
      case 'center':
        return const Color(0xFF1B5E20); // asosiy ko'cha — to'q yashil
      case 'main':
        return const Color(0xFF2E7D32); // yirik ko'cha — yashil
      default:
        return const Color(0xFF43A047); // mahalla ko'chasi — ochroq yashil
    }
  }

  /// Yo'l "casing" (kontur) — bir xil to'q yashil, chiziq aniq ajralib tursin.
  Color get border => const Color(0xFF0B3D14);

  /// Yo'l qalinligi — xaritada yaxshi ko'rinishi uchun yiriklashtirilgan.
  double get width => kind == 'center' ? 11 : (kind == 'main' ? 8.5 : 6.5);

  factory MapRoad.fromJson(Map<String, dynamic> json) {
    final pts = ((json['points'] as List?) ?? const [])
        .map((p) {
          final a = p as List;
          return LatLng((a[0] as num).toDouble(), (a[1] as num).toDouble());
        })
        .toList();
    return MapRoad(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      kind: (json['kind'] as String?) ?? 'street',
      points: pts,
    );
  }
}

/// Admin/OSM yo'llaridan flutter_map Polyline ro'yxati — barcha xaritalarda bir
/// xil yashil ko'rinish. Casing yo'q: butun Beshariq yo'l to'ri (minglab chiziq)
/// ham silliq chizilishi uchun har yo'lга bitta yo'l (path).
List<Polyline> buildRoadPolylines(List<MapRoad> roads) => [
      for (final r in roads)
        if (r.points.length >= 2)
          Polyline(
            points: r.points,
            strokeWidth: r.width,
            color: r.color,
          ),
    ];

/// Qishloq/joy nomlari uchun yorliqli markerlar — xaritada nomlar aniq ko'rinsin.
/// IgnorePointer: yorliqlar xarita bosishini to'smaydi.
List<Marker> buildPlaceMarkers(List<GeoPlace> places) => [
      for (final p in places)
        Marker(
          point: LatLng(p.lat, p.lng),
          width: 130,
          height: 38,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                    child: Text(
                      p.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
