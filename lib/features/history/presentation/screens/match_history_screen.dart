import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class MatchHistoryEntry {
  final String gameVariant;
  final String opponentName;
  final bool isVictory;
  final int myScore;
  final int opponentScore;
  final DateTime playedAt;

  const MatchHistoryEntry({
    required this.gameVariant,
    required this.opponentName,
    required this.isVictory,
    required this.myScore,
    required this.opponentScore,
    required this.playedAt,
  });
}

/// Écran d'historique des parties jouées, alimenté par la collection
/// `matches` (lecture seule côté client, écrite uniquement par
/// `validateMatchResult`, voir firebase/functions/src/index.js).
class MatchHistoryScreen extends StatelessWidget {
  final List<MatchHistoryEntry> matches;
  const MatchHistoryScreen({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Historique des parties')),
      body: matches.isEmpty
          ? const Center(child: Text('Aucune partie jouée pour le moment', style: TextStyle(color: AppColors.lightGray)))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: matches.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final match = matches[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(14)),
                  child: Row(
                    children: [
                      Container(
                        width: 6, height: 40,
                        decoration: BoxDecoration(
                          color: match.isVictory ? AppColors.green : AppColors.red,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${match.gameVariant} vs ${match.opponentName}',
                                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                            Text(_formatDate(match.playedAt), style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${match.myScore} - ${match.opponentScore}',
                        style: TextStyle(
                          color: match.isVictory ? AppColors.green : AppColors.red,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
