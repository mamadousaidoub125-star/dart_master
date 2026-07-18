import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
import 'core/theme/app_colors.dart';
import 'core/services/session_service.dart';
import 'core/services/settings_service.dart';
import 'features/onboarding/presentation/screens/splash_screen.dart';
import 'features/onboarding/presentation/screens/tutorial_screen.dart';
import 'features/auth/domain/entities/app_user.dart';
import 'features/auth/data/repositories/mock_auth_repository.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/signup_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/game_modes/presentation/screens/game_mode_selection_screen.dart';
import 'features/game/presentation/screens/game_screen.dart';
import 'features/game/domain/services/game_rules_factory.dart';
import 'features/profile/presentation/screens/profile_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';
import 'features/legal/presentation/screens/privacy_policy_screen.dart';
import 'features/support/presentation/screens/support_screen.dart';
import 'features/shop/presentation/screens/shop_screen.dart';
import 'features/monetization/domain/entities/shop_product.dart';
import 'core/services/inventory_service.dart';
import 'core/services/throw_history_service.dart';
import 'features/stats/presentation/screens/precision_map_screen.dart';
import 'core/services/season_pass_service.dart';
import 'features/season_pass/presentation/screens/season_pass_screen.dart';

/// Orchestrateur central de navigation de Dart Master pour cette phase
/// de développement.
///
/// NOTE D'ARCHITECTURE : cette classe utilise une machine à états simple
/// (`_AppScreen` + `setState`) plutôt qu'un système de routage nommé
/// (go_router, Navigator 2.0) afin de garder le flux Splash → Auth →
/// Accueil → Jeu facile à suivre et à tester dans cette phase de
/// livraison. Pour une application de cette envergure en production,
/// il est recommandé de migrer vers `go_router` avec des routes
/// nommées et une gestion des deep links (invitations d'amis,
/// notifications push cliquées, etc.).
class AppShell extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ThemeMode currentThemeMode;

  const AppShell({super.key, required this.onThemeModeChanged, required this.currentThemeMode});

  @override
  State<AppShell> createState() => _AppShellState();
}

enum _AppScreen { splash, login, signUp, tutorial, home, modeSelection, game, profile, settings, privacyPolicy, support, shop, precisionMap, seasonPass }

class _AppShellState extends State<AppShell> {
  // TODO(Phase 3) : remplacer par FirebaseAuthRepository une fois
  // `flutterfire configure` exécuté (voir docs/GUIDE_INSTALLATION.md).
  final _authRepository = MockAuthRepository();

  _AppScreen _currentScreen = _AppScreen.splash;
  AppUser? _currentUser;
  GameVariant? _selectedVariant;
  OpponentType? _selectedOpponent;

  bool _hasRestoredSession = false;
  Set<String> _unlockedAxeIds = {};
  Set<String> _unlockedBoardIds = {};
  List<(double, double)> _precisionImpacts = [];
  Set<int> _claimedSeasonTiers = {};
  AppSettings _appSettings = const AppSettings(
    musicEnabled: true,
    soundEffectsEnabled: true,
    vibrationEnabled: true,
    notificationsEnabled: true,
  );

  Future<void> _initializeApp() async {
    // Emplacement prévu pour les initialisations Phase 3 :
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Vérifie si un joueur est déjà resté connecté d'une session précédente.
    // Si oui, on reconstruit son profil localement et on saute directement
    // les écrans de connexion/tutoriel pour l'amener à l'accueil.
    final savedSession = await SessionService.loadSession();
    if (savedSession != null) {
      final savedCoins = await SessionService.loadCoins();
      final savedXp = await SessionService.loadXp();
      _currentUser = AppUser(
        id: savedSession['userId']!,
        displayName: savedSession['displayName']!,
        email: savedSession['email']!,
        coins: savedCoins,
        xp: savedXp,
        level: _levelForXp(savedXp),
      );
      _hasRestoredSession = true;
    }

    // Charge les préférences audio/notifications sauvegardées localement.
    _appSettings = await SettingsService.loadSettings();

    // Charge les haches déjà débloquées par le joueur.
    _unlockedAxeIds = await InventoryService.loadUnlockedAxes();
    _unlockedBoardIds = await InventoryService.loadUnlockedBoards();
    _claimedSeasonTiers = await SeasonPassService.loadClaimedTiers();

    // Démarre la musique de fond en boucle si l'utilisateur ne l'a pas
    // désactivée lors d'une session précédente.
    if (_appSettings.musicEnabled) {
      FlameAudio.bgm.play(_appSettings.musicTrack, volume: 0.5);
    }
  }

