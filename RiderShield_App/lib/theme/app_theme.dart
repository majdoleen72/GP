
import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class RSTheme {

  // ==========================================
  // ORIGINAL DARK MODE - UNCHANGED
  // ==========================================

  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor:
        const Color.fromARGB(255, 0, 36, 98),
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

  // ==========================================
  // FROSTED ICE LIGHT MODE
  // ==========================================

  static final light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Soft icy background
    scaffoldBackgroundColor:
        const Color(0xFFF4F9FF),

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF248BC7),
      brightness: Brightness.light,
      surface: const Color(0xFFFFFFFF),
      onSurface: const Color(0xFF16364D),
      primary: const Color(0xFF248BC7),
      onPrimary: Colors.white,
      outline: const Color(0xFFD2E8F8),
    ),

    // Text and icon colors
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: Color(0xFF16364D),
      ),
      bodyMedium: TextStyle(
        color: Color(0xFF16364D),
      ),
      bodySmall: TextStyle(
        color: Color(0xFF58758C),
      ),
      titleLarge: TextStyle(
        color: Color(0xFF16364D),
        fontWeight: FontWeight.w700,
      ),
    ),

    iconTheme: const IconThemeData(
      color: Color(0xFF248BC7),
    ),

    // Input cursor and selection
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: Color(0xFF248BC7),
      selectionColor: Color(0x6648B5ED),
      selectionHandleColor: Color(0xFF248BC7),
    ),

    // Frosted-style cards
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(
          color: Color(0xFFD2E8F8),
        ),
      ),
    ),

    // Dialogs
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
    ),

    // App bars
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF4F9FF),
      foregroundColor: Color(0xFF16364D),
      elevation: 0,
      centerTitle: false,
    ),

    // Text fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFE5F2FC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFD2E8F8),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF248BC7),
          width: 1.5,
        ),
      ),
    ),
  );
}
