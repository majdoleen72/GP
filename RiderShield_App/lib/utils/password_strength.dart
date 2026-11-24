
import 'package:flutter/material.dart';

// UX-only estimate, not a cryptographic password-security audit.
enum PasswordLevel { empty, weak, medium, strong }

class PasswordStrength {
  const PasswordStrength({
    required this.level,
    required this.tip,
  });

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
      tip: 'Use 8+ characters with uppercase, lowercase, numbers and symbols.',
    );
  }

  final hasLower = RegExp(r'[a-z]').hasMatch(password);
  final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
  final hasNumber = RegExp(r'[0-9]').hasMatch(password);
  final hasSymbol = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

  final categories = [
    hasLower,
    hasUpper,
    hasNumber,
    hasSymbol,
  ].where((value) => value).length;

  final normalized = password.toLowerCase();

  final commonlyUsed = [
    'password',
    'qwerty',
    '12345678',
    'letmein',
    'admin123',
  ].any(normalized.contains);

  // Give accurate advice for the actual missing requirement.
  if (password.length < 8) {
    return const PasswordStrength(
      level: PasswordLevel.weak,
      tip: 'Use at least 8 characters.',
    );
  }

  if (commonlyUsed) {
    return const PasswordStrength(
      level: PasswordLevel.weak,
      tip: 'Avoid common passwords and predictable patterns.',
    );
  }

  if (categories < 2) {
    return const PasswordStrength(
      level: PasswordLevel.weak,
      tip: 'Mix uppercase, lowercase, numbers and symbols.',
    );
  }

  // Match the mandatory sign-up requirements.
  final meetsRequirements =
      hasLower && hasUpper && hasNumber && hasSymbol;

  if (!meetsRequirements) {
    final missing = <String>[];

    if (!hasUpper) missing.add('uppercase letters');
    if (!hasLower) missing.add('lowercase letters');
    if (!hasNumber) missing.add('numbers');
    if (!hasSymbol) missing.add('symbols');

    return PasswordStrength(
      level: PasswordLevel.medium,
      tip: 'Add ${missing.join(', ')}.',
    );
  }

  // All sign-up requirements are satisfied.
  // Extra length improves the strength estimate.
  if (password.length >= 12) {
    return const PasswordStrength(
      level: PasswordLevel.strong,
      tip: 'Great! Your password meets all requirements.',
    );
  }

  return const PasswordStrength(
    level: PasswordLevel.medium,
    tip: 'All requirements met. Use 12+ characters for a stronger password.',
  );
}
