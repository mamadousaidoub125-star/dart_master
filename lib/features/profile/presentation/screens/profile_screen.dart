import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Écran de profil : identité du joueur, progression, badges et
/// cadre de profil débloqué (personnalisation cosmétique).
class ProfileScreen extends StatelessWidget {
  final AppUser user;
  final List<String> unlockedBadges;
  final int gamesPlayed;
  final int gamesWon;
  final double averageScore;
  final VoidCallback? onOpenPrecisionMap;

  const ProfileScreen({
    super.key,
    required this.user,
    this.unlockedBadges = const [],
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.averageScore = 0,
    this.onOpenPrecisionMap,
  });

  @override
  Widget build(BuildContext context) {
    final winRate = gamesPlayed == 0 ? 0.0 : (gamesWon / gamesPlayed) * 100;

    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppColors.darkSurfaceElevated,
                  backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
                  child: user.photoUrl == null ? const Icon(Icons.person, size: 48, color: AppColors.white) : null,
                ),
                const SizedBox(height: 12),
                Text(user.displayName,
                    style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                Text('Niveau ${user.level} · ${user.xp} XP', style: const TextStyle(color: AppColors.lightGray)),
                if (user.isPremium) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(12)),
                    child: const Text('PREMIUM', style: TextStyle(color: AppColors.midnightBlue, fontWeight: FontWeight.w800)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(child: _StatCard(label: 'Parties', value: '$gamesPlayed')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Victoires', value: '$gamesWon')),
              const SizedBox(width: 12),
              Expanded(child: _StatCard(label: 'Taux de victoire', value: '${winRate.toStringAsFixed(0)}%')),
            ],
          ),
          const SizedBox(height: 12),
          _StatCard(label: 'Moyenne par volée (3 fléchettes)', value: averageScore.toStringAsFixed(1), fullWidth: true),
          const SizedBox(height: 16),
          if (onOpenPrecisionMap != null)
            OutlinedButton.icon(
              onPressed: onOpenPrecisionMap,
              icon: const Icon(Icons.my_location, color: AppColors.gold),
              label: const Text('Voir ma carte de précision'),
            ),
          const SizedBox(height: 28),
          const Text('Badges débloqués', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          unlockedBadges.isEmpty
              ? const Text('Aucun badge débloqué pour le moment.', style: TextStyle(color: AppColors.lightGray))
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: unlockedBadges
                      .map((badge) => Chip(
                            label: Text(badge, style: const TextStyle(color: AppColors.white)),
                            backgroundColor: AppColors.darkSurface,
                            avatar: const Icon(Icons.military_tech, color: AppColors.gold, size: 18),
                          ))
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final bool fullWidth;
  const _StatCard({required this.label, required this.value, this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(color: AppColors.gold, fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
        ],
      ),
    );
  }
}
