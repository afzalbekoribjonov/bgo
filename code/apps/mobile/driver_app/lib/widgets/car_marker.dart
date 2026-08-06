import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Tepadan ko'rinishdagi professional avtomobil — xarita markeri.
/// Old oyna, tom, orqa oyna, faralar, stop-chiroqlar va ko'zgular bilan;
/// ostida yumshoq soya. `heading` gradusda (0 = shimolga qarab).
class CarMarker extends StatelessWidget {
  final double size; // bo'yi (px); eni avtomatik ~0.52
  final Color color;
  final double heading;
  final bool glow;

  /// Xaritaning joriy burilish burchagi (gradus). flutter_map butun
  /// MarkerLayer'ni xarita burchagiga burib qo'yadi, shuning uchun belgining
  /// O'Z burchagidan buni ayirmasak, mashina IKKI BAROBAR aylanib ketadi.
  /// Standart 0 — xarita aylanmaydigan joylarda eski xatti-harakat saqlanadi.
  final double mapRotationDeg;

  const CarMarker({
    super.key,
    this.size = 46,
    required this.color,
    this.heading = 0,
    this.glow = false,
    this.mapRotationDeg = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: (heading - mapRotationDeg) * math.pi / 180,
      child: CustomPaint(
        size: Size(size * 0.52, size),
        painter: _CarPainter(color, glow),
      ),
    );
  }
}

class _CarPainter extends CustomPainter {
  final Color body;
  final bool glow;
  _CarPainter(this.body, this.glow);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Porlash (online holat) + ostidagi yumshoq soya
    if (glow) {
      canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx, h * 0.5), width: w * 1.7, height: h * 1.15),
        Paint()
          ..color = body.withValues(alpha: 0.22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h * 0.54), width: w * 1.05, height: h * 0.96),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Kuzov — old tomoni biroz toraygan silliq kapsula
    final bodyPath = Path()
      ..moveTo(cx, h * 0.02)
      ..quadraticBezierTo(w * 0.98, h * 0.02, w * 0.95, h * 0.24)
      ..lineTo(w * 0.95, h * 0.80)
      ..quadraticBezierTo(w * 0.95, h * 0.98, cx, h * 0.98)
      ..quadraticBezierTo(w * 0.05, h * 0.98, w * 0.05, h * 0.80)
      ..lineTo(w * 0.05, h * 0.24)
      ..quadraticBezierTo(w * 0.02, h * 0.02, cx, h * 0.02)
      ..close();
    // Gradientli kuzov (yorug'lik chap-yuqoridan)
    canvas.drawPath(
      bodyPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(body, Colors.white, 0.28)!,
            body,
            Color.lerp(body, Colors.black, 0.22)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    canvas.drawPath(
      bodyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055
        ..color = Colors.white.withValues(alpha: 0.95),
    );

    // Old oyna (trapetsiya)
    final windshield = Path()
      ..moveTo(w * 0.18, h * 0.22)
      ..quadraticBezierTo(cx, h * 0.15, w * 0.82, h * 0.22)
      ..lineTo(w * 0.76, h * 0.36)
      ..quadraticBezierTo(cx, h * 0.30, w * 0.24, h * 0.36)
      ..close();
    canvas.drawPath(
        windshield, Paint()..color = const Color(0xE6E3F2FD));

    // Tom (biroz to'qroq panel)
    final roof = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.20, h * 0.40, w * 0.60, h * 0.26),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(
        roof, Paint()..color = Colors.black.withValues(alpha: 0.13));

    // Orqa oyna
    final rear = Path()
      ..moveTo(w * 0.22, h * 0.72)
      ..quadraticBezierTo(cx, h * 0.78, w * 0.78, h * 0.72)
      ..lineTo(w * 0.82, h * 0.84)
      ..quadraticBezierTo(cx, h * 0.92, w * 0.18, h * 0.84)
      ..close();
    canvas.drawPath(
        rear, Paint()..color = const Color(0xB3E3F2FD));

    // Yon ko'zgular
    final mirror = Paint()..color = body;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(-w * 0.035, h * 0.245, w * 0.12, h * 0.05),
          Radius.circular(w * 0.03)),
      mirror,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.915, h * 0.245, w * 0.12, h * 0.05),
          Radius.circular(w * 0.03)),
      mirror,
    );

    // Faralar (oldi) va stop-chiroqlar (orqa)
    final head = Paint()..color = const Color(0xFFFFF59D);
    canvas.drawCircle(Offset(w * 0.26, h * 0.055), w * 0.075, head);
    canvas.drawCircle(Offset(w * 0.74, h * 0.055), w * 0.075, head);
    final tail = Paint()..color = const Color(0xFFEF5350);
    canvas.drawCircle(Offset(w * 0.24, h * 0.945), w * 0.06, tail);
    canvas.drawCircle(Offset(w * 0.76, h * 0.945), w * 0.06, tail);
  }

  @override
  bool shouldRepaint(_CarPainter old) =>
      old.body != body || old.glow != glow;
}
