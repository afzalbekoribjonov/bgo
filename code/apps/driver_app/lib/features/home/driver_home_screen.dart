import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/alert_sound.dart';
import '../../core/driver_geo.dart';
import '../../core/nav_support.dart';
import '../../widgets/slide_to_confirm.dart';
import '../auth/auth_api.dart';
import '../delivery/delivery_api.dart';
import '../parcel/parcel_api.dart';
import '../profile/driver_profile_screen.dart';
import '../stats/today_screen.dart';
import '../taxi/taxi_api.dart';
import 'balance_screen.dart';

const _gold = Color(0xFFD4AF37);
const _offlineNav = Color(0xFF263238);

/// Haydovchi bosh ekrani — xarita + navigator belgisi + tortiluvchi panel.
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final MapController _map = MapController();
  final DraggableScrollableController _sheet = DraggableScrollableController();
  DriverFix? _fix;
  double _zoom = 16;
  Timer? _gpsTimer;
  Timer? _pollTimer;
  int _lastAvailable = 0;
  bool _silenced = false;
  bool _showOfflineSlider = false;

  @override
  void initState() {
    super.initState();
    _initOnline();
    _refreshGps();
    _gpsTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshGps());
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted || !ref.read(onlineProvider)) return;
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(availableTaxiProvider);
      ref.invalidate(availableParcelsProvider);
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _pollTimer?.cancel();
    ref.read(alertSoundProvider).stop();
    _sheet.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _initOnline() async {
    try {
      final online = await ref.read(authApiProvider).fetchOnline();
      if (mounted) ref.read(onlineProvider.notifier).state = online;
    } catch (_) {}
  }

  Future<void> _refreshGps() async {
    final fix = await driverCurrentFix();
    if (!mounted || fix == null) return;
    setState(() => _fix = fix);
    _map.move(fix.pos, _zoom < 11 ? 16 : _zoom);
  }

  Future<void> _setOnline(bool value) async {
    ref.read(onlineProvider.notifier).state = value;
    _showOfflineSlider = false;
    if (!value) ref.read(alertSoundProvider).stop();
    HapticFeedback.mediumImpact();
    try {
      await ref.read(authApiProvider).setOnline(value);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNetworkError(e) ? 'Tarmoq xatosi' : 'Xatolik')),
        );
      }
    }
  }

  void _onMoonTap(bool online) {
    if (online) {
      setState(() => _showOfflineSlider = true);
      _sheet.animateTo(0.30,
          duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
    }
  }

  void _updateAlert(int available, bool online) {
    final alert = ref.read(alertSoundProvider);
    if (!online || available == 0) {
      _silenced = false;
      _lastAvailable = available;
      if (alert.isPlaying) alert.stop();
      return;
    }
    if (available > _lastAvailable) {
      _silenced = false;
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 350), HapticFeedback.heavyImpact);
    }
    _lastAvailable = available;
    final soundOn = ref.read(soundEnabledProvider);
    if (_silenced || !soundOn) {
      if (alert.isPlaying) alert.stop();
    } else {
      if (!alert.isPlaying) alert.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(onlineProvider);
    final available = (ref.watch(availableOrdersProvider).value?.length ?? 0) +
        (ref.watch(availableTaxiProvider).value?.length ?? 0) +
        (ref.watch(availableParcelsProvider).value?.length ?? 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateAlert(available, online);
    });
    final top = MediaQuery.of(context).padding.top;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _mapWidget(online)),
          Positioned(
            top: top + 10,
            left: 16,
            child: _StatusMoon(online: online, onTap: () => _onMoonTap(online)),
          ),
          Positioned(top: top + 84, left: 18, child: _SpeedBadge(_fix?.speedKmh ?? 0)),
          Positioned(top: top + 10, right: 16, child: _avatar()),
          Positioned(right: 18, bottom: h * 0.32, child: _recenter()),
          _bottomSheet(online),
        ],
      ),
    );
  }

  // ---------------- Xarita ----------------

  Widget _mapWidget(bool online) {
    final places = ref.watch(geoPlacesProvider).valueOrNull ?? const <GeoPlace>[];
    final roads = ref.watch(geoRoadsProvider).valueOrNull ?? const <GeoRoad>[];
    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _fix?.pos ?? beshariqCenter,
        initialZoom: 16,
        minZoom: 11,
        maxZoom: 18,
        cameraConstraint: CameraConstraint.contain(bounds: beshariqBounds),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
        ),
        onPositionChanged: (camera, _) {
          if ((camera.zoom - _zoom).abs() > 0.15) {
            setState(() => _zoom = camera.zoom);
          }
        },
        onTap: (_, __) => _toggleSheet(),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.beshariq.driver_app',
          maxZoom: 19,
        ),
        if (roads.isNotEmpty && _zoom >= 13)
          PolylineLayer(
            polylines: [
              for (final r in roads)
                Polyline(
                  points: r.points,
                  strokeWidth:
                      r.kind == 'center' ? 6 : (r.kind == 'main' ? 5 : 4),
                  color: const Color(0xFFFFFFFF),
                  borderStrokeWidth: 2,
                  borderColor: const Color(0xFFEFC34B),
                ),
            ],
          ),
        if (places.isNotEmpty && _zoom >= 14)
          MarkerLayer(markers: [for (final p in places) _placeMarker(p)]),
        if (_fix != null)
          MarkerLayer(markers: [_driverMarker(_fix!, online)]),
      ],
    );
  }

  Marker _driverMarker(DriverFix fix, bool online) {
    final size = (40 + (_zoom - 16) * 8).clamp(28.0, 62.0);
    return Marker(
      point: fix.pos,
      width: size + 16,
      height: size + 16,
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: fix.heading * math.pi / 180,
        child: CustomPaint(
          size: Size.square(size),
          painter: _NavPainter(online ? _gold : _offlineNav, online),
        ),
      ),
    );
  }

  Marker _placeMarker(GeoPlace p) {
    return Marker(
      point: LatLng(p.lat, p.lng),
      width: 110,
      height: 36,
      alignment: Alignment.center,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, size: 14, color: Color(0xFF6D4C41)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(p.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF455A64))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatar() {
    final initial = ref.watch(driverProfileProvider).valueOrNull?.initial ?? '?';
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
      ),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [scheme.primary, const Color(0xFF1B5E20)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
        ),
        child: Center(
          child: Text(initial,
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _recenter() {
    return Material(
      elevation: 5,
      shape: const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (_fix != null) _map.move(_fix!.pos, 16.5);
        },
        child: const SizedBox(
          width: 54,
          height: 54,
          child: Icon(Icons.my_location_rounded, color: _offlineNav, size: 27),
        ),
      ),
    );
  }

  // ---------------- Tortiluvchi panel ----------------

  void _toggleSheet() {
    final size = _sheet.isAttached ? _sheet.size : 0.30;
    _sheet.animateTo(
      size > 0.20 ? 0.10 : 0.30,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }

  Widget _bottomSheet(bool online) {
    final scheme = Theme.of(context).colorScheme;
    final showSlider = !online || _showOfflineSlider;
    return DraggableScrollableSheet(
      controller: _sheet,
      initialChildSize: 0.30,
      minChildSize: 0.10,
      maxChildSize: 0.55,
      snap: true,
      snapSizes: const [0.10, 0.30, 0.55],
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.surface, scheme.surfaceContainerLow],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18)],
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              // Tortuvchi/bosiluvchi grabber
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggleSheet,
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _walletCard(online)),
                  const SizedBox(width: 12),
                  Expanded(child: _todayCard()),
                ],
              ),
              if (showSlider) ...[
                const SizedBox(height: 16),
                SlideToConfirm(
                  key: ValueKey('slider_$online'),
                  reverse: online,
                  glow: !online,
                  label: online ? 'Ishni yakunlash' : 'Liniyaga chiqish',
                  icon: online
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
                  fillColor: online ? const Color(0xFFC62828) : _gold,
                  onConfirmed: () => _setOnline(!online),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _walletCard(bool online) {
    final balance = ref.watch(driverProfileProvider).valueOrNull?.balance ?? 0;
    return _PremiumCard(
      icon: Icons.account_balance_wallet_rounded,
      color: const Color(0xFF2E7D32),
      title: 'Hisobim',
      value: '${groupThousands(balance)} so‘m',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const BalanceScreen()),
      ),
    );
  }

  Widget _todayCard() {
    final todayCount =
        ref.watch(earningsProvider).valueOrNull?.total.todayCount ?? 0;
    return _PremiumCard(
      icon: Icons.insights_rounded,
      color: const Color(0xFF1565C0),
      title: 'Bugun',
      value: '$todayCount ta zakaz',
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TodayScreen()),
      ),
    );
  }
}

