
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetBundle;
import 'package:glbview/glbview.dart';

import '../app/app_scope.dart';
import '../widgets/screen_parts.dart';

// ======================================================
// CONNECT HELMET THEME
// ======================================================

class _ConnectTheme {
  static bool light(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color text(BuildContext context) =>
      light(context)
          ? const Color(0xFF16364D)
          : inkWhite;

  static Color muted(BuildContext context) =>
      light(context)
          ? const Color(0xFF58758C)
          : softWhite;

  static Color blue(BuildContext context) =>
      light(context)
          ? const Color(0xFF248BC7)
          : const Color(0xFF91D8FF);

  static Color green(BuildContext context) =>
      light(context)
          ? const Color(0xFF17835D)
          : const Color(0xFF63D8A0);

  static Color idle(BuildContext context) =>
      light(context)
          ? const Color(0xFF68889D)
          : const Color(0xFF607D92);
}

// ======================================================
// CONNECT HELMET SCREEN
// Compact layout - pairing button visible before scrolling
// ======================================================

class ConnectHelmetScreen extends StatefulWidget {
  const ConnectHelmetScreen({
    super.key,
    this.openProfile,
  });

  final VoidCallback? openProfile;

  @override
  State<ConnectHelmetScreen> createState() =>
      _ConnectHelmetScreenState();
}

class _ConnectHelmetScreenState
    extends State<ConnectHelmetScreen>
    with SingleTickerProviderStateMixin {
  static const Color blue = Color(0xFF91D8FF);
  static const Color green = Color(0xFF63D8A0);

  late final AnimationController _progressController;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _progressController.addStatusListener(
      _onAnimationStatus,
    );
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted) {
      return;
    }

    // Original demo pairing behavior preserved.
    // This is not a real BLE or Wi-Fi connection.
    RiderScope.of(context).pairDemoHelmet(true);

    setState(() {
      _isConnecting = false;
    });
  }

  void _handlePairing() {
    if (_isConnecting) return;

    final state = RiderScope.of(context);
    final paired = state.demoHelmetConnected;

    if (paired) {
      _progressController.reset();
      state.pairDemoHelmet(false);

      setState(() {
        _isConnecting = false;
      });

      return;
    }

    setState(() {
      _isConnecting = true;
    });

    _progressController.forward(from: 0);
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(
      _onAnimationStatus,
    );

    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final paired = state.demoHelmetConnected;

    final isLight = _ConnectTheme.light(context);

    final accent = paired
        ? _ConnectTheme.green(context)
        : _ConnectTheme.blue(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 690;

        final heroHeight = compact ? 188.0 : 220.0;
        final circleSize = compact ? 176.0 : 204.0;
        final modelSize = compact ? 198.0 : 230.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            135,
          ),
          children: [
            // ==========================================
            // CONNECTION PROGRESS
            // ==========================================

            _AnimatedConnectionProgress(
              animation: _progressController,
              connected: paired,
            ),

            SizedBox(height: compact ? 5 : 9),

            // ==========================================
            // 3D HELMET
            // ==========================================

            _HelmetHero(
              accent: accent,
              height: heroHeight,
              circleSize: circleSize,
              modelSize: modelSize,
            ),

            const SizedBox(height: 2),

            // ==========================================
            // HELMET TITLE
            // ==========================================

            Text(
              'RiderShield Helmet',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _ConnectTheme.text(context),
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 9),

            // ==========================================
            // CONNECTION STATUS
            // ==========================================

            Center(
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 250,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(
                    alpha: isLight ? 0.09 : 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(30),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.55),
                    width: 1.3,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isConnecting
                          ? 'Connecting...'
                          : paired
                              ? 'Connected'
                              : 'Not connected',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: compact ? 13 : 17),

            // ==========================================
            // PRIMARY PAIRING BUTTON
            // ==========================================

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed:
                    _isConnecting ? null : _handlePairing,
                icon: _isConnecting
                    ? SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: isLight
                              ? Colors.white
                              : const Color(0xFF10354D),
                        ),
                      )
                    : Icon(
                        paired
                            ? Icons.link_off_rounded
                            : Icons.bluetooth_searching_rounded,
                        size: 23,
                      ),
                label: Text(
                  _isConnecting
                      ? 'Connecting...'
                      : paired
                          ? 'Disconnect'
                          : 'Start Pairing',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: paired
                      ? const Color(0xFFAE4056)
                      : isLight
                          ? const Color(0xFF248BC7)
                          : const Color(0xFF9BCFFF),
                  disabledBackgroundColor: isLight
                      ? const Color(0xFF74B5D9)
                      : const Color(0xFF9BCFFF),
                  disabledForegroundColor: isLight
                      ? Colors.white
                      : const Color(0xFF10354D),
                  foregroundColor: paired
                      ? Colors.white
                      : isLight
                          ? Colors.white
                          : const Color(0xFF10354D),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // BEFORE YOU PAIR
            // ==========================================

            const _ReminderCard(),

            const SizedBox(height: 24),

            // ==========================================
            // HOW TO CONNECT
            // ==========================================

            const SectionCaption('How to connect'),

            const SizedBox(height: 8),

            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 4,
              ),
              child: _ConnectionSteps(),
            ),
          ],
        );
      },
    );
  }
}

