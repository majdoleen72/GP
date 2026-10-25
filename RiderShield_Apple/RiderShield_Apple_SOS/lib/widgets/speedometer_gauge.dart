import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Smooth custom-painted arc. Value is a *demo* until GPS is wired up.
class SpeedometerGauge extends StatelessWidget {
  const SpeedometerGauge({
    super.key,
    required this.speed,
    this.maxSpeed = 180,
  });

  final double speed;
  final double maxSpeed;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: speed),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          height: 170,
          width: double.infinity,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ArcPainter(
                    ratio: (value / maxSpeed).clamp(0.0, 1.0),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'CURRENT SPEED',
                      style: TextStyle(
                        color: Color(0xFFC3D5E1),
                        letterSpacing: 1.6,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value.round().toString(),
                      style: const TextStyle(
                        fontSize: 57,
                        height: 1.0,
                        fontWeight: FontWeight.w300,
                        color: Colors.white,
                        letterSpacing: -3.0,
                      ),
                    ),
                    const Text(
                      'km/h',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFFB7D2E4),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 12,
                bottom: 7,
                child: _Endpoint(text: '0'),
              ),
              Positioned(
                right: 12,
                bottom: 7,
                child: _Endpoint(text: maxSpeed.toInt().toString()),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Endpoint extends StatelessWidget {
  const _Endpoint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(color: Color(0xFFD2E1EC), fontSize: 12),
      );
}

class _ArcPainter extends CustomPainter {
  _ArcPainter({required this.ratio});
  final double ratio;
  static const _start = math.pi;
  static const _sweep = math.pi;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 7);
    final radius = math.min(size.width * .405, size.height * .81);
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..color = const Color(0x556980A2)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16;
    canvas.drawArc(rect, _start, _sweep, false, track);

    final ticks = Paint()
      ..color = const Color(0x5BD7E6F3)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i <= 36; i++) {
      final a = _start + _sweep * i / 36;
      final inner = radius + 18.0;
      final outer = inner + ((i % 6 == 0) ? 9 : 5);
      final unit = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(center + unit * inner, center + unit * outer, ticks);
    }

    if (ratio > 0) {
      final progress = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 16
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          startAngle: math.pi,
          endAngle: math.pi * 2,
          tileMode: TileMode.clamp,
          colors: [Color(0xFF76B7FA), Color(0xFFB4EBFF)],
        ).createShader(rect);
      canvas.drawArc(rect, _start, _sweep * ratio, false, progress);
    }
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) => oldDelegate.ratio != ratio;
}
