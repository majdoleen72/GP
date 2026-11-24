
import 'package:flutter/material.dart';

abstract final class RSColors {

  // ==========================================
  // ORIGINAL DARK MODE - UNCHANGED
  // ==========================================

  static const midnight = Color(0xFF071225);
  static const deep = Color(0xFF0B1830);
  static const surface = Color(0xFF142640);
  static const accent = Color(0xFF9DD7FF);
  static const electric = Color(0xFF69BFFF);
  static const white = Color(0xFFF8FAFF);
  static const muted = Color(0xFFA8B9CA);

  // ==========================================
  // FROSTED ICE LIGHT MODE
  // ==========================================

  static const iceBackground = Color(0xFFF4F9FF);
  static const iceSurface = Color(0xFFFFFFFF);
  static const iceGlass = Color(0xFFE5F2FC);
  static const iceBorder = Color(0xFFD2E8F8);

  static const iceText = Color(0xFF16364D);
  static const iceMuted = Color(0xFF58758C);
  static const iceAccent = Color(0xFF248BC7);
  static const iceNav = Color(0xFFD9EFFD);

  // ==========================================
  // THEME HELPERS
  // ==========================================

  static bool isLight(BuildContext context) {
    return Theme.of(context).brightness ==
        Brightness.light;
  }

  static Color background(BuildContext context) {
    return isLight(context)
        ? iceBackground
        : midnight;
  }

  static Color card(BuildContext context) {
    return isLight(context)
        ? iceSurface
        : surface;
  }

  static Color glass(BuildContext context) {
    return isLight(context)
        ? iceGlass
        : surface;
  }

  static Color text(BuildContext context) {
    return isLight(context)
        ? iceText
        : white;
  }

  static Color secondaryText(BuildContext context) {
    return isLight(context)
        ? iceMuted
        : muted;
  }

  static Color primaryAccent(BuildContext context) {
    return isLight(context)
        ? iceAccent
        : accent;
  }

  static Color border(BuildContext context) {
    return isLight(context)
        ? iceBorder
        : white.withValues(alpha: 0.16);
  }
}
