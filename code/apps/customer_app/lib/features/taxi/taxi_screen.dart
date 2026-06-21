import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/places.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../geo/geo_api.dart';
import 'taxi_api.dart';
import 'taxi_models.dart';

/// Taksi chaqirish ekrani. plan/05-customer-app.md
/// Xarita ulanmaguncha: Beshariq preset nuqtalari.
class TaxiScreen extends ConsumerStatefulWidget {
  const TaxiScreen({super.key});

  @override
  ConsumerState<TaxiScreen> createState() => _TaxiScreenState();
}

class _TaxiScreenState extends ConsumerState<TaxiScreen> {
  GeoPlace? _from;
  GeoPlace? _to;
  TaxiEstimate? _estimate;
  bool _estimating = false;
  bool _requesting = false;
  String? _error;

  Future<void> _doEstimate() async {
    final t = AppLocalizations.of(context)!;
    if (_from == null || _to == null) return;
    if (_from == _to) {
      setState(() => _error = t.taxiSamePoint);
      return;
    }
    setState(() {
      _estimating = true;
      _error = null;
      _estimate = null;
    });
    try {
      final e = await ref.read(taxiApiProvider).estimate(_from!, _to!);
      setState(() => _estimate = e);
    } catch (e) {
      setState(() =>
          _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
    } finally {
      if (mounted) setState(() => _estimating = false);
    }
  }

  Future<void> _request() async {
    final t = AppLocalizations.of(context)!;
    if (_from == null || _to == null || _from == _to) return;
    setState(() {
      _requesting = true;
      _error = null;
    });
    try {
      await ref.read(taxiApiProvider).request(_from!, _to!);
      ref.invalidate(myTripsProvider);
      if (!mounted) return;
      setState(() => _estimate = null);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t.taxiRequested)));
    } catch (e) {
      setState(() =>
          _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Future<void> _cancel(String id) async {
    final t = AppLocalizations.of(context)!;
    try {
      await ref.read(taxiApiProvider).cancel(id);
      ref.invalidate(myTripsProvider);
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
    final places = ref.watch(placesProvider).valueOrNull ?? beshariqPlaces;
    return Scaffold(
      appBar: AppBar(title: Text(t.taxiTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myTripsProvider);
          ref.invalidate(placesProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _placeDropdown(t.taxiFrom, Icons.my_location, _from, places,
                (p) => setState(() {
                      _from = p;
                      _estimate = null;
                    })),
            const SizedBox(height: 12),
            _placeDropdown(t.taxiTo, Icons.location_on, _to, places,
                (p) => setState(() {
                      _to = p;
                      _estimate = null;
                    })),
            const SizedBox(height: 16),
            if (_estimate != null) _estimateCard(t, _estimate!),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 12),
            if (_estimate == null)
              FilledButton.tonal(
                onPressed: _estimating ? null : _doEstimate,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48)),
                child: _estimating
                    ? const _Spin()
                    : Text(t.taxiEstimate),
              )
            else
              FilledButton.icon(
                onPressed: _requesting ? null : _request,
                style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52)),
                icon: _requesting ? const _Spin() : const Icon(Icons.local_taxi),
                label: Text(t.taxiRequest),
              ),
            const SizedBox(height: 24),
            Text(t.taxiMyTrips, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildTrips(t),
          ],
        ),
      ),
    );
  }

  Widget _placeDropdown(
    String label,
    IconData icon,
    GeoPlace? value,
    List<GeoPlace> places,
    ValueChanged<GeoPlace?> onChanged,
  ) {
    return DropdownButtonFormField<GeoPlace>(
      value: places.contains(value) ? value : null,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final p in places)
          DropdownMenuItem(value: p, child: Text(p.label)),
      ],
      onChanged: onChanged,
    );
  }

  Widget _estimateCard(AppLocalizations t, TaxiEstimate e) {
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

  Widget _buildTrips(AppLocalizations t) {
    final async = ref.watch(myTripsProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AsyncErrorRetry(
        error: e,
        onRetry: () => ref.invalidate(myTripsProvider),
      ),
      data: (trips) {
        if (trips.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(t.taxiNoTrips,
                style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          );
        }
        return Column(children: trips.map((tr) => _tripCard(t, tr)).toList());
      },
    );
  }

  Widget _tripCard(AppLocalizations t, TaxiTrip tr) {
    final (label, color) = _statusInfo(t, tr.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.taxiTripNo(tr.publicNo.toString()),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(label,
                    style:
                        TextStyle(color: color, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            Text('${tr.pickupText} → ${tr.destinationText}'),
            Text(t.priceSom(groupThousands(tr.fare))),
            if (tr.isCancellable)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _cancel(tr.id),
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
        return (t.taxiStatusAccepted, Colors.blue);
      case 'IN_PROGRESS':
        return (t.taxiStatusInProgress, Colors.orange);
      case 'COMPLETED':
        return (t.taxiStatusCompleted, Colors.green);
      case 'CANCELLED':
        return (t.taxiStatusCancelled, Colors.red);
      default:
        return (t.taxiStatusPending, Colors.grey);
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
