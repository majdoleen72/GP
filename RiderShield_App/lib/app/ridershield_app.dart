
import 'package:flutter/material.dart';

import 'app_scope.dart';
import '../screens/welcome_screen.dart';
import '../theme/app_theme.dart';

class RiderShieldApp extends StatelessWidget {
  const RiderShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to changes in RiderState.
    final state = RiderScope.of(context);

    return MaterialApp(
      title: 'RiderShield',
      debugShowCheckedModeBanner: false,

      // Frosted Ice Light Mode
      theme: RSTheme.light,

      // Original Dark Mode
      darkTheme: RSTheme.dark,

      // Manual selection from Profile
      themeMode: state.isLightMode
          ? ThemeMode.light
          : ThemeMode.dark,

      home: const WelcomeScreen(),
    );
  }
}
