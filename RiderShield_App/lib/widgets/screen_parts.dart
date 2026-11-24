
import 'package:flutter/material.dart';

import '../app/app_scope.dart';
import 'soft_glass_card.dart';

// ======================================================
// ORIGINAL DARK COLORS - UNCHANGED
// ======================================================

const inkWhite = Color(0xFFF6FAFF);
const softWhite = Color(0xFFBFD2E0);
const actionBlue = Color(0xFF9DDBFF);

// ======================================================
// FROSTED ICE LIGHT COLORS
// ======================================================

const _iceText = Color(0xFF16364D);
const _iceMuted = Color(0xFF58758C);
const _iceAccent = Color(0xFF248BC7);
const _iceGlass = Color(0xFFE5F2FC);

// ======================================================
// THEME HELPERS
// ======================================================

bool _isLight(BuildContext context) =>
    Theme.of(context).brightness == Brightness.light;

Color _primaryText(BuildContext context) =>
    _isLight(context) ? _iceText : inkWhite;

Color _secondaryText(BuildContext context) =>
    _isLight(context) ? _iceMuted : softWhite;

Color _primaryAccent(BuildContext context) =>
    _isLight(context) ? _iceAccent : actionBlue;

// --------------------------------------------------
// RIDER HEADER
// --------------------------------------------------

class RiderHeader extends StatelessWidget {
  const RiderHeader({
    super.key,
    required this.openProfile,
  });

  final VoidCallback openProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'assets/images/ridershield_shield.png',
          width: 40,
          height: 45,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Image.asset(
            'assets/images/ridershield_wordmark.png',
            width: 178,
            height: 33,
            fit: BoxFit.contain,
            alignment: Alignment.centerLeft,
          ),
        ),
        const Spacer(),
        Semantics(
          label: 'Open profile',
          button: true,
          child: InkWell(
            onTap: openProfile,
            borderRadius: BorderRadius.circular(24),
            child: const RiderAvatar(diameter: 44),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------
// PINNED HEADER
// --------------------------------------------------

class RiderPinnedHeader extends StatelessWidget {
  const RiderPinnedHeader({
    super.key,
    required this.tabIndex,
    required this.openProfile,
    required this.openReport,
  });

  final int tabIndex;
  final VoidCallback openProfile;
  final VoidCallback openReport;

  static const titles = [
    'RiderShield',
    'Safety Report',
    'Emergency',
    'Connect Helmet',
    'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final isLight = _isLight(context);

    // HOME HEADER
    if (tabIndex == 0) {
      return SizedBox(
        height: 58,
        child: Row(
          children: [
            // PROFILE IMAGE
            Semantics(
              label: 'Open profile',
              button: true,
              child: InkWell(
                onTap: openProfile,
                borderRadius: BorderRadius.circular(30),
                child: const RiderAvatar(diameter: 48),
              ),
            ),

            const SizedBox(width: 12),

            // WELCOME + USER NAME
            Expanded(
              child: InkWell(
                onTap: openProfile,
                borderRadius: BorderRadius.circular(12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Welcome, ${state.shortName}!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _primaryText(context),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // SAFETY REPORT BUTTON
            Semantics(
              label: 'Open safety report',
              button: true,
              child: Material(
                color: isLight
                    ? _iceGlass
                    : const Color(0xFF254B66),
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Safety Report',
                  onPressed: openReport,
                  icon: Icon(
                    Icons.bar_chart_rounded,
                    color: isLight ? _iceAccent : inkWhite,
                    size: 23,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // OTHER PAGES HEADER
    return SizedBox(
      height: 58,
      child: Row(
        children: [
          Expanded(
            child: Text(
              titles[tabIndex],
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _primaryText(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (tabIndex != 4)
            Semantics(
              label: 'Open profile',
              button: true,
              child: InkWell(
                onTap: openProfile,
                borderRadius: BorderRadius.circular(24),
                child: const RiderAvatar(diameter: 43),
              ),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// RIDER AVATAR
// --------------------------------------------------

class RiderAvatar extends StatelessWidget {
  const RiderAvatar({
    super.key,
    this.diameter = 62,
  });

  final double diameter;

  @override
  Widget build(BuildContext context) {
    final photo = RiderScope.of(context).avatarBytes;
    final isLight = _isLight(context);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isLight
              ? const Color(0xFF8EC5E9)
              : const Color(0xFFB4DBF2),
          width: 1.6,
        ),
        color: isLight
            ? const Color(0xFFD9EFFD)
            : const Color(0xFF426785),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null
          ? Image.memory(
              photo,
              fit: BoxFit.cover,
            )
          : Icon(
              Icons.person_rounded,
              color: isLight ? _iceAccent : Colors.white,
              size: diameter * 0.58,
            ),
    );
  }
}

// --------------------------------------------------
// PAGE HEADING
// --------------------------------------------------

class PageHeading extends StatelessWidget {
  const PageHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 7,
        bottom: 13,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: _primaryText(context),
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.65,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: TextStyle(
              color: _secondaryText(context),
              height: 1.35,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// SECTION CAPTION
// CRASH HISTORY / WARNING HISTORY
// --------------------------------------------------

class SectionCaption extends StatelessWidget {
  const SectionCaption(
    this.title, {
    super.key,
    this.trailing,
  });

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        2, 6, 2, 11,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                // LIGHT: dark navy
                // DARK: original white
                color: _primaryText(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// --------------------------------------------------
// INFO TILE
// --------------------------------------------------

class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final isLight = _isLight(context);

    return SoftGlassCard(
      light: isLight,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: isLight
                  ? _iceGlass
                  : Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: danger
                  ? (isLight
                      ? const Color(0xFFC74752)
                      : const Color(0xFFFFB1AC))
                  : _primaryAccent(context),
              size: 21,
            ),
          ),

          const SizedBox(width: 13),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: _primaryText(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          if (onTap != null)
            Icon(
              Icons.chevron_right_rounded,
              color: _secondaryText(context),
            ),
        ],
      ),
    );
  }
}

// --------------------------------------------------
// DEMO NOTICE
// --------------------------------------------------

void showDemoNotice(
  BuildContext context,
  String message,
) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
    ),
  );
}

// --------------------------------------------------
// PRETTY DATE
// --------------------------------------------------

String prettyDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  final hour12 =
      value.hour % 12 == 0 ? 12 : value.hour % 12;

  final minute =
      value.minute.toString().padLeft(2, '0');

  return '${value.day} '
      '${months[value.month - 1]} '
      '${value.year}  •  '
      '$hour12:$minute '
      '${value.hour < 12 ? 'AM' : 'PM'}';
}
