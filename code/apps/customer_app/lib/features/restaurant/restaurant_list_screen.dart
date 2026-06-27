import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'restaurant_api.dart';
import 'restaurant_card.dart';
import 'restaurant_models.dart';

enum _FoodFilter { all, open, top }

/// Ovqat bosh ekrani — qidiruv, filtrlar, chiroyli oshxona kartalari.
/// plan/05-customer-app.md
class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  ConsumerState<RestaurantListScreen> createState() =>
      _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  String _query = '';
  _FoodFilter _filter = _FoodFilter.all;

  List<RestaurantSummary> _apply(List<RestaurantSummary> input) {
    final q = _query.trim().toLowerCase();
    var list = input.where((r) {
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.address.toLowerCase().contains(q);
    }).toList();

    switch (_filter) {
      case _FoodFilter.open:
        list = list.where((r) => r.isOpen).toList();
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _FoodFilter.top:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _FoodFilter.all:
        list.sort((a, b) {
          if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
          return b.rating.compareTo(a.rating);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.serviceFood)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(restaurantsProvider),
        ),
        data: (all) {
          final list = _apply(all);
          final dishesAsync = ref.watch(dishesProvider);
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(restaurantsProvider);
              ref.invalidate(dishesProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _searchField(t),
                const SizedBox(height: 12),
                _promoBanner(t),
                const SizedBox(height: 16),
                _filterChips(t),
                const SizedBox(height: 16),
                // Oshxonalar — bitta gorizontal qator
                _sectionTitle(t.foodSectionRestaurants),
                const SizedBox(height: 8),
                if (all.isEmpty)
                  _emptyHint(t.emptyRestaurants)
                else if (list.isEmpty)
                  _emptyHint(t.foodNothingFound)
                else
                  SizedBox(
                    height: 172,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) =>
                          RestaurantMiniCard(restaurant: list[i]),
                    ),
                  ),
                const SizedBox(height: 18),
                // Taomlar — grid (bosh ekrandagi kabi)
                _sectionTitle(t.homeDishes),
                const SizedBox(height: 8),
                dishesAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => AsyncErrorRetry(
                    error: e,
                    onRetry: () => ref.invalidate(dishesProvider),
                  ),
                  data: (allDishes) {
                    final q = _query.trim().toLowerCase();
                    final dishes = q.isEmpty
                        ? allDishes
                        : allDishes
                            .where((d) =>
                                d.name.toLowerCase().contains(q) ||
                                d.restaurantName.toLowerCase().contains(q))
                            .toList();
                    if (dishes.isEmpty) return _emptyHint(t.foodNothingFound);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.78,
                      ),
                      itemCount: dishes.length,
                      itemBuilder: (_, i) => DishCard(dish: dishes[i]),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _searchField(AppLocalizations t) {
    return TextField(
      onChanged: (v) => setState(() => _query = v),
      decoration: InputDecoration(
        hintText: t.foodSearchHint,
        prefixIcon: const Icon(Icons.search),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _promoBanner(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining, color: Colors.white, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.foodPromoTitle,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(t.foodPromoSubtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      );

  Widget _filterChips(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    final items = [
      (_FoodFilter.all, t.foodFilterAll),
      (_FoodFilter.open, t.foodFilterOpen),
      (_FoodFilter.top, t.foodFilterTop),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = items[i];
          final selected = _filter == value;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            labelStyle: TextStyle(
              color: selected ? Colors.white : scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            backgroundColor: scheme.surfaceContainerHighest,
            selectedColor: scheme.primary,
            side: BorderSide(
                color: selected ? scheme.primary : scheme.outlineVariant),
            onSelected: (_) => setState(() => _filter = value),
          );
        },
      ),
    );
  }

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(text,
              style: TextStyle(color: Theme.of(context).colorScheme.outline)),
        ),
      );
}
