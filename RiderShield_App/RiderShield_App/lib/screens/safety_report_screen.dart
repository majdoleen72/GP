import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app/app_scope.dart';
import '../app/app_state.dart';
import '../widgets/screen_parts.dart';
import '../widgets/soft_glass_card.dart';

// NOTE: WarningEvent (in app_state.dart) has speedLevel, drowsinessLevel and
// proximityLevel ('High' / 'Medium' / 'Low' / null) and RiderState has addWarning.

class SafetyReportScreen extends StatefulWidget {
  const SafetyReportScreen({super.key, this.openProfile});
  final VoidCallback? openProfile;

  @override
  State<SafetyReportScreen> createState() => _SafetyReportScreenState();
}

class _SafetyReportScreenState extends State<SafetyReportScreen> {
  int _tab = 0;
  String? _filter;

  // Crash date-range filter
  DateTimeRange? _crashDateRange;

  bool _isInCrashDateRange(CrashIncident incident) {
    final range = _crashDateRange;
    if (range == null) return true;

    final date = incident.happenedAt;
    final start = DateUtils.dateOnly(range.start);
    final endExclusive =
        DateUtils.dateOnly(range.end).add(const Duration(days: 1));

    return !date.isBefore(start) && date.isBefore(endExclusive);
  }

  Future<void> _pickCrashDateRange(BuildContext context) async {
    final now = DateUtils.dateOnly(DateTime.now());

    final initial = _crashDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );

    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: initial.start.isAfter(now) ? now : initial.start,
        end: initial.end.isAfter(now) ? now : initial.end,
      ),
      helpText: 'Select crash report dates',
      saveText: 'Apply filter',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: actionBlue,
            onPrimary: Color(0xFF0E2238),
            surface: Color(0xFF173550),
            onSurface: inkWhite,
          ),
          dialogBackgroundColor: const Color(0xFF173550),
        ),
        child: child!,
      ),
    );

    if (!mounted || selected == null) return;

    setState(() {
      _crashDateRange = selected;
    });
  }

  void _clearCrashDateRange() {
    setState(() {
      _crashDateRange = null;
    });
  }

  String _formatRangeDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Location helpers
  bool _isMapLink(String location) => location.startsWith('http');

  String _placeLabel(String location) {
    if (!_isMapLink(location)) return location;
    final q = Uri.tryParse(location)?.queryParameters['q'];
    return q == null ? 'GPS location' : 'GPS: ${q.replaceAll(',', ', ')}';
  }

  Future<void> _openMap(BuildContext context, String link) async {
    final ok = await launchUrl(
      Uri.parse(link),
      mode: LaunchMode.externalApplication,
    );

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps.')),
      );
    }
  }

  // Crashes are classified by the SOS emergency request.
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

    return spaced[0].toUpperCase() + spaced.substring(1);
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: .45)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _detailRow(IconData icon, String label, String value) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: .10)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: actionBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: softWhite,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: inkWhite,
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

  // ---------- Accident details ----------

  void showIncident(BuildContext context, CrashIncident incident) {
    final state = RiderScope.of(context);
    final accepted = _sosAccepted(incident);
    final color = _sosColor(accepted);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF173550),
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          incident.testOnly
                              ? 'Test crash'
                              : 'Crash incident',
                          style: const TextStyle(
                            color: inkWhite,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _chip(_sosLabel(accepted), color),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(
                Icons.event_rounded,
                'Date & time',
                prettyDate(incident.happenedAt),
              ),
              _detailRow(
                Icons.place_outlined,
                'Location',
                _placeLabel(incident.location),
              ),
              _detailRow(
                Icons.notifications_active_outlined,
                'Emergency request',
                accepted
                    ? 'Sent'
                    : (_statusLabel(incident.notificationStatus) == 'Not sent'
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
                    icon: const Icon(Icons.delete_outline_rounded),
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
                    onPressed: () => _openMap(context, incident.location),
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

  // ---------- Accident card ----------

  Widget _incidentCard(
    BuildContext context,
    CrashIncident incident,
  ) {
    final accepted = _sosAccepted(incident);
    final color = _sosColor(accepted);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: SoftGlassCard(
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
                      const Expanded(
                        child: Text(
                          'Crash detected',
                          style: TextStyle(
                            color: inkWhite,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _chip(_sosLabel(accepted), color),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: softWhite,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          prettyDate(incident.happenedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: softWhite,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: softWhite,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          _placeLabel(incident.location),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: softWhite,
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
            const Icon(
              Icons.chevron_right_rounded,
              color: softWhite,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Report overview ----------

  Widget _heroStat(
    IconData icon,
    String label,
    String value,
    Color color,
  ) =>
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: .12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(height: 9),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: inkWhite,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: softWhite,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ),
      );

  Widget _hero(
    List<CrashIncident> incidents,
    int warningCount,
  ) {
    final clear = incidents.isEmpty;
    final accent = clear
        ? const Color(0xFF7BE0AE)
        : const Color(0xFFFFA45C);

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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E4E78),
            Color(0xFF14304D),
            Color(0xFF0E2238),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: .14),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 22,
            offset: Offset(0, 10),
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
                    const Text(
                      'Safety Report',
                      style: TextStyle(
                        color: inkWhite,
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
                Icons.car_crash_outlined,
                'Total crashes',
                '${incidents.length}',
                const Color(0xFFFF8993),
              ),
              const SizedBox(width: 10),
              _heroStat(
                Icons.schedule_rounded,
                'Last crash',
                last,
                const Color(0xFF8ED5FF),
              ),
              const SizedBox(width: 10),
              _heroStat(
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

  // ---------- Warning history ----------

  (IconData, String, Color) _warningMeta(WarningType type) =>
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

  // ---------- Warning level ----------

  (String?, String?, String?) _factors(WarningEvent w) {
    if (w.speedLevel == null &&
        w.drowsinessLevel == null &&
        w.proximityLevel == null) {
      return (
        w.type == WarningType.speed ? 'Low' : null,
        w.type == WarningType.drowsiness ? 'Low' : null,
        w.type == WarningType.vehicleProximity ? 'Low' : null,
      );
    }
    return (w.speedLevel, w.drowsinessLevel, w.proximityLevel);
  }

  int _rank(String? level) => switch (level) {
        'High' => 3,
        'Medium' => 2,
        'Low' => 1,
        _ => 0,
      };

  String _warningLevel(WarningEvent w) {
    final (s, d, p) = _factors(w);
    final top = [s, d, p].map(_rank).reduce((a, b) => a > b ? a : b);
    return switch (top) {
      3 => 'High',
      2 => 'Medium',
      _ => 'Low',
    };
  }

  // Only High and Medium warnings are shown.
  List<WarningEvent> _shownWarnings(RiderState state) =>
      state.warnings.where((w) => _warningLevel(w) != 'Low').toList();

  Color _warningLevelColor(String level) => switch (level) {
        'High' => const Color(0xFFFF6B72),
        'Medium' => const Color(0xFFFFB45C),
        _ => const Color(0xFF7BE0AE),
      };

  Widget _factorRow(IconData icon, String label, String? level) {
    final active = level != null;
    final color = level == null ? softWhite : _warningLevelColor(level);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active
            ? color.withValues(alpha: .12)
            : Colors.white.withValues(alpha: .06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: active
              ? color.withValues(alpha: .5)
              : Colors.white.withValues(alpha: .10),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: inkWhite,
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

  // ---------- Crashes / warnings tabs ----------

  Widget _segmented(int crashes, int warnings) {
    Widget option(
      int index,
      IconData icon,
      String label,
      int count,
      Color color,
    ) {
      final selected = _tab == index;

      return Expanded(
        child: InkWell(
          onTap: () => setState(() => _tab = index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: selected
                  ? color.withValues(alpha: .20)
                  : Colors.transparent,
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: .7)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? color : softWhite,
                ),
                const SizedBox(width: 7),
                Text(
                  '$label ($count)',
                  style: TextStyle(
                    color: selected ? inkWhite : softWhite,
                    fontSize: 13.5,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
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
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: .10),
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

  Widget _filterPill(
    String label,
    bool selected,
    Color color,
    VoidCallback onTap,
  ) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: selected
                ? color.withValues(alpha: .20)
                : Colors.white.withValues(alpha: .06),
            border: Border.all(
              color: selected
                  ? color.withValues(alpha: .7)
                  : Colors.white.withValues(alpha: .12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? color : softWhite,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );

  // ---------- Warning card ----------

  // Numerical measurements are intentionally hidden.
  Widget _warningCard(BuildContext context, WarningEvent w) {
    final level = _warningLevel(w);
    final color = _warningLevelColor(level);

    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: SoftGlassCard(
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
                      const Expanded(
                        child: Text(
                          'Warning detected',
                          style: TextStyle(
                            color: inkWhite,
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
                      const Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: softWhite,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          prettyDate(w.happenedAt),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: softWhite,
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
            const Icon(
              Icons.chevron_right_rounded,
              color: softWhite,
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Warning details ----------

  void showWarning(BuildContext context, WarningEvent w) {
    final (icon, label, color) = _warningMeta(w.type);
    final level = _warningLevel(w);
    final levelColor = _warningLevelColor(level);
    final (fs, fd, fp) = _factors(w);

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF173550),
      builder: (sheet) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 26),
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
                      color: color,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            color: inkWhite,
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _chip('$level warning', levelColor),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _detailRow(
                Icons.event_rounded,
                'Date & time',
                prettyDate(w.happenedAt),
              ),
              const SizedBox(height: 6),
              const Text(
                'Trigger factors',
                style: TextStyle(
                  color: softWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _factorRow(Icons.speed_rounded, 'Speed', fs),
              _factorRow(Icons.bedtime_outlined, 'Drowsiness', fd),
              _factorRow(
                Icons.directions_car_filled_outlined,
                'Vehicle proximity',
                fp,
              ),
              const SizedBox(height: 4),
              _detailRow(
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

  // ---------- Clear warning history ----------

  Future<void> _confirmClear(BuildContext context) async {
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
            onPressed: () => Navigator.pop(dialog, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await state.clearWarnings();
    }
  }

  // ---------- Crash history ----------

  Widget _crashDateFilter(int total, int filtered) {
    final range = _crashDateRange;
    final hasFilter = range != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: .12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: actionBlue.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: actionBlue,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter by date',
                      style: TextStyle(
                        color: inkWhite,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Choose a date range for crash reports',
                      style: TextStyle(
                        color: softWhite,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasFilter)
                IconButton(
                  onPressed: _clearCrashDateRange,
                  tooltip: 'Clear date filter',
                  icon: const Icon(
                    Icons.close_rounded,
                    color: softWhite,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _pickCrashDateRange(context),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: actionBlue.withValues(alpha: .35),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range_rounded,
                    color: actionBlue,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasFilter
                          ? '${_formatRangeDate(range.start)} - ${_formatRangeDate(range.end)}'
                          : 'Select start and end dates',
                      style: const TextStyle(
                        color: inkWhite,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: softWhite,
                  ),
                ],
              ),
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.filter_alt_rounded,
                  color: actionBlue,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  '$filtered of $total crash reports',
                  style: const TextStyle(
                    color: softWhite,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearCrashDateRange,
                  style: TextButton.styleFrom(
                    foregroundColor: actionBlue,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Reset filter'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _crashSection(
    BuildContext context,
    RiderState state,
  ) {
    final all = state.incidents;
    final shown = all.where(_isInCrashDateRange).toList();

    return [
      const SectionCaption('Crash history'),

      _crashDateFilter(all.length, shown.length),

      if (shown.isEmpty)
        SoftGlassCard(
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
                color: actionBlue,
                size: 42,
              ),
              const SizedBox(height: 12),
              Text(
                all.isEmpty
                    ? 'No crashes recorded'
                    : 'No crashes in this date range',
                style: const TextStyle(
                  color: inkWhite,
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
                style: const TextStyle(
                  color: softWhite,
                  height: 1.4,
                ),
              ),
              if (all.isNotEmpty && _crashDateRange != null) ...[
                const SizedBox(height: 14),
                TextButton.icon(
                  onPressed: _clearCrashDateRange,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Show all crash reports'),
                  style: TextButton.styleFrom(
                    foregroundColor: actionBlue,
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

  // ---------- Warning history section ----------

  List<Widget> _warningSection(
    BuildContext context,
    RiderState state,
  ) {
    final all = _shownWarnings(state);

    final shown = _filter == null
        ? all
        : all.where((w) => _warningLevel(w) == _filter).toList();

    int count(String level) =>
        all.where((w) => _warningLevel(w) == level).length;

    return [
      SectionCaption(
        'Warning history',
        trailing: all.isEmpty
            ? null
            : TextButton(
                onPressed: () => _confirmClear(context),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFFF8F8F),
                ),
                child: const Text('Clear all'),
              ),
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _filterPill(
            'All (${all.length})',
            _filter == null,
            actionBlue,
            () => setState(() => _filter = null),
          ),
          for (final l in const ['High', 'Medium'])
            _filterPill(
              '$l (${count(l)})',
              _filter == l,
              _warningLevelColor(l),
              () => setState(() => _filter = l),
            ),
        ],
      ),
      const SizedBox(height: 14),
      if (shown.isEmpty)
        const SoftGlassCard(
          padding: EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 26,
          ),
          child: Column(
            children: [
              Icon(
                Icons.shield_outlined,
                color: actionBlue,
                size: 42,
              ),
              SizedBox(height: 12),
              Text(
                'No warnings recorded',
                style: TextStyle(
                  color: inkWhite,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 7),
              Text(
                'Warnings detected during your rides will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: softWhite,
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

  // ---------- Main screen ----------

  @override
  Widget build(BuildContext context) {
    final state = RiderScope.of(context);
    final warningCount = _shownWarnings(state).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 115),
      children: [
        _hero(state.incidents, warningCount),
        const SizedBox(height: 18),
        _segmented(
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