import 'package:flutter/material.dart';
import '../app/app_scope.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';

class ConnectHelmetScreen extends StatelessWidget {
  // Profile tab was removed; kept optional so existing callers still compile.
  const ConnectHelmetScreen({super.key, this.openProfile});

  final VoidCallback? openProfile;

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final paired = state.demoHelmetConnected;
    final color = paired
        ? const Color(0xFF63D8A0)
        : const Color(0xFF83D3FF);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 115),
      children: [
        // Helmet hero
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: .26),
                  color.withValues(alpha: .04),
                ],
              ),
              border: Border.all(
                color: color.withValues(alpha: .55),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: .28),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: CustomPaint(
                size: const Size(124, 124),
                painter: _HelmetPainter(accent: color),
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        const Center(
          child: Text(
            'RiderShield Helmet',
            style: TextStyle(
              color: inkWhite,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -.3,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Status pill
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withValues(alpha: .5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  paired ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Reminder right after the photo, title and status
        const _ReminderCard(),

        const SizedBox(height: 18),

        // Pairing button (below the helmet photo and status)
        SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => state.pairDemoHelmet(!paired),
            style: FilledButton.styleFrom(
              backgroundColor: paired
                  ? const Color(0xFF8A2F3C)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: Icon(
              paired
                  ? Icons.link_off_rounded
                  : Icons.bluetooth_searching_rounded,
            ),
            label: Text(
              paired ? 'Disconnect' : 'Start Pairing',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: 26),

        const SectionCaption('How to connect'),

        SoftGlassCard(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
          child: _ConnectionSteps(paired: paired),
        ),
      ],
    );
  }
}

/// Draws a full-face motorcycle helmet (side view, facing right).
class _HelmetPainter extends CustomPainter {
  const _HelmetPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);
    const box = Rect.fromLTWH(0, 0, 200, 200);

    // Shell
    final shell = Path()
      ..moveTo(28, 138)
      ..cubicTo(18, 80, 55, 28, 108, 28)
      ..cubicTo(160, 28, 184, 72, 182, 112)
      ..lineTo(182, 140)
      ..cubicTo(182, 152, 172, 160, 160, 160)
      ..lineTo(62, 160)
      ..cubicTo(44, 160, 30, 152, 28, 138)
      ..close();

    // Soft shadow under the helmet
    canvas.drawOval(
      const Rect.fromLTWH(36, 164, 138, 14),
      Paint()
        ..color = const Color(0x33000000)
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          5,
        ),
    );

    canvas.drawPath(
      shell,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD6EEFF),
            Color(0xFF6FB4E8),
            Color(0xFF2F6FA8),
          ],
        ).createShader(box),
    );

    // Racing stripe + highlight clipped to the shell
    canvas.save();
    canvas.clipPath(shell);

    canvas.drawPath(
      Path()
        ..moveTo(40, 66)
        ..cubicTo(74, 38, 128, 26, 176, 50),
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawPath(
      Path()
        ..moveTo(44, 100)
        ..cubicTo(46, 70, 66, 46, 96, 38),
      Paint()
        ..color = Colors.white.withValues(alpha: .45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // Bottom rim
    canvas.drawPath(
      Path()
        ..moveTo(44, 154)
        ..lineTo(168, 154),
      Paint()
        ..color = const Color(0xFF1B4E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Visor
    final visor = Path()
      ..moveTo(102, 72)
      ..cubicTo(140, 66, 172, 78, 181, 104)
      ..lineTo(181, 118)
      ..cubicTo(150, 124, 118, 120, 98, 108)
      ..cubicTo(90, 96, 92, 78, 102, 72)
      ..close();

    canvas.drawPath(
      visor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B2236),
            Color(0xFF24527C),
          ],
        ).createShader(box),
    );

    canvas.drawPath(
      visor,
      Paint()
        ..color = Colors.white.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Visor glare
    canvas.drawPath(
      Path()
        ..moveTo(116, 80)
        ..cubicTo(134, 78, 152, 84, 162, 94),
      Paint()
        ..color = Colors.white.withValues(alpha: .5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // Chin vents
    final vent = Paint()
      ..color = const Color(0xFF1B4E7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    for (final y in [134.0, 142.0]) {
      canvas.drawLine(
        Offset(150, y),
        Offset(172, y),
        vent,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HelmetPainter old) =>
      old.accent != accent;
}

/// Reminder shown before pairing: Bluetooth, Raspberry Pi power, internet.
class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  static const _amber = Color(0xFFFFB45C);

  static const _items = [
    (Icons.bluetooth_rounded, 'Turn on Bluetooth'),
    (Icons.memory_rounded, 'Power on the Raspberry Pi'),
    (Icons.wifi_rounded, 'Turn on Wi-Fi or mobile data'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: _amber.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _amber.withValues(alpha: .55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: _amber),
              SizedBox(width: 8),
              Text(
                'Before you pair',
                style: TextStyle(
                  color: _amber,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in _items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(item.$1, size: 20, color: inkWhite),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item.$2,
                      style: const TextStyle(
                        color: inkWhite,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StepItem {
  const _StepItem(this.title, this.text);

  final String title;
  final String text;
}

/// Vertical, numbered steps in the order the user actually does them.
class _ConnectionSteps extends StatelessWidget {
  const _ConnectionSteps({required this.paired});

  final bool paired;

  static const _steps = [
    _StepItem(
      'Start pairing',
      'Tap "Start Pairing" to begin connecting your phone to RiderShield.',
    ),
    _StepItem(
      'Wait for connection',
      'Keep your phone close to the helmet while it connects.',
    ),
    _StepItem(
      'Ready to ride',
      'Once connected, RiderShield can monitor your ride and send alerts.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          _StepRow(
            number: i + 1,
            item: _steps[i],
            isLast: i == _steps.length - 1,
            status: paired
                ? _StepStatus.done
                : (i == 0
                    ? _StepStatus.active
                    : _StepStatus.pending),
          ),
      ],
    );
  }
}

enum _StepStatus { pending, active, done }

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.number,
    required this.item,
    required this.isLast,
    required this.status,
  });

  final int number;
  final _StepItem item;
  final bool isLast;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      _StepStatus.done => const Color(0xFF63D8A0),
      _StepStatus.active => const Color(0xFF83D3FF),
      _StepStatus.pending => const Color(0xFF607D92),
    };

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 38,
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(
                      alpha: status == _StepStatus.pending ? .07 : .18,
                    ),
                    border: Border.all(color: color, width: 2),
                    boxShadow: status == _StepStatus.active
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: .3),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  alignment: Alignment.center,
                  child: status == _StepStatus.done
                      ? Icon(
                          Icons.check_rounded,
                          color: color,
                          size: 20,
                        )
                      : Text(
                          '$number',
                          style: TextStyle(
                            color: color,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: color.withValues(alpha: .5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : 20,
                top: 2,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: status == _StepStatus.pending
                          ? softWhite
                          : inkWhite,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.text,
                    style: const TextStyle(
                      color: softWhite,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}