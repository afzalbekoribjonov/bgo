import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../features/geo/geo_api.dart';
import 'map_road.dart';
import 'places.dart';

/// Beshariq xaritasi — admin paneldagidek toza OpenStreetMap. Admin belgilagan
/// joylar (oshxona/parkovka/shifoxona...) rangli belgilar bilan ko'rsatiladi.
/// Ustiga nuqta belgilari va marshrut qo'shiladi.
class BeshariqMap extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final places = ref.watch(placesProvider).valueOrNull ?? const <GeoPlace>[];
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: 11,
        maxZoom: 18,
        cameraConstraint: CameraConstraint.contain(bounds: beshariqBounds),
        onPositionChanged: onPositionChanged,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.beshariq.customer_app',
          maxZoom: 19,
        ),
        // Admin belgilagan joylar (oshxona/parkovka/shifoxona...) — rangli belgi
        if (places.isNotEmpty)
          MarkerLayer(markers: [for (final p in places) _placeMarker(p)]),
        ...overlays,
      ],
    );
  }

  /// Admin joyi — kategoriya rangidagi belgi + nom (kichik).
  Marker _placeMarker(GeoPlace p) {
    final st = placeStyle(p.category);
    return Marker(
      point: LatLng(p.lat, p.lng),
      width: 130,
      height: 46,
      alignment: Alignment.center,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: st.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 3)],
              ),
              child: Icon(st.icon, size: 13, color: Colors.white),
            ),
            const SizedBox(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                p.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
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

/// Boshlang'ich nuqta (Qayerdan) — yashil DOIRA + "siz turgan joy" ikonkasi.
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