  void _handleAuthSuccess(AppUser user) {
    // Sauvegarde la session dès la connexion réussie : le joueur restera
    // connecté même après avoir complètement fermé l'application, jusqu'à
    // ce qu'il appuie explicitement sur "Se déconnecter".
    SessionService.saveSession(
      userId: user.id,
      displayName: user.displayName,
      email: user.email,
    );
    setState(() {
      _currentUser = user;
      _currentScreen = _AppScreen.tutorial;
    });
  }

  /// Calcule le niveau du joueur à partir de son XP totale (500 XP par
  /// niveau, cohérent avec la logique déjà prévue côté Cloud Function
  /// pour la future synchronisation Firestore, voir firebase/functions).
  int _levelForXp(int xp) => (xp ~/ 500) + 1;

  /// Crédite l'XP gagnée après une victoire (voir [GameScreen.onMatchWonXp])
  /// et fait progresser le niveau du joueur en conséquence, ce qui
  /// débloque de nouvelles catégories de mur/tête d'animal dans le jeu.
  void _handleXpEarned(int xpGained) {
    if (_currentUser == null) return;
    final newXp = _currentUser!.xp + xpGained;
    final newLevel = _levelForXp(newXp);
    setState(() => _currentUser = _currentUser!.copyWith(xp: newXp, level: newLevel));
    SessionService.saveXp(newXp);
  }

