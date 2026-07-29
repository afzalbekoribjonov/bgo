import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/places.dart';
import 'package:beshariq_core/beshariq_core.dart';
import '../taxi/taxi_models.dart' show DriverLoc;
import 'parcel_models.dart';

/// Dostavka API'si (gateway orqali, Bearer token). plan/05-customer-app.md
class ParcelApi {
  final Dio _dio;
  ParcelApi(this._dio);

  Map<String, dynamic> _point(GeoPlace p) => {
        'text': p.label,
        'lat': p.lat,
        'lng': p.lng,
      };

  Future<ParcelEstimate> estimate(
    GeoPlace pickup,
    GeoPlace destination,
    ParcelSize size,
  ) async {
    final res = await _dio.post('/parcel/estimate', data: {
      'pickup': _point(pickup),
      'destination': _point(destination),
      'size': size.api,
    });
    return ParcelEstimate.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<ParcelDelivery> request({
    required GeoPlace pickup,
    required GeoPlace destination,
    required ParcelSize size,
    required String recipientName,
    required String recipientPhone,
    String? note,
  }) async {
    final res = await _dio.post('/parcel/request', data: {
      'pickup': _point(pickup),
      'destination': _point(destination),
      'size': size.api,
      'recipientName': recipientName,
      'recipientPhone': recipientPhone,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return ParcelDelivery.fromJson(res.data['data'] as Map<String, dynamic>);
  }

  Future<List<ParcelDelivery>> listMine() async {
    final res = await _dio.get('/parcel/mine');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => ParcelDelivery.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancel(String id) async {
    await _dio.post('/parcel/$id/cancel');
  }

  /// Biriktirilgan kuryerning jonli joylashuvi (null bo'lishi mumkin).
  Future<DriverLoc?> driverLocation(String id) async {
    final res = await _dio.get('/parcel/$id/driver');
    final data = res.data['data'];
    if (data == null) return null;
    return DriverLoc.fromJson(data as Map<String, dynamic>);
  }

  /// Yetkazilgan dostavkani baholash (1-5).
  Future<void> rate(String id, int rating, {String? comment}) async {
    await _dio.post('/parcel/$id/rate', data: {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
    });
  }
}

final parcelApiProvider =
    Provider<ParcelApi>((ref) => ParcelApi(ref.read(dioProvider)));

final myParcelsProvider = FutureProvider<List<ParcelDelivery>>((ref) {
  ref.watch(localeProvider);
  return ref.read(parcelApiProvider).listMine();
});
