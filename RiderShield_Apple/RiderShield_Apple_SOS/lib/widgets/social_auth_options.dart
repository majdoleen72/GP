import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../utils/demo_feedback.dart';

class SocialAuthOptions extends StatelessWidget {
  const SocialAuthOptions({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.white.withValues(alpha: .18))),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 13),
              child: Text('OR CONTINUE WITH', style: TextStyle(
                color: RSColors.muted, fontSize: 10,
                letterSpacing: 1.3, fontWeight: FontWeight.w800,
              )),
            ),
            Expanded(child: Divider(color: Colors.white.withValues(alpha: .18))),
          ],
        ),
        SizedBox(height: compact ? 8 : 15),
        Row(
          children: [
            Expanded(child: _SocialButton(
              provider: 'Google', icon: const _GoogleG(), compact: compact,
              onPressed: () => showDemoMessage(context, provider: 'Google'),
            )),
            const SizedBox(width: 9),
            Expanded(child: _SocialButton(
              provider: 'Apple', icon: const Icon(Icons.apple, size: 22), compact: compact,
              onPressed: () => showDemoMessage(context, provider: 'Apple'),
            )),
            const SizedBox(width: 9),
            Expanded(child: _SocialButton(
              provider: 'Facebook', compact: compact,
              icon: const Icon(Icons.facebook, size: 21, color: Color(0xFF66B6FF)),
              onPressed: () => showDemoMessage(context, provider: 'Facebook'),
            )),
          ],
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.provider,
    required this.icon,
    required this.onPressed,
    this.compact = false,
  });

  final String provider;
  final Widget icon;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
        color: const Color(0xFF20344B),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: compact ? 44 : 55,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: .15)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 7),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    icon,
                    const SizedBox(width: 5),
                    Text(provider, style: const TextStyle(
                      color: RSColors.white, fontSize: 12, fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

// Colored lettermark for a lightweight UI prototype, not an official SVG.
class _GoogleG extends StatelessWidget {
  const _GoogleG();
  @override
  Widget build(BuildContext context) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) => const SweepGradient(colors: [
          Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05),
          Color(0xFFEA4335), Color(0xFF4285F4),
        ]).createShader(bounds),
        child: const Text('G', style: TextStyle(
          fontWeight: FontWeight.w900, fontSize: 22, height: 1,
        )),
      );
}
