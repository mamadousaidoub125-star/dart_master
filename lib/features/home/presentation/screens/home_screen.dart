import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/app_user.dart';

/// Écran d'accueil premium : point central de navigation, avec cartes de
/// modes de jeu façon jeu AAA, bouton principal à effet néon, et barre
/// de navigation inférieure fonctionnelle.
class HomeScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onPlayPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onShopPressed;
  final VoidCallback onLeaderboardPressed;
  final VoidCallback onFriendsPressed;
  final VoidCallback onDailyRewardPressed;
  final VoidCallback onMissionsPressed;
  final VoidCallback onOpenSeasonPass;

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
    required this.onOpenSeasonPass,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _GameModeCardData {
  final String label;
  final IconData icon;
  final Color color;
  const _GameModeCardData(this.label, this.icon, this.color);
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  static const _modeCards = [
    _GameModeCardData('501', Icons.looks_one, AppColors.electricBlue),
    _GameModeCardData('301', Icons.looks_two, AppColors.gold),
    _GameModeCardData('Cricket', Icons.sports_cricket, AppColors.green),
    _GameModeCardData('Around\nthe Clock', Icons.access_time_filled, AppColors.orange),
    _GameModeCardData('Entraînement', Icons.fitness_center, AppColors.lightGray),
    _GameModeCardData('Match rapide', Icons.bolt, AppColors.gold),
    _GameModeCardData('Tournoi', Icons.emoji_events, AppColors.electricBlue),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildCurrencyBar(),
              const SizedBox(height: 24),
              _PlayButton(onPressed: widget.onPlayPressed),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: widget.onOpenSeasonPass,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.military_tech, color: AppColors.midnightBlue),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Season Pass Viking', style: TextStyle(color: AppColors.midnightBlue, fontWeight: FontWeight.w800)),
                      ),
                      Icon(Icons.chevron_right, color: AppColors.midnightBlue),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Modes de jeu',
                style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 16),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.95,
                  ),
                  itemCount: _modeCards.length,
                  itemBuilder: (context, index) {
                    final mode = _modeCards[index];
                    return _ModeCard(data: mode, onTap: widget.onPlayPressed);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: widget.onProfilePressed,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: AppColors.neonGlow(AppColors.gold, intensity: 0.3),
            ),
            child: CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.darkSurfaceElevated,
              backgroundImage: widget.user.photoUrl != null ? NetworkImage(widget.user.photoUrl!) : null,
              child: widget.user.photoUrl == null ? const Icon(Icons.person, color: AppColors.white) : null,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.user.displayName,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
              Text('Niveau ${widget.user.level}', style: const TextStyle(color: AppColors.lightGray, fontSize: 12)),
            ],
          ),
        ),
        IconButton(onPressed: widget.onSettingsPressed, icon: const Icon(Icons.settings, color: AppColors.white)),
      ],
    );
  }

  Widget _buildCurrencyBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.darkSurface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: Row(
            children: [
              _CurrencyChip(icon: Icons.monetization_on, color: AppColors.gold, value: widget.user.coins),
              const SizedBox(width: 12),
              _CurrencyChip(icon: Icons.diamond, color: AppColors.electricBlue, value: widget.user.diamonds),
              const Spacer(),
              IconButton(
                onPressed: widget.onDailyRewardPressed,
                icon: const Icon(Icons.card_giftcard, color: AppColors.gold),
                tooltip: 'Récompense quotidienne',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedTab,
      onTap: (index) {
        setState(() => _selectedTab = index);
        switch (index) {
          case 0:
            break; // Déjà sur l'accueil.
          case 1:
            widget.onPlayPressed();
            break;
          case 2:
            widget.onMissionsPressed();
            break;
          case 3:
            widget.onShopPressed();
            break;
          case 4:
            widget.onProfilePressed();
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
        BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: 'Jouer'),
        BottomNavigationBarItem(icon: Icon(Icons.flag), label: 'Défis'),
        BottomNavigationBarItem(icon: Icon(Icons.storefront), label: 'Boutique'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _PlayButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: AppColors.electricGradient,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.neonGlow(AppColors.electricBlue),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_arrow, color: AppColors.white, size: 28),
            SizedBox(width: 8),
            Text('JOUER', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final _GameModeCardData data;
  final VoidCallback onTap;
  const _ModeCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: data.color.withOpacity(0.35)),
          boxShadow: [
            BoxShadow(color: data.color.withOpacity(0.15), blurRadius: 12, spreadRadius: 1),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(data.icon, color: data.color, size: 28),
            const SizedBox(height: 8),
            Text(
              data.label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Text('$value', style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
