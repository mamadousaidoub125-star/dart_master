import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Tutoriel affiché à la première connexion, expliquant le geste de
/// visée/puissance/effet/lancer avant d'envoyer le joueur en partie réelle.
class TutorialScreen extends StatefulWidget {
  final VoidCallback onFinished;
  const TutorialScreen({super.key, required this.onFinished});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialStep {
  final IconData icon;
  final String title;
  final String description;
  const _TutorialStep({required this.icon, required this.title, required this.description});
}

class _TutorialScreenState extends State<TutorialScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _steps = [
    _TutorialStep(
      icon: Icons.gps_fixed,
      title: 'Visez',
      description: 'Glissez votre doigt sur la cible pour positionner votre réticule à l\'endroit exact où vous voulez toucher.',
    ),
    _TutorialStep(
      icon: Icons.speed,
      title: 'Réglez la puissance',
      description: 'Une jauge oscille automatiquement. Tapez au bon moment pour verrouiller une puissance proche du maximum.',
    ),
    _TutorialStep(
      icon: Icons.rotate_right,
      title: "Ajustez l'effet",
      description: 'Utilisez le curseur pour donner de l\'effet à votre fléchette et compenser les petites imprécisions.',
    ),
    _TutorialStep(
      icon: Icons.swipe_up,
      title: 'Lancez',
      description: 'Balayez l\'écran vers le haut d\'un geste fluide et régulier : plus votre swipe est stable, plus votre lancer est précis !',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: widget.onFinished,
                child: const Text('Passer', style: TextStyle(color: AppColors.lightGray)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: const BoxDecoration(color: AppColors.darkSurface, shape: BoxShape.circle),
                          child: Icon(step.icon, size: 56, color: AppColors.gold),
                        ),
                        const SizedBox(height: 32),
                        Text(step.title,
                            style: const TextStyle(color: AppColors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 16),
                        Text(step.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.lightGray, fontSize: 15, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _currentPage ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _currentPage ? AppColors.gold : AppColors.darkSurfaceElevated,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _steps.length - 1) {
                      widget.onFinished();
                    } else {
                      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                    }
                  },
                  child: Text(_currentPage == _steps.length - 1 ? 'Commencer à jouer' : 'Suivant'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
