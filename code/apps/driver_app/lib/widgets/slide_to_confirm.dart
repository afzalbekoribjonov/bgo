import 'package:flutter/material.dart';

/// Surib tasdiqlash — surilganda ichi tillo rangga to'ladi.
/// reverse=false: chapdan o'ngga; reverse=true: o'ngdan chapga. plan/06-driver-app.md
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
    this.height = 66,
    this.reverse = false,
    this.glow = false,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _p = 0;
  bool _done = false;
  bool _dragging = false;

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
        // To'lib boruvchi gold qism: surgich tomonidan to'ldiriladi.
        final fillW = (reverse ? (maxDx - thumbLeft) : thumbLeft) + thumb;
        final dur = Duration(milliseconds: _dragging ? 0 : 240);
        return GestureDetector(
          onHorizontalDragStart: (_) {
            if (!_done) setState(() => _dragging = true);
          },
          onHorizontalDragUpdate: (d) {
            if (_done || maxDx <= 0) return;
            final delta = (reverse ? -d.delta.dx : d.delta.dx) / maxDx;
            setState(() => _p = (_p + delta).clamp(0.0, 1.0));
          },
          onHorizontalDragEnd: (_) {
            _dragging = false;
            if (_p >= 0.85) {
              setState(() {
                _p = 1;
                _done = true;
              });
              widget.onConfirmed();
            } else {
              setState(() => _p = 0);
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Yo'nalish ko'rsatuvchi chevronlar (xira)
                Positioned(
                  left: reverse ? 20 : null,
                  right: reverse ? null : 20,
                  child: Opacity(
                    opacity: (0.5 - _p).clamp(0.0, 0.5),
                    child: Icon(
                      reverse ? Icons.keyboard_double_arrow_left
                              : Icons.keyboard_double_arrow_right,
                      color: scheme.outline,
                      size: 22,
                    ),
                  ),
                ),
                // To'lib boruvchi tillo qism
                Align(
                  alignment:
                      reverse ? Alignment.centerRight : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: dur,
                    curve: Curves.easeOut,
                    width: fillW.clamp(thumb, c.maxWidth),
                    height: thumb,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          widget.fillColor,
                          Color.lerp(widget.fillColor, Colors.black, 0.12)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(thumb / 2),
                    ),
                  ),
                ),
                // Yozuv
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Color.lerp(scheme.onSurface, Colors.white, _p),
                  ),
                ),
                // Surgich (oq, gold ikonка)
                AnimatedPositioned(
                  duration: dur,
                  curve: Curves.easeOut,
                  left: thumbLeft,
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (widget.glow)
                          BoxShadow(
                            color: widget.fillColor.withValues(alpha: 0.7),
                            blurRadius: 16,
                            spreadRadius: 1,
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
                      color: widget.fillColor,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
