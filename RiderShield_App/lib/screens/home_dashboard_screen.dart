
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:glbview/glbview.dart';

import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';

// ======================================================
// RIDERSHIELD ORIGINAL DARK COLORS
// ======================================================

const Color _midnight = Color(0xFF071225);
const Color _deep = Color(0xFF0B1830);
const Color _surface = Color(0xFF142640);
const Color _accent = Color(0xFF9DD7FF);
const Color _electric = Color(0xFF69BFFF);
const Color _green = Color(0xFF63D8A0);

// ======================================================
// FROSTED ICE LIGHT COLORS
// ======================================================

const Color _iceBackground = Color(0xFFF4F9FF);
const Color _iceSurface = Color(0xFFFFFFFF);
const Color _iceGlass = Color(0xFFE5F2FC);
const Color _iceBorder = Color(0xFFD2E8F8);
const Color _iceText = Color(0xFF16364D);
const Color _iceMuted = Color(0xFF58758C);
const Color _iceAccent = Color(0xFF248BC7);
const Color _iceGreen = Color(0xFF17835D);

// Bottom outline only.
const Color _helmetOutline = Color.fromARGB(255, 164, 199, 232);

// LIGHT HELMET
const String _lightHelmetAsset =
    'assets/images/motorcycle_helmet_-_racing_helmet.glb';

// ORIGINAL DARK HELMET
const String _darkHelmetAsset =
    'assets/images/helmet.glb';

