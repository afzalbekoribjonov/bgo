import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../auth/auth_api.dart';
import '../auth/driver_balance.dart';

/// Hisobim — balans + to'ldirish tarixi. plan/06-driver-app.md
class BalanceScreen extends ConsumerWidget {
  const BalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(driverBalanceProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Hisobim')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(driverBalanceProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(children: const [
            SizedBox(height: 80),
            Center(child: Text('Ma‘lumot yuklanmadi')),
          ]),
          data: (b) => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _balanceCard(b.balance),
              const SizedBox(height: 18),
              const Text('To‘ldirish tarixi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              if (b.topups.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('Hozircha to‘ldirishlar yo‘q',
                        style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  ),
                )
              else
                ...b.topups.map((t) => _topupTile(context, t)),
              const SizedBox(height: 18),
              _supportNote(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balanceCard(int balance) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.account_balance_wallet_rounded, color: Colors.white70),
              SizedBox(width: 8),
              Text('Joriy balans',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          Text('${groupThousands(balance)} so‘m',
              style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            balance > 0
                ? 'Buyurtmalarni qabul qilishingiz mumkin'
                : 'Buyurtma olish uchun hisobni to‘ldiring',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _topupTile(BuildContext context, DriverTopup t) {
    final dt = DateTime.tryParse(t.createdAt)?.toLocal();
    final when = dt == null
        ? ''
        : '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
            '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8F5E9),
          child: Icon(Icons.add_rounded, color: Color(0xFF2E7D32)),
        ),
        title: Text('+ ${groupThousands(t.amount)} so‘m',
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(t.note?.isNotEmpty == true ? '${t.note} · $when' : when),
      ),
    );
  }

  Widget _supportNote(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Text('ℹ️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Hisobni to‘ldirish uchun qo‘llab-quvvatlash xizmatiga murojaat qiling '
              'yoki ofisga tashrif buyuring.',
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
