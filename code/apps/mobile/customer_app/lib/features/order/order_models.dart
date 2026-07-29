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
  final int serviceFee;
  final int deliveryFee;
  final int discount;
  final int total;
  final String status;
  final String addressText;
  final double? addressLat;
  final double? addressLng;
  final int? rating;
  final String createdAt;
  // Ikki tomonlama qabul holati
  final bool kitchenAccepted;
  final bool hasDriver;
  // Jonli (/orders/:id/live) — oshxona + kuryer ma'lumoti
  final String? restaurantName;
  final double? restaurantLat;
  final double? restaurantLng;
  final String? driverName;
  final String? driverCar;
  final String? driverPlate;
  final String? driverPhone;
  final double? driverLat;
  final double? driverLng;

  const OrderView({
    required this.id,
    required this.publicNo,
    required this.items,
    required this.itemsTotal,
    required this.serviceFee,
    required this.deliveryFee,
    required this.discount,
    required this.total,
    required this.status,
    required this.addressText,
    required this.createdAt,
    this.addressLat,
    this.addressLng,
    this.rating,
    this.kitchenAccepted = false,
    this.hasDriver = false,
    this.restaurantName,
    this.restaurantLat,
    this.restaurantLng,
    this.driverName,
    this.driverCar,
    this.driverPlate,
    this.driverPhone,
    this.driverLat,
    this.driverLng,
  });

  bool get isActive => const [
        'PENDING',
        'ACCEPTED',
        'PREPARING',
        'READY',
        'ASSIGNED',
        'IN_PROGRESS',
        'PICKED_UP',
      ].contains(status);
  bool get isDone => status == 'DELIVERED' || status == 'COMPLETED';
  bool get isCancelled => status == 'CANCELLED' || status == 'FAILED';

  factory OrderView.fromJson(Map<String, dynamic> json) {
    final r = json['restaurant'] as Map<String, dynamic>?;
    final d = json['driver'] as Map<String, dynamic>?;
    final dl = json['driverLocation'] as Map<String, dynamic>?;
    return OrderView(
      id: json['id'] as String,
      publicNo: (json['publicNo'] as num).toInt(),
      items: ((json['items'] as List?) ?? const [])
          .map((e) => OrderItemView.fromJson(e as Map<String, dynamic>))
          .toList(),
      itemsTotal: (json['itemsTotal'] as num?)?.toInt() ?? 0,
      serviceFee: (json['serviceFee'] as num?)?.toInt() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toInt() ?? 0,
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      total: (json['total'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'PENDING',
      addressText: (json['address']?['text'] as String?) ?? '',
      addressLat: (json['address']?['lat'] as num?)?.toDouble(),
      addressLng: (json['address']?['lng'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toInt(),
      createdAt: (json['createdAt'] as String?) ?? '',
      kitchenAccepted: json['kitchenAcceptedAt'] != null,
      hasDriver: json['driverId'] != null,
      restaurantName: r?['name'] as String?,
      restaurantLat: (r?['lat'] as num?)?.toDouble(),
      restaurantLng: (r?['lng'] as num?)?.toDouble(),
      driverName: d?['name'] as String?,
      driverCar: d?['car'] as String?,
      driverPlate: d?['plate'] as String?,
      driverPhone: d?['phone'] as String?,
      driverLat: (dl?['lat'] as num?)?.toDouble(),
      driverLng: (dl?['lng'] as num?)?.toDouble(),
    );
  }
}
