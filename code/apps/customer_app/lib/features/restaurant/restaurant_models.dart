// Restaurant katalog modellari (backend javobiga mos). plan/04-backend-services.md

class RestaurantSummary {
  final String id;
  final String name;
  final String address;
  final bool isOpen;
  final double rating;
  final String? logoUrl;

  /// Xaritadagi joylashuvi (admin belgilaydi). 0 bo'lsa — hali belgilanmagan.
  final double lat;
  final double lng;

  const RestaurantSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.isOpen,
    required this.rating,
    this.lat = 0,
    this.lng = 0,
    this.logoUrl,
  });

  /// Xaritada ko'rsatish mumkinmi (joylashuv belgilangan).
  bool get hasLocation => lat != 0 && lng != 0;

  factory RestaurantSummary.fromJson(Map<String, dynamic> json) {
    return RestaurantSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      address: (json['address'] as String?) ?? '',
      isOpen: (json['isOpen'] as bool?) ?? false,
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      lat: ((json['lat'] as num?) ?? 0).toDouble(),
      lng: ((json['lng'] as num?) ?? 0).toDouble(),
      logoUrl: json['logoUrl'] as String?,
    );
  }
}

/// Bosh ekran taomlar lentasi elementi — taom + tegishli oshxona.
class Dish {
  final String id;
  final String name;
  final String? description;
  final int price;
  final String? imageUrl;
  final String restaurantId;
  final String restaurantName;
  final double restaurantRating;
  final double restaurantLat;
  final double restaurantLng;

  const Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantRating,
    required this.restaurantLat,
    required this.restaurantLng,
    this.description,
    this.imageUrl,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      restaurantId: (json['restaurantId'] as String?) ?? '',
      restaurantName: (json['restaurantName'] as String?) ?? '',
      restaurantRating: ((json['restaurantRating'] as num?) ?? 0).toDouble(),
      restaurantLat: ((json['restaurantLat'] as num?) ?? 0).toDouble(),
      restaurantLng: ((json['restaurantLng'] as num?) ?? 0).toDouble(),
    );
  }
}

class MenuItemView {
  final String id;
  final String name;
  final String? description;
  final int price;
  final String? imageUrl;
  final bool isAvailable;

  const MenuItemView({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.description,
    this.imageUrl,
  });

  factory MenuItemView.fromJson(Map<String, dynamic> json) {
    return MenuItemView(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
      isAvailable: (json['isAvailable'] as bool?) ?? true,
    );
  }
}

class MenuCategory {
  final String id;
  final String name;
  final List<MenuItemView> items;

  const MenuCategory({required this.id, required this.name, required this.items});

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      items: ((json['items'] as List?) ?? const [])
          .map((e) => MenuItemView.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RestaurantMenu {
  final RestaurantSummary restaurant;
  final List<MenuCategory> categories;

  const RestaurantMenu({required this.restaurant, required this.categories});

  factory RestaurantMenu.fromJson(Map<String, dynamic> json) {
    return RestaurantMenu(
      restaurant:
          RestaurantSummary.fromJson(json['restaurant'] as Map<String, dynamic>),
      categories: ((json['categories'] as List?) ?? const [])
          .map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
