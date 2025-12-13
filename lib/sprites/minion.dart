import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:bassknight/utils/bmp.dart';
import 'package:bassknight/utils/material_palette.dart';

BMP minionTexture = BMP(32, 32);

// This function needs to be called in an appropriate async context,
// for example, in the game's onLoad method or a main setup function.
Future<Image> loadMinionTextureAndPrintPalette() async {
  await minionTexture.loadAsset('assets/images/minion_32x32.png');
  for (int i = 0; i < minionTexture.palette.length; i++) {
    final color = minionTexture.palette[i];
    final colorName = getMaterialColorName(color);
    debugPrint(
      '  Color $i: $colorName (0x${color.toRadixString(16).toUpperCase()})',
    );
  }

  return decodeImageFromList(minionTexture.bytes);
}
