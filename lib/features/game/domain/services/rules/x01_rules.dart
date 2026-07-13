import '../../entities/board_zone.dart';
import 'game_rules.dart';

/// Implémente les règles officielles de la famille "X01" (101, 301, 501).
///
/// Règles officielles appliquées :
/// - Chaque joueur part de [startingScore] points et doit atteindre
///   exactement 0.
/// - La manche doit se terminer sur un **double** (ou le bull central,
///   qui compte comme un double) : c'est la règle "double out" standard
///   utilisée en compétition.
/// - Si un lancer ferait passer le score en dessous de 0, l'amènerait
///   exactement à 1 (impossible à finir sur un double), ou à 0 sans que
///   le dernier lancer soit un double : c'est un **"bust"**. Tous les
///   points de la volée en cours sont alors annulés et le tour repasse
///   au joueur suivant avec le score d'avant la volée.
class X01Rules implements GameRules {
  final int startingScore; // 101, 301 ou 501

  const X01Rules({required this.startingScore});

  @override
  String get displayName => '$startingScore';

  @override
  Map<String, dynamic> initialState() => {
        'remainingScore': startingScore,
        'scoreBeforeThisRound': startingScore,
        'dartsThrownThisRound': 0,
      };

  @override
  (Map<String, dynamic>, RuleOutcome) applyThrow({
    required Map<String, dynamic> currentState,
    required BoardZone zone,
  }) {
    final int remaining = currentState['remainingScore'] as int;
    final int dartsThrown = currentState['dartsThrownThisRound'] as int;
    final int newDartsThrown = dartsThrown + 1;

    final int afterThrow = remaining - zone.points;
    final bool endsOnDouble = zone.multiplier == 2 || zone.isDoubleBull;

    // Cas de victoire : score exact à 0 ET dernier lancer sur un double.
    if (afterThrow == 0 && endsOnDouble) {
      return (
        {
          ...currentState,
          'remainingScore': 0,
          'dartsThrownThisRound': newDartsThrown,
        },
        const RuleOutcome(
          isValidThrow: true,
          isRoundOver: true,
          isMatchOver: true,
          message: 'Partie terminée : checkout réussi !',
        ),
      );
    }

    // Cas de "bust" : score négatif, égal à 1, ou à 0 sans finir sur un double.
    final bool isBust = afterThrow < 0 || afterThrow == 1 || (afterThrow == 0 && !endsOnDouble);
    if (isBust) {
      final int scoreBeforeRound = currentState['scoreBeforeThisRound'] as int;
      return (
        {
          ...currentState,
          'remainingScore': scoreBeforeRound, // Annulation de toute la volée.
          'dartsThrownThisRound': 0,
        },
        const RuleOutcome(
          isValidThrow: true,
          isBust: true,
          isRoundOver: true,
          message: 'Bust ! Le score de la volée est annulé.',
        ),
      );
    }

    // Fin normale de la volée de 3 fléchettes, sans bust ni victoire.
    final bool roundOver = newDartsThrown >= 3;
    return (
      {
        ...currentState,
        'remainingScore': afterThrow,
        'dartsThrownThisRound': roundOver ? 0 : newDartsThrown,
        if (roundOver) 'scoreBeforeThisRound': afterThrow,
      },
      RuleOutcome(isValidThrow: true, isRoundOver: roundOver),
    );
  }
}
