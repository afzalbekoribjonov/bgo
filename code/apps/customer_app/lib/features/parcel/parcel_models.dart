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
  final String recipientName;

  const ParcelDelivery({
    required this.id,
    required this.publicNo,
    required this.status,
    required this.fare,
    required this.size,
    required this.pickupText,
    required this.destinationText,
    required this.recipientName,
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
      recipientName: (json['recipientName'] as String?) ?? '',
    );
  }

  bool get isCancellable => status == 'PENDING' || status == 'ACCEPTED';
}
