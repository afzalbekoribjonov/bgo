import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/beshariq_map.dart';
import '../../core/location_service.dart';
import '../../core/places.dart';
import '../../core/routing_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../geo/geo_api.dart';
import '../map/map_picker_screen.dart';
import 'parcel_api.dart';
import 'parcel_models.dart';

/// Dostavka (pochta) — xaritali oqim. plan/05-customer-app.md, plan/12-maps-navigation.md
class ParcelScreen extends ConsumerStatefulWidget {
  const ParcelScreen({super.key});

  @override
  ConsumerState<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends ConsumerState<ParcelScreen> {
  final MapController _map = MapController();
  LatLng? _myLoc;
  GeoPlace? _from;
  GeoPlace? _to;
  ParcelSize _size = ParcelSize.small;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ParcelEstimate? _estimate;
  bool _sending = false;
  String? _error;
  List<LatLng> _routeLine = const [];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.invalidate(placesProvider));
    _initLocation();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    _map.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final t = AppLocalizations.of(context)!;
    final svc = ref.read(locationServiceProvider);
    await svc.ensurePermission();
    final pos = await svc.currentLatLng();
    if (!mounted) return;
    setState(() {
      _myLoc = pos;
      if (pos != null) {
        _from = GeoPlace(t.taxiCurrentLocation, pos.latitude, pos.longitude);
      }
    });
    if (pos != null) _map.move(pos, 16);
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
      _estimate = null;
    });
    await _recompute();
  }

  Future<void> _recompute() async {
    if (_from == null || _to == null) {
      setState(() => _routeLine = const []);
      return;
    }
    await _doEstimate();
    final pts = await ref.read(routingServiceProvider).route(
          LatLng(_from!.lat, _from!.lng),
          LatLng(_to!.lat, _to!.lng),
        );
    if (mounted) setState(() => _routeLine = pts);
  }

  Future<void> _doEstimate() async {
    final t = AppLocalizations.of(context)!;
    if (_from == null || _to == null) return;
    if (_from == _to) {
      setState(() => _error = t.taxiSamePoint);
      return;
    }
    setState(() {
      _error = null;
      _estimate = null;
    });
    try {
      final e = await ref.read(parcelApiProvider).estimate(_from!, _to!, _size);
      if (mounted) setState(() => _estimate = e);
    } catch (e) {
      setState(() =>
          _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
    }
  }

  Future<void> _send() async {
    final t = AppLocalizations.of(context)!;
    if (_from == null || _to == null || _from == _to) return;
    if (_nameCtrl.text.trim().isEmpty || _phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = t.parcelRecipientRequired);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(parcelApiProvider).request(
            pickup: _from!,
            destination: _to!,
            size: _size,
            recipientName: _nameCtrl.text.trim(),
            recipientPhone: _phoneCtrl.text.trim(),
            note: _noteCtrl.text.trim(),
          );
      ref.invalidate(myParcelsProvider);
      if (!mounted) return;
      setState(() {
        _estimate = null;
        _routeLine = const [];
        _to = null;
        _nameCtrl.clear();
        _phoneCtrl.clear();
        _noteCtrl.clear();
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.parcelSent)));
    } catch (e) {
      setState(() =>
          _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _cancel(String id) async {
    final t = AppLocalizations.of(context)!;
    try {
      await ref.read(parcelApiProvider).cancel(id);
      ref.invalidate(myParcelsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isNetworkError(e) ? t.errorNetwork : t.errorGeneric)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.parcelTitle)),
      body: Column(
        children: [
          SizedBox(height: 250, child: _buildMap()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _addressRow(
                  icon: Icons.my_location,
                  color: Colors.green,
                  label: _from?.label ?? t.taxiSelectFromHint,
                  filled: _from != null,
                  onTap: () => _pick(isFrom: true),
                ),
                const SizedBox(height: 8),
                _addressRow(
                  icon: Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                  label: _to?.label ?? t.taxiSelectToHint,
                  filled: _to != null,
                  onTap: () => _pick(isFrom: false),
                ),
                const SizedBox(height: 16),
                Text(t.parcelSize, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<ParcelSize>(
                  segments: [
                    ButtonSegment(value: ParcelSize.small, label: Text(t.parcelSizeSmall), icon: const Icon(Icons.inventory_2_outlined)),
                    ButtonSegment(value: ParcelSize.medium, label: Text(t.parcelSizeMedium), icon: const Icon(Icons.inventory_2)),
                    ButtonSegment(value: ParcelSize.large, label: Text(t.parcelSizeLarge), icon: const Icon(Icons.local_shipping_outlined)),
                  ],
                  selected: {_size},
                  onSelectionChanged: (s) {
                    setState(() {
                      _size = s.first;
                      _estimate = null;
                    });
                    _doEstimate();
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: t.parcelRecipientName,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: t.parcelRecipientPhone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  decoration: InputDecoration(
                    labelText: t.parcelNote,
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (_estimate != null) _estimateCard(t, _estimate!),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(_error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: (_sending ||
                          _from == null ||
                          _to == null ||
                          _from == _to)
                      ? null
                      : _send,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  icon: _sending
                      ? const _Spin()
                      : const Icon(Icons.local_shipping),
                  label: Text(t.parcelSend),
                ),
                const SizedBox(height: 24),
                Text(t.parcelMyParcels,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _buildParcels(t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    final overlays = <Widget>[];
    final line = _routeLine.isNotEmpty
        ? _routeLine
        : ((_from != null && _to != null)
            ? [LatLng(_from!.lat, _from!.lng), LatLng(_to!.lat, _to!.lng)]
            : null);
    if (line != null) {
      overlays.add(PolylineLayer(polylines: [
        Polyline(
          points: line,
          strokeWidth: 6,
          color: const Color(0xFF1E88E5),
          borderColor: Colors.white,
          borderStrokeWidth: 2,
        ),
      ]));
    }
    final markers = <Marker>[];
    // Jo'natuvchi (yashil doira) va qabul qiluvchi (qizil pin) — aniq farqli.
    if (_from != null) markers.add(pickupMarker(LatLng(_from!.lat, _from!.lng)));
    if (_to != null) markers.add(destMarker(LatLng(_to!.lat, _to!.lng)));
    overlays.add(MarkerLayer(markers: markers));

    return Stack(
      children: [
        BeshariqMap(
          controller: _map,
          initialCenter: _center,
          initialZoom: 15,
          overlays: overlays,
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'parcelMyLoc',
            onPressed: _recenter,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Future<void> _recenter() async {
    final pos = await ref.read(locationServiceProvider).currentLatLng();
    if (!mounted || pos == null) return;
    _map.move(pos, 16);
    setState(() => _myLoc = pos);
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
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
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
            Icon(Icons.chevron_right, color: scheme.outline),
          ],
        ),
      ),
    );
  }

  Widget _estimateCard(AppLocalizations t, ParcelEstimate e) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.taxiDistance,
                    style: TextStyle(color: scheme.onPrimaryContainer)),
                Text(t.taxiKm(e.distanceKm.toStringAsFixed(1)),
                    style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(t.taxiFare,
                    style: TextStyle(color: scheme.onPrimaryContainer)),
                Text(t.priceSom(groupThousands(e.fare)),
                    style: TextStyle(
                        color: scheme.onPrimaryContainer,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParcels(AppLocalizations t) {
    final async = ref.watch(myParcelsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myParcelsProvider),
      ),
      data: (parcels) {
        if (parcels.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(t.parcelNoParcels,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          );
        }
        return Column(children: parcels.map((p) => _parcelCard(t, p)).toList());
      },
    );
  }

  Widget _parcelCard(AppLocalizations t, ParcelDelivery p) {
    final (label, color) = _statusInfo(t, p.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.parcelNo(p.publicNo.toString()),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(label,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${p.pickupText} → ${p.destinationText}'),
            Text('${p.recipientName} · ${t.priceSom(groupThousands(p.fare))}'),
            if (p.isCancellable)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _cancel(p.id),
                  child: Text(t.taxiCancel),
                ),
              ),
          ],
        ),
      ),
    );
  }

  (String, Color) _statusInfo(AppLocalizations t, String status) {
    switch (status) {
      case 'ACCEPTED':
        return (t.parcelStatusAccepted, Colors.blue);
      case 'PICKED_UP':
        return (t.parcelStatusPickedUp, Colors.orange);
      case 'DELIVERED':
        return (t.parcelStatusDelivered, Colors.green);
      case 'CANCELLED':
        return (t.parcelStatusCancelled, Colors.red);
      default:
        return (t.parcelStatusPending, Colors.grey);
    }
  }
}

class _Spin extends StatelessWidget {
  const _Spin();
  @override
  Widget build(BuildContext context) => const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}
