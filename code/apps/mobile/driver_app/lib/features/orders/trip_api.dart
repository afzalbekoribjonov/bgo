import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';

/// Haydovchining faol ishi (taksi safari yoki dostavka) — server hisoblagan
/// jonli narx + holat bilan. Vertikalga qarab endpoint farq qiladi.
/// Backend: TaxiTripLive (/taxi/driver/trips/:id) yoki ParcelDeliveryLive
/// (/parcel/driver/deliveries/:id).
class DriverTrip {
  final String id;
  final String vertical; // 'taxi' | 'parcel' | 'food'
  final String status;
  final String customerId;
  final double pickupLat;
  final double pickupLng;
  final String pickupText;
  final double? dropoffLat;
  final double? dropoffLng;
  final String? dropoffText;
  final bool metered;
  final double distanceKm;
  final double pickupDistanceKm; // taksi: haydovchi -> olib ketish
  final int pickupSurcharge;
  final int fare;
  final int waitMinutes;
  final bool waiting;
  final DateTime? waitStartedAt; // joriy ochiq kutish segmenti boshlangani
  final int waitAccumSec; // oldingi yopiq segmentlar (soniya)
  final int waitFreeMin; // bepul kutish oynasi (daqiqa) — keyin tillo/pulli
  final int currentWaitMinutes;
  final int currentWaitFee;
  final int currentFare;
  final int durationMinutes;
  // Dostavka maydonlari
  final String? recipientName;
  final String? recipientPhone;
  final String? size;
  // Mijoz raqami (suhbatdagi qo'ng'iroq tugmasi uchun)
  final String? customerPhone;
  // Ovqat maydonlari (naqd taqsimot)
  final int foodItemsTotal; // oshxonaga naqd to'lanadi
  final int foodServiceFee; // xizmat haqi (balansdan)
  final int foodIncome; // haydovchi daromadi (yetkazish)

  const DriverTrip({
    required this.id,
    required this.vertical,
    required this.status,
    required this.customerId,
    required this.pickupLat,
    required this.pickupLng,
    required this.pickupText,
    required this.metered,
    required this.distanceKm,
    required this.pickupDistanceKm,
    required this.pickupSurcharge,
    required this.fare,
    required this.waitMinutes,
    required this.waiting,
    required this.currentWaitMinutes,
    required this.currentWaitFee,
    required this.currentFare,
    required this.durationMinutes,
    this.waitStartedAt,
    this.waitAccumSec = 0,
    this.waitFreeMin = 2,
    this.dropoffLat,
    this.dropoffLng,
    this.dropoffText,
    this.recipientName,
    this.recipientPhone,
    this.size,
    this.customerPhone,
    this.foodItemsTotal = 0,
    this.foodServiceFee = 0,
    this.foodIncome = 0,
  });

  LatLng get pickup => LatLng(pickupLat, pickupLng);
  LatLng? get dropoff => (dropoffLat != null && dropoffLng != null)
      ? LatLng(dropoffLat!, dropoffLng!)
      : null;

  bool get isTaxi => vertical == 'taxi';
  bool get isFood => vertical == 'food';

  /// Qabul qiluvchiga (manzilga) yo'ldagi holatlar — marshrut manzilga.
  /// Ovqatda: PICKED_UP dan keyin mijozga; undan oldin oshxonaga.
  bool get goingToDropoff =>
      status == 'IN_PROGRESS' ||
      status == 'IN_TRANSIT' ||
      (isFood && status == 'PICKED_UP');

  bool get isActive => isFood
      ? const ['PENDING', 'ACCEPTED', 'PREPARING', 'READY', 'PICKED_UP']
          .contains(status)
      : const ['ACCEPTED', 'ARRIVED', 'PICKED_UP', 'IN_PROGRESS', 'IN_TRANSIT']
          .contains(status);

  bool get isDone => status == 'COMPLETED' || status == 'DELIVERED';

  /// Jonli jami kutish (soniya) — jamlangan + ochiq segment; har soniya o'sadi.
  int get liveWaitSeconds {
    var s = waitAccumSec;
    if (waitStartedAt != null) {
      s += DateTime.now().difference(waitStartedAt!).inSeconds;
    }
    return s < 0 ? 0 : s;
  }

  /// mm:ss ko'rinishidagi kutish taymeri (00:00).
  String get waitClock {
    final s = liveWaitSeconds;
    return '${(s ~/ 60).toString().padLeft(2, '0')}:'
        '${(s % 60).toString().padLeft(2, '0')}';
  }

  /// Bepul oyna o'tib, pulli kutish boshlandimi (tillo/porlash holati).
  bool get waitPaidStarted => liveWaitSeconds >= waitFreeMin * 60;

