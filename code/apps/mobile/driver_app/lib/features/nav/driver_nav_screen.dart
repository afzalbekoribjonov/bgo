import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/nav_support.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/car_marker.dart';

/// Haydovchi navigatsiyasi — to'liq ekran xarita: jonli GPS, olib ketish/manzil
/// nuqtalari va yo'l ustidan marshrut (OSRM). plan/06-driver-app.md
class DriverNavScreen extends ConsumerStatefulWidget {
  final String title;
  final String routeText;
  final LatLng? pickup;
  final LatLng? destination;

  /// true: hozir MANZILGA boriladi; false: olib ketish nuqtasiga.
  final bool toDestination;
  final String? phone;

  const DriverNavScreen({
    super.key,
    required this.title,
    required this.routeText,
    required this.pickup,
    required this.destination,
    required this.toDestination,
    this.phone,
  });

  LatLng? get target => toDestination ? destination : pickup;

  @override
  ConsumerState<DriverNavScreen> createState() => _DriverNavScreenState();
}

class _DriverNavScreenState extends ConsumerState<DriverNavScreen> {
  final MapController _map = MapController();
  LatLng? _me;
  List<LatLng> _route = const [];
  int? _etaMin;
  String? _distKm;
  Timer? _timer;
  bool _followed = false;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _map.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final me = await driverCurrentLatLng();
    if (!mounted || me == null) return;
    setState(() => _me = me);
    if (!_followed) {
      _followed = true;
      _map.move(me, 15);
    }
    final target = widget.target;
    if (target == null) return;
    final dir = await ref.read(driverRoutingServiceProvider).directions(me, target);
    if (!mounted || dir == null) return;
    setState(() {
      _route = dir.points;
      _etaMin = dir.etaMinutes;
      _distKm = dir.distanceKm;
    });
  }

  void _recenter() {
    if (_me != null) _map.move(_me!, 16);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final markers = <Marker>[];
    if (_me != null) {
      markers.add(Marker(
        point: _me!,
        width: 42,
        height: 42,
        alignment: Alignment.center,
        child: const CarMarker(
          size: 34,
          color: Color(0xFFD4AF37),
          glow: true,
        ),
      ));
    }
    if (widget.pickup != null) {
      markers.add(_pin(widget.pickup!, const Color(0xFF2E7D32), Icons.my_location));
    }
    if (widget.destination != null) {
      markers.add(_pin(widget.destination!, const Color(0xFFE53935), Icons.flag));
    }

    final line = _route.isNotEmpty
        ? _route
        : (_me != null && widget.target != null ? [_me!, widget.target!] : null);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _me ?? widget.target ?? beshariqCenter,
              initialZoom: 15,
              minZoom: 11,
              maxZoom: 18,
              cameraConstraint:
                  CameraConstraint.contain(bounds: beshariqBounds),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.beshariq.driver_app',
                maxZoom: 19,
              ),
              if (line != null)
                PolylineLayer(polylines: [
                  Polyline(
                    points: line,
                    strokeWidth: 6,
                    color: const Color(0xFF1E88E5),
                    borderColor: Colors.white,
                    borderStrokeWidth: 2,
                  ),
                ]),
              MarkerLayer(markers: markers),
            ],
          ),
          Positioned(
            right: 16,
            bottom: 150,
            child: FloatingActionButton.small(
              heroTag: 'navRecenter',
              onPressed: _recenter,
              child: const Icon(Icons.my_location),
            ),
          ),
          Positioned(left: 12, right: 12, bottom: 12, child: _infoCard(t)),
        ],
      ),
    );
  }

  Widget _infoCard(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    final toDest = widget.toDestination;
    return Card(
      elevation: 6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(toDest ? Icons.flag : Icons.my_location,
                    color: toDest ? const Color(0xFFE53935) : const Color(0xFF2E7D32)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    toDest ? t.navDeliverToAddress : t.navGoPickupCustomer,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (_etaMin != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      t.navEtaChip(_etaMin.toString(), _distKm ?? '—'),
                      style: TextStyle(
                          color: scheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(widget.routeText,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: scheme.outline)),
            if (widget.phone != null && widget.phone!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: scheme.outline),
                  const SizedBox(width: 6),
                  Text(widget.phone!, style: TextStyle(color: scheme.outline)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Marker _pin(LatLng p, Color color, IconData icon) => Marker(
        point: p,
        width: 40,
        height: 40,
        alignment: Alignment.center,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );
}
