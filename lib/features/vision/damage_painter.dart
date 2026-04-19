import 'package:flutter/material.dart';

class DamagePainter extends CustomPainter {
  final double normalizedX;
  final double normalizedY;
  final String damageCode;
  final double confidence;

  DamagePainter({
    required this.normalizedX,
    required this.normalizedY,
    required this.damageCode,
    required this.confidence,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool isHeavyDamage = damageCode == 'D40';
    final Color themeColor = isHeavyDamage ? Colors.redAccent : Colors.amber;
    final String damageName = isHeavyDamage ? 'POTHOLE' : 'LONGITUDINAL CRACK';
    final String labelText =
        ' [$damageCode] $damageName - ${(confidence * 100).toStringAsFixed(0)}% ';

    final Paint paint = Paint()
      ..color = themeColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // Responsif 35% dari lebar layar agar tetap ringan dan jelas.
    final double boxSize = size.width * 0.35;
    final double left = (normalizedX * size.width) - (boxSize / 2);
    final double top = (normalizedY * size.height) - (boxSize / 2);

    final Rect rect = Rect.fromLTWH(left, top, boxSize, boxSize);

    canvas.drawRect(rect, paint);

    final TextStyle textStyle = TextStyle(
      color: isHeavyDamage ? Colors.white : Colors.black87,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      shadows: const [
        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(1, 1)),
      ],
    );

    final TextStyle strokeStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.bold,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black87,
    );

    final TextSpan textSpan = TextSpan(text: labelText, style: textStyle);

    final TextSpan strokeSpan = TextSpan(text: labelText, style: strokeStyle);

    final TextPainter textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    final TextPainter strokePainter = TextPainter(
      text: strokeSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    strokePainter.layout();

    double textY = top - 30;
    if (textY < 0) {
      textY = top + boxSize + 8;
    }

    final double textX = left.clamp(8.0, size.width - textPainter.width - 20);
    final RRect labelBg = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        textX - 6,
        textY - 3,
        textPainter.width + 12,
        textPainter.height + 6,
      ),
      const Radius.circular(6),
    );
    canvas.drawRRect(labelBg, Paint()..color = themeColor.withOpacity(0.9));
    strokePainter.paint(canvas, Offset(textX, textY));
    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(covariant DamagePainter oldDelegate) {
    return oldDelegate.normalizedX != normalizedX ||
        oldDelegate.normalizedY != normalizedY ||
        oldDelegate.damageCode != damageCode ||
        oldDelegate.confidence != confidence;
  }
}
