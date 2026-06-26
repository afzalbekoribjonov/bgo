import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/geocoding_service.dart';
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
  Timer? _debounce;
  List<GeoResult> _geoResults = const [];
  bool _searching = false;
  String? _pickedLabel; // qidiruvdan tanlangan nom (panmagunча saqlanadi)

  @override
  void initState() {
    super.initState();
    _center = widget.initial ?? LocationService.beshariqCenter;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _map.dispose();
    super.dispose();
  }

  /// Qidiruv matni o'zgardi — debounce bilan Nominatim'dan izlaymiz.
  void _onSearchChanged(String v) {
    setState(() => _query = v);
    _debounce?.cancel();
    if (v.trim().length < 2) {
      setState(() {
        _geoResults = const [];
        _searching = false;
      });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final r = await ref.read(geocodingServiceProvider).search(v);
      if (mounted) {
        setState(() {
          _geoResults = r;
          _searching = false;
        });
      }
    });
  }

  /// Natija tanlandi — xaritani o'sha joyga olib boramiz, nomni eslab qolamiz.
  void _selectResult(String label, LatLng ll) {
    _map.move(ll, 16);
    setState(() {
      _center = ll;
      _pickedLabel = label;
      _query = '';
      _geoResults = const [];
      _searching = false;
    });
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
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
    final label = _pickedLabel ?? _labelFor(places, t);
    Navigator.of(context).pop(
      GeoPlace(label, _center.latitude, _center.longitude),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final places = ref.watch(placesProvider).valueOrNull ?? beshariqPlaces;
    final roads = ref.watch(roadsProvider).valueOrNull ?? const [];
    // Mahalliy (admin) joylar — qidiruv matniga mos keladiganlari.
    final localResults = _query.trim().isEmpty
        ? const <GeoPlace>[]
        : places
            .where((p) => p.label.toLowerCase().contains(_query.toLowerCase()))
            .take(4)
            .toList();
    final showResults =
        _query.trim().length >= 2 &&
            (localResults.isNotEmpty || _geoResults.isNotEmpty || _searching);

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
              onPositionChanged: (camera, hasGesture) {
                _center = camera.center;
                // Foydalanuvchi xaritani surса, tanlangan nomni bekor qilamiz.
                if (hasGesture && _pickedLabel != null) {
                  setState(() => _pickedLabel = null);
                }
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
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: t.mapSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : (_query.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    _onSearchChanged('');
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null),
                      filled: true,
                      fillColor: scheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (showResults)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    constraints: const BoxConstraints(maxHeight: 320),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 6)
                      ],
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      children: [
                        for (final p in localResults)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.push_pin,
                                color: Color(0xFF1B5E20)),
                            title: Text(p.label),
                            subtitle: Text(t.mapLocalPlace,
                                style: const TextStyle(fontSize: 11)),
                            onTap: () => _selectResult(
                                p.label, LatLng(p.lat, p.lng)),
                          ),
                        for (final r in _geoResults)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(r.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            onTap: () => _selectResult(
                                r.label, LatLng(r.lat, r.lng)),
                          ),
                        if (!_searching &&
                            localResults.isEmpty &&
                            _geoResults.isEmpty)
                          ListTile(
                            dense: true,
                            leading: const Icon(Icons.search_off),
                            title: Text(t.mapNoResults),
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
                          child: Text(_pickedLabel ?? _labelFor(places, t),
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
