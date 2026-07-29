import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../features/geo/geo_api.dart';
import 'map_road.dart';
import 'places.dart';

/// Beshariq xaritasi — admin belgilagan yo'llar + joylar bilan professional ko'rinish.
/// Barcha xarita ekranlarida (taksi, dostavka, oshxona, joy tanlash) yagona komponent.
class BeshariqMap extends ConsumerStatefulWidget {
  final MapController controller;
  final LatLng initialCenter;
  final double initialZoom;

  /// Yo'l/plitka ustiga qo'shiladigan qatlamlar (marshrut, markerlar).
  final List<Widget> overlays;

  /// Kamera o'zgarishi (markaz pin uchun — map picker ishlatadi).
  final void Function(MapCamera camera, bool hasGesture)? onPositionChanged;

  const BeshariqMap({
    super.key,
    required this.controller,
    required this.initialCenter,
    this.initialZoom = 15,
    this.overlays = const [],
    this.onPositionChanged,
  });

  @override
  ConsumerState<BeshariqMap> createState() => _BeshariqMapState();
}

class _BeshariqMapState extends ConsumerState<BeshariqMap> {
  double _zoom = 15;

  // Katta zoomda belgilar kichrayadi — ekranni berkitishining oldini oladi
  double get _circleSize {
    if (_zoom < 14) return 30;
    if (_zoom < 16) return 26;
    if (_zoom < 17) return 22;
    return 18;
  }

  double get _iconSize => _circleSize * 0.56;

  double get _fontSize {
    if (_zoom < 14) return 12;
    if (_zoom < 16) return 11.5;
    if (_zoom < 17) return 11;
    return 10.5;
  }

