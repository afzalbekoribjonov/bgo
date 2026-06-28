import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/nav_support.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Buyurtma sizga biriktirildi')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isNetworkError(e) ? 'Tarmoq xatosi' : 'Buyurtma endi mavjud emas')),
        );
        ref.invalidate(poolProvider);
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(poolProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Bo‘sh buyurtmalar')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(poolProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(children: const [
            SizedBox(height: 80),
            Center(child: Text('Yuklanmadi')),
          ]),
          data: (list) {
            if (list.isEmpty) {
              return ListView(children: [
                const SizedBox(height: 100),
                Icon(Icons.inbox_rounded, size: 56, color: scheme.outlineVariant),
                const SizedBox(height: 12),
                Center(
                  child: Text('Hozircha bo‘sh buyurtma yo‘q',
                      style: TextStyle(color: scheme.outline)),
                ),
              ]);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _card(list[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _card(DriverOffer o) {
    final emoji = o.vertical == 'taxi' ? '🚕' : (o.vertical == 'parcel' ? '📦' : '🍽️');
    final busy = _busy == o.orderId;
    final scheme = Theme.of(context).colorScheme;
    final dist = _distance(o);
    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(o.pickupName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                Text('+${groupThousands(o.earning)} so‘m',
                    style: const TextStyle(
                        color: Color(0xFF2E7D32), fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 5),
            // Masofa + narx (kichik shrift)
            Row(
              children: [
                if (dist != null) ...[
                  const Icon(Icons.route_rounded, size: 13, color: Color(0xFF1565C0)),
                  const SizedBox(width: 4),
                  Text(dist, style: TextStyle(fontSize: 12, color: scheme.outline)),
                  const SizedBox(width: 14),
                ],
                const Icon(Icons.payments_rounded, size: 13, color: Color(0xFF2E7D32)),
                const SizedBox(width: 4),
                Text('${groupThousands(o.amount)} so‘m',
                    style: TextStyle(fontSize: 12, color: scheme.outline)),
              ],
            ),
            if (o.dropoffText?.isNotEmpty == true) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.flag_rounded, size: 16, color: Color(0xFFE53935)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(o.dropoffText!, maxLines: 1, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            const SizedBox(height: 10),
            FilledButton(
              onPressed: busy ? null : () => _take(o),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              child: busy
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Olish'),
            ),
          ],
        ),
      ),
    );
  }
}
