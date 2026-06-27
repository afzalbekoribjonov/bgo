import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../features/geo/geo_api.dart';
import 'map_road.dart';
import 'places.dart';

/// Beshariq professional xaritasi — toza CARTO asos, haqiqiy ko'rinishdagi
/// yo'llar (casing + ierarxiya, zoomga qarab masshtab, viewport culling) va
/// zoomga qarab o'lchami o'zgaradigan joy nomlari. Barcha ekranlarda umumiy.
class BeshariqMap extends ConsumerStatefulWidget {
  final MapController controller;
  final LatLng initialCenter;
  final double initialZoom;

  /// Yo'l/yorliq qatlamlari ustiga qo'shiladigan qatlamlar (marshrut, markerlar).
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
  late LatLngBounds _bounds;
  late double _zoom;
  Timer? _throttle;
  MapCamera? _lastCam;

  @override
  void initState() {
    super.initState();
    _zoom = widget.initialZoom;
    final c = widget.initialCenter;
    // Boshlang'ich taxminiy ko'rinish (birinchi kadrда hamma yo'lni chizmaslik).
    _bounds = LatLngBounds(
      LatLng(c.latitude - 0.03, c.longitude - 0.045),
      LatLng(c.latitude + 0.03, c.longitude + 0.045),
    );
  }

  @override
  void dispose() {
    _throttle?.cancel();
    super.dispose();
  }

  void _onPos(MapCamera cam, bool hasGesture) {
    widget.onPositionChanged?.call(cam, hasGesture);
    _lastCam = cam;
    _throttle ??= Timer(const Duration(milliseconds: 120), () {
      _throttle = null;
      if (mounted && _lastCam != null) {
        setState(() {
          _zoom = _lastCam!.zoom;
          _bounds = _lastCam!.visibleBounds;
        });
      }
    });
  }

  /// Zoomga qarab to'ldirish kengligi (piksel) — pastda ingichka, yaqinda yo'g'on.
  double _fillWidth(RoadStyle s) {
    final scale = pow(2, _zoom - 15).toDouble();
    return (s.baseWidth * scale).clamp(1.4, 26.0);
  }

  /// Ko'rinadigan + zoomга mos yo'llar (culling + decluttering).
  List<MapRoad> _visibleRoads(List<MapRoad> roads) {
    final z = _zoom;
    return roads.where((r) {
      if (!r.visibleIn(_bounds)) return false;
      if (z < 13.0 && r.kind == 'street') return false; // mahalla ko'chasi yaqinda
      if (z < 11.8 && r.kind == 'main') return false; // faqat magistrallar uzoqda
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final roads = ref.watch(roadsProvider).valueOrNull ?? const <MapRoad>[];
    final places = ref.watch(placesProvider).valueOrNull ?? beshariqPlaces;
    final visible = _visibleRoads(roads);

    // Casing (kontur) — pastki qatlam; fill — ustki qatlam (haqiqiy yo'l effekti).
    final casing = <Polyline>[];
    final fill = <Polyline>[];
    for (final r in visible) {
      if (r.points.length < 2) continue;
      final w = _fillWidth(r.style);
      casing.add(Polyline(
        points: r.points,
        strokeWidth: w + max(2.0, w * 0.5),
        color: r.style.casing,
      ));
      fill.add(Polyline(
        points: r.points,
        strokeWidth: w,
        color: r.style.fill,
      ));
    }

    return FlutterMap(
      mapController: widget.controller,
      options: MapOptions(
        initialCenter: widget.initialCenter,
        initialZoom: widget.initialZoom,
        minZoom: 11,
        maxZoom: 18,
        cameraConstraint: CameraConstraint.contain(bounds: beshariqBounds),
        onPositionChanged: _onPos,
        onMapReady: () {
          final cam = widget.controller.camera;
          setState(() {
            _zoom = cam.zoom;
            _bounds = cam.visibleBounds;
          });
        },
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c', 'd'],
          userAgentPackageName: 'com.beshariq.customer_app',
          maxZoom: 19,
        ),
        if (casing.isNotEmpty) PolylineLayer(polylines: casing),
        if (fill.isNotEmpty) PolylineLayer(polylines: fill),
        if (_zoom >= 12.5) MarkerLayer(markers: _placeLabels(places)),
        ...widget.overlays,
      ],
    );
  }

  /// Joy nomlari — zoomga qarab shrift o'lchami o'zgaradi.
  List<Marker> _placeLabels(List<GeoPlace> places) {
    final fontSize = (9.0 + (_zoom - 13) * 2.2).clamp(9.0, 17.0);
    return [
      for (final p in places)
        Marker(
          point: LatLng(p.lat, p.lng),
          width: 150,
          height: fontSize + 14,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: const Color(0xFF455A64),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                ),
                const SizedBox(width: 3),
                Flexible(
                  child: Text(
                    p.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF263238),
                      height: 1.1,
                      shadows: const [
                        Shadow(color: Colors.white, blurRadius: 2),
                        Shadow(color: Colors.white, blurRadius: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    ];
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

/// Boshlang'ich nuqta (Qayerdan) — yashil DOIRA + "siz turgan joy" ikonkasi.
/// Yakuniy manzildan SHAKLI bilan ham farq qiladi.
Marker pickupMarker(LatLng p) => Marker(
      point: p,
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: _Badge(
        color: const Color(0xFF2E7D32),
        icon: Icons.my_location,
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
        const Icon(Icons.location_pin, size: 46, color: Color(0xFFE53935)),
        Positioned(
          top: 7,
          child: Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
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
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
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
    // Ikki to'lqin, fazasi siljigan.
    for (final phase in [0.0, 0.5]) {
      final p = (t + phase) % 1.0;
      final radius = 20 + p * 58;
      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = color.withValues(alpha: (1 - p) * 0.22);
      canvas.drawCircle(center, radius, paint);
    }
    // Markaziy nuqta
    canvas.drawCircle(
      center,
      8,
      Paint()..color = color,
    );
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
