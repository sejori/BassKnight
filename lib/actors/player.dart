import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/services.dart';

import '../bass_knight.dart';
import '../objects/ground_block.dart';
import '../objects/platform_block.dart';
import '../objects/star.dart';
import 'minion.dart';

class Player extends SpriteAnimationComponent
    with KeyboardHandler, CollisionCallbacks, HasGameReference<BassKnightGame> {
  Player({required super.position})
    : super(size: Vector2.all(64), anchor: Anchor.center);

  final Vector2 velocity = Vector2.zero();
  final double moveSpeed = 200;
  int horizontalDirection = 0;
  int verticalDirection = 0;
  bool hitByEnemy = false;

  @override
  Future<void> onLoad() async {
    animation = SpriteAnimation.fromFrameData(
      game.images.fromCache('bassknight_32x32.png'),
      SpriteAnimationData.sequenced(
        amount: 1,
        textureSize: Vector2.all(32),
        stepTime: 0.12,
      ),
    );

    add(CircleHitbox());
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Handle W and S keys for vertical movement
    verticalDirection = 0; // Reset vertical direction
    if (keysPressed.contains(LogicalKeyboardKey.keyW)) {
      verticalDirection = -1; // Move up
    } else if (keysPressed.contains(LogicalKeyboardKey.keyS)) {
      verticalDirection = 1; // Move down
    }

    // Existing space key for attack
    if (event is KeyDownEvent &&
        keysPressed.contains(LogicalKeyboardKey.space)) {
      attack();
    }
    return true;
  }

  @override
  void update(double dt) {
    velocity.x = 0;
    game.objectSpeed = 0;

    velocity.y = verticalDirection * moveSpeed;

    // Adjust ember position.
    position += velocity * dt;

    // Clamp vertical position
    position.y = position.y.clamp(game.canvasSize.y - 256, game.canvasSize.y);

    // If ember fell in pit, then game over.
    if (position.y > game.size.y + size.y) {
      game.health = 0;
    }

    if (game.health <= 0) {
      removeFromParent();
    }

    super.update(dt);
  }

  void attack() {
    final minions = game.world.children.whereType<Minion>();
    for (final minion in minions) {
      // Calculate minion center assuming anchor is bottomLeft
      final minionCenter =
          minion.position + Vector2(minion.size.x / 2, -minion.size.y / 2);
      final distance = position.distanceTo(minionCenter);

      if (distance < 150) {
        final direction = minionCenter.x - position.x;
        if ((scale.x > 0 && direction > 0) || (scale.x < 0 && direction < 0)) {
          minion.removeFromParent();
          game.starsCollected++;
        }
      }
    }
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {


    if (other is Star) {
      other.removeFromParent();
      game.starsCollected++;
    }

    if (other is Minion) {
      hit();
    }
    super.onCollision(intersectionPoints, other);
  }

  // This method runs an opacity effect on ember
  // to make it blink.
  void hit() {
    if (!hitByEnemy) {
      game.health--;
      hitByEnemy = true;
    }
    add(
      OpacityEffect.fadeOut(
          EffectController(alternate: true, duration: 0.1, repeatCount: 5),
        )
        ..onComplete = () {
          hitByEnemy = false;
        },
    );
  }
}
