import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'restaurant_api.dart';
import 'restaurant_models.dart';

/// Oshxona menyusi — kategoriya bo'yicha taomlar. plan/05-customer-app.md
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
            padding: const EdgeInsets.symmetric(vertical: 8),
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
                for (final item in category.items) _MenuItemTile(item: item),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  final MenuItemView item;
  const _MenuItemTile({required this.item});

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
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(priceText, style: const TextStyle(fontWeight: FontWeight.w600)),
            if (disabled)
              Text(
                t.unavailable,
                style: TextStyle(
                    fontSize: 11, color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
        // TODO(savat): mavjud taomni savatga qo'shish (keyingi bo'lak)
        onTap: disabled ? null : () {},
      ),
    );
  }
}