bool _isLight(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light;

Color _textColor(BuildContext context) =>
    _isLight(context) ? _iceText : inkWhite;

Color _secondaryColor(BuildContext context) =>
    _isLight(context) ? _iceMuted : softWhite;

Color _accentColor(BuildContext context) =>
    _isLight(context) ? _iceAccent : _accent;

const int _delayStep = 1;
const int _confirmSeconds = 5;

// ======================================================
// HOME DASHBOARD
// ======================================================

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({
    super.key,
    required this.openTab,
  });

  final ValueChanged<int> openTab;

  static const int _emergencyTab = 2;
  static const int _connectTab = 3;

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final isLight = _isLight(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final screenWidth = constraints.maxWidth;

        final horizontalPadding =
            screenWidth > 620 ? 34.0 : 20.0;

        final topHeight =
            (screenHeight * 0.55).clamp(330.0, 430.0);

        final helmetHeight =
            (screenHeight * 0.25).clamp(155.0, 215.0);

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // ==========================================
            // HELMET TOP SECTION
            // ==========================================

            _GlassTopSection(
              height: topHeight,
              horizontalPadding: horizontalPadding,
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ConnectionStatus(
                      connected: state.demoHelmetConnected,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Expanded(
                    child: _HomeHelmet3D(
                      height: helmetHeight,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    'RiderShield Helmet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isLight ? _iceText : inkWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    state.demoHelmetConnected
                        ? 'Your helmet is connected'
                        : 'Connect your helmet to get started',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isLight
                          ? _iceMuted
                          : const Color(0xFFD0E3F0),
                      fontSize: 12.5,
                    ),
                  ),

                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 51,
                    child: FilledButton(
                      onPressed: () => openTab(_connectTab),
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            isLight ? _iceAccent : _accent,
                        foregroundColor:
                            isLight ? Colors.white : _deep,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Icon(
                            state.demoHelmetConnected
                                ? Icons.settings_bluetooth_rounded
                                : Icons.bluetooth_searching_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 9),
                          Flexible(
                            child: Text(
                              state.demoHelmetConnected
                                  ? 'Manage Helmet Connection'
                                  : 'Connect Helmet to Get Started',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // ORIGINAL BOTTOM SECTION
            // UNCHANGED
            // ==========================================

            Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight:
                    (screenHeight - topHeight).clamp(
                  205.0,
                  double.infinity,
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                25,
                horizontalPadding,
                135,
              ),
              color: Colors.transparent,
              child: SizedBox(
                height: 155,
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(
                      child: _SosDelayCard(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sosCard(
                        context,
                        state.contacts,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ====================================================
  // SOS ACTION - ORIGINAL BEHAVIOR
  // ====================================================

  Future<void> _startSos(
    BuildContext context,
    List<EmergencyContact> contacts,
  ) async {
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Add an emergency contact first.',
          ),
        ),
      );

      openTab(_emergencyTab);
      return;
    }

    final sendToAll = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SosConfirmDialog(
        count: contacts.length,
      ),
    );

    if (sendToAll == null || !context.mounted) {
      return;
    }

    if (sendToAll) {
      _sendSos(context, contacts);
      return;
    }

    final chosen =
        await showModalBottomSheet<List<EmergencyContact>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _isLight(context)
          ? _iceSurface
          : const Color(0xFF173550),
      builder: (_) => _ContactPicker(
        contacts: contacts,
      ),
    );

    if (chosen == null ||
        chosen.isEmpty ||
        !context.mounted) {
      return;
    }

    _sendSos(context, chosen);
  }

  void _sendSos(
    BuildContext context,
    List<EmergencyContact> to,
  ) {
    final names =
        to.map((contact) => contact.name).join(', ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'SOS request confirmed for ${to.length} contact(s): $names. Messages have not been sent.',
        ),
      ),
    );
  }

  // ====================================================
  // SOS CARD - ORIGINAL DESIGN
  // ====================================================

  Widget _sosCard(
    BuildContext context,
    List<EmergencyContact> contacts,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _startSos(context, contacts),
        borderRadius: BorderRadius.circular(26),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFD43D46),
                Color(0xFFAA2B38),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(
                        alpha: 0.20,
                      ),
                    ),
                    child: const Icon(
                      Icons.sos_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.north_east_rounded,
                    color: Colors.white70,
                    size: 17,
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'SOS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              const Text(
                'Tap to start SOS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// GLASS TOP SECTION
//
// LIGHT:
// - TRANSPARENT UNIFORM BACKGROUND
// - NO GRADIENT
// - NO DARK LINE AT TOP
// - BOTTOM OUTLINE + BOTTOM CORNERS ONLY
//
// DARK:
// - ORIGINAL GRADIENT AND COLORS
//
// CONTENT IS ABOVE DECORATIVE LAYERS.
// ======================================================

class _GlassTopSection extends StatelessWidget {
  const _GlassTopSection({
    required this.height,
    required this.horizontalPadding,
    required this.child,
  });

  final double height;
  final double horizontalPadding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);

    const radius = BorderRadius.only(
      bottomLeft: Radius.circular(38),
      bottomRight: Radius.circular(38),
    );

    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ============================================
          // BACKGROUND ONLY
          // ============================================

          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: isLight
                          ? const Color(0x23647E98)
                          : _midnight.withValues(
                              alpha: 0.32,
                            ),
                      blurRadius: 23,
                      spreadRadius: -7,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      // Light: transparent, uniform.
                      color: isLight
                          ? const Color.fromARGB(22, 150, 167, 190)
                          : null,

                      // Dark: original gradient.
                      gradient: isLight
                          ? null
                          : LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [
                                0.0,
                                0.48,
                                0.78,
                                1.0,
                              ],
                              colors: [
                                const Color(0xFF113252)
                                    .withValues(
                                  alpha: 0.82,
                                ),
                                const Color(0xFF10304C)
                                    .withValues(
                                  alpha: 0.92,
                                ),
                                const Color(0xFF0D2740)
                                    .withValues(
                                  alpha: 0.96,
                                ),
                                _midnight.withValues(
                                  alpha: 0.98,
                                ),
                              ],
                            ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),

          // ============================================
          // ORIGINAL ANIMATED SIDE CIRCLES
          // ============================================

          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: radius,
                child: const _FloatingGlassShapes(),
              ),
            ),
          ),

          // ============================================
          // ORIGINAL DARK BOTTOM SHADE
          // No gradient in Light Mode.
          // ============================================

          if (!isLight)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 34,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _deep.withValues(alpha: 0.14),
                        _midnight.withValues(alpha: 0.34),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // ============================================
          // BOTTOM OUTLINE ONLY
          // No top or straight side borders.
          // ============================================

          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _HelmetPanelOutlinePainter(
                  isLight: isLight,
                ),
              ),
            ),
          ),

          // ============================================
          // HELMET + CONTENT ALWAYS ON TOP
          // ============================================

          Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              10,
              horizontalPadding,
              30,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

