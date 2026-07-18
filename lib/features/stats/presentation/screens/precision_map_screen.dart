import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../game/presentation/widgets/dartboard_painter.dart';

/// Écran "Carte de précision" : superpose tous les points d'impact
/// récents du joueur sur la planche, pour visualiser sa tendance de tir
/// (regroupé au centre = précis, dispersé = à travailler). Un effet très
/// apprécié dans les jeux de précision premium, façon tableau de bord
/// analytique plutôt qu'un simple total de statistiques.
class PrecisionMapScreen extends StatelessWidget {
  final List<(double, double)> impacts;
  final VoidCallback onClearHistory;

  const PrecisionMapScreen({super.key, required this.impacts, required this.onClearHistory});

  /// Calcule un indice de régularité simple (0 à 100) à partir de
  /// l'écart-type des distances au centre : plus les impacts sont
  /// regroupés, plus l'indice est élevé.
  double get _consistencyScore {
    if (impacts.isEmpty) return 0;
    final distances = impacts.map((p) {
      final (x, y) = p;
      return (x * x + y * y);
    }).map((d) => d).toList();
    final mean = distances.reduce((a, b) => a + b) / distances.length;
    final variance = distances.map((d) => (d - mean) * (d - mean)).reduce((a, b) => a + b) / distances.length;
    final spread = variance.clamp(0.0, 1.0);
    return ((1 - spread) * 100).clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(
        title: const Text('Carte de précision'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Réinitialiser l\'historique',
            onPressed: onClearHistory,
          ),
        ],
      ),
      body: impacts.isEmpty
          ? const Center(
              child: Text(
                'Aucun lancer enregistré pour le moment.\nJoue quelques manches pour voir ta carte de précision !',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.lightGray),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatChip('Lancers analysés', '${impacts.length}'),
                      _buildStatChip('Régularité', '${_consistencyScore.toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final boardSize = Size.square(constraints.maxWidth);
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                CustomPaint(size: boardSize, painter: DartboardPainter()),
                                ...impacts.map((p) {
                                  final (x, y) = p;
                                  return Positioned(
                                    left: boardSize.width / 2 + x * boardSize.width / 2 - 4,
                                    top: boardSize.height / 2 + y * boardSize.height / 2 - 4,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.gold.withOpacity(0.45),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Chaque point doré représente un lancer récent. Plus les points sont regroupés au centre, meilleure est ta précision.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.lightGray, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 20)),
          Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 11)),
        ],
      ),
    );
  }
}
