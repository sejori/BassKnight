import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../bass_knight.dart';


class GroundBlock extends SpriteComponent
    with HasGameReference<BassKnightGame> {
  final Vector2 gridPosition;
  double xOffset;

  final UniqueKey _blockKey = UniqueKey();
  final Vector2 velocity = Vector2.zero();

  GroundBlock({required this.gridPosition, required this.xOffset})
    : super(size: Vector2(64, 256), anchor: Anchor.bottomLeft);

  @override
  Future<void> onLoad() async {
    final groundImage = game.images.fromCache('grass_32x32.png');
    sprite = Sprite(groundImage);
    position = Vector2(
      (gridPosition.x * size.x) + xOffset,
      game.size.y - (gridPosition.y * size.y),
    );
    add(RectangleHitbox(collisionType: CollisionType.passive));
    if (gridPosition.x == 9 && position.x > game.lastBlockXPosition) {
      game.lastBlockKey = _blockKey;
      game.lastBlockXPosition = position.x + size.x;
    }
  }

  @override
  void render(Canvas canvas) {
    if (sprite == null) {
      return;
    }
    sprite!.renderRect(canvas, Rect.fromLTWH(0, 0, size.x, 64));
    sprite!.renderRect(canvas, Rect.fromLTWH(0, 64, size.x, 64));
    sprite!.renderRect(canvas, Rect.fromLTWH(0, 128, size.x, 64));
    sprite!.renderRect(canvas, Rect.fromLTWH(0, 192, size.x, 64));
  }
}
