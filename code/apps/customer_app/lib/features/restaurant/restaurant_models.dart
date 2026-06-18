// Restaurant katalog modellari (backend javobiga mos). plan/04-backend-services.md

class RestaurantSummary {
  final String id;
  final String name;
  final String address;
  final bool isOpen;
  final double rating;
  final String? logoUrl;

  const RestaurantSummary({
    required this.id,
    required this.name,
    required this.address,
    required this.isOpen,
    required this.rating,
    this.logoUrl,
  });

  factory RestaurantSummary.fromJson(Map<String, dynamic> json) {
    return RestaurantSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      address: (json['address'] as String?) ?? '',
      isOpen: (json['isOpen'] as bool?) ?? false,
      rating: ((json['rating'] as num?) ?? 0).toDouble(),
      logoUrl: json['logoUrl'] as String?,
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
