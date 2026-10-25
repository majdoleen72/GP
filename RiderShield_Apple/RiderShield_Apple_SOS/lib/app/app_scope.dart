import 'package:flutter/widgets.dart';
import 'app_state.dart';

class RiderScope extends InheritedNotifier<RiderState> {
  const RiderScope({super.key, required RiderState state, required super.child}) : super(notifier: state);

  static RiderState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<RiderScope>();
    assert(scope != null, 'RiderScope missing above the widget tree');
    return scope!.notifier!;
  }
}
