import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralise toute l'intégration Google AdMob de Dart Master.
///
/// ⚠️ Les identifiants ci-dessous sont les IDs de TEST officiels fournis
/// par Google. Ils DOIVENT être remplacés par tes propres IDs de
/// production (créés dans ta console AdMob) avant publication, sous
/// peine de bannissement du compte AdMob pour clics invalides pendant
/// les tests. Voir GUIDE_PUBLICATION.md, section AdMod.
class AdMobService {
  AdMobService._();
  static final AdMobService instance = AdMobService._();

  static const String _testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testBannerIos = 'ca-app-pub-3940256099942544/2934735716';
  static const String _testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';
  static const String _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isPremiumUser = false;

  Future<void> initialize() => MobileAds.instance.initialize();

  /// Doit être appelé dès que le statut premium de l'utilisateur est
  /// connu (au login et après tout achat/renouvellement d'abonnement),
  /// pour désactiver intégralement les publicités pour les abonnés.
  void updatePremiumStatus(bool isPremium) => _isPremiumUser = isPremium;

  /// Widget bannière à placer en bas des écrans non-premium (accueil,
  /// classements, boutique). Retourne `null` pour un utilisateur premium.
  BannerAd? createBannerAd({required void Function(Ad ad) onLoaded, required void Function(Ad ad, LoadAdError error) onFailed}) {
    if (_isPremiumUser) return null;
    return BannerAd(
      // TODO(prod): remplacer par l'ID de production Android/iOS avant publication.
      adUnitId: _testBannerAndroid,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(onAdLoaded: onLoaded, onAdFailedToLoad: onFailed),
    )..load();
  }

  /// Précharge un interstitiel, à afficher entre deux manches ou au
  /// retour à l'accueil après une partie (jamais pendant une manche en cours).
  void preloadInterstitial() {
    if (_isPremiumUser) return;
    InterstitialAd.load(
      adUnitId: _testInterstitialAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (_) => _interstitialAd = null,
      ),
    );
  }

  Future<void> showInterstitialIfReady() async {
    if (_isPremiumUser || _interstitialAd == null) return;
    await _interstitialAd!.show();
    _interstitialAd = null;
    preloadInterstitial(); // Recharge immédiatement le prochain interstitiel.
  }

  /// Précharge une vidéo récompensée (bonus de pièces, coffre gratuit).
  void preloadRewardedAd() {
    RewardedAd.load(
      adUnitId: _testRewardedAndroid,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (_) => _rewardedAd = null,
      ),
    );
  }

  /// Affiche la vidéo récompensée si disponible. [onUserEarnedReward] est
  /// appelé UNIQUEMENT si l'utilisateur a regardé la vidéo jusqu'au bout
  /// (comportement standard AdMob, empêche de récompenser un skip précoce).
  Future<bool> showRewardedAd({required void Function(int amount) onUserEarnedReward}) async {
    if (_rewardedAd == null) return false;
    bool earned = false;
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
        onUserEarnedReward(reward.amount.toInt());
      },
    );
    _rewardedAd = null;
    preloadRewardedAd();
    return earned;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
