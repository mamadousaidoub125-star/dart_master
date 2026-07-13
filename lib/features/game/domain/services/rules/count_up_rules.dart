import '../../entities/board_zone.dart';
import 'game_rules.dart';

/// Implémente le mode **Count Up**, souvent utilisé comme mode
/// d'entraînement ou de comparaison rapide entre joueurs.
///
/// Contrairement aux modes X01, il n'y a pas de score de départ à
/// atteindre : chaque lancer ajoute simplement des points au total du
/// joueur sur un nombre fixe de volées ([totalRounds], 8 par défaut,
/// soit 24 fléchettes). Le joueur avec le score total le plus élevé à
/// la fin des volées remporte la partie.
class CountUpRules implements GameRules {
  final int totalRounds;

  const CountUpRules({this.totalRounds = 8});

  @override
  String get displayName => 'Count Up';

  @override
  Map<String, dynamic> initialState() => {
        'totalScore': 0,
        'dartsThrownThisRound': 0,
        'roundsCompleted': 0,
      };

  @override
  (Map<String, dynamic>, RuleOutcome) applyThrow({
    required Map<String, dynamic> currentState,
    required BoardZone zone,
  }) {
    final int totalScore = (currentState['totalScore'] as int) + zone.points;
    final int dartsThrown = (currentState['dartsThrownThisRound'] as int) + 1;
    final bool roundOver = dartsThrown >= 3;
    final int roundsCompleted = (currentState['roundsCompleted'] as int) + (roundOver ? 1 : 0);
    final bool matchOver = roundOver && roundsCompleted >= totalRounds;

    return (
      {
        'totalScore': totalScore,
        'dartsThrownThisRound': roundOver ? 0 : dartsThrown,
        'roundsCompleted': roundsCompleted,
      },
      RuleOutcome(
        isValidThrow: true,
        isRoundOver: roundOver,
        isMatchOver: matchOver,
        message: matchOver ? 'Partie terminée, score final : $totalScore' : '',
      ),
    );
  }
}
