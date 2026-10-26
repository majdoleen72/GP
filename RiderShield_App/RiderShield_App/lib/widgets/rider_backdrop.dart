
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class RiderBackdrop extends StatelessWidget {
  const RiderBackdrop({
    super.key,
    this.auth = false,
  });

  final bool auth;

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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF163149),
                    Color(0xFF23475E),
                    RSColors.midnight,
                  ],
                ),
              ),
            ),

            Image.asset(
              'assets/images/rider_hero.jpg',
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.45),
              filterQuality: FilterQuality.high,
            ),

            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: auth
                      ? const [
                          0.0,
                          0.15,
                          0.32,
                          0.50,
                          0.68,
                          0.85,
                          1.0,
                        ]
                      : const [
                          0.0,
                          0.18,
                          0.40,
                          0.60,
                          0.82,
                          1.0,
                        ],
                  colors: auth
                      ? const [
                          Color(0x88071629),
                          Color(0x28071629),
                          Color(0x400B2439),
                          Color(0x850B253A),
                          Color(0xC9162E42),
                          Color(0xF0091C30),
                          RSColors.midnight,
                        ]
                      : const [
                          Color(0x70071629),
                          Color(0x16071629),
                          Color(0x290B253A),
                          Color(0x930B253A),
                          Color(0xE5091C30),
                          RSColors.midnight,
                        ],
                ),
              ),
            ),

            Positioned(
              top: -90,
              right: -90,
              child: Container(
                width: 240,
                height: 280,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Color(0x2691CEFF),
                      Colors.transparent,
                    ],
                    radius: 0.95,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
