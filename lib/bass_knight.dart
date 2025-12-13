import 'dart:math';
import 'package:bassknight/textures/minion.dart';
import 'package:bassknight/utils/bmp.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'actors/player.dart';
import 'actors/minion.dart';
import 'objects/ground_block.dart';
import 'objects/background.dart';
import 'overlays/hud.dart';

class BassKnightGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  BassKnightGame();

  late Player _bassKnight;
  late double lastBlockXPosition = 0.0;
  late UniqueKey lastBlockKey;
  bool hasGameStarted = false;
  double minionSpawnInterval = 2.0; // Initial interval
  double _timeSinceLastMinionSpawn = 0.0;

  int starsCollected = 0;
  int health = 3;
  double cloudSpeed = 0.0;
  double objectSpeed = 0.0;
  double _elapsedTime = 0.0;

  @override
  Future<void> onLoad() async {
    // Generate a 32x32 BMP image manually
    final bmp = BMP(32, 32);
    generateGradient(bmp);
    final bmpBytes = bmp.image;
    final flutterImage = await decodeImageFromList(bmpBytes);

    loadMinionTextureAndPrintPalette();

    images.add('image.png', flutterImage);

    // debugMode = true; // Uncomment to see the bounding boxes
    await images.loadAll([
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
    ]);
    camera.viewfinder.anchor = Anchor.topLeft;

    initializeGame(loadHud: true);
  }

  void spawnMinion() {
    final minion = Minion();
    final random = Random();
    final minMinionY = size.y - 256; // Top of the grass
    final maxMinionY = size.y; // Bottom of the screen (bottom of the grass)
    final randomY =
        minMinionY + random.nextDouble() * (maxMinionY - minMinionY);
    minion.position = Vector2(size.x + 64, randomY);
    world.add(minion);
  }

  @override
  void update(double dt) {
    if (health <= 0) {
      overlays.add('GameOver');
    }
    _elapsedTime += dt;
    _timeSinceLastMinionSpawn += dt;
    _calculateAndSetMinionSpawnInterval();
    _trySpawnMinion();
    super.update(dt);
  }

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 173, 223, 247);
  }

  void initializeGame({required bool loadHud}) {
    world.add(Background());

    // Create a static floor
    double groundScale = 1.0;
    if (size.y * 0.5 < 256) {
      groundScale = (size.y * 0.5) / 256;
    }

    final segmentsToLoad = (size.x / (64 * groundScale)).ceil();
    for (var i = 0; i <= segmentsToLoad; i++) {
      final ground = GroundBlock(
        gridPosition: Vector2(i.toDouble(), 0),
        xOffset: 0,
        heightScale: groundScale,
      );
      world.add(ground);
    }

    _bassKnight = Player(position: Vector2(128, canvasSize.y - 128));
    world.add(_bassKnight);
    if (loadHud) {
      camera.viewport.add(Hud());
    }
  }

  void startGame() {
    overlays.remove('MainMenu');
  }

  void reset() {
    starsCollected = 0;
    health = 3;
    _elapsedTime = 0.0;
    _timeSinceLastMinionSpawn = 0.0;
    // Clear existing children to reset world
    world.removeAll(world.children);
    initializeGame(loadHud: false);
  }

  void _calculateAndSetMinionSpawnInterval() {
    const double initialInterval = 2.0; // 2 seconds
    const double finalInterval = 0.5; // 1 second (double the rate)
    const double rampUpStartTime = 30.0; // After 1 minute
    const double rampUpEndTime = 120.0; // Levels out after 2 minutes

    double newInterval = initialInterval;

    if (_elapsedTime >= rampUpEndTime) {
      newInterval = finalInterval;
    } else if (_elapsedTime >= rampUpStartTime) {
      final double progress =
          (_elapsedTime - rampUpStartTime) / (rampUpEndTime - rampUpStartTime);
      newInterval =
          initialInterval * (1.0 - progress) + finalInterval * progress;
    }
    minionSpawnInterval = newInterval;

    // // Debug print every second
    // if ((_elapsedTime * 10).toInt() % 10 == 0) {
    //   // Prints roughly once per second
    //   print(
    //     'Elapsed Time: ${_elapsedTime.toStringAsFixed(1)}s, Minion Spawn Interval: ${minionSpawnInterval.toStringAsFixed(2)}s',
    //   );
    // }
  }

  void _trySpawnMinion() {
    if (_timeSinceLastMinionSpawn >= minionSpawnInterval) {
      spawnMinion();
      _timeSinceLastMinionSpawn -=
          minionSpawnInterval; // Subtract, don't reset to 0 to handle frame skips
    }
  }
}
