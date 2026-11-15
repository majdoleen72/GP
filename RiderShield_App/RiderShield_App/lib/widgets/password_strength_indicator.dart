import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/password_strength.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final strength = evaluatePassword(value.text);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Password strength', style: TextStyle(
                  color: RSColors.muted, fontSize: 12, fontWeight: FontWeight.w600,
                )),
                const Spacer(),
                Text(strength.label, style: TextStyle(
                  color: strength.color, fontWeight: FontWeight.w800, fontSize: 12,
                )),
              ],
            ),
            const SizedBox(height: 5),
            Row(children: List.generate(3, (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == 2 ? 0 : 7),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeInOut,
                  height: 5,
                  decoration: BoxDecoration(
                    color: i < strength.bars
                        ? strength.color : Colors.white.withValues(alpha: .11),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ))),
            if (value.text.isNotEmpty) const SizedBox(height: 4),
            if (value.text.isNotEmpty) Text(strength.tip, maxLines: 2, style: const TextStyle(
              fontSize: 11.3, color: RSColors.muted, height: 1.4,
            )),
          ],
        );
      },
    );
  }
}
