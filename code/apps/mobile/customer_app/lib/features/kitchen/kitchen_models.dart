/// Ko'p tilli matn (uz majburiy, uz_Cyrl/ru ixtiyoriy) — menyu nomi/tavsifi
/// kabi maydonlar uchun, oshxona egasi barcha tillarni tahrirlashi mumkin.
class I18nText {
  final String uz;
  final String? uzCyrl;
  final String? ru;
  const I18nText({required this.uz, this.uzCyrl, this.ru});

  factory I18nText.fromJson(Map<String, dynamic> j) => I18nText(
        uz: (j['uz'] as String?) ?? '',
        uzCyrl: j['uz_Cyrl'] as String?,
        ru: j['ru'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'uz': uz,
        if (uzCyrl != null && uzCyrl!.isNotEmpty) 'uz_Cyrl': uzCyrl,
        if (ru != null && ru!.isNotEmpty) 'ru': ru,
      };

  static const empty = I18nText(uz: '');
}

class KitchenRestaurant {
  final String id;
  final String name;
  final String address;
  final bool isOpen;
  final double rating;
  final String? logoUrl;
  const KitchenRestaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.isOpen,
    required this.rating,
    this.logoUrl,
  });

  factory KitchenRestaurant.fromJson(Map<String, dynamic> j) => KitchenRestaurant(
        id: j['id'] as String,
        name: j['name'] as String,
        address: (j['address'] as String?) ?? '',
        isOpen: (j['isOpen'] as bool?) ?? false,
        rating: ((j['rating'] as num?) ?? 0).toDouble(),
        logoUrl: j['logoUrl'] as String?,
      );
}

class KitchenCategory {
  final String id;
  final I18nText name;
  final int sortOrder;
  const KitchenCategory({required this.id, required this.name, required this.sortOrder});

  factory KitchenCategory.fromJson(Map<String, dynamic> j) => KitchenCategory(
        id: j['id'] as String,
        name: I18nText.fromJson((j['name'] as Map?)?.cast<String, dynamic>() ?? const {}),
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class KitchenMenuItem {
  final String id;
  final String categoryId;
  final I18nText name;
  final I18nText? description;
  final int price;
  final String? imageUrl;
  final bool isAvailable;
  const KitchenMenuItem({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.isAvailable,
  });

  factory KitchenMenuItem.fromJson(Map<String, dynamic> j) => KitchenMenuItem(
        id: j['id'] as String,
        categoryId: j['categoryId'] as String,
        name: I18nText.fromJson((j['name'] as Map?)?.cast<String, dynamic>() ?? const {}),
        description: j['description'] != null
            ? I18nText.fromJson((j['description'] as Map).cast<String, dynamic>())
            : null,
        price: (j['price'] as num).toInt(),
        imageUrl: j['imageUrl'] as String?,
        isAvailable: (j['isAvailable'] as bool?) ?? true,
      );
}

class KitchenOrderItem {
  final String nameSnapshot;
  final int qty;
  final int lineTotal;
  const KitchenOrderItem({required this.nameSnapshot, required this.qty, required this.lineTotal});

  factory KitchenOrderItem.fromJson(Map<String, dynamic> j) => KitchenOrderItem(
        nameSnapshot: (j['nameSnapshot'] as String?) ?? '',
        qty: (j['qty'] as num?)?.toInt() ?? 0,
        lineTotal: (j['lineTotal'] as num?)?.toInt() ?? 0,
      );
}

enum KitchenOrderStatus {
  pending,
  accepted,
  preparing,
  ready,
  assigned,
  inProgress,
  pickedUp,
  delivered,
  completed,
  cancelled,
  failed,
  unknown,
}

KitchenOrderStatus _statusFromString(String? s) {
  switch (s) {
    case 'PENDING':
      return KitchenOrderStatus.pending;
    case 'ACCEPTED':
      return KitchenOrderStatus.accepted;
    case 'PREPARING':
      return KitchenOrderStatus.preparing;
    case 'READY':
      return KitchenOrderStatus.ready;
    case 'ASSIGNED':
      return KitchenOrderStatus.assigned;
    case 'IN_PROGRESS':
      return KitchenOrderStatus.inProgress;
    case 'PICKED_UP':
      return KitchenOrderStatus.pickedUp;
    case 'DELIVERED':
      return KitchenOrderStatus.delivered;
    case 'COMPLETED':
      return KitchenOrderStatus.completed;
    case 'CANCELLED':
      return KitchenOrderStatus.cancelled;
    case 'FAILED':
      return KitchenOrderStatus.failed;
    default:
      return KitchenOrderStatus.unknown;
  }
}

/// Mijoz ismi/telefoni — oshxona egasi bog'lanishi uchun.
class KitchenCustomerInfo {
  final String? name;
  final String? phone;
  const KitchenCustomerInfo({this.name, this.phone});

  factory KitchenCustomerInfo.fromJson(Map<String, dynamic>? j) => KitchenCustomerInfo(
        name: j?['name'] as String?,
        phone: j?['phone'] as String?,
      );
}

/// Haydovchi ismi/telefoni/mashinasi/reytingi — kuryer biriktirilgach.
class KitchenDriverInfo {
  final String? name;
  final String? phone;
  final String? car;
  final String? plate;
  final double? rating;
  const KitchenDriverInfo({this.name, this.phone, this.car, this.plate, this.rating});

  factory KitchenDriverInfo.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const KitchenDriverInfo();
    return KitchenDriverInfo(
      name: j['name'] as String?,
      phone: j['phone'] as String?,
      car: j['car'] as String?,
      plate: j['plate'] as String?,
      rating: (j['rating'] as num?)?.toDouble(),
    );
  }
}

class KitchenOrder {
  final String id;
  final int publicNo;
  final List<KitchenOrderItem> items;
  final int itemsTotal;
  final int deliveryFee;
  final int total;
  final KitchenOrderStatus status;
  final String? driverId;
  final DateTime? kitchenAcceptedAt;
  final String addressText;
  final DateTime createdAt;
  final KitchenCustomerInfo customer;
  final KitchenDriverInfo? driver;
  const KitchenOrder({
    required this.id,
    required this.publicNo,
    required this.items,
    required this.itemsTotal,
    required this.deliveryFee,
    required this.total,
    required this.status,
    this.driverId,
    this.kitchenAcceptedAt,
    required this.addressText,
    required this.createdAt,
    this.customer = const KitchenCustomerInfo(),
    this.driver,
  });

