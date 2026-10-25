import 'dart:ui';
import 'package:flutter/material.dart';

/// Floating dynamic glass tab bar inspired by the supplied reference.
/// Pure Flutter animation, no dependency or platform-specific code.
class RiderBottomNav extends StatelessWidget {
  const RiderBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const labels = ['Home', 'Reports', 'Emergency', 'Connect', 'Profile'];
  static const icons = [
    Icons.home_rounded,
    Icons.insert_chart_outlined_rounded,
    Icons.health_and_safety_outlined,
    Icons.bluetooth_rounded,
    Icons.person_outline_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final active = selectedIndex >= 0 && selectedIndex < 5 ? selectedIndex : 0;
    final activeColor = active == 2
        ? const Color(0xFFFF848A)
        : const Color(0xFF8ED5FF);

    return SizedBox(
      height: 80,
      child: LayoutBuilder(builder: (context, bounds) {
        final cell = bounds.maxWidth / 5;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0, right: 0, bottom: 0, height: 59,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 19, sigmaY: 19),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: const Color(0xD816293F),
                      border: Border.all(color: const Color(0x558CC5E9)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x29000000), blurRadius: 18,
                          offset: Offset(0, 7)),
                      ],
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            // The entire cell is a tap target. The selected orb cannot
            // intercept taps because it is wrapped with IgnorePointer.
            Positioned.fill(
              child: Row(
                children: List.generate(5, (index) {
                  final isSelected = index == active;
                  return Expanded(
                    child: Semantics(
                      button: true,
                      selected: isSelected,
                      label: '${labels[index]} tab',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onSelect(index),
                        child: Column(
                          children: [
                            SizedBox(height: isSelected ? 59 : 34),
                            if (!isSelected)
                              Icon(icons[index], size: 21,
                                color: index == 2
                                  ? const Color(0xFFFFB7BA)
                                  : const Color(0xFFE0EBF5)),
                            SizedBox(height: isSelected ? 4 : 3),
                            Text(labels[index],
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              softWrap: false,
                              style: TextStyle(
                                fontSize: 10.2,
                                height: 1.15,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? activeColor : const Color(0xFFE0EBF5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            AnimatedPositioned(
              duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 370),
              curve: Curves.easeOutBack,
              left: cell * active + (cell - 55) / 2,
              top: 0,
              width: 55,
              height: 55,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF14263B),
                    shape: BoxShape.circle,
                    border: Border.all(color: activeColor, width: 3),
                    boxShadow: [
                      BoxShadow(color: activeColor.withValues(alpha: .32),
                        blurRadius: 17, spreadRadius: 1),
                      const BoxShadow(color: Color(0x32000000),
                        blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: Icon(icons[active], color: Colors.white, size: 25),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