  /// Crédite le joueur en pièces gagnées pendant une partie (voir
  /// [GameScreen.onCoinsEarned]) et persiste immédiatement le nouveau
  /// solde pour qu'il survive à la fermeture de l'application.
  void _handleCoinsEarned(int amount) {
    if (_currentUser == null) return;
    final newCoins = _currentUser!.coins + amount;
    setState(() => _currentUser = _currentUser!.copyWith(coins: newCoins));
    SessionService.saveCoins(newCoins);
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case _AppScreen.splash:
        return SplashScreen(
          initialize: _initializeApp,
          onInitializationComplete: () => setState(
            () => _currentScreen = _hasRestoredSession ? _AppScreen.home : _AppScreen.login,
          ),
        );

      case _AppScreen.login:
        return LoginScreen(
          authRepository: _authRepository,
          onLoginSuccess: _handleAuthSuccess,
          onNavigateToSignUp: () => setState(() => _currentScreen = _AppScreen.signUp),
        );

      case _AppScreen.signUp:
        return SignUpScreen(
          authRepository: _authRepository,
          onSignUpSuccess: _handleAuthSuccess,
          onNavigateToLogin: () => setState(() => _currentScreen = _AppScreen.login),
        );

      case _AppScreen.tutorial:
        return TutorialScreen(onFinished: () => setState(() => _currentScreen = _AppScreen.home));

      case _AppScreen.home:
        return HomeScreen(
          user: _currentUser!,
          onPlayPressed: () => setState(() => _currentScreen = _AppScreen.modeSelection),
          onProfilePressed: () => setState(() => _currentScreen = _AppScreen.profile),
          onSettingsPressed: () => setState(() => _currentScreen = _AppScreen.settings),
          // TODO(Phase 5) : brancher ces callbacks sur LeaderboardScreen,
          // FriendsScreen, DailyRewardScreen, MissionsScreen une fois les repositories
          // de données réelles connectés à Firestore.
          onShopPressed: () => setState(() => _currentScreen = _AppScreen.shop),
          onLeaderboardPressed: () {},
          onFriendsPressed: () {},
          onDailyRewardPressed: () {},
          onMissionsPressed: () {},
          onOpenSeasonPass: () => setState(() => _currentScreen = _AppScreen.seasonPass),
        );

      case _AppScreen.modeSelection:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.home);
            return false;
          },
          child: GameModeSelectionScreen(
            onModeConfirmed: (variant, opponent) {
              // Les modes en ligne nécessitent un vrai projet Firebase
              // configuré (voir docs/GUIDE_INSTALLATION.md) : le code de
              // synchronisation existe déjà (lib/features/multiplayer/)
              // mais l'utiliser sans Firebase actif provoquerait un
              // plantage. On avertit donc le joueur au lieu de planter.
              if (opponent == OpponentType.onlinePrivate || opponent == OpponentType.onlinePublic) {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppColors.darkSurface,
                    title: const Text('Bientôt disponible', style: TextStyle(color: AppColors.gold)),
                    content: const Text(
                      'Le jeu en ligne nécessite une configuration serveur supplémentaire, pas encore activée dans cette version de test.',
                      style: TextStyle(color: AppColors.white),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Compris'),
                      ),
                    ],
                  ),
                );
                return;
              }
              setState(() {
                _selectedVariant = variant;
                _selectedOpponent = opponent;
                _currentScreen = _AppScreen.game;
              });
            },
          ),
        );

      case _AppScreen.game:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.modeSelection);
            return false;
          },
          child: GameScreen(
            opponentType: _selectedOpponent ?? OpponentType.training,
            vibrationEnabled: _appSettings.vibrationEnabled,
            soundEffectsEnabled: _appSettings.soundEffectsEnabled,
            playerLevel: _currentUser?.level ?? 1,
            onCoinsEarned: _handleCoinsEarned,
            onMatchWonXp: _handleXpEarned,
          ),
        );

      case _AppScreen.profile:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.home);
            return false;
          },
          child: ProfileScreen(
            user: _currentUser!,
            onOpenPrecisionMap: () async {
              final impacts = await ThrowHistoryService.loadImpacts();
              setState(() {
                _precisionImpacts = impacts;
                _currentScreen = _AppScreen.precisionMap;
              });
            },
          ),
        );

      case _AppScreen.precisionMap:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.profile);
            return false;
          },
          child: PrecisionMapScreen(
            impacts: _precisionImpacts,
            onClearHistory: () async {
              await ThrowHistoryService.clearHistory();
              setState(() => _precisionImpacts = []);
            },
          ),
        );

      case _AppScreen.seasonPass:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.home);
            return false;
          },
          child: SeasonPassScreen(
            currentXp: _currentUser?.xp ?? 0,
            claimedTiers: _claimedSeasonTiers,
            onClaimTier: (tier) async {
              await SeasonPassService.markTierClaimed(tier.tierNumber);
              final newCoins = (_currentUser?.coins ?? 0) + tier.coinsReward;
              setState(() {
                _claimedSeasonTiers = {..._claimedSeasonTiers, tier.tierNumber};
                _currentUser = _currentUser?.copyWith(coins: newCoins);
              });
              SessionService.saveCoins(newCoins);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Récompense du palier ${tier.tierNumber} réclamée !')),
              );
            },
          ),
        );

      case _AppScreen.settings:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.home);
            return false;
          },
          child: SettingsScreen(
          currentThemeMode: widget.currentThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          musicEnabled: _appSettings.musicEnabled,
          onMusicToggled: (value) {
            setState(() => _appSettings = _appSettings.copyWith(musicEnabled: value));
            SettingsService.setMusicEnabled(value);
            if (value) {
              FlameAudio.bgm.play(_appSettings.musicTrack, volume: 0.5);
            } else {
              FlameAudio.bgm.stop();
            }
          },
          selectedMusicTrack: _appSettings.musicTrack,
          availableMusicTracks: SettingsService.availableTracks,
          onMusicTrackChanged: (filename) {
            setState(() => _appSettings = _appSettings.copyWith(musicTrack: filename));
            SettingsService.setMusicTrack(filename);
            if (_appSettings.musicEnabled) {
              FlameAudio.bgm.play(filename, volume: 0.5);
            }
          },
          soundEffectsEnabled: _appSettings.soundEffectsEnabled,
          onSoundEffectsToggled: (value) {
            setState(() => _appSettings = _appSettings.copyWith(soundEffectsEnabled: value));
            SettingsService.setSoundEffectsEnabled(value);
          },
          vibrationEnabled: _appSettings.vibrationEnabled,
          onVibrationToggled: (value) {
            setState(() => _appSettings = _appSettings.copyWith(vibrationEnabled: value));
            SettingsService.setVibrationEnabled(value);
          },
          notificationsEnabled: _appSettings.notificationsEnabled,
          onNotificationsToggled: (value) {
            setState(() => _appSettings = _appSettings.copyWith(notificationsEnabled: value));
            SettingsService.setNotificationsEnabled(value);
          },
          onOpenPrivacyPolicy: () => setState(() => _currentScreen = _AppScreen.privacyPolicy),
          onOpenSupport: () => setState(() => _currentScreen = _AppScreen.support),
          onSignOut: () async {
            await _authRepository.signOut();
            await SessionService.clearSession();
            setState(() {
              _currentUser = null;
              _currentScreen = _AppScreen.login;
            });
          },
          ),
        );

      case _AppScreen.privacyPolicy:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.settings);
            return false;
          },
          child: const PrivacyPolicyScreen(),
        );

      case _AppScreen.support:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.settings);
            return false;
          },
          child: SupportScreen(
            onSubmitTicket: (subject, message) {
              // TODO(Phase 3) : envoyer réellement le ticket via Firestore/Cloud Function.
              setState(() => _currentScreen = _AppScreen.settings);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message envoyé, merci !')),
              );
            },
          ),
        );

      case _AppScreen.shop:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.home);
            return false;
          },
          child: ShopScreen(
            userCoins: _currentUser?.coins ?? 0,
            userDiamonds: _currentUser?.diamonds ?? 0,
            isPremium: _currentUser?.isPremium ?? false,
            unlockedAxeIds: _unlockedAxeIds,
            unlockedBoardIds: _unlockedBoardIds,
            onBuyAxeWithCoins: (product) async {
              final price = product.coinPrice ?? 0;
              if (_currentUser == null || _currentUser!.coins < price) return;
              final newCoins = _currentUser!.coins - price;
              await InventoryService.unlockAxe(product.id);
              final updatedIds = await InventoryService.loadUnlockedAxes();
              setState(() {
                _currentUser = _currentUser!.copyWith(coins: newCoins);
                _unlockedAxeIds = updatedIds;
              });
              SessionService.saveCoins(newCoins);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.title} débloquée !')),
              );
            },
            onBuyBoardWithCoins: (product) async {
              final price = product.coinPrice ?? 0;
              if (_currentUser == null || _currentUser!.coins < price) return;
              final newCoins = _currentUser!.coins - price;
              await InventoryService.unlockBoard(product.id);
              final updatedIds = await InventoryService.loadUnlockedBoards();
              setState(() {
                _currentUser = _currentUser!.copyWith(coins: newCoins);
                _unlockedBoardIds = updatedIds;
              });
              SessionService.saveCoins(newCoins);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.title} débloquée !')),
              );
            },
            onBuyBoardWithDiamonds: (product) async {
              final price = product.diamondPrice ?? 0;
              if (_currentUser == null || _currentUser!.diamonds < price) return;
              final newDiamonds = _currentUser!.diamonds - price;
              await InventoryService.unlockBoard(product.id);
              final updatedIds = await InventoryService.loadUnlockedBoards();
              setState(() {
                _currentUser = _currentUser!.copyWith(diamonds: newDiamonds);
                _unlockedBoardIds = updatedIds;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.title} débloquée !')),
              );
            },
            onWatchAdToUnlockBoard: (product) async {
              // NOTE : la vraie vidéo récompensée AdMob n'est pas encore
              // connectée dans cette version (voir docs/GUIDE_INSTALLATION.md,
              // section AdMob) ; on débloque directement pour l'instant afin
              // de pouvoir tester le reste du parcours boutique.
              await InventoryService.unlockBoard(product.id);
              final updatedIds = await InventoryService.loadUnlockedBoards();
              setState(() => _unlockedBoardIds = updatedIds);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.title} débloquée ! (pub non connectée dans cette version de test)')),
              );
            },
            onBuyRealMoneyProduct: (product) {
              // TODO(Phase 4) : brancher le vrai flux d'achat intégré (IapService)
              // une fois les produits configurés dans Play Console / App Store Connect.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Achats réels non configurés dans cette version de test.')),
              );
            },
            onRestorePurchases: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Aucun achat à restaurer dans cette version de test.')),
              );
            },
          ),
        );
    }
  }
}
