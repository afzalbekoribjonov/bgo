import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/location_service.dart';
import '../../core/map_road.dart';
import '../../core/places.dart';
import '../../l10n/generated/app_localizations.dart';
import '../geo/geo_api.dart';

/// Xaritadan joy tanlash — markazda pin (xarita siljiydi), qidiruv + GPS.
/// GeoPlace qaytaradi. plan/12-maps-navigation.md
class MapPickerScreen extends ConsumerStatefulWidget {
  final LatLng? initial;
  final String? titleOverride;
  const MapPickerScreen({super.key, this.initial, this.titleOverride});

  @override
  ConsumerState<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends ConsumerState<MapPickerScreen> {
  final _map = MapController();
  final _searchCtrl = TextEditingController();
  late LatLng _center;
  String _query = '';
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? LocationService.beshariqCenter;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    final pos = await ref.read(locationServiceProvider).currentLatLng();
    if (!mounted) return;
    setState(() => _locating = false);
    if (pos != null) {
      _map.move(pos, 16);
      setState(() => _center = pos);
    }
  }

  /// Markazga eng yaqin saqlangan joy nomi (200m ichida), aks holda umumiy.
  String _labelFor(List<GeoPlace> places, AppLocalizations t) {
    const dist = Distance();
    GeoPlace? best;
    double bestM = 250;
    for (final p in places) {
      final m = dist.as(LengthUnit.Meter, _center, LatLng(p.lat, p.lng));
      if (m < bestM) {
        bestM = m;
        best = p;
      }
    }
    return best?.label ?? t.mapPickedPoint;
  }

  void _confirm(List<GeoPlace> places) {
    final t = AppLocalizations.of(context)!;
    Navigator.of(context).pop(
      GeoPlace(_labelFor(places, t), _center.latitude, _center.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final places = ref.watch(placesProvider).valueOrNull ?? beshariqPlaces;
    final roads = ref.watch(roadsProvider).valueOrNull ?? const [];
    final results = _query.isEmpty
        ? const <GeoPlace>[]
        : places
            .where((p) => p.label.toLowerCase().contains(_query.toLowerCase()))
            .take(6)
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.titleOverride ?? t.mapPickTitle)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15,
              minZoom: 12,
              maxZoom: 18,
              cameraConstraint:
                  CameraConstraint.contain(bounds: beshariqBounds),
              onPositionChanged: (camera, _) {
                _center = camera.center;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.beshariq.customer_app',
              ),
              if (roads.isNotEmpty)
                PolylineLayer(polylines: buildRoadPolylines(roads)),
            ],
          ),

          // Markaz pin (uchi markazga to'g'ri kelishi uchun yuqoriga siljitilgan)
          IgnorePointer(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -22),
                child: Icon(Icons.location_pin, size: 48, color: scheme.primary),
              ),
            ),
          ),

          // Qidiruv + natijalar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 3,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: t.mapSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: scheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (results.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6)
                      ],
                    ),
                    child: Column(
                      children: [
                        for (final p in results)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined),
                            title: Text(p.label),
                            onTap: () {
                              final ll = LatLng(p.lat, p.lng);
                              _map.move(ll, 16);
                              setState(() {
                                _center = ll;
                                _query = '';
                                _searchCtrl.clear();
                              });
                              FocusScope.of(context).unfocus();
                            },
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // GPS tugmasi
          Positioned(
            right: 16,
            bottom: 110,
            child: FloatingActionButton.small(
              heroTag: 'myloc',
              onPressed: _locating ? null : _goToMyLocation,
              child: _locating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
            ),
          ),

          // Pastki tasdiqlash paneli
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: scheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_labelFor(places, t),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => _confirm(places),
                      icon: const Icon(Icons.check),
                      label: Text(t.mapConfirm),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
