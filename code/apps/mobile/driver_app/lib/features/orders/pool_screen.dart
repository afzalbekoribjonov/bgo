import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/nav_support.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'offer_api.dart';

/// Qabul qilinmagan buyurtmalar (pool) — istalgan haydovchi olishi mumkin.
class PoolScreen extends ConsumerStatefulWidget {
  const PoolScreen({super.key});

  @override
  ConsumerState<PoolScreen> createState() => _PoolScreenState();
}

class _PoolScreenState extends ConsumerState<PoolScreen> {
  String? _busy;
  LatLng? _me;

  @override
  void initState() {
    super.initState();
    driverCurrentLatLng().then((p) {
      if (mounted && p != null) setState(() => _me = p);
    });
  }

  /// Joriy joydan pickup'gача masofa (km).
  String? _distance(DriverOffer o) {
    if (_me == null) return null;
    final km = const Distance().as(LengthUnit.Kilometer, _me!, o.pickup);
    return '${km.toStringAsFixed(1)} km';
  }

  Future<void> _take(DriverOffer o) async {
    setState(() => _busy = o.orderId);
    try {
      await ref.read(offerApiProvider).acceptFromPool(o.orderId);
      if (!mounted) return;
      ref.invalidate(poolProvider);
      // Olingan buyurtmani bosh ekranga qaytaramiz — u faol safar oynasini ochadi.
      Navigator.of(context).pop(o);
    } catch (e) {
      if (mounted) {
        final t = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNetworkError(e) ? 'Tarmoq xatosi' : t.homeOrderGone)),
        );
        ref.invalidate(poolProvider);
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(poolProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.poolTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(poolProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AsyncErrorRetry(
            error: e,
            scrollable: true,
            onRetry: () => ref.invalidate(poolProvider),
          ),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 100),
                Icon(Icons.inbox_rounded, size: 56, color: scheme.outlineVariant),
                const SizedBox(height: 12),
                Center(
                  child: Text(t.poolEmpty,
                      style: TextStyle(color: scheme.outline)),
                ),
              ]);
            }
            // "Uyga" rejimi mos kelganlar (bo'lsa) ro'yxat boshida — tavsiya,
            // qolganlari ham ko'rinishda davom etadi (qattiq filtr emas).
            final matches = list.where((o) => o.homeModeMatch).toList();
            final others = list.where((o) => !o.homeModeMatch).toList();
            final sorted = [...matches, ...others];
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _card(t, sorted[i]),
            );
          },
        ),
      ),
    );
  }

  (String, IconData, Color) _verticalInfo(AppLocalizations t, String v) {
    switch (v) {
      case 'taxi':
        return (t.taxiTab, Icons.local_taxi_rounded, const Color(0xFF8A6D1B));
      case 'parcel':
        return (t.deliveryTab, Icons.local_shipping_rounded, const Color(0xFF1565C0));
      default:
        return (t.vertFood, Icons.restaurant_rounded, const Color(0xFFEF6C00));
    }
  }

  Widget _card(AppLocalizations t, DriverOffer o) {
    final (vLabel, vIcon, vColor) = _verticalInfo(t, o.vertical);
    final busy = _busy == o.orderId;
    final scheme = Theme.of(context).colorScheme;
    final dist = _distance(o);
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: vColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(vIcon, color: vColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vLabel,
                          style: TextStyle(fontSize: 11, color: vColor, fontWeight: FontWeight.w700)),
                      Text(o.pickupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text("+${groupThousands(o.earning)} so'm",
                    style: const TextStyle(
                        color: Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: 14)),
              ],
            ),
            if (o.homeModeMatch) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.home_rounded, size: 13, color: Color(0xFFB8860B)),
                    const SizedBox(width: 4),
                    Text(t.homeModeLabel,
                        style: const TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFFB8860B))),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                if (dist != null) ...[
                  Icon(Icons.route_rounded, size: 13, color: scheme.outline),
                  const SizedBox(width: 4),
                  Text(dist, style: TextStyle(fontSize: 12, color: scheme.outline)),
                  const SizedBox(width: 14),
                ],
                Icon(Icons.payments_outlined, size: 13, color: scheme.outline),
                const SizedBox(width: 4),
                Text("${groupThousands(o.amount)} so'm",
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
              ],
            ),
            if (o.dropoffText?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.flag_rounded, size: 14, color: Color(0xFFE53935)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(o.dropoffText!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: scheme.outline)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: busy ? null : () => _take(o),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: busy
                  ? const SizedBox(
                      height: 18, width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded, size: 20),
              label: Text(busy ? t.poolLoading : t.poolTake),
            ),
          ],
        ),
      ),
    );
  }
}
