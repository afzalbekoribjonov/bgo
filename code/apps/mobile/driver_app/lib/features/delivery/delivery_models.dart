// Yetkazib berish (kuryer) modellari — Order servisi javobiga mos.

class DeliveryOrder {
  final String id;
  final int publicNo;
  final int total;
  final int courierEarning;
  final String status;
  final String addressText;
  final int itemsCount;

  /// Mijoz manzili koordinatasi (GPS checkout bo'lsa) — yetkazish nuqtasi.
  final double? addressLat;
  final double? addressLng;

  /// Oshxona (olib ketish nuqtasi) — backend boyitadi (restaurant obyekti).
  final String? restaurantName;
  final double? restaurantLat;
  final double? restaurantLng;

  const DeliveryOrder({
    required this.id,
    required this.publicNo,
    required this.total,
    required this.courierEarning,
    required this.status,
    required this.addressText,
    required this.itemsCount,
    this.addressLat,
    this.addressLng,
    this.restaurantName,
    this.restaurantLat,
    this.restaurantLng,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?) ?? const [];
    final address = json['address'] as Map<String, dynamic>?;
    final restaurant = json['restaurant'] as Map<String, dynamic>?;
    return DeliveryOrder(
      id: json['id'] as String,
      publicNo: (json['publicNo'] as num).toInt(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      courierEarning: (json['courierEarning'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? '',
      addressText: (address?['text'] as String?) ?? '',
      itemsCount: items.length,
      addressLat: (address?['lat'] as num?)?.toDouble(),
      addressLng: (address?['lng'] as num?)?.toDouble(),
      restaurantName: restaurant?['name'] as String?,
      restaurantLat: (restaurant?['lat'] as num?)?.toDouble(),
      restaurantLng: (restaurant?['lng'] as num?)?.toDouble(),
    );
  }
}

/// Bitta vertikal daromadi xulosasi.
class EarningsPart {
  final int count;
  final int earning;
  final int todayEarning;
  final int todayCount;
  final int activeCount;

  const EarningsPart({
    required this.count,
    required this.earning,
    required this.todayEarning,
    required this.todayCount,
    required this.activeCount,
  });

  factory EarningsPart.fromJson(Map<String, dynamic>? json) {
    final j = json ?? const {};
    return EarningsPart(
      count: (j['count'] as num?)?.toInt() ?? 0,
      earning: (j['earning'] as num?)?.toInt() ?? 0,
      todayEarning: (j['todayEarning'] as num?)?.toInt() ?? 0,
      todayCount: (j['todayCount'] as num?)?.toInt() ?? 0,
      activeCount: (j['activeCount'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Haydovchi daromadi — /courier/earnings javobi (uchala vertikal).
class DriverEarnings {
  final EarningsPart food;
  final EarningsPart taxi;
  final EarningsPart parcel;
  final EarningsPart total;

  const DriverEarnings({
    required this.food,
    required this.taxi,
    required this.parcel,
    required this.total,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      food: EarningsPart.fromJson(json['food'] as Map<String, dynamic>?),
      taxi: EarningsPart.fromJson(json['taxi'] as Map<String, dynamic>?),
      parcel: EarningsPart.fromJson(json['parcel'] as Map<String, dynamic>?),
      total: EarningsPart.fromJson(json['total'] as Map<String, dynamic>?),
    );
  }
}
