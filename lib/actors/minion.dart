import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../bass_knight.dart';
import '../mixins/z_aware.dart';

class Minion extends SpriteAnimationComponent
    with HasGameReference<BassKnightGame>, ZAware {
  final Vector2 velocity = Vector2.zero();

  bool hasDamagedPlayer = false;

  Minion() : super(size: Vector2.all(64), anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('minion'),
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
    velocity.x = -300;
    position += velocity * dt;
    if (position.x < -size.x) {
      if (!hasDamagedPlayer) {
        game.health--;
        hasDamagedPlayer = true;
      }
      removeFromParent();
    } else if (game.health <= 0) {
      removeFromParent();
    }
    super.update(dt);
  }
}
