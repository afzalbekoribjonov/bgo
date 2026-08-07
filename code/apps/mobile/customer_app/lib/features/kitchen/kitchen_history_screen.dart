import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/async_error.dart';
import 'kitchen_api.dart';
import 'kitchen_models.dart';

final kitchenHistoryProvider =
    FutureProvider.family<List<KitchenOrder>, String>((ref, restaurantId) {
  return ref.read(kitchenApiProvider).history(restaurantId);
});

/// Bajarilgan/bekor qilingan buyurtmalar tarixi.
class KitchenHistoryScreen extends ConsumerWidget {
  final String restaurantId;
  const KitchenHistoryScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(kitchenHistoryProvider(restaurantId));
    final scheme = Theme.of(context).colorScheme;

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: AsyncErrorRetry(error: e, onRetry: () => ref.invalidate(kitchenHistoryProvider(restaurantId))),
      ),
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history_rounded, size: 56, color: scheme.outline),
                const SizedBox(height: 12),
                Text("Tarix hozircha bo'sh", style: TextStyle(color: scheme.outline, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(kitchenHistoryProvider(restaurantId)),
          child: ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _HistoryRow(order: orders[i]),
          ),
        );
      },
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final KitchenOrder order;
  const _HistoryRow({required this.order});

  (String, Color) get _meta => switch (order.status) {
        KitchenOrderStatus.delivered || KitchenOrderStatus.completed => ('Yetkazildi', const Color(0xFF2E7D32)),
        KitchenOrderStatus.cancelled => ('Bekor qilindi', const Color(0xFFC62828)),
        KitchenOrderStatus.failed => ('Amalga oshmadi', const Color(0xFFC62828)),
        _ => ('Yakunlangan', const Color(0xFF616161)),
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = _meta;
    final d = order.createdAt.toLocal();
    final dateStr = '${d.day.toString().padLeft(2, "0")}.${d.month.toString().padLeft(2, "0")}.${d.year} '
        '${d.hour.toString().padLeft(2, "0")}:${d.minute.toString().padLeft(2, "0")}';

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4))),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('#${order.publicNo}', style: const TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                        child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(dateStr, style: TextStyle(color: scheme.outline, fontSize: 12)),
                ],
              ),
            ),
            Text('${order.itemsTotal} so\'m', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
          ],
        ),
      ),
    );
  }
}
