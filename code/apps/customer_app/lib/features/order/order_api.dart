import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../cart/cart_controller.dart';
import 'order_models.dart';

/// Buyurtma API'si (gateway orqali, Bearer token). plan/14-api-design.md
class OrderApi {
  final Dio _dio;
  OrderApi(this._dio);

  Future<OrderView> createFoodOrder({
    required String restaurantId,
    required List<CartLine> lines,
    required String addressText,
  }) async {
    final res = await _dio.post('/orders', data: {
      'type': 'FOOD',
      'restaurantId': restaurantId,
      'paymentType': 'CASH',
      'address': {'text': addressText},
      'items': [
        for (final l in lines) {'menuItemId': l.menuItemId, 'qty': l.qty},
      ],
    });
    return OrderView.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<OrderView>> listOrders() async {
    final res = await _dio.get('/orders');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => OrderView.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderView> getOrder(String id) async {
    final res = await _dio.get('/orders/$id');
    return OrderView.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<OrderView> cancelOrder(String id) async {
    final res = await _dio.post('/orders/$id/cancel');
    return OrderView.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

final orderApiProvider =
    Provider<OrderApi>((ref) => OrderApi(ref.read(dioProvider)));

final myOrdersProvider = FutureProvider<List<OrderView>>((ref) {
  ref.watch(localeProvider);
  return ref.read(orderApiProvider).listOrders();
});

final orderProvider = FutureProvider.family<OrderView, String>((ref, id) {
  ref.watch(localeProvider);
  return ref.read(orderApiProvider).getOrder(id);
});
