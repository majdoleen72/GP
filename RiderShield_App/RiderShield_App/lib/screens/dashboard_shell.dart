import 'package:flutter/material.dart';
import '../widgets/dashboard_background.dart';
import '../widgets/rider_bottom_nav.dart';
import '../widgets/screen_parts.dart';
import 'home_dashboard_screen.dart';
import 'safety_report_screen.dart';
import 'emergency_screen.dart';
import 'connect_helmet_screen.dart';
import 'profile_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int currentTab = 0;
  void openTab(int tab) => setState(() => currentTab = tab);

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(openTab: openTab),
      SafetyReportScreen(openProfile: () => openTab(4)),
      EmergencyScreen(openProfile: () => openTab(4)),
      ConnectHelmetScreen(openProfile: () => openTab(4)),
      ProfileScreen(openProfile: () => openTab(4)),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF0B2336),
      body: Stack(children: [
        const DashboardBackground(),
        SafeArea(child: Column(children: [
          // Outside the scroll views: stays pinned on every tab.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 7, 20, 4),
            child: RiderPinnedHeader(tabIndex: currentTab, openProfile: () => openTab(4)),
          ),
          Expanded(child: IndexedStack(index: currentTab, children: screens)),
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 2, 13, 6),
            child: RiderBottomNav(selectedIndex: currentTab, onSelect: openTab),
          ),
        ])),
      ]),
    );
  }
}
