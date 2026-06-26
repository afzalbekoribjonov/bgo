import 'package:flutter/material.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import 'restaurant_menu_screen.dart';
import 'restaurant_models.dart';

/// Nomdan barqaror rang — rasm yo'qligida chiroyli banner uchun.
Color restaurantAccent(String name) {
  final hue = (name.hashCode % 360).abs().toDouble();
  return HSLColor.fromAHSL(1, hue, 0.5, 0.5).toColor();
}

/// Taom nomidan barqaror "ishtaha ochuvchi" rang (rasm yo'qligida).
Color dishAccent(String name) {
  final hue = (name.hashCode % 360).abs().toDouble();
  return HSLColor.fromAHSL(1, hue, 0.55, 0.46).toColor();
}

void openRestaurant(BuildContext context, RestaurantSummary r) {
  openRestaurantById(context, r.id, r.name);
}

/// id + nom orqali oshxona menyusiga o'tish (taom kartasidan ham ishlatiladi).
void openRestaurantById(BuildContext context, String id, String name) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => RestaurantMenuScreen(restaurantId: id, restaurantName: name),
    ),
  );
}

Widget _statusPill(BuildContext context, String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600)),
  );
}

Widget _ratingPill(BuildContext context, double rating) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.star, size: 15, color: Colors.amber),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1),
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    ),
  );
}

Widget _banner(String name, {double height = 110}) {
  final accent = restaurantAccent(name);
  return Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: [accent, accent.withValues(alpha: 0.65)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: const Center(
      child: Icon(Icons.restaurant_menu, size: 50, color: Colors.white70),
    ),
  );
}

/// Katta (vertikal) oshxona kartasi — ro'yxat va bosh ekran uchun.
class RestaurantCard extends StatelessWidget {
  final RestaurantSummary restaurant;
  const RestaurantCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => openRestaurant(context, restaurant),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _banner(restaurant.name),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _statusPill(
                      context,
                      restaurant.isOpen ? t.open : t.closed,
                      restaurant.isOpen ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(restaurant.name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        _ratingPill(context, restaurant.rating),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 15, color: scheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(restaurant.address,
                              style:
                                  TextStyle(color: scheme.outline, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Taom kartasi (bosh ekran 2-ustunli grid) — bosilsa o'sha oshxona menyusi.
class DishCard extends StatelessWidget {
  final Dish dish;
  const DishCard({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = dishAccent(dish.name);
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () =>
            openRestaurantById(context, dish.restaurantId, dish.restaurantName),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rasm yoki gradient banner + reyting
            Stack(
              children: [
                SizedBox(
                  height: 104,
                  width: double.infinity,
                  child: _dishImage(accent),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: _ratingPill(context, dish.restaurantRating),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dish.name,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.storefront_outlined,
                          size: 13, color: scheme.outline),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(dish.restaurantName,
                            style:
                                TextStyle(color: scheme.outline, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          AppLocalizations.of(context)!
                              .priceSom(groupThousands(dish.price)),
                          style: TextStyle(
                              color: scheme.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.add,
                            size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dishImage(Color accent) {
    final fallback = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accent, accent.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.lunch_dining, size: 40, color: Colors.white70),
      ),
    );
    final url = dish.imageUrl;
    if (url == null || url.isEmpty) return fallback;
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}

/// Ixcham (gorizontal lenta) oshxona kartasi — "Mashhur" bo'limi uchun.
class RestaurantMiniCard extends StatelessWidget {
  final RestaurantSummary restaurant;
  const RestaurantMiniCard({super.key, required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 180,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => openRestaurant(context, restaurant),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  _banner(restaurant.name, height: 90),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ratingPill(context, restaurant.rating),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(restaurant.name,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(restaurant.address,
                        style: TextStyle(color: scheme.outline, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
