import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/beshariq_map.dart';
import '../../core/location_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'restaurant_api.dart';
import 'restaurant_card.dart';
import 'restaurant_models.dart';

/// Oshxonalar xaritasi — admin belgilagan joylashuvlar bo'yicha oshxonalarni
/// xaritada ko'rsatadi. Belgini bosib o'sha oshxona menyusi ochiladi.
/// plan/12-maps-navigation.md
class RestaurantsMapScreen extends ConsumerStatefulWidget {
  const RestaurantsMapScreen({super.key});

  @override
  ConsumerState<RestaurantsMapScreen> createState() =>
      _RestaurantsMapScreenState();
}

class _RestaurantsMapScreenState extends ConsumerState<RestaurantsMapScreen> {
  final MapController _map = MapController();
  LatLng? _me;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _goToMyLocation());
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    final me = await ref.read(locationServiceProvider).currentLatLng();
    if (!mounted || me == null) return;
    setState(() => _me = me);
    _map.move(me, 15);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.restaurantsMapTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AsyncErrorRetry(
          error: e,
          onRetry: () => ref.invalidate(restaurantsProvider),
        ),
        data: (all) {
          final located = all.where((r) => r.hasLocation).toList();
          return Stack(
            children: [
              BeshariqMap(
                controller: _map,
                initialCenter: located.isNotEmpty
                    ? LatLng(located.first.lat, located.first.lng)
                    : LocationService.beshariqCenter,
                initialZoom: 14,
                overlays: [
                  if (_me != null)
                    MarkerLayer(markers: [myLocationMarker(_me!)]),
                  MarkerLayer(
                    markers: [for (final r in located) _restaurantMarker(r)],
                  ),
                ],
              ),
              if (located.isEmpty)
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 24,
                  child: Card(
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        t.restaurantsMapEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.outline),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'restMapMe',
        onPressed: _goToMyLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  /// Bosiluvchi oshxona belgisi — to'q-to'sariq doira + nom; bosilsa menyu.
  Marker _restaurantMarker(RestaurantSummary r) {
    const color = Color(0xFFE8590C);
    return Marker(
      point: LatLng(r.lat, r.lng),
      width: 150,
      height: 56,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => openRestaurantById(context, r.id, r.name),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: r.isOpen ? color : Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Colors.black38, blurRadius: 4),
                ],
              ),
              child: const Icon(Icons.restaurant, size: 16, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 2),
                ],
              ),
              child: Text(
                r.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