  @override
  Widget build(BuildContext context) {
    final places = ref.watch(placesProvider).valueOrNull ?? const <GeoPlace>[];
    final allRoads = ref.watch(roadsProvider).valueOrNull ?? const <MapRoad>[];
    final markers =
        ref.watch(geoMarkersProvider).valueOrNull ?? const <GeoMarker>[];
    // farmland — chiziq emas, yashil dala poligoni sifatida chiziladi.
    final roads = [
      for (final r in allRoads)
        if (r.kind != 'farmland') r,
    ];
    final farmlands = [
      for (final r in allRoads)
        if (r.kind == 'farmland' && r.points.length >= 3) r,
    ];

    return FlutterMap(
      mapController: widget.controller,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: 11,
        maxZoom: 18,
        cameraConstraint: CameraConstraint.contain(bounds: beshariqBounds),
        onPositionChanged: (camera, hasGesture) {
          // 0.5 zoomdan farq bo'lganda qayta chiz (haddan ko'p rebuild'larni kamaytirish)
          if ((camera.zoom - _zoom).abs() >= 0.5) {
            setState(() => _zoom = camera.zoom);
          }
          widget.onPositionChanged?.call(camera, hasGesture);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.beshariq.customer_app',
          maxZoom: 19,
          maxNativeZoom: 18,
        ),

        // Dehqonchilik maydonlari — yashil dalalar (yo'llar ostida)
        if (farmlands.isNotEmpty)
          PolygonLayer(
            polygons: [
              for (final f in farmlands)
                Polygon(
                  points: f.points,
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.28),
                  borderColor: const Color(0xFF2E7D32),
                  borderStrokeWidth: 1.6,
                ),
            ],
          ),

        // Admin chizgan yo'llar — casing (kontur) qatlami
        if (roads.isNotEmpty)
          PolylineLayer(
            polylines: [
              for (final r in roads)
                Polyline(
                  points: r.points,
                  strokeWidth: r.kind == 'center' ? 9.5 : (r.kind == 'main' ? 7.0 : 4.5),
                  color: r.style.casing,
                ),
            ],
          ),

        // Admin chizgan yo'llar — fill (rang) qatlami
        if (roads.isNotEmpty)
          PolylineLayer(
            polylines: [
              for (final r in roads)
                Polyline(
                  points: r.points,
                  strokeWidth: r.kind == 'center' ? 7.0 : (r.kind == 'main' ? 5.0 : 3.0),
                  color: r.style.fill,
                ),
            ],
          ),

        // Admin belgilagan joylar — zoomga moslashuvchan belgilar
        if (places.isNotEmpty)
          MarkerLayer(markers: [for (final p in places) _placeMarker(p)]),

        // Admin xarita belgilari (do'kon/fermer/svetofor/...) — zoom 14+
        if (markers.isNotEmpty && _zoom >= 14)
          MarkerLayer(
              markers: [for (final m in markers) _adminMarker(m)]),

        ...widget.overlays,
      ],
    );
  }

  /// Admin xarita belgisi — kvadratik chip (joylardan farqli ko'rinish).
  Marker _adminMarker(GeoMarker m) {
    final st = markerStyle(m.kind);
    final cs = _circleSize * 0.85;
    final hasLabel = (m.label ?? '').isNotEmpty;
    return Marker(
      point: LatLng(m.lat, m.lng),
      width: 130,
      height: cs + (hasLabel ? 22 : 6),
      alignment: Alignment.center,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: cs,
              height: cs,
              decoration: BoxDecoration(
                color: st.color,
                borderRadius: BorderRadius.circular(cs * 0.32),
                border: Border.all(color: Colors.white, width: 1.8),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black38,
                      blurRadius: 3,
                      offset: Offset(0, 1.5)),
                ],
              ),
              child: Icon(st.icon, size: cs * 0.6, color: Colors.white),
            ),
            if (hasLabel) ...[
              const SizedBox(height: 2),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  m.label!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: _fontSize - 1.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF37474F),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Admin joyi — zoomga moslashuvchan kattalikdagi belgi + nom.
  Marker _placeMarker(GeoPlace p) {
    final st = placeStyle(p.category);
    final cs = _circleSize;
    return Marker(
      point: LatLng(p.lat, p.lng),
      width: 150,
      height: cs + 26,
      alignment: Alignment.center,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: cs,
              height: cs,
              decoration: BoxDecoration(
                color: st.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Icon(st.icon, size: _iconSize, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(5),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
              ),
              child: Text(
                p.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF263238),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== Markerlar (boshlang'ich/yakuniy/joriy) =====================

/// "Siz turgan joy" — joriy GPS, pulslanuvchi ko'k nuqta.
Marker myLocationMarker(LatLng p) => Marker(
      point: p,
      width: 30,
      height: 30,
      alignment: Alignment.center,
      child: const _PulsingDot(),
    );

/// Boshlang'ich nuqta (Qayerdan) — qo'l ko'targan yo'lovchi (taksi chaqirmoqda).
Marker pickupMarker(LatLng p) => Marker(
      point: p,
      width: 44,
      height: 44,
      alignment: Alignment.center,
      child: _Badge(
        color: const Color(0xFF2E7D32),
        icon: Icons.hail_rounded,
      ),
    );

/// Yakuniy manzil (Qayerga) — qizil PIN (tomchi) + bayroq (manzil mazmuni).
Marker destMarker(LatLng p) => Marker(
      point: p,
      width: 44,
      height: 48,
      alignment: Alignment.bottomCenter,
      child: const _DestinationPin(),
    );

/// Haydovchi qidirilayotganda boshlang'ich nuqtada tarqaluvchi "radar" signali.
Marker searchPulseMarker(LatLng p) => Marker(
      point: p,
      width: 160,
      height: 160,
      alignment: Alignment.center,
      child: const IgnorePointer(child: _SearchPulse()),
    );

class _Badge extends StatelessWidget {
  final Color color;
  final IconData icon;
  const _Badge({required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 5)],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _DestinationPin extends StatelessWidget {
  const _DestinationPin();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Pin uchi ostidagi "yer" soyasi — belgi xaritada turgandek ko'rinadi.
        Positioned(
          bottom: 0,
          child: Container(
            width: 14,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
        const Icon(Icons.location_pin,
            size: 46,
            color: Color(0xFFE53935),
            shadows: [Shadow(color: Colors.black38, blurRadius: 6)]),
        Positioned(
          top: 7,
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 3),
              ],
            ),
            child: const Icon(Icons.flag, size: 14, color: Color(0xFFE53935)),
          ),
        ),
      ],
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot();
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 8 + t * 22,
              height: 8 + t * 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1E88E5).withValues(alpha: (1 - t) * 0.35),
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF1E88E5),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchPulse extends StatefulWidget {
  const _SearchPulse();
  @override
  State<_SearchPulse> createState() => _SearchPulseState();
}

class _SearchPulseState extends State<_SearchPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => CustomPaint(
        size: const Size(160, 160),
        painter: _PulsePainter(_c.value),
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double t;
  _PulsePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const color = Color(0xFFE8590C);
    for (final phase in [0.0, 0.5]) {
      final p = (t + phase) % 1.0;
      final radius = 20 + p * 58;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: (1 - p) * 0.22);
      canvas.drawCircle(center, radius, paint);
    }
    canvas.drawCircle(center, 8, Paint()..color = color);
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_PulsePainter old) => old.t != t;
}
