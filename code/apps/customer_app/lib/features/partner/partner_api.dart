import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'partner_models.dart';

/// Hamkorlik (partner) API'si — gateway orqali, Bearer token. plan/05-customer-app.md
class PartnerApi {
  final Dio _dio;
  PartnerApi(this._dio);

  Future<PartnerApplication> apply({
    required String fullName,
    required PartnerType type,
    String? note,
  }) async {
    final res = await _dio.post('/partners/apply', data: {
      'fullName': fullName,
      'type': type.api,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return PartnerApplication.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<PartnerApplication>> listMine() async {
    final res = await _dio.get('/partners/mine');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => PartnerApplication.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final partnerApiProvider =
    Provider<PartnerApi>((ref) => PartnerApi(ref.read(dioProvider)));

final myApplicationsProvider =
    FutureProvider<List<PartnerApplication>>((ref) {
  ref.watch(localeProvider);
  return ref.read(partnerApiProvider).listMine();
});
