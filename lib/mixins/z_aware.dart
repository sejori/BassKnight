import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../bass_knight.dart';

mixin ZAware on PositionComponent implements HasGameReference<BassKnightGame> {
  late Vector2 _initialScale;
  late double _maxScaleY; // Y-coordinate where max scale (1.0) applies
  final double _minScale = 0.2; // Minimum scale factor
  late double _scalingRangeY; // Vertical range over which scaling occurs

  @override
  void onMount() {
    super.onMount();
    _initialScale = scale.clone();
    
    // Define the Y-coordinate where objects appear at their maximum scale (1.0)
    // Let's assume this is when the component's bottom is at game.size.y (bottom of screen).
    // So, center Y = game.size.y - size.y / 2
    _maxScaleY = game.size.y - size.y / 2;

    // Define the vertical range for scaling.
    // Let's scale over the entire visible height from maxScaleY up to the top of the screen.
    _scalingRangeY = _maxScaleY; // From _maxScaleY up to 0 (top of screen)
  }

  @override
  void update(double dt) {
    super.update(dt);

    final currentY = position.y; // This is the center Y of the component

    // Calculate how far up the component is from the maxScaleY point
    // This value will be positive when currentY < _maxScaleY (component is higher)
    final distanceUp = _maxScaleY - currentY;

    // Calculate a normalized factor (0.0 to 1.0) based on distanceUp
    // Clamped to ensure it stays within 0 and _scalingRangeY
    final normalizedHeight = (distanceUp / _scalingRangeY).clamp(0.0, 1.0);

    // Calculate the new scale, interpolating between initialScale (max scale) and _minScale
    // If normalizedHeight is 0, scale is initialScale (1.0)
    // If normalizedHeight is 1, scale is _minScale (0.2)
    final newScaleFactor = _initialScale.x * (1.0 - normalizedHeight) + _minScale * normalizedHeight;

    // Apply the new scale.
    scale.setAll(newScaleFactor);
  }
}