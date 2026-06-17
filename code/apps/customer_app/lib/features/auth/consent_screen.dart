import 'package:flutter/material.dart';
import 'package:customer_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/error_text.dart';
import 'auth_controller.dart';

/// Maxfiylik va shartlarga rozilik. Majburiy. plan/10-auth-security.md
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _agreed = false;
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).submitConsent();
      // Holat -> authenticated, AuthGate bosh ekranga o'tadi.
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(t.consentTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.privacy_tip_outlined,
                  size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(t.consentBody, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                title: Text(t.consentCheckbox),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              const Spacer(),
              FilledButton(
                onPressed: (!_agreed || _loading) ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.continueButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
