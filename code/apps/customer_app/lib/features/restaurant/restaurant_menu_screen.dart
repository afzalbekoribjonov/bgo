import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_screen.dart';
import 'restaurant_api.dart';
import 'restaurant_card.dart';
import 'restaurant_models.dart';

/// Oshxona menyusi — gradient banner + chiroyli taom kartalari. plan/05-customer-app.md
class RestaurantMenuScreen extends ConsumerWidget {
  final String restaurantId;
  final String restaurantName;

  const RestaurantMenuScreen({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(menuProvider(restaurantId));
    final cart = ref.watch(cartProvider);

    void addToCart(MenuItemView item) {
      final replaced = ref.read(cartProvider.notifier).addItem(
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            menuItemId: item.id,
            name: item.name,
            price: item.price,
          );
      if (replaced) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.cartUpdatedNewRestaurant)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} — ${t.cart}'),
            duration: const Duration(milliseconds: 900),
          ),
        );
      }
    }

    final showCartBar = !cart.isEmpty && cart.restaurantId == restaurantId;

    return Scaffold(
      body: async.when(
        loading: () => CustomScrollView(slivers: [
          _appBar(context, rating: null, address: null),
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          ),
        ]),
        error: (e, _) => CustomScrollView(slivers: [
          _appBar(context, rating: null, address: null),
          SliverFillRemaining(
            hasScrollBody: false,
            child: AsyncErrorRetry(
              error: e,
              onRetry: () => ref.invalidate(menuProvider(restaurantId)),
            ),
          ),
        ]),
        data: (menu) {
          final categories =
              menu.categories.where((c) => c.items.isNotEmpty).toList();
          return CustomScrollView(
            slivers: [
              _appBar(context,
                  rating: menu.restaurant.rating,
                  address: menu.restaurant.address,
                  isOpen: menu.restaurant.isOpen),
              if (categories.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text(t.emptyMenu)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 96, top: 4),
                  sliver: SliverList.list(
                    children: [
                      for (final category in categories) ...[
                        _categoryHeader(context, category.name),
                        for (final item in category.items)
                          _MenuItemCard(
                            item: item,
                            onAdd:
                                item.isAvailable ? () => addToCart(item) : null,
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: showCartBar
          ? _CartBar(
              itemCount: cart.itemCount,
              subtotal: cart.subtotal,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ),
            )
          : null,
    );
  }

  Widget _appBar(BuildContext context,
      {double? rating, String? address, bool isOpen = true}) {
    final accent = restaurantAccent(restaurantName);
    return SliverAppBar(
      expandedHeight: 170,
      pinned: true,
      foregroundColor: Colors.white,
      backgroundColor: accent,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
        title: Text(restaurantName,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [accent, accent.withValues(alpha: 0.6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                right: 16,
                bottom: 40,
                child: Icon(Icons.restaurant_menu,
                    size: 90, color: Colors.white24),
              ),
              Positioned(
                left: 16,
                bottom: 46,
                child: Row(
                  children: [
                    if (rating != null) ...[
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(rating.toStringAsFixed(1),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                    ],
                    if (address != null && address.isNotEmpty)
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryHeader(BuildContext context, String name) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(name,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  final MenuItemView item;
  final VoidCallback? onAdd;

  const _MenuItemCard({required this.item, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final disabled = !item.isAvailable;
    final accent = restaurantAccent(item.name);

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Card(
        margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onAdd,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                // Taom rasmi (placeholder gradient)
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fastfood,
                      color: Colors.white70, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (item.description != null &&
                          item.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(item.description!,
                            style:
                                TextStyle(color: scheme.outline, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        disabled
                            ? t.unavailable
                            : t.priceSom(groupThousands(item.price)),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: disabled ? scheme.error : scheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!disabled)
                  IconButton.filled(
                    icon: const Icon(Icons.add),
                    onPressed: onAdd,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final int itemCount;
  final int subtotal;
  final VoidCallback onTap;

  const _CartBar({
    required this.itemCount,
    required this.subtotal,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton(
          onPressed: onTap,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text('${t.cart} ($itemCount)'),
                ],
              ),
              Text(t.priceSom(groupThousands(subtotal))),
            ],
          ),
        ),
      ),
    );
  }
}
