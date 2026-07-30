import 'package:flutter/material.dart';

import 'package:beshariq_core/async_error_retry.dart' as core;
import '../l10n/generated/app_localizations.dart';
import '../theme/app_theme.dart';

/// Ilovaning o'z brend rangi/lokalizatsiyasi bilan o'ralgan umumiy xato-holat
/// widget'i (asosiy ko'rinish `beshariq_core`da — 2 ilova o'rtasida ulashiladi).
class AsyncErrorRetry extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
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
    return core.AsyncErrorRetry(
      error: error,
      onRetry: onRetry,
      scrollable: scrollable,
      retryLabel: t.retry,
      networkColor: AppTheme.brand,
      retryGradient: const [AppTheme.brand, AppTheme.brandDark],
    );
  }
}
