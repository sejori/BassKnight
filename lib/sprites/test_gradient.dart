import 'dart:ui';
import 'package:flutter/painting.dart';
import 'package:bassknight/utils/bmp.dart';

final bmp = BMP(32, 32);

/// Generates the default gradient pattern directly into the image buffer.
/// Does not populate the palette.
Future<Image> generateGradientImage() async {
  int offset = BMP.headerSize;
  // BMP is bottom-up, so we write rows from bottom (height-1) to top (0)
  for (int y = bmp.height - 1; y >= 0; y--) {
    for (int x = 0; x < bmp.width; x++) {
      // Scale 0-31 coordinates to 0-255 color range
      final int r = (x * 255 / (bmp.width - 1)).round();
      final int g = (y * 255 / (bmp.height - 1)).round();

      bmp.bytes[offset++] = 0; // B
      bmp.bytes[offset++] = g; // G
      bmp.bytes[offset++] = r; // R
      bmp.bytes[offset++] = 255; // A
    }
  }
  final bmpBytes = bmp.bytes;
  return decodeImageFromList(bmpBytes);
}
