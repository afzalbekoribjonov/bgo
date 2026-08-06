import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import 'market_models.dart';

/// Beshariq Market katalog API'si (gateway orqali, ochiq endpoint).
class MarketApi {
  final Dio _dio;
  MarketApi(this._dio);

  /// Bosh ekran uchun mahsulotlar lentasi (barcha kategoriyalardan).
  ///
  /// Backend endi sahifalab qaytaradi (`{items,total,page,pageSize}`) — shuffle
  /// puli "butun katalog"dan torayib qolmasligi uchun kattaroq pageSize so'raladi.
  Future<List<MarketProduct>> listProducts() async {
    final res = await _dio.get('/market/products', queryParameters: {'pageSize': 50});
    final data = res.data['data'] as Map<String, dynamic>?;
    final list = (data?['items'] as List?) ?? const [];
    return list
        .map((e) => MarketProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final marketApiProvider =
    Provider<MarketApi>((ref) => MarketApi(ref.read(dioProvider)));

/// Bosh ekran Market bo'limi uchun mahsulotlar. Til o'zgarsa qayta yuklanadi.
final marketProductsProvider = FutureProvider<List<MarketProduct>>((ref) {
  ref.watch(localeProvider);
  return ref.read(marketApiProvider).listProducts();
});
