import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Écran d'accueil : point central de navigation vers les différents
/// modes de jeu et fonctionnalités (boutique, missions, classements...).
class HomeScreen extends StatelessWidget {
  final AppUser user;
  final VoidCallback onPlayPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onShopPressed;
  final VoidCallback onLeaderboardPressed;
  final VoidCallback onFriendsPressed;
  final VoidCallback onDailyRewardPressed;
  final VoidCallback onMissionsPressed;

  const HomeScreen({
    super.key,
    required this.user,
    required this.onPlayPressed,
    required this.onProfilePressed,
    required this.onSettingsPressed,
    required this.onShopPressed,
    required this.onLeaderboardPressed,
    required this.onFriendsPressed,
    required this.onDailyRewardPressed,
    required this.onMissionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildCurrencyBar(),
              const SizedBox(height: 32),
              Expanded(
                child: Center(
                  child: _PlayButton(onPressed: onPlayPressed),
                ),
              ),
              _buildQuickActionsRow(),
              const SizedBox(height: 12),
              _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: onProfilePressed,
          child: CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.darkSurfaceElevated,
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child: user.photoUrl == null
                ? const Icon(Icons.person, color: AppColors.white)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.displayName,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              Text('Niveau ${user.level}', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
            ],
          ),
        ),
        IconButton(onPressed: onSettingsPressed, icon: const Icon(Icons.settings, color: AppColors.white)),
      ],
    );
  }

  Widget _buildCurrencyBar() {
    return Row(
      children: [
        _CurrencyChip(icon: Icons.monetization_on, color: AppColors.gold, value: user.coins),
        const SizedBox(width: 12),
        _CurrencyChip(icon: Icons.diamond, color: AppColors.electricBlue, value: user.diamonds),
        const Spacer(),
        IconButton(
          onPressed: onDailyRewardPressed,
          icon: const Icon(Icons.card_giftcard, color: AppColors.gold),
          tooltip: 'Récompense quotidienne',
        ),
      ],
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickAction(icon: Icons.storefront, label: 'Boutique', onTap: onShopPressed),
        _QuickAction(icon: Icons.emoji_events, label: 'Classements', onTap: onLeaderboardPressed),
        _QuickAction(icon: Icons.people, label: 'Amis', onTap: onFriendsPressed),
        _QuickAction(icon: Icons.task_alt, label: 'Missions', onTap: onMissionsPressed),
      ],
    );
  }

  Widget _buildBottomNav() => const SizedBox.shrink(); // Réservé pour une éventuelle barre de nav Phase 5.
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _PlayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 180,
        height: 180,
        decoration: const BoxDecoration(gradient: AppColors.electricGradient, shape: BoxShape.circle),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, color: AppColors.white, size: 56),
            Text('JOUER', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _CurrencyChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final int value;
  const _CurrencyChip({required this.icon, required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppColors.darkSurface, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text('$value', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 24, backgroundColor: AppColors.darkSurface, child: Icon(icon, color: AppColors.gold)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.lightGray, fontSize: 11)),
        ],
      ),
    );
  }
}
