import 'package:flutter/material.dart';
import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';
import '../widgets/apple_grouped_fields.dart';
import 'crash_alert_screen.dart';

class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key, required this.openProfile});
  final VoidCallback openProfile;

  Future<void> editContact(BuildContext context, {EmergencyContact? existing}) async {
    final state = RiderScope.of(context);
    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: existing?.name ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final relationship = TextEditingController(text: existing?.relationship ?? '');
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      showDragHandle: true, backgroundColor: const Color(0xFF173550),
      builder: (sheet) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(sheet).bottom + 22),
        child: SafeArea(top: false, child: SingleChildScrollView(child: Form(
          key: key,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(existing == null ? 'Add emergency contact' : 'Edit contact',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w700)),
            const SizedBox(height: 18),
            AppleFormGroup(children: [
              AppleFormField(label: 'Name', controller: name, hint: 'Full name',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null),
              AppleFormField(label: 'Relation', controller: relationship, hint: 'e.g. Sister',
                icon: Icons.group_outlined,
                validator: (v) => (v ?? '').trim().isEmpty ? 'Enter relationship' : null),
              AppleFormField(label: 'Phone', controller: phone, hint: '+9665...',
                icon: Icons.phone_outlined, keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                validator: (v) => RegExp(r'^\+?[0-9 ()-]{7,20}$').hasMatch((v ?? '').trim())
                  ? null : 'Enter a valid phone number'),
            ]),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 50, child: FilledButton(
              onPressed: () async {
                if (!(key.currentState?.validate() ?? false)) return;
                await state.upsertContact(EmergencyContact(
                  id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
                  name: name.text.trim(), relationship: relationship.text.trim(),
                  phone: phone.text.trim(),
                ));
                if (sheet.mounted) Navigator.pop(sheet);
              }, child: const Text('Save contact'),
            )),
          ]),
        ))),
      ),
    );
    name.dispose(); phone.dispose(); relationship.dispose();
  }

  Future<void> deleteContact(BuildContext context, EmergencyContact contact) async {
    final state = RiderScope.of(context);
    final remove = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: const Text('Delete contact?'),
      content: Text('Remove ${contact.name} from your emergency contacts?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Delete')),
      ],
    ));
    if (remove == true) await state.deleteContact(contact.id);
  }

  void openManualSos(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const CrashAlertScreen(crashDetected: false),
    ));
  }

  void tryCrashCountdown(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => const CrashAlertScreen(crashDetected: true, testOnly: true),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 14, 20, 24), children: [
        const Padding(padding: EdgeInsets.fromLTRB(2, 6, 2, 14), child: Text('Manage the people you trust in an emergency.', style: TextStyle(color: softWhite, fontSize: 12.5))),
      SoftGlassCard(
        padding: const EdgeInsets.all(19),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const CircleAvatar(radius: 26, backgroundColor: Color(0x664D354A),
              child: Icon(Icons.sos_rounded, size: 30, color: Color(0xFFFFB8B8))),
            const SizedBox(width: 13),
            const Expanded(child: Text('Emergency SOS',
              style: TextStyle(color: inkWhite, fontWeight: FontWeight.w700, fontSize: 20))),
            Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: .6)),
          ]),
          const SizedBox(height: 14),
          const Text('Keep trusted contacts here for crash response or manual SOS.',
            style: TextStyle(color: softWhite, height: 1.45)),
          const SizedBox(height: 15),
          SizedBox(width: double.infinity, height: 48,
            child: FilledButton.icon(
              onPressed: () => openManualSos(context),
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF693D4B),
                foregroundColor: Colors.white),
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Manual SOS'),
            )),
          const SizedBox(height: 10),
          const Text('A real SMS needs a configured delivery service. Manual SOS always asks for confirmation.',
            style: TextStyle(color: softWhite, fontSize: 11)),
        ]),
      ),
      const SizedBox(height: 19),
      SectionCaption('Emergency contacts', trailing: Text('${state.contacts.length} saved',
        style: const TextStyle(color: softWhite, fontSize: 12))),
      if (state.contacts.isEmpty)
        const SoftGlassCard(child: Column(children: [
          Icon(Icons.groups_2_outlined, size: 35, color: actionBlue),
          SizedBox(height: 10),
          Text('No contacts yet', style: TextStyle(color: inkWhite, fontWeight: FontWeight.w700)),
          SizedBox(height: 5),
          Text('Add a trusted person to your emergency list.',
            textAlign: TextAlign.center, style: TextStyle(color: softWhite)),
        ])),
      for (final contact in state.contacts) ...[
        SoftGlassCard(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(children: [
            CircleAvatar(radius: 23, backgroundColor: const Color(0x775C9AC1),
              child: Text(contact.name.isEmpty ? '?' : contact.name[0].toUpperCase(),
                style: const TextStyle(color: inkWhite, fontWeight: FontWeight.bold))),
            const SizedBox(width: 11),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(contact.name, style: const TextStyle(color: inkWhite, fontWeight: FontWeight.w700)),
              Text(contact.relationship, style: const TextStyle(color: softWhite, fontSize: 12)),
              Text(contact.phone, style: const TextStyle(color: softWhite, fontSize: 12)),
            ])),
            IconButton(tooltip: 'Edit ${contact.name}',
              icon: const Icon(Icons.edit_outlined, color: actionBlue),
              onPressed: () => editContact(context, existing: contact)),
            IconButton(tooltip: 'Delete ${contact.name}',
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFFFB5B3)),
              onPressed: () => deleteContact(context, contact)),
          ])),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 12),
      SizedBox(width: double.infinity, height: 52,
        child: OutlinedButton.icon(
          onPressed: () => editContact(context),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Add contact'),
        ),
      ),
      const SizedBox(height: 22),
      const SectionCaption('Crash alert preview'),
      SoftGlassCard(onTap: () => tryCrashCountdown(context),
        child: const Row(children: [
          Icon(Icons.timer_outlined, color: actionBlue, size: 27),
          SizedBox(width: 12),
          Expanded(child: Text('Test 10-second crash countdown',
            style: TextStyle(color: inkWhite, fontWeight: FontWeight.w600))),
          Icon(Icons.chevron_right_rounded, color: softWhite),
        ])),
      const SizedBox(height: 9),
      const Text('This button is a TEST: no real SMS is transmitted. Automatic crash detection still requires integration with your crash detector.',
        style: TextStyle(color: softWhite, fontSize: 11, height: 1.4)),
    ]);
  }
}
