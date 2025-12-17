import 'dart:ui';
import 'package:bassknight/actors/minion.dart';
import 'package:bassknight/bass_knight.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

class TestBassKnightGame extends BassKnightGame {
  @override
  Future<void> onLoad() async {
    // Mock images
    final imageNames = [
      'block.png',
      'bassknight_32x32.png',
      'grass_32x32.png',
      'heart_half.png',
      'heart.png',
      'star.png',
      'water_enemy.png',
      'minion_32x32.png',
      'bg_castle_64x64.png',
      'bg_pillar_64x64.png',
      'bg_starter_32x32.png',
    ];

    for (final name in imageNames) {
      final image = await createMockImage();
      images.add(name, image);
    }

    final variationColors = ['purple', 'yellow', 'red', 'blue', 'green'];
    for (final color in variationColors) {
      final image = await createMockImage();
      images.add('minion_$color', image);
    }

    camera.viewfinder.anchor = Anchor.topLeft;

    // Initialize game without HUD to keep it simple
    initializeGame(loadHud: false);
  }

  Future<Image> createMockImage() async {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = const Color(0xFF000000);
    canvas.drawRect(const Rect.fromLTWH(0, 0, 32, 32), paint);
    final picture = recorder.endRecording();
    return picture.toImage(32, 32);
  }
}

void main() {
  group('BassKnightGame', () {
    testWidgets('initial state is correct', (tester) async {
      final game = TestBassKnightGame();
      await tester.pumpWidget(GameWidget(game: game));
      await tester.pump(); // Wait for load cycle

      expect(game.starsCollected, 0);
      expect(game.health, 3);
      expect(game.minionSpawnInterval, 2.0);

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
