// Buyurtma modellari (Order servisi javobiga mos). plan/04-backend-services.md

class OrderItemView {
  final String name;
  final int qty;
  final int lineTotal;

  const OrderItemView({
    required this.name,
    required this.qty,
    required this.lineTotal,
  });

  factory OrderItemView.fromJson(Map<String, dynamic> json) {
    return OrderItemView(
      name: (json['nameSnapshot'] as String?) ?? '',
      qty: (json['qty'] as num).toInt(),
      lineTotal: (json['lineTotal'] as num).toInt(),
    );
  }
}

class OrderView {
  final String id;
  final int publicNo;
  final List<OrderItemView> items;
  final int itemsTotal;
  final int deliveryFee;
  final int total;
  final String status;
  final String addressText;
  final String createdAt;

  const OrderView({
    required this.id,
    required this.publicNo,
    required this.items,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    required this.addressText,
    required this.createdAt,
  });

  factory OrderView.fromJson(Map<String, dynamic> json) {
    return OrderView(
      id: json['id'] as String,
      publicNo: (json['publicNo'] as num).toInt(),
      items: ((json['items'] as List?) ?? const [])
          .map((e) => OrderItemView.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemsTotal: (json['itemsTotal'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'PENDING',
      addressText: (json['address']?['text'] as String?) ?? '',
      createdAt: (json['createdAt'] as String?) ?? '',
    );
  }
}
