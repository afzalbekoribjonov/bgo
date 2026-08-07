import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../widgets/async_error.dart';
import 'kitchen_api.dart';
import 'kitchen_models.dart';

final kitchenStatsProvider =
    FutureProvider.family<KitchenStats, String>((ref, restaurantId) {
  return ref.read(kitchenApiProvider).stats(restaurantId);
});

/// Daromad — bugungi + umumiy statistika va 7-kunlik grafik.
class KitchenIncomeScreen extends ConsumerWidget {
  final String restaurantId;
  const KitchenIncomeScreen({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(kitchenStatsProvider(restaurantId));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: AsyncErrorRetry(error: e, onRetry: () => ref.invalidate(kitchenStatsProvider(restaurantId))),
      ),
      data: (stats) => RefreshIndicator(
        onRefresh: () async => ref.invalidate(kitchenStatsProvider(restaurantId)),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _SectionLabel('Bugun'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Daromad', value: '${_fmt(stats.todayRevenue)} so\'m', color: const Color(0xFF2E7D32))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Buyurtma', value: '${stats.todayOrders}', color: const Color(0xFF1565C0))),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Yetkazildi', value: '${stats.todayDelivered}', color: const Color(0xFF00838F))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'Bekor qilindi', value: '${stats.cancelledToday}', color: const Color(0xFFC62828))),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionLabel('Umumiy'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _StatCard(label: 'Jami daromad', value: '${_fmt(stats.totalRevenue)} so\'m', color: const Color(0xFF6A1B9A))),
                const SizedBox(width: 10),
                Expanded(child: _StatCard(label: 'O\'rtacha buyurtma', value: '${_fmt(stats.avgOrderValue)} so\'m', color: const Color(0xFFEF6C00))),
              ],
            ),
            const SizedBox(height: 22),
            const _SectionLabel('So\'nggi 7 kun'),
            const SizedBox(height: 14),
            _WeeklyChart(points: stats.weekly),
          ],
        ),
      ),
    );
  }
}

String _fmt(int value) {
  final s = value.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
    buf.write(s[i]);
  }
  return buf.toString();
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800));
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.85), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final List<WeeklyPoint> points;
  const _WeeklyChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Text('Ma\'lumot yo\'q', style: TextStyle(color: scheme.outline)),
        ),
      );
    }
    final maxRevenue = points.map((p) => p.revenue).fold<int>(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 160,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: points.map((p) {
          final h = maxRevenue == 0 ? 4.0 : 8 + (p.revenue / maxRevenue) * 120;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('${p.orders}', style: TextStyle(fontSize: 10, color: scheme.outline)),
                  const SizedBox(height: 4),
                  Container(
                    height: h,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.75),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_weekdayLabel(p.date), style: TextStyle(fontSize: 10.5, color: scheme.outline, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _weekdayLabel(DateTime d) {
    const names = ['Du', 'Se', 'Ch', 'Pa', 'Ju', 'Sh', 'Ya'];
    return names[d.weekday - 1];
  }
}
