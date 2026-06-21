/// Beshariq tumani ichidagi taniqli nuqtalar (taxminiy koordinatalar).
/// Taksi va dostavka uchun umumiy. Xarita (MapLibre) ulangach pin tanlash
/// bilan almashtiriladi.
class GeoPlace {
  final String label;
  final double lat;
  final double lng;
  const GeoPlace(this.label, this.lat, this.lng);
}

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
