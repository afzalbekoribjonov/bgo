// Taksi safari modeli — Order servisi (taxi) javobiga mos.

class TaxiTrip {
  final String id;
  final int publicNo;
  final String status;
  final int fare;
  final int driverEarning;
  final double distanceKm;
  final String pickupText;
  final String destinationText;

  const TaxiTrip({
    required this.id,
    required this.publicNo,
    required this.status,
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
      fare: (json['fare'] as num?)?.toInt() ?? 0,
      driverEarning: (json['driverEarning'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      pickupText: (json['pickup']?['text'] as String?) ?? '',
      destinationText: (json['destination']?['text'] as String?) ?? '',
    );
  }
}
