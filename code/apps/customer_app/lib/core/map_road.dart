import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  Color get color {
    switch (kind) {
      case 'center':
        return const Color(0xFFFF7043); // markaziy — qizg'ish
      case 'main':
        return const Color(0xFF2E7D32); // asosiy — to'q yashil
      default:
        return const Color(0xFF4CAF50); // ko'cha — yashil
    }
  }

  double get width => kind == 'center' ? 6 : (kind == 'main' ? 5 : 3.5);

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
