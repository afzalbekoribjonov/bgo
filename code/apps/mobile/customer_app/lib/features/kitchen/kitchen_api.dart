import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'kitchen_models.dart';

/// Native "Mening oshxonam" paneli — `kitchenDioProvider` orqali ishlaydi
/// (alohida, 'restaurant' rolli JWT — mijozning o'z tokeni emas).
/// `restaurant_web/src/lib/api.ts`ning to'g'ridan-to'g'ri Dart nusxasi.
class KitchenApi {
  final Dio _dio;
  KitchenApi(this._dio);

  /// Oshxona profili — ochiq (public) endpoint, `restaurantId` `myKitchen()`
  /// orqali allaqachon ma'lum (`/restaurants/mine` BU YERDA ISHLAMAYDI —
  /// u `user.sub`ni ownerUserId deb hisoblaydi, kitchen-token'ning `sub`i esa
  /// `'kitchen:<id>'` — real userId emas).
  Future<KitchenRestaurant> restaurant(String id) async {
    final res = await _dio.get('/restaurants/$id');
    return KitchenRestaurant.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  // ---- Buyurtmalar ----

  Future<List<KitchenOrder>> orders(String restaurantId) async {
    final res = await _dio.get('/kitchen/restaurants/$restaurantId/orders');
    return ((res.data['data'] as List?) ?? const [])
        .map((e) => KitchenOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<KitchenOrder>> history(String restaurantId) async {
    final res = await _dio.get('/kitchen/restaurants/$restaurantId/orders/history');
    return ((res.data['data'] as List?) ?? const [])
        .map((e) => KitchenOrder.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KitchenStats> stats(String restaurantId) async {
    final res = await _dio.get('/kitchen/restaurants/$restaurantId/stats');
    return KitchenStats.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  /// action: accept | preparing | ready | reject
  Future<KitchenOrder> orderAction(String orderId, String action) async {
    final res = await _dio.post('/kitchen/orders/$orderId/$action');
    return KitchenOrder.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<List<KitchenOrderMessage>> orderMessages(String orderId) async {
    final res = await _dio.get('/kitchen/orders/$orderId/messages');
    return ((res.data['data'] as List?) ?? const [])
        .map((e) => KitchenOrderMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KitchenOrderMessage> sendOrderMessage(String orderId, String text) async {
    final res = await _dio.post('/kitchen/orders/$orderId/messages', data: {'text': text});
    return KitchenOrderMessage.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  // ---- Holat / profil ----

  Future<KitchenRestaurant> setOpen(String restaurantId, bool isOpen) async {
    final res = await _dio.patch('/restaurants/$restaurantId/open', data: {'isOpen': isOpen});
    return KitchenRestaurant.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<KitchenRestaurant> updateLogo(String restaurantId, String logoUrl) async {
    final res = await _dio.patch('/restaurants/$restaurantId/logo', data: {'logoUrl': logoUrl});
    return KitchenRestaurant.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  // ---- Menyu: kategoriyalar ----

  Future<List<KitchenCategory>> categories(String restaurantId) async {
    final res = await _dio.get('/restaurants/$restaurantId/categories');
    return ((res.data['data'] as List?) ?? const [])
        .map((e) => KitchenCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KitchenCategory> createCategory(String restaurantId, I18nText name, {int? sortOrder}) async {
    final res = await _dio.post('/restaurants/$restaurantId/categories', data: {
      'name': name.toJson(),
      if (sortOrder != null) 'sortOrder': sortOrder,
    });
    return KitchenCategory.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<KitchenCategory> updateCategory(String restaurantId, String id, {I18nText? name, int? sortOrder}) async {
    final res = await _dio.patch('/restaurants/$restaurantId/categories/$id', data: {
      if (name != null) 'name': name.toJson(),
      if (sortOrder != null) 'sortOrder': sortOrder,
    });
    return KitchenCategory.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<void> deleteCategory(String restaurantId, String id) async {
    await _dio.delete('/restaurants/$restaurantId/categories/$id');
  }

  // ---- Menyu: mahsulotlar ----

  Future<List<KitchenMenuItem>> menuItems(String restaurantId) async {
    final res = await _dio.get('/restaurants/$restaurantId/menu-items');
    return ((res.data['data'] as List?) ?? const [])
        .map((e) => KitchenMenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<KitchenMenuItem> createMenuItem(
    String restaurantId, {
    required String categoryId,
    required I18nText name,
    I18nText? description,
    required int price,
    String? imageUrl,
  }) async {
    final res = await _dio.post('/restaurants/$restaurantId/menu-items', data: {
      'categoryId': categoryId,
      'name': name.toJson(),
      if (description != null) 'description': description.toJson(),
      'price': price,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return KitchenMenuItem.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<KitchenMenuItem> updateMenuItem(
    String restaurantId,
    String id, {
    String? categoryId,
    I18nText? name,
    I18nText? description,
    int? price,
    String? imageUrl,
  }) async {
    final res = await _dio.patch('/restaurants/$restaurantId/menu-items/$id', data: {
      if (categoryId != null) 'categoryId': categoryId,
      if (name != null) 'name': name.toJson(),
      if (description != null) 'description': description.toJson(),
      if (price != null) 'price': price,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return KitchenMenuItem.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<KitchenMenuItem> setAvailability(String restaurantId, String id, bool isAvailable) async {
    final res = await _dio.patch(
      '/restaurants/$restaurantId/menu-items/$id/availability',
      data: {'isAvailable': isAvailable},
    );
    return KitchenMenuItem.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<void> deleteMenuItem(String restaurantId, String id) async {
    await _dio.delete('/restaurants/$restaurantId/menu-items/$id');
  }

  /// Taom/logotip rasmini yuklaydi, tayyor URL qaytaradi.
  Future<String> uploadImage(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final res = await _dio.post('/restaurants/upload', data: form);
    return (res.data['data'] as Map)['url'] as String;
  }
}

final kitchenApiProvider = Provider<KitchenApi>((ref) => KitchenApi(ref.read(kitchenDioProvider)));
