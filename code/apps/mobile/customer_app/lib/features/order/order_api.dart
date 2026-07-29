import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../cart/cart_controller.dart';
import '../taxi/taxi_models.dart' show DriverLoc;
import 'order_models.dart';

/// Ovqat narx-konfiguratsiyasi (ustama + yetkazish).
class FoodConfig {
  final int serviceThreshold;
  final int serviceFeeUnder;
  final int serviceFeeOver;
  final int deliveryFee;
  const FoodConfig({
    required this.serviceThreshold,
    required this.serviceFeeUnder,
    required this.serviceFeeOver,
    required this.deliveryFee,
  });

  /// Bitta taom narxiga qo'shiladigan xizmat haqi ustamasi.
  int markup(int price) =>
      price > serviceThreshold ? serviceFeeOver : serviceFeeUnder;

  factory FoodConfig.fromJson(Map<String, dynamic> j) => FoodConfig(
        serviceThreshold: (j['serviceThreshold'] as num?)?.toInt() ?? 19000,
        serviceFeeUnder: (j['serviceFeeUnder'] as num?)?.toInt() ?? 1000,
        serviceFeeOver: (j['serviceFeeOver'] as num?)?.toInt() ?? 1500,
        deliveryFee: (j['deliveryFee'] as num?)?.toInt() ?? 5000,
      );
}

/// Buyurtma API'si (gateway orqali, Bearer token). plan/14-api-design.md
class OrderApi {
  final Dio _dio;
  OrderApi(this._dio);

  Future<OrderView> createFoodOrder({
    required String restaurantId,
    required List<CartLine> lines,
    required String addressText,
    double? lat,
    double? lng,
    String? promoCode,
  }) async {
    final res = await _dio.post('/orders', data: {
      'type': 'FOOD',
      'restaurantId': restaurantId,
      'paymentType': 'CASH',
      'address': {
        'text': addressText,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      },
      'items': [
        for (final l in lines) {'menuItemId': l.menuItemId, 'qty': l.qty},
      ],
      if (promoCode != null && promoCode.isNotEmpty) 'promoCode': promoCode,
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

  /// Jonli buyurtma — oshxona joylashuvi + kuryer + kuryer joylashuvi.
  Future<OrderView> getOrderLive(String id) async {
    final res = await _dio.get('/orders/$id/live');
    return OrderView.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// Biriktirilgan kuryerning jonli joylashuvi (null bo'lishi mumkin).
  Future<DriverLoc?> driverLocation(String id) async {
    final res = await _dio.get('/orders/$id/driver');
    final data = res.data['data'];
    if (data == null) return null;
    return DriverLoc.fromJson(data as Map<String, dynamic>);
  }

  /// Yetkazilgan buyurtmani baholash (1-5).
  Future<void> rate(String id, int rating, {String? comment}) async {
    await _dio.post('/orders/$id/rate', data: {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }

  /// Ovqat narx-konfiguratsiyasi (ustama + yetkazish).
  Future<FoodConfig> foodConfig() async {
    final res = await _dio.get('/orders/food-config');
    return FoodConfig.fromJson(res.data['data'] as Map<String, dynamic>);
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

final foodConfigProvider = FutureProvider<FoodConfig>((ref) {
  return ref.read(orderApiProvider).foodConfig();
});
