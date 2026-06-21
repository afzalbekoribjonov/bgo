// Yetkazib berish (kuryer) modellari — Order servisi javobiga mos.

class DeliveryOrder {
  final String id;
  final int publicNo;
  final int total;
  final int courierEarning;
  final String status;
  final String addressText;
  final int itemsCount;

  const DeliveryOrder({
    required this.id,
    required this.publicNo,
    required this.total,
    required this.courierEarning,
    required this.status,
    required this.addressText,
    required this.itemsCount,
  });

  factory DeliveryOrder.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?) ?? const [];
    return DeliveryOrder(
      id: json['id'] as String,
      publicNo: (json['publicNo'] as num).toInt(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      courierEarning: (json['courierEarning'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? '',
      addressText: (json['address']?['text'] as String?) ?? '',
      itemsCount: items.length,
    );
  }
}

/// Bitta vertikal daromadi xulosasi.
class EarningsPart {
  final int count;
  final int earning;
  final int todayEarning;
  final int activeCount;

  const EarningsPart({
    required this.count,
    required this.earning,
    required this.todayEarning,
    required this.activeCount,
  });

  factory EarningsPart.fromJson(Map<String, dynamic>? json) {
    final j = json ?? const {};
    return EarningsPart(
      count: (j['count'] as num?)?.toInt() ?? 0,
      earning: (j['earning'] as num?)?.toInt() ?? 0,
      todayEarning: (j['todayEarning'] as num?)?.toInt() ?? 0,
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
