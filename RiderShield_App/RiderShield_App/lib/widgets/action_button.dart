import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon = Icons.arrow_forward_rounded,
    this.height = 60,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFDDEEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2552B5FF),
              blurRadius: 29,
              offset: Offset(0, 11),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(19),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 21),
            child: Row(
              children: [
                const SizedBox(width: 34),
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: RSColors.midnight,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.25,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: RSColors.midnight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: RSColors.white, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
