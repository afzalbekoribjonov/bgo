import 'package:flutter/material.dart';

/// Beshariq tumani ichidagi taniqli nuqtalar (admin belgilaydi).
class GeoPlace {
  final String label;
  final double lat;
  final double lng;
  final String? category;

  const GeoPlace(this.label, this.lat, this.lng, [this.category]);
}

/// Joy turi uslubi — admin panel (place-style.ts) bilan rang/ikonka mos.
class PlaceStyle {
  final Color color;
  final IconData icon;
  const PlaceStyle(this.color, this.icon);
}

const Map<String, PlaceStyle> _placeStyles = {
  // Ovqat & ichimlik
  'restaurant':   PlaceStyle(Color(0xFFE8590C), Icons.restaurant),
  'cafe':         PlaceStyle(Color(0xFFA05C34), Icons.local_cafe),
  // Ta'lim
  'school':       PlaceStyle(Color(0xFF7048E8), Icons.school),
  'kindergarten': PlaceStyle(Color(0xFFE67700), Icons.child_care),
  // Sog'liq
  'hospital':     PlaceStyle(Color(0xFFE03131), Icons.local_hospital),
  'pharmacy':     PlaceStyle(Color(0xFF0CA678), Icons.local_pharmacy),
  // Savdo
  'market':       PlaceStyle(Color(0xFF2F9E44), Icons.storefront),
  'shop':         PlaceStyle(Color(0xFF1971C2), Icons.shopping_bag),
  // Din & madaniyat
  'mosque':       PlaceStyle(Color(0xFF5C940D), Icons.mosque),
  'museum':       PlaceStyle(Color(0xFF495057), Icons.museum),
  // Sport & dam olish
  'park':         PlaceStyle(Color(0xFF2F9E44), Icons.park),
  'stadium':      PlaceStyle(Color(0xFF0C8599), Icons.sports_soccer),
  // Transport
  'station':      PlaceStyle(Color(0xFFF08C00), Icons.directions_bus),
  'parking':      PlaceStyle(Color(0xFF1971C2), Icons.local_parking),
  // Yoqilg'i & avto xizmatlar
  'fuel':         PlaceStyle(Color(0xFFE65100), Icons.local_gas_station),
  'car_repair':   PlaceStyle(Color(0xFF546E7A), Icons.build),
  'car_wash':     PlaceStyle(Color(0xFF0288D1), Icons.local_car_wash),
  // Xizmatlar
  'bank':         PlaceStyle(Color(0xFF1864AB), Icons.account_balance),
  'post':         PlaceStyle(Color(0xFFD9480F), Icons.local_post_office),
  'hotel':        PlaceStyle(Color(0xFF7048E8), Icons.hotel),
  'atm':          PlaceStyle(Color(0xFF00897B), Icons.atm),
  'toilet':       PlaceStyle(Color(0xFF78909C), Icons.wc),
  // Xavfsizlik & yo'l
  'police':       PlaceStyle(Color(0xFF283593), Icons.local_police),
  'pedestrian':   PlaceStyle(Color(0xFFF9A825), Icons.directions_walk),
  // Mahalla & boshqa
  'mahalla':      PlaceStyle(Color(0xFF0C8599), Icons.holiday_village),
  'landmark':     PlaceStyle(Color(0xFF495057), Icons.place),
};

PlaceStyle placeStyle(String? category) =>
    _placeStyles[category] ?? _placeStyles['landmark']!;

/// Admin xarita belgisi (do'kon/fermer/svetofor/...) — /geo/markers.
class GeoMarker {
  final String id;
  final double lat;
  final double lng;
  final String kind;
  final String? label;

  const GeoMarker({
    required this.id,
    required this.lat,
    required this.lng,
    required this.kind,
    this.label,
  });

  factory GeoMarker.fromJson(Map<String, dynamic> j) => GeoMarker(
        id: j['id'] as String,
        lat: (j['lat'] as num).toDouble(),
        lng: (j['lng'] as num).toDouble(),
        kind: (j['kind'] as String?) ?? 'sticker',
        label: j['label'] as String?,
      );
}

/// Belgi turi uslubi — admin panel (road-map.tsx MARKER_EMOJI) bilan mos.
const Map<String, PlaceStyle> _markerStyles = {
  'shop':          PlaceStyle(Color(0xFF1971C2), Icons.storefront_rounded),
  'sticker':       PlaceStyle(Color(0xFF7048E8), Icons.push_pin_rounded),
  'construction':  PlaceStyle(Color(0xFFE8590C), Icons.engineering_rounded),
  'traffic_light': PlaceStyle(Color(0xFF2F9E44), Icons.traffic_rounded),
  'restriction':   PlaceStyle(Color(0xFFE03131), Icons.block_rounded),
  'farm':          PlaceStyle(Color(0xFF2E7D32), Icons.agriculture_rounded),
};

PlaceStyle markerStyle(String kind) =>
    _markerStyles[kind] ?? _markerStyles['sticker']!;

const beshariqPlaces = <GeoPlace>[
  GeoPlace('Markaziy bozor', 40.4236, 70.6094, 'market'),
  GeoPlace('Avtostansiya', 40.4185, 70.6042, 'station'),
  GeoPlace('Tuman kasalxonasi', 40.4291, 70.6158, 'hospital'),
  GeoPlace('Stadion', 40.4258, 70.6201, 'stadium'),
  GeoPlace("Temir yo'l bekati", 40.4112, 70.5983, 'station'),
  GeoPlace('Yangiobod mahallasi', 40.4360, 70.6270, 'mahalla'),
  GeoPlace('Sanoat zonasi', 40.4050, 70.6300, 'landmark'),
  GeoPlace('Universitet', 40.4205, 70.6155, 'school'),
];
