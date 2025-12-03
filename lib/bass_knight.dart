import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'actors/player.dart';
import 'actors/minion.dart';
import 'objects/ground_block.dart';
import 'overlays/hud.dart';

class BassKnightGame extends FlameGame
    with HasCollisionDetection, HasKeyboardHandlerComponents {
  BassKnightGame();

  late Player _bassKnight;
  late double lastBlockXPosition = 0.0;
  late UniqueKey lastBlockKey;
  Timer? minionSpawnTimer;

  int starsCollected = 0;
  int health = 3;
  double cloudSpeed = 0.0;
  double objectSpeed = 0.0;

  @override
  Future<void> onLoad() async {
    debugMode = true; // Uncomment to see the bounding boxes
    await images.loadAll([
      'block.png',
      'bassknight_32x32.png',
      'ground.png',
      'heart_half.png',
      'heart.png',
      'star.png',
      'water_enemy.png',
      'minion_32x32.png',
    ]);
    camera.viewfinder.anchor = Anchor.topLeft;
    
    minionSpawnTimer = Timer(2.0, onTick: spawnMinion, repeat: true);

    initializeGame(loadHud: true);
  }

  void spawnMinion() {
    final minion = Minion();
    // Spawn off-screen to the right
    // Ground block height is 64, and minion anchor is bottomLeft.
    // So minion should sit at size.y - 64.
    minion.position = Vector2(size.x + 64, size.y - 64);
    world.add(minion);
  }

  @override
  void update(double dt) {
    if (health <= 0) {
      overlays.add('GameOver');
    }
    minionSpawnTimer?.update(dt);
    super.update(dt);
  }

  @override
  Color backgroundColor() {
    return const Color.fromARGB(255, 173, 223, 247);
  }

  void initializeGame({required bool loadHud}) {
    // Create a static floor
    final segmentsToLoad = (size.x / 64).ceil();
    for (var i = 0; i <= segmentsToLoad; i++) {
      final ground = GroundBlock(
        gridPosition: Vector2(i.toDouble(), 0),
        xOffset: 0,
      );
      world.add(ground);
    }

    _bassKnight = Player(position: Vector2(128, canvasSize.y - 128));
    world.add(_bassKnight);
    if (loadHud) {
      camera.viewport.add(Hud());
    }
    minionSpawnTimer?.start();
  }

  void reset() {
    starsCollected = 0;
    health = 3;
    // Clear existing children to reset world
    world.removeAll(world.children);
    initializeGame(loadHud: false);
  }
}
