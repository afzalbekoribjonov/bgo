import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:beshariq_core/beshariq_core.dart';
import '../../core/uz_phone.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../theme/driver_colors.dart';
import '../../widgets/language_button.dart';
import 'auth_controller.dart';

const _deepGreen = DriverColors.deepGreen;
const _darkGreen = Color(0xFF0D3311);
const _gold = DriverColors.gold;

/// Haydovchi kirishi: telefon -> administrator bergan 8 xonali kod.
/// Brend qahramon (to'q yashil gradient + oltin uchqunlar + pulsli logo)
/// va oq forma kartasi — mijoz ilovasi bilan bir dizayn tilida.
class LoginFlow extends ConsumerStatefulWidget {
  const LoginFlow({super.key});

  @override
  ConsumerState<LoginFlow> createState() => _LoginFlowState();
}

class _LoginFlowState extends ConsumerState<LoginFlow>
    with SingleTickerProviderStateMixin {
  final _phoneCtrl = TextEditingController(text: UzPhoneFormatter.format(''));
  final _codeCtrl = TextEditingController();

  bool _codeStep = false;
  bool _loading = false;
  String? _error;
  String _phone = '';

  /// Fon harakati: oltin uchqunlar + logo pulsi (bitta tsikl).
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
    final h = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2E7D32), _deepGreen, _darkGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            // Jonli fon: sekin ko'tarilib suzuvchi oltin uchqunlar.
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          iconTheme:
                              const IconThemeData(color: Colors.white),
                        ),
                        child: const LanguageButton(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                      child: Column(
                        children: [
                          SizedBox(height: h * 0.02),
                          _hero(),
                          SizedBox(height: h * 0.035),
                          // Oq forma kartasi
                          Container(
                            padding:
                                const EdgeInsets.fromLTRB(20, 24, 20, 20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.28),
                                  blurRadius: 30,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _codeStep
                                  ? _codeStepView(t)
                                  : _phoneStepView(t),
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

  /// Brend qahramon: pulsli rul belgisi + "Beshariq Driver" + ish chiplari.
  Widget _hero() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _motion,
          builder: (_, child) {
            final pulse = math.sin(_motion.value * 2 * math.pi * 2);
            return Transform.scale(
              scale: 1 + 0.035 * pulse,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                      color: _gold.withValues(alpha: 0.55), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: _gold.withValues(
                          alpha: 0.14 + 0.12 * (pulse + 1) / 2),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child,
              ),
            );
          },
          child: const Icon(Icons.local_taxi_rounded,
              color: _gold, size: 46),
        ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(children: [
            const TextSpan(
              text: 'Beshariq ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            TextSpan(
              text: 'Driver',
              style: TextStyle(
                color: _gold,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                shadows: [
                  Shadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 8),
        Text(
          'Haydovchilar uchun ish kabinasi',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        // Nima ish qilinadi — 3 chip, har biri o'z fazasida suzadi.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _serviceChip(Icons.local_taxi_rounded, 'Taksi', 0),
            const SizedBox(width: 8),
            _serviceChip(Icons.restaurant_rounded, 'Ovqat', 1),
            const SizedBox(width: 8),
            _serviceChip(Icons.local_shipping_rounded, 'Dostavka', 2),
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
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: _gold),
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

  Widget _phoneStepView(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('phone'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Telefon raqamingiz',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          'Administrator ro‘yxatga olgan raqamni kiriting',
          style: TextStyle(color: scheme.outline, fontSize: 13),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [UzPhoneFormatter()],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
          decoration: _fieldDecoration(
            scheme,
            prefixIcon: Icons.phone_iphone_rounded,
          ),
        ),
        if (_error != null) _errorText(scheme),
        const SizedBox(height: 20),
        _primaryButton(
          label: 'Davom etish',
          icon: Icons.arrow_forward_rounded,
          onPressed: _continue,
        ),
      ],
    );
  }

  Widget _codeStepView(AppLocalizations t) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      key: const ValueKey('code'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Kirish kodi',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(
          'Administrator bergan 8 xonali kodni kiriting',
          style: TextStyle(color: scheme.outline, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(Icons.phone_rounded, size: 14, color: scheme.primary),
            const SizedBox(width: 5),
            Text(_phone,
                style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
        const SizedBox(height: 18),
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
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
          ),
          decoration: _fieldDecoration(scheme, hint: '••••••••'),
        ),
        if (_error != null) _errorText(scheme),
        const SizedBox(height: 20),
        _primaryButton(
            label: 'Kirish', icon: Icons.lock_open_rounded, onPressed: _login),
        const SizedBox(height: 4),
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
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.8),
      ),
    );
  }

  /// Gradient CTA — brend yashil, soyali, yuklanish holati bilan.
  Widget _primaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final enabled = !_loading;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.6,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2E7D32), _deepGreen],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.38),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: _loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, color: Colors.white, size: 20),
                        const SizedBox(width: 9),
                        Text(label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            )),
                      ],
                    ),
            ),
          ),
        ),
      ),
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

/// Bitta ko'tarilayotgan uchqun: joy, o'lcham, tezlik va faza.
class _Ember {
  final double x;
  final double start;
  final double r;
  final double speed;
  final double wobble;
  const _Ember(this.x, this.start, this.r, this.speed, this.wobble);
}

/// Login fonidagi oltin uchqunlar — sekin ko'tarilib, yon-veriga suzadi.
class _EmberPainter extends CustomPainter {
  final double t;

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
      final p = (e.start + t * e.speed) % 1.0;
      final y = size.height * (1.06 - p * 1.16);
      final x = size.width * e.x +
          math.sin(t * 2 * math.pi * 1.5 + e.wobble) * 12;
      final alpha = 0.06 + 0.10 * (1 - p);
      paint.color = _gold.withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), e.r, paint);
    }
  }

  @override
  bool shouldRepaint(_EmberPainter old) => old.t != t;
}
