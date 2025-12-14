import 'dart:ui' as ui;
import 'package:flutter/material.dart' hide Image;
import 'package:bassknight/utils/bmp.dart';

BMP minionTexture = BMP(32, 32);

// Returns a Map of color name -> Image
Future<Map<String, ui.Image>> loadMinionVariations() async {
  await minionTexture.loadAsset('assets/images/minion_32x32.png');

  final variations = <String, ui.Image>{};

  // Define variations: Name -> [BodyColor, ShadowColor]
  final definitions = {
    'purple': [Colors.purple[500]!, Colors.deepPurple[500]!],
    'yellow': [Colors.yellow[500]!, Colors.orange[500]!],
    'red': [Colors.red[500]!, Colors.red[900]!],
    'blue': [Colors.blue[500]!, Colors.indigo[500]!],
    'green': [Colors.green[500]!, Colors.green[900]!],
  };

  // Indices found by analysis
  const int bodyIndex = 2;
  const int shadowIndex = 3;

  for (final entry in definitions.entries) {
    final name = entry.key;
    final colors = entry.value;

    // Update palette
    minionTexture.updatePalette(bodyIndex, colors[0].toARGB32());
    minionTexture.updatePalette(shadowIndex, colors[1].toARGB32());

    // Decode
    final ui.Image image = await decodeImageFromList(minionTexture.bytes);
    variations[name] = image;
  }

  return variations;
}
