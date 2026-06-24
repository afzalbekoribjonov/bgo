import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/location_service.dart';
import '../../core/places.dart';
import '../../l10n/generated/app_localizations.dart';
import '../map/map_picker_screen.dart';
import 'taxi_api.dart';
import 'taxi_chat_screen.dart';
import 'taxi_models.dart';

/// Taksi chaqirish — xaritali oqim. plan/05-customer-app.md, plan/12-maps-navigation.md
class TaxiScreen extends ConsumerStatefulWidget {
  const TaxiScreen({super.key});

  @override
  ConsumerState<TaxiScreen> createState() => _TaxiScreenState();
}

class _TaxiScreenState extends ConsumerState<TaxiScreen> {
  final MapController _map = MapController();
  LatLng? _myLoc;
  GeoPlace? _from;
  GeoPlace? _to;
  bool _noDest = false;
  TaxiEstimate? _estimate;
  bool _requesting = false;
  String? _error;
  List<LatLng> _cars = const [];

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _map.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final t = AppLocalizations.of(context)!;
    final pos = await ref.read(locationServiceProvider).currentLatLng();
    if (!mounted) return;
    setState(() {
      _myLoc = pos;
      // Joriy joylashuvni "Qayerdan" sifatida avtomatik o'rnatamiz.
      if (pos != null && _from == null) {
        _from = GeoPlace(t.taxiCurrentLocation, pos.latitude, pos.longitude);
      }
    });
    if (pos != null) _map.move(pos, 15);
  }

  LatLng get _center =>
      _myLoc ??
      (_from != null
          ? LatLng(_from!.lat, _from!.lng)
          : LocationService.beshariqCenter);

  Future<void> _pick({required bool isFrom}) async {
    final initial = isFrom
        ? (_from != null ? LatLng(_from!.lat, _from!.lng) : _myLoc)
        : (_to != null ? LatLng(_to!.lat, _to!.lng) : _myLoc);
    final result = await Navigator.of(context).push<GeoPlace>(
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(initial: initial ?? _center),
      ),
    );
    if (result == null) return;
    setState(() {
      if (isFrom) {
        _from = result;
      } else {
        _to = result;
      }
    });
    await _recompute();
  }

  Future<void> _recompute() async {
    if (_noDest || _from == null || _to == null) {
      setState(() => _estimate = null);
      return;
    }
    try {
      final e = await ref.read(taxiApiProvider).estimate(_from!, _to!);
      if (mounted) setState(() => _estimate = e);
    } catch (_) {
      if (mounted) setState(() => _estimate = null);
    }
  }

  Future<void> _request() async {
    final t = AppLocalizations.of(context)!;
    if (_from == null) return;
    if (!_noDest && _to == null) return;
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      await ref.read(taxiApiProvider).request(_from!, _noDest ? null : _to);
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      _spawnCars();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.taxiRequested)));
    } catch (e) {
      setState(() =>
          _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  /// Buyurtmadan keyin xaritada yaqin "mashinalar" (vizual).
  void _spawnCars() {
    final base = _from != null ? LatLng(_from!.lat, _from!.lng) : _center;
    final rnd = Random();
    setState(() {
      _cars = List.generate(4, (_) {
        final dLat = (rnd.nextDouble() - 0.5) * 0.012;
        final dLng = (rnd.nextDouble() - 0.5) * 0.012;
        return LatLng(base.latitude + dLat, base.longitude + dLng);
      });
    });
  }

  Future<void> _cancel(String id) async {
    final t = AppLocalizations.of(context)!;
    try {
      await ref.read(taxiApiProvider).cancel(id);
      ref.invalidate(myTripsProvider);
      setState(() => _cars = const []);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final trips = ref.watch(myTripsProvider).valueOrNull ?? const [];
    final active = trips
        .where((tr) =>
            tr.status == 'PENDING' ||
            tr.status == 'ACCEPTED' ||
            tr.status == 'IN_PROGRESS')
        .toList();
    final activeTrip = active.isNotEmpty ? active.first : null;

    return Scaffold(
      appBar: AppBar(title: Text(t.taxiTitle)),
      body: Column(
        children: [
          Expanded(child: _buildMap()),
          if (activeTrip != null)
            _activePanel(t, activeTrip)
          else
            _bookingPanel(t),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final scheme = Theme.of(context).colorScheme;
    final markers = <Marker>[];
    if (_myLoc != null) {
      markers.add(Marker(
        point: _myLoc!,
        width: 22,
        height: 22,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
          ),
        ),
      ));
    }
    if (_from != null) {
      markers.add(_pin(LatLng(_from!.lat, _from!.lng), Colors.green));
    }
    if (_to != null && !_noDest) {
      markers.add(_pin(LatLng(_to!.lat, _to!.lng), scheme.primary));
    }
    for (final c in _cars) {
      markers.add(Marker(
        point: c,
        width: 34,
        height: 34,
        child: const Icon(Icons.local_taxi, color: Color(0xFFFFB300), size: 30),
      ));
    }

    final line = (_from != null && _to != null && !_noDest)
        ? [LatLng(_from!.lat, _from!.lng), LatLng(_to!.lat, _to!.lng)]
        : null;

    return FlutterMap(
      mapController: _map,
      options: MapOptions(
        initialCenter: _center,
        initialZoom: 14,
        minZoom: 11,
        maxZoom: 18,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.beshariq.customer_app',
        ),
        if (line != null)
          PolylineLayer(polylines: [
            Polyline(points: line, strokeWidth: 4, color: scheme.primary),
          ]),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Marker _pin(LatLng p, Color color) => Marker(
        point: p,
        width: 40,
        height: 40,
        alignment: Alignment.topCenter,
        child: Icon(Icons.location_pin, color: color, size: 40),
      );

  // ---------- Buyurtma paneli ----------
  Widget _bookingPanel(AppLocalizations t) {
    return _panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _addressRow(
            icon: Icons.my_location,
            color: Colors.green,
            label: _from?.label ?? t.taxiSelectFromHint,
            filled: _from != null,
            onTap: () => _pick(isFrom: true),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _addressRow(
                  icon: Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  label: _noDest
                      ? t.taxiMeteredBadge
                      : (_to?.label ?? t.taxiSelectToHint),
                  filled: _noDest || _to != null,
                  onTap: _noDest ? null : () => _pick(isFrom: false),
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(t.taxiMeteredBadge),
                selected: _noDest,
                onSelected: (v) {
                  setState(() {
                    _noDest = v;
                    if (v) _to = null;
                  });
                  _recompute();
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          _fareLine(t),
          if (_error != null) ...[
            const SizedBox(height: 6),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed:
                (_requesting || _from == null || (!_noDest && _to == null))
                    ? null
                    : _request,
            icon: _requesting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.local_taxi),
            label: Text(t.taxiRequest),
          ),
        ],
      ),
    );
  }

  Widget _fareLine(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    if (_estimate != null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Icon(Icons.payments_outlined, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
            Text(t.priceSom(groupThousands(_estimate!.fare)),
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: scheme.primary)),
            const SizedBox(width: 6),
            Text('· ${t.taxiKm(_estimate!.distanceKm.toStringAsFixed(1))}',
                style: TextStyle(color: scheme.outline)),
          ],
        ),
      );
    }
    // Manzil yo'q — minimal narx
    final tariff = ref.watch(taxiTariffProvider).valueOrNull;
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Icon(Icons.payments_outlined, size: 18, color: scheme.outline),
          const SizedBox(width: 6),
          Text(
            tariff != null
                ? t.taxiFareFrom(groupThousands(tariff.minFare))
                : '…',
            style: TextStyle(fontWeight: FontWeight.w600, color: scheme.outline),
          ),
        ],
      ),
    );
  }

  // ---------- Faol safar paneli ----------
  Widget _activePanel(AppLocalizations t, TaxiTrip trip) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = _statusInfo(t, trip.status);
    final pending = trip.status == 'PENDING';
    return _panel(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.taxiTripNo(trip.publicNo.toString()),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 6),
          if (pending)
            Row(
              children: [
                const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(t.taxiSearchingCars,
                        style: TextStyle(color: scheme.outline))),
              ],
            )
          else
            Text(
              trip.fare > 0
                  ? t.priceSom(groupThousands(trip.fare))
                  : t.taxiMeteredHint,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (trip.status == 'ACCEPTED' || trip.status == 'IN_PROGRESS')
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TaxiChatScreen(
                          tripId: trip.id,
                          tripTitle: t.taxiTripNo(trip.publicNo.toString()),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: Text(t.chatTitle),
                  ),
                ),
              if ((trip.status == 'PENDING' || trip.status == 'ACCEPTED')) ...[
                if (trip.status == 'ACCEPTED' || trip.status == 'IN_PROGRESS')
                  const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _cancel(trip.id),
                    icon: Icon(Icons.close, size: 18, color: scheme.error),
                    label: Text(t.taxiCancel,
                        style: TextStyle(color: scheme.error)),
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: scheme.error.withValues(alpha: 0.5))),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Material(
      elevation: 12,
      color: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    );
  }

  Widget _addressRow({
    required IconData icon,
    required Color color,
    required String label,
    required bool filled,
    VoidCallback? onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: filled ? scheme.onSurface : scheme.outline,
                    fontWeight: filled ? FontWeight.w600 : FontWeight.normal,
                  )),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(AppLocalizations t, String status) {
    switch (status) {
      case 'ACCEPTED':
        return (t.taxiStatusAccepted, Colors.blue);
      case 'IN_PROGRESS':
        return (t.taxiStatusInProgress, Colors.orange);
      default:
        return (t.taxiStatusPending, Colors.grey);
    }
  }
}
