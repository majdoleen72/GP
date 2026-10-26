import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_state.dart';
import 'app/app_scope.dart';
import 'app/ridershield_app.dart';
import 'theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = await RiderState.initialize();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: RSColors.midnight,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(RiderScope(state: state, child: const RiderShieldApp()));
}
