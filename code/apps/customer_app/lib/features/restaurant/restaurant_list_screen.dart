import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../../widgets/language_button.dart';
import 'restaurant_api.dart';
import 'restaurant_menu_screen.dart';
import 'restaurant_models.dart';

/// Oshxonalar ro'yxati. plan/05-customer-app.md
class RestaurantListScreen extends ConsumerWidget {
  const RestaurantListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.restaurantsTitle),
        actions: const [LanguageButton()],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(restaurantsProvider),
        ),
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return Center(child: Text(t.emptyRestaurants));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(restaurantsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: restaurants.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) =>
                  _RestaurantCard(restaurant: restaurants[i]),
            ),
          );
        },
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final RestaurantSummary restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.restaurant),
        ),
        title: Text(restaurant.name),
        subtitle: Text(restaurant.address),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                Text(' ${restaurant.rating.toStringAsFixed(1)}'),
              ],
            ),
            Text(
              restaurant.isOpen ? t.open : t.closed,
              style: TextStyle(
                color: restaurant.isOpen ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RestaurantMenuScreen(
              restaurantId: restaurant.id,
              restaurantName: restaurant.name,
            ),
          ),
        ),
      ),
    );
  }
}
