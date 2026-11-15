
import 'dart:ui';
import 'package:flutter/material.dart';

class DashboardBackground extends StatelessWidget {
  const DashboardBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0, .38, .74, 1],
                  colors: [
                    Color(0xFF07172A),
                    Color(0xFF12324B),
                    Color(0xFF193C53),
                    Color(0xFF102A3F),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -105,
              right: -115,
              child: _Glow(
                size: 360,
                color: Color(0x735C9AC1),
              ),
            ),
            Positioned(
              top: 300,
              left: -165,
              child: _Glow(
                size: 340,
                color: Color(0x575EADBA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => ImageFiltered(
        imageFilter: ImageFilter.blur(
          sigmaX: 38,
          sigmaY: 38,
        ),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color,
                color.withValues(alpha: 0),
              ],
            ),
          ),
        ),
      );
}
