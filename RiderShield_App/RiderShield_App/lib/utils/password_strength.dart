import 'package:flutter/material.dart';

// UX-only estimate, not a cryptographic password-security audit.
enum PasswordLevel { empty, weak, medium, strong }

class PasswordStrength {
  const PasswordStrength({required this.level, required this.tip});

  final PasswordLevel level;
  final String tip;

  String get label => switch (level) {
        PasswordLevel.empty => 'Not entered',
        PasswordLevel.weak => 'Weak',
        PasswordLevel.medium => 'Medium',
        PasswordLevel.strong => 'Strong',
      };

  int get bars => switch (level) {
        PasswordLevel.empty => 0,
        PasswordLevel.weak => 1,
        PasswordLevel.medium => 2,
        PasswordLevel.strong => 3,
      };

  Color get color => switch (level) {
        PasswordLevel.empty => const Color(0xFF698199),
        PasswordLevel.weak => const Color(0xFFFF7F8A),
        PasswordLevel.medium => const Color(0xFFFFC476),
        PasswordLevel.strong => const Color(0xFF78DDC8),
      };
}

PasswordStrength evaluatePassword(String password) {
  if (password.isEmpty) {
    return const PasswordStrength(
      level: PasswordLevel.empty,
      tip: 'Use 8+ characters with a mix of letters, numbers and symbols.',
    );
  }

  final lower = RegExp(r'[a-z]').hasMatch(password);
  final upper = RegExp(r'[A-Z]').hasMatch(password);
  final digits = RegExp(r'[0-9]').hasMatch(password);
  final symbols = RegExp(r'[^A-Za-z0-9]').hasMatch(password);
  final categories = [lower, upper, digits, symbols].where((v) => v).length;
  final normalized = password.toLowerCase();
  final commonlyUsed = ['password', 'qwerty', '12345678', 'letmein', 'admin123']
      .any(normalized.contains);

  if (password.length < 8 || categories < 2 || commonlyUsed) {
    return const PasswordStrength(
      level: PasswordLevel.weak,
      tip: 'Try 8+ characters and avoid common passwords.',
    );
  }
  if (password.length >= 12 && categories >= 3) {
    return const PasswordStrength(
      level: PasswordLevel.strong,
      tip: 'Nice! Your password has a strong mix of characters.',
    );
  }
  return const PasswordStrength(
    level: PasswordLevel.medium,
    tip: 'Good start. Add length, numbers or symbols for more strength.',
  );
}
