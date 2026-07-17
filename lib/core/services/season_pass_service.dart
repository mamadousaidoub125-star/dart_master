import 'package:shared_preferences/shared_preferences.dart';

/// Représente un palier du Season Pass, avec sa récompense.
class SeasonPassTier {
  final int tierNumber;
  final int xpRequired;
  final int coinsReward;
  final String? specialReward; // Ex: nom d'une hache/planche exclusive, ou null si juste des pièces.

  const SeasonPassTier({
    required this.tierNumber,
    required this.xpRequired,
    required this.coinsReward,
    this.specialReward,
  });
}

/// Gère la progression du "Season Pass" : une piste de 10 paliers
/// débloqués progressivement avec l'XP gagnée en jouant, façon jeu
/// mobile premium (Fortnite, Clash Royale, etc.), pour donner un
/// objectif de progression à plus long terme que la simple XP/niveau.
class SeasonPassService {
  SeasonPassService._();

  static const _keyClaimedTiers = 'season_pass_claimed_tiers';

  /// 10 paliers, 300 XP d'écart entre chaque, avec une récompense spéciale
  /// tous les 3 paliers pour créer des objectifs marquants.
  static const List<SeasonPassTier> tiers = [
    SeasonPassTier(tierNumber: 1, xpRequired: 300, coinsReward: 50),
    SeasonPassTier(tierNumber: 2, xpRequired: 600, coinsReward: 75),
    SeasonPassTier(tierNumber: 3, xpRequired: 900, coinsReward: 100, specialReward: 'Hache de fer runique'),
    SeasonPassTier(tierNumber: 4, xpRequired: 1200, coinsReward: 100),
    SeasonPassTier(tierNumber: 5, xpRequired: 1500, coinsReward: 150),
    SeasonPassTier(tierNumber: 6, xpRequired: 1800, coinsReward: 150, specialReward: 'Planche de pierre runique'),
    SeasonPassTier(tierNumber: 7, xpRequired: 2100, coinsReward: 200),
    SeasonPassTier(tierNumber: 8, xpRequired: 2400, coinsReward: 200),
    SeasonPassTier(tierNumber: 9, xpRequired: 2700, coinsReward: 250, specialReward: 'Hache enflammée'),
    SeasonPassTier(tierNumber: 10, xpRequired: 3000, coinsReward: 500, specialReward: "Hache dorée d'Odin"),
  ];

  static Future<Set<int>> loadClaimedTiers() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyClaimedTiers) ?? const [];
    return list.map(int.parse).toSet();
  }

  static Future<void> markTierClaimed(int tierNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyClaimedTiers) ?? const []).map(int.parse).toSet();
    current.add(tierNumber);
    await prefs.setStringList(_keyClaimedTiers, current.map((e) => e.toString()).toList());
  }
}
