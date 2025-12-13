import 'package:bassknight/utils/bmp.dart';
import 'package:flutter/material.dart'; // For Color class in print

BMP minionTexture = BMP(32, 32);

// This function needs to be called in an appropriate async context,
// for example, in the game's onLoad method or a main setup function.
Future<void> loadMinionTextureAndPrintPalette() async {
  await minionTexture.loadAsset('assets/images/minion_32x32.png');
  debugPrint('Minion Texture Palette:');
  for (int i = 0; i < minionTexture.palette.length; i++) {
    final color = minionTexture.palette[i];
    // Convert ARGB int to Flutter Color for better print representation
    debugPrint('  Color $i: ${Color(color)}');
  }
}