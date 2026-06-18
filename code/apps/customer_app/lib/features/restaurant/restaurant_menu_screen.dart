import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../cart/cart_controller.dart';
import '../cart/cart_screen.dart';
import 'restaurant_api.dart';
import 'restaurant_models.dart';

/// Oshxona menyusi — kategoriya bo'yicha taomlar + savatga qo'shish. plan/05-customer-app.md
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
      }
    }

    final showCartBar = !cart.isEmpty && cart.restaurantId == restaurantId;

    return Scaffold(
      appBar: AppBar(title: Text(restaurantName)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(menuProvider(restaurantId)),
        ),
        data: (menu) {
          final categories =
              menu.categories.where((c) => c.items.isNotEmpty).toList();
          if (categories.isEmpty) {
            return Center(child: Text(t.emptyMenu));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 88, top: 8),
            children: [
              for (final category in categories) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                for (final item in category.items)
                  _MenuItemTile(
                    item: item,
                    onAdd: item.isAvailable ? () => addToCart(item) : null,
                  ),
              ],
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
}

class _MenuItemTile extends StatelessWidget {
  final MenuItemView item;
  final VoidCallback? onAdd;

  const _MenuItemTile({required this.item, this.onAdd});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final priceText = t.priceSom(groupThousands(item.price));
    final disabled = !item.isAvailable;

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: ListTile(
        title: Text(item.name),
        subtitle: item.description != null && item.description!.isNotEmpty
            ? Text(item.description!)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (disabled)
              Text(
                t.unavailable,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.error),
              )
            else ...[
              Text(priceText,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: onAdd,
              ),
            ],
          ],
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
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${t.cart} ($itemCount)'),
              Text(t.priceSom(groupThousands(subtotal))),
            ],
          ),
        ),
      ),
    );
  }
}