  factory DriverTrip.fromJson(Map<String, dynamic> j, String vertical) {
    // Ovqat — buyurtma shakli boshqacha (oshxona = olib ketish, manzil = yetkazish).
    if (vertical == 'food') {
      final r = j['restaurant'] as Map<String, dynamic>?;
      final total = (j['total'] as num?)?.toInt() ?? 0;
      return DriverTrip(
        id: j['id'] as String,
        vertical: 'food',
        status: j['status'] as String,
        customerId: (j['customerId'] as String?) ?? '',
        pickupLat: (r?['lat'] as num?)?.toDouble() ?? 0,
        pickupLng: (r?['lng'] as num?)?.toDouble() ?? 0,
        pickupText: (r?['name'] as String?) ?? 'Oshxona',
        dropoffLat: (j['address']?['lat'] as num?)?.toDouble(),
        dropoffLng: (j['address']?['lng'] as num?)?.toDouble(),
        dropoffText: j['address']?['text'] as String?,
        metered: false,
        distanceKm: 0,
        pickupDistanceKm: 0,
        pickupSurcharge: 0,
        fare: total,
        waitMinutes: 0,
        waiting: false,
        currentWaitMinutes: 0,
        currentWaitFee: 0,
        currentFare: total,
        durationMinutes: 0,
        customerPhone: j['customerPhone'] as String?,
        foodItemsTotal: (j['itemsTotal'] as num?)?.toInt() ?? 0,
        foodServiceFee: (j['serviceFee'] as num?)?.toInt() ?? 0,
        foodIncome: (j['courierEarning'] as num?)?.toInt() ?? 0,
      );
    }
    return DriverTrip(
        id: j['id'] as String,
        vertical: vertical,
        status: j['status'] as String,
        customerId: (j['customerId'] as String?) ?? '',
        pickupLat: ((j['pickup']?['lat']) as num).toDouble(),
        pickupLng: ((j['pickup']?['lng']) as num).toDouble(),
        pickupText: (j['pickup']?['text'] as String?) ?? '',
        dropoffLat: (j['destination']?['lat'] as num?)?.toDouble(),
        dropoffLng: (j['destination']?['lng'] as num?)?.toDouble(),
        dropoffText: j['destination']?['text'] as String?,
        metered: (j['metered'] as bool?) ?? false,
        distanceKm: (j['distanceKm'] as num?)?.toDouble() ?? 0,
        pickupDistanceKm: (j['pickupDistanceKm'] as num?)?.toDouble() ?? 0,
        pickupSurcharge: (j['pickupSurcharge'] as num?)?.toInt() ?? 0,
        fare: (j['fare'] as num?)?.toInt() ?? 0,
        waitMinutes: (j['waitMinutes'] as num?)?.toInt() ?? 0,
        waiting: j['waitStartedAt'] != null,
        waitStartedAt: j['waitStartedAt'] != null
            ? DateTime.tryParse(j['waitStartedAt'] as String)
            : null,
        waitAccumSec: (j['waitAccumSec'] as num?)?.toInt() ?? 0,
        waitFreeMin: (j['waitFreeMin'] as num?)?.toInt() ?? 2,
        currentWaitMinutes: (j['currentWaitMinutes'] as num?)?.toInt() ?? 0,
        currentWaitFee: (j['currentWaitFee'] as num?)?.toInt() ?? 0,
        currentFare: (j['currentFare'] as num?)?.toInt() ?? 0,
        durationMinutes: (j['durationMinutes'] as num?)?.toInt() ?? 0,
        recipientName: j['recipientName'] as String?,
        recipientPhone: j['recipientPhone'] as String?,
        size: j['size'] as String?,
        customerPhone: j['customerPhone'] as String?,
      );
  }
}

/// Vertikalga qarab faol ish boshqaruvi (qabuldan keyingi oqim).
class TripApi {
  final Dio _dio;
  TripApi(this._dio);

  String _base(String vertical) {
    if (vertical == 'parcel') return '/parcel/driver/deliveries';
    if (vertical == 'food') return '/courier/orders';
    return '/taxi/driver/trips';
  }

  Future<DriverTrip> get(String vertical, String id) async {
    final res = await _dio.get('${_base(vertical)}/$id');
    return DriverTrip.fromJson(
        res.data['data'] as Map<String, dynamic>, vertical);
  }

  /// Holatni o'zgartiruvchi amal (arrive/start/pickup/transit/complete/
  /// delivered/wait) — endpoint vertikalga mos.
  Future<DriverTrip> act(String vertical, String id, String action) async {
    final res = await _dio.post('${_base(vertical)}/$id/$action');
    return DriverTrip.fromJson(
        res.data['data'] as Map<String, dynamic>, vertical);
  }

  /// Buyurtmadan voz kechish — sabab majburiy (balansdan jarima yechiladi).
  /// Javob tarkibi vertikalga qarab farq qiladi (ovqatda {ok:true}), shuning
  /// uchun parse qilinmaydi.
  Future<void> cancel(
    String vertical,
    String id, {
    required String reason,
    String? note,
  }) async {
    await _dio.post(
      '${_base(vertical)}/$id/cancel',
      data: {'reason': reason, if (note != null && note.isNotEmpty) 'note': note},
    );
  }

  /// Haydovchining hozirgi faol ishi (taksi yoki dostavka) — ilova qayta
  /// ochilganda tiklash uchun. Topilmasa null.
  Future<DriverTrip?> activeJob() async {
    // Taksi/dostavka — o'z ro'yxati; ovqat — /courier/my-orders.
    const listEndpoint = {
      'taxi': '/taxi/driver/trips',
      'parcel': '/parcel/driver/deliveries',
      'food': '/courier/my-orders',
    };
    const activeFood = ['PENDING', 'ACCEPTED', 'PREPARING', 'READY', 'PICKED_UP'];
    const activeTrip = ['ACCEPTED', 'ARRIVED', 'PICKED_UP', 'IN_PROGRESS', 'IN_TRANSIT'];
    for (final v in const ['taxi', 'parcel', 'food']) {
      try {
        final res = await _dio.get(listEndpoint[v]!);
        final list = (res.data['data'] as List?) ?? const [];
        final active = v == 'food' ? activeFood : activeTrip;
        for (final e in list) {
          final m = e as Map<String, dynamic>;
          final s = m['status'] as String?;
          if (s != null && active.contains(s)) {
            return DriverTrip.fromJson(m, v);
          }
        }
      } catch (_) {/* keyingi vertikal */}
    }
    return null;
  }
}

final tripApiProvider =
    Provider<TripApi>((ref) => TripApi(ref.read(dioProvider)));
