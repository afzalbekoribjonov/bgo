import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/places.dart';
import 'taxi_models.dart';

/// Taksi API'si (gateway orqali, Bearer token). plan/05-customer-app.md
class TaxiApi {
  final Dio _dio;
  TaxiApi(this._dio);

  Map<String, dynamic> _point(GeoPlace p) => {
        'text': p.label,
        'lat': p.lat,
        'lng': p.lng,
      };

  Future<TaxiTariff> tariff() async {
    final res = await _dio.get('/taxi/tariff');
    return TaxiTariff.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<TaxiEstimate> estimate(GeoPlace pickup, GeoPlace destination) async {
    final res = await _dio.post('/taxi/estimate', data: {
      'pickup': _point(pickup),
      'destination': _point(destination),
    });
    return TaxiEstimate.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  /// [destination] null bo'lsa — manzilsiz (metered) so'rov: narx yakunda.
  Future<TaxiTrip> request(GeoPlace pickup, GeoPlace? destination) async {
    final res = await _dio.post('/taxi/request', data: {
      'pickup': _point(pickup),
      if (destination != null) 'destination': _point(destination),
    });
    return TaxiTrip.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<TaxiTrip>> listMine() async {
    final res = await _dio.get('/taxi/mine');
    final list = (res.data['data'] as List?) ?? const [];
    return list.map((e) => TaxiTrip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> cancel(String id) async {
    await _dio.post('/taxi/$id/cancel');
  }

  Future<List<TaxiMessage>> messages(String id) async {
    final res = await _dio.get('/taxi/$id/messages');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => TaxiMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TaxiMessage> sendMessage(String id, String text) async {
    final res = await _dio.post('/taxi/$id/messages', data: {'text': text});
    return TaxiMessage.fromJson(res.data['data'] as Map<String, dynamic>);
  }
}

final taxiApiProvider =
    Provider<TaxiApi>((ref) => TaxiApi(ref.read(dioProvider)));

final myTripsProvider = FutureProvider<List<TaxiTrip>>((ref) {
  ref.watch(localeProvider);
  return ref.read(taxiApiProvider).listMine();
});

final taxiTariffProvider =
    FutureProvider<TaxiTariff>((ref) => ref.read(taxiApiProvider).tariff());
