import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Arrière-plan façon mur de taverne viking, avec 3 paliers de décor
/// qui se débloquent selon le niveau du joueur : plus il progresse,
/// plus le mur et la tête d'animal accrochée dessus deviennent
/// impressionnants (bois+taureau -> pierre+loup -> fer sombre+dragon).
class VikingWallBackground extends StatelessWidget {
  final Widget child;
  final int levelTier; // 0 = bois/taureau, 1 = pierre/loup, 2 = fer/dragon

  const VikingWallBackground({super.key, required this.child, this.levelTier = 0});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      fit: StackFit.expand,
      children: [
        CustomPaint(painter: _WallPainter(tier: levelTier), child: Container()),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            CustomPaint(size: const Size(120, 70), painter: _AnimalHeadPainter(tier: levelTier)),
            const SizedBox(height: 4),
            Expanded(child: child),
          ],
        ),
      ],
    );
  }
}

/// Dessine le mur en fonction du palier : planches de bois, pierre
/// taillée, ou fer sombre martelé.
class _WallPainter extends CustomPainter {
  final int tier;
  const _WallPainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final palettes = [
      [const Color(0xFF2E1E14), const Color(0xFF44301F)], // Bois
      [const Color(0xFF3A3A3E), const Color(0xFF54545A)], // Pierre
      [const Color(0xFF0D0D10), const Color(0xFF23232B)], // Fer sombre
    ];
    final colors = palettes[tier.clamp(0, 2)];

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: colors,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    final rng = math.Random(7);
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 2;

    if (tier == 1) {
      // Pierre : blocs rectangulaires décalés (appareillage classique).
      const blockH = 60.0;
      const blockW = 140.0;
      int row = 0;
      for (double y = 0; y < size.height; y += blockH) {
        final offset = (row % 2 == 0) ? 0.0 : blockW / 2;
        for (double x = -offset; x < size.width; x += blockW) {
          canvas.drawRect(Rect.fromLTWH(x, y, blockW - 4, blockH - 4), linePaint);
        }
        row++;
      }
    } else if (tier == 2) {
      // Fer : plaques rivetées, avec petits points de rivets.
      const plateH = 80.0;
      const plateW = 100.0;
      final rivetPaint = Paint()..color = Colors.black.withOpacity(0.4);
      for (double y = 0; y < size.height; y += plateH) {
        for (double x = 0; x < size.width; x += plateW) {
          canvas.drawRect(Rect.fromLTWH(x, y, plateW - 4, plateH - 4), linePaint);
          canvas.drawCircle(Offset(x + 6, y + 6), 2.5, rivetPaint);
          canvas.drawCircle(Offset(x + plateW - 10, y + 6), 2.5, rivetPaint);
        }
      }
    } else {
      // Bois : planches horizontales avec veines discrètes.
      const plankHeight = 46.0;
      for (double y = plankHeight; y < size.height; y += plankHeight) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
      final grainPaint = Paint()..color = Colors.black.withOpacity(0.12)..strokeWidth = 1;
      for (double y = 0; y < size.height; y += plankHeight) {
        final grainCount = 3 + rng.nextInt(3);
        for (int i = 0; i < grainCount; i++) {
          final x = rng.nextDouble() * size.width;
          canvas.drawLine(Offset(x, y + 4), Offset(x + 6, y + plankHeight - 4), grainPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WallPainter oldDelegate) => oldDelegate.tier != tier;
}

/// Dessine la tête d'animal accrochée au mur : taureau (départ), loup
/// (niveau 3+), ou dragon (niveau 5+), pour marquer visuellement la
/// progression du joueur.
class _AnimalHeadPainter extends CustomPainter {
  final int tier;
  const _AnimalHeadPainter({required this.tier});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.55);
    final skullColor = [
      const Color(0xFFEDE0CC), // Taureau : os clair
      const Color(0xFFB8B0A8), // Loup : gris pierre
      const Color(0xFF2A2A30), // Dragon : écailles sombres
    ][tier.clamp(0, 2)];
    final accentColor = [
      const Color(0xFFD9C7A3),
      const Color(0xFF8A8580),
      const Color(0xFF6B1F1F),
    ][tier.clamp(0, 2)];

    final skullPaint = Paint()..color = skullColor;
    final shadowPaint = Paint()..color = Colors.black.withOpacity(0.15);
    final accentPaint = Paint()..color = accentColor;

    canvas.drawOval(
      Rect.fromCenter(center: center.translate(4, 6), width: size.width * 0.55, height: size.height * 0.5),
      shadowPaint,
    );

    if (tier == 0) {
      _drawHornPair(canvas, center, size, accentPaint, curved: true);
    } else if (tier == 1) {
      _drawEarPair(canvas, center, size, accentPaint);
    } else {
      _drawSpikePair(canvas, center, size, accentPaint);
    }

    final skullPath = Path()
      ..moveTo(center.dx, center.dy - size.height * 0.42)
      ..quadraticBezierTo(center.dx + size.width * 0.22, center.dy - size.height * 0.3, center.dx + size.width * 0.18, center.dy)
      ..quadraticBezierTo(center.dx + size.width * 0.12, center.dy + size.height * 0.4, center.dx, center.dy + size.height * 0.46)
      ..quadraticBezierTo(center.dx - size.width * 0.12, center.dy + size.height * 0.4, center.dx - size.width * 0.18, center.dy)
      ..quadraticBezierTo(center.dx - size.width * 0.22, center.dy - size.height * 0.3, center.dx, center.dy - size.height * 0.42)
      ..close();
    canvas.drawPath(skullPath, skullPaint);

    final eyePaint = Paint()..color = tier == 2 ? const Color(0xFFB33A1E) : const Color(0xFF2E1E14);
    canvas.drawOval(Rect.fromCenter(center: center.translate(-size.width * 0.09, -6), width: 12, height: 16), eyePaint);
    canvas.drawOval(Rect.fromCenter(center: center.translate(size.width * 0.09, -6), width: 12, height: 16), eyePaint);
  }

  void _drawHornPair(Canvas canvas, Offset center, Size size, Paint paint, {required bool curved}) {
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
    canvas.drawPath(leftHorn, paint);
    canvas.drawPath(rightHorn, paint);
  }

  void _drawEarPair(Canvas canvas, Offset center, Size size, Paint paint) {
    final leftEar = Path()
      ..moveTo(center.dx - size.width * 0.14, center.dy - size.height * 0.32)
      ..lineTo(center.dx - size.width * 0.32, center.dy - size.height * 0.62)
      ..lineTo(center.dx - size.width * 0.04, center.dy - size.height * 0.38)
      ..close();
    final rightEar = Path()
      ..moveTo(center.dx + size.width * 0.14, center.dy - size.height * 0.32)
      ..lineTo(center.dx + size.width * 0.32, center.dy - size.height * 0.62)
      ..lineTo(center.dx + size.width * 0.04, center.dy - size.height * 0.38)
      ..close();
    canvas.drawPath(leftEar, paint);
    canvas.drawPath(rightEar, paint);
  }

  void _drawSpikePair(Canvas canvas, Offset center, Size size, Paint paint) {
    for (int i = -2; i <= 2; i++) {
      final baseX = center.dx + i * size.width * 0.09;
      final spike = Path()
        ..moveTo(baseX - 8, center.dy - size.height * 0.3)
        ..lineTo(baseX, center.dy - size.height * 0.65 - (i.abs() == 2 ? 0 : 10))
        ..lineTo(baseX + 8, center.dy - size.height * 0.3)
        ..close();
      canvas.drawPath(spike, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimalHeadPainter oldDelegate) => oldDelegate.tier != tier;
}
