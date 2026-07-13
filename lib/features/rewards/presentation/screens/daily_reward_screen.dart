import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DailyRewardDay {
  final int dayNumber;
  final int coins;
  final int diamonds;
  final bool isClaimed;
  final bool isToday;

  const DailyRewardDay({
    required this.dayNumber,
    required this.coins,
    this.diamonds = 0,
    required this.isClaimed,
    required this.isToday,
  });
}

/// Écran de récompense quotidienne : cycle de 7 jours avec un palier
/// bonus (diamants) le jour 7, incitant à la connexion quotidienne
/// sans pour autant pénaliser durement une absence isolée.
class DailyRewardScreen extends StatelessWidget {
  final List<DailyRewardDay> days;
  final VoidCallback onClaimToday;
  final bool canWatchAdForBonus;
  final VoidCallback onWatchAdForBonus;

  const DailyRewardScreen({
    super.key,
    required this.days,
    required this.onClaimToday,
    this.canWatchAdForBonus = true,
    required this.onWatchAdForBonus,
  });

  @override
  Widget build(BuildContext context) {
    final todayIndex = days.indexWhere((d) => d.isToday);

    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Récompense quotidienne')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) => _DayCard(day: days[index]),
            ),
            const Spacer(),
            if (todayIndex != -1 && !days[todayIndex].isClaimed)
              ElevatedButton(
                onPressed: onClaimToday,
                child: Text('Réclamer le jour ${days[todayIndex].dayNumber}'),
              ),
            if (canWatchAdForBonus) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onWatchAdForBonus,
                icon: const Icon(Icons.play_circle, color: AppColors.gold),
                label: const Text('Doubler la récompense (vidéo)', style: TextStyle(color: AppColors.gold)),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  final DailyRewardDay day;
  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final isBonusDay = day.dayNumber == 7;
    return Container(
      decoration: BoxDecoration(
        color: day.isToday ? AppColors.electricBlue.withOpacity(0.25) : AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: day.isToday ? Border.all(color: AppColors.electricBlue, width: 2) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('J${day.dayNumber}', style: const TextStyle(color: AppColors.lightGray, fontSize: 11)),
          Icon(
            isBonusDay ? Icons.card_giftcard : Icons.monetization_on,
            color: day.isClaimed ? AppColors.lightGray : AppColors.gold,
            size: 22,
          ),
          Text('${day.coins}', style: const TextStyle(color: AppColors.white, fontSize: 11, fontWeight: FontWeight.w600)),
          if (day.isClaimed)
            const Icon(Icons.check_circle, color: AppColors.green, size: 14),
        ],
      ),
    );
  }
}
