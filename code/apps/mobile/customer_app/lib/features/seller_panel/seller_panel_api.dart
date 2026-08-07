import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'seller_panel_models.dart';

/// Native "Mening do'konim" paneli — `sellerDioProvider` orqali ishlaydi
/// (alohida, 'seller' rolli JWT). `seller_web/src/lib/api.ts`ning Dart nusxasi.
class SellerPanelApi {
  final Dio _dio;
  SellerPanelApi(this._dio);

  // ---- Mahsulotlar ----

  Future<List<SellerProduct>> products() async {
    final res = await _dio.get('/marketplace/seller/products');
    return ((res.data['data'] as List?) ?? const [])
        .map((e) => SellerProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SellerProduct> createProduct({
    String? categoryId,
    required I18nText name,
    I18nText? description,
    required int price,
    List<String> imageUrls = const [],
    List<String> sizes = const [],
  }) async {
    final res = await _dio.post('/marketplace/seller/products', data: {
      if (categoryId != null) 'categoryId': categoryId,
      'name': name.toJson(),
      if (description != null) 'description': description.toJson(),
      'price': price,
      if (imageUrls.isNotEmpty) 'imageUrls': imageUrls,
      if (sizes.isNotEmpty) 'sizes': sizes,
    });
    return SellerProduct.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<SellerProduct> updateProduct(
    String id, {
    String? categoryId,
    I18nText? name,
    I18nText? description,
    int? price,
    List<String>? imageUrls,
    List<String>? sizes,
    bool? isActive,
  }) async {
    final res = await _dio.patch('/marketplace/seller/products/$id', data: {
      if (categoryId != null) 'categoryId': categoryId,
      if (name != null) 'name': name.toJson(),
      if (description != null) 'description': description.toJson(),
      if (price != null) 'price': price,
      if (imageUrls != null) 'imageUrls': imageUrls,
      if (sizes != null) 'sizes': sizes,
      if (isActive != null) 'isActive': isActive,
    });
    return SellerProduct.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<void> deleteProduct(String id) async {
    await _dio.delete('/marketplace/seller/products/$id');
  }

  /// Kategoriyalar — ochiq (public) endpoint, sotuvchining o'z turi bo'yicha.
  Future<List<SellerCategory>> categories(String sellerType) async {
    try {
      final res = await _dio.get('/marketplace/categories', queryParameters: {'sellerType': sellerType});
      return ((res.data['data'] as List?) ?? const [])
          .map((e) => SellerCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  // ---- Suhbatlar ----

  Future<List<SellerChatThread>> chatThreads() async {
    final res = await _dio.get('/marketplace/seller/chats');
    return ((res.data['data'] as List?) ?? const [])
        .map((e) => SellerChatThread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<SellerChatMessage>> chatMessages(String customerId) async {
    final res = await _dio.get('/marketplace/seller/chats/$customerId/messages');
    return ((res.data['data'] as List?) ?? const [])
        .map((e) => SellerChatMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SellerChatMessage> sendChatMessage(String customerId, String text) async {
    final res = await _dio.post('/marketplace/seller/chats/$customerId/messages', data: {'text': text});
    return SellerChatMessage.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  // ---- Profil ----

  Future<SellerProfile> profile() async {
    final res = await _dio.get('/marketplace/seller/profile');
    return SellerProfile.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  Future<SellerProfile> updateProfile({
    String? name,
    String? description,
    String? contactPhone,
    String? address,
    double? lat,
    double? lng,
  }) async {
    final res = await _dio.patch('/marketplace/seller/profile', data: {
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (contactPhone != null) 'contactPhone': contactPhone,
      if (address != null) 'address': address,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    });
    return SellerProfile.fromJson((res.data['data'] as Map).cast<String, dynamic>());
  }

  /// Mahsulot rasmini yuklaydi, tayyor URL qaytaradi.
  Future<String> uploadImage(File file) async {
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path),
    });
    final res = await _dio.post('/marketplace/upload', data: form);
    return (res.data['data'] as Map)['url'] as String;
  }
}

final sellerPanelApiProvider = Provider<SellerPanelApi>((ref) => SellerPanelApi(ref.read(sellerDioProvider)));
