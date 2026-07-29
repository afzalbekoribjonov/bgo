import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// GPS joylashuv xizmati (geolocator). plan/12-maps-navigation.md
class LocationService {
  /// Beshariq markazi — GPS yo'q/ruxsat berilmaganda zaxira nuqta.
  static const LatLng beshariqCenter = LatLng(40.4236, 70.6094);

  /// Joylashuv ruxsatini so'raydi (kirishdagi "majburiy GPS" uchun).
  /// Xizmat o'chiq bo'lsa sozlamalarni ochishga undaydi. true = ruxsat bor.
  Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      return perm == LocationPermission.always ||
          perm == LocationPermission.whileInUse;
    } catch (_) {
      return false;
    }
  }

  /// Joriy joylashuv (LatLng). Ruxsat/GPS bo'lmasa null.
  Future<LatLng?> currentLatLng() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}

final locationServiceProvider =
    Provider<LocationService>((ref) => LocationService());
