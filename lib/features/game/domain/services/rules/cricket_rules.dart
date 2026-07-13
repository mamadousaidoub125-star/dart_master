import '../../entities/board_zone.dart';
import 'game_rules.dart';

/// Implémente les règles officielles du mode **Cricket**.
///
/// Les cases jouables sont 15, 16, 17, 18, 19, 20 et le Bull. Pour
/// "fermer" une case, un joueur doit la toucher 3 fois (un simple compte
/// pour 1, un double pour 2, un triple pour 3 marques). Une fois une case
/// fermée par un joueur, celui-ci marque des points dessus tant que
/// l'adversaire ne l'a pas fermée à son tour ; une case fermée par les
/// deux joueurs ne rapporte plus de points à personne.
///
/// Le joueur gagne la manche s'il a fermé toutes les cases ET a un score
/// total supérieur ou égal à celui de son adversaire.
class CricketRules implements GameRules {
  static const List<int> playableNumbers = [15, 16, 17, 18, 19, 20, 25];

  @override
  String get displayName => 'Cricket';

  @override
  Map<String, dynamic> initialState() => {
        // marks : nombre de marques (0 à 3) par case, par joueur.
        'marksPlayer': {for (final n in playableNumbers) '$n': 0},
        'marksOpponent': {for (final n in playableNumbers) '$n': 0},
        'scorePlayer': 0,
        'scoreOpponent': 0,
      };

  @override
  (Map<String, dynamic>, RuleOutcome) applyThrow({
    required Map<String, dynamic> currentState,
    required BoardZone zone,
  }) {
    final int number = zone.isBullseye ? 25 : zone.score;

    // Case non jouable en Cricket (ex: un 7 simple) : lancer valide mais sans effet.
    if (!playableNumbers.contains(number)) {
      return (currentState, const RuleOutcome(isValidThrow: true, message: 'Case non jouable en Cricket'));
    }

    final marksPlayer = Map<String, int>.from(currentState['marksPlayer']);
    final marksOpponent = Map<String, int>.from(currentState['marksOpponent']);
    int scorePlayer = currentState['scorePlayer'] as int;

    final int hits = zone.isDoubleBull ? 2 : zone.multiplier; // Bull central = double bull = 2 marques.
    final int currentMarks = marksPlayer['$number'] ?? 0;
    final int newMarks = (currentMarks + hits).clamp(0, 3);
    marksPlayer['$number'] = newMarks;

    // Si la case n'est pas encore fermée par l'adversaire, les marques
    // excédentaires (au-delà de 3) rapportent des points.
    final int opponentMarks = marksOpponent['$number'] ?? 0;
    if (opponentMarks < 3) {
      final int excessHits = (currentMarks + hits) - 3;
      if (excessHits > 0) {
        scorePlayer += excessHits * number;
      }
    }

    final newState = {
      ...currentState,
      'marksPlayer': marksPlayer,
      'marksOpponent': marksOpponent,
      'scorePlayer': scorePlayer,
    };

    // Victoire : toutes les cases fermées par le joueur ET score >= adversaire.
    final bool allClosed = playableNumbers.every((n) => (marksPlayer['$n'] ?? 0) >= 3);
    final int scoreOpponent = currentState['scoreOpponent'] as int;
    if (allClosed && scorePlayer >= scoreOpponent) {
      return (
        newState,
        const RuleOutcome(isValidThrow: true, isMatchOver: true, message: 'Toutes les cases fermées, victoire !'),
      );
    }

    return (newState, const RuleOutcome(isValidThrow: true));
  }
}
