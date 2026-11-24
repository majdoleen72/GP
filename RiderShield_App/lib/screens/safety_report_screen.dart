
// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';

// ======================================================
// LIGHT / DARK COLORS
// ======================================================

class _ReportTheme {
  static bool light(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;

  static Color text(BuildContext context) =>
      light(context)
          ? const Color(0xFF16364D)
          : inkWhite;

  static Color secondary(BuildContext context) =>
      light(context)
          ? const Color(0xFF58758C)
          : softWhite;

  static Color accent(BuildContext context) =>
      light(context)
          ? const Color(0xFF248BC7)
          : actionBlue;

  static Color sheet(BuildContext context) =>
      light(context)
          ? const Color(0xFFF8FCFF)
          : const Color(0xFF173550);

  static Color filterSheet(BuildContext context) =>
      light(context)
          ? const Color(0xFFF8FCFF)
          : const Color(0xFF142C43);

  static Color fill(BuildContext context) =>
      light(context)
          ? const Color(0xFFE5F2FC)
          : Colors.white.withValues(alpha: 0.07);

  static Color border(BuildContext context) =>
      light(context)
          ? const Color(0xFFD2E8F8)
          : Colors.white.withValues(alpha: 0.10);

  static Color selectedFill(
    BuildContext context,
    Color color,
  ) =>
      color.withValues(
        alpha: light(context) ? 0.11 : 0.20,
      );
}

// ======================================================
// SAFETY REPORT SCREEN
// ======================================================

class SafetyReportScreen extends StatefulWidget {
  const SafetyReportScreen({
    super.key,
    this.openProfile,
  });

  final VoidCallback? openProfile;

