import 'dart:typed_data';

import 'package:bassknight/utils/bmp.dart';
import 'package:bassknight/utils/material_palette.dart';
import 'package:flutter/material.dart';

BMP minionTexture = BMP(32, 32);

// This function needs to be called in an appropriate async context,
// for example, in the game's onLoad method or a main setup function.
Future<Uint8List> loadMinionTextureAndPrintPalette() async {
  await minionTexture.loadAsset('assets/images/minion_32x32.png');
  debugPrint('Minion Texture Palette:');
  for (int i = 0; i < minionTexture.palette.length; i++) {
    final color = minionTexture.palette[i];
    final colorName = getMaterialColorName(color);
    debugPrint(
      '  Color $i: $colorName (0x${color.toRadixString(16).toUpperCase()})',
    );
  }

  return minionTexture.bytes;
}
