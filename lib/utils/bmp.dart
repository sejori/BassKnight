import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

class BMP {
  static const int headerSize = 54;
  final int width;
  final int height;
  late final Uint8List image;

  /// Stores unique ARGB colors found in the loaded image.
  final List<int> palette = [];

  /// Maps palette index to a list of (x,y) coordinates (Top-Left origin).
  final Map<int, List<({int x, int y})>> _paletteMap = {};

  BMP(this.width, this.height) {
    final int contentSize = width * height * 4;
    final int fileSize = headerSize + contentSize;
    image = Uint8List(fileSize);
    _writeHeader();
  }

  void _writeHeader() {
    final ByteData bd = image.buffer.asByteData();
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

  /// Loads a PNG from [filePath], resizes it to match this BMP's dimensions,
  /// populates the image buffer, and builds the color palette.
  Future<void> loadImage(String filePath) async {
    final File file = File(filePath);
    final Uint8List fileBytes = await file.readAsBytes();

    final ui.Codec codec = await ui.instantiateImageCodec(
      fileBytes,
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

    palette.clear();
    _paletteMap.clear();

    int srcOffset = 0;
    // Iterate source image (Top-Down)
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final r = imageBytes.getUint8(srcOffset);
        final g = imageBytes.getUint8(srcOffset + 1);
        final b = imageBytes.getUint8(srcOffset + 2);
        final a = imageBytes.getUint8(srcOffset + 3);
        srcOffset += 4;

        // Pack as ARGB int
        final int color = (a << 24) | (r << 16) | (g << 8) | b;

        int index = palette.indexOf(color);
        if (index == -1) {
          index = palette.length;
          palette.add(color);
          _paletteMap[index] = [];
        }
        _paletteMap[index]!.add((x: x, y: y));

        _setPixel(x, y, b, g, r, a);
      }
    }
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

  /// Sets pixel at (x,y) [Top-Left origin] with BGRA values.
  void _setPixel(int x, int y, int b, int g, int r, int a) {
    // Convert top-down y to bottom-up BMP y
    final int bmpY = (height - 1) - y;
    final int rowStride = width * 4;
    final int offset = headerSize + (bmpY * rowStride) + (x * 4);

    image[offset] = b;
    image[offset + 1] = g;
    image[offset + 2] = r;
    image[offset + 3] = a;
  }
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

      bmp.image[offset++] = 0; // B
      bmp.image[offset++] = g; // G
      bmp.image[offset++] = r; // R
      bmp.image[offset++] = 255; // A
    }
  }
}
