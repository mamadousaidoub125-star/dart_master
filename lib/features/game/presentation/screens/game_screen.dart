import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/board_zone.dart';
import '../../domain/services/scoring_service.dart';
import '../../domain/services/throw_physics.dart';
import '../widgets/dartboard_painter.dart';

/// Écran de jeu jouable : reproduit le geste naturel d'un joueur de
/// fléchettes en trois temps, comme dans la réalité :
///
/// 1. VISER   -> le joueur glisse le doigt sur la cible pour positionner
///               son réticule de visée (aimX, aimY).
/// 2. PUISSANCE -> une jauge oscille automatiquement de bas en haut ;
///               le joueur tape au bon moment pour verrouiller sa
///               puissance (mécanique "golf swing", intuitive au tactile).
/// 3. LANCER  -> un swipe vers le haut, dont la régularité de vitesse
///               est mesurée pour déterminer `gestureSteadiness`,
///               déclenche le lancer réel avec effet (spin) réglable
///               via un curseur horizontal.
class GameScreen extends StatefulWidget {
  final double aiSkillLevel; // Réutilisable aussi pour un mode entraînement calibré.

  const GameScreen({super.key, this.aiSkillLevel = 0.7});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum _ThrowPhase { aiming, poweringUp, readyToThrow, resolved }

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  Offset _aim = const Offset(0, 0); // Coordonnées normalisées (-1..1) relatives au centre.
  double _power = 0.0;
  double _spin = 0.0;
  _ThrowPhase _phase = _ThrowPhase.aiming;

  late final AnimationController _powerController;
  BoardZone? _lastResult;

  // Mesure de la régularité du swipe de lancer.
  final List<double> _swipeVelocities = [];
  DateTime? _lastSwipeTimestamp;
  Offset? _lastSwipePosition;

