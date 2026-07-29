// Taksi modellari — Order servisi (taxi) javobiga mos.
// Nuqta tipi: GeoPlace (lib/core/places.dart) — taksi va dostavka uchun umumiy.

class TaxiTariff {
  final int baseFare;
  final int perKm;
  final int minFare;
  /// Comfort minimal narxi (Start minFare + baza ustamasi).
  final int minFareComfort;
  /// Comfort boshlang'ich haqi (Start baseFare + baza ustamasi) — tarif
  /// tanlash tugmalarida ko'rsatiladi (minimal narx emas).
  final int baseFareComfort;

  const TaxiTariff({
    required this.baseFare,
    required this.perKm,
    required this.minFare,
    required this.minFareComfort,
    required this.baseFareComfort,
  });

  factory TaxiTariff.fromJson(Map<String, dynamic> json) => TaxiTariff(
        baseFare: (json['baseFare'] as num?)?.toInt() ?? 0,
        perKm: (json['perKm'] as num?)?.toInt() ?? 0,
        minFare: (json['minFare'] as num?)?.toInt() ?? 0,
        minFareComfort: (json['minFareComfort'] as num?)?.toInt() ??
            (json['minFare'] as num?)?.toInt() ??
            0,
        baseFareComfort: (json['baseFareComfort'] as num?)?.toInt() ??
            (json['baseFare'] as num?)?.toInt() ??
            0,
      );
}

class TaxiEstimate {
  final double distanceKm;
  /// Start tarifi narxi.
  final int fare;
  /// Comfort tarifi narxi (Start + km/baza ustamalari).
  final int fareComfort;
  /// Taxminiy yurish vaqti (daqiqa) — server zaxirasi; OSRM aniqrog'i bo'lsa u ustun.
  final int etaMinutes;
  final int commission;
  final int driverEarning;

  const TaxiEstimate({
    required this.distanceKm,
    required this.fare,
    required this.fareComfort,
    required this.etaMinutes,
    required this.commission,
    required this.driverEarning,
  });

  factory TaxiEstimate.fromJson(Map<String, dynamic> json) {
    final fare = (json['fare'] as num?)?.toInt() ?? 0;
    return TaxiEstimate(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      fare: fare,
      fareComfort: (json['fareComfort'] as num?)?.toInt() ?? fare,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 0,
      commission: (json['commission'] as num?)?.toInt() ?? 0,
      driverEarning: (json['driverEarning'] as num?)?.toInt() ?? 0,
    );
  }
}

class TaxiTrip {
  final String id;
  final int publicNo;
  final String status;
  final int fare;
  final double distanceKm;
  /// Haydovchi GPS orqali haqiqatda bosib o'tgan masofa (bo'lsa) — narxga
  /// ta'sir qilmaydi, faqat ko'rsatish uchun.
  final double? actualDistanceKm;
  final String pickupText;
  final String destinationText;
  final int? rating;
  final String createdAt;
  // Jonli (server hisoblagan) maydonlar
  final int pickupSurcharge;
  final int currentFare;
  final int currentWaitFee;
  final int currentWaitMinutes;
  final int durationMinutes;
  final bool waiting; // haydovchi hozir kutmoqda (pulli kutish yonishi mumkin)
  // Biriktirilgan haydovchi (faol safarda)
  final String? driverName;
  final String? driverCar;
  final String? driverPlate; // mashina raqami (eng muhim — farqlash uchun)
  final String? driverPhone; // suhbatda qo'ng'iroq qilish uchun
  final double driverRating; // o'rtacha baho (0 = hali baho yo'q)
  final int driverRatingCount;

  /// Ko'rsatish uchun masofa: GPS bilan o'lchangan bo'lsa o'shani, aks holda
  /// dastlabki (narx) masofasini qaytaradi. Narxga hech qanday ta'sir qilmaydi.
  double get displayDistanceKm =>
      (actualDistanceKm != null && actualDistanceKm! > 0)
          ? actualDistanceKm!
          : distanceKm;

  const TaxiTrip({
    required this.id,
    required this.publicNo,
    required this.status,
    required this.fare,
    required this.distanceKm,
    this.actualDistanceKm,
    required this.pickupText,
    required this.destinationText,
    this.rating,
    this.createdAt = '',
    this.pickupSurcharge = 0,
    this.currentFare = 0,
    this.currentWaitFee = 0,
    this.currentWaitMinutes = 0,
    this.durationMinutes = 0,
    this.waiting = false,
    this.driverName,
    this.driverCar,
    this.driverPlate,
    this.driverPhone,
    this.driverRating = 0,
    this.driverRatingCount = 0,
  });

  factory TaxiTrip.fromJson(Map<String, dynamic> json) {
    return TaxiTrip(
      id: json['id'] as String,
      publicNo: (json['publicNo'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'PENDING',
      fare: (json['fare'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      actualDistanceKm: (json['actualDistanceKm'] as num?)?.toDouble(),
      pickupText: (json['pickup']?['text'] as String?) ?? '',
      destinationText: (json['destination']?['text'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as String?) ?? '',
      pickupSurcharge: (json['pickupSurcharge'] as num?)?.toInt() ?? 0,
      currentFare: (json['currentFare'] as num?)?.toInt() ?? 0,
      currentWaitFee: (json['currentWaitFee'] as num?)?.toInt() ?? 0,
      currentWaitMinutes: (json['currentWaitMinutes'] as num?)?.toInt() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      waiting: json['waitStartedAt'] != null,
      driverName: json['driverName'] as String?,
      driverCar: json['driverCar'] as String?,
      driverPlate: json['driverPlate'] as String?,
      driverPhone: json['driverPhone'] as String?,
      driverRating: (json['driverRating'] as num?)?.toDouble() ?? 0,
      driverRatingCount: (json['driverRatingCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Ko'rsatiladigan narx — jonli bo'lsa o'sha, aks holda asos.
  int get displayFare => currentFare > 0 ? currentFare : fare;

  bool get isActive =>
      status == 'PENDING' ||
      status == 'ACCEPTED' ||
      status == 'ARRIVED' ||
      status == 'IN_PROGRESS';

  /// Safar boshlangach (IN_PROGRESS) bekor qilib bo'lmaydi.
  bool get isCancellable =>
      status == 'PENDING' || status == 'ACCEPTED' || status == 'ARRIVED';

  /// Suhbat haydovchi biriktirilgach ochiq, yakuniygacha.
  bool get hasChat =>
      status == 'ACCEPTED' || status == 'ARRIVED' || status == 'IN_PROGRESS';

  /// Pulli kutish yonmoqda — mijozga "shoshiling" ogohlantirishi.
  bool get paidWaiting => waiting && currentWaitFee > 0;
}

/// Haydovchining jonli joylashuvi (kuzatuv uchun).
class DriverLoc {
  final double lat;
  final double lng;
  final double? heading;

  const DriverLoc({required this.lat, required this.lng, this.heading});

  factory DriverLoc.fromJson(Map<String, dynamic> json) => DriverLoc(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        heading: (json['heading'] as num?)?.toDouble(),
      );
}

/// Taksi suhbat xabari. senderRole: 'customer' | 'driver'.
class TaxiMessage {
  final String id;
  final String senderRole;
  final String text;
  final String createdAt;

  const TaxiMessage({
    required this.id,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  factory TaxiMessage.fromJson(Map<String, dynamic> json) {
    return TaxiMessage(
      id: json['id'] as String,
      senderRole: (json['senderRole'] as String?) ?? 'customer',
      text: (json['text'] as String?) ?? '',
      createdAt: (json['createdAt'] as String?) ?? '',
    );
  }
}
