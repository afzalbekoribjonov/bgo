// Taksi modellari — Order servisi (taxi) javobiga mos.
// Nuqta tipi: GeoPlace (lib/core/places.dart) — taksi va dostavka uchun umumiy.

class TaxiEstimate {
  final double distanceKm;
  final int fare;
  final int commission;
  final int driverEarning;

  const TaxiEstimate({
    required this.distanceKm,
    required this.fare,
    required this.commission,
    required this.driverEarning,
  });

  factory TaxiEstimate.fromJson(Map<String, dynamic> json) {
    return TaxiEstimate(
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      fare: (json['fare'] as num?)?.toInt() ?? 0,
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
  final String pickupText;
  final String destinationText;

  const TaxiTrip({
    required this.id,
    required this.publicNo,
    required this.status,
    required this.fare,
    required this.distanceKm,
    required this.pickupText,
    required this.destinationText,
  });

  factory TaxiTrip.fromJson(Map<String, dynamic> json) {
    return TaxiTrip(
      id: json['id'] as String,
      publicNo: (json['publicNo'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'PENDING',
      fare: (json['fare'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      pickupText: (json['pickup']?['text'] as String?) ?? '',
      destinationText: (json['destination']?['text'] as String?) ?? '',
    );
  }

  bool get isActive =>
      status == 'PENDING' || status == 'ACCEPTED' || status == 'IN_PROGRESS';
  bool get isCancellable => status == 'PENDING' || status == 'ACCEPTED';

  /// Suhbat haydovchi biriktirilgach (ACCEPTED) ochiq, yakuniygacha.
  bool get hasChat => status == 'ACCEPTED' || status == 'IN_PROGRESS';
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
