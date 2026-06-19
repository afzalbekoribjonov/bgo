// Yetkazib berish (kuryer) modellari — Order servisi javobiga mos.

class DeliveryOrder {
  final String id;
  final int publicNo;
  final int total;
  final String status;
  final String addressText;
  final int itemsCount;

  const DeliveryOrder({
    required this.id,
    required this.publicNo,
    required this.total,
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
      status: (json['status'] as String?) ?? '',
      addressText: (json['address']?['text'] as String?) ?? '',
      itemsCount: items.length,
    );
  }
}
