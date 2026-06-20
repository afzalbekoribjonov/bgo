import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'delivery_models.dart';

/// Kuryer (courier) API'si — gateway orqali. driverId token (JWT) dan olinadi.
/// plan/06-driver-app.md
class DeliveryApi {
  final Dio _dio;
  DeliveryApi(this._dio);

  Future<List<DeliveryOrder>> available() async {
    final res = await _dio.get('/courier/available');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<DeliveryOrder>> myOrders() async {
    final res = await _dio.get('/courier/my-orders');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DriverEarnings> earnings() async {
    final res = await _dio.get('/courier/earnings');
    return DriverEarnings.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> accept(String orderId) => _action(orderId, 'accept');
  Future<void> pickup(String orderId) => _action(orderId, 'pickup');
  Future<void> delivered(String orderId) => _action(orderId, 'delivered');

  Future<void> _action(String orderId, String action) async {
    await _dio.post('/courier/orders/$orderId/$action');
  }
}

final deliveryApiProvider =
    Provider<DeliveryApi>((ref) => DeliveryApi(ref.read(dioProvider)));

/// Haydovchi onlayn holati (lokal).
final onlineProvider = StateProvider<bool>((ref) => false);

final availableOrdersProvider = FutureProvider<List<DeliveryOrder>>((ref) {
  ref.watch(localeProvider);
  return ref.read(deliveryApiProvider).available();
});

final myDeliveriesProvider = FutureProvider<List<DeliveryOrder>>((ref) {
  ref.watch(localeProvider);
  return ref.read(deliveryApiProvider).myOrders();
});

final earningsProvider = FutureProvider<DriverEarnings>((ref) {
  ref.watch(localeProvider);
  return ref.read(deliveryApiProvider).earnings();
});
