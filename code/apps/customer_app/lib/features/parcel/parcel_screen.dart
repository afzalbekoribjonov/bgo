import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import '../../core/format.dart';
import '../../core/places.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'parcel_api.dart';
import 'parcel_models.dart';

/// Dostavka (pochta) ekrani. plan/05-customer-app.md
/// Xarita ulanmaguncha: Beshariq preset nuqtalari.
class ParcelScreen extends ConsumerStatefulWidget {
  const ParcelScreen({super.key});

  @override
  ConsumerState<ParcelScreen> createState() => _ParcelScreenState();
}

class _ParcelScreenState extends ConsumerState<ParcelScreen> {
  GeoPlace? _from;
  GeoPlace? _to;
  ParcelSize _size = ParcelSize.small;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  ParcelEstimate? _estimate;
  bool _estimating = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

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
      final e = await ref.read(parcelApiProvider).estimate(_from!, _to!, _size);
      setState(() => _estimate = e);
    } catch (e) {
      setState(() =>
          _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric);
    } finally {
      if (mounted) setState(() => _estimating = false);
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
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(myParcelsProvider),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _placeDropdown(t.taxiFrom, Icons.my_location, _from,
                (p) => setState(() {
                      _from = p;
                      _estimate = null;
                    })),
            const SizedBox(height: 12),
            _placeDropdown(t.taxiTo, Icons.location_on, _to, (p) => setState(() {
                  _to = p;
                  _estimate = null;
                })),
            const SizedBox(height: 16),
            Text(t.parcelSize, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<ParcelSize>(
              segments: [
                ButtonSegment(value: ParcelSize.small, label: Text(t.parcelSizeSmall)),
                ButtonSegment(value: ParcelSize.medium, label: Text(t.parcelSizeMedium)),
                ButtonSegment(value: ParcelSize.large, label: Text(t.parcelSizeLarge)),
              ],
              selected: {_size},
              onSelectionChanged: (s) => setState(() {
                _size = s.first;
                _estimate = null;
              }),
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
            if (_estimate == null)
              FilledButton.tonal(
                onPressed: _estimating ? null : _doEstimate,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                child: _estimating ? const _Spin() : Text(t.taxiEstimate),
              )
            else
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                icon: _sending ? const _Spin() : const Icon(Icons.local_shipping),
                label: Text(t.parcelSend),
              ),
            const SizedBox(height: 24),
            Text(t.parcelMyParcels, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _buildParcels(t),
          ],
        ),
      ),
    );
  }

  Widget _placeDropdown(
    String label,
    IconData icon,
    GeoPlace? value,
    ValueChanged<GeoPlace?> onChanged,
  ) {
    return DropdownButtonFormField<GeoPlace>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final p in beshariqPlaces)
          DropdownMenuItem(value: p, child: Text(p.label)),
      ],
      onChanged: onChanged,
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
