import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/async_error.dart';
import '../auth/auth_api.dart';
import '../auth/driver_balance.dart';

/// Hisobim — balans + to'ldirish tarixi (kun/hafta/oy filtri bilan,
/// butun tarix ekranni to'ldirib yubormaydi). plan/06-driver-app.md
class BalanceScreen extends ConsumerStatefulWidget {
  const BalanceScreen({super.key});

  @override
  ConsumerState<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends ConsumerState<BalanceScreen> {
  String _period = 'today';

  List<(String, String)> _periods(AppLocalizations t) => [
        ('today', t.periodDaily),
        ('week', t.periodWeekly),
        ('month', t.periodMonthly),
      ];

  /// Tanlangan davr boshlanishi: kun — bugun 00:00; hafta — oxirgi 7 kun;
  /// oy — shu oyning 1-sanasi.
  DateTime get _since {
    final now = DateTime.now();
    switch (_period) {
      case 'week':
        return now.subtract(const Duration(days: 7));
      case 'month':
        return DateTime(now.year, now.month, 1);
      default:
        return DateTime(now.year, now.month, now.day);
    }
  }

  List<DriverTopup> _filtered(List<DriverTopup> all) {
    final since = _since;
    return [
      for (final t in all)
        if ((DateTime.tryParse(t.createdAt)?.toLocal() ?? since)
            .isAfter(since))
          t,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final async = ref.watch(driverBalanceProvider);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(t.walletTitle)),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(driverBalanceProvider),
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => AsyncErrorRetry(
            error: e,
            scrollable: true,
            onRetry: () => ref.invalidate(driverBalanceProvider),
          ),
          data: (b) {
            final items = _filtered(b.topups);
            final periodSum =
                items.fold<int>(0, (s, topup) => s + topup.amount);
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _balanceCard(t, b.balance),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: Text(t.balanceTopupHistory,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    if (items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: (periodSum >= 0
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828))
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${periodSum >= 0 ? '+' : '−'}${t.priceSom(groupThousands(periodSum.abs()))}",
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: periodSum >= 0
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFC62828)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                // Davr filtri — Kunlik / Haftalik / Oylik
                Row(
                  children: [
                    for (final (key, label) in _periods(t)) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _period = key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding:
                                const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: _period == key
                                  ? const LinearGradient(colors: [
                                      Color(0xFF2E7D32),
                                      Color(0xFF1B5E20),
                                    ])
                                  : null,
                              color: _period == key
                                  ? null
                                  : scheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _period == key
                                    ? Colors.white
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (key != 'month') const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_rounded,
                            size: 40,
                            color: scheme.outlineVariant),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                              t.balanceNoTopups,
                              style: TextStyle(color: scheme.outline)),
                        ),
                      ],
                    ),
                  )
                else
                  ...items.map((topup) => _topupTile(context, t, topup)),
                const SizedBox(height: 18),
                _supportNote(context, t),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _balanceCard(AppLocalizations t, int balance) {
    final hasBalance = balance > 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withValues(alpha: hasBalance ? 0.45 : 0.2),
            blurRadius: hasBalance ? 22 : 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(t.balanceCurrent,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
              const Spacer(),
              if (!hasBalance)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 14),
                      const SizedBox(width: 4),
                      Text(t.balanceLow, style: const TextStyle(color: Colors.orangeAccent, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(t.priceSom(groupThousands(balance)),
              style: const TextStyle(
                  color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -1)),
          const SizedBox(height: 6),
          Text(
            hasBalance
                ? t.balanceCanAccept
                : t.balanceMustTopup,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _topupTile(
      BuildContext context, AppLocalizations t, DriverTopup topup) {
    final dt = DateTime.tryParse(topup.createdAt)?.toLocal();
    final when = dt == null
        ? ''
        : '${dt.day.toString().padLeft(2, "0")}.${dt.month.toString().padLeft(2, "0")}.${dt.year} '
            '${dt.hour.toString().padLeft(2, "0")}:${dt.minute.toString().padLeft(2, "0")}';
    final scheme = Theme.of(context).colorScheme;
    // Manfiy yozuv — chiqim (komissiya/xizmat haqi balansdan yechilgan).
    final income = topup.amount >= 0;
    final color =
        income ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    final sign = income ? '+' : '−';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
                income ? Icons.add_rounded : Icons.remove_rounded,
                color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$sign ${t.priceSom(groupThousands(topup.amount.abs()))}",
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: color)),
                if ((topup.note?.isNotEmpty ?? false) || when.isNotEmpty)
                  Text(
                    topup.note?.isNotEmpty == true
                        ? '${topup.note} · $when'
                        : when,
                    style: TextStyle(fontSize: 12, color: scheme.outline),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _supportNote(BuildContext context, AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.info_outline_rounded, color: scheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.balanceSupportNote,
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
