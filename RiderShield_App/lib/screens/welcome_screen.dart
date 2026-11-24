import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../navigation/ride_route.dart';
import '../widgets/rider_backdrop.dart';
import '../widgets/action_button.dart';
import 'sign_in_screen.dart';
import 'sign_up_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const RiderBackdrop(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: height),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 115),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: math.max(230, height * .50)),
                          const Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: 'Every ride.\n'),
                                TextSpan(
                                  text: 'Protected.',
                                  style: TextStyle(color: RSColors.accent),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontSize: 47,
                              height: 1.04,
                              letterSpacing: -2.1,
                              fontWeight: FontWeight.w800,
                              color: RSColors.white,
                            ),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            'Stay aware. Ride connected.\nLet RiderShield look out for you.',
                            style: TextStyle(
                              color: Color(0xFFD1DFEF),
                              fontSize: 14.5,
                              height: 1.65,
                            ),
                          ),
                          const SizedBox(height: 27),
                          ActionButton(
                            label: 'Get started',
                            onPressed: () => Navigator.of(context)
                                .push(rideRoute(const SignUpScreen())),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.of(context)
                                  .push(rideRoute(const SignInScreen())),
                              child: const Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Already have an account?  ',
                                      style: TextStyle(color: RSColors.muted),
                                    ),
                                    TextSpan(
                                      text: 'Sign in',
                                      style: TextStyle(
                                        color: RSColors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                style: TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
