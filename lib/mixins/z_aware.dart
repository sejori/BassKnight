import 'package:flame/components.dart';

mixin ZAware on PositionComponent {
  double _z = 0;
  double _altitude = 0;
  
  // Logic X is just super.position.x
  
  double get z => _z;
  set z(double value) {
    _z = value;
    _updatePositionAndPriority();
  }

  double get altitude => _altitude;
  set altitude(double value) {
    _altitude = value;
    _updatePositionAndPriority();
  }

  void _updatePositionAndPriority() {
    // We assume super.position.x is managed by the user or movement logic.
    // We strictly control super.position.y
    // We need a baseline Y for Z=0. Let's assume the parent handles the "World" offset.
    // For now, let's assume y = z - altitude.
    // However, we usually want to position relative to the screen.
    // Let's rely on the user to set a 'baseY' or just use 'z' as the ground line Y.
    
    // Simple projection:
    // The "Ground" level for a given Z is equal to Z.
    // So if I am at Z=500, my feet (altitude=0) are at screen Y=500.
    // If I jump 100 units high, my screen Y becomes 400.
    
    y = _z - _altitude;
    priority = _z.toInt();
  }
  
  @override
  void onMount() {
    super.onMount();
    _updatePositionAndPriority();
  }
}
