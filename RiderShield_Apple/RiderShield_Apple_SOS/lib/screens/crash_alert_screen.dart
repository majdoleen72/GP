import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app_scope.dart';
import '../services/emergency_dispatcher.dart';

/// Real crash detectors should open CrashAlertScreen(crashDetected: true,
/// testOnly: false). This UI does not itself detect crashes. When testOnly is
/// true, notifications are categorically blocked by EmergencyDispatcher.
class CrashAlertScreen extends StatefulWidget {
  const CrashAlertScreen({super.key,
    required this.crashDetected, this.testOnly = false});
  final bool crashDetected;
  final bool testOnly;

  @override
  State<CrashAlertScreen> createState() => _CrashAlertScreenState();
}

class _CrashAlertScreenState extends State<CrashAlertScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _deadline;
  int _secondsLeft = 10;
  bool _processing = false;
  bool _finished = false;
  bool _canLeave = false;
  EmergencyOutcome? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.crashDetected) {
      _deadline = DateTime.now().add(const Duration(seconds: 10));
      _timer = Timer.periodic(const Duration(milliseconds: 150), (_) => _tick());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _tick() {
    if (_processing || _finished || _deadline == null) return;
    final ms = _deadline!.difference(DateTime.now()).inMilliseconds;
    final left = ms <= 0 ? 0 : (ms / 1000).ceil();
    if (left != _secondsLeft && mounted) setState(() => _secondsLeft = left);
    if (ms <= 0) _send();
  }

  void _cancel() {
    if (_processing || _finished) return;
    _timer?.cancel();
    setState(() => _canLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _send() async {
    if (_processing || _finished || !mounted) return;
    _timer?.cancel();
    setState(() => _processing = true);
    final rider = RiderScope.of(context);
    final result = await EmergencyDispatcher.dispatch(
      rider: rider,
      simulated: widget.testOnly,
      trigger: widget.crashDetected ? 'crash_timeout' : 'manual_sos',
    );
    if (widget.crashDetected) {
      // Real/crash-test records ONLY. Manual SOS and warnings don't create reports.
      await rider.recordCrash(
        location: result.location,
        notificationStatus: result.status.name,
        testOnly: widget.testOnly,
      );
    }
    if (!mounted) return;
    setState(() { _result = result; _finished = true; _processing = false; });
  }

  Future<void> _openSms(String phone) async {
    final rider = RiderScope.of(context);
    var place = _result?.location ?? 'Location unavailable';
    if (place.startsWith('Location not requested')) {
      place = await EmergencyDispatcher.tryLocation();
    }
    final message = 'RiderShield emergency alert. '
      '${rider.fullName.isEmpty ? 'A rider' : rider.fullName} may need help. '
      'Time: ${DateTime.now().toLocal()}. Location: $place. '
      'Please try to contact them and reach emergency services if needed.';
    final uri = Uri(scheme: 'sms', path: phone, queryParameters: {'body': message});
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      await Clipboard.setData(ClipboardData(text: message));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Messages unavailable. SOS text copied; no SMS sent.'),
      ));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rider = RiderScope.of(context);
    const accent = Color(0xFFFF8993);
    const pale = Color(0xFFCADBEC);
    return PopScope(
      canPop: _finished || _canLeave,
      child: Scaffold(
        backgroundColor: const Color(0xFF091B30),
        body: SafeArea(
          child: Center(child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 18, 26, 28),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [
                  const Icon(Icons.shield_outlined, color: Color(0xFF91CFFF), size: 26),
                  const SizedBox(width: 9),
                  const Expanded(child: Text('RiderShield', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700))),
                  if (widget.testOnly) const Text('TEST MODE',
                    style: TextStyle(color: Color(0xFFFFCE87),
                      fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
                const SizedBox(height: 55),
                Center(child: Container(
                  width: 94, height: 94,
                  decoration: const BoxDecoration(shape: BoxShape.circle,
                    color: Color(0xFF512B43)),
                  child: const Icon(Icons.car_crash_outlined,
                    size: 53, color: accent),
                )),
                const SizedBox(height: 23),
                Text(_finished ? 'Emergency status'
                  : widget.crashDetected ? 'Possible crash detected' : 'Manual SOS',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 27, fontWeight: FontWeight.w700,
                    letterSpacing: -.4)),
                const SizedBox(height: 12),
                if (!_finished) ...[
                  Text(widget.crashDetected
                    ? 'Are you OK? Emergency action starts automatically after 10 seconds unless you cancel.'
                    : 'Send an emergency alert to your saved contacts. Confirm only when you need help.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: pale, fontSize: 14, height: 1.5)),
                  const SizedBox(height: 29),
                  if (widget.crashDetected)
                    Center(child: SizedBox(
                      width: 176, height: 176,
                      child: Stack(fit: StackFit.expand, children: [
                        CircularProgressIndicator(
                          value: _secondsLeft / 10,
                          strokeWidth: 9,
                          strokeCap: StrokeCap.round,
                          color: accent,
                          backgroundColor: const Color(0xFF38516B),
                        ),
                        Center(child: Column(mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$_secondsLeft', style: const TextStyle(
                              fontSize: 70, height: 1, fontWeight: FontWeight.w700)),
                            const Text('seconds', style: TextStyle(color: pale)),
                          ])),
                      ]),
                    )),
                  const SizedBox(height: 28),
                  if (_processing)
                    const Center(child: Column(children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Checking emergency service…'),
                    ]))
                  else ...[
                    if (!widget.crashDetected)
                      FilledButton.icon(
                        onPressed: rider.contacts.isEmpty ? null : _send,
                        icon: const Icon(Icons.sos_rounded),
                        label: const Text('Send manual SOS'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFBD3445),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(54)),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(onPressed: _cancel,
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: Text(widget.crashDetected ? 'I’m OK — Cancel alert' : 'Cancel'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52),
                        foregroundColor: Colors.white)),
                  ],
                  if (rider.contacts.isEmpty)
                    const Padding(padding: EdgeInsets.only(top: 14),
                      child: Text('No emergency contacts saved. Add contacts first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0xFFFFC7C7)))),
                  if (widget.testOnly)
                    const Padding(padding: EdgeInsets.only(top: 15),
                      child: Text('Demo countdown. It never transmits a real alert.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: pale, fontSize: 12))),
                ] else ...[
                  const SizedBox(height: 12),
                  Text(_result!.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: pale, fontSize: 15, height: 1.5)),
                  const SizedBox(height: 13),
                  Text('Location: ${_result!.location}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: pale, fontSize: 12)),
                  const SizedBox(height: 21),
                  if (!_result!.accepted && !widget.testOnly && rider.contacts.isNotEmpty) ...[
                    const Text('Contact someone yourself:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (final contact in rider.contacts)
                      Padding(padding: const EdgeInsets.only(bottom: 7),
                        child: OutlinedButton.icon(
                          onPressed: () => _openSms(contact.phone),
                          icon: const Icon(Icons.sms_outlined),
                          label: Text('Open SMS to ${contact.name}'),
                        )),
                    const Text('Opening Messages does NOT send an SMS. Press Send in Messages.',
                      style: TextStyle(fontSize: 11, color: pale)),
                    const SizedBox(height: 12),
                  ],
                  FilledButton(onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: const Text('Back to RiderShield')),
                ],
              ]),
            ),
          )),
        ),
      ),
    );
  }
}
