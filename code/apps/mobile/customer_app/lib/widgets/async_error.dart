import 'package:flutter/material.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Professional xato holati: yumshoq doiradagi ikonka + sarlavha + izoh +
/// gradient RETRY tugmasi. Tarmoq xatosida wifi-off, boshqasida ogohlantirish.
class AsyncErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  /// ListView/RefreshIndicator ichida ishlatish uchun scroll o'rab beradi.
  final bool scrollable;

  const AsyncErrorRetry({
    super.key,
    required this.error,
    required this.onRetry,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final network = isNetworkError(error);
    final color = network ? AppTheme.brand : scheme.error;

    final content = Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                network
                    ? Icons.wifi_off_rounded
                    : Icons.error_outline_rounded,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              network ? 'Internet aloqasi yo\'q' : 'Xatolik yuz berdi',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              network
                  ? 'Aloqani tekshirib, qayta urining — ma\'lumotlaringiz saqlanadi.'
                  : 'Kutilmagan xatolik. Bir ozdan so\'ng qayta urining.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: scheme.outline, height: 1.4),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.brand, AppTheme.brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.brand.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onRetry,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 26, vertical: 13),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 19),
                        const SizedBox(width: 8),
                        Text(t.retry,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (!scrollable) return content;
    return LayoutBuilder(
      builder: (_, c) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: c.maxHeight, child: content),
      ),
    );
  }
}