  /// Oshxona qabul qilgan, lekin hali kuryer topilmagan — "kuryer qidirilmoqda"
  /// holatini "yangi buyurtma" dan ajratish uchun (restaurant_web bilan bir xil).
  bool get isAwaitingDriver =>
      status == KitchenOrderStatus.pending && kitchenAcceptedAt != null && driverId == null;

  factory KitchenOrder.fromJson(Map<String, dynamic> j) => KitchenOrder(
        id: j['id'] as String,
        publicNo: (j['publicNo'] as num?)?.toInt() ?? 0,
        items: ((j['items'] as List?) ?? const [])
            .map((e) => KitchenOrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        itemsTotal: (j['itemsTotal'] as num?)?.toInt() ?? 0,
        deliveryFee: (j['deliveryFee'] as num?)?.toInt() ?? 0,
        total: (j['total'] as num?)?.toInt() ?? 0,
        status: _statusFromString(j['status'] as String?),
        driverId: j['driverId'] as String?,
        kitchenAcceptedAt: j['kitchenAcceptedAt'] != null
            ? DateTime.tryParse(j['kitchenAcceptedAt'] as String)
            : null,
        addressText: (j['address'] as Map?)?['text'] as String? ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        customer: KitchenCustomerInfo.fromJson((j['customer'] as Map?)?.cast<String, dynamic>()),
        driver: j['driver'] != null
            ? KitchenDriverInfo.fromJson((j['driver'] as Map).cast<String, dynamic>())
            : null,
      );
}

class KitchenOrderMessage {
  final String id;
  final String senderRole; // 'kitchen' | 'driver'
  final String text;
  final DateTime createdAt;
  const KitchenOrderMessage({
    required this.id,
    required this.senderRole,
    required this.text,
    required this.createdAt,
  });

  bool get isFromKitchen => senderRole == 'kitchen';

  factory KitchenOrderMessage.fromJson(Map<String, dynamic> j) => KitchenOrderMessage(
        id: j['id'] as String,
        senderRole: (j['senderRole'] as String?) ?? 'driver',
        text: (j['text'] as String?) ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class WeeklyPoint {
  final DateTime date;
  final int orders;
  final int revenue;
  const WeeklyPoint({required this.date, required this.orders, required this.revenue});

  factory WeeklyPoint.fromJson(Map<String, dynamic> j) => WeeklyPoint(
        date: DateTime.tryParse(j['date'] as String? ?? '') ?? DateTime.now(),
        orders: (j['orders'] as num?)?.toInt() ?? 0,
        revenue: (j['revenue'] as num?)?.toInt() ?? 0,
      );
}

class KitchenStats {
  final int totalOrders;
  final int totalDelivered;
  final int totalRevenue;
  final int todayOrders;
  final int todayDelivered;
  final int todayRevenue;
  final int cancelledToday;
  final int avgOrderValue;
  final List<WeeklyPoint> weekly;
  const KitchenStats({
    required this.totalOrders,
    required this.totalDelivered,
    required this.totalRevenue,
    required this.todayOrders,
    required this.todayDelivered,
    required this.todayRevenue,
    required this.cancelledToday,
    required this.avgOrderValue,
    required this.weekly,
  });

  factory KitchenStats.fromJson(Map<String, dynamic> j) => KitchenStats(
        totalOrders: (j['totalOrders'] as num?)?.toInt() ?? 0,
        totalDelivered: (j['totalDelivered'] as num?)?.toInt() ?? 0,
        totalRevenue: (j['totalRevenue'] as num?)?.toInt() ?? 0,
        todayOrders: (j['todayOrders'] as num?)?.toInt() ?? 0,
        todayDelivered: (j['todayDelivered'] as num?)?.toInt() ?? 0,
        todayRevenue: (j['todayRevenue'] as num?)?.toInt() ?? 0,
        cancelledToday: (j['cancelledToday'] as num?)?.toInt() ?? 0,
        avgOrderValue: (j['avgOrderValue'] as num?)?.toInt() ?? 0,
        weekly: ((j['weekly'] as List?) ?? const [])
            .map((e) => WeeklyPoint.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
