import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class Mission {
  final String id;
  final String title;
  final int currentProgress;
  final int targetProgress;
  final int coinsReward;
  final bool isClaimed;

  const Mission({
    required this.id,
    required this.title,
    required this.currentProgress,
    required this.targetProgress,
    required this.coinsReward,
    this.isClaimed = false,
  });

  bool get isCompleted => currentProgress >= targetProgress;
}

/// Écran des missions quotidiennes (ex: "Marquez 3 triples", "Gagnez
/// une partie en Cricket") renouvelées chaque jour à minuit (heure locale).
class MissionsScreen extends StatelessWidget {
  final List<Mission> missions;
  final void Function(Mission mission) onClaimReward;

  const MissionsScreen({super.key, required this.missions, required this.onClaimReward});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Missions quotidiennes')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: missions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final mission = missions[index];
          final progress = (mission.currentProgress / mission.targetProgress).clamp(0.0, 1.0);
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mission.title, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.darkSurfaceElevated,
                    color: mission.isCompleted ? AppColors.green : AppColors.electricBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${mission.currentProgress}/${mission.targetProgress}',
                        style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                    if (mission.isCompleted && !mission.isClaimed)
                      ElevatedButton(
                        onPressed: () => onClaimReward(mission),
                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                        child: Text('+${mission.coinsReward} 🪙'),
                      )
                    else if (mission.isClaimed)
                      const Text('Réclamée', style: TextStyle(color: AppColors.green, fontSize: 12))
                    else
                      Text('${mission.coinsReward} 🪙', style: const TextStyle(color: AppColors.gold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.isUnlocked,
    this.unlockedAt,
  });
}

/// Écran des succès (achievements) : accomplissements permanents,
/// contrairement aux missions qui se renouvellent chaque jour.
class AchievementsScreen extends StatelessWidget {
  final List<Achievement> achievements;
  const AchievementsScreen({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: Text('Succès ($unlockedCount/${achievements.length})')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final achievement = achievements[index];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkSurface,
              borderRadius: BorderRadius.circular(14),
              border: achievement.isUnlocked ? Border.all(color: AppColors.gold.withOpacity(0.5)) : null,
            ),
            child: Row(
              children: [
                Icon(
                  achievement.isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                  color: achievement.isUnlocked ? AppColors.gold : AppColors.lightGray,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(achievement.title,
                          style: TextStyle(color: achievement.isUnlocked ? AppColors.white : AppColors.lightGray, fontWeight: FontWeight.w600)),
                      Text(achievement.description, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
