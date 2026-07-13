import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:dart_master/features/game/domain/services/throw_physics.dart';

void main() {
  group('ThrowPhysics.computeImpact', () {
    test('un joueur expert avec puissance idéale et geste stable dévie très peu', () {
      final input = const ThrowInput(
        aimX: 0,
        aimY: -0.605, // Vise le Triple 20.
        power: 0.9,
        spin: 0.0,
        gestureSteadiness: 1.0,
      );

      final result = ThrowPhysics.computeImpact(
        input: input,
        skillLevel: 0.99,
        random: Random(42), // Seed fixe pour un test déterministe.
      );

      // La déviation doit rester faible pour un joueur quasi-parfait.
      expect((result.impactX - input.aimX).abs(), lessThan(0.15));
      expect((result.impactY - input.aimY).abs(), lessThan(0.15));
    });

    test('une puissance trop faible dévie le point d\'impact vers le bas', () {
      final input = const ThrowInput(
        aimX: 0,
        aimY: 0,
        power: 0.3, // Bien en dessous de la puissance idéale (0.9).
        spin: 0.0,
        gestureSteadiness: 1.0,
      );

      final result = ThrowPhysics.computeImpact(
        input: input,
        skillLevel: 0.99,
        random: Random(1),
      );

      // Une sous-puissance doit décaler l'impact vers le bas (Y négatif car
      // powerError est négatif -> verticalDeviation négatif).
      expect(result.impactY, lessThan(0.1));
    });

    test('un débutant avec geste instable a une dispersion nettement plus grande', () {
      final input = const ThrowInput(
        aimX: 0,
        aimY: 0,
        power: 0.9,
        spin: 0.0,
        gestureSteadiness: 0.2,
      );

      final results = List.generate(
        50,
        (i) => ThrowPhysics.computeImpact(input: input, skillLevel: 0.1, random: Random(i)),
      );

      final avgDeviation = results
              .map((r) => (r.impactX - input.aimX).abs() + (r.impactY - input.aimY).abs())
              .reduce((a, b) => a + b) /
          results.length;

      // Un débutant doit statistiquement dévier de manière significative.
      expect(avgDeviation, greaterThan(0.1));
    });
  });
}
