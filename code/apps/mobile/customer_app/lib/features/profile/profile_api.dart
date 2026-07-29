import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'profile_models.dart';

/// Profil + manzillar API'si (gateway orqali, Bearer token). plan/05-customer-app.md
class ProfileApi {
  final Dio _dio;
  ProfileApi(this._dio);

  Future<void> updateName(String fullName) async {
    await _dio.patch('/profile', data: {'fullName': fullName});
  }

  Future<List<Address>> listAddresses() async {
    final res = await _dio.get('/profile/addresses');
    final list = (res.data['data'] as List?) ?? const [];
    return list.map((e) => Address.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Address> addAddress({
    required String label,
    required String text,
    double? lat,
    double? lng,
    bool isDefault = false,
  }) async {
    final res = await _dio.post('/profile/addresses', data: {
      'label': label,
      'text': text,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
      if (isDefault) 'isDefault': true,
    });
    return Address.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<void> setDefault(String id) async {
    await _dio.patch('/profile/addresses/$id', data: {'isDefault': true});
  }

  Future<void> deleteAddress(String id) async {
    await _dio.delete('/profile/addresses/$id');
  }

  /// "Mening oshxonam" — kirgan foydalanuvchi oshxona egasimi? Egasi bo'lsa
  /// panelga WebView orqali avtomatik kirish uchun token qaytadi.
  Future<MyKitchen> myKitchen() async {
    final res = await _dio.get('/restaurants/my-kitchen');
    return MyKitchen.fromJson(
        (res.data['data'] as Map<String, dynamic>?) ?? const {});
  }
}

/// Foydalanuvchining oshxonasi (egasi bo'lsa) + panelga kirish tokeni.
class MyKitchen {
  final String? restaurantId;
  final String? name;
  final String? accessToken;
  const MyKitchen({this.restaurantId, this.name, this.accessToken});

  bool get owns =>
      restaurantId != null && (accessToken?.isNotEmpty ?? false);

  factory MyKitchen.fromJson(Map<String, dynamic> j) => MyKitchen(
        restaurantId: j['restaurantId'] as String?,
        name: j['name'] as String?,
        accessToken: j['accessToken'] as String?,
      );
}

final profileApiProvider =
    Provider<ProfileApi>((ref) => ProfileApi(ref.read(dioProvider)));

final addressesProvider = FutureProvider<List<Address>>((ref) {
  ref.watch(localeProvider);
  return ref.read(profileApiProvider).listAddresses();
});

/// Egalik holati (profil ekranida "Mening oshxonam" tugmasini ko'rsatish uchun).
final myKitchenProvider = FutureProvider<MyKitchen>((ref) {
  return ref.read(profileApiProvider).myKitchen();
});
