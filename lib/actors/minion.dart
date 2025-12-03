import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

import '../bass_knight.dart';

class Minion extends SpriteAnimationComponent
    with HasGameReference<BassKnightGame> {
  final Vector2 velocity = Vector2.zero();

  Minion() : super(size: Vector2.all(64), anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('minion_32x32.png'),
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: Vector2.all(32),
        stepTime: 0.7,
      ),
    );
    add(RectangleHitbox(collisionType: CollisionType.passive));
  }

  @override
  void update(double dt) {
    velocity.x = -150;
    position += velocity * dt;
    if (position.x < -size.x || game.health <= 0) {
      removeFromParent();
    }
    super.update(dt);
  }
}
