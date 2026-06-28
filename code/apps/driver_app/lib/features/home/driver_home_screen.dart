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
import '../orders/offer_api.dart';
import '../orders/pool_screen.dart';
import '../profile/driver_profile_screen.dart';
import '../stats/today_screen.dart';
import 'balance_screen.dart';

const _gold = Color(0xFFD4AF37);
const _offlineNav = Color(0xFF263238);

/// Haydovchi bosh ekrani — xarita + navigator + tortiluvchi panel +
/// yangi buyurtma (taklif) oqimi. plan/06-driver-app.md
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final MapController _map = MapController();
  bool _panelHidden = false; // xarita bosilganda panel pastga yashirinadi
  DriverFix? _fix;
  double _zoom = 16;
  Timer? _gpsTimer;
  Timer? _offerTimer;
  Timer? _tick;
  bool _showOfflineSlider = false;

  // Buyurtma taklifi
  DriverOffer? _offer;
  int _offerLeft = 0;
  List<LatLng> _route = const [];
  bool _showNotTaken = false;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _initOnline();
    _refreshGps();
    _gpsTimer = Timer.periodic(const Duration(seconds: 3), (_) => _refreshGps());
    _offerTimer =
        Timer.periodic(const Duration(seconds: 2), (_) => _pollOffer());
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_offer != null && mounted) {
        setState(() => _offerLeft = (_offerLeft - 1).clamp(0, 60));
      }
    });
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _offerTimer?.cancel();
    _tick?.cancel();
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
    _map.move(fix.pos, _zoom < 11 ? 16 : _zoom);
  }

  // ---------------- Taklif oqimi ----------------

  Future<void> _pollOffer() async {
    if (!mounted || !ref.read(onlineProvider) || _accepting) return;
    try {
      final offer = await ref.read(offerApiProvider).current();
      if (!mounted) return;
      if (offer != null) {
        final isNew = _offer?.orderId != offer.orderId;
        setState(() {
          _offer = offer;
          _offerLeft = offer.secondsLeft;
        });
        if (isNew) {
          _alertOn();
          _loadRoute(offer);
        }
      } else if (_offer != null) {
        // Taklif yo'qoldi (qabul qilinmadi / boshqaga o'tdi)
        _clearOffer(notTaken: true);
      }
      ref.invalidate(poolProvider);
    } catch (_) {/* tarmoq — jim */}
  }

  void _alertOn() {
    if (ref.read(soundEnabledProvider)) ref.read(alertSoundProvider).start();
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 400), HapticFeedback.heavyImpact);
  }

  Future<void> _loadRoute(DriverOffer offer) async {
    final me = _fix?.pos;
    if (me == null) return;
    final dir =
        await ref.read(driverRoutingServiceProvider).directions(me, offer.pickup);
    if (!mounted || _offer?.orderId != offer.orderId) return;
    setState(() => _route = dir?.points ?? [me, offer.pickup]);
  }

  void _clearOffer({bool notTaken = false}) {
    ref.read(alertSoundProvider).stop();
    setState(() {
      _offer = null;
      _route = const [];
      _offerLeft = 0;
    });
    if (notTaken) {
      setState(() => _showNotTaken = true);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _showNotTaken = false);
      });
    }
  }

  Future<void> _skipOffer() async {
    final o = _offer;
    if (o == null) return;
    _clearOffer();
    try {
      await ref.read(offerApiProvider).skip(o.orderId);
    } catch (_) {}
  }

  Future<void> _acceptOffer() async {
    final o = _offer;
    if (o == null || _accepting) return;
    setState(() => _accepting = true);
    ref.read(alertSoundProvider).stop();
    try {
      await ref.read(offerApiProvider).accept(o.orderId);
      if (!mounted) return;
      setState(() {
        _offer = null;
        _route = const [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buyurtma qabul qilindi')),
      );
      // Keyingi bosqich (yo'l/yetkazish) — alohida.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNetworkError(e) ? 'Tarmoq xatosi' : 'Buyurtma endi mavjud emas')),
        );
        _clearOffer();
      }
    } finally {
      if (mounted) setState(() => _accepting = false);
    }
  }

  // ---------------- Online ----------------

  Future<void> _setOnline(bool value) async {
    ref.read(onlineProvider.notifier).state = value;
    _showOfflineSlider = false;
    if (!value) {
      ref.read(alertSoundProvider).stop();
      _clearOffer();
    }
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
    if (online && _offer == null) {
      setState(() {
        _showOfflineSlider = true;
        _panelHidden = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final online = ref.watch(onlineProvider);
    final top = MediaQuery.of(context).padding.top;
    final hasOffer = _offer != null;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: _mapWidget(online)),
          // Indikatorlar
          Positioned(
            top: top + (hasOffer ? 74 : 10),
            left: 16,
            child: _StatusMoon(online: online, onTap: () => _onMoonTap(online)),
          ),
          Positioned(
            top: top + (hasOffer ? 142 : 84),
            left: 18,
            child: _SpeedBadge(_fix?.speedKmh ?? 0),
          ),
          Positioned(top: top + 10, right: 16, child: _avatar()),
          Positioned(top: top + 72, right: 20, child: _poolBadge()),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
            right: 18,
            bottom: hasOffer ? 200 : (_panelHidden ? 26 : 208),
            child: _recenter(),
          ),
          // Yangi buyurtma banneri (yuqorida)
          if (hasOffer)
            Positioned(top: 0, left: 0, right: 0, child: _orderBanner(top)),
          // Pastki panel yoki qabul paneli
          if (hasOffer) _acceptPanel() else _bottomPanel(online),
          // Panel yashiringanda — tortib chiqarish uchun kichik tutqich
          if (!hasOffer && _panelHidden)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: GestureDetector(
                onTap: () => setState(() => _panelHidden = false),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 26,
                  alignment: Alignment.center,
                  child: Container(
                    width: 56, height: 6,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
          // "Buyurtma olinmadi"
          if (_showNotTaken) _notTakenOverlay(),
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
        onTap: (_, __) {
          if (_offer == null) setState(() => _panelHidden = !_panelHidden);
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.beshariq.driver_app',
          maxZoom: 19,
        ),
        if (roads.isNotEmpty && _zoom >= 13 && _offer == null)
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
        // Yangi buyurtma marshruti (yashil)
        if (_route.length >= 2)
          PolylineLayer(polylines: [
            Polyline(
              points: _route,
              strokeWidth: 6,
              color: const Color(0xFF2E7D32),
              borderStrokeWidth: 2,
              borderColor: Colors.white,
            ),
          ]),
        if (places.isNotEmpty && _zoom >= 14 && _offer == null)
          MarkerLayer(markers: [for (final p in places) _placeMarker(p)]),
        // Olib ketish nuqtasi — bayroq
        if (_offer != null)
          MarkerLayer(markers: [
            Marker(
              point: _offer!.pickup,
              width: 40,
              height: 44,
              alignment: Alignment.topCenter,
              child: const Icon(Icons.flag_rounded, color: Color(0xFF2E7D32), size: 38, shadows: [Shadow(color: Colors.black45, blurRadius: 4)]),
            ),
          ]),
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
                      fontSize: 8.5, fontWeight: FontWeight.w600, color: Color(0xFF455A64))),
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
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _poolBadge() {
    final count = ref.watch(poolProvider).valueOrNull?.length ?? 0;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PoolScreen()),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5)],
            ),
            child: const Icon(Icons.list_alt_rounded, color: _offlineNav, size: 24),
          ),
          if (count > 0)
            Positioned(
              top: -4,
              right: -4,
              child: Container(
                padding: const EdgeInsets.all(5),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
                child: Text('$count',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
        ],
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
          width: 54, height: 54,
          child: Icon(Icons.my_location_rounded, color: _offlineNav, size: 27),
        ),
      ),
    );
  }

  // ---------------- Yangi buyurtma banneri ----------------

  Widget _orderBanner(double topPad) {
    final progress = (_offerLeft / 20).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: _skipOffer,
      child: Container(
        height: topPad + 60,
        color: const Color(0xFFC62828), // qizil asos
        child: Stack(
          children: [
            // Yashil — o'ngdan kamayadi (vaqt o'tishi bilan)
            FractionallySizedBox(
              widthFactor: progress,
              alignment: Alignment.centerLeft,
              child: Container(color: const Color(0xFF2E7D32)),
            ),
            Padding(
              padding: EdgeInsets.only(top: topPad + 8, left: 18, right: 18),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Yangi buyurtma',
                            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
                        Text("O'tkazib yuborish uchun bosing",
                            style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                      ],
                    ),
                  ),
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('$_offerLeft',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Qabul paneli ----------------

  Widget _acceptPanel() {
    final o = _offer!;
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(child: _infoChip(Icons.route_rounded, 'Masofa', '${o.distanceKm.toStringAsFixed(1)} km', const Color(0xFF1565C0))),
                const SizedBox(width: 12),
                Expanded(child: _infoChip(Icons.payments_rounded, 'Narx', groupThousands(o.amount), const Color(0xFF2E7D32))),
              ],
            ),
            const SizedBox(height: 6),
            Text('${o.pickupName} · ulush +${groupThousands(o.earning)} so‘m',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.outline, fontSize: 12.5)),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _accepting ? null : _acceptOffer,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: const Color(0xFF2E7D32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              child: _accepting
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Buyurtmani olish'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _notTakenOverlay() {
    return IgnorePointer(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text('Buyurtma olinmadi',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- Pastki panel (taklif yo'q payti) ----------------

  /// Pastki panel — kontent o'lchamida (bo'sh joy yo'q). Xarita bosilsa
  /// pastga yashirinadi (AnimatedSlide).
  Widget _bottomPanel(bool online) {
    final scheme = Theme.of(context).colorScheme;
    final showSlider = !online || _showOfflineSlider;
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
        offset: _panelHidden ? const Offset(0, 1) : Offset.zero,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, 16 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.surface, scheme.surfaceContainerLow],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 18)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _panelHidden = true),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    width: 46, height: 5,
                    decoration: BoxDecoration(
                      color: scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _walletCard()),
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
                  icon: online ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded,
                  fillColor: online ? const Color(0xFFC62828) : _gold,
                  onConfirmed: () => _setOnline(!online),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletCard() {
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
    final todayCount = ref.watch(earningsProvider).valueOrNull?.total.todayCount ?? 0;
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
              BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8)],
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(value, maxLines: 1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
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

// ================= Status oy =================

class _StatusMoon extends StatelessWidget {
  final bool online;
  final VoidCallback onTap;
  const _StatusMoon({required this.online, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 62, height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            if (online) BoxShadow(color: _gold.withValues(alpha: 0.65), blurRadius: 20, spreadRadius: 2),
            const BoxShadow(color: Colors.black38, blurRadius: 6),
          ],
        ),
        child: ClipOval(
          child: CustomPaint(size: const Size.square(62), painter: _MoonPainter(online)),
        ),
      ),
    );
  }
}

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
    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawCircle(
      c, r,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.4, -0.5),
          colors: [light, base, dark],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(rect),
    );
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
      canvas.drawCircle(o.translate(-rad * 0.25, -rad * 0.25), rad * 0.7,
          Paint()..color = light.withValues(alpha: 0.25));
    }
    canvas.drawCircle(Offset(r * 0.6, r * 0.55), r * 0.35,
        Paint()..color = Colors.white.withValues(alpha: online ? 0.28 : 0.18));
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
    if (glow) {
      canvas.drawCircle(
        Offset(cx, h * 0.55), w * 0.4,
        Paint()
          ..color = color.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
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
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: over ? const Color(0xFFD32F2F) : Colors.transparent, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${speedKmh.round()}',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color, height: 1)),
          Text('km/s', style: TextStyle(fontSize: 8, color: color)),
        ],
      ),
    );
  }
}
