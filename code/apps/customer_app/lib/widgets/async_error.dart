import 'package:flutter/material.dart';

import '../core/error_text.dart';
import '../l10n/generated/app_localizations.dart';

/// AsyncValue xato holati uchun umumiy ko'rinish (xabar + qayta urinish).
class AsyncErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const AsyncErrorRetry({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final message = isNetworkError(error) ? t.errorNetwork : t.errorGeneric;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(onPressed: onRetry, child: Text(t.retry)),
          ],
        ),
      ),
    );
  }
}
