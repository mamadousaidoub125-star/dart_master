import 'package:flutter/material.dart';
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

enum _AppScreen { splash, login, signUp, tutorial, home, modeSelection, game, profile, settings }

class _AppShellState extends State<AppShell> {
  // TODO(Phase 3) : remplacer par FirebaseAuthRepository une fois
  // `flutterfire configure` exécuté (voir docs/GUIDE_INSTALLATION.md).
  final _authRepository = MockAuthRepository();

  _AppScreen _currentScreen = _AppScreen.splash;
  AppUser? _currentUser;
  GameVariant? _selectedVariant;
  OpponentType? _selectedOpponent;

  Future<void> _initializeApp() async {
    // Emplacement prévu pour les initialisations Phase 3 :
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  void _handleAuthSuccess(AppUser user) {
    setState(() {
      _currentUser = user;
      _currentScreen = _AppScreen.tutorial; // TODO: sauter le tutoriel si déjà vu (à stocker via shared_preferences).
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentScreen) {
      case _AppScreen.splash:
        return SplashScreen(
          initialize: _initializeApp,
          onInitializationComplete: () => setState(() => _currentScreen = _AppScreen.login),
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
          // TODO(Phase 4/5) : brancher ces callbacks sur ShopScreen, LeaderboardScreen,
          // FriendsScreen, DailyRewardScreen, MissionsScreen une fois les repositories
          // de données réelles connectés à Firestore.
          onShopPressed: () {},
          onLeaderboardPressed: () {},
          onFriendsPressed: () {},
          onDailyRewardPressed: () {},
          onMissionsPressed: () {},
        );

      case _AppScreen.modeSelection:
        return GameModeSelectionScreen(
          onModeConfirmed: (variant, opponent) {
            setState(() {
              _selectedVariant = variant;
              _selectedOpponent = opponent;
              _currentScreen = _AppScreen.game;
            });
          },
        );

      case _AppScreen.game:
        return GameScreen(aiSkillLevel: _skillLevelForOpponent(_selectedOpponent));

      case _AppScreen.profile:
        return ProfileScreen(user: _currentUser!);

      case _AppScreen.settings:
        return SettingsScreen(
          currentThemeMode: widget.currentThemeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          musicEnabled: true,
          onMusicToggled: (_) {},
          soundEffectsEnabled: true,
          onSoundEffectsToggled: (_) {},
          vibrationEnabled: true,
          onVibrationToggled: (_) {},
          notificationsEnabled: true,
          onNotificationsToggled: (_) {},
          onOpenPrivacyPolicy: () {},
          onOpenSupport: () {},
          onSignOut: () async {
            await _authRepository.signOut();
            setState(() {
              _currentUser = null;
              _currentScreen = _AppScreen.login;
            });
          },
        );
    }
  }

  /// Traduit le type d'adversaire choisi en niveau de compétence pour
  /// [GameScreen]. En Phase 2+, ce niveau pilotera directement une
  /// instance d'[AiOpponent] plutôt qu'un simple double.
  double _skillLevelForOpponent(OpponentType? opponent) {
    switch (opponent) {
      case OpponentType.aiEasy:
        return 0.35;
      case OpponentType.aiMedium:
        return 0.58;
      case OpponentType.aiHard:
        return 0.78;
      case OpponentType.aiExpert:
        return 0.94;
      default:
        return 0.7;
    }
  }
}
