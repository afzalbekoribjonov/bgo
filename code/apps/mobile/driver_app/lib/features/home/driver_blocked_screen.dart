import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';

const _gold = Color(0xFFD4AF37);

/// Haydovchi liniyaga chiqishga uringanda backend `DRIVER_BLOCKED` qaytarsa
/// ko'rsatiladigan to'liq ekranli holat: sabab + qolgan vaqt + ofisga kelish
/// orqali darhol blokdan chiqish haqida eslatma.
class DriverBlockedScreen extends StatelessWidget {
  final String? reason;
  final DateTime? blockedUntil;

  const DriverBlockedScreen({super.key, this.reason, this.blockedUntil});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final remaining = blockedUntil?.difference(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFF16161F),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.block_rounded,
                      size: 44, color: Colors.redAccent),
                ),
                const SizedBox(height: 22),
                Text(
                  t.driverBlockedTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  (reason != null && reason!.trim().isNotEmpty)
                      ? reason!.trim()
                      : t.driverBlockedNoReason,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.72),
                    height: 1.5,
                  ),
                ),
                if (remaining != null && remaining > Duration.zero) ...[
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          t.driverBlockedUntilLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatRemaining(t, remaining),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: _gold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd.MM.yyyy HH:mm')
                              .format(blockedUntil!.toLocal()),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _gold.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _gold.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.storefront_rounded, color: _gold, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.driverBlockedOfficeNote,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.82),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      t.driverBlockedClose,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRemaining(AppLocalizations t, Duration d) {
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return t.driverBlockedDaysHours(days, hours);
    if (d.inHours > 0) return t.driverBlockedHoursMinutes(d.inHours, minutes);
    return t.minutesValue(d.inMinutes < 1 ? 1 : d.inMinutes);
  }
}
