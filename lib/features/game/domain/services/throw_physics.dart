import 'dart:math' as math;

/// Paramètres d'un lancer tels que définis par le joueur avant le tir.
///
/// - [aimX], [aimY] : point visé sur la cible, en coordonnées normalisées
///   (0,0 = centre de la cible, 1.0 = bord du cercle de jeu).
/// - [power] : puissance du lancer, de 0.0 (trop faible) à 1.0 (parfaite).
///   Le "sweet spot" est autour de 0.85-0.95 ; une puissance mal calibrée
///   dévie le point d'impact verticalement (trop court ou trop long).
/// - [spin] : effet donné à la fléchette, de -1.0 (effet gauche) à 1.0
///   (effet droit), dévie le point d'impact horizontalement.
/// - [gestureSteadiness] : qualité du geste de lancer (0.0 = tremblant,
///   1.0 = parfaitement stable), mesurée à partir de la régularité du
///   swipe de l'utilisateur (vitesse constante = meilleure précision).
class ThrowInput {
  final double aimX;
  final double aimY;
  final double power;
  final double spin;
  final double gestureSteadiness;

  const ThrowInput({
    required this.aimX,
    required this.aimY,
    required this.power,
    required this.spin,
    required this.gestureSteadiness,
  });
}

/// Résultat final d'un lancer : la position réelle d'impact,
/// qui peut différer du point visé à cause des imperfections physiques.
class ThrowResult {
  final double impactX;
  final double impactY;

  const ThrowResult({required this.impactX, required this.impactY});
}

/// Simule la physique réaliste d'un lancer de fléchette.
///
/// Le modèle combine trois sources de déviation par rapport au point visé :
/// 1. Une erreur de puissance (sous/sur-puissance déplace l'impact
///    verticalement, comme une fléchette trop courte tombant plus bas,
///    ou trop appuyée qui part plus haut que prévu) ;
/// 2. Une déviation latérale due à l'effet (spin) appliqué ;
/// 3. Un bruit aléatoire inversement proportionnel à la compétence du
///    joueur (niveau du profil) et à la stabilité du geste effectué.
class ThrowPhysics {
  ThrowPhysics._();

  static const double _idealPower = 0.9;

  /// Calcule le point d'impact final.
  ///
  /// [skillLevel] représente la compétence du joueur ou de l'IA (0.0 à 1.0).
  /// Un joueur expert (proche de 1.0) aura une dispersion très faible ;
  /// un débutant (proche de 0.0) aura une dispersion importante même
  /// avec une visée et un geste parfaits.
  static ThrowResult computeImpact({
    required ThrowInput input,
    required double skillLevel,
    math.Random? random,
  }) {
    final rng = random ?? math.Random();

    // 1. Déviation verticale due à l'écart de puissance par rapport à l'idéal.
    final double powerError = input.power - _idealPower;
    final double verticalDeviation = powerError * 0.18;

    // 2. Déviation horizontale due à l'effet appliqué (spin).
    final double spinDeviation = input.spin * 0.12;

    // 3. Bruit aléatoire : plus le joueur est compétent et le geste stable,
    // plus l'écart-type de la dispersion diminue.
    final double instability = (1 - skillLevel) * (1 - input.gestureSteadiness * 0.6);
    final double dispersion = 0.02 + instability * 0.18;

    // Bruit gaussien approximé par la méthode de Box-Muller pour un
    // comportement de dispersion réaliste (plus de tirs proches du centre
    // de la dispersion que de tirs extrêmes, comme un vrai lancer).
    final double u1 = rng.nextDouble().clamp(0.0001, 1.0);
    final double u2 = rng.nextDouble();
    final double gaussianX = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
    final double gaussianY = math.sqrt(-2 * math.log(u1)) * math.sin(2 * math.pi * u2);

    final double finalX = input.aimX + spinDeviation + gaussianX * dispersion;
    final double finalY = input.aimY + verticalDeviation + gaussianY * dispersion;

    return ThrowResult(impactX: finalX, impactY: finalY);
  }
}