  @override
  State<SafetyReportScreen> createState() =>
      _SafetyReportScreenState();
}

class _SafetyReportScreenState
    extends State<SafetyReportScreen> {
  int _tab = 0;
  String? _filter;

  DateTimeRange? _crashDateRange;
  int? _recentDays;

  bool _isInCrashDateRange(CrashIncident incident) {
    if (_recentDays == null) return true;

    if (_recentDays != -1) {
      final today = DateUtils.dateOnly(DateTime.now());
      final start = today.subtract(
        Duration(days: _recentDays! - 1),
      );
      final end = today.add(const Duration(days: 1));

      return !incident.happenedAt.isBefore(start) &&
          incident.happenedAt.isBefore(end);
    }

    final range = _crashDateRange;
    if (range == null) return true;

    final date = incident.happenedAt;
    final start = DateUtils.dateOnly(range.start);
    final endExclusive = DateUtils.dateOnly(range.end)
        .add(const Duration(days: 1));

    return !date.isBefore(start) &&
        date.isBefore(endExclusive);
  }

  // ====================================================
  // CRASH DATE FILTER
  // ====================================================

  Future<void> _showCrashFilterSheet() async {
    final today = DateUtils.dateOnly(DateTime.now());

    int? draftDays = _recentDays;

    DateTime draftStart = _crashDateRange?.start ??
        today.subtract(const Duration(days: 29));

    DateTime draftEnd =
        _crashDateRange?.end ?? today;

    bool pickingStart = true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: _ReportTheme.filterSheet(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) {
          final isLight = _ReportTheme.light(sheetContext);
          final text = _ReportTheme.text(sheetContext);
          final secondary =
              _ReportTheme.secondary(sheetContext);
          final accent =
              _ReportTheme.accent(sheetContext);

          Widget option(String label, int? days) {
            final selected = draftDays == days;

            return InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                updateSheet(() {
                  draftDays = days;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 7),
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: .17)
                      : _ReportTheme.fill(sheetContext),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: selected
                        ? accent.withValues(alpha: .65)
                        : _ReportTheme.border(sheetContext),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: text,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected ? accent : secondary,
                      size: 21,
                    ),
                  ],
                ),
              ),
            );
          }

          Widget dateButton(
            String label,
            DateTime date,
            bool isStart,
          ) {
            final active = pickingStart == isStart;

            return Expanded(
              child: OutlinedButton(
                onPressed: () {
                  updateSheet(() {
                    pickingStart = isStart;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      active ? accent : text,
                  side: BorderSide(
                    color: active
                        ? accent
                        : _ReportTheme.border(sheetContext),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontSize: 11),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRangeDate(date),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            top: false,
            child: FractionallySizedBox(
              heightFactor: .85,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  20, 4, 20, 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter crash history',
                      style: TextStyle(
                        color: text,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Choose a time period',
                      style: TextStyle(
                        color: secondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        children: [
                          option('All time', null),
                          option('Last 7 days', 7),
                          option('Last 30 days', 30),
                          option('Last 90 days', 90),
                          option('Custom dates', -1),
                          if (draftDays == -1) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                dateButton(
                                  'From',
                                  draftStart,
                                  true,
                                ),
                                const SizedBox(width: 10),
                                dateButton(
                                  'To',
                                  draftEnd,
                                  false,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Theme(
                              data: Theme.of(sheetContext)
                                  .copyWith(
                                colorScheme: ColorScheme(
                                  brightness: isLight
                                      ? Brightness.light
                                      : Brightness.dark,
                                  primary: accent,
                                  onPrimary: isLight
                                      ? Colors.white
                                      : const Color(0xFF0E2238),
                                  secondary: accent,
                                  onSecondary: isLight
                                      ? Colors.white
                                      : const Color(0xFF0E2238),
                                  surface: isLight
                                      ? const Color(0xFFF8FCFF)
                                      : const Color(0xFF142C43),
                                  onSurface: text,
                                  error: const Color(0xFFE5484D),
                                  onError: Colors.white,
                                ),
                              ),
                              child: CalendarDatePicker(
                                key: ValueKey(pickingStart),
                                initialDate: pickingStart
                                    ? draftStart
                                    : draftEnd,
                                firstDate: DateTime(2000),
                                lastDate: today,
                                onDateChanged: (date) {
                                  updateSheet(() {
                                    if (pickingStart) {
                                      draftStart = date;
                                      if (draftEnd.isBefore(date)) {
                                        draftEnd = date;
                                      }
                                      pickingStart = false;
                                    } else {
                                      draftEnd = date;
                                      if (draftStart.isAfter(date)) {
                                        draftStart = date;
                                      }
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: isLight
                              ? Colors.white
                              : const Color(0xFF0E2238),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _recentDays = draftDays;
                            _crashDateRange = draftDays == -1
                                ? DateTimeRange(
                                    start: draftStart,
                                    end: draftEnd,
                                  )
                                : null;
                          });
                          Navigator.pop(sheetContext);
                        },
                        child: const Text(
                          'Apply filter',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _clearCrashDateRange() {
    setState(() {
      _crashDateRange = null;
      _recentDays = null;
    });
  }

  String _formatRangeDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // ====================================================
  // LOCATION HELPERS
  // ====================================================

  bool _isMapLink(String location) =>
      location.startsWith('http');

  String _placeLabel(String location) {
    if (!_isMapLink(location)) return location;

    final q = Uri.tryParse(location)?.queryParameters['q'];

    return q == null
        ? 'GPS location'
        : 'GPS: ${q.replaceAll(',', ', ')}';
  }

  Future<void> _openMap(
    BuildContext context,
    String link,
  ) async {
    final ok = await launchUrl(
      Uri.parse(link),
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open Maps.'),
        ),
      );
    }
  }

  // ====================================================
  // SOS STATUS
  // ====================================================

  bool _sosAccepted(CrashIncident incident) {
    final status = incident.notificationStatus
        .toLowerCase()
        .replaceAll('_', ' ')
        .trim();

    return status.startsWith('accept');
  }

  String _sosLabel(bool accepted) =>
      accepted ? 'SOS sent' : 'SOS not sent';

  Color _sosColor(bool accepted) => accepted
      ? const Color(0xFFFF6B72)
      : const Color(0xFF8ED5FF);

  String _statusLabel(String raw) {
    if (raw.isEmpty) return 'Unknown';

    final spaced = raw
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        )
        .replaceAll('_', ' ');

    return spaced[0].toUpperCase() +
        spaced.substring(1);
  }

  // ====================================================
  // STATUS CHIP
  // ====================================================

  Widget _chip(
    String text,
    Color color, {
    bool light = false,
  }) {
    final chipColor = light
        ? (color == const Color(0xFF8ED5FF)
            ? const Color(0xFF1879B5)
            : color)
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: chipColor.withValues(alpha: .45),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: chipColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ====================================================
  // DETAIL ROW
  // ====================================================

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: _ReportTheme.fill(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _ReportTheme.border(context),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: _ReportTheme.accent(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _ReportTheme.secondary(context),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    color: _ReportTheme.text(context),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // INCIDENT DETAILS
  // ====================================================

  void showIncident(
    BuildContext context,
    CrashIncident incident,
  ) {
    final state = RiderScope.of(context);
    final accepted = _sosAccepted(incident);
    final color = _sosColor(accepted);
    final isLight = _ReportTheme.light(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _ReportTheme.sheet(context),
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20, 4, 20, 26,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: .18),
                    ),
                    child: Icon(
                      Icons.car_crash_outlined,
                      color: color,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.testOnly
                              ? 'Test crash'
                              : 'Crash incident',
                          style: TextStyle(
                            color: _ReportTheme.text(context),
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _chip(
                          _sosLabel(accepted),
                          color,
                          light: isLight,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _detailRow(
                context,
                Icons.event_rounded,
                'Date & time',
                prettyDate(incident.happenedAt),
              ),

              _detailRow(
                context,
                Icons.place_outlined,
                'Location',
                _placeLabel(incident.location),
              ),

              _detailRow(
                context,
                Icons.notifications_active_outlined,
                'Emergency request',
                accepted
                    ? 'Sent'
                    : (_statusLabel(
                              incident.notificationStatus,
                            ) ==
                            'Not sent'
                        ? 'Not sent'
                        : 'Not sent (${_statusLabel(incident.notificationStatus)})'),
              ),

              if (incident.testOnly) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheet);
                      await state.removeIncident(incident.id);
                    },
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                    ),
                    label: const Text('Delete incident'),
                  ),
                ),
              ],

              if (_isMapLink(incident.location)) ...[
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () => _openMap(
                      context,
                      incident.location,
                    ),
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Open in Maps'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ====================================================
  // INCIDENT CARD
  // ====================================================

  Widget _incidentCard(
    BuildContext context,
    CrashIncident incident,
  ) {
    final accepted = _sosAccepted(incident);
    final color = _sosColor(accepted);

    final isLight = _ReportTheme.light(context);
    final text = _ReportTheme.text(context);
    final secondary = _ReportTheme.secondary(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: SoftGlassCard(
        light: isLight,
        onTap: () => showIncident(context, incident),
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Crash detected',
                          style: TextStyle(
                            color: text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _chip(
                        _sosLabel(accepted),
                        color,
                        light: isLight,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: secondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          prettyDate(incident.happenedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: secondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _placeLabel(incident.location),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: secondary,
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // REPORT OVERVIEW STAT
  // ====================================================

  Widget _heroStat(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    final isLight = _ReportTheme.light(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.white.withValues(alpha: .72)
              : Colors.white.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLight
                ? const Color(0xFFD2E8F8)
                : Colors.white.withValues(alpha: .12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isLight
                  ? _readableAccent(color)
                  : color,
            ),
            const SizedBox(height: 9),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ReportTheme.text(context),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _ReportTheme.secondary(context),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _readableAccent(Color color) {
    if (color == const Color(0xFF8ED5FF)) {
      return const Color(0xFF248BC7);
    }
    if (color == const Color(0xFFFFB45C)) {
      return const Color(0xFFB76A11);
    }
    if (color == const Color(0xFFFF8993)) {
      return const Color(0xFFCB4655);
    }
    return color;
  }

  // ====================================================
  // REPORT HERO
  // ====================================================

  Widget _hero(
    BuildContext context,
    List<CrashIncident> incidents,
    int warningCount,
  ) {
    final isLight = _ReportTheme.light(context);
    final clear = incidents.isEmpty;

    final accent = clear
        ? (isLight
            ? const Color(0xFF17835D)
            : const Color(0xFF7BE0AE))
        : (isLight
            ? const Color(0xFFB76A11)
            : const Color(0xFFFFA45C));

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final last = clear
        ? 'None'
        : '${incidents.first.happenedAt.day} '
            '${months[incidents.first.happenedAt.month - 1]}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? const [
                  Color(0xFFFFFFFF),
                  Color(0xFFF0F8FF),
                  Color(0xFFE3F1FC),
                ]
              : const [
                  Color(0xFF1E4E78),
                  Color(0xFF14304D),
                  Color(0xFF0E2238),
                ],
        ),
        border: Border.all(
          color: isLight
              ? const Color(0xFFD2E8F8)
              : Colors.white.withValues(alpha: .14),
        ),
        boxShadow: [
          BoxShadow(
            color: isLight
                ? const Color(0x1A7299B8)
                : const Color(0x40000000),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: .18),
                  border: Border.all(
                    color: accent.withValues(alpha: .55),
                    width: 2,
                  ),
                ),
                child: Icon(
                  clear
                      ? Icons.verified_user_rounded
                      : Icons.shield_moon_rounded,
                  color: accent,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safety Report',
                      style: TextStyle(
                        color: _ReportTheme.text(context),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.4,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      clear
                          ? 'All clear — no crashes recorded'
                          : 'Crash and warning records',
                      style: TextStyle(
                        color: accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              _heroStat(
                context,
                Icons.car_crash_outlined,
                'Total crashes',
                '${incidents.length}',
                const Color(0xFFFF8993),
              ),
              const SizedBox(width: 10),
              _heroStat(
                context,
                Icons.schedule_rounded,
                'Last crash',
                last,
                const Color(0xFF8ED5FF),
              ),
              const SizedBox(width: 10),
              _heroStat(
                context,
                Icons.warning_amber_rounded,
                'Warnings',
                '$warningCount',
                const Color(0xFFFFB45C),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================================================
  // WARNING METADATA
  // ====================================================

  (IconData, String, Color) _warningMeta(
    WarningType type,
  ) =>
      switch (type) {
        WarningType.speed => (
            Icons.speed_rounded,
            'Speed warning',
            const Color(0xFFFFB45C),
          ),
        WarningType.drowsiness => (
            Icons.bedtime_outlined,
            'Drowsiness',
            const Color(0xFFB99BFF),
          ),
        WarningType.vehicleProximity => (
            Icons.directions_car_filled_outlined,
            'Vehicle too close',
            const Color(0xFFFF8993),
          ),
      };

  (String?, String?, String?) _factors(
    WarningEvent w,
  ) {
    if (w.speedLevel == null &&
        w.drowsinessLevel == null &&
        w.proximityLevel == null) {
      return (
        w.type == WarningType.speed ? 'Low' : null,
        w.type == WarningType.drowsiness ? 'Low' : null,
        w.type == WarningType.vehicleProximity
            ? 'Low'
            : null,
      );
    }

    return (
      w.speedLevel,
      w.drowsinessLevel,
      w.proximityLevel,
    );
  }

  int _rank(String? level) => switch (level) {
        'High' => 3,
        'Medium' => 2,
        'Low' => 1,
        _ => 0,
      };

  String _warningLevel(WarningEvent w) {
    final (s, d, p) = _factors(w);

    final top = [s, d, p]
        .map(_rank)
        .reduce((a, b) => a > b ? a : b);

    return switch (top) {
      3 => 'High',
      2 => 'Medium',
      _ => 'Low',
    };
  }

  List<WarningEvent> _shownWarnings(
    RiderState state,
  ) =>
      state.warnings
          .where((w) => _warningLevel(w) != 'Low')
          .toList();

  Color _warningLevelColor(String level) =>
      switch (level) {
        'High' => const Color(0xFFFF6B72),
        'Medium' => const Color(0xFFFFB45C),
        _ => const Color(0xFF7BE0AE),
      };

  Color _displayLevelColor(
    BuildContext context,
    String level,
  ) {
    if (!_ReportTheme.light(context)) {
      return _warningLevelColor(level);
    }

    return switch (level) {
      'High' => const Color(0xFFCA4351),
      'Medium' => const Color(0xFFAA6714),
      _ => const Color(0xFF17835D),
    };
  }

  // ====================================================
  // FACTOR ROW
  // ====================================================

  Widget _factorRow(
    BuildContext context,
    IconData icon,
    String label,
    String? level,
  ) {
    final active = level != null;
    final color = level == null
        ? _ReportTheme.secondary(context)
        : _displayLevelColor(context, level);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: .12)
            : _ReportTheme.fill(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? color.withValues(alpha: .5)
              : _ReportTheme.border(context),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: _ReportTheme.text(context),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _chip(level ?? 'Normal', color),
        ],
      ),
    );
  }

  // ====================================================
  // SEGMENTED CRASHES / WARNINGS
  // ====================================================

  Widget _segmented(
    BuildContext context,
    int crashes,
    int warnings,
  ) {
    final isLight = _ReportTheme.light(context);

    Widget option(
      int index,
      IconData icon,
      String label,
      int count,
      Color color,
    ) {
      final selected = _tab == index;
      final displayColor =
          isLight ? _readableAccent(color) : color;

      return Expanded(
        child: InkWell(
          onTap: () {
            setState(() {
              _tab = index;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: selected
                  ? displayColor.withValues(alpha: .20)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? displayColor.withValues(alpha: .7)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? displayColor
                      : _ReportTheme.secondary(context),
                ),
                const SizedBox(width: 7),
                Text(
                  '$label ($count)',
                  style: TextStyle(
                    color: selected
                        ? _ReportTheme.text(context)
                        : _ReportTheme.secondary(context),
                    fontSize: 13.5,
                    fontWeight: selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _ReportTheme.fill(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _ReportTheme.border(context),
        ),
      ),
      child: Row(
        children: [
          option(
            0,
            Icons.car_crash_outlined,
            'Crashes',
            crashes,
            const Color(0xFFFF8993),
          ),
          option(
            1,
            Icons.warning_amber_rounded,
            'Warnings',
            warnings,
            const Color(0xFFFFB45C),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // WARNING CARD
  // ====================================================

  Widget _warningCard(
    BuildContext context,
    WarningEvent w,
  ) {
    final level = _warningLevel(w);
    final color = _displayLevelColor(context, level);

    final text = _ReportTheme.text(context);
    final secondary = _ReportTheme.secondary(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: SoftGlassCard(
        light: _ReportTheme.light(context),
        onTap: () => showWarning(context, w),
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Warning detected',
                          style: TextStyle(
                            color: text,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _chip(level, color),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: secondary,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          prettyDate(w.happenedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: secondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              color: secondary,
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // WARNING DETAILS
  // ====================================================

  void showWarning(
    BuildContext context,
    WarningEvent w,
  ) {
    final (icon, label, color) = _warningMeta(w.type);
    final level = _warningLevel(w);
    final levelColor = _displayLevelColor(context, level);
    final (fs, fd, fp) = _factors(w);

    final isLight = _ReportTheme.light(context);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: _ReportTheme.sheet(context),
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            20, 4, 20, 26,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withValues(alpha: .18),
                    ),
                    child: Icon(
                      icon,
                      color: isLight
                          ? _readableAccent(color)
                          : color,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            color: _ReportTheme.text(context),
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _chip(
                          '$level warning',
                          levelColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              _detailRow(
                context,
                Icons.event_rounded,
                'Date & time',
                prettyDate(w.happenedAt),
              ),

              const SizedBox(height: 6),

              Text(
                'Trigger factors',
                style: TextStyle(
                  color: _ReportTheme.secondary(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              _factorRow(
                context,
                Icons.speed_rounded,
                'Speed',
                fs,
              ),

              _factorRow(
                context,
                Icons.bedtime_outlined,
                'Drowsiness',
                fd,
              ),

              _factorRow(
                context,
                Icons.directions_car_filled_outlined,
                'Vehicle proximity',
                fp,
              ),

              const SizedBox(height: 4),

              _detailRow(
                context,
                Icons.rule_rounded,
                'Overall level',
                level,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====================================================
  // CLEAR WARNING HISTORY
  // ====================================================

  Future<void> _confirmClear(
    BuildContext context,
  ) async {
    final state = RiderScope.of(context);

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: const Text('Clear warning history?'),
        content: const Text(
          'All recorded warnings will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialog, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialog, true);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await state.clearWarnings();
    }
  }

  // ====================================================
  // CRASH FILTER BUTTON
  // ====================================================

  Widget _crashFilterButton() {
    final custom =
        _recentDays == -1 && _crashDateRange != null;

    final label = custom
        ? 'Custom range'
        : switch (_recentDays) {
            7 => 'Last 7 days',
            30 => 'Last 30 days',
            90 => 'Last 90 days',
            _ => 'All',
          };

    return InkWell(
      onTap: _showCrashFilterSheet,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: _ReportTheme.fill(context),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _ReportTheme.border(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              color: _ReportTheme.accent(context),
              size: 17,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ReportTheme.text(context),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _ReportTheme.secondary(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // WARNING FILTER SHEET
  // ====================================================

  Future<void> _showWarningFilterSheet(
    int total,
    int high,
    int medium,
  ) async {
    String? draft = _filter;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: _ReportTheme.filterSheet(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, updateSheet) {
          final isLight = _ReportTheme.light(sheetContext);
          final text = _ReportTheme.text(sheetContext);
          final secondary =
              _ReportTheme.secondary(sheetContext);
          final accent =
              _ReportTheme.accent(sheetContext);

          return SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                20, 4, 20, 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter warning history',
                    style: TextStyle(
                      color: text,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Choose a warning level',
                    style: TextStyle(
                      color: secondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 16),

                  for (final option
                      in <(String, String?, int)>[
                    ('All warnings', null, total),
                    ('High', 'High', high),
                    ('Medium', 'Medium', medium),
                  ])
                    InkWell(
                      onTap: () {
                        updateSheet(() {
                          draft = option.$2;
                        });
                      },
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: draft == option.$2
                              ? accent.withValues(alpha: .17)
                              : _ReportTheme.fill(sheetContext),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: draft == option.$2
                                ? accent.withValues(alpha: .65)
                                : _ReportTheme.border(sheetContext),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${option.$1} (${option.$3})',
                                style: TextStyle(
                                  color: text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Icon(
                              draft == option.$2
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: draft == option.$2
                                  ? accent
                                  : secondary,
                              size: 21,
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: isLight
                            ? Colors.white
                            : const Color(0xFF0E2238),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _filter = draft;
                        });
                        Navigator.pop(sheetContext);
                      },
                      child: const Text(
                        'Apply filter',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ====================================================
  // WARNING FILTER BUTTON
  // ====================================================

  Widget _warningFilterButton(
    int total,
    int high,
    int medium,
  ) {
    final label = _filter ?? 'All';

    return InkWell(
      onTap: () =>
          _showWarningFilterSheet(total, high, medium),
      borderRadius: BorderRadius.circular(13),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: _ReportTheme.fill(context),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: _ReportTheme.border(context),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              color: _ReportTheme.accent(context),
              size: 17,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: _ReportTheme.text(context),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 3),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _ReportTheme.secondary(context),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // CRASH HISTORY SECTION
  // ====================================================

  List<Widget> _crashSection(
    BuildContext context,
    RiderState state,
  ) {
    final all = state.incidents;
    final shown =
        all.where(_isInCrashDateRange).toList();

    return [
      SectionCaption(
        'Crash history',
        trailing: _crashFilterButton(),
      ),

      if (_recentDays == -1 &&
          _crashDateRange != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            '${_formatRangeDate(_crashDateRange!.start)} – ${_formatRangeDate(_crashDateRange!.end)}',
            style: TextStyle(
              color: _ReportTheme.secondary(context),
              fontSize: 12,
            ),
          ),
        ),

      if (shown.isEmpty)
        SoftGlassCard(
          light: _ReportTheme.light(context),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 26,
          ),
          child: Column(
            children: [
              Icon(
                all.isEmpty
                    ? Icons.verified_user_outlined
                    : Icons.calendar_month_outlined,
                color: _ReportTheme.accent(context),
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                all.isEmpty
                    ? 'No crashes recorded'
                    : 'No crashes in this date range',
                style: TextStyle(
                  color: _ReportTheme.text(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                all.isEmpty
                    ? 'Crashes detected during your rides will appear here.'
                    : 'Try selecting another date range or reset the filter to see all crash reports.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ReportTheme.secondary(context),
                  height: 1.4,
                ),
              ),
              if (all.isNotEmpty &&
                  _crashDateRange != null) ...[
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: _clearCrashDateRange,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Show all crash reports',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        _ReportTheme.accent(context),
                  ),
                ),
              ],
            ],
          ),
        ),

      for (final incident in shown)
        _incidentCard(context, incident),
    ];
  }

  // ====================================================
  // WARNING HISTORY SECTION
  // ====================================================

  List<Widget> _warningSection(
    BuildContext context,
    RiderState state,
  ) {
    final all = _shownWarnings(state);

    final shown = _filter == null
        ? all
        : all
            .where(
              (w) => _warningLevel(w) == _filter,
            )
            .toList();

    int count(String level) =>
        all.where((w) => _warningLevel(w) == level)
            .length;

    return [
      SectionCaption(
        'Warning history',
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _warningFilterButton(
              all.length,
              count('High'),
              count('Medium'),
            ),

            if (all.isNotEmpty) ...[
              const SizedBox(width: 4),
              TextButton(
                onPressed: () => _confirmClear(context),
                style: TextButton.styleFrom(
                  foregroundColor:
                      const Color(0xFFFF8F8F),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                  ),
                  minimumSize: const Size(0, 36),
                ),
                child: const Text(
                  'Clear all',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),

      const SizedBox(height: 8),

      if (shown.isEmpty)
        SoftGlassCard(
          light: _ReportTheme.light(context),
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 26,
          ),
          child: Column(
            children: [
              Icon(
                Icons.shield_outlined,
                color: _ReportTheme.accent(context),
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                'No warnings recorded',
                style: TextStyle(
                  color: _ReportTheme.text(context),
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                'Warnings detected during your rides will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _ReportTheme.secondary(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),

      for (final w in shown)
        _warningCard(context, w),
    ];
  }

  // ====================================================
  // MAIN SCREEN
  // ====================================================

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final warningCount =
        _shownWarnings(state).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        20, 14, 20, 24,
      ),
      children: [
        _hero(
          context,
          state.incidents,
          warningCount,
        ),

        const SizedBox(height: 18),

        _segmented(
          context,
          state.incidents.length,
          warningCount,
        ),

        const SizedBox(height: 20),

        if (_tab == 0)
          ..._crashSection(context, state)
        else
          ..._warningSection(context, state),
      ],
    );
  }
}
