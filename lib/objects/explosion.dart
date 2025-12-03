import 'package:flame/components.dart';

class Explosion extends SpriteAnimationComponent with HasGameReference {
  Explosion({super.position})
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
  }
}
