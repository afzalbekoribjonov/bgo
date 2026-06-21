import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/language_button.dart';
import 'auth_controller.dart';

/// Haydovchi kirishi: telefon -> OTP.
class LoginFlow extends ConsumerStatefulWidget {
  const LoginFlow({super.key});

  @override
  ConsumerState<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends ConsumerState<LoginFlow> {
  final _phoneCtrl = TextEditingController(text: '+998');
  final _codeCtrl = TextEditingController();

  bool _otpStep = false;
  bool _loading = false;
  String? _error;
  String? _devCode;
  String _phone = '';

  static final _phoneRegex = RegExp(r'^\+998\d{9}$');

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final t = AppLocalizations.of(context)!;
    final phone = _phoneCtrl.text.trim();
    if (!_phoneRegex.hasMatch(phone)) {
      setState(() => _error = t.errorInvalidPhone);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final code =
          await ref.read(authControllerProvider.notifier).requestOtp(phone);
      if (!mounted) return;
      setState(() {
        _phone = phone;
        _devCode = code;
        _otpStep = true;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = isNetworkError(e)
            ? t.errorNetwork
            : (httpStatus(e) == 400 ? t.errorInvalidPhone : t.errorGeneric);
      });
    }
  }

  Future<void> _verify() async {
    final t = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyOtp(_phone, _codeCtrl.text.trim());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = isNetworkError(e)
            ? t.errorNetwork
            : (httpStatus(e) == 400 ? t.errorInvalidCode : t.errorGeneric);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(t.appName),
        actions: const [LanguageButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _otpStep ? _buildOtpStep(t) : _buildPhoneStep(t),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(t.loginTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(t.loginSubtitle, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
            LengthLimitingTextInputFormatter(13),
          ],
          decoration: InputDecoration(
            labelText: t.phoneLabel,
            prefixIcon: const Icon(Icons.phone),
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _sendCode,
          child: _loading ? const _Spinner() : Text(t.sendCode),
        ),
      ],
    );
  }

  Widget _buildOtpStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(t.otpTitle, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(t.otpSubtitle(_phone), style: Theme.of(context).textTheme.bodyMedium),
        if (_devCode != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(t.devCodeHint(_devCode!)),
          ),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            labelText: t.otpLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _verify,
          child: _loading ? const _Spinner() : Text(t.verify),
        ),
        TextButton(
          onPressed: _loading
              ? null
              : () => setState(() {
                    _otpStep = false;
                    _error = null;
                    _codeCtrl.clear();
                  }),
          child: Text(t.resendCode),
        ),
      ],
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String message;
  const _ErrorText(this.message);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(message,
          style: TextStyle(color: Theme.of(context).colorScheme.error)),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 20,
      width: 20,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }
}
