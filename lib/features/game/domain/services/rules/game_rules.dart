import '../../entities/board_zone.dart';

/// Résultat de l'application d'un lancer aux règles d'un mode de jeu.
///
/// [isValidThrow] permet de gérer les cas où une règle refuse un lancer
/// (ex: à 501, un lancer qui ferait passer le score sous zéro est un
/// "bust" et est annulé selon les règles officielles).
class RuleOutcome {
  final bool isValidThrow;
  final bool isBust;
  final bool isRoundOver;
  final bool isMatchOver;
  final String message;

  const RuleOutcome({
    required this.isValidThrow,
    this.isBust = false,
    this.isRoundOver = false,
    this.isMatchOver = false,
    this.message = '',
  });
}

/// Contrat commun à toutes les règles de fléchettes prises en charge
/// par Dart Master (101, 301, 501, Cricket, Around the Clock, Count Up).
///
/// Chaque implémentation encapsule sa propre logique de score et de
/// condition de victoire, ce qui permet d'ajouter facilement de
/// nouvelles variantes à l'avenir sans toucher au reste du moteur de jeu.
abstract class GameRules {
  /// Nom affiché du mode de jeu (ex: "501", "Cricket").
  String get displayName;

  /// Score ou état initial du joueur au début d'une manche.
  Map<String, dynamic> initialState();

  /// Applique un lancer (déjà évalué par [ScoringService]) à l'état
  /// courant du joueur, et retourne le nouvel état ainsi que le résultat
  /// de la règle (bust, fin de manche, fin de partie...).
  (Map<String, dynamic> newState, RuleOutcome outcome) applyThrow({
    required Map<String, dynamic> currentState,
    required BoardZone zone,
  });
}
