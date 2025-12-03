import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../actors/minion.dart';

class Blast extends SpriteAnimationComponent
    with CollisionCallbacks, HasGameReference {
  Blast({required super.position})
      : super(
          size: Vector2.all(64),
          anchor: Anchor.center,
          removeOnFinish: true,
        );

  @override
  Future<void> onLoad() async {
    animation = await game.loadSpriteAnimation(
      'ember.png',
      SpriteAnimationData.sequenced(
        amount: 4,
        textureSize: Vector2.all(16),
        stepTime: 0.1,
        loop: false,
      ),
    );
    add(CircleHitbox());
  }

  @override
  void onCollisionStart(
      Set<Vector2> intersectionPoints, PositionComponent other) {
    if (other is Minion) {
      other.hit();
    }
    super.onCollisionStart(intersectionPoints, other);
  }
}
