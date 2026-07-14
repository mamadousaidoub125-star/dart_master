import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';
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

enum _AppScreen { splash, login, signUp, tutorial, home, modeSelection, game, profile, settings, privacyPolicy, support }

class _AppShellState extends State<AppShell> {
  // TODO(Phase 3) : remplacer par FirebaseAuthRepository une fois
  // `flutterfire configure` exécuté (voir docs/GUIDE_INSTALLATION.md).
  final _authRepository = MockAuthRepository();

  _AppScreen _currentScreen = _AppScreen.splash;
  AppUser? _currentUser;
  GameVariant? _selectedVariant;
  OpponentType? _selectedOpponent;

  bool _hasRestoredSession = false;
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
      _currentUser = AppUser(
        id: savedSession['userId']!,
        displayName: savedSession['displayName']!,
        email: savedSession['email']!,
      );
      _hasRestoredSession = true;
    }

    // Charge les préférences audio/notifications sauvegardées localement.
    _appSettings = await SettingsService.loadSettings();

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
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.home);
            return false;
          },
          child: GameModeSelectionScreen(
            onModeConfirmed: (variant, opponent) {
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
          child: GameScreen(aiSkillLevel: _skillLevelForOpponent(_selectedOpponent)),
        );

      case _AppScreen.profile:
        return WillPopScope(
          onWillPop: () async {
            setState(() => _currentScreen = _AppScreen.home);
            return false;
          },
          child: ProfileScreen(user: _currentUser!),
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
