import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/board_zone.dart';
import '../../domain/services/scoring_service.dart';
import '../../domain/services/throw_physics.dart';
import '../../domain/services/ai_opponent.dart';
import '../../../game_modes/presentation/screens/game_mode_selection_screen.dart' show OpponentType;
import '../../../../core/services/throw_history_service.dart';
import '../widgets/dartboard_painter.dart';
import '../widgets/viking_wall_background.dart';

/// Une hache déjà plantée sur la planche, conservée visible pendant toute
/// la manche de 3 lancers, comme dans un vrai jeu de fléchettes.
class _StuckAxe {
  final Offset position;
  final double rotation;
  const _StuckAxe(this.position, this.rotation);
}

enum _ThrowPhase { aiming, poweringUp, readyToThrow, throwing, resolved }

/// Écran de jeu jouable, avec un véritable adversaire (IA ou 2e joueur
/// local) qui joue son tour et dont le score s'affiche en face du tien.
///
/// Visée en croix : une ligne verticale et une ligne horizontale se
/// déplacent avec le doigt, la hache part exactement sur leur point
/// d'intersection — plus précis qu'un simple réticule ponctuel.
class GameScreen extends StatefulWidget {
  final OpponentType opponentType;
  final bool vibrationEnabled;
  final bool soundEffectsEnabled;
  final int playerLevel;
  final ValueChanged<int>? onCoinsEarned;

  /// Appelé quand le joueur remporte le match, avec l'XP gagnée — permet
  /// à l'écran parent (AppShell) de faire progresser son niveau, ce qui
  /// débloque de nouvelles catégories de mur et de tête d'animal.
  final ValueChanged<int>? onMatchWonXp;

  const GameScreen({
    super.key,
    this.opponentType = OpponentType.training,
    this.vibrationEnabled = true,
    this.soundEffectsEnabled = true,
    this.playerLevel = 1,
    this.onCoinsEarned,
    this.onMatchWonXp,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  static const int _totalRounds = 3;

  Offset _aim = const Offset(0, 0);
  double _power = 0.0;
  double _spin = 0.0;
  _ThrowPhase _phase = _ThrowPhase.aiming;

  late final AnimationController _powerController;
  late final AnimationController _axeFlightController;
  late final AnimationController _burstController;
  BoardZone? _lastResult;
  Offset _pendingImpact = const Offset(0, 0);

  // --- Système de combo/série ---
  int _streakCount = 0;
  double _lastMultiplier = 1.0;
  int _lastEffectivePoints = 0;

  // --- Ralenti + effet visuel sur les gros coups (Bullseye/Triple 20) ---
  bool _isExceptionalThrow = false;
  String _exceptionalLabel = '';

  final List<_StuckAxe> _stuckAxes = [];
  int _roundScore = 0;

  final List<double> _swipeVelocities = [];
  DateTime? _lastSwipeTimestamp;
  Offset? _lastSwipePosition;

  // --- Gestion de l'adversaire (IA ou 2e joueur local) ---
  AiOpponent? _aiOpponent;
  bool get _hasOpponent =>
      widget.opponentType == OpponentType.aiEasy ||
      widget.opponentType == OpponentType.aiMedium ||
      widget.opponentType == OpponentType.aiHard ||
      widget.opponentType == OpponentType.aiExpert ||
      widget.opponentType == OpponentType.localTwoPlayer ||
      widget.opponentType == OpponentType.vikingDuel;
  bool get _isLocalSecondPlayer =>
      widget.opponentType == OpponentType.localTwoPlayer || widget.opponentType == OpponentType.vikingDuel;

  bool _isPlayerTwoTurn = false;
  int _currentRound = 1;
  int _playerTotalScore = 0;
  int _opponentTotalScore = 0;
  String? _lastOpponentMessage;

  String get _opponentLabel {
    switch (widget.opponentType) {
      case OpponentType.aiEasy:
        return 'IA Facile';
      case OpponentType.aiMedium:
        return 'IA Moyenne';
      case OpponentType.aiHard:
        return 'IA Difficile';
      case OpponentType.aiExpert:
        return 'IA Experte';
      case OpponentType.localTwoPlayer:
      case OpponentType.vikingDuel:
        return 'Joueur 2';
      default:
        return '';
    }
  }

  @override
  void initState() {
    super.initState();

    switch (widget.opponentType) {
      case OpponentType.aiEasy:
        _aiOpponent = AiOpponent(difficulty: AiDifficulty.facile);
        break;
      case OpponentType.aiMedium:
        _aiOpponent = AiOpponent(difficulty: AiDifficulty.moyenne);
        break;
      case OpponentType.aiHard:
        _aiOpponent = AiOpponent(difficulty: AiDifficulty.difficile);
        break;
      case OpponentType.aiExpert:
        _aiOpponent = AiOpponent(difficulty: AiDifficulty.experte);
        break;
      default:
        _aiOpponent = null;
    }

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
          if (widget.vibrationEnabled) {
            final points = _lastResult?.points ?? 0;
            if (points >= 45) {
              HapticFeedback.heavyImpact();
            } else if (points > 0) {
              HapticFeedback.mediumImpact();
            } else {
              HapticFeedback.lightImpact();
            }
          }
          if (widget.soundEffectsEnabled) {
            FlameAudio.play('sfx_axe_hit.wav', volume: 0.7);
          }
          setState(() {
            _stuckAxes.add(_StuckAxe(_pendingImpact, math.Random().nextDouble() * 0.6 - 0.3));
            _phase = _ThrowPhase.resolved;
          });
          if (_isExceptionalThrow) {
            _burstController.forward(from: 0);
          }
        }
      });

