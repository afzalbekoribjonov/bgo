import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'restaurant_api.dart';
import 'restaurant_menu_screen.dart';
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
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(restaurantsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              children: [
                _searchField(t),
                const SizedBox(height: 12),
                _promoBanner(t),
                const SizedBox(height: 16),
                _filterChips(t),
                const SizedBox(height: 12),
                Text(t.foodSectionRestaurants,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (all.isEmpty)
                  _emptyHint(t.emptyRestaurants)
                else if (list.isEmpty)
                  _emptyHint(t.foodNothingFound)
                else
                  ...list.map((r) => _RestaurantCard(restaurant: r)),
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

  Widget _filterChips(AppLocalizations t) {
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
          return ChoiceChip(
            label: Text(label),
            selected: _filter == value,
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

class _RestaurantCard extends StatelessWidget {
  final RestaurantSummary restaurant;
  const _RestaurantCard({required this.restaurant});

  /// Nomdan barqaror rang (rasm yo'qligi uchun chiroyli banner).
  Color _accent() {
    final hue = (restaurant.name.hashCode % 360).abs().toDouble();
    return HSLColor.fromAHSL(1, hue, 0.5, 0.5).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final accent = _accent();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RestaurantMenuScreen(
                restaurantId: restaurant.id,
                restaurantName: restaurant.name,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner (gradient + ikonka + holat)
              Stack(
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.restaurant_menu,
                          size: 52, color: Colors.white70),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _pill(
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
                          child: Text(
                            restaurant.name,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: scheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 15, color: Colors.amber),
                              const SizedBox(width: 2),
                              Text(restaurant.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 15, color: scheme.outline),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant.address,
                            style: TextStyle(
                                color: scheme.outline, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
