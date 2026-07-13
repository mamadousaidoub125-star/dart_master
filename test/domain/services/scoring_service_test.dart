import 'package:flutter_test/flutter_test.dart';
import 'package:dart_master/features/game/domain/services/scoring_service.dart';

void main() {
  group('ScoringService.evaluateImpact', () {
    test('un impact exactement au centre donne le double bull (50)', () {
      final zone = ScoringService.evaluateImpact(dx: 0, dy: 0);
      expect(zone.points, 50);
      expect(zone.isDoubleBull, true);
    });

    test('un impact juste hors du double bull mais dans le bull donne 25', () {
      final zone = ScoringService.evaluateImpact(dx: 0, dy: 0.06);
      expect(zone.score, 25);
      expect(zone.isBullseye, true);
      expect(zone.isDoubleBull, false);
    });

    test('un impact au-delà du rayon de jeu est un lancer manqué', () {
      final zone = ScoringService.evaluateImpact(dx: 1.5, dy: 0);
      expect(zone.points, 0);
    });

    test('un impact tout en haut (12h) dans la zone triple touche le Triple 20', () {
      // Le secteur 20 est centré en haut de la cible (angle 0°).
      final zone = ScoringService.evaluateImpact(dx: 0, dy: -0.605);
      expect(zone.score, 20);
      expect(zone.multiplier, 3);
      expect(zone.points, 60);
    });

    test('un impact dans l\'anneau double en haut touche le Double 20', () {
      final zone = ScoringService.evaluateImpact(dx: 0, dy: -0.975);
      expect(zone.score, 20);
      expect(zone.multiplier, 2);
      expect(zone.points, 40);
    });
  });
}
