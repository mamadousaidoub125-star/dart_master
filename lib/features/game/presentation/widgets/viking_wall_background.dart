import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Arrière-plan façon mur de taverne viking : planches de bois brutes
/// avec une tête de taureau empaillée accrochée au-dessus de la cible,
/// comme demandé pour l'ambiance générale du jeu.
class VikingWallBackground extends StatelessWidget {
  final Widget child;

  const VikingWallBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _WoodWallPainter(), child: Container()),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            CustomPaint(size: const Size(120, 70), painter: _BullSkullPainter()),
            const SizedBox(height: 4),
            Expanded(child: child),
          ],
        ),
      ],
    );
  }
}

/// Dessine des planches de bois horizontales avec un léger dégradé,
/// pour donner l'impression que la cible est accrochée à un vrai mur.
class _WoodWallPainter extends CustomPainter {
  static const Color _plankDark = Color(0xFF2E1E14);
  static const Color _plankLight = Color(0xFF44301F);

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_plankDark, _plankLight],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Lignes horizontales de séparation entre planches.
    const plankHeight = 46.0;
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 2;
    for (double y = plankHeight; y < size.height; y += plankHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Quelques traits verticaux discrets (veines du bois), semi-aléatoires
    // mais déterministes (seed fixe) pour ne pas re-générer à chaque frame.
    final rng = math.Random(7);
    final grainPaint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += plankHeight) {
      final grainCount = 3 + rng.nextInt(3);
      for (int i = 0; i < grainCount; i++) {
        final x = rng.nextDouble() * size.width;
        canvas.drawLine(Offset(x, y + 4), Offset(x + 6, y + plankHeight - 4), grainPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WoodWallPainter oldDelegate) => false;
}

/// Dessine une tête de taureau stylisée (crâne + cornes) accrochée au mur,
/// dans un style simple mais reconnaissable, sans nécessiter d'image externe.
class _BullSkullPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final skullPaint = Paint()..color = const Color(0xFFEDE0CC);
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.15);
    final hornPaint = Paint()..color = const Color(0xFFD9C7A3);

    // Ombre portée sur le mur.
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(4, 6), width: size.width * 0.55, height: size.height * 0.5),
      shadowPaint,
    );

    // Cornes (deux arcs symétriques partant du haut du crâne).
    final leftHorn = Path()
      ..moveTo(center.dx - 8, center.dy - 10)
      ..quadraticBezierTo(
        center.dx - size.width * 0.55, center.dy - size.height * 0.75,
        center.dx - size.width * 0.48, center.dy - size.height * 0.05,
      )
      ..quadraticBezierTo(center.dx - size.width * 0.3, center.dy - 20, center.dx - 8, center.dy - 10)
      ..close();
    final rightHorn = Path()
      ..moveTo(center.dx + 8, center.dy - 10)
      ..quadraticBezierTo(
        center.dx + size.width * 0.55, center.dy - size.height * 0.75,
        center.dx + size.width * 0.48, center.dy - size.height * 0.05,
      )
      ..quadraticBezierTo(center.dx + size.width * 0.3, center.dy - 20, center.dx + 8, center.dy - 10)
      ..close();
    canvas.drawPath(leftHorn, hornPaint);
    canvas.drawPath(rightHorn, hornPaint);

    // Crâne (forme ovale allongée verticalement, museau plus étroit).
    final skullPath = Path()
      ..moveTo(center.dx, center.dy - size.height * 0.42)
      ..quadraticBezierTo(center.dx + size.width * 0.22, center.dy - size.height * 0.3, center.dx + size.width * 0.18, center.dy)
      ..quadraticBezierTo(center.dx + size.width * 0.12, center.dy + size.height * 0.4, center.dx, center.dy + size.height * 0.46)
      ..quadraticBezierTo(center.dx - size.width * 0.12, center.dy + size.height * 0.4, center.dx - size.width * 0.18, center.dy)
      ..quadraticBezierTo(center.dx - size.width * 0.22, center.dy - size.height * 0.3, center.dx, center.dy - size.height * 0.42)
      ..close();
    canvas.drawPath(skullPath, skullPaint);

    // Orbites (yeux vides du crâne).
    final eyePaint = Paint()..color = const Color(0xFF2E1E14);
    canvas.drawOval(Rect.fromCenter(center: center.translate(-size.width * 0.09, -6), width: 12, height: 16), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: center.translate(size.width * 0.09, -6), width: 12, height: 16), eyePaint);
  }

  @override
  bool shouldRepaint(covariant _BullSkullPainter oldDelegate) => false;
}
