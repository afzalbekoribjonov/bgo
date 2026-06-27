import 'package:flutter/material.dart';

/// Beshariq tumani ichidagi taniqli nuqtalar (admin belgilaydi).
/// Taksi va dostavka uchun umumiy.
class GeoPlace {
  final String label;
  final double lat;
  final double lng;
  final String? category; // restaurant | parking | hospital | ...

  const GeoPlace(this.label, this.lat, this.lng, [this.category]);
}

/// Joy turi uslubi — xaritada rangli belgi (admin paneldagi ranglar bilan mos).
class PlaceStyle {
  final Color color;
  final IconData icon;
  const PlaceStyle(this.color, this.icon);
}

const Map<String, PlaceStyle> _placeStyles = {
  'restaurant': PlaceStyle(Color(0xFFE8590C), Icons.restaurant),
  'parking': PlaceStyle(Color(0xFF1971C2), Icons.local_parking),
  'hospital': PlaceStyle(Color(0xFFE03131), Icons.local_hospital),
  'market': PlaceStyle(Color(0xFF2F9E44), Icons.storefront),
  'pharmacy': PlaceStyle(Color(0xFF0CA678), Icons.local_pharmacy),
  'school': PlaceStyle(Color(0xFF7048E8), Icons.school),
  'mosque': PlaceStyle(Color(0xFF5C940D), Icons.mosque),
  'mahalla': PlaceStyle(Color(0xFF0C8599), Icons.holiday_village),
  'station': PlaceStyle(Color(0xFFF08C00), Icons.directions_bus),
  'landmark': PlaceStyle(Color(0xFF495057), Icons.place),
};

PlaceStyle placeStyle(String? category) =>
    _placeStyles[category] ?? _placeStyles['landmark']!;

const beshariqPlaces = <GeoPlace>[
  GeoPlace('Markaziy bozor', 40.4236, 70.6094),
  GeoPlace('Avtostansiya', 40.4185, 70.6042),
  GeoPlace('Tuman kasalxonasi', 40.4291, 70.6158),
  GeoPlace('Stadion', 40.4258, 70.6201),
  GeoPlace('Temir yo\'l bekati', 40.4112, 70.5983),
  GeoPlace('Yangiobod mahallasi', 40.4360, 70.6270),
  GeoPlace('Sanoat zonasi', 40.4050, 70.6300),
  GeoPlace('Universitet', 40.4205, 70.6155),
];
