import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';

/// Haydovchiga taklif qilingan (yoki pool'dagi) buyurtma.
class DriverOffer {
  final String orderId;
  final String vertical; // food | taxi | parcel
  final String pickupName;
  final double pickupLat;
  final double pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? dropoffText;
  final int amount; // buyurtma narxi
  final int earning; // haydovchi ulushi
  final double distanceKm; // haydovchi -> pickup
  final int secondsLeft; // taklif uchun (pool'da 0)
  // Ovqat: naqd taqsimot (qabul qilishdan oldin ko'rsatiladi)
  final int foodItemsTotal; // oshxonaga naqd to'lanadi
  final int foodServiceFee; // xizmat haqi (balansdan yechiladi)

  const DriverOffer({
    required this.orderId,
    required this.vertical,
    required this.pickupName,
    required this.pickupLat,
    required this.pickupLng,
    required this.amount,
    required this.earning,
    required this.distanceKm,
    required this.secondsLeft,
    this.dropoffLat,
    this.dropoffLng,
    this.dropoffText,
    this.foodItemsTotal = 0,
    this.foodServiceFee = 0,
  });

  bool get isFood => vertical == 'food';

  LatLng get pickup => LatLng(pickupLat, pickupLng);
  LatLng? get dropoff =>
      (dropoffLat != null && dropoffLng != null) ? LatLng(dropoffLat!, dropoffLng!) : null;

  factory DriverOffer.fromJson(Map<String, dynamic> j) => DriverOffer(
        orderId: j['orderId'] as String,
        vertical: (j['vertical'] as String?) ?? 'food',
        pickupName: (j['pickupName'] as String?) ?? '',
        pickupLat: (j['pickupLat'] as num).toDouble(),
        pickupLng: (j['pickupLng'] as num).toDouble(),
        dropoffLat: (j['dropoffLat'] as num?)?.toDouble(),
        dropoffLng: (j['dropoffLng'] as num?)?.toDouble(),
        dropoffText: j['dropoffText'] as String?,
        amount: (j['amount'] as num?)?.toInt() ?? 0,
        earning: (j['earning'] as num?)?.toInt() ?? 0,
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
        secondsLeft: (j['secondsLeft'] as num?)?.toInt() ?? 0,
        foodItemsTotal: (j['foodItemsTotal'] as num?)?.toInt() ?? 0,
        foodServiceFee: (j['foodServiceFee'] as num?)?.toInt() ?? 0,
      );
}

class OfferApi {
  final Dio _dio;
  OfferApi(this._dio);

  /// Menga hozir taklif qilingan buyurtma (yoki null).
  Future<DriverOffer?> current() async {
    final res = await _dio.get('/courier/offer');
    final data = res.data['data'];
    if (data == null) return null;
    return DriverOffer.fromJson(data as Map<String, dynamic>);
  }

  Future<void> accept(String orderId) =>
      _dio.post('/courier/offer/$orderId/accept');

  Future<void> skip(String orderId) =>
      _dio.post('/courier/offer/$orderId/skip');

  /// Qabul qilinmagan (pool) buyurtmalar.
  Future<List<DriverOffer>> pool() async {
    final res = await _dio.get('/courier/pool');
    final list = (res.data['data'] as List?) ?? const [];
    return list
        .map((e) => DriverOffer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> acceptFromPool(String orderId) =>
      _dio.post('/courier/pool/$orderId/accept');
}

final offerApiProvider =
    Provider<OfferApi>((ref) => OfferApi(ref.read(dioProvider)));

/// Pool ro'yxati (badge + sahifa uchun).
final poolProvider = FutureProvider<List<DriverOffer>>(
  (ref) => ref.read(offerApiProvider).pool(),
);
