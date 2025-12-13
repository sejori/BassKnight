import 'dart:math';
import 'package:flutter/material.dart';

// Cache for the color registry
Map<int, String>? _materialColorsRegistry;

/// Ensures the registry is populated.
void _ensureRegistry() {
  if (_materialColorsRegistry != null) return;

  _materialColorsRegistry = {
    // Basics
    Colors.transparent.toARGB32(): 'Colors.transparent',
    Colors.white.toARGB32(): 'Colors.white',
    Colors.black.toARGB32(): 'Colors.black',
  };

  // Helper to add a swatch
  void addSwatch(String name, MaterialColor color) {
    // Primary shades
    final shades = [50, 100, 200, 300, 400, 500, 600, 700, 800, 900];
    for (final shade in shades) {
      if (color[shade] != null) {
        _materialColorsRegistry![color[shade]!.toARGB32()] = '$name[$shade]';
      }
    }
  }

  // Helper to add an accent swatch
  void addAccentSwatch(String name, MaterialAccentColor color) {
    final shades = [100, 200, 400, 700];
    for (final shade in shades) {
      if (color[shade] != null) {
        _materialColorsRegistry![color[shade]!.toARGB32()] = '$name[$shade]';
      }
    }
  }

  // Register all standard MaterialColors
  addSwatch('Colors.red', Colors.red);
  addAccentSwatch('Colors.redAccent', Colors.redAccent);

  addSwatch('Colors.pink', Colors.pink);
  addAccentSwatch('Colors.pinkAccent', Colors.pinkAccent);

  addSwatch('Colors.purple', Colors.purple);
  addAccentSwatch('Colors.purpleAccent', Colors.purpleAccent);

  addSwatch('Colors.deepPurple', Colors.deepPurple);
  addAccentSwatch('Colors.deepPurpleAccent', Colors.deepPurpleAccent);

  addSwatch('Colors.indigo', Colors.indigo);
  addAccentSwatch('Colors.indigoAccent', Colors.indigoAccent);

  addSwatch('Colors.blue', Colors.blue);
  addAccentSwatch('Colors.blueAccent', Colors.blueAccent);

  addSwatch('Colors.lightBlue', Colors.lightBlue);
  addAccentSwatch('Colors.lightBlueAccent', Colors.lightBlueAccent);

  addSwatch('Colors.cyan', Colors.cyan);
  addAccentSwatch('Colors.cyanAccent', Colors.cyanAccent);

  addSwatch('Colors.teal', Colors.teal);
  addAccentSwatch('Colors.tealAccent', Colors.tealAccent);

  addSwatch('Colors.green', Colors.green);
  addAccentSwatch('Colors.greenAccent', Colors.greenAccent);

  addSwatch('Colors.lightGreen', Colors.lightGreen);
  addAccentSwatch('Colors.lightGreenAccent', Colors.lightGreenAccent);

  addSwatch('Colors.lime', Colors.lime);
  addAccentSwatch('Colors.limeAccent', Colors.limeAccent);

  addSwatch('Colors.yellow', Colors.yellow);
  addAccentSwatch('Colors.yellowAccent', Colors.yellowAccent);

  addSwatch('Colors.amber', Colors.amber);
  addAccentSwatch('Colors.amberAccent', Colors.amberAccent);

  addSwatch('Colors.orange', Colors.orange);
  addAccentSwatch('Colors.orangeAccent', Colors.orangeAccent);

  addSwatch('Colors.deepOrange', Colors.deepOrange);
  addAccentSwatch('Colors.deepOrangeAccent', Colors.deepOrangeAccent);

  addSwatch('Colors.brown', Colors.brown);
  // Brown has no accent

  addSwatch('Colors.grey', Colors.grey);
  // Grey has no accent

  addSwatch('Colors.blueGrey', Colors.blueGrey);
  // BlueGrey has no accent
}

/// Finds the closest Material Color to the given [sourceColor] (ARGB int).
/// Returns the ARGB int of the matched Material Color.
int findClosestMaterialColor(int sourceColor) {
  _ensureRegistry();

  // Extract source components
  final sa = (sourceColor >> 24) & 0xFF;

  // Optimization: If fully transparent, return 0 (transparent)
  if (sa == 0) return 0x00000000;

  final sr = (sourceColor >> 16) & 0xFF;
  final sg = (sourceColor >> 8) & 0xFF;
  final sb = sourceColor & 0xFF;

  double minDistance = double.maxFinite;
  int closestColor = 0xFF000000; // Default to black

  // Iterate through our registry
  for (final entry in _materialColorsRegistry!.entries) {
    final targetColor = entry.key;

    final ta = (targetColor >> 24) & 0xFF;
    final tr = (targetColor >> 16) & 0xFF;
    final tg = (targetColor >> 8) & 0xFF;
    final tb = targetColor & 0xFF;

    // Euclidean distance in RGBA space
    final dSq =
        pow(sr - tr, 2) + pow(sg - tg, 2) + pow(sb - tb, 2) + pow(sa - ta, 2);

    if (dSq < minDistance) {
      minDistance = dSq.toDouble();
      closestColor = targetColor;
    }
  }

  return closestColor;
}

/// Returns the string name of a material color (e.g. "Colors.red[500]")
/// or "Unknown" if not found.
String getMaterialColorName(int color) {
  _ensureRegistry();
  if (color == 0x00000000) return 'Transparent';
  return _materialColorsRegistry![color] ??
      'Unknown Color(0x${color.toRadixString(16).toUpperCase()})';
}
