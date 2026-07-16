import 'package:flutter/material.dart';

/// Shared visual language for the map and flight instruments.
///
/// Neutral colors carry structure and hierarchy. [accent] is reserved for the
/// aircraft, current values, active navigation, and live progress. [danger]
/// appears only when the telemetry link needs attention.
abstract final class InstrumentPalette {
  static const background = Color(0xFF080D13);
  static const surface = Color(0xF20F1720);
  static const surfaceMuted = Color(0xEB151F29);
  static const surfaceRaised = Color(0xFF1B2732);

  static const line = Color(0xFF34424E);
  static const lineSoft = Color(0x6634424E);
  static const inactive = Color(0xFF71808C);

  static const textPrimary = Color(0xFFF2F6F8);
  static const textSecondary = Color(0xFFA8B4BE);

  static const accent = Color(0xFF35C2D4);
  static const danger = Color(0xFFFF6B6B);

  static const mapBackground = Color(0xFFDCE3E7);
  static const mapInk = Color(0xFF3D4D58);

  /// Removes category colors from the base map and gives it a subtle cool tint.
  static const monochromeMapFilter = ColorFilter.matrix(<double>[
    0.22,
    0.70,
    0.08,
    0,
    2,
    0.22,
    0.70,
    0.08,
    0,
    7,
    0.22,
    0.70,
    0.08,
    0,
    11,
    0,
    0,
    0,
    1,
    0,
  ]);
}
