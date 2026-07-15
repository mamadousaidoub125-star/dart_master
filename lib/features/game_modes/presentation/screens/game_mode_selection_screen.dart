import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../game/domain/services/game_rules_factory.dart';

/// Écran de sélection du mode de jeu.
///
/// Regroupe à la fois les variantes de règles (301/501/Cricket/etc.)
/// et le type d'adversaire (entraînement, IA à 4 niveaux, local 2 joueurs,
/// multijoueur, tournoi, défi quotidien). Les deux choix combinés
/// déterminent la configuration exacte transmise à [GameScreen].
enum OpponentType { training, aiEasy, aiMedium, aiHard, aiExpert, localTwoPlayer, vikingDuel, onlinePrivate, onlinePublic, tournament, dailyChallenge }

class GameModeSelectionScreen extends StatefulWidget {
  final void Function(GameVariant variant, OpponentType opponent) onModeConfirmed;

  const GameModeSelectionScreen({super.key, required this.onModeConfirmed});

  @override
  State<GameModeSelectionScreen> createState() => _GameModeSelectionScreenState();
}

class _GameModeSelectionScreenState extends State<GameModeSelectionScreen> {
  GameVariant _selectedVariant = GameVariant.fiveOhOne;
  OpponentType _selectedOpponent = OpponentType.aiMedium;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightBlue,
      appBar: AppBar(title: const Text('Choisir un mode de jeu')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Règles', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: GameVariant.values.map((variant) {
              final isSelected = variant == _selectedVariant;
              return ChoiceChip(
                label: Text(GameRulesFactory.displayName(variant)),
                selected: isSelected,
                selectedColor: AppColors.electricBlue,
                backgroundColor: AppColors.darkSurface,
                labelStyle: TextStyle(color: isSelected ? AppColors.white : AppColors.lightGray),
                onSelected: (_) => setState(() => _selectedVariant = variant),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            GameRulesFactory.description(_selectedVariant),
            style: const TextStyle(color: AppColors.lightGray, fontSize: 13),
          ),
          const SizedBox(height: 28),
          const Text('Adversaire', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ..._buildOpponentTiles(),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => widget.onModeConfirmed(_selectedVariant, _selectedOpponent),
            child: const Text('Commencer la partie'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOpponentTiles() {
    final entries = <(OpponentType, String, IconData)>[
      (OpponentType.training, 'Entraînement libre', Icons.fitness_center),
      (OpponentType.aiEasy, 'IA — Facile', Icons.smart_toy),
      (OpponentType.aiMedium, 'IA — Moyenne', Icons.smart_toy),
      (OpponentType.aiHard, 'IA — Difficile', Icons.smart_toy),
      (OpponentType.aiExpert, 'IA — Experte', Icons.smart_toy),
      (OpponentType.localTwoPlayer, 'Deux joueurs (même téléphone)', Icons.people),
      (OpponentType.vikingDuel, '⚔️ Duel Viking (lancers simultanés)', Icons.bolt),
      (OpponentType.onlinePrivate, 'Multijoueur privé', Icons.lock),
      (OpponentType.onlinePublic, 'Multijoueur public', Icons.public),
      (OpponentType.tournament, 'Tournoi', Icons.emoji_events),
      (OpponentType.dailyChallenge, 'Défi quotidien', Icons.calendar_today),
    ];

    return entries.map((entry) {
      final (type, label, icon) = entry;
      final isSelected = type == _selectedOpponent;
      return Card(
        color: isSelected ? AppColors.electricBlue.withOpacity(0.25) : AppColors.darkSurface,
        child: ListTile(
          leading: Icon(icon, color: isSelected ? AppColors.electricBlue : AppColors.lightGray),
          title: Text(label, style: const TextStyle(color: AppColors.white)),
          trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.electricBlue) : null,
          onTap: () => setState(() => _selectedOpponent = type),
        ),
      );
    }).toList();
  }
}