// ======================================================
// CONNECTION PROGRESS
// ======================================================

class _AnimatedConnectionProgress extends StatelessWidget {
  const _AnimatedConnectionProgress({
    required this.animation,
    required this.connected,
  });

  final Animation<double> animation;
  final bool connected;

  static const Color green = Color(0xFF63D8A0);
  static const Color muted = Color(0xFF607D92);

  static const _items = [
    (
      Icons.smartphone_rounded,
      'Start pairing',
    ),
    (
      Icons.sports_motorsports_outlined,
      'Wait for connection',
    ),
    (
      Icons.check_circle_outline_rounded,
      'Ready to ride',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLight = _ConnectTheme.light(context);

    final progressGreen = isLight
        ? _ConnectTheme.green(context)
        : green;

    final progressMuted = isLight
        ? _ConnectTheme.idle(context)
        : muted;

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress =
            connected ? 1.0 : animation.value;

        return Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < _items.length; i++) ...[
              if (i > 0)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 24,
                      left: 5,
                      right: 5,
                    ),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: progress >= i / 3
                            ? progressGreen
                            : progressMuted.withValues(
                                alpha: 0.5,
                              ),
                        borderRadius:
                            BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

              _ProgressCircle(
                icon: _items[i].$1,
                label: _items[i].$2,
                isDone: progress >= (i + 1) / 3,
                isActive: progress > i / 3 &&
                    progress < (i + 1) / 3,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ======================================================
// PROGRESS CIRCLE
// ======================================================

class _ProgressCircle extends StatelessWidget {
  const _ProgressCircle({
    required this.icon,
    required this.label,
    required this.isDone,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isDone;
  final bool isActive;

  static const Color blue = Color(0xFF91D8FF);
  static const Color green = Color(0xFF63D8A0);
  static const Color muted = Color(0xFF607D92);

  @override
  Widget build(BuildContext context) {
    final isLight = _ConnectTheme.light(context);

    final circleBlue = isLight
        ? _ConnectTheme.blue(context)
        : blue;

    final circleGreen = isLight
        ? _ConnectTheme.green(context)
        : green;

    final circleMuted = isLight
        ? _ConnectTheme.idle(context)
        : muted;

    final color = isDone
        ? circleGreen
        : isActive
            ? circleBlue
            : circleMuted;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(
            milliseconds: 250,
          ),
          width: 49,
          height: 49,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.13),
            border: Border.all(
              color: color,
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: circleBlue.withValues(
                        alpha: isLight ? 0.15 : 0.3,
                      ),
                      blurRadius: 14,
                    ),
                  ]
                : isDone
                    ? [
                        BoxShadow(
                          color: circleGreen.withValues(
                            alpha: 0.15,
                          ),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 200,
            ),
            child: Icon(
              isDone
                  ? Icons.check_rounded
                  : icon,
              key: ValueKey(isDone),
              color: color,
              size: 23,
            ),
          ),
        ),

        const SizedBox(height: 6),

        Text(
          label,
          style: TextStyle(
            color: isDone
                ? circleGreen
                : _ConnectTheme.text(context),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ======================================================
// 3D HELMET - COMPACT HERO
// ======================================================

class _HelmetHero extends StatelessWidget {
  const _HelmetHero({
    required this.accent,
    required this.height,
    required this.circleSize,
    required this.modelSize,
  });

  final Color accent;
  final double height;
  final double circleSize;
  final double modelSize;

  static const String _darkHelmet = 'assets/images/helmet.glb';

  // Supported names for the light-mode model. No other UI is changed.
  static const List<String> _lightHelmets = [
    'assets/images/motorcycle_helmet_-_racing_helmet(1).glb',
    'assets/images/motorcycle_helmet_-_racing_helmet.glb',
    'assets/images/helmet_light.glb',
  ];

  Future<String> _resolveHelmet(AssetBundle bundle, bool isLight) async {
    if (!isLight) return _darkHelmet;

    for (final path in _lightHelmets) {
      try {
        // An asset must be listed in pubspec.yaml, not just present on disk.
        await bundle.load(path);
        return path;
      } catch (_) {
        // Try another supported filename without changing the rest of the UI.
      }
    }

    debugPrint(
      'Connect Helmet: Light helmet GLB is missing from Flutter assets. '
      'Add the model to assets/images/ and declare the folder in pubspec.yaml.',
    );
    return _darkHelmet;
  }

  Widget _model(BuildContext context, String assetPath, {bool fallback = true}) {
    return GlbView.asset(
      assetPath,
      key: ValueKey<String>('connect_helmet:$assetPath'),
      width: modelSize,
      height: height,
      autoRotate: true,
      autoRotateDegreesPerSecond: 18,
      gestures: GlbGesture.orbit,
      initialYaw: 35,
      initialPitch: 10,
      initialDistance: 2.9,
      glossy: true,
      placeholder: Center(
        child: CircularProgressIndicator(
          color: _ConnectTheme.blue(context),
          strokeWidth: 2,
        ),
      ),
      errorBuilder: (context, error) {
        debugPrint('Connect Helmet: Cannot render $assetPath: $error');

        // Keep the helmet visible even when the replacement GLB is invalid.
        if (fallback && assetPath != _darkHelmet) {
          return _model(context, _darkHelmet, fallback: false);
        }

        return Center(
          child: Text(
            'Unable to load 3D helmet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _ConnectTheme.text(context),
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _ConnectTheme.light(context);

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ==========================================
          // HELMET CIRCLE (UNCHANGED)
          // ==========================================

          Container(
            width: circleSize,
            height: circleSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withValues(
                    alpha: isLight ? 0.14 : 0.25,
                  ),
                  accent.withValues(
                    alpha: isLight ? 0.035 : 0.07,
                  ),
                  Colors.transparent,
                ],
              ),
              border: Border.all(
                color: accent.withValues(
                  alpha: isLight ? 0.40 : 0.60,
                ),
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(
                    alpha: isLight ? 0.08 : 0.16,
                  ),
                  blurRadius: 28,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // ==========================================
          // 3D HELMET (LIGHT/DARK MODEL ONLY)
          // ==========================================

          FutureBuilder<String>(
            future: _resolveHelmet(DefaultAssetBundle.of(context), isLight),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return Center(
                  child: CircularProgressIndicator(
                    color: _ConnectTheme.blue(context),
                    strokeWidth: 2,
                  ),
                );
              }
              return _model(context, snapshot.data ?? _darkHelmet);
            },
          ),
        ],
      ),
    );
  }
}

// ======================================================
// BEFORE YOU PAIR - REMINDER CARD
// ======================================================

class _ReminderCard extends StatelessWidget {
  const _ReminderCard();

  static const _items = [
    (
      Icons.bluetooth_rounded,
      'Turn on\nBluetooth',
    ),
    (
      Icons.memory_rounded,
      'Power on\nRaspberry Pi',
    ),
    (
      Icons.wifi_rounded,
      'Turn on\nWi-Fi',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLight = _ConnectTheme.light(context);

    final reminderColor = isLight
        ? const Color(0xFFAA6714)
        : const Color(0xFFFFB45C);

    return Container(
      padding: const EdgeInsets.fromLTRB(
        12,
        12,
        12,
        13,
      ),
      decoration: BoxDecoration(
        color: isLight
            ? const Color(0xFFFFF8E9)
            : const Color(0xFF263F50)
                .withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: reminderColor.withValues(
            alpha: 0.55,
          ),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: reminderColor,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                'Before you pair',
                style: TextStyle(
                  color: reminderColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              for (int i = 0; i < _items.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: 46,
                    color: isLight
                        ? const Color(0xFFDCCBA7)
                        : const Color(0xFF68869B)
                            .withValues(alpha: 0.35),
                  ),

                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        _items[i].$1,
                        size: 21,
                        color: _ConnectTheme.text(context),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _items[i].$2,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _ConnectTheme.text(context),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ======================================================
// HOW TO CONNECT - NO BACKGROUND CARD
// ======================================================

class _ConnectionSteps extends StatelessWidget {
  const _ConnectionSteps();

  static const _steps = [
    (
      Icons.smartphone_rounded,
      'Start pairing',
      'Tap "Start Pairing" to begin connecting your phone to RiderShield.',
    ),
    (
      Icons.sports_motorsports_outlined,
      'Wait for connection',
      'Keep your phone close to the helmet while it connects.',
    ),
    (
      Icons.check_circle_outline_rounded,
      'Ready to ride',
      'Once connected, RiderShield can monitor your ride and send alerts.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isLight = _ConnectTheme.light(context);

    return Column(
      children: [
        for (int i = 0; i < _steps.length; i++) ...[
          _ConnectionStepRow(
            number: i + 1,
            icon: _steps[i].$1,
            title: _steps[i].$2,
            description: _steps[i].$3,
          ),

          if (i != _steps.length - 1)
            Padding(
              padding: const EdgeInsets.only(
                left: 23,
                top: 3,
                bottom: 3,
              ),
              child: Container(
                height: 1,
                color: isLight
                    ? const Color(0xFFD2E8F8)
                    : const Color(0xFF65849A)
                        .withValues(alpha: 0.25),
              ),
            ),
        ],
      ],
    );
  }
}

// ======================================================
// INSTRUCTION ROW
// ======================================================

class _ConnectionStepRow extends StatelessWidget {
  const _ConnectionStepRow({
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
  });

  final int number;
  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final isLight = _ConnectTheme.light(context);

    final color = isLight
        ? const Color(0xFF248BC7)
        : const Color(0xFF83D3FF);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.14),
              border: Border.all(
                color: color,
                width: 1.8,
              ),
            ),
            child: Text(
              '$number',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          const SizedBox(width: 11),

          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),

          const SizedBox(width: 11),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _ConnectTheme.text(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: _ConnectTheme.muted(context),
                    fontSize: 12,
                    height: 1.35,
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
