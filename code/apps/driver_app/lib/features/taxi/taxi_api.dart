import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'taxi_models.dart';

/// Haydovchi taksi API'si — gateway orqali. driverId token (JWT) dan olinadi.
/// plan/06-driver-app.md
class TaxiApi {
  final Dio _dio;
  TaxiApi(this._dio);

  Future<List<TaxiTrip>> available() async {
    final res = await _dio.get('/taxi/driver/available');
    final list = (res.data['data'] as List?) ?? const [];
    return list.map((e) => TaxiTrip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TaxiTrip>> myTrips() async {
    final res = await _dio.get('/taxi/driver/my-trips');
    final list = (res.data['data'] as List?) ?? const [];
    return list.map((e) => TaxiTrip.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> accept(String id) => _action(id, 'accept');
  Future<void> start(String id) => _action(id, 'start');
  Future<void> complete(String id) => _action(id, 'complete');

  Future<void> _action(String id, String action) async {
    await _dio.post('/taxi/driver/trips/$id/$action');
  }
}

final taxiApiProvider =
    Provider<TaxiApi>((ref) => TaxiApi(ref.read(dioProvider)));

final availableTaxiProvider = FutureProvider<List<TaxiTrip>>((ref) {
  ref.watch(localeProvider);
  return ref.read(taxiApiProvider).available();
});

final myTaxiTripsProvider = FutureProvider<List<TaxiTrip>>((ref) {
  ref.watch(localeProvider);
  return ref.read(taxiApiProvider).myTrips();
});
