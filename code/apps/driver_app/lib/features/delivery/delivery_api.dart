import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'delivery_models.dart';

/// Kuryer (courier) API'si — gateway orqali. plan/06-driver-app.md
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

  Future<List<DeliveryOrder>> myOrders(String driverId) async {
    final res = await _dio.get('/courier/drivers/$driverId/orders');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => DeliveryOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> accept(String orderId, String driverId) =>
      _action(orderId, 'accept', driverId);
  Future<void> pickup(String orderId, String driverId) =>
      _action(orderId, 'pickup', driverId);
  Future<void> delivered(String orderId, String driverId) =>
      _action(orderId, 'delivered', driverId);

  Future<void> _action(String orderId, String action, String driverId) async {
    await _dio.post('/courier/orders/$orderId/$action',
        data: {'driverId': driverId});
  }
}

final deliveryApiProvider =
    Provider<DeliveryApi>((ref) => DeliveryApi(ref.read(dioProvider)));

/// Haydovchi onlayn holati (lokal).
final onlineProvider = StateProvider<bool>((ref) => false);

final availableOrdersProvider =
    FutureProvider<List<DeliveryOrder>>((ref) {
  ref.watch(localeProvider);
  return ref.read(deliveryApiProvider).available();
});

final myDeliveriesProvider =
    FutureProvider.family<List<DeliveryOrder>, String>((ref, driverId) {
  ref.watch(localeProvider);
  return ref.read(deliveryApiProvider).myOrders(driverId);
});
