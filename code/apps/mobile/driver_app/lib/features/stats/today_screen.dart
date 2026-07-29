import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import 'stats_api.dart';

/// Bugun — kunlik/haftalik/oylik statistika + grafik + buyurtmalar.
/// plan/06-driver-app.md
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  String _period = 'today';

  List<(String, String)> _periods(AppLocalizations t) => [
        ('today', t.periodDaily),
        ('week', t.periodWeekly),
        ('month', t.periodMonthly),
      ];

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(driverStatsProvider(_period));
    return Scaffold(
      appBar: AppBar(title: Text(t.statsTitle)),
      body: Column(
        children: [
          _filters(t),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => AsyncErrorRetry(
                error: e,
                onRetry: () => ref.invalidate(driverStatsProvider(_period)),
              ),
              data: (s) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(driverStatsProvider(_period)),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _summary(t.statsCompleted, '${s.totalCount} ta',
                              const Color(0xFF1E88E5), Icons.check_circle_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summary(
                              t.yourEarning,
                              t.priceSom(groupThousands(s.totalEarning)),
                              const Color(0xFF2E7D32),
                              Icons.payments_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(t.statsChartTitle,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    _BarChart(points: s.daily, t: t),
                    const SizedBox(height: 20),
                    Text(t.statsCompletedOrders(s.orders.length),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    if (s.orders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(t.statsNoOrders,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline)),
                        ),
                      )
                    else
                      ...s.orders.map((o) => _orderTile(t, o)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          for (final (value, label) in _periods(t))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: _period == value,
                showCheckmark: false,
                labelStyle: TextStyle(
                  color: _period == value ? Colors.white : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                selectedColor: scheme.primary,
                onSelected: (_) => setState(() => _period = value),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summary(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 12, color: color)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
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

  Widget _orderTile(AppLocalizations t, StatOrder o) {
    final (vLabel, vIcon, vColor) = _verticalInfo(t, o.type);
    final dt = DateTime.tryParse(o.createdAt)?.toLocal();
    String when = '';
    if (dt != null) {
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      when = '$d.$mo $h:$mi';
    }
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: vColor.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(vIcon, color: vColor, size: 20),
        ),
        title: Text("$vLabel · ${t.priceSom(groupThousands(o.amount))}",
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(when, style: const TextStyle(fontSize: 12)),
        trailing: Text("+${groupThousands(o.earning)}",
            style: const TextStyle(
                color: Color(0xFF2E7D32), fontWeight: FontWeight.w800, fontSize: 14)),
      ),
    );
  }
}

/// Oddiy ustunli grafik (kunlik daromad).
class _BarChart extends StatelessWidget {
  final List<StatPoint> points;
  final AppLocalizations t;
  const _BarChart({required this.points, required this.t});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.isEmpty) {
      return SizedBox(
        height: 140,
        child: Center(child: Text(t.statsNoData)),
      );
    }
    final maxE = points.map((p) => p.earning).fold<int>(0, (a, b) => a > b ? a : b);
    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final p in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: maxE == 0 ? 2 : 4 + (p.earning / maxE) * 96,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF66BB6A), Color(0xFF2E7D32)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p.date.length >= 10 ? p.date.substring(8, 10) : '',
                      style: TextStyle(fontSize: 9, color: scheme.outline),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
