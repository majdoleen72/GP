
import 'package:flutter/material.dart';

/// RiderShield Dynamic Notched Navbar
///
/// Home      = 0
/// Emergency = 2
/// Connect   = 3

class RiderBottomNav extends StatefulWidget {
  const RiderBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  State<RiderBottomNav> createState() =>
      _RiderBottomNavState();
}

class _RiderBottomNavState extends State<RiderBottomNav>
    with SingleTickerProviderStateMixin {
  static const List<int> _pages = [0, 2, 3];

  static const List<String> _labels = [
    'Home',
    'Emergency',
    'Connect',
  ];

  static const List<IconData> _icons = [
    Icons.home_rounded,
    Icons.health_and_safety_outlined,
    Icons.bluetooth_rounded,
  ];

  static const List<Color> _colors = [
    Color(0xFF8ED5FF),
    Color(0xFFFF1680),
    Color(0xFFB59AFF),
  ];

  static const List<Color> _lightColors = [
    Color(0xFF248BC7),
    Color(0xFFD43B79),
    Color(0xFF8061C5),
  ];

  // Solid Frosted Ice navbar color.
  static const Color _lightBar = Color(0xFFA3BED3);
  static const Color _lightOutline = Color(0xFF789BB5);
  static const Color _lightInactive = Color(0xFF405E76);

  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 125),
      reverseDuration: const Duration(milliseconds: 230),
    );

    _pressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pressController.reverse();
      }
    });
  }

  void _onTabPressed(int index, bool reduceMotion) {
    if (reduceMotion) {
      _pressController.value = 0;
    } else {
      _pressController.forward(from: 0);
    }

    widget.onSelect(_pages[index]);
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight =
        Theme.of(context).brightness == Brightness.light;

    final reduceMotion =
        MediaQuery.disableAnimationsOf(context);

    final selected = _pages.indexOf(widget.selectedIndex);
    final target = selected < 0 ? 0 : selected;

    return SizedBox(
      height: 105,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final cellWidth = width / _pages.length;
          final targetX = cellWidth * (target + 0.5);

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(end: targetX),
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 430),
            curve: Curves.easeInOutCubic,
            builder: (context, centerX, child) {
              final activeColor = isLight
                  ? _lightColors[target]
                  : _colors[target];

              return AnimatedBuilder(
                animation: _pressController,
                builder: (context, child) {
                  final press = reduceMotion
                      ? 0.0
                      : Curves.easeInOut.transform(
                          _pressController.value,
                        );

                  // Original press-down animation.
                  final drop = 9.0 * press;

                  // Original slight compression.
                  final scale = 1.0 - (0.055 * press);

                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // ==================================
                      // SOLID NAVBAR BACKGROUND
                      // ==================================

                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _NavbarPainter(
                              centerX: centerX,
                              isLight: isLight,
                            ),
                          ),
                        ),
                      ),

                      // ==================================
                      // INACTIVE NAVIGATION ICONS
                      // ==================================

                      Positioned(
                        top: 38,
                        left: 0,
                        right: 0,
                        height: 67,
                        child: Row(
                          children: List.generate(
                            _pages.length,
                            (index) {
                              final isActive = index == target;

                              return Expanded(
                                child: Semantics(
                                  button: true,
                                  selected: selected == index,
                                  label: '${_labels[index]} tab',
                                  child: GestureDetector(
                                    behavior:
                                        HitTestBehavior.opaque,
                                    onTap: () => _onTabPressed(
                                      index,
                                      reduceMotion,
                                    ),
                                    child: Center(
                                      child: isActive
                                          ? const SizedBox.shrink()
                                          : Icon(
                                              _icons[index],
                                              size: 25,
                                              color: isLight
                                                  ? _lightInactive
                                                  : const Color(
                                                      0xFFABB3C1,
                                                    ),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // ==================================
                      // ACTIVE CIRCLE GLOW
                      // ==================================

                      Positioned(
                        left: centerX - 43,
                        top: -5 + drop,
                        width: 86,
                        height: 86,
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withValues(
                                    alpha:
                                        isLight ? 0.14 : 0.25,
                                  ),
                                  blurRadius: 30,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // ==================================
                      // ACTIVE CIRCLE WITH PRESS ANIMATION
                      // ==================================

                      Positioned(
                        left: centerX - 34,
                        top: 4 + drop,
                        width: 68,
                        height: 68,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _onTabPressed(
                            target,
                            reduceMotion,
                          ),
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isLight
                                    ? const Color(0xFFF8FCFF)
                                    : const Color(0xFF121523),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: activeColor,
                                  width: 3.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: activeColor.withValues(
                                      alpha:
                                          isLight ? 0.25 : 0.65,
                                    ),
                                    blurRadius: 19,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _icons[target],
                                size: 29,
                                color: isLight
                                    ? activeColor
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // ==================================
                      // ACTIVE LABEL
                      // ==================================

                      Positioned(
                        top: 79,
                        left: centerX - cellWidth / 2,
                        width: cellWidth,
                        child: IgnorePointer(
                          child: Text(
                            _labels[target],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: activeColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  color: activeColor.withValues(
                                    alpha:
                                        isLight ? 0.16 : 0.8,
                                  ),
                                  blurRadius:
                                      isLight ? 4 : 10,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ======================================================
// ORIGINAL NAVBAR GEOMETRY
// ======================================================

Path _createBaseBarPath(Size size) {
  const double barTop = 37;
  const double cornerRadius = 30;

  return Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          0,
          barTop,
          size.width,
          size.height - barTop,
        ),
        const Radius.circular(cornerRadius),
      ),
    );
}

Path _createNotchPath(double centerX) {
  return Path()
    ..addOval(
      Rect.fromCircle(
        center: Offset(centerX, 38),
        radius: 40,
      ),
    );
}

Path _createNavbarPath(Size size, double centerX) {
  final basePath = _createBaseBarPath(size);
  final notchPath = _createNotchPath(centerX);

  return Path.combine(
    PathOperation.difference,
    basePath,
    notchPath,
  );
}

// ======================================================
// CUSTOM NAVBAR PAINTER
// ======================================================

class _NavbarPainter extends CustomPainter {
  const _NavbarPainter({
    required this.centerX,
    required this.isLight,
  });

  final double centerX;
  final bool isLight;

  @override
  void paint(Canvas canvas, Size size) {
    final basePath = _createBaseBarPath(size);
    final notchPath = _createNotchPath(centerX);
    final barPath = _createNavbarPath(size, centerX);

    // =====================================
    // 1. SOLID BAR
    // =====================================

    canvas.drawPath(
      basePath,
      Paint()
        ..color = isLight
            ? _RiderBottomNavColors.lightBar
            : const Color(0xFF1A1D2B)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    // =====================================
    // 2. NOTCH BACKING
    // Light mode uses exactly the same solid
    // color as the main bar.
    // =====================================

    canvas.save();
    canvas.clipPath(basePath);

    canvas.drawPath(
      notchPath,
      Paint()
        ..color = isLight
            ? _RiderBottomNavColors.lightBar
            : const Color(0xFF121523)
        ..style = PaintingStyle.fill
        ..isAntiAlias = true,
    );

    canvas.restore();

    // =====================================
    // 3. OUTLINE
    // Light mode uses the base outline only,
    // preventing a second visible notch edge.
    // Dark mode retains the original path.
    // =====================================

    canvas.drawPath(
      isLight ? basePath : barPath,
      Paint()
        ..color = isLight
            ? _RiderBottomNavColors.lightBar
            : const Color(0x554B5A70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(
    covariant _NavbarPainter oldDelegate,
  ) {
    return oldDelegate.centerX != centerX ||
        oldDelegate.isLight != isLight;
  }
}

// ======================================================
// SOLID LIGHT NAVBAR PALETTE
// ======================================================

abstract final class _RiderBottomNavColors {
  static const Color lightBar = Color(0xFFA3BED3);
}
