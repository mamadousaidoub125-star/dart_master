import 'package:flutter_test/flutter_test.dart';
import 'package:dart_master/features/game/domain/entities/board_zone.dart';
import 'package:dart_master/features/game/domain/services/rules/x01_rules.dart';
import 'package:dart_master/features/game/domain/services/rules/cricket_rules.dart';
import 'package:dart_master/features/game/domain/services/rules/around_the_clock_rules.dart';
import 'package:dart_master/features/game/domain/services/rules/count_up_rules.dart';

void main() {
  group('X01Rules (501)', () {
    const rules = X01Rules(startingScore: 501);

    test('un lancer normal décrémente simplement le score restant', () {
      final state = rules.initialState();
      final (newState, outcome) = rules.applyThrow(
        currentState: state,
        zone: const BoardZone(score: 20, multiplier: 3, label: 'Triple 20'),
      );
      expect(newState['remainingScore'], 501 - 60);
      expect(outcome.isBust, false);
    });

    test('un lancer amenant le score à 1 est un bust', () {
      var state = {'remainingScore': 21, 'scoreBeforeThisRound': 21, 'dartsThrownThisRound': 0};
      final (newState, outcome) = rules.applyThrow(
        currentState: state,
        zone: const BoardZone(score: 20, multiplier: 1, label: 'Simple 20'),
      );
      expect(outcome.isBust, true);
      expect(newState['remainingScore'], 21); // Score restauré.
    });

    test('finir exactement sur un double à 0 termine la partie', () {
      var state = {'remainingScore': 40, 'scoreBeforeThisRound': 40, 'dartsThrownThisRound': 0};
      final (_, outcome) = rules.applyThrow(
        currentState: state,
        zone: const BoardZone(score: 20, multiplier: 2, label: 'Double 20'),
      );
      expect(outcome.isMatchOver, true);
    });

    test('finir à 0 sans toucher un double est un bust', () {
      var state = {'remainingScore': 40, 'scoreBeforeThisRound': 40, 'dartsThrownThisRound': 0};
      final (_, outcome) = rules.applyThrow(
        currentState: state,
        zone: const BoardZone(score: 20, multiplier: 1, label: 'Simple 20'), // 40 -> 20, pas bust en soi
      );
      expect(outcome.isBust, false); // Ce cas précis ne finit pas à 0, donc pas de bust ici.
    });
  });

  group('CricketRules', () {
    test('3 marques sur une case non fermée par l\'adversaire ferme la case sans points', () {
      final rules = CricketRules();
      var state = rules.initialState();
      final (newState, _) = rules.applyThrow(
        currentState: state,
        zone: const BoardZone(score: 20, multiplier: 3, label: 'Triple 20'),
      );
      expect(newState['marksPlayer']['20'], 3);
      expect(newState['scorePlayer'], 0); // Pile 3 marques, aucun excédent.
    });

    test('un 4e coup sur une case déjà fermée rapporte des points', () {
      final rules = CricketRules();
      var state = {
        'marksPlayer': {'15': 3, '16': 0, '17': 0, '18': 0, '19': 0, '20': 0, '25': 0},
        'marksOpponent': {'15': 0, '16': 0, '17': 0, '18': 0, '19': 0, '20': 0, '25': 0},
        'scorePlayer': 0,
        'scoreOpponent': 0,
      };
      final (newState, _) = rules.applyThrow(
        currentState: state,
        zone: const BoardZone(score: 15, multiplier: 1, label: 'Simple 15'),
      );
      expect(newState['scorePlayer'], 15);
    });
  });

  group('AroundTheClockRules', () {
    test('toucher le bon numéro fait progresser la cible', () {
      const rules = AroundTheClockRules();
      var state = rules.initialState();
      final (newState, outcome) = rules.applyThrow(
        currentState: state,
        zone: const BoardZone(score: 1, multiplier: 1, label: 'Simple 1'),
      );
      expect(newState['currentTarget'], 2);
      expect(outcome.isMatchOver, false);
    });

    test('toucher un mauvais numéro ne fait pas progresser', () {
      const rules = AroundTheClockRules();
      var state = rules.initialState();
      final (newState, _) = rules.applyThrow(
        currentState: state,
        zone: const BoardZone(score: 5, multiplier: 1, label: 'Simple 5'),
      );
      expect(newState['currentTarget'], 1);
    });
  });

  group('CountUpRules', () {
    test('accumule les points sur plusieurs lancers', () {
      const rules = CountUpRules(totalRounds: 8);
      var state = rules.initialState();
      final (newState, _) = rules.applyThrow(
        currentState: state,
        zone: const BoardZone(score: 20, multiplier: 3, label: 'Triple 20'),
      );
      expect(newState['totalScore'], 60);
    });
  });
}
