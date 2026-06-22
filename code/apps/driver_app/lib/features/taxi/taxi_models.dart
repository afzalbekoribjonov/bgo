// Taksi safari modeli — Order servisi (taxi) javobiga mos.

class TaxiTrip {
  final String id;
  final int publicNo;
  final String status;
  final bool metered; // manzilsiz: narx yakunda masofadan
  final int fare;
  final int driverEarning;
  final double distanceKm;
  final String pickupText;
  final String destinationText;

  const TaxiTrip({
    required this.id,
    required this.publicNo,
    required this.status,
    required this.metered,
    required this.fare,
    required this.driverEarning,
    required this.distanceKm,
    required this.pickupText,
    required this.destinationText,
  });

  factory TaxiTrip.fromJson(Map<String, dynamic> json) {
    return TaxiTrip(
      id: json['id'] as String,
      publicNo: (json['publicNo'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'PENDING',
      metered: (json['metered'] as bool?) ?? false,
      fare: (json['fare'] as num?)?.toInt() ?? 0,
      driverEarning: (json['driverEarning'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      pickupText: (json['pickup']?['text'] as String?) ?? '',
      destinationText: (json['destination']?['text'] as String?) ?? '',
    );
  }
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
      senderRole: (json['senderRole'] as String?) ?? 'driver',
      text: (json['text'] as String?) ?? '',
      createdAt: (json['createdAt'] as String?) ?? '',
    );
  }
}
