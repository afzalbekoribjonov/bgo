import 'package:flutter/material.dart';

/// Surib tasdiqlash tugmasi — chapdan o'ngga surilganda ichini to'ldirib
/// tasdiqlaydi (liniyaga chiqish / ishni yakunlash). plan/06-driver-app.md
class SlideToConfirm extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color fillColor;
  final Color thumbColor;
  final VoidCallback onConfirmed;
  final double height;

  const SlideToConfirm({
    super.key,
    required this.label,
    required this.icon,
    required this.fillColor,
    required this.onConfirmed,
    this.thumbColor = Colors.white,
    this.height = 68,
  });

  @override
  State<SlideToConfirm> createState() => _SlideToConfirmState();
}

class _SlideToConfirmState extends State<SlideToConfirm> {
  double _dx = 0;
  bool _done = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pad = 6.0;
    final thumb = widget.height - pad * 2;
    return LayoutBuilder(
      builder: (ctx, c) {
        final maxDx = c.maxWidth - thumb - pad * 2;
        final progress = maxDx <= 0 ? 0.0 : (_dx / maxDx).clamp(0.0, 1.0);
        return GestureDetector(
          onHorizontalDragStart: (_) {
            if (!_done) setState(() => _dragging = true);
          },
          onHorizontalDragUpdate: (d) {
            if (_done) return;
            setState(() => _dx = (_dx + d.delta.dx).clamp(0.0, maxDx));
          },
          onHorizontalDragEnd: (_) {
            _dragging = false;
            if (_dx >= maxDx * 0.85) {
              setState(() {
                _dx = maxDx;
                _done = true;
              });
              widget.onConfirmed();
            } else {
              setState(() => _dx = 0);
            }
          },
          child: Container(
            height: widget.height,
            padding: EdgeInsets.all(pad),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                // To'lib boruvchi qism
                AnimatedContainer(
                  duration: Duration(milliseconds: _dragging ? 0 : 200),
                  width: _dx + thumb,
                  height: thumb,
                  decoration: BoxDecoration(
                    color: widget.fillColor.withValues(alpha: 0.18 + 0.5 * progress),
                    borderRadius: BorderRadius.circular(thumb / 2),
                  ),
                ),
                // Yozuv
                Positioned.fill(
                  child: Center(
                    child: Opacity(
                      opacity: (1 - progress).clamp(0.25, 1.0),
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                ),
                // Surgich (thumb)
                AnimatedPositioned(
                  duration: Duration(milliseconds: _dragging ? 0 : 200),
                  curve: Curves.easeOut,
                  left: _dx,
                  child: Container(
                    width: thumb,
                    height: thumb,
                    decoration: BoxDecoration(
                      color: widget.fillColor,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
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
