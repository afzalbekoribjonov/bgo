import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:customer_app/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/uz_phone.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand.dart';
import '../../widgets/language_button.dart';
import 'auth_controller.dart';

/// Kirish oqimi: telefon → OTP. Muvaffaqiyatli tasdiqlashdan keyin
/// AuthGate avtomatik keyingi ekranga (rozilik/bosh) o'tadi.
class LoginFlow extends ConsumerStatefulWidget {
  const LoginFlow({super.key});

  @override
  ConsumerState<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends ConsumerState<LoginFlow>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl =
      TextEditingController(text: UzPhoneFormatter.format(''));
  final _codeCtrl = TextEditingController();

  bool _otpStep = false;
  bool _loading = false;
  String? _error;
  String? _devCode;
  String? _telegramBotUrl;
  String _phone = '';

  /// Fon harakati: uchqunlar, logo pulsi va chiplar tebranishi — bitta tsikl.
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
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
      final res =
          await ref.read(authControllerProvider.notifier).requestOtp(phone);
      if (!mounted) return;
      setState(() {
        _phone = phone;
        _devCode = res.devCode;
        _telegramBotUrl = res.telegramBotUrl;
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
      // Holat o'zgaradi -> AuthGate boshqa ekranga o'tadi (bu yerda navigatsiya shart emas).
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
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      // Brend gradient fon — ilova kimligini birinchi soniyadan bildiradi.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.brand, AppTheme.brandDark, Color(0xFFBF360C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Jonli fon: sekin ko'tarilib suzuvchi yorug' uchqunlar.
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (_, __) => CustomPaint(
                    painter: _EmberPainter(_motion.value),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  // Yuqori qator: til tanlash
                  const Padding(
                    padding: EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: LanguageButton(),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        children: [
                          SizedBox(height: h * 0.03),
                          _hero(t),
                          SizedBox(height: h * 0.04),
                          // Oq forma kartasi
                          Container(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.22),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _otpStep
                                  ? _buildOtpStep(t)
                                  : _buildPhoneStep(t),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Brend qahramon qismi — logotip belgisi + "Beshariq Go" + xizmat ikonkalari.
  Widget _hero(AppLocalizations t) {
    return Column(
      children: [
        // Yaltiroq oq kvadratda yashin belgisi — yumshoq puls bilan "nafas oladi".
        AnimatedBuilder(
          animation: _motion,
          builder: (_, child) {
            final pulse =
                math.sin(_motion.value * 2 * math.pi * 2); // 2x tez puls
            return Transform.scale(
              scale: 1 + 0.035 * pulse,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white
                          .withValues(alpha: 0.10 + 0.08 * (pulse + 1) / 2),
                      blurRadius: 26,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child:
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 48),
        ),
        const SizedBox(height: 18),
        // Beshariq Go — yirik brend yozuvi
        Text.rich(
          TextSpan(children: [
            const TextSpan(
              text: 'Beshariq ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(
              text: 'Go',
              style: TextStyle(
                color: const Color(0xFFFFD54F),
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text(
          t.loginSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        // Xizmatlar qatori — har chip o'z fazasida yumshoq tebranadi (suzadi).
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _serviceChip(Icons.restaurant_rounded, t.serviceFood, 0),
            const SizedBox(width: 8),
            _serviceChip(Icons.local_taxi_rounded, t.serviceTaxi, 1),
            const SizedBox(width: 8),
            _serviceChip(Icons.delivery_dining_rounded, t.serviceDelivery, 2),
          ],
        ),
      ],
    );
  }

  Widget _serviceChip(IconData icon, String label, int index) {
    return AnimatedBuilder(
      animation: _motion,
      builder: (_, child) => Transform.translate(
        offset: Offset(
          0,
          2.6 * math.sin(_motion.value * 2 * math.pi + index * 2.1),
        ),
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneStep(AppLocalizations t) {
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.loginTitle,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(t.phoneLabel,
            style: TextStyle(
                color: Theme.of(context).colorScheme.outline, fontSize: 13)),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
          inputFormatters: [UzPhoneFormatter()],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_iphone_rounded),
          ),
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 20),
        BrandButton(
          label: t.sendCode,
          icon: Icons.arrow_forward_rounded,
          loading: _loading,
          onPressed: _loading ? null : _sendCode,
        ),
      ],
    );
  }

  Widget _buildOtpStep(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('otp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t.otpTitle,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(t.otpSubtitle(_phone),
            style: TextStyle(color: scheme.outline, fontSize: 13)),
        if (_devCode != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.secondaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              t.devCodeHint(_devCode!),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
        if (_telegramBotUrl != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _openUrl(_telegramBotUrl!),
            icon: const Icon(Icons.send, size: 18),
            label: Text(t.telegramFreeHint),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: _codeCtrl,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontSize: 26, letterSpacing: 10, fontWeight: FontWeight.w800),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(hintText: '••••••'),
        ),
        if (_error != null) _ErrorText(_error!),
        const SizedBox(height: 20),
        BrandButton(
          label: t.verify,
          icon: Icons.lock_open_rounded,
          loading: _loading,
          onPressed: _loading ? null : _verify,
        ),
        const SizedBox(height: 4),
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
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    );
  }
}

/// Bitta ko'tarilayotgan uchqun: boshlang'ich joy, o'lcham, tezlik va faza.
class _Ember {
  final double x; // gorizontal joy (0..1)
  final double start; // boshlang'ich balandlik fazasi (0..1)
  final double r; // radius (px)
  final double speed; // tsikl davomida necha marta ko'tariladi
  final double wobble; // yon tebranish fazasi
  const _Ember(this.x, this.start, this.r, this.speed, this.wobble);
}

/// Login fonidagi jonli uchqunlar — brend gradientida sekin ko'tarilib,
/// yon-veriga suzadi (olov uchqunlari kayfiyati, e'tiborni tortmaydi).
class _EmberPainter extends CustomPainter {
  final double t; // 0..1 takrorlanuvchi animatsiya qiymati

  _EmberPainter(this.t);

  static const _embers = [
    _Ember(0.08, 0.10, 5.0, 1.0, 0.0),
    _Ember(0.22, 0.55, 3.2, 1.4, 2.1),
    _Ember(0.35, 0.30, 7.0, 0.8, 4.2),
    _Ember(0.50, 0.75, 4.0, 1.2, 1.3),
    _Ember(0.63, 0.15, 3.0, 1.6, 3.4),
    _Ember(0.74, 0.60, 6.0, 0.9, 5.1),
    _Ember(0.88, 0.35, 4.5, 1.3, 0.7),
    _Ember(0.94, 0.85, 2.8, 1.7, 2.9),
    _Ember(0.15, 0.90, 5.5, 1.1, 4.8),
    _Ember(0.58, 0.45, 2.5, 1.9, 1.9),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final e in _embers) {
      // 0..1 oralig'ida yuqoriga siljish (aylanib qaytadi).
      final p = (e.start + t * e.speed) % 1.0;
      final y = size.height * (1.06 - p * 1.16);
      final x = size.width * e.x +
          math.sin(t * 2 * math.pi * 1.5 + e.wobble) * 12;
      // Yuqoriga chiqqan sari sekin so'nadi.
      final alpha = 0.05 + 0.09 * (1 - p);
      paint.color = Colors.white.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), e.r, paint);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => old.t != t;
}

