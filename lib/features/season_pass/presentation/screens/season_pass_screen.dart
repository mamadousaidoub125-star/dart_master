import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/season_pass_service.dart';

/// Écran du Season Pass : piste de progression à 10 paliers, débloqués
/// avec l'XP gagnée en jouant, avec pièces et objets exclusifs à la clé.
class SeasonPassScreen extends StatelessWidget {
  final int currentXp;
  final Set<int> claimedTiers;
  final void Function(SeasonPassTier tier) onClaimTier;

  const SeasonPassScreen({
    super.key,
    required this.currentXp,
    required this.claimedTiers,
    required this.onClaimTier,
  });

  @override
  Widget build(BuildContext context) {
    final nextTier = SeasonPassService.tiers.firstWhere(
      (t) => !claimedTiers.contains(t.tierNumber),
      orElse: () => SeasonPassService.tiers.last,
    );

    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Season Pass Viking')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Text('$currentXp XP au total', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w800, fontSize: 20)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (currentXp / nextTier.xpRequired).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: AppColors.darkSurfaceElevated,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: SeasonPassService.tiers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tier = SeasonPassService.tiers[index];
                final isUnlocked = currentXp >= tier.xpRequired;
                final isClaimed = claimedTiers.contains(tier.tierNumber);

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: isUnlocked && !isClaimed ? Border.all(color: AppColors.gold, width: 2) : null,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: isUnlocked ? AppColors.gold : AppColors.darkSurfaceElevated,
                        child: Text('${tier.tierNumber}', style: TextStyle(color: isUnlocked ? AppColors.midnightBlue : AppColors.lightGray, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${tier.coinsReward} 🪙${tier.specialReward != null ? ' + ${tier.specialReward}' : ''}',
                                style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
                            Text('${tier.xpRequired} XP requis', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
                          ],
                        ),
                      ),
                      if (isClaimed)
                        const Icon(Icons.check_circle, color: AppColors.green)
                      else if (isUnlocked)
                        ElevatedButton(onPressed: () => onClaimTier(tier), child: const Text('Réclamer'))
                      else
                        const Icon(Icons.lock, color: AppColors.lightGray),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
