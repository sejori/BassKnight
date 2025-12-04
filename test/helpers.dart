import 'dart:ui';

import 'package:bassknight/bass_knight.dart';
import 'package:bassknight/actors/minion.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

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
    ];
    
    for (final name in imageNames) {
      final image = await createMockImage();
      images.add(name, image);
    }

    camera.viewfinder.anchor = Anchor.topLeft;
    minionSpawnTimer = Timer(2.0, onTick: spawnMinion, repeat: true, autoStart: false);
    
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
