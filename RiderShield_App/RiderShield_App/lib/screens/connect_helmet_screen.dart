
import 'package:flutter/material.dart';
import '../app/app_scope.dart';
import '../widgets/screen_parts.dart';

class ConnectHelmetScreen extends StatelessWidget {
  const ConnectHelmetScreen({
    super.key,
    required this.openProfile,
  });

  final VoidCallback openProfile;

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final paired = state.demoHelmetConnected;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 115),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 26),
          child: Text(
            'Pair your phone with RiderShield.',
            style: TextStyle(
              color: softWhite,
              fontSize: 13,
            ),
          ),
        ),

        _ConnectionSteps(paired: paired),

        const SizedBox(height: 35),

        Center(
          child: Icon(
            Icons.sports_motorsports_rounded,
            size: 145,
            color: const Color(0xFF92D0FF),
          ),
        ),

        const SizedBox(height: 16),

        const Center(
          child: Text(
            'RiderShield Helmet',
            style: TextStyle(
              color: inkWhite,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 9),

        Center(
          child: Text(
            paired ? 'Demo paired' : 'Not connected',
            style: TextStyle(
              color: paired
                  ? const Color(0xFF63D8A0)
                  : softWhite,
              fontSize: 14,
            ),
          ),
        ),

        const SizedBox(height: 35),

        SizedBox(
          height: 54,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () {
              state.pairDemoHelmet(!paired);
            },
            icon: Icon(
              paired
                  ? Icons.link_off_rounded
                  : Icons.bluetooth_searching_rounded,
            ),
            label: Text(
              paired ? 'Disconnect Demo' : 'Start Pairing',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        Center(
          child: Text(
            paired
                ? 'Bluetooth pairing simulation completed.'
                : 'Ready to pair your helmet.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: softWhite,
              fontSize: 12,
            ),
          ),
        ),

        const SizedBox(height: 10),

        const Center(
          child: Text(
            'Demo mode: no physical Bluetooth connection.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: softWhite,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConnectionSteps extends StatelessWidget {
  const _ConnectionSteps({required this.paired});

  final bool paired;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _StepCircle(
            icon: Icons.bluetooth_rounded,
            title: 'Pair\nHelmet',
            status: paired ? _StepStatus.done : _StepStatus.active,
          ),
        ),
        const _StepConnector(),
        const Expanded(
          child: _StepCircle(
            icon: Icons.battery_charging_full_rounded,
            title: 'Check\nBattery',
            status: _StepStatus.pending,
          ),
        ),
        const _StepConnector(),
        const Expanded(
          child: _StepCircle(
            icon: Icons.sports_motorsports_outlined,
            title: 'Helmet\nStatus',
            status: _StepStatus.pending,
          ),
        ),
        const _StepConnector(),
        const Expanded(
          child: _StepCircle(
            icon: Icons.check_rounded,
            title: 'Complete',
            status: _StepStatus.pending,
          ),
        ),
      ],
    );
  }
}

enum _StepStatus {
  pending,
  active,
  done,
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.icon,
    required this.title,
    required this.status,
  });

  final IconData icon;
  final String title;
  final _StepStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      _StepStatus.done => const Color(0xFF63D8A0),
      _StepStatus.active => const Color(0xFF83D3FF),
      _StepStatus.pending => const Color(0xFF607D92),
    };

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          width: 65,
          height: 65,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(
              alpha: status == _StepStatus.pending ? 0.07 : 0.15,
            ),
            border: Border.all(
              color: color,
              width: status == _StepStatus.pending ? 2 : 3,
            ),
            boxShadow: status == _StepStatus.active
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 17,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: Icon(
            status == _StepStatus.done
                ? Icons.check_rounded
                : icon,
            color: color,
            size: 29,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: status == _StepStatus.pending
                ? softWhite
                : inkWhite,
            fontSize: 11,
            fontWeight: status == _StepStatus.active
                ? FontWeight.w600
                : FontWeight.w400,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 13,
      height: 2,
      margin: const EdgeInsets.only(top: 32),
      color: const Color(0xFF607D92),
    );
  }
}
