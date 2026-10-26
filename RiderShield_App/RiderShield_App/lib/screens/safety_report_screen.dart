import 'package:flutter/material.dart';
import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';

class SafetyReportScreen extends StatelessWidget {
  const SafetyReportScreen({super.key, required this.openProfile});
  final VoidCallback openProfile;

  Future<void> addTestCrash(BuildContext context) async {
    final state = RiderScope.of(context);
    final location = TextEditingController();
    var severity = 'Minor';
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      backgroundColor: const Color(0xFF173550), showDragHandle: true,
      builder: (sheet) => StatefulBuilder(builder: (context, update) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(sheet).bottom + 22),
        child: SafeArea(top: false, child: SingleChildScrollView(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add test crash', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
            const SizedBox(height: 9),
            const Text('A demo-only incident for checking the report design. This is NOT a real crash.',
              style: TextStyle(color: softWhite)),
            const SizedBox(height: 18),
            TextField(controller: location, decoration: const InputDecoration(
              labelText: 'Demo location (optional)', hintText: 'e.g. Test route')),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(initialValue: severity,
              decoration: const InputDecoration(labelText: 'Example severity'),
              items: ['Minor', 'Moderate', 'Severe']
                  .map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => update(() => severity = v ?? severity)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, height: 48,
              child: FilledButton(onPressed: () async {
                await state.addDemoIncident(severity: severity, location: location.text.trim());
                if (sheet.mounted) Navigator.pop(sheet);
              }, child: const Text('Save test incident'))),
          ],
        ))),
      )),
    );
    location.dispose();
  }

  void showIncident(BuildContext context, CrashIncident incident) {
    final state = RiderScope.of(context);
    showModalBottomSheet<void>(context: context, showDragHandle: true,
      backgroundColor: const Color(0xFF173550), builder: (sheet) =>
      SafeArea(top: false, child: Padding(padding: const EdgeInsets.fromLTRB(22, 5, 22, 115),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(incident.testOnly ? 'Test crash incident' : 'Crash incident', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text(prettyDate(incident.happenedAt)),
          const SizedBox(height: 6),
          Text('Location: ${incident.location}'),
          Text('Severity: ${incident.severity}'),
          const SizedBox(height: 6),
          Text('Emergency request: ${incident.notificationStatus}',
            style: const TextStyle(color: softWhite)),
          if (incident.testOnly) ...[
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(sheet);
                await state.removeIncident(incident.id);
              },
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete test incident'),
            )),
          ],
        ]),
      )));
  }

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final last = state.incidents.isNotEmpty ? state.incidents.first : null;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 115), children: [
        const Padding(padding: EdgeInsets.fromLTRB(2, 6, 2, 14), child: Text('Crash and accident records only.', style: TextStyle(color: softWhite, fontSize: 12.5))),
      SoftGlassCard(child: Row(children: [
        const CircleAvatar(radius: 29, backgroundColor: Color(0x664B364A),
          child: Icon(Icons.car_crash_outlined, color: Color(0xFFFFC2C0), size: 29)),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Crash events / tests', style: TextStyle(color: softWhite, fontSize: 12)),
          Text('${state.incidents.length}', style: const TextStyle(color: inkWhite,
              fontSize: 34, fontWeight: FontWeight.w700)),
          Text(last == null ? 'No incidents recorded' : 'Last: ${prettyDate(last.happenedAt)}',
            style: const TextStyle(color: softWhite, fontSize: 11)),
        ])),
      ])),
      const SizedBox(height: 20),
      SectionCaption('Crash history', trailing: TextButton.icon(
        onPressed: () => addTestCrash(context),
        icon: const Icon(Icons.add_rounded, size: 17), label: const Text('Add test crash'),
        style: TextButton.styleFrom(foregroundColor: const Color(0xFFD5ECFF)))),
      if (state.incidents.isEmpty)
        const SoftGlassCard(child: Column(children: [
          Icon(Icons.verified_user_outlined, color: actionBlue, size: 40),
          SizedBox(height: 10),
          Text('No crashes recorded', style: TextStyle(color: inkWhite,
              fontSize: 17, fontWeight: FontWeight.w700)),
          SizedBox(height: 7),
          Text('Safety alerts and nearby hazards will not appear in this report.',
            textAlign: TextAlign.center, style: TextStyle(color: softWhite, height: 1.4)),
        ])),
      for (final incident in state.incidents) ...[
        SoftGlassCard(onTap: () => showIncident(context, incident),
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 43, height: 43,
              decoration: BoxDecoration(color: const Color(0x554F647C),
                borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB4AA))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${incident.testOnly ? 'Test crash' : 'Crash'} • ${incident.severity}', style: const TextStyle(
                color: inkWhite, fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text(prettyDate(incident.happenedAt),
                style: const TextStyle(color: softWhite, fontSize: 12)),
              Text(incident.location, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: softWhite, fontSize: 12)),
            ])),
            const Icon(Icons.chevron_right_rounded, color: softWhite),
          ])),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 20),
      const InfoTile(icon: Icons.info_outline_rounded,
        title: 'Accidents only',
        value: 'Warnings do not create crash reports.'),
      const SizedBox(height: 10),
      const Text('Crash countdown records are saved after the timer expires. Cancelled alerts and regular risk warnings do not enter Safety Report. Real crash detection still requires sensor integration.',
        style: TextStyle(color: softWhite, fontSize: 11, height: 1.4)),
    ]);
  }
}
