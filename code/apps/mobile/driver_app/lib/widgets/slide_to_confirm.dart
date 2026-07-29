import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Surib tasdiqlash — jonli premium slider:
/// • bo'sh holatda yo'nalish bo'ylab yugurayotgan shimmer + ketma-ket
///   pulslanuvchi chevronlar (qaysi tomonga surishni o'zi "aytib turadi");
/// • surilganda surgich kattalashadi va porlashi kuchayadi, yarmida yengil
///   vibratsiya; qo'yib yuborilsa prujinaday orqaga qaytadi;
/// • tasdiqda surgich rangga to'lib, oq belgi bilan "pop" qiladi.
/// reverse=false: chapdan o'ngga; reverse=true: o'ngdan chapga.
class SlideToConfirm extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color fillColor;
  final VoidCallback onConfirmed;
  final double height;
  final bool reverse;
  final bool glow;

  const SlideToConfirm({
    super.key,
    required this.label,
    required this.icon,
    required this.fillColor,
    required this.onConfirmed,
    this.height = 76,
    this.reverse = false,
    this.glow = false,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm>
    with TickerProviderStateMixin {
  double _p = 0;
  bool _done = false;
  bool _dragging = false;
  bool _hapticHalf = false;

  /// Doimiy tsikl — shimmer va chevron pulslari uchun (2.2s).
  late final AnimationController _idle;

  /// Qo'yib yuborilganda prujinali qaytish.
  late final AnimationController _return;

  @override
  void initState() {
    super.initState();
    _idle = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
    _return = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _return.addListener(() {
      setState(() {
        _p = _returnTween.transform(
            Curves.easeOutBack.transform(_return.value));
      });
    });
  }

  Tween<double> _returnTween = Tween(begin: 0, end: 0);

  @override
  void dispose() {
    _idle.dispose();
    _return.dispose();
    super.dispose();
  }

  void _springBack() {
    _returnTween = Tween(begin: _p, end: 0);
    _return.forward(from: 0);
  }

  void _confirm() {
    setState(() {
      _p = 1;
      _done = true;
    });
    HapticFeedback.heavyImpact();
    widget.onConfirmed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const pad = 5.0;
    final thumb = widget.height - pad * 2;
    final reverse = widget.reverse;
    return LayoutBuilder(
      builder: (ctx, c) {
        final maxDx = c.maxWidth - thumb - pad * 2;
        final thumbLeft = (reverse ? (1 - _p) : _p) * maxDx;
        final fillW = (reverse ? (maxDx - thumbLeft) : thumbLeft) + thumb;
        return GestureDetector(
          onHorizontalDragStart: (_) {
            if (_done) return;
            _return.stop();
            _hapticHalf = false;
            HapticFeedback.selectionClick();
            setState(() => _dragging = true);
          },
          onHorizontalDragUpdate: (d) {
            if (_done || maxDx <= 0 || !_dragging) return;
            final delta = (reverse ? -d.delta.dx : d.delta.dx) / maxDx;
            final np = (_p + delta).clamp(0.0, 1.0);
            if (!_hapticHalf && np >= 0.5) {
              _hapticHalf = true;
              HapticFeedback.mediumImpact();
            }
            setState(() => _p = np);
          },
          onHorizontalDragEnd: (_) {
            if (_done) return;
            _dragging = false;
            if (_p >= 0.85) {
              _confirm();
            } else {
              _springBack();
            }
          },
          child: Container(
            height: widget.height,
            padding: const EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(widget.height / 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(thumb / 2 + pad),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Yugurayotgan shimmer (faqat boshlang'ich holatda ko'rinadi)
                  if (!_done)
                    AnimatedBuilder(
                      animation: _idle,
                      builder: (_, __) {
                        final t = _idle.value;
                        final x = (reverse ? (1 - t) : t) * 2 - 0.5;
                        return Opacity(
                          opacity: (0.55 - _p * 2).clamp(0.0, 0.55),
                          child: Align(
                            alignment: Alignment(x * 2 - 1, 0),
                            child: Container(
                              width: c.maxWidth * 0.28,
                              height: widget.height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0),
                                    Colors.white.withValues(alpha: 0.35),
                                    Colors.white.withValues(alpha: 0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  // Ketma-ket pulslanuvchi 3 chevron — yo'nalish darak
                  if (!_done)
                    Positioned(
                      left: reverse ? 18 : null,
                      right: reverse ? null : 18,
                      child: AnimatedBuilder(
                        animation: _idle,
                        builder: (_, __) {
                          final t = _idle.value;
                          double op(int i) {
                            var v = (t * 1.6 - i * 0.22) % 1.0;
                            if (v < 0) v += 1;
                            // uchburchak to'lqin: 0→1→0
                            final tri = v < 0.5 ? v * 2 : (1 - v) * 2;
                            return (tri * (0.75 - _p * 2)).clamp(0.0, 0.75);
                          }

                          final ch = reverse
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded;
                          final idx = reverse ? [2, 1, 0] : [0, 1, 2];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final i in idx)
                                Opacity(
                                  opacity: op(i),
                                  child: Icon(ch,
                                      color: scheme.outline, size: 24),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  // To'lib boruvchi rangli qism
                  Align(
                    alignment: reverse
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: fillW.clamp(thumb, c.maxWidth),
                      height: thumb,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.fillColor,
                            Color.lerp(
                                widget.fillColor, Colors.black, 0.14)!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(thumb / 2),
                        boxShadow: _p > 0.02
                            ? [
                                BoxShadow(
                                  color: widget.fillColor
                                      .withValues(alpha: 0.35 * _p),
                                  blurRadius: 14,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                  // Yozuv — surilgan sari oqarib, yengil siljiydi
                  Transform.translate(
                    offset: Offset((reverse ? -1 : 1) * _p * 8, 0),
                    child: Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color:
                            Color.lerp(scheme.onSurface, Colors.white, _p),
                      ),
                    ),
                  ),
                  // Surgich — bosilganda kattalashadi, tasdiqda rangga to'ladi
                  Positioned(
                    left: thumbLeft,
                    child: AnimatedScale(
                      scale: _done ? 1.12 : (_dragging ? 1.08 : 1.0),
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: thumb,
                        height: thumb,
                        decoration: BoxDecoration(
                          color: _done ? widget.fillColor : Colors.white,
                          shape: BoxShape.circle,
                          border: _done
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                          boxShadow: [
                            if (widget.glow || _dragging)
                              BoxShadow(
                                color: widget.fillColor.withValues(
                                    alpha: _dragging ? 0.85 : 0.7),
                                blurRadius: _dragging ? 20 : 16,
                                spreadRadius: _dragging ? 2 : 1,
                              ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.22),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _done ? Icons.check_rounded : widget.icon,
                          color: _done ? Colors.white : widget.fillColor,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
