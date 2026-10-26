import 'package:flutter/material.dart';

void showDemoMessage(BuildContext context, {String? provider}) {
  final message = provider == null
      ? 'Preview only — account authentication will be connected later.'
      : '$provider sign-in is a UI preview. OAuth is not connected yet.';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF243D58),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
}
