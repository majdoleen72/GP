import 'dart:async';
import 'package:flutter/material.dart';
import '../app/app_scope.dart';
import '../app/app_state.dart';
import 'crash_alert_screen.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';

// SOS countdown changes by 1 second per tap (was SosSettings.step = 5).
const int _delayStep = 1;

// If the rider answers neither Yes nor No, SOS goes to everyone after this.
const int _confirmSeconds = 5;

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key, required this.openTab});
  final ValueChanged<int> openTab;

  // Tab indexes (same as before): 1 = Report, 2 = Emergency, 3 = Connect
  static const int _emergencyTab = 2;
  static const int _connectTab = 3;

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
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
        const SizedBox(height: 14),

        // Replaces the old speed card -> goes to Connect page
        _connectCard(state.demoHelmetConnected),
        const SizedBox(height: 12),

        // Replaces the old Overview: Time + SOS
        SizedBox(
          height: 158,
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Expanded(child: _SosDelayCard()),
            const SizedBox(width: 11),
            Expanded(child: _sosCard(context, state.contacts)),
          ]),
        ),
      ]);
    });
  }

  Widget _connectCard(bool connected) {
    final color = connected ? const Color(0xFF63D8A0) : const Color(0xFF83D3FF);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openTab(_connectTab),
        borderRadius: BorderRadius.circular(30),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF1E5A8C), Color(0xFF14375A), Color(0xFF0E2640)]),
            border: Border.all(color: color.withValues(alpha: .45), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: .22),
                blurRadius: 26, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 78, height: 78,
                decoration: BoxDecoration(shape: BoxShape.circle,
                  color: color.withValues(alpha: .16),
                  border: Border.all(color: color.withValues(alpha: .6), width: 2)),
                child: Icon(Icons.sports_motorsports_rounded, size: 43, color: color)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .16),
                    borderRadius: BorderRadius.circular(20)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 7, height: 7,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
                    const SizedBox(width: 6),
                    Text(connected ? 'Connected' : 'Not connected',
                      style: TextStyle(color: color, fontSize: 11.5,
                        fontWeight: FontWeight.w700)),
                  ]),
                ),
                const SizedBox(height: 9),
                const Text('Connect your helmet', style: TextStyle(color: inkWhite,
                  fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.3)),
              ])),
            ]),
            const SizedBox(height: 14),
            const Text('Pair your helmet via Bluetooth so RiderShield can monitor your ride and detect crashes.',
              style: TextStyle(color: softWhite, fontSize: 13, height: 1.45)),
            const SizedBox(height: 18),
            SizedBox(width: double.infinity, height: 56,
              child: FilledButton.icon(
                onPressed: () => openTab(_connectTab),
                style: FilledButton.styleFrom(
                  backgroundColor: connected ? const Color(0xFF63D8A0) : actionBlue,
                  foregroundColor: const Color(0xFF0E2640),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                icon: Icon(connected
                  ? Icons.check_circle_outline_rounded
                  : Icons.bluetooth_searching_rounded),
                label: Text(connected ? 'Manage helmet' : 'Connect now'),
              )),
          ]),
        ),
      ),
    );
  }

  Future<void> _startSos(
    BuildContext context,
    List<EmergencyContact> contacts,
  ) async {
    if (contacts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Add an emergency contact first.')));
      openTab(_emergencyTab);
      return;
    }

    // Step 1: ask. Yes (or no answer for 5 s) = send to all contacts.
    final sendToAll = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SosConfirmDialog(count: contacts.length),
    );
    if (sendToAll == null || !context.mounted) return;

    if (sendToAll) {
      _sendSos(context, contacts);
      return;
    }

    // Step 2: "No" -> let the rider choose who gets the SOS.
    final chosen = await showModalBottomSheet<List<EmergencyContact>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFF173550),
      builder: (_) => _ContactPicker(contacts: contacts),
    );
    if (chosen == null || chosen.isEmpty || !context.mounted) return;
    _sendSos(context, chosen);
  }

  // TODO: connect this to your real SOS sender (the emergency dispatcher /
  // CrashAlertScreen logic). For now it only shows a demo confirmation.
  void _sendSos(BuildContext context, List<EmergencyContact> to) {
    final names = to.map((c) => c.name).join(', ');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text('SOS (demo) sent to ${to.length} contact(s): $names'),
    ));
  }

  Widget _sosCard(BuildContext context, List<EmergencyContact> contacts) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => _startSos(context, contacts),
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [Color(0xFFE5484D), Color(0xFF9E2A2F)]),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(height: 40, width: 40,
              decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: .20)),
              child: const Icon(Icons.sos_rounded, color: Colors.white, size: 22)),
            const Spacer(),
            const Icon(Icons.north_east_rounded, color: Colors.white70, size: 17),
          ]),
          const Spacer(),
          const Text('SOS', style: TextStyle(color: Colors.white, fontSize: 24,
            fontWeight: FontWeight.w800, letterSpacing: .5)),
          const SizedBox(height: 3),
          const Text('Tap to start SOS', style: TextStyle(color: Colors.white70,
            fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    ),
  );
}

