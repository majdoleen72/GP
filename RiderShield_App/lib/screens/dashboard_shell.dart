
import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import '../widgets/dashboard_background.dart';
import '../widgets/rider_bottom_nav.dart';
import '../widgets/screen_parts.dart';

import 'home_dashboard_screen.dart';
import 'safety_report_screen.dart';
import 'emergency_screen.dart';
import 'connect_helmet_screen.dart';
import 'profile_screen.dart';

// ======================================================
// DASHBOARD SHELL
// ======================================================

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() =>
      _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int currentTab = 0;

  int _previousTab = 0;
  int _previousProfileTab = 0;

  // ====================================================
  // LIGHT / DARK THEME HELPERS
  // ====================================================

  bool get isLight =>
      Theme.of(context).brightness == Brightness.light;

  Color get headerTextColor =>
      isLight ? const Color(0xFF16364D) : inkWhite;

  Color get backgroundColor =>
      isLight
          ? const Color(0xFFF4F9FF)
          : const Color(0xFF0B2336);

  Color get accentColor =>
      isLight
          ? const Color(0xFF248BC7)
          : const Color(0xFF9DDBFF);

  // ====================================================
  // NAVIGATION
  // ====================================================

  void openTab(int tab) {
    if (tab < 0 || tab > 4 || tab == currentTab) return;

    setState(() {
      if (tab == 1 && currentTab != 1) {
        _previousTab = currentTab;
      }

      if (tab == 4 && currentTab != 4) {
        _previousProfileTab = currentTab;
      }

      currentTab = tab;
    });
  }

  void _backFromReports() {
    openTab(
      _previousTab == 1 ? 0 : _previousTab,
    );
  }

  void _backFromProfile() {
    openTab(
      _previousProfileTab == 4
          ? 0
          : _previousProfileTab,
    );
  }

  // ====================================================
  // HEADER
  // ====================================================

  Widget _buildHeader() {
    if (currentTab == 4) {
      return _backHeader(
        title: 'Profile',
        onBack: _backFromProfile,
      );
    }

    if (currentTab == 1) {
      return _backHeader(
        title: 'Safety Report',
        onBack: _backFromReports,
      );
    }

    if (currentTab == 2) {
      return _simpleHeader('Emergency');
    }

    if (currentTab == 3) {
      return _simpleHeader('Connect Helmet');
    }

    // HOME
    // Rebuild when RiderState changes.
    final state = RiderScope.of(context);

    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        return _HomeHeader(
          name: state.shortName,
          onProfile: () => openTab(4),
          onReport: () => openTab(1),
        );
      },
    );
  }

  // ====================================================
  // SIMPLE HEADER
  // ====================================================

  Widget _simpleHeader(String title) {
    return SizedBox(
      height: 40,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: TextStyle(
            color: headerTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ====================================================
  // BACK HEADER
  // ====================================================

  Widget _backHeader({
    required String title,
    required VoidCallback onBack,
  }) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            tooltip: 'Back',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 38,
              minHeight: 38,
            ),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: headerTextColor,
              size: 20,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: headerTextColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // MAIN DASHBOARD LAYOUT
  // ====================================================

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeDashboardScreen(
        openTab: openTab,
      ),
      SafetyReportScreen(
        openProfile: () => openTab(4),
      ),
      EmergencyScreen(
        openProfile: () => openTab(4),
      ),
      ConnectHelmetScreen(
        openProfile: () => openTab(4),
      ),
      ProfileScreen(
        openProfile: () => openTab(4),
      ),
    ];

    final bottomInset =
        MediaQuery.paddingOf(context).bottom;

    final showNavbar =
        currentTab == 0 ||
        currentTab == 2 ||
        currentTab == 3;

    return Scaffold(
      // Original dark background is preserved.
      // Frosted Ice is used in light mode.
      backgroundColor: backgroundColor,
      extendBody: true,

      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background changes automatically
          // between Dark and Frosted Ice.
          const DashboardBackground(),

          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    5,
                    20,
                    3,
                  ),
                  child: _buildHeader(),
                ),

                Expanded(
                  child: IndexedStack(
                    index: currentTab,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),

          // Original navbar visibility preserved.
          if (showNavbar)
            Positioned(
              left: 13,
              right: 13,
              bottom: bottomInset + 6,
              child: RiderBottomNav(
                selectedIndex: currentTab,
                onSelect: openTab,
              ),
            ),
        ],
      ),
    );
  }
}

// ======================================================
// HOME HEADER
// ======================================================

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.onProfile,
    required this.onReport,
  });

  final String name;
  final VoidCallback onProfile;
  final VoidCallback onReport;

  String get displayName {
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      return 'there';
    }

    return trimmed.split(RegExp(r'\s+')).first;
  }

  @override
  Widget build(BuildContext context) {
    final isLight =
        Theme.of(context).brightness == Brightness.light;

    final textColor = isLight
        ? const Color(0xFF16364D)
        : inkWhite;

    return SizedBox(
      height: 64,
      child: Row(
        children: [
          // ==========================================
          // PROFILE CIRCLE
          // ==========================================

          InkWell(
            onTap: onProfile,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 53,
              height: 53,
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: isLight
                    ? const Color(0xFFD9EFFD)
                    : const Color(0xFF547E9D),

                border: Border.all(
                  color: isLight
                      ? const Color(0xFF8EC5E9)
                      : const Color(0xFFB8E6FF),
                  width: 1.8,
                ),
              ),

              child: Icon(
                Icons.person_rounded,
                color: isLight
                    ? const Color(0xFF248BC7)
                    : Colors.white,
                size: 30,
              ),
            ),
          ),

          const SizedBox(width: 13),

          // ==========================================
          // WELCOME TEXT
          // ==========================================

          Expanded(
            child: Text(
              'Welcome, $displayName!',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),

          // ==========================================
          // SAFETY REPORT BUTTON
          // ==========================================

          InkWell(
            onTap: onReport,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,

                color: isLight
                    ? const Color(0xFFE5F2FC)
                    : const Color(0xFF244965),

                border: isLight
                    ? Border.all(
                        color: const Color(0xFFD2E8F8),
                        width: 1,
                      )
                    : null,
              ),

              child: Icon(
                Icons.bar_chart_rounded,
                color: isLight
                    ? const Color(0xFF248BC7)
                    : Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
