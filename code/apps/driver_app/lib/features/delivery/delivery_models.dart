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

/// Haydovchi daromadi — /courier/earnings javobi.
class DriverEarnings {
  final int deliveredCount;
  final int totalEarning;
  final int todayDeliveredCount;
  final int todayEarning;
  final int activeCount;

  const DriverEarnings({
    required this.deliveredCount,
    required this.totalEarning,
    required this.todayDeliveredCount,
    required this.todayEarning,
    required this.activeCount,
  });

  factory DriverEarnings.fromJson(Map<String, dynamic> json) {
    return DriverEarnings(
      deliveredCount: (json['deliveredCount'] as num?)?.toInt() ?? 0,
      totalEarning: (json['totalEarning'] as num?)?.toInt() ?? 0,
      todayDeliveredCount: (json['todayDeliveredCount'] as num?)?.toInt() ?? 0,
      todayEarning: (json['todayEarning'] as num?)?.toInt() ?? 0,
      activeCount: (json['activeCount'] as num?)?.toInt() ?? 0,
    );
  }
}
