import 'rules/game_rules.dart';
import 'rules/x01_rules.dart';
import 'rules/cricket_rules.dart';
import 'rules/around_the_clock_rules.dart';
import 'rules/count_up_rules.dart';

/// Identifiants uniques des variantes de règles supportées par Dart Master.
enum GameVariant { oneOhOne, threeOhOne, fiveOhOne, cricket, aroundTheClock, countUp }

/// Fabrique centralisant la création des règles de jeu à partir d'une
/// variante choisie par le joueur dans l'écran "Choix du mode de jeu".
///
/// Centraliser cette logique ici évite d'éparpiller des `switch` sur
/// [GameVariant] dans toute la présentation, et facilite l'ajout futur
/// de nouvelles variantes (ex: Shanghai, Killer) sans casser l'existant.
class GameRulesFactory {
  GameRulesFactory._();

  static GameRules create(GameVariant variant) {
    switch (variant) {
      case GameVariant.oneOhOne:
        return const X01Rules(startingScore: 101);
      case GameVariant.threeOhOne:
        return const X01Rules(startingScore: 301);
      case GameVariant.fiveOhOne:
        return const X01Rules(startingScore: 501);
      case GameVariant.cricket:
        return CricketRules();
      case GameVariant.aroundTheClock:
        return const AroundTheClockRules();
      case GameVariant.countUp:
        return const CountUpRules();
    }
  }

  static String displayName(GameVariant variant) => create(variant).displayName;

  static String description(GameVariant variant) {
    switch (variant) {
      case GameVariant.oneOhOne:
        return 'Format rapide, idéal pour un échauffement.';
      case GameVariant.threeOhOne:
        return 'Format classique, parfait pour progresser.';
      case GameVariant.fiveOhOne:
        return 'Le format de référence en compétition.';
      case GameVariant.cricket:
        return 'Fermez les cases 15 à 20 et le Bull avant votre adversaire.';
      case GameVariant.aroundTheClock:
        return 'Touchez les numéros de 1 à 20 puis le Bull, dans l\'ordre.';
      case GameVariant.countUp:
        return 'Cumulez un maximum de points sur 8 volées.';
    }
  }
}
