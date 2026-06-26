import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:beshariq_core/beshariq_core.dart';

/// Haydovchi joylashuvini backendga yuboruvchi API.
/// Mijoz ilovasi shu joylashuvni jonli kuzatadi (taksi/dostavka).
class DriverLocationApi {
  final Dio _dio;
  DriverLocationApi(this._dio);

  Future<void> ping(double lat, double lng, {double? heading}) async {
    await _dio.post('/driver/location', data: {
      'lat': lat,
      'lng': lng,
      if (heading != null && heading >= 0) 'heading': heading,
    });
  }

  Future<void> offline() async {
    try {
      await _dio.delete('/driver/location');
    } catch (_) {/* best-effort */}
  }
}

final driverLocationApiProvider =
    Provider<DriverLocationApi>((ref) => DriverLocationApi(ref.read(dioProvider)));

/// Autentifikatsiyalangan haydovchi joylashuvini muntazam (~8s) yuboradi.
/// [child] atrofini o'raydi; ilova fonga o'tsa to'xtaydi, qaytsa davom etadi.
class LocationPinger extends ConsumerStatefulWidget {
  final Widget child;
  const LocationPinger({super.key, required this.child});

  @override
  ConsumerState<LocationPinger> createState() => _LocationPingerState();
}

class _LocationPingerState extends ConsumerState<LocationPinger>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _askedPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  Future<void> _ensurePermission() async {
    if (_askedPermission) return;
    _askedPermission = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {/* jim */}
  }

  void _start() {
    _ensurePermission();
    _timer?.cancel();
    _pingOnce();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _pingOnce());
  }

  Future<void> _pingOnce() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await ref
          .read(driverLocationApiProvider)
          .ping(pos.latitude, pos.longitude, heading: pos.heading);
    } catch (_) {/* tarmoq/GPS — jim o'tkazamiz */}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _start();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    ref.read(driverLocationApiProvider).offline();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