// ================= Premium karta =================

class _PremiumCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String value;
  final VoidCallback onTap;
  const _PremiumCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.14), color.withValues(alpha: 0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 12.5,
                            color: color,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value,
                          maxLines: 1,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= Status oy (online/offline) =================

class _StatusMoon extends StatelessWidget {
  final bool online;
  final VoidCallback onTap;
  const _StatusMoon({required this.online, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (online)
              BoxShadow(color: _gold.withValues(alpha: 0.65), blurRadius: 20, spreadRadius: 2),
            const BoxShadow(color: Colors.black38, blurRadius: 6),
          ],
        ),
        child: ClipOval(
          child: CustomPaint(
            size: const Size.square(62),
            painter: _MoonPainter(online),
          ),
        ),
      ),
    );
  }
}

/// Oy yuzasi — kraterlar + yorug'lik aksi. Online=tillo (porlaydi), offline=kulrang.
class _MoonPainter extends CustomPainter {
  final bool online;
  _MoonPainter(this.online);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    final base = online ? const Color(0xFFD4AF37) : const Color(0xFF9AA3A8);
    final light = online ? const Color(0xFFF4D469) : const Color(0xFFBCC3C7);
    final dark = online ? const Color(0xFFA8842A) : const Color(0xFF7E888E);

