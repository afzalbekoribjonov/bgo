// Dostavka (pochta) modellari — Order servisi (parcel) javobiga mos.

enum ParcelSize { small, medium, large }

extension ParcelSizeApi on ParcelSize {
  String get api => switch (this) {
        ParcelSize.small => 'SMALL',
        ParcelSize.medium => 'MEDIUM',
        ParcelSize.large => 'LARGE',
      };
}

class ParcelEstimate {
  final double distanceKm;
  final int fare;

  const ParcelEstimate({required this.distanceKm, required this.fare});

  factory ParcelEstimate.fromJson(Map<String, dynamic> json) {
    return ParcelEstimate(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      fare: (json['fare'] as num?)?.toInt() ?? 0,
    );
  }
}

class ParcelDelivery {
  final String id;
  final int publicNo;
  final String status;
  final int fare;
  final String size;
  final String pickupText;
  final String destinationText;
  final double? pickupLat;
  final double? pickupLng;
  final double? destLat;
  final double? destLng;
  final String recipientName;
  final int? rating;
  final String createdAt;
  /// Kuryer GPS orqali haqiqatda bosib o'tgan masofa (bo'lsa) — narxga
  /// ta'sir qilmaydi, faqat ko'rsatish uchun.
  final double? actualDistanceKm;
  // Jonli (server) maydonlar — kuryer biriktirilganda
  final int currentFare;
  final String? driverName;
  final String? driverCar;
  final String? driverPlate;
  final String? driverPhone; // suhbatdan kuryerga qo'ng'iroq qilish uchun
  final double driverRating;
  final int driverRatingCount;

  const ParcelDelivery({
    required this.id,
    required this.publicNo,
    required this.status,
    required this.fare,
    required this.size,
    required this.pickupText,
    required this.destinationText,
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
    required this.recipientName,
    this.rating,
    this.createdAt = '',
    this.actualDistanceKm,
    this.currentFare = 0,
    this.driverName,
    this.driverCar,
    this.driverPlate,
    this.driverPhone,
    this.driverRating = 0,
    this.driverRatingCount = 0,
  });

  factory ParcelDelivery.fromJson(Map<String, dynamic> json) {
    return ParcelDelivery(
      id: json['id'] as String,
      publicNo: (json['publicNo'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'PENDING',
      fare: (json['fare'] as num?)?.toInt() ?? 0,
      size: (json['size'] as String?) ?? 'SMALL',
      pickupText: (json['pickup']?['text'] as String?) ?? '',
      destinationText: (json['destination']?['text'] as String?) ?? '',
      pickupLat: (json['pickup']?['lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup']?['lng'] as num?)?.toDouble(),
      destLat: (json['destination']?['lat'] as num?)?.toDouble(),
      destLng: (json['destination']?['lng'] as num?)?.toDouble(),
      recipientName: (json['recipientName'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as String?) ?? '',
      actualDistanceKm: (json['actualDistanceKm'] as num?)?.toDouble(),
      currentFare: (json['currentFare'] as num?)?.toInt() ?? 0,
      driverName: json['driverName'] as String?,
      driverCar: json['driverCar'] as String?,
      driverPlate: json['driverPlate'] as String?,
      driverPhone: json['driverPhone'] as String?,
      driverRating: (json['driverRating'] as num?)?.toDouble() ?? 0,
      driverRatingCount: (json['driverRatingCount'] as num?)?.toInt() ?? 0,
    );
  }

  static const _activeStatuses = [
    'PENDING',
    'ACCEPTED',
    'ARRIVED',
    'PICKED_UP',
    'IN_TRANSIT',
  ];

  bool get isActive => _activeStatuses.contains(status);
  bool get isCancellable =>
      status == 'PENDING' || status == 'ACCEPTED' || status == 'ARRIVED';
  bool get hasDriver => (driverName ?? '').isNotEmpty;
  int get displayFare => currentFare > 0 ? currentFare : fare;
}
