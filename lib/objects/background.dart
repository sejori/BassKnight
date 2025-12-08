import 'package:flame/components.dart';
import 'package:flame/game.dart';

class Background extends Component with HasGameRef<FlameGame> {
  late SpriteComponent _castle;
  late SpriteComponent _pillar;
  final List<SpriteComponent> _fillers = [];
  final double _yOffset = -64.0; // Half of the 256 height of the ground blocks

  @override
  Future<void> onLoad() async {
    final castleSprite = await gameRef.loadSprite('bg_castle_64x64.png');
    final pillarSprite = await gameRef.loadSprite('bg_pillar_64x64.png');
    final fillerSprite = await gameRef.loadSprite('bg_starter_32x32.png');

    // Create components with priorities to establish depth.
    // Adjusted based on user request:
    // Castle is -70 (Top-most of background elements) to prevent clipping.
    // Pillar is -80 (Behind Castle, but in front of filler).
    // Filler is -100 (Back).
    _castle = SpriteComponent(sprite: castleSprite, priority: -70);
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

    // Scale and position Castle (Left aligned, shifted up)
    if (_castle.sprite != null) {
      double scale = size.y / _castle.sprite!.originalSize.y;
      _castle.size = _castle.sprite!.originalSize * scale;
      _castle.position = Vector2(0, _yOffset);
    }

    // Scale and position Pillar (Right aligned, shifted up)
    if (_pillar.sprite != null) {
      double scale = size.y / _pillar.sprite!.originalSize.y;
      _pillar.size = _pillar.sprite!.originalSize * scale;
      _pillar.position = Vector2(size.x - _pillar.size.x, _yOffset);
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
      
      // Position all fillers (shifted up)
      for (int i = 0; i < _fillers.length; i++) {
        if (i < needed) {
           _fillers[i].size = fillerSize;
           _fillers[i].position = Vector2(i * fillerSize.x, _yOffset);
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