    // Asos — radial gradient (yuqori-chapdan yorug')
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );

    // Kraterlar
    final crater = Paint()..color = dark.withValues(alpha: 0.65);
    final craters = <(Offset, double)>[
      (Offset(r * 0.75, r * 0.7), r * 0.2),
      (Offset(r * 1.4, r * 0.95), r * 0.14),
      (Offset(r * 0.95, r * 1.45), r * 0.17),
      (Offset(r * 1.5, r * 1.45), r * 0.1),
      (Offset(r * 1.25, r * 0.5), r * 0.08),
    ];
    for (final (o, rad) in craters) {
      canvas.drawCircle(o, rad, crater);
      canvas.drawCircle(
        o.translate(-rad * 0.25, -rad * 0.25),
        rad * 0.7,
        Paint()..color = light.withValues(alpha: 0.25),
      );
    }

    // Yorug'lik aksi (glossy highlight)
    canvas.drawCircle(
      Offset(r * 0.6, r * 0.55),
      r * 0.35,
      Paint()..color = Colors.white.withValues(alpha: online ? 0.28 : 0.18),
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.online != online;
}

// ================= Navigator belgisi =================

class _NavPainter extends CustomPainter {
  final Color color;
  final bool glow;
  _NavPainter(this.color, this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cx = w / 2;

    // Yumshoq nur (glow)
    if (glow) {
      canvas.drawCircle(
        Offset(cx, h * 0.55),
        w * 0.4,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    // Strelka (uchli navigator)
    final path = ui.Path()
      ..moveTo(cx, h * 0.12)
      ..lineTo(w * 0.82, h * 0.82)
      ..lineTo(cx, h * 0.66)
      ..lineTo(w * 0.18, h * 0.82)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.05
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(_NavPainter old) => old.color != color || old.glow != glow;
}

// ================= Tezlik =================

class _SpeedBadge extends StatelessWidget {
  final double speedKmh;
  const _SpeedBadge(this.speedKmh);

  @override
  Widget build(BuildContext context) {
    final over = speedKmh > 70;
    final color = over ? const Color(0xFFD32F2F) : _offlineNav;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
            color: over ? const Color(0xFFD32F2F) : Colors.transparent, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${speedKmh.round()}',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900, color: color, height: 1)),
          Text('km/s', style: TextStyle(fontSize: 8, color: color)),
        ],
      ),
    );
  }
}

