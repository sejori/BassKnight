import 'package:flame/components.dart';
import 'package:flame/game.dart';

class Background extends Component with HasGameRef<FlameGame> {
  late SpriteComponent _castle;
  late SpriteComponent _pillar;
  final List<SpriteComponent> _fillers = [];

  @override
  Future<void> onLoad() async {
    final castleSprite = await gameRef.loadSprite('bg_castle_64x64.png');
    final pillarSprite = await gameRef.loadSprite('bg_pillar_64x64.png');
    final fillerSprite = await gameRef.loadSprite('bg_starter_32x32.png');

    // Create components with priorities to establish depth
    // Filler is at the back
    // Castle is in front of filler
    // Pillar is in front of castle
    // All are negative to be behind the gameplay elements (default priority 0)
    _castle = SpriteComponent(sprite: castleSprite, priority: -90);
    _pillar = SpriteComponent(sprite: pillarSprite, priority: -80);
    
    // Add components to the game
    add(_castle);
    add(_pillar);
    
    // Initialize filler (we'll add more in onGameResize if needed)
    final filler = SpriteComponent(sprite: fillerSprite, priority: -100);
    _fillers.add(filler);
    add(filler);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    // Ensure sprites are loaded before resizing
    if (!isLoaded) return;

    // Scale and position Castle (Left aligned)
    if (_castle.sprite != null) {
      double scale = size.y / _castle.sprite!.originalSize.y;
      _castle.size = _castle.sprite!.originalSize * scale;
      _castle.position = Vector2(0, 0);
    }

    // Scale and position Pillar (Right aligned)
    if (_pillar.sprite != null) {
      double scale = size.y / _pillar.sprite!.originalSize.y;
      _pillar.size = _pillar.sprite!.originalSize * scale;
      _pillar.position = Vector2(size.x - _pillar.size.x, 0);
    }

    // Handle Fillers
    if (_fillers.isNotEmpty && _fillers.first.sprite != null) {
      final fillerSprite = _fillers.first.sprite!;
      double fillerScale = size.y / fillerSprite.originalSize.y;
      Vector2 fillerSize = fillerSprite.originalSize * fillerScale;
      
      // Calculate how many fillers we need to cover the screen width
      int needed = (size.x / fillerSize.x).ceil();
      
      // Add more fillers if needed
      if (_fillers.length < needed) {
        for (int i = _fillers.length; i < needed; i++) {
          final f = SpriteComponent(sprite: fillerSprite, priority: -100);
          _fillers.add(f);
          add(f);
        }
      }
      
      // Position all fillers
      for (int i = 0; i < _fillers.length; i++) {
        if (i < needed) {
           _fillers[i].size = fillerSize;
           _fillers[i].position = Vector2(i * fillerSize.x, 0);
           // Ensure it's visible (in case it was hidden)
           _fillers[i].opacity = 1.0; 
        } else {
           // Hide unused fillers
           _fillers[i].position = Vector2(-10000, -10000);
        }
      }
    }
  }
}
