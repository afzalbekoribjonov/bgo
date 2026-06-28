import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/uz_phone.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/language_button.dart';
import 'auth_controller.dart';

/// Haydovchi kirishi: telefon -> administrator bergan 8 xonali kod.
/// Zamonaviy, keng va qulay ko'rinish. plan/06-driver-app.md
class LoginFlow extends ConsumerStatefulWidget {
  const LoginFlow({super.key});

  @override
  ConsumerState<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends ConsumerState<LoginFlow> {
  final _phoneCtrl = TextEditingController(text: UzPhoneFormatter.format(''));
  final _codeCtrl = TextEditingController();

  bool _codeStep = false;
  bool _loading = false;
  String? _error;
  String _phone = '';

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final t = AppLocalizations.of(context)!;
    if (!UzPhoneFormatter.isComplete(_phoneCtrl.text)) {
      setState(() => _error = t.errorInvalidPhone);
      return;
    }
    final phone = UzPhoneFormatter.e164(_phoneCtrl.text);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final exists =
          await ref.read(authControllerProvider.notifier).checkDriver(phone);
      if (!mounted) return;
      if (!exists) {
        setState(() {
          _loading = false;
          _error =
              'Siz bizning haydovchimiz emassiz. Iltimos, administrator bilan bog‘laning.';
        });
        return;
      }
      setState(() {
        _phone = phone;
        _codeStep = true;
        _loading = false;
        _codeCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = isNetworkError(e) ? t.errorNetwork : t.errorGeneric;
      });
    }
  }

  Future<void> _login() async {
    final t = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim();
    if (code.length != 8) {
      setState(() => _error = 'Kod 8 xonali bo‘lishi kerak');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).driverLogin(_phone, code);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = isNetworkError(e)
            ? t.errorNetwork
            : (httpStatus(e) == 401
                ? 'Kod noto‘g‘ri. Administratordan tekshiring.'
                : t.errorGeneric);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        children: [
          _header(t, scheme),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: _codeStep ? _codeStepView(t, scheme) : _phoneStepView(t, scheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations t, ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 0, 12, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, const Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Theme(
                data: Theme.of(context).copyWith(
                  iconTheme: const IconThemeData(color: Colors.white),
                ),
                child: const LanguageButton(),
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.local_taxi_rounded,
                  color: Colors.white, size: 38),
            ),
            const SizedBox(height: 16),
            const Text(
              'Beshariq Haydovchi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Hisobingizga kiring',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _phoneStepView(AppLocalizations t, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Telefon raqamingiz',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Administrator ro‘yxatga olgan raqamni kiriting.',
          style: TextStyle(color: scheme.outline, fontSize: 14),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          autofocus: true,
          inputFormatters: [UzPhoneFormatter()],
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          decoration: _fieldDecoration(
            scheme,
            prefixIcon: Icons.phone_rounded,
          ),
        ),
        if (_error != null) _errorText(scheme),
        const SizedBox(height: 26),
        _primaryButton(
          label: 'Davom etish',
          onPressed: _continue,
        ),
      ],
    );
  }

  Widget _codeStepView(AppLocalizations t, ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Kirish kodi',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          'Administrator bergan 8 xonali kodni kiriting.',
          style: TextStyle(color: scheme.outline, fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(_phone,
            style: TextStyle(
                color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 22),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: 10,
          ),
          decoration: _fieldDecoration(scheme, hint: '••••••••'),
        ),
        if (_error != null) _errorText(scheme),
        const SizedBox(height: 26),
        _primaryButton(label: 'Kirish', onPressed: _login),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading
              ? null
              : () => setState(() {
                    _codeStep = false;
                    _error = null;
                  }),
          child: const Text('← Raqamni o‘zgartirish'),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration(ColorScheme scheme,
      {IconData? prefixIcon, String? hint}) {
    return InputDecoration(
      counterText: '',
      hintText: hint,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onPressed}) {
    return FilledButton(
      onPressed: _loading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
      child: _loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Text(label),
    );
  }

  Widget _errorText(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: scheme.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(_error!, style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
    );
  }
}
