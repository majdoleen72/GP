import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../theme/app_theme.dart';

class RiderShieldApp extends StatelessWidget {
  const RiderShieldApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'RiderShield',
        debugShowCheckedModeBanner: false,
        theme: RSTheme.dark,
        home: const WelcomeScreen(),
      );
}
