import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'restaurant_api.dart';
import 'restaurant_card.dart';
import 'restaurant_models.dart';
import 'restaurants_map_screen.dart';

enum _FoodFilter { all, open, top }

/// Ovqat bosh ekrani — qidiruv, filtrlar, chiroyli oshxona kartalari.
/// GPS bo'lsa oshxonalar ENG YAQINI BIRINCHI tartibda. plan/05-customer-app.md
class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  ConsumerState<RestaurantListScreen> createState() =>
      _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _FoodFilter _filter = _FoodFilter.all;
  LatLng? _myLoc;

  /// id -> masofa (km) — GPS va oshxona joylashuvi bo'lsa.
  final Map<String, double> _distanceKm = {};

  @override
  void initState() {
    super.initState();
    ref.read(locationServiceProvider).currentLatLng().then((p) {
      if (mounted && p != null) setState(() => _myLoc = p);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Ikki oshxonani masofa bo'yicha solishtiradi (masofasizlar oxirida).
  int _byDistance(RestaurantSummary a, RestaurantSummary b) {
    final da = _distanceKm[a.id];
    final db = _distanceKm[b.id];
    if (da != null && db != null) return da.compareTo(db);
    if (da != null) return -1;
    if (db != null) return 1;
    return b.rating.compareTo(a.rating);
  }

  List<RestaurantSummary> _apply(List<RestaurantSummary> input) {
    // Masofalarni yangilab olamiz (GPS kelgach bir marta hisoblanadi).
    final me = _myLoc;
    if (me != null && _distanceKm.isEmpty) {
      const d = Distance();
      for (final r in input.where((r) => r.hasLocation)) {
        _distanceKm[r.id] =
            d.as(LengthUnit.Kilometer, me, LatLng(r.lat, r.lng));
      }
    }
    final q = _query.trim().toLowerCase();
    var list = input.where((r) {
      if (q.isEmpty) return true;
      return r.name.toLowerCase().contains(q) ||
          r.address.toLowerCase().contains(q);
    }).toList();

    switch (_filter) {
      case _FoodFilter.open:
        list = list.where((r) => r.isOpen).toList();
        list.sort(_byDistance);
      case _FoodFilter.top:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _FoodFilter.all:
        // Ochiqlar birinchi, ular ichida eng yaqini oldinda.
        list.sort((a, b) {
          if (a.isOpen != b.isOpen) return a.isOpen ? -1 : 1;
          return _byDistance(a, b);
        });
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.serviceFood),
        actions: [
          IconButton(
            tooltip: t.restaurantsMapTitle,
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const RestaurantsMapScreen(),
              ),
            ),
          ),
        ],
      ),
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
                      itemBuilder: (_, i) => RestaurantMiniCard(
                        restaurant: list[i],
                        distanceKm: _distanceKm[list[i].id],
                      ),
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
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: t.foodSearchHint,
        prefixIcon: const Icon(Icons.search),
        // Matn bor bo'lsa — bir bosishda tozalash
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, size: 20),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _query = '');
                },
              ),
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

  Widget _emptyHint(String text) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.search_off_rounded,
                  size: 30, color: scheme.outline),
            ),
            const SizedBox(height: 12),
            Text(text,
                style: TextStyle(
                    color: scheme.outline, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
