// Taksi modellari — Order servisi (taxi) javobiga mos.

/// Beshariq ichidagi oldindan belgilangan nuqta (xarita ulanmaguncha).
class TaxiPlace {
  final String label;
  final double lat;
  final double lng;
  const TaxiPlace(this.label, this.lat, this.lng);
}

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
}
