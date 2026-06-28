import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/alert_sound.dart';
import '../../core/nav_support.dart';
import '../../widgets/slide_to_confirm.dart';
import '../auth/auth_api.dart';
import '../delivery/delivery_api.dart';
import '../parcel/parcel_api.dart';
import '../profile/driver_profile_screen.dart';
import '../taxi/taxi_api.dart';

/// Haydovchi bosh ekrani — 70% xarita (jonli GPS, navigator belgisi) +
/// 30% "Liniyaga chiqish" surish tugmasi. plan/06-driver-app.md
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  final MapController _map = MapController();
  LatLng? _me;
  Timer? _gpsTimer;
  Timer? _pollTimer;
  int _lastAvailable = 0;
  bool _silenced = false;

  static const _offlineColor = Color(0xFF37474F); // qoramtir (oq-qora uyg'un)
  static const _onlineColor = Color(0xFFD4AF37); // tillo

  @override
  void initState() {
    super.initState();
    _initOnline();
    _refreshGps();
    _gpsTimer = Timer.periodic(const Duration(seconds: 4), (_) => _refreshGps());
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
    final me = await driverCurrentLatLng();
    if (!mounted || me == null) return;
    setState(() => _me = me);
    _map.move(me, _map.camera.zoom == 0 ? 16 : _map.camera.zoom);
  }

  Future<void> _setOnline(bool value) async {
    ref.read(onlineProvider.notifier).state = value;
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
          Expanded(flex: 7, child: _mapArea(online)),
          Expanded(flex: 3, child: _bottomPanel(online, available)),
        ],
      ),
    );
  }

  Widget _mapArea(bool online) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _map,
          options: MapOptions(
            initialCenter: _me ?? beshariqCenter,
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
            if (_me != null)
              MarkerLayer(markers: [_driverMarker(_me!, online)]),
          ],
        ),
        // Profil avatari (o'ng-yuqori)
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 14,
          child: _avatarButton(),
        ),
        // Joriy joyga qaytarish
        Positioned(
          bottom: 14,
          right: 14,
          child: FloatingActionButton.small(
            heroTag: 'homeRecenter',
            backgroundColor: Colors.white,
            foregroundColor: _offlineColor,
            onPressed: () {
              if (_me != null) _map.move(_me!, 16);
            },
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Marker _driverMarker(LatLng p, bool online) {
    final color = online ? _onlineColor : _offlineColor;
    return Marker(
      point: p,
      width: 54,
      height: 54,
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1),
            const BoxShadow(color: Colors.black26, blurRadius: 4),
          ],
        ),
        padding: const EdgeInsets.all(7),
        child: Icon(Icons.navigation_rounded, color: color, size: 26),
      ),
    );
  }

  Widget _avatarButton() {
    final profile = ref.watch(driverProfileProvider);
    final initial = profile.valueOrNull?.initial ?? '?';
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
          width: 50,
          height: 50,
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomPanel(bool online, int available) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                online ? Icons.bolt : Icons.power_settings_new,
                color: online ? _onlineColor : scheme.outline,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                online
                    ? (available > 0
                        ? '$available ta yangi buyurtma!'
                        : 'Liniyadasiz — buyurtma kutilmoqda')
                    : 'Hozir oflaynsiz',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: online ? scheme.onSurface : scheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SlideToConfirm(
            key: ValueKey(online),
            label: online ? 'Ishni yakunlash uchun suring' : 'Liniyaga chiqish uchun suring',
            icon: online ? Icons.stop_rounded : Icons.arrow_forward_rounded,
            fillColor: online ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
            onConfirmed: () => _setOnline(!online),
          ),
        ],
      ),
    );
  }
}
