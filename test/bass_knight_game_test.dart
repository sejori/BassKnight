import 'package:bassknight/actors/minion.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('BassKnightGame', () {
    testWidgets('initial state is correct', (tester) async {
      final game = TestBassKnightGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump(); // Wait for load cycle

      print('Verify: timer is ${game.minionSpawnTimer}');

      expect(game.starsCollected, 0);
      expect(game.health, 3);
      expect(game.minionSpawnTimer, isNotNull);
      
      // pump to process additions
      await tester.pump(const Duration(milliseconds: 10));
      expect(game.world.children.length, greaterThan(0));
    });

    testWidgets('spawnMinion adds a minion', (tester) async {
      final game = TestBassKnightGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      final initialCount = game.world.children.length;
      game.spawnMinion();
      
      await tester.pump(const Duration(milliseconds: 100));
      
      expect(game.world.children.length, greaterThan(initialCount));
      expect(game.world.children.whereType<Minion>().length, 1);
    });

    testWidgets('reset restores health and stars', (tester) async {
      final game = TestBassKnightGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      game.health = 1;
      game.starsCollected = 10;
      
      game.reset();
      await tester.pump(const Duration(milliseconds: 100));

      expect(game.health, 3);
      expect(game.starsCollected, 0);
    });
  });
}
