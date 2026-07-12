import 'dart:math' as math;
import '../entities/board_zone.dart';

/// Calcule le score d'un impact à partir de sa position sur la cible.
///
/// Les proportions utilisées reproduisent fidèlement les dimensions
/// officielles d'une cible de fléchettes réglementaire (norme WDF/PDC) :
/// un cercle de jeu de 170 mm de rayon contenant les anneaux simple,
/// triple, double et le bull, chaque ratio ci-dessous étant exprimé
/// par rapport à ce rayon total (donc entre 0.0 = centre et 1.0 = bord).
class ScoringService {
  ScoringService._();

  // --- Rayons normalisés des anneaux (mesures officielles / 170mm) ---
  static const double _doubleBullRadius = 0.0374; // Bull central (50 pts)
  static const double _outerBullRadius = 0.0941;  // Bull extérieur (25 pts)
  static const double _tripleInnerRadius = 0.5824;
  static const double _tripleOuterRadius = 0.6294;
  static const double _doubleInnerRadius = 0.9529;
  static const double _doubleOuterRadius = 1.0;

  /// Ordre officiel des 20 secteurs sur une cible réglementaire,
  /// en partant du haut (12h) et en tournant dans le sens horaire.
  static const List<int> _sectorOrder = [
    20, 1, 18, 4, 13, 6, 10, 15, 2, 17,
    3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
  ];

  /// Détermine la [BoardZone] touchée à partir d'une position d'impact
  /// exprimée en coordonnées cartésiennes normalisées, où (0,0) est le
  /// centre exact de la cible et 1.0 la distance au bord du cercle de jeu.
  static BoardZone evaluateImpact({required double dx, required double dy}) {
    final double radius = math.sqrt(dx * dx + dy * dy);

    // Lancer complètement en dehors de la cible.
    if (radius > _doubleOuterRadius) {
      return BoardZone.miss;
    }

    // Bull central (double bull / "50").
    if (radius <= _doubleBullRadius) {
      return const BoardZone(
        score: 50,
        multiplier: 1,
        label: 'Bull (50)',
        isBullseye: true,
        isDoubleBull: true,
      );
    }

    // Bull extérieur ("25").
    if (radius <= _outerBullRadius) {
      return const BoardZone(
        score: 25,
        multiplier: 1,
        label: 'Bull extérieur (25)',
        isBullseye: true,
      );
    }

    // Détermination du secteur numéroté via l'angle polaire.
    // atan2 donne un angle en radians dans [-π, π], 0 pointant vers la droite (3h).
    // On le convertit pour que 0° corresponde au haut (12h), sens horaire.
    double angle = math.atan2(dx, -dy) * (180 / math.pi);
    if (angle < 0) angle += 360;

    // Chaque secteur occupe 18° (360° / 20 secteurs), centré sur sa valeur.
    final int sectorIndex = (((angle + 9) ~/ 18) % 20);
    final int sectorValue = _sectorOrder[sectorIndex];

    // Détermination du multiplicateur selon l'anneau touché.
    if (radius >= _tripleInnerRadius && radius <= _tripleOuterRadius) {
      return BoardZone(score: sectorValue, multiplier: 3, label: 'Triple $sectorValue');
    }
    if (radius >= _doubleInnerRadius && radius <= _doubleOuterRadius) {
      return BoardZone(score: sectorValue, multiplier: 2, label: 'Double $sectorValue');
    }
    return BoardZone(score: sectorValue, multiplier: 1, label: 'Simple $sectorValue');
  }
}
