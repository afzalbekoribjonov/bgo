import 'package:flutter/material.dart';
import 'package:customer_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// Til almashtirish tugmasi (uz / uz-Cyrl / ru). plan/13-localization.md
class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppLocalizations.of(context)!;
    return PopupMenuButton<Locale>(
      icon: const Icon(Icons.language),
      tooltip: t.language,
      onSelected: (locale) => ref.read(localeProvider.notifier).state = locale,
      itemBuilder: (context) => const [
        PopupMenuItem(value: Locale('uz'), child: Text("O'zbekcha")),
        PopupMenuItem(
          value: Locale.fromSubtags(languageCode: 'uz', scriptCode: 'Cyrl'),
          child: Text('Ўзбекча'),
        ),
        PopupMenuItem(value: Locale('ru'), child: Text('Русский')),
      ],
    );
  }
}
