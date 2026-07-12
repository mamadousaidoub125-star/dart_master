/// Représente le résultat de l'évaluation d'un point d'impact sur la cible.
///
/// [score] est la valeur brute de la case touchée (1 à 20, ou 25 pour le centre).
/// [multiplier] vaut 1 (simple), 2 (double / bull extérieur) ou 3 (triple).
/// [isBullseye] et [isDoubleBull] identifient le centre de la cible,
/// utile pour les règles "Around the Clock" et pour terminer une manche à 501/301.
class BoardZone {
  final int score;
  final int multiplier;
  final bool isBullseye;
  final bool isDoubleBull;
  final String label; // Ex: "Triple 20", "Simple 5", "Bull"

  const BoardZone({
    required this.score,
    required this.multiplier,
    required this.label,
    this.isBullseye = false,
    this.isDoubleBull = false,
  });

  /// Valeur totale des points rapportés par ce lancer (score * multiplicateur).
  int get points => score * multiplier;

  /// Zone représentant un lancer complètement manqué (hors de la cible).
  static const BoardZone miss = BoardZone(score: 0, multiplier: 1, label: 'Manqué');

  @override
  String toString() => label;
}