  @override
  void initState() {
    super.initState();
    // La jauge de puissance oscille en continu tant que le joueur ne tape pas.
    _powerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        setState(() {
          // Aller-retour 0 -> 1 -> 0 pour simuler un swing de bras.
          final t = _powerController.value;
          _power = t < 0.5 ? t * 2 : (1 - t) * 2;
        });
      });
  }

  @override
  void dispose() {
    _powerController.dispose();
    super.dispose();
  }

  void _onBoardPanUpdate(DragUpdateDetails details, Size boardSize) {
    if (_phase != _ThrowPhase.aiming) return;
    final center = Offset(boardSize.width / 2, boardSize.height / 2);
    final radius = boardSize.width / 2;
    final local = details.localPosition - center;
    setState(() {
      _aim = Offset(
        (local.dx / radius).clamp(-1.1, 1.1),
        (local.dy / radius).clamp(-1.1, 1.1),
      );
    });
  }

  void _confirmAim() {
    setState(() {
      _phase = _ThrowPhase.poweringUp;
      _powerController.repeat(reverse: false);
      _powerController.reset();
      _powerController.repeat();
    });
  }

  void _lockPower() {
    _powerController.stop();
    setState(() => _phase = _ThrowPhase.readyToThrow);
  }

  void _onThrowSwipeStart(DragStartDetails details) {
    if (_phase != _ThrowPhase.readyToThrow) return;
    _swipeVelocities.clear();
    _lastSwipeTimestamp = DateTime.now();
    _lastSwipePosition = details.localPosition;
  }

  void _onThrowSwipeUpdate(DragUpdateDetails details) {
    if (_phase != _ThrowPhase.readyToThrow) return;
    final now = DateTime.now();
    if (_lastSwipeTimestamp != null && _lastSwipePosition != null) {
      final dt = now.difference(_lastSwipeTimestamp!).inMilliseconds.clamp(1, 1000);
      final distance = (details.localPosition - _lastSwipePosition!).distance;
      _swipeVelocities.add(distance / dt);
    }
    _lastSwipeTimestamp = now;
    _lastSwipePosition = details.localPosition;
  }

  void _onThrowSwipeEnd(DragEndDetails details) {
    if (_phase != _ThrowPhase.readyToThrow) return;
    _executeThrow();
  }

  /// Calcule la régularité du geste : un swipe à vitesse constante
  /// (faible écart-type entre les échantillons de vitesse) donne une
  /// note de stabilité élevée, comme un vrai geste sportif maîtrisé.
  double _computeGestureSteadiness() {
    if (_swipeVelocities.length < 2) return 0.4; // Geste trop bref pour être noté favorablement.
    final mean = _swipeVelocities.reduce((a, b) => a + b) / _swipeVelocities.length;
    if (mean == 0) return 0.4;
    final variance = _swipeVelocities
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        _swipeVelocities.length;
    final coefficientOfVariation = math.sqrt(variance) / mean;
    // Un coefficient de variation faible (geste fluide) -> steadiness proche de 1.
    return (1 - coefficientOfVariation).clamp(0.2, 1.0);
  }

  Future<void> _executeThrow() async {
    final steadiness = _computeGestureSteadiness();

    final input = ThrowInput(
      aimX: _aim.dx,
      aimY: _aim.dy,
      power: _power,
      spin: _spin,
      gestureSteadiness: steadiness,
    );

    final result = ThrowPhysics.computeImpact(
      input: input,
      skillLevel: widget.aiSkillLevel, // TODO(phase 2): remplacer par le skill du profil joueur persistant.
    );

    final zone = ScoringService.evaluateImpact(dx: result.impactX, dy: result.impactY);

    // Retour haptique proportionnel à la qualité du lancer.
    if (await Vibration.hasVibrator() ?? false) {
      final intensity = zone.points >= 60 ? 120 : (zone.points > 0 ? 60 : 30);
      Vibration.vibrate(duration: intensity);
    }

    setState(() {
      _lastResult = zone;
      _phase = _ThrowPhase.resolved;
    });
  }

  void _resetForNextThrow() {
    setState(() {
      _phase = _ThrowPhase.aiming;
      _power = 0.0;
      _spin = 0.0;
      _lastResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Dart Master')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSize = Size.square(
                    (constraints.maxWidth < constraints.maxHeight
                            ? constraints.maxWidth
                            : constraints.maxHeight) *
                        0.85,
                  );
                  return Center(
                    child: GestureDetector(
                      onPanUpdate: (d) => _onBoardPanUpdate(d, boardSize),
                      onPanStart: _onThrowSwipeStart,
                      onPanEnd: _onThrowSwipeEnd,
                      child: SizedBox(
                        width: boardSize.width,
                        height: boardSize.height,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CustomPaint(
                              size: boardSize,
                              painter: DartboardPainter(),
                            ),
                            if (_phase == _ThrowPhase.aiming ||
                                _phase == _ThrowPhase.poweringUp ||
                                _phase == _ThrowPhase.readyToThrow)
                              Positioned(
                                left: boardSize.width / 2 +
                                    _aim.dx * boardSize.width / 2 -
                                    12,
                                top: boardSize.height / 2 +
                                    _aim.dy * boardSize.height / 2 -
                                    12,
                                child: const Icon(Icons.add, color: AppColors.gold, size: 24),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildControlPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    switch (_phase) {
      case _ThrowPhase.aiming:
        return _panelWrapper(
          child: ElevatedButton(
            onPressed: _confirmAim,
            child: const Text('Valider la visée'),
          ),
        );
      case _ThrowPhase.poweringUp:
        return _panelWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tapez au bon moment !', style: TextStyle(color: AppColors.white)),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _power,
                color: AppColors.gold,
                backgroundColor: AppColors.darkSurfaceElevated,
              ),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _lockPower, child: const Text('Verrouiller la puissance')),
            ],
          ),
        );
      case _ThrowPhase.readyToThrow:
        return _panelWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Réglez l'effet puis balayez vers le haut pour lancer",
                  style: TextStyle(color: AppColors.white), textAlign: TextAlign.center),
              Slider(
                value: _spin,
                min: -1,
                max: 1,
                activeColor: AppColors.electricBlue,
                onChanged: (v) => setState(() => _spin = v),
              ),
            ],
          ),
        );
      case _ThrowPhase.resolved:
        return _panelWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _lastResult?.label ?? '',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('${_lastResult?.points ?? 0} points',
                  style: const TextStyle(color: AppColors.white)),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _resetForNextThrow, child: const Text('Fléchette suivante')),
            ],
          ),
        );
    }
  }

  Widget _panelWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: child,
    );
  }
}
