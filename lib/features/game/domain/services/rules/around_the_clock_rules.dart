import '../../entities/board_zone.dart';
import 'game_rules.dart';

/// Implémente les règles du mode **Around the Clock**.
///
/// Le joueur doit toucher les numéros dans l'ordre croissant, de 1 à 20,
/// puis terminer sur le Bull. Un lancer qui ne touche pas le numéro
/// actuellement visé n'a aucun effet (ce n'est pas une erreur, juste un
/// lancer qui ne fait pas progresser le joueur). Variante "stricte"
/// disponible via [requireDoubleToAdvance] pour les joueurs confirmés
/// (chaque numéro doit être touché en double pour passer au suivant).
class AroundTheClockRules implements GameRules {
  final bool requireDoubleToAdvance;

  const AroundTheClockRules({this.requireDoubleToAdvance = false});

  @override
  String get displayName => 'Around the Clock';

  @override
  Map<String, dynamic> initialState() => {
        'currentTarget': 1, // 1 à 20, puis 25 (Bull) pour terminer.
        'dartsUsed': 0,
      };

  @override
  (Map<String, dynamic>, RuleOutcome) applyThrow({
    required Map<String, dynamic> currentState,
    required BoardZone zone,
  }) {
    final int currentTarget = currentState['currentTarget'] as int;
    final int dartsUsed = (currentState['dartsUsed'] as int) + 1;
    final int touchedNumber = zone.isBullseye ? 25 : zone.score;

    final bool validHit = touchedNumber == currentTarget &&
        (!requireDoubleToAdvance || zone.multiplier == 2 || zone.isDoubleBull || currentTarget == 25);

    if (!validHit) {
      return (
        {...currentState, 'dartsUsed': dartsUsed},
        const RuleOutcome(isValidThrow: true, message: 'Cible non atteinte, prochain essai'),
      );
    }

    final int nextTarget = currentTarget == 25 ? 25 : (currentTarget == 20 ? 25 : currentTarget + 1);
    final bool matchOver = currentTarget == 25;

    return (
      {'currentTarget': nextTarget, 'dartsUsed': dartsUsed},
      RuleOutcome(
        isValidThrow: true,
        isMatchOver: matchOver,
        message: matchOver ? 'Parcours terminé en $dartsUsed fléchettes !' : 'Cible $currentTarget validée',
      ),
    );
  }
}
