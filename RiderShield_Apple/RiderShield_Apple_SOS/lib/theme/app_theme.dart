import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class RSTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color.fromARGB(255, 0, 36, 98),
    colorScheme: ColorScheme.fromSeed(
      seedColor: RSColors.electric,
      brightness: Brightness.dark,
      surface: const Color.fromARGB(255, 12, 58, 142),
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: RSColors.accent,
      selectionColor: Color(0x6069BFFF),
      selectionHandleColor: RSColors.electric,
    ),
  );
}
