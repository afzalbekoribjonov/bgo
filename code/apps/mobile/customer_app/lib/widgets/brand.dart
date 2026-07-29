import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Beshariq Go — umumiy brend komponentlari.
/// Barcha ekranlar bitta professional dizayn tilida gaplashishi uchun:
/// gradientli CTA tugma, pastki panel, marshrut (qayerdan→qayerga) maydoni,
/// xarita ustidagi dumaloq boshqaruv tugmasi.

/// Asosiy harakat tugmasi — brend gradienti + soya + yuklanish holati.
/// Oddiy FilledButton'dan farqi: chuqurlik (soya), gradient va aniq bosim
/// animatsiyasi — "haqiqiy ilova" his-tuyg'usi.
class BrandButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final double height;
  /// Ikkilamchi (xavf) rejimi — qizil gradient (bekor qilish kabi).
  final bool danger;

  const BrandButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.height = 56,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final colors = danger
        ? const [Color(0xFFE53935), Color(0xFFC62828)]
        : const [AppTheme.brand, AppTheme.brandDark];

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.55,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: colors.first.withValues(alpha: 0.38),
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
              child: loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 21),
                          const SizedBox(width: 9),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastki panel — dumaloq yuqori burchak, yumshoq soya, tortish dastasi.
/// Xaritali ekranlar (taksi/dostavka) pastki varag'i uchun yagona uslub.
class AppPanel extends StatelessWidget {
  final Widget child;
  /// SafeArea pastki bo'shlig'ini panelning o'zi boshqaradimi.
  final bool safeArea;

  const AppPanel({super.key, required this.child, this.safeArea = true});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.16),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: safeArea,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const SheetHandle(),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Tortish dastasi (pastki varaq ko'rsatkichi).
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Marshrut maydoni — "Qayerdan → Qayerga" bitta yaxlit kartada,
/// chapda yashil nuqta → chiziqcha → qizil pin (haqiqiy taksi ilovalari kabi).
class RouteFields extends StatelessWidget {
  final String fromLabel;
  final String toLabel;
  final bool fromFilled;
  final bool toFilled;
  final VoidCallback? onFromTap;
  final VoidCallback? onToTap;
  /// "Qayerga" qatorining o'ng tomonidagi qo'shimcha vidjet (masalan, toggle).
  final Widget? toTrailing;

  const RouteFields({
    super.key,
    required this.fromLabel,
    required this.toLabel,
    required this.fromFilled,
    required this.toFilled,
    this.onFromTap,
    this.onToTap,
    this.toTrailing,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      // Chegara chizig'isiz — yumshoq to'ldirilgan sirt (zerikarli borderlar yo'q).
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Chap ustun: nuqta → vertikal chiziq → pin
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                children: [
                  const SizedBox(height: 19),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                          width: 2.5,
                          strokeAlign: BorderSide.strokeAlignOutside),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.outlineVariant,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                  Icon(Icons.location_on,
                      size: 18, color: scheme.primary),
                  const SizedBox(height: 15),
                ],
              ),
            ),
            // O'ng ustun: ikkita bosiladigan qator
            Expanded(
              child: Column(
                children: [
                  _row(
                    context,
                    label: fromLabel,
                    filled: fromFilled,
                    onTap: onFromTap,
                    isTop: true,
                  ),
                  Divider(
                      height: 1,
                      indent: 0,
                      color: scheme.outlineVariant.withValues(alpha: 0.5)),
                  _row(
                    context,
                    label: toLabel,
                    filled: toFilled,
                    onTap: onToTap,
                    isTop: false,
                    trailing: toTrailing,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required bool filled,
    required bool isTop,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isTop ? const Radius.circular(16) : Radius.zero,
        bottom: isTop ? Radius.zero : const Radius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14.5,
                  color: filled ? scheme.onSurface : scheme.outline,
                  fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing,
            ] else if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child:
                    Icon(Icons.chevron_right, size: 20, color: scheme.outline),
              ),
          ],
        ),
      ),
    );
  }
}

/// Xarita ustidagi dumaloq boshqaruv tugmasi (masalan, "mening joyim").
/// Oq sirt + soya — xarita fonida aniq ko'rinadi.
class MapCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const MapCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: const CircleBorder(),
      elevation: 4,
      shadowColor: Colors.black38,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Tooltip(
          message: tooltip ?? '',
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, size: 22, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

/// "Beshariq Go" logotip yozuvi — ochiq fonda yoki gradient ustida.
class BrandLogo extends StatelessWidget {
  /// Gradient (to'q) fonda oq variant.
  final bool onDark;
  final double size;

  const BrandLogo({super.key, this.onDark = false, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final base = onDark ? Colors.white : Theme.of(context).colorScheme.onSurface;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(size * 0.28),
          decoration: BoxDecoration(
            gradient: onDark
                ? LinearGradient(colors: [
                    Colors.white.withValues(alpha: 0.28),
                    Colors.white.withValues(alpha: 0.14),
                  ])
                : const LinearGradient(
                    colors: [AppTheme.brand, AppTheme.brandDark]),
            borderRadius: BorderRadius.circular(size * 0.42),
          ),
          child: Icon(Icons.bolt_rounded,
              size: size, color: Colors.white),
        ),
        SizedBox(width: size * 0.42),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Beshariq ',
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: base,
                ),
              ),
              TextSpan(
                text: 'Go',
                style: TextStyle(
                  fontSize: size,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                  color: onDark ? const Color(0xFFFFD54F) : AppTheme.brand,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
