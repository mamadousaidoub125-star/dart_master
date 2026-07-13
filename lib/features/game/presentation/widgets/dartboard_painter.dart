import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Dessine une cible de fléchettes réglementaire.
///
/// Reprend exactement les mêmes ratios de rayons que [ScoringService]
/// pour garantir que ce que le joueur voit correspond à 100% à ce que
/// le moteur de score calcule (aucune tricherie visuelle possible).
class DartboardPainter extends CustomPainter {
  final bool darkMode;

  DartboardPainter({this.darkMode = true});

  static const List<int> _sectorOrder = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17,
    3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Fond de la cible (cadre extérieur en bois/noir).
    final backgroundPaint = Paint()..color = darkMode ? AppColors.black : AppColors.darkSurface;
    canvas.drawCircle(center, maxRadius, backgroundPaint);

    // Dessin des 20 secteurs alternant noir et blanc/crème.
    for (int i = 0; i < 20; i++) {
      final startAngle = (i * 18 - 9 - 90) * math.pi / 180;
      final sweepAngle = 18 * math.pi / 180;
      final isEven = i % 2 == 0;

      final sectorPaint = Paint()
        ..color = isEven ? AppColors.lightGray.withOpacity(0.95) : AppColors.black;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: maxRadius * 0.9529), startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, sectorPaint);
    }

    // Anneaux double et triple (bandes rouge/vert alternées par secteur).
    _drawRing(canvas, center, maxRadius, 0.5824, 0.6294); // Triple
    _drawRing(canvas, center, maxRadius, 0.9529, 1.0);    // Double

    // Bull extérieur (25) et bull central (50).
    canvas.drawCircle(center, maxRadius * 0.0941, Paint()..color = AppColors.green);
    canvas.drawCircle(center, maxRadius * 0.0374, Paint()..color = AppColors.red);

    // Numéros des secteurs autour de la cible.
    for (int i = 0; i < 20; i++) {
      final angle = (i * 18 - 90) * math.pi / 180;
      final labelRadius = maxRadius * 1.08;
      final offset = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${_sectorOrder[i]}',
          style: TextStyle(
            color: darkMode ? AppColors.white : AppColors.midnightBlue,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(canvas, offset - Offset(textPainter.width / 2, textPainter.height / 2));
    }
  }

  void _drawRing(Canvas canvas, Offset center, double maxRadius, double innerRatio, double outerRatio) {
    for (int i = 0; i < 20; i++) {
      final startAngle = (i * 18 - 9 - 90) * math.pi / 180;
      final sweepAngle = 18 * math.pi / 180;
      final isRed = i % 2 == 0;

      final paint = Paint()
        ..color = isRed ? AppColors.red : AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = (outerRatio - innerRatio) * maxRadius;

      final ringRadius = maxRadius * (innerRatio + outerRatio) / 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: ringRadius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant DartboardPainter oldDelegate) => oldDelegate.darkMode != darkMode;
}
