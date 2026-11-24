import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_scope.dart';
import '../app/app_state.dart' show SosSettings;
import '../services/emergency_dispatcher.dart';
import '../widgets/screen_parts.dart';
import 'dashboard_shell.dart';

export '../app/app_state.dart' show SosSettings;

// ======================================================
// CRASH ALERT SCREEN
// ======================================================

class CrashAlertScreen extends StatefulWidget {
  const CrashAlertScreen({
    super.key,
    required this.crashDetected,
    this.testOnly = false,
    this.manualCountdown = false,
  });

  final bool crashDetected;
  final bool testOnly;
  final bool manualCountdown;

  @override
  State<CrashAlertScreen> createState() =>
      _CrashAlertScreenState();
}

class _CrashAlertScreenState extends State<CrashAlertScreen>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime? _deadline;

  late final int _totalSeconds =
      SosSettings.delaySeconds.value;

  late int _secondsLeft = _totalSeconds;

  bool _processing = false;
  bool _finished = false;
  bool _canLeave = false;

  EmergencyOutcome? _result;

  bool get _hasCountdown =>
      widget.crashDetected || widget.manualCountdown;

  // ======================================================
  // COUNTDOWN
  // ======================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    if (_hasCountdown) {
      _deadline = DateTime.now().add(
        Duration(seconds: _totalSeconds),
      );

      _timer = Timer.periodic(
        const Duration(milliseconds: 150),
        (_) => _tick(),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _tick();
    }
  }

  void _tick() {
    if (_canLeave ||
        _processing ||
        _finished ||
        _deadline == null) {
      return;
    }

    final ms = _deadline!
        .difference(DateTime.now())
        .inMilliseconds;

    final left = ms <= 0 ? 0 : (ms / 1000).ceil();

    if (left != _secondsLeft && mounted) {
      setState(() => _secondsLeft = left);
    }

    if (ms <= 0) {
      _send();
    }
  }

  // ======================================================
  // RETURN TO HOME DASHBOARD
  // ======================================================

  void _goHome() {
    if (!mounted || _canLeave) return;

    _timer?.cancel();
    _deadline = null;

    setState(() {
      _canLeave = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const DashboardShell(),
        ),
        (route) => false,
      );
    });
  }

  void _cancel() {
    if (_processing || _finished) return;

    _goHome();
  }

  // ======================================================
  // EMERGENCY DISPATCH
  // ======================================================

  Future<void> _send() async {
    if (_canLeave ||
        _processing ||
        _finished ||
        !mounted) {
      return;
    }

    _timer?.cancel();
    _deadline = null;

    setState(() {
      _processing = true;
    });

    final rider = RiderScope.of(context);

    final result = await EmergencyDispatcher.dispatch(
      rider: rider,
      simulated: widget.testOnly,
      trigger: widget.crashDetected
          ? 'crash_timeout'
          : 'manual_sos',
    );

    if (widget.crashDetected) {
      await rider.recordCrash(
        location: result.location,
        notificationStatus: result.status.name,
        testOnly: widget.testOnly,
      );
    }

    if (!mounted) return;

    setState(() {
      _result = result;
      _finished = true;
      _processing = false;
    });

    // Return automatically only after acceptance, or in safe test mode.
    if (result.accepted || widget.testOnly) {
      _goHome();
    }
  }

  // ======================================================
  // SMS FALLBACK
  // ======================================================

  Future<void> _openSms(String phone) async {
    if (widget.testOnly) return;

    final rider = RiderScope.of(context);

    var place =
        _result?.location ?? 'Location unavailable';

    if (place.startsWith('Location not requested')) {
      try {
        place = await EmergencyDispatcher.tryLocation();
      } catch (_) {
        place = 'Location unavailable';
      }
    }

    final message =
        'RiderShield emergency alert. '
        '${rider.fullName.isEmpty ? 'A rider' : rider.fullName} may need help. '
        'Time: ${DateTime.now().toLocal()}. '
        'Location: $place. '
        'Please try to contact them and reach emergency services if needed.';

    final number = phone.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    final uri = Uri.parse(
      'sms:$number?body=${Uri.encodeComponent(message)}',
    );

    var opened = false;

    try {
      opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }

    if (!opened) {
      try {
        await Clipboard.setData(
          ClipboardData(text: message),
        );
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Messages unavailable. SOS text copied; no SMS sent.',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ======================================================
  // USER INTERFACE
  // ======================================================

  @override
  Widget build(BuildContext context) {
    final rider = RiderScope.of(context);

    // ====================================================
    // LIGHT / DARK MODE
    // ====================================================

    final isLight =
        Theme.of(context).brightness == Brightness.light;

    final background = isLight
        ? const Color(0xFFF8FCFF)
        : const Color(0xFF091B30);

    final textColor = isLight
        ? const Color(0xFF16364D)
        : inkWhite;

    final secondaryColor = isLight
        ? const Color(0xFF58758C)
        : softWhite;

    final accent = isLight
        ? const Color(0xFFBD3445)
        : const Color(0xFFFF8993);

    final iconBackground = isLight
        ? const Color(0xFFFCE5E8)
        : const Color(0xFF512B43);

    final progressBackground = isLight
        ? const Color(0xFFD2E8F8)
        : const Color(0xFF38516B);

    final borderColor = isLight
        ? const Color(0xFF58758C)
        : const Color(0xFF8195A8);

    final actionColor = isLight
        ? const Color(0xFF248BC7)
        : const Color(0xFF8ED5FF);

    return PopScope(
      canPop: _finished || _canLeave,
      child: Scaffold(
        backgroundColor: background,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 470,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  26,
                  24,
                  26,
                  28,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [

                    // ====================================
                    // CRASH / SOS ICON
                    // ====================================

                    Center(
                      child: Container(
                        width: 94,
                        height: 94,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: iconBackground,
                        ),
                        child: Icon(
                          widget.crashDetected
                              ? Icons.car_crash_outlined
                              : Icons.sos_rounded,
                          size: 53,
                          color: accent,
                        ),
                      ),
                    ),

                    const SizedBox(height: 23),

                    // ====================================
                    // TITLE
                    // ====================================

                    Text(
                      _finished
                          ? 'Emergency status'
                          : widget.crashDetected
                              ? 'Possible crash detected'
                              : widget.manualCountdown
                                  ? 'SOS activated'
                                  : 'Manual SOS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -.4,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (_canLeave) ...[
                      const SizedBox.shrink(),
                    ] else if (!_finished) ...[

                      // ==================================
                      // DESCRIPTION
                      // ==================================

                      Text(
                        widget.crashDetected
                            ? 'Are you OK? Emergency action starts automatically after $_totalSeconds seconds unless you cancel.'
                            : widget.manualCountdown
                                ? 'Your emergency contacts will be alerted in $_totalSeconds seconds unless you cancel.'
                                : 'Send an emergency alert to your saved contacts. Confirm only when you need help.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 29),

                      // ==================================
                      // COUNTDOWN CIRCLE
                      // ==================================

                      if (_hasCountdown)
                        Center(
                          child: SizedBox(
                            width: 176,
                            height: 176,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: _secondsLeft /
                                      _totalSeconds,
                                  strokeWidth: 9,
                                  strokeCap: StrokeCap.round,
                                  color: accent,
                                  backgroundColor:
                                      progressBackground,
                                ),

                                Center(
                                  child: Column(
                                    mainAxisSize:
                                        MainAxisSize.min,
                                    children: [
                                      Text(
                                        '$_secondsLeft',
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 70,
                                          height: 1,
                                          fontWeight:
                                              FontWeight.w700,
                                        ),
                                      ),

                                      Text(
                                        'seconds',
                                        style: TextStyle(
                                          color:
                                              secondaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const SizedBox(height: 28),

                      // ==================================
                      // PROCESSING STATE
                      // ==================================

                      if (_processing)
                        Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                color: accent,
                              ),

                              const SizedBox(height: 12),

                              Text(
                                'Checking emergency service…',
                                style: TextStyle(
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[

                        // ================================
                        // MANUAL SOS
                        // ================================

                        if (!widget.crashDetected)
                          FilledButton.icon(
                            onPressed:
                                rider.contacts.isEmpty
                                    ? null
                                    : _send,
                            icon: const Icon(
                              Icons.sos_rounded,
                            ),
                            label: Text(
                              widget.manualCountdown
                                  ? 'Send SOS now'
                                  : 'Send manual SOS',
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFBD3445),
                              foregroundColor: Colors.white,
                              minimumSize:
                                  const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(30),
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        // ================================
                        // I'M OK - RETURN TO HOME
                        // ================================

                        OutlinedButton.icon(
                          onPressed: _cancel,

                          icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 20,
                          ),

                          label: Text(
                            widget.crashDetected
                                ? 'I’m OK — Cancel alert'
                                : widget.manualCountdown
                                    ? 'Cancel SOS'
                                    : 'Cancel',
                          ),

                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,

                            minimumSize:
                                const Size.fromHeight(52),

                            side: BorderSide(
                              color: borderColor,
                              width: 1,
                            ),

                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(30),
                            ),

                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],

                      // ==================================
                      // NO EMERGENCY CONTACTS
                      // ==================================

                      if (rider.contacts.isEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.only(top: 14),
                          child: Text(
                            'No emergency contacts saved. Add contacts first.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: accent,
                              fontSize: 13,
                            ),
                          ),
                        ),

                    ] else ...[

                      // ==================================
                      // EMERGENCY STATUS
                      // ==================================

                      const SizedBox(height: 12),

                      Text(
                        widget.testOnly
                            ? 'No emergency alert was sent.'
                            : _result!.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 13),

                      Text(
                        widget.testOnly
                            ? 'Location: Not requested'
                            : 'Location: ${_result!.location}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: secondaryColor,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 21),

                      // ==================================
                      // MANUAL CONTACT FALLBACK
                      // ==================================

                      if (!_result!.accepted &&
                          !widget.testOnly &&
                          rider.contacts.isNotEmpty) ...[

                        Text(
                          'Contact someone yourself:',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 8),

                        for (final contact in rider.contacts)
                          Padding(
                            padding:
                                const EdgeInsets.only(
                              bottom: 7,
                            ),
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _openSms(contact.phone),

                              icon: const Icon(
                                Icons.sms_outlined,
                              ),

                              label: Text(
                                'Open SMS to ${contact.name}',
                              ),

                              style:
                                  OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: BorderSide(
                                  color: borderColor,
                                ),
                              ),
                            ),
                          ),

                        Text(
                          'Opening Messages does NOT send an SMS. Press Send in Messages.',
                          style: TextStyle(
                            color: secondaryColor,
                            fontSize: 11,
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],

                      // ==================================
                      // BACK TO HOME DASHBOARD
                      // ==================================

                      FilledButton(
                        onPressed: _goHome,

                        style: FilledButton.styleFrom(
                          backgroundColor: actionColor,

                          foregroundColor: isLight
                              ? Colors.white
                              : const Color(0xFF0E2238),

                          minimumSize:
                              const Size.fromHeight(52),

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(30),
                          ),
                        ),

                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}