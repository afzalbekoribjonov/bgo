import 'dart:async';
import 'dart:math' as math;

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

/// Haydovchi bosh ekrani — 80% xarita (navigator belgisi, jonli GPS) +
/// pastda Hisobim/Bugun + surib "Liniyaga chiqish". plan/06-driver-app.md
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final MapController _map = MapController();
  DriverFix? _fix;
  Timer? _gpsTimer;
  Timer? _pollTimer;
  int _lastAvailable = 0;
  bool _silenced = false;
  bool _showOfflineSlider = false; // online'da pastdan slide-to-offline ko'rsatish

  static const _offlineColor = Color(0xFF263238); // qoramtir navigator
  static const _gold = Color(0xFFD4AF37); // tillo

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
    final z = _map.camera.zoom;
    _map.move(fix.pos, z < 11 ? 16 : z);
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

    return Scaffold(
      body: Column(
        children: [
          Expanded(flex: 8, child: _mapArea(online)),
          _bottomPanel(online, available),
        ],
      ),
    );
  }

  // ---------------- Xarita ----------------

  Widget _mapArea(bool online) {
    final places = ref.watch(geoPlacesProvider).valueOrNull ?? const <GeoPlace>[];
    final roads = ref.watch(geoRoadsProvider).valueOrNull ?? const <GeoRoad>[];
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        FlutterMap(
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
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.beshariq.driver_app',
              maxZoom: 19,
            ),
            // Admin yo'llari — oq o'zak + sariq chet (navigator uslubi)
            if (roads.isNotEmpty)
              PolylineLayer(
                polylines: [
                  for (final r in roads)
                    Polyline(
                      points: r.points,
                      strokeWidth: r.kind == 'center'
                          ? 6
                          : r.kind == 'main'
                              ? 5
                              : 4,
                      color: const Color(0xFFFFFFFF),
                      borderStrokeWidth: 2,
                      borderColor: const Color(0xFFE9B824),
                    ),
                ],
              ),
            // Admin belgilagan joylar
            if (places.isNotEmpty)
              MarkerLayer(markers: [for (final p in places) _placeMarker(p)]),
            if (_fix != null)
              MarkerLayer(markers: [_driverMarker(_fix!, online)]),
          ],
        ),
        Positioned(top: top + 10, left: 14, child: _OnlineIndicator(
          online: online,
          onTap: () {
            if (online) setState(() => _showOfflineSlider = true);
          },
        )),
        Positioned(top: top + 78, left: 14, child: _SpeedIndicator(_fix?.speedKmh ?? 0)),
        Positioned(top: top + 10, right: 14, child: _avatarButton()),
        Positioned(bottom: 16, right: 16, child: _recenterButton()),
      ],
    );
  }

  Marker _driverMarker(DriverFix fix, bool online) {
    final color = online ? _gold : _offlineColor;
    return Marker(
      point: fix.pos,
      width: 46,
      height: 46,
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: fix.heading * math.pi / 180,
        child: Icon(
          Icons.navigation,
          color: color,
          size: 40,
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 6),
            Shadow(color: Colors.black54, blurRadius: 3),
          ],
        ),
      ),
    );
  }

  Marker _placeMarker(GeoPlace p) {
    return Marker(
      point: LatLng(p.lat, p.lng),
      width: 120,
      height: 40,
      alignment: Alignment.center,
      child: IgnorePointer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.place, size: 16, color: Color(0xFF5D4037)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                p.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF37474F)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarButton() {
    final initial = ref.watch(driverProfileProvider).valueOrNull?.initial ?? '?';
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: scheme.primary,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DriverProfileScreen()),
        ),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Center(
            child: Text(initial,
                style: const TextStyle(
                    color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800)),
          ),
        ),
      ),
    );
  }

  Widget _recenterButton() {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {
          if (_fix != null) _map.move(_fix!.pos, 16);
        },
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.my_location, color: Color(0xFF263238), size: 26),
        ),
      ),
    );
  }

  // ---------------- Pastki panel ----------------

  Widget _bottomPanel(bool online, int available) {
    final scheme = Theme.of(context).colorScheme;
    final profile = ref.watch(driverProfileProvider).valueOrNull;
    final todayCount =
        ref.watch(earningsProvider).valueOrNull?.total.todayCount ?? 0;
    final balance = profile?.balance ?? 0;

    final showSlider = !online || _showOfflineSlider;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 14)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hisobim + Bugun
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _statCard(
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF2E7D32),
                    title: 'Hisobim',
                    value: '${groupThousands(balance)} so‘m',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BalanceScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                    icon: Icons.bar_chart_rounded,
                    color: const Color(0xFF1E88E5),
                    title: 'Bugun',
                    value: '$todayCount ta zakaz',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const TodayScreen()),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Holat + slider
          if (showSlider)
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width * 0.05),
              child: SlideToConfirm(
                key: ValueKey('slider_$online'),
                reverse: online, // online -> o'ngdan chapga (yakunlash)
                glow: !online, // liniyaga chiqish surgichi tillo porlaydi
                label: online
                    ? 'Ishni yakunlash uchun suring'
                    : 'Liniyaga chiqish uchun suring',
                icon: online ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                fillColor: online ? const Color(0xFFC62828) : _gold,
                onConfirmed: () => _setOnline(!online),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: _gold, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    available > 0 ? '$available ta yangi buyurtma!' : 'Liniyadasiz — buyurtma kutilmoqda',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.09),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- Online/offline indikator ----------------

class _OnlineIndicator extends StatelessWidget {
  final bool online;
  final VoidCallback onTap;
  const _OnlineIndicator({required this.online, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
        ),
        child: online
            ? Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFFE9C84B), Color(0xFFD4AF37)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Text('online',
                      style: TextStyle(
                          color: Color(0xFF3E2C00),
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                ),
              )
            : ClipOval(child: CustomPaint(painter: _MoonPainter())),
      ),
    );
  }
}

/// Offline — kulrang "oy dog'lari" naqsh.
class _MoonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF9AA3A8));
    final spot = Paint()..color = const Color(0xFF7E888E);
    final craters = <(Offset, double)>[
      (Offset(r * 0.7, r * 0.6), r * 0.22),
      (Offset(r * 1.35, r * 0.9), r * 0.16),
      (Offset(r * 0.9, r * 1.4), r * 0.2),
      (Offset(r * 1.45, r * 1.45), r * 0.12),
      (Offset(r * 1.2, r * 0.45), r * 0.1),
    ];
    for (final (o, rad) in craters) {
      canvas.drawCircle(o, rad, spot);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ---------------- Tezlik indikatori ----------------

class _SpeedIndicator extends StatelessWidget {
  final double speedKmh;
  const _SpeedIndicator(this.speedKmh);

  @override
  Widget build(BuildContext context) {
    final over = speedKmh > 70;
    final color = over ? const Color(0xFFD32F2F) : const Color(0xFF263238);
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: over ? const Color(0xFFD32F2F) : Colors.transparent, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${speedKmh.round()}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color, height: 1),
          ),
          Text('km/s', style: TextStyle(fontSize: 8, color: color)),
        ],
      ),
    );
  }
}
