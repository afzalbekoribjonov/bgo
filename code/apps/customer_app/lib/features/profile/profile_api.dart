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
    bool isDefault = false,
  }) async {
    final res = await _dio.post('/profile/addresses', data: {
      'label': label,
      'text': text,
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
}

final profileApiProvider =
    Provider<ProfileApi>((ref) => ProfileApi(ref.read(dioProvider)));

final addressesProvider = FutureProvider<List<Address>>((ref) {
  ref.watch(localeProvider);
  return ref.read(profileApiProvider).listAddresses();
});
