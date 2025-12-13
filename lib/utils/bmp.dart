import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:bassknight/utils/material_palette.dart';

class BMP {
  static const int headerSize = 54;
  final int width;
  final int height;
  late Uint8List bytes;

  /// Stores unique ARGB colors found in the loaded image.
  final List<int> palette = [];

  /// Maps palette index to a list of (x,y) coordinates (Top-Left origin).
  final Map<int, List<({int x, int y})>> _paletteMap = {};

  BMP(this.width, this.height) {
    final int contentSize = width * height * 4;
    final int fileSize = headerSize + contentSize;
    bytes = Uint8List(fileSize);
    _writeHeader(bytes.buffer.asByteData(), width, height);
  }

  /// Shared static method to write BMP header
  static void _writeHeader(ByteData bd, int width, int height) {
    final int contentSize = width * height * 4;
    final int fileSize = headerSize + contentSize;

    // Bitmap File Header
    bd.setUint8(0, 0x42); // 'B'
    bd.setUint8(1, 0x4D); // 'M'
    bd.setUint32(2, fileSize, Endian.little);
    bd.setUint32(6, 0, Endian.little); // Reserved
    bd.setUint32(10, headerSize, Endian.little); // Offset to pixel data

    // Bitmap Info Header
    bd.setUint32(14, 40, Endian.little); // Header size
    bd.setInt32(18, width, Endian.little);
    bd.setInt32(22, height, Endian.little); // Positive height for bottom-up
    bd.setUint16(26, 1, Endian.little); // Planes
    bd.setUint16(28, 32, Endian.little); // BPP
    bd.setUint32(30, 0, Endian.little); // Compression (BI_RGB)
    bd.setUint32(34, contentSize, Endian.little); // Image size
    bd.setInt32(38, 0, Endian.little); // X pixels per meter
    bd.setInt32(42, 0, Endian.little); // Y pixels per meter
    bd.setUint32(46, 0, Endian.little); // Colors used
    bd.setUint32(50, 0, Endian.little); // Colors important
  }

  /// Loads a PNG from [filePath] in a background isolate.
  Future<void> loadImage(String filePath) async {
    final File file = File(filePath);
    final Uint8List fileBytes = await file.readAsBytes();
    await _processImageBytes(fileBytes);
  }

  /// Loads an image from Flutter assets from [assetPath].
  Future<void> loadAsset(String assetPath) async {
    final ByteData byteData = await rootBundle.load(assetPath);
    final Uint8List bytes = byteData.buffer.asUint8List();
    await _processImageBytes(bytes);
  }

  Future<void> _processImageBytes(Uint8List imageBytesSource) async {
    final ui.Codec codec = await ui.instantiateImageCodec(
      imageBytesSource,
      targetWidth: width,
      targetHeight: height,
    );

    final ui.FrameInfo frame = await codec.getNextFrame();
    final ByteData? imageBytes = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );

    if (imageBytes == null) {
      throw Exception('Failed to decode image data');
    }

    // Offload heavy processing to an isolate
    final result = await compute(_processBmpData, (
      width: width,
      height: height,
      sourceBytes: imageBytes.buffer.asUint8List(),
    ));

    // Update state with result from isolate
    bytes = result.bmpData;
    palette.clear();
    palette.addAll(result.palette);
    _paletteMap.clear();
    _paletteMap.addAll(result.paletteMap);
  }

  /// Updates the color at [index] in the palette and redraws all associated pixels.
  void updatePalette(int index, int newColor) {
    if (index < 0 || index >= palette.length) return;

    palette[index] = newColor;
    final a = (newColor >> 24) & 0xFF;
    final r = (newColor >> 16) & 0xFF;
    final g = (newColor >> 8) & 0xFF;
    final b = newColor & 0xFF;

    final pixels = _paletteMap[index];
    if (pixels != null) {
      for (final point in pixels) {
        _setPixel(point.x, point.y, b, g, r, a);
      }
    }
  }

  void _setPixel(int x, int y, int b, int g, int r, int a) {
    final int bmpY = (height - 1) - y;
    final int rowStride = width * 4;
    final int offset = headerSize + (bmpY * rowStride) + (x * 4);

    bytes[offset] = b;
    bytes[offset + 1] = g;
    bytes[offset + 2] = r;
    bytes[offset + 3] = a;
  }
}

/// The data transfer object for the isolate
typedef _BmpProcessArgs = ({int width, int height, Uint8List sourceBytes});
typedef _BmpProcessResult = ({
  Uint8List bmpData,
  List<int> palette,
  Map<int, List<({int x, int y})>> paletteMap,
});

/// Top-level function to run in the isolate
_BmpProcessResult _processBmpData(_BmpProcessArgs args) {
  final width = args.width;
  final height = args.height;
  final sourceBytes = args.sourceBytes;

  const int headerSize = 54;
  final int contentSize = width * height * 4;
  final int fileSize = headerSize + contentSize;
  final Uint8List bmpData = Uint8List(fileSize);

  // Write header
  BMP._writeHeader(bmpData.buffer.asByteData(), width, height);

  final List<int> palette = [];
  final Map<int, List<({int x, int y})>> paletteMap = {};

  // Helpers for O(1) lookups
  final Map<int, int> materialColorToIndex =
      {}; // Maps MatColor -> Palette Index
  final Map<int, int> sourceColorCache =
      {}; // Maps Source ARGB -> MatColor ARGB

  int srcOffset = 0;

  // Iterate source image (Top-Down)
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final r = sourceBytes[srcOffset];
      final g = sourceBytes[srcOffset + 1];
      final b = sourceBytes[srcOffset + 2];
      final a = sourceBytes[srcOffset + 3];
      srcOffset += 4;

      // Pack as ARGB int
      final int originalColor = (a << 24) | (r << 16) | (g << 8) | b;

      // 1. Find the Closest Material Color (with caching)
      int materialColor;
      if (sourceColorCache.containsKey(originalColor)) {
        materialColor = sourceColorCache[originalColor]!;
      } else {
        materialColor = findClosestMaterialColor(originalColor);
        sourceColorCache[originalColor] = materialColor;
      }

      // 2. Add to Palette (if new)
      int? index = materialColorToIndex[materialColor];
      if (index == null) {
        index = palette.length;
        palette.add(materialColor);
        materialColorToIndex[materialColor] = index;
        paletteMap[index] = [];
      }
      paletteMap[index]!.add((x: x, y: y));

      // 3. Write to BMP Buffer (using the Material Color components)
      final ma = (materialColor >> 24) & 0xFF;
      final mr = (materialColor >> 16) & 0xFF;
      final mg = (materialColor >> 8) & 0xFF;
      final mb = materialColor & 0xFF;

      // Convert top-down y to bottom-up BMP y
      final int bmpY = (height - 1) - y;
      final int rowStride = width * 4;
      final int offset = headerSize + (bmpY * rowStride) + (x * 4);

      bmpData[offset] = mb; // B
      bmpData[offset + 1] = mg; // G
      bmpData[offset + 2] = mr; // R
      bmpData[offset + 3] = ma; // A
    }
  }

  return (bmpData: bmpData, palette: palette, paletteMap: paletteMap);
}

/// Generates the default gradient pattern directly into the image buffer.
/// Does not populate the palette.
void generateGradient(BMP bmp) {
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
}