// ======================================================
// BOTTOM OUTLINE PAINTER
// ======================================================

class _HelmetPanelOutlinePainter extends CustomPainter {
  const _HelmetPanelOutlinePainter({
    required this.isLight,
  });

  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final paint = Paint()
      ..color = isLight
          ? _helmetOutline
          : _midnight.withValues(alpha: 0.75)
      ..strokeWidth = isLight ? 2.0 : 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    const radius = 38.0;

    final bottom = size.height - 1;
    const left = 1.0;
    final right = size.width - 1;

    // Bottom corners and bottom horizontal edge.
    // No top line and no straight side lines.

    final path = Path()
      ..moveTo(left, bottom - radius)
      ..arcToPoint(
        Offset(left + radius, bottom),
        radius: const Radius.circular(radius),
        clockwise: false,
      )
      ..lineTo(right - radius, bottom)
      ..arcToPoint(
        Offset(right, bottom - radius),
        radius: const Radius.circular(radius),
        clockwise: false,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(
    covariant _HelmetPanelOutlinePainter oldDelegate,
  ) {
    return oldDelegate.isLight != isLight;
  }
}

// ======================================================
// TRANSLUCENT SIDE CIRCLES
// ORIGINAL MOTION PRESERVED
// ======================================================

class _FloatingGlassShapes extends StatefulWidget {
  const _FloatingGlassShapes();

  @override
  State<_FloatingGlassShapes> createState() =>
      _FloatingGlassShapesState();
}

class _FloatingGlassShapesState
    extends State<_FloatingGlassShapes>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SoftSideCirclesPainter(
        animation: _controller,
        isLight: _isLight(context),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _SoftSideCirclesPainter extends CustomPainter {
  _SoftSideCirclesPainter({
    required this.animation,
    required this.isLight,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final w = size.width;
    final h = size.height;
    final phase = animation.value * math.pi * 2;

    _drawGlassCircle(
      canvas,
      center: Offset(
        -19,
        h * 0.31 + math.sin(phase) * 4,
      ),
      radius: 57,
      opacity: 0.15,
    );

    _drawGlassCircle(
      canvas,
      center: Offset(
        45,
        h * 0.49 + math.cos(phase) * 3,
      ),
      radius: 19,
      opacity: 0.17,
    );

    _drawGlassCircle(
      canvas,
      center: Offset(
        w + 21,
        h * 0.37 + math.cos(phase) * 4,
      ),
      radius: 64,
      opacity: 0.14,
    );

    _drawGlassCircle(
      canvas,
      center: Offset(
        w - 39,
        h * 0.56 + math.sin(phase) * 3,
      ),
      radius: 19,
      opacity: 0.17,
    );

    _drawGlassCircle(
      canvas,
      center: Offset(
        1,
        h * 0.66 + math.sin(phase + 0.7) * 3,
      ),
      radius: 27,
      opacity: 0.10,
    );
  }

  void _drawGlassCircle(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double opacity,
  }) {
    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final haloColor =
        isLight ? _iceAccent : _electric;

    final middleColor =
        isLight ? const Color(0xFF80C9EC) : _accent;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = haloColor.withValues(
          alpha: opacity * 0.21,
        )
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          10,
        ),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.38, -0.40),
          radius: 1.0,
          colors: [
            Colors.white.withValues(
              alpha: isLight
                  ? opacity * 0.96
                  : opacity * 0.80,
            ),
            middleColor.withValues(
              alpha: opacity * 0.42,
            ),
            haloColor.withValues(
              alpha: opacity * 0.08,
            ),
          ],
          stops: const [
            0.0,
            0.53,
            1.0,
          ],
        ).createShader(rect),
    );

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.85
        ..color = (isLight
                ? _iceAccent
                : Colors.white)
            .withValues(
          alpha: isLight
              ? opacity * 0.75
              : opacity * 0.85,
        ),
    );
  }

  @override
  bool shouldRepaint(
    covariant _SoftSideCirclesPainter oldDelegate,
  ) =>
      oldDelegate.animation != animation ||
      oldDelegate.isLight != isLight;
}