    _burstController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _burstController.reset();
        }
      });
  }

  @override
  void dispose() {
    _powerController.dispose();
    _axeFlightController.dispose();
    _burstController.dispose();
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

    // Un joueur humain (Joueur 1 ou Joueur 2 local) a toujours le même
    // niveau de compétence de base ; seule l'IA a un skillLevel variable.
    final result = ThrowPhysics.computeImpact(input: input, skillLevel: 0.75);
    final zone = ScoringService.evaluateImpact(dx: result.impactX, dy: result.impactY);

    // Système de combo : chaque lancer touché d'affilée augmente un
    // multiplicateur de score (jusqu'à x1.75 pour 5 touches consécutives).
    // Un lancer manqué (0 point) remet le compteur à zéro.
    if (zone.points > 0) {
      _streakCount++;
    } else {
      _streakCount = 0;
    }
    final multiplier = 1.0 + 0.15 * math.min(_streakCount, 5);
    final effectivePoints = (zone.points * multiplier).round();

    // Coup exceptionnel (Bullseye ou Triple 20) : déclenche un ralenti
    // dramatique du vol de la hache et un effet de lueur dorée à l'impact.
    final isExceptional = zone.isDoubleBull || (zone.multiplier == 3 && zone.score == 20);

    setState(() {
      _lastResult = zone;
      _lastMultiplier = multiplier;
      _lastEffectivePoints = effectivePoints;
      _isExceptionalThrow = isExceptional;
      _exceptionalLabel = zone.isDoubleBull ? 'BULLSEYE !' : 'TRIPLE 20 !';
      _roundScore += effectivePoints;
      _pendingImpact = Offset(result.impactX.clamp(-1.3, 1.3), result.impactY.clamp(-1.3, 1.3));
      _phase = _ThrowPhase.throwing;
    });
    // Enregistrement pour la carte de précision (n'affecte pas le jeu en
    // cours, purement pour les statistiques du profil).
    ThrowHistoryService.recordImpact(_pendingImpact.dx, _pendingImpact.dy);
    _axeFlightController.duration =
        isExceptional ? const Duration(milliseconds: 950) : const Duration(milliseconds: 420);
    _axeFlightController.forward(from: 0);
  }

  void _resetForNextThrow() {
    final isEndOfRound = _stuckAxes.length >= 3;

    if (!isEndOfRound) {
      setState(() {
        _phase = _ThrowPhase.aiming;
        _power = 0.0;
        _spin = 0.0;
        _lastResult = null;
      });
      return;
    }

    // Fin de manche de 3 haches pour le joueur actif.
    if (!_hasOpponent) {
      // Mode entraînement : pas d'adversaire, on récompense et on continue.
      final coinsEarned = math.max(5, (_roundScore / 2).round());
      widget.onCoinsEarned?.call(coinsEarned);
      setState(() {
        _phase = _ThrowPhase.aiming;
        _power = 0.0;
        _spin = 0.0;
        _lastResult = null;
        _stuckAxes.clear();
        _roundScore = 0;
      });
      return;
    }

    if (_isLocalSecondPlayer && !_isPlayerTwoTurn) {
      // Le Joueur 1 vient de finir sa manche : on passe au Joueur 2.
      setState(() {
        _playerTotalScore += _roundScore;
        _isPlayerTwoTurn = true;
        _stuckAxes.clear();
        _roundScore = 0;
        _phase = _ThrowPhase.aiming;
        _power = 0.0;
        _spin = 0.0;
        _lastResult = null;
        _lastOpponentMessage = null;
      });
      return;
    }

    if (_isLocalSecondPlayer && _isPlayerTwoTurn) {
      // Le Joueur 2 vient de finir : fin de la manche complète.
      final coinsEarned = math.max(5, ((_playerTotalScore) / 2).round());
      setState(() {
        _opponentTotalScore += _roundScore;
        widget.onCoinsEarned?.call(coinsEarned);
        _advanceRoundOrFinish();
      });
      return;
    }

    // Adversaire IA : le joueur vient de finir sa manche, l'IA joue
    // immédiatement ses 3 haches (calculées par le vrai moteur AiOpponent).
    final ai = _aiOpponent!;
    int aiRoundScore = 0;
    for (int i = 0; i < 3; i++) {
      final zone = ai.performThrow(remainingScore: 999); // Toujours en mode "score max", pas de checkout.
      aiRoundScore += zone.points;
    }

    final coinsEarned = math.max(5, (_roundScore / 2).round());
    widget.onCoinsEarned?.call(coinsEarned);

    setState(() {
      _playerTotalScore += _roundScore;
      _opponentTotalScore += aiRoundScore;
      _lastOpponentMessage = "$_opponentLabel a marqué $aiRoundScore points sur cette manche !";
      _stuckAxes.clear();
      _roundScore = 0;
      _advanceRoundOrFinish();
    });
  }

  void _advanceRoundOrFinish() {
    if (_currentRound >= _totalRounds) {
      _showMatchResultDialog();
    } else {
      _currentRound += 1;
      _isPlayerTwoTurn = false;
      _phase = _ThrowPhase.aiming;
      _power = 0.0;
      _spin = 0.0;
      _lastResult = null;
    }
  }

  void _showMatchResultDialog() {
    final playerWins = _playerTotalScore >= _opponentTotalScore;
    if (playerWins) {
      // XP gagnée en cas de victoire : fait progresser le niveau du
      // joueur, ce qui débloque de nouvelles catégories de mur et de
      // tête d'animal (voir VikingWallBackground).
      widget.onMatchWonXp?.call(100);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.darkSurface,
          title: Text(
            playerWins ? '🏆 Victoire !' : 'Défaite',
            style: TextStyle(color: playerWins ? AppColors.gold : AppColors.red),
          ),
          content: Text(
            'Toi : $_playerTotalScore points\n$_opponentLabel : $_opponentTotalScore points',
            style: const TextStyle(color: AppColors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _currentRound = 1;
                  _playerTotalScore = 0;
                  _opponentTotalScore = 0;
                  _isPlayerTwoTurn = false;
                  _stuckAxes.clear();
                  _roundScore = 0;
                  _streakCount = 0;
                  _phase = _ThrowPhase.aiming;
                  _lastOpponentMessage = null;
                });
              },
              child: const Text('Rejouer'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePlayerLabel = _isLocalSecondPlayer && _isPlayerTwoTurn ? 'Joueur 2' : 'Toi';

    return Scaffold(
      backgroundColor: const Color(0xFF2E1E14),
      appBar: AppBar(
        title: Text(_hasOpponent ? 'Manche $_currentRound / $_totalRounds' : 'Dart Master'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_hasOpponent) _buildScoreHeader(activePlayerLabel),
            if (_lastOpponentMessage != null)
              Container(
                width: double.infinity,
                color: AppColors.darkSurfaceElevated,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _lastOpponentMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.gold, fontSize: 13),
                ),
              ),
            Expanded(
              child: VikingWallBackground(
                levelTier: _wallTierForLevel(widget.playerLevel),
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
                                _buildCrosshair(boardSize),
                              if (_phase == _ThrowPhase.throwing)
                                AnimatedBuilder(
                                  animation: _axeFlightController,
                                  builder: (context, _) {
                                    final curve = _isExceptionalThrow ? Curves.easeOutQuart : Curves.easeIn;
                                    final t = curve.transform(_axeFlightController.value);
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
                              if (_isExceptionalThrow) _buildExceptionalBurst(boardSize),
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

  /// Effet visuel déclenché sur un coup exceptionnel (Bullseye/Triple 20) :
  /// un anneau doré qui s'agrandit en s'estompant, avec un texte qui
  /// remonte légèrement, pour souligner le lancer comme dans un vrai jeu AAA.
  Widget _buildExceptionalBurst(Size boardSize) {
    return AnimatedBuilder(
      animation: _burstController,
      builder: (context, _) {
        if (_burstController.value <= 0) return const SizedBox.shrink();
        final t = _burstController.value;
        final scale = 0.5 + t * 1.8;
        final opacity = (1 - t).clamp(0.0, 1.0);
        final ix = boardSize.width / 2 + _pendingImpact.dx * boardSize.width / 2;
        final iy = boardSize.height / 2 + _pendingImpact.dy * boardSize.height / 2;
        return Stack(
          children: [
            Positioned(
              left: ix - 60,
              top: iy - 60,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 4),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: ix - 70,
              top: iy - 50 - (t * 30),
              child: Opacity(
                opacity: opacity,
                child: SizedBox(
                  width: 140,
                  child: Text(
                    _exceptionalLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Réticule en croix : une ligne verticale et une ligne horizontale se
  /// déplacent avec le doigt, la hache part exactement sur leur intersection.
  Widget _buildCrosshair(Size boardSize) {
    final ix = boardSize.width / 2 + _aim.dx * boardSize.width / 2;
    final iy = boardSize.height / 2 + _aim.dy * boardSize.height / 2;
    return Stack(
      children: [
        // Ligne verticale.
        Positioned(
          left: ix - 1,
          top: 0,
          child: Container(width: 2, height: boardSize.height, color: AppColors.gold.withOpacity(0.65)),
        ),
        // Ligne horizontale.
        Positioned(
          left: 0,
          top: iy - 1,
          child: Container(width: boardSize.width, height: 2, color: AppColors.gold.withOpacity(0.65)),
        ),
        // Point d'intersection mis en évidence.
        Positioned(
          left: ix - 9,
          top: iy - 9,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.gold, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreHeader(String activePlayerLabel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: AppColors.darkSurface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildScoreBadge('Toi', _playerTotalScore, isActive: activePlayerLabel == 'Toi'),
          const Text('VS', style: TextStyle(color: AppColors.lightGray, fontWeight: FontWeight.w700)),
          _buildScoreBadge(_opponentLabel, _opponentTotalScore, isActive: activePlayerLabel != 'Toi'),
        ],
      ),
    );
  }

  Widget _buildScoreBadge(String label, int score, {required bool isActive}) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
              color: isActive ? AppColors.gold : AppColors.lightGray,
              fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
              fontSize: 13,
            )),
        Text('$score', style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
      ],
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
        final coinsPreview = math.max(5, (_roundScore / 2).round());
        return _panelWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _lastResult?.label ?? '',
                style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text('${_lastResult?.points ?? 0} points', style: const TextStyle(color: AppColors.white)),
              if (_streakCount >= 2) ...[
                const SizedBox(height: 4),
                Text(
                  '🔥 Série de $_streakCount ! x${_lastMultiplier.toStringAsFixed(2)} → $_lastEffectivePoints points',
                  style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ],
              if (isEndOfRound && !_hasOpponent) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.monetization_on, color: AppColors.gold, size: 18),
                    const SizedBox(width: 4),
                    Text('+$coinsPreview pièces gagnées', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _resetForNextThrow,
                child: Text(isEndOfRound ? 'Manche suivante' : 'Hache suivante'),
              ),
            ],
          ),
        );
    }
  }

  /// Détermine le palier de décor (mur + tête d'animal) selon le niveau
  /// du joueur : plus il gagne de parties, plus le décor devient
  /// impressionnant, comme une vraie progression de statut de guerrier.
  int _wallTierForLevel(int level) {
    if (level >= 5) return 2; // Mur de fer sombre + tête de dragon
    if (level >= 3) return 1; // Mur de pierre + tête de loup
    return 0; // Mur de bois + tête de taureau (décor de départ)
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
