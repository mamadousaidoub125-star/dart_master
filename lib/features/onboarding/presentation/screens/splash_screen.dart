import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Écran de démarrage affiché brièvement au lancement de l'application.
///
/// Anime le logo et le nom du jeu (fondu + léger zoom) pendant que
/// l'application effectue ses initialisations en arrière-plan
/// (Firebase, chargement des préférences locales, vérification de
/// session). Une fois [_minimumDisplayDuration] écoulée ET les
/// initialisations terminées, [onInitializationComplete] est appelé
/// pour naviguer vers l'écran suivant (connexion ou accueil).
class SplashScreen extends StatefulWidget {
  final Future<void> Function() initialize;
  final VoidCallback onInitializationComplete;

  const SplashScreen({
    super.key,
    required this.initialize,
    required this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  static const _minimumDisplayDuration = Duration(milliseconds: 1800);
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final stopwatch = Stopwatch()..start();
    try {
      await widget.initialize();
    } catch (e) {
      // En cas d'échec d'initialisation (ex: pas de réseau pour Firebase),
      // on laisse tout de même l'utilisateur accéder à l'app en mode
      // dégradé plutôt que de le bloquer indéfiniment sur le splash.
      debugPrint('Erreur d\'initialisation au démarrage : $e');
    }
    final elapsed = stopwatch.elapsed;
    final remaining = _minimumDisplayDuration - elapsed;
    if (remaining > Duration.zero) {
      await Future.delayed(remaining);
    }
    if (mounted) widget.onInitializationComplete();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.adjust, color: AppColors.midnightBlue, size: 52),
                ),
                const SizedBox(height: 24),
                const Text(
                  'DART MASTER',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(AppColors.gold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