// ======================================================
// CONNECTION STATUS
// ======================================================

class _ConnectionStatus extends StatelessWidget {
  const _ConnectionStatus({
    required this.connected,
  });

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);

    final color = connected
        ? (isLight ? _iceGreen : _green)
        : (isLight ? _iceAccent : _accent);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.white.withValues(alpha: 0.78)
            : _deep.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            connected
                ? 'Connected'
                : 'Not connected',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ======================================================
// 3D HELMET
//
// DARK: ORIGINAL HELMET
// LIGHT: NEW RACING HELMET
//
// MORE CAMERA DISTANCE FOR LIGHT HELMET TO
// REDUCE CLIPPING WHILE ROTATING.
// ======================================================

class _HomeHelmet3D extends StatelessWidget {
  const _HomeHelmet3D({
    required this.height,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);

    final helmetAsset = isLight
        ? _lightHelmetAsset
        : _darkHelmetAsset;

    return LayoutBuilder(
      builder: (context, constraints) {
        final modelWidth =
            constraints.maxWidth.clamp(220.0, 380.0);

        return Center(
          child: SizedBox(
            width: modelWidth,
            height: height,
            child: GlbView.asset(
              helmetAsset,

              key: ValueKey<String>(helmetAsset),

              width: modelWidth,
              height: height,

              autoRotate: true,
              autoRotateDegreesPerSecond: 18,
              gestures: GlbGesture.orbit,

              initialYaw: 32,
              initialPitch: 10,

              // Light helmet has more room to rotate.
              initialDistance: isLight ? 2.6 : 2.2,

              glossy: true,

              placeholder: Center(
                child: CircularProgressIndicator(
                  color: _accentColor(context),
                  strokeWidth: 2,
                ),
              ),

              errorBuilder: (context, error) {
                debugPrint(
                  'Home helmet 3D error: $error',
                );

                return Center(
                  child: Text(
                    'Unable to load 3D helmet',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _textColor(context),
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ======================================================
// SOS COUNTDOWN CARD
// ORIGINAL LAYOUT AND COLORS PRESERVED
// ======================================================

class _SosDelayCard extends StatefulWidget {
  const _SosDelayCard();

  @override
  State<_SosDelayCard> createState() =>
      _SosDelayCardState();
}

class _SosDelayCardState
    extends State<_SosDelayCard> {
  Widget _roundButton(
    IconData icon,
    VoidCallback? onTap,
    bool isLight,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 32,
        width: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isLight
              ? (onTap == null
                  ? _iceGlass
                  : const Color(0xFFD0E9FA))
              : (onTap == null
                  ? const Color(0xFF7AA9CF)
                      .withValues(alpha: 0.28)
                  : const Color.fromARGB(
                      255,
                      128,
                      176,
                      210,
                    )),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isLight
              ? (onTap == null
                  ? _iceMuted
                  : _iceAccent)
              : const Color.fromARGB(
                  255,
                  246,
                  246,
                  247,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);

    return SoftGlassCard(
      light: isLight,
      padding: const EdgeInsets.all(15),
      child: ValueListenableBuilder<int>(
        valueListenable:
            SosSettings.delaySeconds,
        builder: (context, seconds, _) {
          return Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: isLight
                        ? _iceAccent
                        : const Color.fromARGB(
                            255,
                            253,
                            254,
                            254,
                          ),
                    size: 24,
                  ),
                  const Spacer(),
                  _roundButton(
                    Icons.remove_rounded,
                    seconds > SosSettings.minDelay
                        ? () {
                            SosSettings
                                .delaySeconds.value =
                                seconds - _delayStep;
                          }
                        : null,
                    isLight,
                  ),
                  const SizedBox(width: 6),
                  _roundButton(
                    Icons.add_rounded,
                    seconds < SosSettings.maxDelay
                        ? () {
                            SosSettings
                                .delaySeconds.value =
                                seconds + _delayStep;
                          }
                        : null,
                    isLight,
                  ),
                ],
              ),

              const Spacer(),

              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.baseline,
                textBaseline:
                    TextBaseline.alphabetic,
                children: [
                  Text(
                    '$seconds',
                    style: TextStyle(
                      color: isLight
                          ? _iceText
                          : const Color.fromARGB(
                              255,
                              236,
                              247,
                              255,
                            ),
                      fontSize: 34,
                      fontWeight:
                          FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'sec',
                    style: TextStyle(
                      color: isLight
                          ? _iceText
                          : const Color.fromARGB(
                              255,
                              236,
                              247,
                              255,
                            ),
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 3),

              Text(
                'Set SOS countdown',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isLight
                      ? _iceMuted
                      : const Color(0xFFB7CCDB),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ======================================================
// SOS CONFIRMATION DIALOG
// ======================================================

class _SosConfirmDialog extends StatefulWidget {
  const _SosConfirmDialog({
    required this.count,
  });

  final int count;

  @override
  State<_SosConfirmDialog> createState() =>
      _SosConfirmDialogState();
}

class _SosConfirmDialogState
    extends State<_SosConfirmDialog> {
  int _left = _confirmSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_left <= 1) {
          timer.cancel();
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _left--;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);

    return AlertDialog(
      backgroundColor:
          isLight ? _iceSurface : _deep,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      title: Text(
        'Send SOS?',
        style: TextStyle(
          color:
              isLight ? _iceText : Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            'Do you accept to send an SOS to all your emergency contacts (${widget.count})?',
            style: TextStyle(
              color: isLight
                  ? _iceMuted
                  : const Color(0xFFD1DFEF),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _left / _confirmSeconds,
              minHeight: 6,
              color: const Color(0xFFE5484D),
              backgroundColor: isLight
                  ? _iceGlass
                  : Colors.white12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No answer? Sending to all in $_left s',
            style: TextStyle(
              color: isLight
                  ? _iceAccent
                  : const Color(0xFFBDE5FF),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(false),
          child: Text(
            'No, choose contacts',
            style: TextStyle(
              color: isLight
                  ? _iceAccent
                  : const Color(0xFFBDE5FF),
            ),
          ),
        ),
        FilledButton(
          onPressed: () =>
              Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor:
                const Color(0xFFE5484D),
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'Yes, send to all',
          ),
        ),
      ],
    );
  }
}

// ======================================================
// CONTACT PICKER
// ORIGINAL FUNCTIONALITY PRESERVED
// ======================================================

class _ContactPicker extends StatefulWidget {
  const _ContactPicker({
    required this.contacts,
  });

  final List<EmergencyContact> contacts;

  @override
  State<_ContactPicker> createState() =>
      _ContactPickerState();
}

class _ContactPickerState
    extends State<_ContactPicker> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          0,
          20,
          22,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Choose who gets the SOS',
              style: TextStyle(
                color: isLight
                    ? _iceText
                    : inkWhite,
                fontSize: 21,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              'Select one or more emergency contacts.',
              style: TextStyle(
                color: isLight
                    ? _iceMuted
                    : softWhite,
                fontSize: 12.5,
              ),
            ),

            const SizedBox(height: 10),

            for (final contact in widget.contacts)
              CheckboxListTile(
                value: _selected.contains(
                  contact.id,
                ),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selected.add(contact.id);
                    } else {
                      _selected.remove(
                        contact.id,
                      );
                    }
                  });
                },
                contentPadding:
                    EdgeInsets.zero,
                controlAffinity:
                    ListTileControlAffinity.trailing,
                activeColor:
                    const Color(0xFFE5484D),
                title: Text(
                  contact.name,
                  style: TextStyle(
                    color: isLight
                        ? _iceText
                        : inkWhite,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${contact.relationship} • ${contact.phone}',
                  style: TextStyle(
                    color: isLight
                        ? _iceMuted
                        : softWhite,
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () {
                        Navigator.of(
                          context,
                        ).pop(
                          widget.contacts
                              .where(
                                (contact) =>
                                    _selected.contains(
                                  contact.id,
                                ),
                              )
                              .toList(),
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFE5484D),
                  foregroundColor:
                      Colors.white,
                ),
                icon: const Icon(
                  Icons.sos_rounded,
                ),
                label: Text(
                  _selected.isEmpty
                      ? 'Select at least one contact'
                      : 'Send SOS to ${_selected.length}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
