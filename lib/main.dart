import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'app_shell.dart';

/// Point d'entrée de Dart Master.
///
/// Relie désormais le flux complet : Splash -> Connexion/Inscription ->
/// Tutoriel -> Accueil -> Choix du mode -> Jeu (voir app_shell.dart).
///
/// NOTE (Phase 3) : ajouter avant runApp() :
///   WidgetsFlutterBinding.ensureInitialized();
///   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
/// une fois `flutterfire configure` exécuté (voir docs/GUIDE_INSTALLATION.md).
void main() {
  runApp(const DartMasterApp());
}

class DartMasterApp extends StatefulWidget {
  const DartMasterApp({super.key});

  @override
  State<DartMasterApp> createState() => _DartMasterAppState();
}

class _DartMasterAppState extends State<DartMasterApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dart Master',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: AppShell(
        currentThemeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}
