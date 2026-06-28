import 'package:flutter/material.dart';

/// Surib tasdiqlash tugmasi — surilganda ichini to'ldirib tasdiqlaydi.
/// reverse=false: chapdan o'ngga (liniyaga chiqish);
/// reverse=true: o'ngdan chapga (ishni yakunlash). plan/06-driver-app.md
class SlideToConfirm extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color fillColor;
  final Color thumbColor;
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
    this.thumbColor = Colors.white,
    this.height = 71,
    this.reverse = false,
    this.glow = false,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _p = 0; // 0..1 progress
  bool _done = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const pad = 6.0;
    final thumb = widget.height - pad * 2;
    return LayoutBuilder(
      builder: (ctx, c) {
        final maxDx = c.maxWidth - thumb - pad * 2;
        final thumbLeft = (widget.reverse ? (1 - _p) : _p) * maxDx;
        final fillW = (widget.reverse ? (maxDx - thumbLeft) : thumbLeft) + thumb;
        return GestureDetector(
          onHorizontalDragStart: (_) {
            if (!_done) setState(() => _dragging = true);
          },
          onHorizontalDragUpdate: (d) {
            if (_done || maxDx <= 0) return;
            final delta = (widget.reverse ? -d.delta.dx : d.delta.dx) / maxDx;
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
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // To'lib boruvchi qism
                Align(
                  alignment:
                      widget.reverse ? Alignment.centerRight : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: _dragging ? 0 : 220),
                    width: fillW.clamp(thumb, c.maxWidth),
                    height: thumb,
                    decoration: BoxDecoration(
                      color: widget.fillColor.withValues(alpha: 0.2 + 0.55 * _p),
                      borderRadius: BorderRadius.circular(thumb / 2),
                    ),
                  ),
                ),
                // Yozuv
                Opacity(
                  opacity: (1 - _p).clamp(0.25, 1.0),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                // Surgich
                AnimatedPositioned(
                  duration: Duration(milliseconds: _dragging ? 0 : 220),
                  curve: Curves.easeOut,
                  left: thumbLeft,
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: BoxDecoration(
                      color: widget.fillColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        if (widget.glow)
                          BoxShadow(
                            color: widget.fillColor.withValues(alpha: 0.6),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        const BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    child: Icon(
                      _done ? Icons.check : widget.icon,
                      color: widget.thumbColor,
                      size: 26,
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
