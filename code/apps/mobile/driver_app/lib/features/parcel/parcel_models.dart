// Dostavka (pochta) modeli — Order servisi (parcel) javobiga mos.

class ParcelDelivery {
  final String id;
  final int publicNo;
  final String status;
  final int fare;
  final int driverEarning;
  final double distanceKm;
  final String size;
  final String pickupText;
  final String destinationText;
  final String recipientName;
  final String recipientPhone;
  final double? pickupLat, pickupLng, destLat, destLng;

  const ParcelDelivery({
    required this.id,
    required this.publicNo,
    required this.status,
    required this.fare,
    required this.driverEarning,
    required this.distanceKm,
    required this.size,
    required this.pickupText,
    required this.destinationText,
    required this.recipientName,
    required this.recipientPhone,
    this.pickupLat,
    this.pickupLng,
    this.destLat,
    this.destLng,
  });

  factory ParcelDelivery.fromJson(Map<String, dynamic> json) {
    return ParcelDelivery(
      id: json['id'] as String,
      publicNo: (json['publicNo'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'PENDING',
      fare: (json['fare'] as num?)?.toInt() ?? 0,
      driverEarning: (json['driverEarning'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      size: (json['size'] as String?) ?? 'SMALL',
      pickupText: (json['pickup']?['text'] as String?) ?? '',
      destinationText: (json['destination']?['text'] as String?) ?? '',
      recipientName: (json['recipientName'] as String?) ?? '',
      recipientPhone: (json['recipientPhone'] as String?) ?? '',
      pickupLat: (json['pickup']?['lat'] as num?)?.toDouble(),
      pickupLng: (json['pickup']?['lng'] as num?)?.toDouble(),
      destLat: (json['destination']?['lat'] as num?)?.toDouble(),
      destLng: (json['destination']?['lng'] as num?)?.toDouble(),
    );
  }
}
