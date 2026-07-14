import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/board_zone.dart';
import '../../domain/services/scoring_service.dart';
import '../../domain/services/throw_physics.dart';
import '../widgets/dartboard_painter.dart';
import '../widgets/viking_wall_background.dart';

/// Représente une hache déjà plantée sur la planche (visuellement),
/// conservée à l'écran jusqu'à la fin de la manche de 3 lancers, comme
/// dans un vrai jeu de fléchettes où les 3 impacts restent visibles.
class _StuckAxe {
  final Offset position; // Coordonnées normalisées (-1..1) par rapport au centre.
  final double rotation;
  const _StuckAxe(this.position, this.rotation);
}

/// Écran de jeu jouable : reproduit le geste naturel d'un guerrier viking
/// lançant sa hache en trois temps (viser, puissance, lancer). Les haches
/// plantées restent visibles sur la planche pendant toute la manche de
/// 3 lancers, puis sont retirées au début de la manche suivante.
class GameScreen extends StatefulWidget {
  final double aiSkillLevel;

  const GameScreen({super.key, this.aiSkillLevel = 0.7});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum _ThrowPhase { aiming, poweringUp, readyToThrow, throwing, resolved }

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  Offset _aim = const Offset(0, 0);
  double _power = 0.0;
  double _spin = 0.0;
  _ThrowPhase _phase = _ThrowPhase.aiming;

  late final AnimationController _powerController;
  late final AnimationController _axeFlightController;
  BoardZone? _lastResult;
  Offset _pendingImpact = const Offset(0, 0);

  // Haches déjà plantées sur la planche pendant la manche en cours (max 3).
  final List<_StuckAxe> _stuckAxes = [];
  int _roundScore = 0;

  final List<double> _swipeVelocities = [];
  DateTime? _lastSwipeTimestamp;
  Offset? _lastSwipePosition;

  @override
  void initState() {
    super.initState();
    _powerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(() {
        setState(() {
          final t = _powerController.value;
          _power = t < 0.5 ? t * 2 : (1 - t) * 2;
        });
      });

    _axeFlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          // La hache vient de se planter : on la garde visible sur la
          // planche et on passe à l'écran de résultat du lancer.
          setState(() {
            _stuckAxes.add(_StuckAxe(_pendingImpact, math.Random().nextDouble() * 0.6 - 0.3));
            _phase = _ThrowPhase.resolved;
          });
        }
      });
  }

  @override
  void dispose() {
    _powerController.dispose();
    _axeFlightController.dispose();
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

  double _computeGestureSteadiness() {
    if (_swipeVelocities.length < 2) return 0.4;
    final mean = _swipeVelocities.reduce((a, b) => a + b) / _swipeVelocities.length;
    if (mean == 0) return 0.4;
    final variance = _swipeVelocities
            .map((v) => (v - mean) * (v - mean))
            .reduce((a, b) => a + b) /
        _swipeVelocities.length;
    final coefficientOfVariation = math.sqrt(variance) / mean;
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
      skillLevel: widget.aiSkillLevel,
    );

    final zone = ScoringService.evaluateImpact(dx: result.impactX, dy: result.impactY);

    setState(() {
      _lastResult = zone;
      _roundScore += zone.points;
      _pendingImpact = Offset(result.impactX.clamp(-1.3, 1.3), result.impactY.clamp(-1.3, 1.3));
      _phase = _ThrowPhase.throwing;
    });
    _axeFlightController.forward(from: 0);
  }

  void _resetForNextThrow() {
    final isEndOfRound = _stuckAxes.length >= 3;
    setState(() {
      _phase = _ThrowPhase.aiming;
      _power = 0.0;
      _spin = 0.0;
      _lastResult = null;
      if (isEndOfRound) {
        // Fin de manche (3 haches lancées) : on retire les haches de la
        // planche et on remet le compteur à zéro pour la manche suivante,
        // exactement comme un joueur qui va récupérer ses fléchettes.
        _stuckAxes.clear();
        _roundScore = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2E1E14),
      appBar: AppBar(
        title: const Text('Dart Master — Duel Viking'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Manche : $_roundScore pts',
                style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: VikingWallBackground(
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
                          height: boardSize.height * 1.35,
                          child: Stack(
                            alignment: Alignment.topCenter,
                            children: [
                              Positioned(
                                top: 0,
                                child: CustomPaint(size: boardSize, painter: DartboardPainter()),
                              ),
                              // Haches déjà plantées, conservées visibles pendant toute la manche.
                              ..._stuckAxes.map((axe) => Positioned(
                                    left: boardSize.width / 2 + axe.position.dx * boardSize.width / 2 - 14,
                                    top: boardSize.height / 2 + axe.position.dy * boardSize.height / 2 - 14,
                                    child: Transform.rotate(
                                      angle: axe.rotation,
                                      child: const Text('🪓', style: TextStyle(fontSize: 26)),
                                    ),
                                  )),
                              if (_phase == _ThrowPhase.aiming ||
                                  _phase == _ThrowPhase.poweringUp ||
                                  _phase == _ThrowPhase.readyToThrow)
                                Positioned(
                                  left: boardSize.width / 2 + _aim.dx * boardSize.width / 2 - 14,
                                  top: boardSize.height / 2 + _aim.dy * boardSize.height / 2 - 14,
                                  child: const Text('🎯', style: TextStyle(fontSize: 22)),
                                ),
                              if (_phase == _ThrowPhase.throwing)
                                AnimatedBuilder(
                                  animation: _axeFlightController,
                                  builder: (context, _) {
                                    final t = Curves.easeIn.transform(_axeFlightController.value);
                                    final startX = boardSize.width / 2;
                                    final startY = boardSize.height * 1.25;
                                    final endX = boardSize.width / 2 + _pendingImpact.dx * boardSize.width / 2;
                                    final endY = boardSize.height / 2 + _pendingImpact.dy * boardSize.height / 2;
                                    final x = startX + (endX - startX) * t;
                                    final y = startY + (endY - startY) * t;
                                    return Positioned(
                                      left: x - 16,
                                      top: y - 16,
                                      child: Transform.rotate(
                                        angle: t * math.pi * 3,
                                        child: const Text('🪓', style: TextStyle(fontSize: 30)),
                                      ),
                                    );
                                  },
                                ),
                              Positioned(
                                bottom: 0,
                                child: Transform.rotate(
                                  angle: _aim.dx * 0.3,
                                  child: const Text('✋🏽', style: TextStyle(fontSize: 40)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Hache ${_stuckAxes.length + 1} / 3', style: const TextStyle(color: AppColors.lightGray)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: _confirmAim, child: const Text('Valider la visée')),
            ],
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
              const Text("Réglez l'effet puis balayez vers le haut pour lancer la hache",
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
      case _ThrowPhase.throwing:
        return _panelWrapper(
          child: const Text('La hache est en vol...', style: TextStyle(color: AppColors.gold)),
        );
      case _ThrowPhase.resolved:
        final isEndOfRound = _stuckAxes.length >= 3;
        return _panelWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _lastResult?.label ?? '',
                style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('${_lastResult?.points ?? 0} points', style: const TextStyle(color: AppColors.white)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _resetForNextThrow,
                child: Text(isEndOfRound ? 'Manche suivante (retirer les haches)' : 'Hache suivante'),
              ),
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
