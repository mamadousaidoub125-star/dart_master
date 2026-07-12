import 'dart:math' as math;
import '../entities/board_zone.dart';
import 'scoring_service.dart';
import 'throw_physics.dart';

/// Niveaux de difficulté disponibles pour l'adversaire IA.
enum AiDifficulty { facile, moyenne, difficile, experte }

/// Représente une décision stratégique de l'IA : quelle case elle
/// tente de viser avant d'appliquer sa propre marge d'erreur.
class AiIntent {
  final double targetX;
  final double targetY;
  final String reasoning; // Utilisé en debug / analytics, pas affiché au joueur.

  const AiIntent({required this.targetX, required this.targetY, required this.reasoning});
}

/// Simule un adversaire artificiel réaliste.
///
/// Plutôt que de "tricher" en connaissant le score exact à l'avance,
/// l'IA raisonne comme un joueur humain : elle choisit une case cible
/// selon le score restant (stratégie de "checkout" à 501/301, priorité
/// aux triples 20 en phase de scoring, fermeture des cases à Cricket),
/// puis son swing est perturbé par un niveau de compétence qui varie
/// selon la difficulté choisie.
class AiOpponent {
  final AiDifficulty difficulty;
  final math.Random _random;

  AiOpponent({required this.difficulty, math.Random? random})
      : _random = random ?? math.Random();

  /// Compétence brute de l'IA, réutilisée par [ThrowPhysics.computeImpact].
  /// Calibrée pour donner une vraie sensation de progression entre niveaux :
  /// - facile : proche d'un débutant humain
  /// - moyenne : joueur de club occasionnel
  /// - difficile : joueur régulier bien entraîné
  /// - experte : proche du niveau professionnel
  double get skillLevel {
    switch (difficulty) {
      case AiDifficulty.facile:
        return 0.35;
      case AiDifficulty.moyenne:
        return 0.58;
      case AiDifficulty.difficile:
        return 0.78;
      case AiDifficulty.experte:
        return 0.94;
    }
  }

  /// Stabilité de geste simulée (l'IA "n'a pas de doigt qui tremble"
  /// comme un humain sur mobile, mais on lui laisse une légère variance
  /// aux niveaux inférieurs pour éviter un jeu robotique peu crédible).
  double get gestureSteadiness {
    switch (difficulty) {
      case AiDifficulty.facile:
        return 0.5;
      case AiDifficulty.moyenne:
        return 0.7;
      case AiDifficulty.difficile:
        return 0.88;
      case AiDifficulty.experte:
        return 0.97;
    }
  }

  /// Décide quelle case viser en fonction du score restant (mode 301/501).
  ///
  /// Stratégie simplifiée mais réaliste :
  /// - Si le score restant permet une fermeture directe (checkout) sur
  ///   un double atteignable, l'IA vise ce double en priorité (comme un
  ///   vrai joueur cherchant à terminer la manche).
  /// - Sinon, elle vise le triple 20 (case de scoring maximal standard),
  ///   sauf aux niveaux faibles où elle privilégie une case plus sûre
  ///   pour rester crédible.
  AiIntent decideTargetForScoring({required int remainingScore}) {
    // Tentative de "checkout" : score restant pair et raisonnable (<= 40)
    // correspond à un double direct (ex : 32 -> Double 16).
    if (remainingScore <= 40 && remainingScore % 2 == 0 && remainingScore > 0) {
      final int doubleValue = remainingScore ~/ 2;
      final coords = _sectorCenterCoordinates(doubleValue, ring: 'double');
      return AiIntent(
        targetX: coords.$1,
        targetY: coords.$2,
        reasoning: 'Tentative de checkout sur le Double $doubleValue',
      );
    }

    // Niveaux faibles : viser une grande zone simple pour rester crédible
    // plutôt que de tenter systématiquement le triple 20 comme un pro.
    if (difficulty == AiDifficulty.facile) {
      final coords = _sectorCenterCoordinates(20, ring: 'simple');
      return AiIntent(targetX: coords.$1, targetY: coords.$2, reasoning: 'Scoring prudent');
    }

    // Stratégie standard : viser le Triple 20 pour maximiser les points.
    final coords = _sectorCenterCoordinates(20, ring: 'triple');
    return AiIntent(targetX: coords.$1, targetY: coords.$2, reasoning: 'Scoring maximal (T20)');
  }

  /// Exécute un lancer complet de l'IA et retourne la zone effectivement
  /// touchée, en réutilisant le même moteur physique que pour le joueur
  /// humain afin de garantir une équité totale des règles du jeu.
  BoardZone performThrow({required int remainingScore}) {
    final intent = decideTargetForScoring(remainingScore: remainingScore);

    final input = ThrowInput(
      aimX: intent.targetX,
      aimY: intent.targetY,
      power: 0.9, // L'IA vise toujours une puissance idéale ; seul skillLevel introduit l'erreur.
      spin: 0.0,
      gestureSteadiness: gestureSteadiness,
    );

    final result = ThrowPhysics.computeImpact(
      input: input,
      skillLevel: skillLevel,
      random: _random,
    );

    return ScoringService.evaluateImpact(dx: result.impactX, dy: result.impactY);
  }

  /// Retourne des coordonnées normalisées approximatives du centre
  /// d'un secteur donné, pour un anneau donné ('simple', 'double', 'triple').
  /// Utilise la même géométrie officielle que [ScoringService].
  (double, double) _sectorCenterCoordinates(int sectorValue, {required String ring}) {
    const sectorOrder = [
      20, 1, 18, 4, 13, 6, 10, 15, 2, 17,
      3, 19, 7, 16, 8, 11, 14, 9, 12, 5,
    ];
    final index = sectorOrder.indexOf(sectorValue);
    final angleDeg = index * 18.0; // Centre du secteur, en degrés depuis le haut.
    final angleRad = angleDeg * math.pi / 180;

    double radius;
    switch (ring) {
      case 'double':
        radius = 0.975; // Milieu de l'anneau double.
        break;
      case 'triple':
        radius = 0.605; // Milieu de l'anneau triple.
        break;
      default:
        radius = 0.35; // Zone simple, entre le bull et le triple.
    }

    final dx = radius * math.sin(angleRad);
    final dy = -radius * math.cos(angleRad);
    return (dx, dy);
  }
}
