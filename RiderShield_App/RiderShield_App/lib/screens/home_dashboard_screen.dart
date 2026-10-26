import 'package:flutter/material.dart';
import '../app/app_scope.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';
import '../widgets/speedometer_gauge.dart';
import 'crash_alert_screen.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key, required this.openTab});
  final ValueChanged<int> openTab;

  Future<void> showSpeedDemo(BuildContext context) async {
    final state = RiderScope.of(context);
    var speed = state.demoSpeed;
    var risk = state.demoRisk == 'Not monitoring' ? 'Safe' : state.demoRisk;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF183550), showDragHandle: true,
      builder: (sheet) => StatefulBuilder(builder: (context, update) =>
        SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(20, 5, 20, 23),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Speed & risk preview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Demo values only. Phone GPS and risk analysis are not connected.',
              style: TextStyle(color: softWhite, fontSize: 12)),
            const SizedBox(height: 20),
            Center(child: Text('${speed.round()} km/h', style: const TextStyle(fontSize: 30))),
            Slider(value: speed, min: 0, max: 180,
              onChanged: (v) => update(() => speed = v)),
            const SizedBox(height: 12),
            const Text('Preview risk status', style: TextStyle(color: softWhite)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [for (final item in ['Safe','Careful','Unsafe'])
              ChoiceChip(label: Text(item), selected: risk == item,
                onSelected: (_) => update(() => risk = item))]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () {
                state.clearRidePreview(); Navigator.pop(sheet);
              }, child: const Text('Reset'))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: () {
                state.setRidePreview(speed, risk); Navigator.pop(sheet);
              }, child: const Text('Apply demo'))),
            ]),
          ]))),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final demo = state.demoRisk != 'Not monitoring';
    return LayoutBuilder(builder: (context, constraints) {
      final margin = constraints.maxWidth > 620 ? 34.0 : 20.0;
      return ListView(padding: EdgeInsets.fromLTRB(margin, 14, margin, 25), children: [

        const SizedBox(height: 5),
        Text('Welcome back, ${state.shortName}.',
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: inkWhite, fontSize: 28,
            letterSpacing: -.55, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Your ride at a glance.', style: TextStyle(color: softWhite, fontSize: 13)),
        const SizedBox(height: 11),
        _speedCard(context, state.demoSpeed, state.demoRisk),
        const SizedBox(height: 12),
        Row(children: [
          const Expanded(child: Text('Overview', style: TextStyle(color: inkWhite,
            fontWeight: FontWeight.w700, fontSize: 18))),
          TextButton.icon(
            onPressed: () => showSpeedDemo(context),
            icon: const Icon(Icons.tune_rounded, size: 17),
            label: Text(demo ? 'Edit demo' : 'Preview speed'),
            style: TextButton.styleFrom(foregroundColor: actionBlue),
          ),
        ]),
        const SizedBox(height: 5),
        Row(children: [
          Expanded(child: _miniCard(
            icon: Icons.sports_motorsports_outlined,
            title: 'Helmet', value: state.demoHelmetConnected ? 'Demo paired' : 'Not connected',
            hint: 'Bluetooth', onTap: () => openTab(3))),
          const SizedBox(width: 11),
          Expanded(child: _miniCard(
            icon: Icons.shield_outlined, title: 'Safety',
            value: demo ? state.demoRisk : 'Not monitoring',
            hint: 'Risk status', onTap: () => showSpeedDemo(context))),
        ]),
        const SizedBox(height: 11),
        Row(children: [
          Expanded(child: _miniCard(icon: Icons.contact_emergency_outlined,
            title: 'Emergency', value: 'Contacts & SOS',
            hint: 'Manage', onTap: () => openTab(2))),
          const SizedBox(width: 11),
          Expanded(child: _miniCard(icon: Icons.receipt_long_outlined,
            title: 'Safety report', value: '${state.incidents.length} crash entries',
            hint: 'Crashes only', onTap: () => openTab(1))),
        ]),
        const SizedBox(height: 12),
        const SectionCaption('Recent ride'),
        const SoftGlassCard(padding: EdgeInsets.all(17), child: Row(children: [
          Icon(Icons.route_outlined, color: actionBlue, size: 25),
          SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('No completed rides yet', style: TextStyle(color: inkWhite,
              fontSize: 15, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text('Ride history will appear after trip tracking is connected.',
              style: TextStyle(color: softWhite, fontSize: 12, height: 1.3)),
          ])),
        ])),
        const SizedBox(height: 10),
        SoftGlassCard(onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const CrashAlertScreen(
            crashDetected: true, testOnly: true)),
        ), padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: const Row(children: [
            Icon(Icons.timer_outlined, color: Color(0xFFFFB1B4), size: 23),
            SizedBox(width: 12),
            Expanded(child: Text('Test crash countdown (10 seconds)',
              style: TextStyle(color: inkWhite, fontSize: 13.5,
                fontWeight: FontWeight.w600))),
            Icon(Icons.chevron_right_rounded, color: softWhite),
          ])),
        const SizedBox(height: 15),
        SoftGlassCard(padding: const EdgeInsets.all(16), child: Row(children: [
          const Icon(Icons.info_outline_rounded, color: actionBlue, size: 22),
          const SizedBox(width: 12),
          const Expanded(child: Text('Preview mode: speed, alerts and helmet connectivity are not live.',
            style: TextStyle(color: softWhite, fontSize: 12, height: 1.4))),
          const SizedBox(width: 5),
          TextButton(onPressed: () => showSpeedDemo(context),
            child: const Text('Try it')),
        ])),
      ]);
    });
  }

  Widget _speedCard(BuildContext context, double speed, String risk) {
    final state = RiderScope.of(context);
    final riskColor = switch (risk) {
      'Safe' => const Color(0xFFB3EBCB),
      'Careful' => const Color(0xFFFFD792),
      'Unsafe' => const Color(0xFFFFB0AC),
      _ => softWhite,
    };
    return SoftGlassCard(padding: const EdgeInsets.fromLTRB(15, 16, 15, 14), child: Column(children: [
      Row(children: [
        const Icon(Icons.speed_rounded, color: actionBlue),
        const SizedBox(width: 9),
        const Expanded(child: Text('Current speed', style: TextStyle(color: inkWhite,
          fontSize: 17, fontWeight: FontWeight.w700))),
        Semantics(button: true, label: 'Open speed preview',
          child: InkWell(onTap: () => showSpeedDemo(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: .10)),
              child: const Text('DEMO', style: TextStyle(color: softWhite,
                fontSize: 10, letterSpacing: .6, fontWeight: FontWeight.w700))))),
      ]),
      SpeedometerGauge(speed: speed),
      const SizedBox(height: 5),
      Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .10), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: .12))),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: Row(children: [
          Icon(Icons.verified_user_outlined, color: riskColor, size: 26),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ride safety status', style: TextStyle(color: softWhite, fontSize: 11)),
            Text(risk, style: TextStyle(color: riskColor, fontSize: 18,
              fontWeight: FontWeight.w700)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: softWhite),
        ]),
      ),
      const SizedBox(height: 9),
      Row(children: [
        _metric(Icons.location_off_outlined, 'GPS', 'Offline'),
        _metric(Icons.bluetooth_rounded, 'Helmet',
          state.demoHelmetConnected ? 'Demo' : 'Offline'),
        _metric(Icons.battery_unknown_rounded, 'Battery', '--'),
      ]),
    ]));
  }

  Widget _metric(IconData icon, String label, String value) => Expanded(
    child: Column(children: [
      Icon(icon, size: 19, color: const Color(0xFFD8EAF5)),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: softWhite, fontSize: 10)),
      const SizedBox(height: 3),
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: inkWhite, fontWeight: FontWeight.w600, fontSize: 11)),
    ]),
  );

  Widget _miniCard({required IconData icon, required String title,
    required String value, required String hint, required VoidCallback onTap}) =>
    SoftGlassCard(light: true, onTap: onTap, padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(height: 40, width: 40,
            decoration: const BoxDecoration(shape: BoxShape.circle,
              color: Color(0xFFBFD7E9)),
            child: Icon(icon, color: const Color(0xFF16364D), size: 21)),
          const Spacer(),
          const Icon(Icons.north_east_rounded, color: Color(0xFF416078), size: 17),
        ]),
        const SizedBox(height: 13),
        Text(title, style: const TextStyle(color: Color(0xFF143349), fontSize: 15,
          fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF23485F), fontSize: 12,
            fontWeight: FontWeight.w600)),
        const SizedBox(height: 5),
        Text(hint, style: const TextStyle(color: Color(0xFF597789), fontSize: 11)),
      ]));
}
