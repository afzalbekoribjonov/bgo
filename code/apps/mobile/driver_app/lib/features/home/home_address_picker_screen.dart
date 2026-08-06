import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/nav_support.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/driver_colors.dart';

/// Tanlangan uy manzili — koordinata + ko'rsatiladigan matn.
class PickedHome {
  final double lat;
  final double lng;
  final String address;
  const PickedHome(this.lat, this.lng, this.address);
}

class _SearchResult {
  final String label;
  final double lat;
  final double lng;
  const _SearchResult(this.label, this.lat, this.lng);
}

/// Uy manzilini xaritadan yoki qidiruv orqali belgilash — "Uyga" rejimi
/// uchun (customer_app'ning MapPickerScreen'iga o'xshab, lekin driver_app'ga
/// moslab soddalashtirilgan: markaziy pin + qidiruv, admin joy/yo'l qatlamsiz).
class HomeAddressPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  const HomeAddressPickerScreen({super.key, this.initialLat, this.initialLng});

  @override
  State<HomeAddressPickerScreen> createState() => _HomeAddressPickerScreenState();
}

class _HomeAddressPickerScreenState extends State<HomeAddressPickerScreen> {
  final _map = MapController();
  final _searchCtrl = TextEditingController();
  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  late LatLng _center;
  String? _pickedLabel;
  bool _searching = false;
  bool _locating = false;
  bool _confirming = false;
  List<_SearchResult> _results = [];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = (widget.initialLat != null && widget.initialLng != null)
        ? LatLng(widget.initialLat!, widget.initialLng!)
        : beshariqCenter;
    if (widget.initialLat == null) _goToMyLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _goToMyLocation() async {
    setState(() => _locating = true);
    final pos = await driverCurrentLatLng();
    if (!mounted) return;
    setState(() => _locating = false);
    if (pos == null) return;
    setState(() {
      _center = pos;
      _pickedLabel = null;
    });
    _map.move(pos, 16);
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    final query = q.trim();
    if (query.length < 3) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () => _search(query));
  }

  Future<void> _search(String q) async {
    setState(() => _searching = true);
    try {
      final res = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': q,
          'format': 'jsonv2',
          'limit': 8,
          'viewbox':
              '${beshariqBounds.west},${beshariqBounds.north},${beshariqBounds.east},${beshariqBounds.south}',
          'bounded': 1,
        },
        options: Options(headers: {'Accept-Language': 'uz'}),
      );
      if (!mounted) return;
      final list = (res.data ?? const [])
          .map((e) => _SearchResult(
                (e as Map)['display_name'] as String,
                double.parse(e['lat'] as String),
                double.parse(e['lon'] as String),
              ))
          .toList();
      setState(() => _results = list);
    } catch (_) {
      if (mounted) setState(() => _results = []);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _pick(_SearchResult r) {
    FocusScope.of(context).unfocus();
    setState(() {
      _center = LatLng(r.lat, r.lng);
      _pickedLabel = r.label;
      _results = [];
      _searchCtrl.clear();
    });
    _map.move(_center, 16);
  }

  /// Qidiruv orqali tanlangan bo'lsa — o'sha nom ishlatiladi. Faqat pin
  /// surib (qidiruvsiz) belgilangan bo'lsa — Nominatim REVERSE geocoding
  /// bilan manzil nomi so'raladi; u ham topilmasa umumiy, raqamsiz matnga
  /// tushiladi. Xom lat/lng HECH QACHON ko'rsatilmaydi.
  Future<void> _confirm() async {
    if (_confirming) return;
    final picked = _pickedLabel;
    if (picked != null) {
      Navigator.of(context).pop(PickedHome(_center.latitude, _center.longitude, picked));
      return;
    }
    setState(() => _confirming = true);
    String? reverseLabel;
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': _center.latitude,
          'lon': _center.longitude,
          'format': 'jsonv2',
        },
        options: Options(headers: {'Accept-Language': 'uz'}),
      );
      final name = res.data?['display_name'] as String?;
      if (name != null && name.trim().isNotEmpty) reverseLabel = name;
    } catch (_) {
      reverseLabel = null;
    }
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    Navigator.of(context).pop(
      PickedHome(_center.latitude, _center.longitude, reverseLabel ?? t.homeAddressUnknownPoint),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: FlutterMap(
              mapController: _map,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 15,
                minZoom: 11,
                maxZoom: 18,
                cameraConstraint: CameraConstraint.contain(bounds: beshariqBounds),
                onPositionChanged: (camera, hasGesture) {
                  _center = camera.center;
                  if (hasGesture && _pickedLabel != null) {
                    setState(() => _pickedLabel = null);
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.beshariq.driver_app',
                  maxZoom: 19,
                ),
              ],
            ),
          ),
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_pin, size: 44, color: DriverColors.red),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      _RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Material(
                          borderRadius: BorderRadius.circular(14),
                          elevation: 3,
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearchChanged,
                            decoration: InputDecoration(
                              hintText: t.homeAddressSearchHint,
                              prefixIcon: _searching
                                  ? const Padding(
                                      padding: EdgeInsets.all(14),
                                      child: SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_results.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      constraints: const BoxConstraints(maxHeight: 260),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 10),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) => ListTile(
                          leading: const Icon(Icons.place_outlined),
                          title: Text(
                            _results[i].label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13.5),
                          ),
                          onTap: () => _pick(_results[i]),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 130,
            child: FloatingActionButton.small(
              heroTag: 'home_locate',
              backgroundColor: Colors.white,
              onPressed: _locating ? null : _goToMyLocation,
              child: _locating
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location_rounded, color: Colors.black87),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _pickedLabel ?? t.homeAddressPinHint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: DriverColors.green,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                      onPressed: _confirming ? null : _confirm,
                      child: _confirming
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colors.white),
                            )
                          : Text(t.homeAddressConfirm),
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

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(padding: const EdgeInsets.all(10), child: Icon(icon, size: 20)),
      ),
    );
  }
}
