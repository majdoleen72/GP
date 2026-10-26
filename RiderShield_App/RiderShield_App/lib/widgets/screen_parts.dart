import 'package:flutter/material.dart';
import '../app/app_scope.dart';
import 'soft_glass_card.dart';

const inkWhite = Color(0xFFF6FAFF);
const softWhite = Color(0xFFBFD2E0);
const actionBlue = Color(0xFF9DDBFF);

class RiderHeader extends StatelessWidget {
  const RiderHeader({super.key, required this.openProfile});
  final VoidCallback openProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset('assets/images/ridershield_shield.png', width: 40, height: 45, fit: BoxFit.contain),
        const SizedBox(width: 8),
        Flexible(
          child: Image.asset('assets/images/ridershield_wordmark.png',
            width: 178, height: 33, fit: BoxFit.contain, alignment: Alignment.centerLeft),
        ),
        const Spacer(),
        Semantics(
          label: 'Open profile', button: true,
          child: InkWell(
            onTap: openProfile,
            borderRadius: BorderRadius.circular(24),
            child: RiderAvatar(diameter: 44),
          ),
        ),
      ],
    );
  }
}

/// Small fixed title bar for the dashboard. No repeated wordmark on subpages.
class RiderPinnedHeader extends StatelessWidget {
  const RiderPinnedHeader({
    super.key,
    required this.tabIndex,
    required this.openProfile,
  });
  final int tabIndex;
  final VoidCallback openProfile;

  static const titles = ['RiderShield', 'Safety Report', 'Emergency', 'Connect Helmet', 'Profile'];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 45,
    child: Row(children: [
      if (tabIndex == 0) ...[
        Image.asset('assets/images/ridershield_shield.png',
          width: 30, height: 34, fit: BoxFit.contain),
        const SizedBox(width: 8),
      ],
      Expanded(child: Text(titles[tabIndex], maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: inkWhite, fontSize: 18,
          fontWeight: FontWeight.w700))),
      Semantics(
        label: 'Open profile', button: true,
        child: InkWell(
          onTap: openProfile,
          borderRadius: BorderRadius.circular(23),
          child: const RiderAvatar(diameter: 43),
        ),
      ),
    ]),
  );
}

class RiderAvatar extends StatelessWidget {
  const RiderAvatar({super.key, this.diameter = 62});
  final double diameter;

  @override
  Widget build(BuildContext context) {
    final photo = RiderScope.of(context).avatarBytes;
    return Container(
      width: diameter, height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFB4DBF2), width: 1.6),
        color: const Color(0xFF426785),
      ),
      clipBehavior: Clip.antiAlias,
      child: photo != null
          ? Image.memory(photo, fit: BoxFit.cover)
          : Icon(Icons.person_rounded, color: Colors.white, size: diameter * .58),
    );
  }
}

class PageHeading extends StatelessWidget {
  const PageHeading({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 7, bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: inkWhite, fontSize: 25,
            fontWeight: FontWeight.w700, letterSpacing: -.65)),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: softWhite, height: 1.35, fontSize: 13)),
      ],
    ),
  );
}

class SectionCaption extends StatelessWidget {
  const SectionCaption(this.title, {super.key, this.trailing});
  final String title;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 6, 2, 11),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(color: inkWhite, fontSize: 18,
          fontWeight: FontWeight.w700))),
      if (trailing != null) trailing!,
    ]),
  );
}

class InfoTile extends StatelessWidget {
  const InfoTile({super.key, required this.icon, required this.title, required this.value,
    this.onTap, this.danger = false});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool danger;
  @override
  Widget build(BuildContext context) => SoftGlassCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
    child: Row(children: [
      Container(
        height: 40, width: 40,
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .12),
            borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: danger ? const Color(0xFFFFB1AC) : actionBlue, size: 21),
      ),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: softWhite, fontSize: 12)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(color: inkWhite, fontSize: 15,
            fontWeight: FontWeight.w600)),
      ])),
      if (onTap != null) const Icon(Icons.chevron_right_rounded, color: softWhite),
    ]),
  );
}

void showDemoNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message), behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 3),
  ));
}

String prettyDate(DateTime value) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.day} ${months[value.month - 1]} ${value.year}  •  $hour12:$minute ${value.hour < 12 ? 'AM' : 'PM'}';
}
