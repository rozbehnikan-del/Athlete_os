import 'package:flutter/material.dart';

/// Semantic colors and dimensions from Figma: 01 — Foundations / CrossFit V1.
/// Keep these separate from legacy AthleteOS colors until each screen is migrated.
abstract final class FigmaV1Tokens {
  static const background = Color(0xFFF7F8FA);
  static const surface = Color(0xFFFFFFFF);
  static const primary = Color(0xFF141719);
  static const text = Color(0xFF0A1118);
  static const muted = Color(0xFF68737D);
  static const border = Color(0xFFE5E9EE);
  static const success = Color(0xFF17834B);
  static const successSurface = Color(0xFFE7F7EE);
  static const danger = Color(0xFFB83242);

  static const double pageGutter = 20;
  static const double mobileTopInset = 54;
  static const double cardRadius = 18;
  static const double primaryButtonRadius = 14;
  static const double primaryButtonHeight = 54;
}
