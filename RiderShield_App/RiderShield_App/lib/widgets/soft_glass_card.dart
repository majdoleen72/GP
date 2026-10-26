import 'dart:ui';
import 'package:flutter/material.dart';

/// A quiet frosted-glass surface, intentionally unlike neon/glossy cards.
class SoftGlassCard extends StatelessWidget {
  const SoftGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.radius = 26,
    this.light = false,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final bool light;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: shape,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 17, sigmaY: 17),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            color: light
                ? const Color(0xC8E4EDF3)
                : const Color(0x3C7D97AE),
            border: Border.all(
              color: Colors.white.withValues(alpha: light ? .75 : .23),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF071225).withValues(alpha: .13),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: onTap == null
                ? Padding(padding: padding, child: child)
                : InkWell(
                    onTap: onTap,
                    borderRadius: shape,
                    child: Padding(padding: padding, child: child),
                  ),
          ),
        ),
      ),
    );
  }
}
