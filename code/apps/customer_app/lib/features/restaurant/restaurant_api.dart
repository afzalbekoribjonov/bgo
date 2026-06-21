import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'restaurant_models.dart';

/// Restaurant katalog API'si (gateway orqali). plan/14-api-design.md
class RestaurantApi {
  final Dio _dio;
  RestaurantApi(this._dio);

  Future<List<RestaurantSummary>> listRestaurants() async {
    final res = await _dio.get('/restaurants');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => RestaurantSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<RestaurantMenu> getMenu(String restaurantId) async {
    final res = await _dio.get('/restaurants/$restaurantId/menu');
    return RestaurantMenu.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

final restaurantApiProvider =
    Provider<RestaurantApi>((ref) => RestaurantApi(ref.read(dioProvider)));

/// Oshxonalar ro'yxati. Til o'zgarsa qayta yuklanadi.
final restaurantsProvider = FutureProvider<List<RestaurantSummary>>((ref) {
  ref.watch(localeProvider);
  return ref.read(restaurantApiProvider).listRestaurants();
});

/// Oshxona menyusi (id bo'yicha). Til o'zgarsa qayta yuklanadi.
final menuProvider = FutureProvider.family<RestaurantMenu, String>((ref, id) {
  ref.watch(localeProvider);
  return ref.read(restaurantApiProvider).getMenu(id);
});
