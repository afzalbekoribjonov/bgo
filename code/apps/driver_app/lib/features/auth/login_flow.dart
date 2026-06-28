import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/language_button.dart';
import 'auth_controller.dart';

/// Haydovchi kirishi: telefon -> administrator bergan 8 xonali kod.
/// Ro'yxatdan o'tish yo'q — haydovchi admin tomonidan qo'shiladi.
class LoginFlow extends ConsumerStatefulWidget {
  const LoginFlow({super.key});

  @override
  ConsumerState<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends ConsumerState<LoginFlow> {
  final _phoneCtrl = TextEditingController(text: '+998');
  final _codeCtrl = TextEditingController();

  bool _codeStep = false;
  bool _loading = false;
  String? _error;
  String _phone = '';

  static final _phoneRegex = RegExp(r'^\+998\d{9}$');

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  /// 1-bosqich: raqamni tekshirish (bizning haydovchimi?).
  Future<void> _continue() async {
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

  /// 2-bosqich: 8 xonali kod bilan kirish.
  Future<void> _login() async {
    final t = AppLocalizations.of(context)!;
    final code = _codeCtrl.text.trim();
    if (code.length != 8) {
      setState(() => _error = "Kod 8 xonali bo‘lishi kerak");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .driverLogin(_phone, code);
      // muvaffaqiyatli — AuthGate avtomatik bosh ekranga o'tkazadi
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = isNetworkError(e)
            ? t.errorNetwork
            : (httpStatus(e) == 401
                ? "Kod noto‘g‘ri. Administratordan tekshiring."
                : t.errorGeneric);
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
          child: _codeStep ? _buildCodeStep(t) : _buildPhoneStep(t),
        ),
      ),
    );
  }

  Widget _buildPhoneStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.local_taxi, size: 56),
        const SizedBox(height: 16),
        Text('Haydovchi kirishi',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Administrator ro‘yxatga olgan telefon raqamingizni kiriting.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
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
          onPressed: _loading ? null : _continue,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: _loading ? const _Spinner() : const Text('Davom etish'),
        ),
      ],
    );
  }

  Widget _buildCodeStep(AppLocalizations t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.password, size: 56),
        const SizedBox(height: 16),
        Text('Kirish kodi',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          'Administrator bergan 8 xonali kodni kiriting.\n$_phone',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          autofocus: true,
          style: const TextStyle(fontSize: 24, letterSpacing: 8),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          decoration: const InputDecoration(
            counterText: '',
            hintText: '••••••••',
            border: OutlineInputBorder(),
          ),
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _loading ? null : _login,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          child: _loading ? const _Spinner() : const Text('Kirish'),
        ),
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
