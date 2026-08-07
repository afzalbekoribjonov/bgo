import '../kitchen/kitchen_models.dart' show I18nText;

export '../kitchen/kitchen_models.dart' show I18nText;

class SellerProduct {
  final String id;
  final String? categoryId;
  final I18nText name;
  final I18nText? description;
  final int price;
  final List<String> imageUrls;
  final List<String> sizes;
  final double? ratingAvg;
  final bool isActive;
  const SellerProduct({
    required this.id,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.imageUrls,
    required this.sizes,
    this.ratingAvg,
    required this.isActive,
  });

  factory SellerProduct.fromJson(Map<String, dynamic> j) => SellerProduct(
        id: j['id'] as String,
        categoryId: j['categoryId'] as String?,
        name: I18nText.fromJson((j['name'] as Map?)?.cast<String, dynamic>() ?? const {}),
        description: j['description'] != null
            ? I18nText.fromJson((j['description'] as Map).cast<String, dynamic>())
            : null,
        price: (j['price'] as num).toInt(),
        imageUrls: ((j['imageUrls'] as List?) ?? const []).cast<String>(),
        sizes: ((j['sizes'] as List?) ?? const []).cast<String>(),
        ratingAvg: (j['ratingAvg'] as num?)?.toDouble(),
        isActive: (j['isActive'] as bool?) ?? true,
      );
}

class SellerCategory {
  final String id;
  final String name;
  final int sortOrder;
  const SellerCategory({required this.id, required this.name, required this.sortOrder});

  factory SellerCategory.fromJson(Map<String, dynamic> j) => SellerCategory(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
      );
}

class SellerProfile {
  final String id;
  final String name;
  final String? description;
  final String contactPhone;
  final String sellerType; // 'SHOP' | 'CONSTRUCTION'
  final String? address;
  final double? lat;
  final double? lng;
  final bool isActive;
  const SellerProfile({
    required this.id,
    required this.name,
    this.description,
    required this.contactPhone,
    required this.sellerType,
    this.address,
    this.lat,
    this.lng,
    required this.isActive,
  });

  factory SellerProfile.fromJson(Map<String, dynamic> j) => SellerProfile(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        description: j['description'] as String?,
        contactPhone: (j['contactPhone'] as String?) ?? '',
        sellerType: (j['sellerType'] as String?) ?? 'SHOP',
        address: j['address'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        isActive: (j['isActive'] as bool?) ?? true,
      );
}

class SellerChatThread {
  final String customerId;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unseenCount;
  const SellerChatThread({
    required this.customerId,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unseenCount,
  });

  factory SellerChatThread.fromJson(Map<String, dynamic> j) => SellerChatThread(
        customerId: j['customerId'] as String,
        lastMessage: (j['lastMessage'] as String?) ?? '',
        lastMessageAt: DateTime.tryParse(j['lastMessageAt'] as String? ?? '') ?? DateTime.now(),
        unseenCount: (j['unseenCount'] as num?)?.toInt() ?? 0,
      );
}

class SellerChatMessage {
  final String id;
  final String senderRole; // 'CUSTOMER' | 'SELLER'
  final String text;
  final DateTime createdAt;
  const SellerChatMessage({required this.id, required this.senderRole, required this.text, required this.createdAt});

  bool get isFromSeller => senderRole == 'SELLER';

  factory SellerChatMessage.fromJson(Map<String, dynamic> j) => SellerChatMessage(
        id: j['id'] as String,
        senderRole: (j['senderRole'] as String?) ?? 'CUSTOMER',
        text: (j['text'] as String?) ?? '',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}