class _SosDelayCard extends StatelessWidget {
  const _SosDelayCard();

  Widget _roundButton(IconData icon, VoidCallback? onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(height: 32, width: 32,
      decoration: BoxDecoration(shape: BoxShape.circle,
        color: onTap == null
          ? const Color(0xFFBFD7E9).withValues(alpha: .45)
          : const Color(0xFFBFD7E9)),
      child: Icon(icon, size: 18, color: const Color(0xFF16364D))),
  );

  @override
  Widget build(BuildContext context) {
    return SoftGlassCard(light: true, padding: const EdgeInsets.all(15),
      child: ValueListenableBuilder<int>(
        valueListenable: SosSettings.delaySeconds,
        builder: (context, seconds, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.timer_outlined, color: Color(0xFF16364D), size: 24),
            const Spacer(),
            _roundButton(Icons.remove_rounded,
              seconds > SosSettings.minDelay
                ? () => SosSettings.delaySeconds.value = seconds - _delayStep
                : null),
            const SizedBox(width: 6),
            _roundButton(Icons.add_rounded,
              seconds < SosSettings.maxDelay
                ? () => SosSettings.delaySeconds.value = seconds + _delayStep
                : null),
          ]),
          const Spacer(),
          Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
            Text('$seconds', style: const TextStyle(color: Color(0xFF143349),
              fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: -.5)),
            const SizedBox(width: 4),
            const Text('sec', style: TextStyle(color: Color(0xFF416078),
              fontSize: 13, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 3),
          const Text('Set the SOS countdown', maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Color(0xFF597789),
              fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ));
  }
}

/// "Send SOS to all your emergency contacts?" with a 5 s auto-yes timer.
class _SosConfirmDialog extends StatefulWidget {
  const _SosConfirmDialog({required this.count});
  final int count;

  @override
  State<_SosConfirmDialog> createState() => _SosConfirmDialogState();
}

class _SosConfirmDialogState extends State<_SosConfirmDialog> {
  int _left = _confirmSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_left <= 1) {
        t.cancel();
        Navigator.of(context).pop(true); // no answer -> send to all
      } else {
        setState(() => _left--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF173550),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text('Send SOS?',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Do you accept to send an SOS to all your emergency contacts (${widget.count})?',
            style: const TextStyle(color: Color(0xFFD1DFEF), height: 1.4)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _left / _confirmSeconds,
              minHeight: 6,
              color: const Color(0xFFE5484D),
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(height: 8),
          Text('No answer? Sending to all in $_left s',
            style: const TextStyle(color: Color(0xFFBDE5FF), fontSize: 12.5)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('No, choose contacts',
            style: TextStyle(color: Color(0xFFBDE5FF))),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE5484D)),
          child: const Text('Yes, send to all'),
        ),
      ],
    );
  }
}

/// Bottom sheet to pick which emergency contacts receive the SOS.
class _ContactPicker extends StatefulWidget {
  const _ContactPicker({required this.contacts});
  final List<EmergencyContact> contacts;

  @override
  State<_ContactPicker> createState() => _ContactPickerState();
}

class _ContactPickerState extends State<_ContactPicker> {
  final Set<String> _selected = {};

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose who gets the SOS',
              style: TextStyle(color: inkWhite, fontSize: 21,
                fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Select one or more emergency contacts.',
              style: TextStyle(color: softWhite, fontSize: 12.5)),
            const SizedBox(height: 10),
            for (final c in widget.contacts)
              CheckboxListTile(
                value: _selected.contains(c.id),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selected.add(c.id);
                  } else {
                    _selected.remove(c.id);
                  }
                }),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.trailing,
                activeColor: const Color(0xFFE5484D),
                title: Text(c.name, style: const TextStyle(
                  color: inkWhite, fontWeight: FontWeight.w700)),
                subtitle: Text('${c.relationship} • ${c.phone}',
                  style: const TextStyle(color: softWhite, fontSize: 12)),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(
                        widget.contacts
                            .where((c) => _selected.contains(c.id))
                            .toList()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE5484D)),
                icon: const Icon(Icons.sos_rounded),
                label: Text(_selected.isEmpty
                    ? 'Select at least one contact'
                    : 'Send SOS to ${_selected.length}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}