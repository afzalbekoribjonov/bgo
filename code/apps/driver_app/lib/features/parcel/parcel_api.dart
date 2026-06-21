import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'parcel_models.dart';

/// Kuryer dostavka API'si — gateway orqali. driverId token (JWT) dan olinadi.
/// plan/06-driver-app.md
class ParcelApi {
  final Dio _dio;
  ParcelApi(this._dio);

  Future<List<ParcelDelivery>> available() async {
    final res = await _dio.get('/parcel/driver/available');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => ParcelDelivery.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParcelDelivery>> myDeliveries() async {
    final res = await _dio.get('/parcel/driver/my-deliveries');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => ParcelDelivery.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> accept(String id) => _action(id, 'accept');
  Future<void> pickup(String id) => _action(id, 'pickup');
  Future<void> delivered(String id) => _action(id, 'delivered');

  Future<void> _action(String id, String action) async {
    await _dio.post('/parcel/driver/deliveries/$id/$action');
  }
}

final parcelApiProvider =
    Provider<ParcelApi>((ref) => ParcelApi(ref.read(dioProvider)));

final availableParcelsProvider = FutureProvider<List<ParcelDelivery>>((ref) {
  ref.watch(localeProvider);
  return ref.read(parcelApiProvider).available();
});

final myParcelDeliveriesProvider = FutureProvider<List<ParcelDelivery>>((ref) {
  ref.watch(localeProvider);
  return ref.read(parcelApiProvider).myDeliveries();
});
