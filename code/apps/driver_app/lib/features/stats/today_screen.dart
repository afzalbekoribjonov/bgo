import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
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

  static const _periods = [
    ('today', 'Kunlik'),
    ('week', 'Haftalik'),
    ('month', 'Oylik'),
  ];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(driverStatsProvider(_period));
    return Scaffold(
      appBar: AppBar(title: const Text('Bugun · Statistika')),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Ma‘lumot yuklanmadi')),
              data: (s) => RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(driverStatsProvider(_period)),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _summary('Bajarilgan', '${s.totalCount} ta',
                              const Color(0xFF1E88E5), Icons.check_circle_rounded),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _summary(
                              'Daromad',
                              '${groupThousands(s.totalEarning)} so‘m',
                              const Color(0xFF2E7D32),
                              Icons.payments_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Daromad grafigi',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 10),
                    _BarChart(points: s.daily),
                    const SizedBox(height: 20),
                    Text('Bajarilgan buyurtmalar (${s.orders.length})',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    if (s.orders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text('Bu davrda buyurtma yo‘q',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.outline)),
                        ),
                      )
                    else
                      ...s.orders.map(_orderTile),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          for (final (value, label) in _periods)
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

  Widget _orderTile(StatOrder o) {
    final emoji = o.type == 'taxi' ? '🚕' : (o.type == 'parcel' ? '📦' : '🍽️');
    final name = o.type == 'taxi' ? 'Taksi' : (o.type == 'parcel' ? 'Dostavka' : 'Ovqat');
    final dt = DateTime.tryParse(o.createdAt)?.toLocal();
    final when = dt == null
        ? ''
        : '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 26)),
        title: Text('$name · ${groupThousands(o.amount)} so‘m',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(when),
        trailing: Text('+${groupThousands(o.earning)}',
            style: const TextStyle(
                color: Color(0xFF2E7D32), fontWeight: FontWeight.w800)),
      ),
    );
  }
}

/// Oddiy ustunli grafik (kunlik daromad).
class _BarChart extends StatelessWidget {
  final List<StatPoint> points;
  const _BarChart({required this.points});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (points.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('Ma‘lumot yo‘q')),
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
