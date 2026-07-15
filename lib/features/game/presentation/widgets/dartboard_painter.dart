import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Dessine une cible façon "planche de bois pour lancer de hache",
/// dans l'esprit viking, tout en conservant EXACTEMENT les mêmes
/// proportions de zones que ScoringService (simple/double/triple/bull) :
/// seul l'habillage visuel change, pas la géométrie de score.
class DartboardPainter extends CustomPainter {
  final bool darkMode;

  DartboardPainter({this.darkMode = true});

  // Palette bois / hache viking.
  static const Color _woodDark = Color(0xFF3E2723); // Noyer foncé
  static const Color _woodLight = Color(0xFF6D4C36); // Chêne clair
  static const Color _ringColor = Color(0xFFB33A1E); // Anneaux gravés au fer rouge
  static const Color _bullColor = Color(0xFFFBBF24); // Centre doré

  static const List<int> _sectorOrder = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17,
    3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) / 2;

    // Contour extérieur : tranche de tronc d'arbre (cerne de bois).
    final trunkPaint = Paint()..color = _woodDark;
    canvas.drawCircle(center, maxRadius * 1.04, trunkPaint);

    // Anneaux de croissance du tronc, pour l'effet "rondin de bois".
    for (double r = maxRadius; r > maxRadius * 0.3; r -= maxRadius * 0.09) {
      canvas.drawCircle(
        center,
        r,
        Paint()
          ..color = _woodLight.withOpacity(0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Secteurs alternés (deux tons de bois plutôt que noir/blanc).
    for (int i = 0; i < 20; i++) {
      final startAngle = (i * 18 - 9 - 90) * math.pi / 180;
      final sweepAngle = 18 * math.pi / 180;
      final isEven = i % 2 == 0;

      final sectorPaint = Paint()..color = isEven ? _woodLight : _woodDark;

      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(Rect.fromCircle(center: center, radius: maxRadius * 0.9529), startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, sectorPaint);
    }

    // Anneaux double et triple, gravés au fer rouge façon marquage viking.
    _drawRing(canvas, center, maxRadius, 0.5824, 0.6294);
    _drawRing(canvas, center, maxRadius, 0.9529, 1.0);

    // Bull extérieur et central, dorés.
    canvas.drawCircle(center, maxRadius * 0.0941, Paint()..color = _bullColor.withOpacity(0.85));
    canvas.drawCircle(center, maxRadius * 0.0374, Paint()..color = _bullColor);

    // Numéros gravés autour de la cible.
    for (int i = 0; i < 20; i++) {
      final angle = (i * 18 - 90) * math.pi / 180;
      final labelRadius = maxRadius * 1.14;
      final offset = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${_sectorOrder[i]}',
          style: const TextStyle(
            color: Color(0xFFE8D9C5),
            fontWeight: FontWeight.bold,
            fontSize: 13,
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

      final paint = Paint()
        ..color = _ringColor.withOpacity(i % 2 == 0 ? 0.9 : 0.7)
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
