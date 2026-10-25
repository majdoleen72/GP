String? validateEmail(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return 'Please enter your email address';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validatePassword(String? value) {
  if ((value ?? '').isEmpty) return 'Please enter a password';
  if (value!.length < 8) return 'Use at least 8 characters';
  return null;
}
