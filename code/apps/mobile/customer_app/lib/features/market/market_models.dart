/// Beshariq Market mahsuloti — bosh ekran karuseli uchun (GET /market/products).
class MarketProduct {
  final String id;
  final String name;
  final int price;
  final bool inStock;
  final String? imageUrl;
  final int likesCount;
  final double? ratingAvg;

  const MarketProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.inStock,
    this.imageUrl,
    this.likesCount = 0,
    this.ratingAvg,
  });

  factory MarketProduct.fromJson(Map<String, dynamic> json) {
    final images = (json['imageUrls'] as List?) ?? const [];
    return MarketProduct(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      inStock: (json['inStock'] as bool?) ?? true,
      imageUrl: images.isNotEmpty ? images.first as String : null,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      ratingAvg: (json['ratingAvg'] as num?)?.toDouble(),
    );
  }
}
