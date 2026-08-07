import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  /// native panelga kirish uchun (kitchenDioProvider ichida) token qaytadi.
  Future<MyKitchen> myKitchen() async {
    final res = await _dio.get('/restaurants/my-kitchen');
    return MyKitchen.fromJson(
        (res.data['data'] as Map<String, dynamic>?) ?? const {});
  }

  /// "Mening do'konim" — kirgan foydalanuvchi marketplace sotuvchisi egasimi?
  Future<MyShop> myShop() async {
    final res = await _dio.get('/marketplace/my-shop');
    return MyShop.fromJson(
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

/// Foydalanuvchining do'koni (marketplace sotuvchisi egasi bo'lsa) + panel tokeni.
class MyShop {
  final String? sellerId;
  final String? name;
  final String? accessToken;
  const MyShop({this.sellerId, this.name, this.accessToken});

  bool get owns => sellerId != null && (accessToken?.isNotEmpty ?? false);

  factory MyShop.fromJson(Map<String, dynamic> j) => MyShop(
        sellerId: j['sellerId'] as String?,
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

/// Native "Mening oshxonam"/"Mening do'konim" kartalari uchun — mahalliy
/// keshda saqlanadi (`flutter_secure_storage`), ilova ochilishida DARHOL
/// ko'rsatiladi (tarmoq kutilmasdan), fonda revalidatsiya qilinadi.
/// `authControllerProvider`ning `_readCachedUser`/`_cacheUser` naqshi.
class PartnerLinkStatus {
  final bool loading;
  final String? id;
  final String? name;
  const PartnerLinkStatus({this.loading = true, this.id, this.name});

  bool get linked => id != null;
}

class KitchenLinkController extends Notifier<PartnerLinkStatus> {
  static const _key = 'my_kitchen_link_cache';
  final _secure = const FlutterSecureStorage();

  @override
  PartnerLinkStatus build() => const PartnerLinkStatus();

  Future<void> bootstrap() async {
    final cached = await _readCached(_secure, _key);
    if (cached != null) {
      state = PartnerLinkStatus(loading: false, id: cached['id'] as String?, name: cached['name'] as String?);
    }
    try {
      final fresh = await ref.read(profileApiProvider).myKitchen();
      await _writeCached(_secure, _key, fresh.restaurantId, fresh.name);
      state = PartnerLinkStatus(loading: false, id: fresh.restaurantId, name: fresh.name);
    } catch (_) {
      if (cached == null) state = const PartnerLinkStatus(loading: false);
      // aks holda: tarmoq xatosida keshdagi holatda qolamiz
    }
  }
}

class SellerShopLinkController extends Notifier<PartnerLinkStatus> {
  static const _key = 'my_shop_link_cache';
  final _secure = const FlutterSecureStorage();

  @override
  PartnerLinkStatus build() => const PartnerLinkStatus();

  Future<void> bootstrap() async {
    final cached = await _readCached(_secure, _key);
    if (cached != null) {
      state = PartnerLinkStatus(loading: false, id: cached['id'] as String?, name: cached['name'] as String?);
    }
    try {
      final fresh = await ref.read(profileApiProvider).myShop();
      await _writeCached(_secure, _key, fresh.sellerId, fresh.name);
      state = PartnerLinkStatus(loading: false, id: fresh.sellerId, name: fresh.name);
    } catch (_) {
      if (cached == null) state = const PartnerLinkStatus(loading: false);
    }
  }
}

Future<Map<String, dynamic>?> _readCached(FlutterSecureStorage s, String key) async {
  try {
    final raw = await s.read(key: key);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Future<void> _writeCached(FlutterSecureStorage s, String key, String? id, String? name) async {
  if (id == null) {
    await s.delete(key: key);
  } else {
    await s.write(key: key, value: jsonEncode({'id': id, 'name': name}));
  }
}

final kitchenLinkProvider =
    NotifierProvider<KitchenLinkController, PartnerLinkStatus>(KitchenLinkController.new);
final sellerShopLinkProvider =
    NotifierProvider<SellerShopLinkController, PartnerLinkStatus>(SellerShopLinkController.new);
