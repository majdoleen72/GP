import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyContact {
  const EmergencyContact({required this.id, required this.name, required this.phone, required this.relationship});
  final String id;
  final String name;
  final String phone;
  final String relationship;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'phone': phone, 'relationship': relationship};
  factory EmergencyContact.fromJson(Map<String, dynamic> j) => EmergencyContact(
        id: '${j['id'] ?? ''}', name: '${j['name'] ?? ''}',
        phone: '${j['phone'] ?? ''}', relationship: '${j['relationship'] ?? ''}',
      );
}

class CrashIncident {
  const CrashIncident({required this.id, required this.happenedAt, required this.location, required this.severity, required this.sosSent, this.notificationStatus = 'notSent', this.testOnly = true});
  final String id;
  final DateTime happenedAt;
  final String location;
  final String severity;
  final bool sosSent;
  final String notificationStatus;
  final bool testOnly;

  Map<String, dynamic> toJson() => {
        'id': id, 'happenedAt': happenedAt.toIso8601String(),
        'location': location, 'severity': severity, 'sosSent': sosSent,
        'notificationStatus': notificationStatus, 'testOnly': testOnly,
      };
  factory CrashIncident.fromJson(Map<String, dynamic> j) => CrashIncident(
        id: '${j['id'] ?? ''}',
        happenedAt: DateTime.tryParse('${j['happenedAt'] ?? ''}') ?? DateTime.now(),
        location: '${j['location'] ?? 'Not recorded'}',
        severity: '${j['severity'] ?? 'Unknown'}',
        sosSent: j['sosSent'] == true,
        notificationStatus: '${j['notificationStatus'] ?? 'notSent'}',
        testOnly: j['testOnly'] != false,
      );
}

/// Kinds of ride warnings shown in the Safety Report's warning history.
enum WarningType { speed, drowsiness, vehicleProximity }

class WarningEvent {
  const WarningEvent({
    required this.id,
    required this.happenedAt,
    required this.type,
    this.detail = '',
    this.speedLevel,
    this.drowsinessLevel,
    this.proximityLevel,
  });
  final String id;
  final DateTime happenedAt;
  final WarningType type;
  /// Optional short text, e.g. "92 km/h in a 60 zone".
  final String detail;

  /// Level of each of the three factors: 'High', 'Medium', 'Low',
  /// or null when that factor was not triggered.
  /// The warning's overall level is the highest of the three
  /// (if any factor is High, the warning is High).
  /// All null = old record, the screen falls back to [type].
  final String? speedLevel;
  final String? drowsinessLevel;
  final String? proximityLevel;

  Map<String, dynamic> toJson() => {
        'id': id, 'happenedAt': happenedAt.toIso8601String(),
        'type': type.name, 'detail': detail,
        'speedLevel': speedLevel,
        'drowsinessLevel': drowsinessLevel,
        'proximityLevel': proximityLevel,
      };
  factory WarningEvent.fromJson(Map<String, dynamic> j) => WarningEvent(
        id: '${j['id'] ?? ''}',
        happenedAt: DateTime.tryParse('${j['happenedAt'] ?? ''}') ?? DateTime.now(),
        type: WarningType.values.firstWhere(
          (t) => t.name == j['type'], orElse: () => WarningType.speed),
        detail: '${j['detail'] ?? ''}',
        speedLevel: j['speedLevel'] as String?,
        drowsinessLevel: j['drowsinessLevel'] as String?,
        proximityLevel: j['proximityLevel'] as String?,
      );
}

/// Prototype state: local persistence only. No real login or Bluetooth.
/// GPS and SOS are routed through an optional emergency service (not configured).
class RiderState extends ChangeNotifier {
  RiderState._(this._prefs);
  final SharedPreferences _prefs;

  String fullName = '';
  String email = '';
  String phone = '';
  String city = '';
  String ridingExperience = 'Beginner';
  String avatarBase64 = '';
  String coverBase64 = '';
  final List<EmergencyContact> contacts = [];
  final List<CrashIncident> incidents = [];
  final List<WarningEvent> warnings = [];
  bool demoHelmetConnected = false;
  double demoSpeed = 0;
  String demoRisk = 'Not monitoring';

  static const _maxWarnings = 300;
  int _seq = 0;
  String _newId() => '${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  static Future<RiderState> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final s = RiderState._(prefs);
    s.fullName = prefs.getString('rs_name') ?? '';
    s.email = prefs.getString('rs_email') ?? '';
    s.phone = prefs.getString('rs_phone') ?? '';
    s.city = prefs.getString('rs_city') ?? '';
    s.ridingExperience = prefs.getString('rs_experience') ?? 'Beginner';
    s.avatarBase64 = prefs.getString('rs_avatar') ?? '';
    s.coverBase64 = prefs.getString('rs_cover') ?? '';
    try {
      final raw = jsonDecode(prefs.getString('rs_contacts') ?? '[]') as List<dynamic>;
      s.contacts.addAll(raw.map((e) => EmergencyContact.fromJson(Map<String, dynamic>.from(e as Map))));
    } catch (_) { /* Keep contacts empty when a local record is corrupted. */ }
    try {
      final raw = jsonDecode(prefs.getString('rs_incidents') ?? '[]') as List<dynamic>;
      s.incidents.addAll(raw.map((e) => CrashIncident.fromJson(Map<String, dynamic>.from(e as Map))));
      s.incidents.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    } catch (_) { /* Keep reports empty when a local record is corrupted. */ }
    try {
      final raw = jsonDecode(prefs.getString('rs_warnings') ?? '[]') as List<dynamic>;
      s.warnings.addAll(raw.map((e) => WarningEvent.fromJson(Map<String, dynamic>.from(e as Map))));
      s.warnings.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    } catch (_) { /* Keep warning history empty when a local record is corrupted. */ }
    // TEMPORARY (supervisor demo): preload sample reports once, on first launch.
    // Key bumped to v4 so the new High/Medium/Low warning samples load once
    // even on devices that already ran v1.
    // Delete this block and _seedSamples() before the final version.
    if (!(prefs.getBool('rs_demo_seeded_v4') ?? false)) {
      s._seedSamples();
      await prefs.setString('rs_incidents', jsonEncode(s.incidents.map((i) => i.toJson()).toList()));
      await prefs.setString('rs_warnings', jsonEncode(s.warnings.map((w) => w.toJson()).toList()));
      await prefs.setBool('rs_demo_seeded_v4', true);
    }
    // TEMPORARY (supervisor demo): preload sample emergency contacts once.
    // Delete this block before the final version.
    if (!(prefs.getBool('rs_demo_contacts_v1') ?? false)) {
      if (s.contacts.isEmpty) {
        s.contacts.addAll(const [
          EmergencyContact(id: 'sample_1', name: 'Sara Alharbi',
            relationship: 'Sister', phone: '+966500000001'),
          EmergencyContact(id: 'sample_2', name: 'Khalid Alharbi',
            relationship: 'Father', phone: '+966500000002'),
          EmergencyContact(id: 'sample_3', name: 'Noura Alqahtani',
            relationship: 'Friend', phone: '+966500000003'),
        ]);
        await prefs.setString('rs_contacts', jsonEncode(s.contacts.map((c) => c.toJson()).toList()));
      }
      await prefs.setBool('rs_demo_contacts_v1', true);
    }
    return s;
  }

  // TEMPORARY (supervisor demo): sample crashes and warnings.
  void _seedSamples() {
    final now = DateTime.now();
    var n = 0;
    String id() => '${now.microsecondsSinceEpoch}_s${n++}';
    // Remove old demo entries (testOnly ones and earlier seeded ones, whose id has "_s").
    incidents.removeWhere((i) => i.testOnly || i.id.contains('_s'));
    warnings.clear();
    incidents.addAll([
      CrashIncident(id: id(), happenedAt: now.subtract(const Duration(days: 5, hours: 2)),
        location: 'https://maps.google.com/?q=24.7136,46.6753', severity: 'Minor',
        sosSent: false, notificationStatus: 'notSent', testOnly: false),
      CrashIncident(id: id(), happenedAt: now.subtract(const Duration(days: 2, hours: 6)),
        location: 'https://maps.google.com/?q=24.8000,46.6400', severity: 'Moderate',
        sosSent: true, notificationStatus: 'accepted', testOnly: false),
      CrashIncident(id: id(), happenedAt: now.subtract(const Duration(hours: 3)),
        location: 'https://maps.google.com/?q=24.9570,46.6980', severity: 'Severe',
        sosSent: true, notificationStatus: 'accepted', testOnly: false),
    ]);
    warnings.addAll([
      // HIGH: one factor is High
      WarningEvent(id: id(), type: WarningType.vehicleProximity,
        detail: 'Vehicle 2 m ahead',
        happenedAt: now.subtract(const Duration(minutes: 40)),
        speedLevel: 'Medium', drowsinessLevel: 'Low', proximityLevel: 'High'),
      WarningEvent(id: id(), type: WarningType.drowsiness,
        detail: 'Eyes closed for 3 seconds',
        happenedAt: now.subtract(const Duration(days: 2, hours: 1)),
        drowsinessLevel: 'High', proximityLevel: 'Low'),
      // MEDIUM: highest factor is Medium
      WarningEvent(id: id(), type: WarningType.speed,
        detail: '92 km/h in a 60 km/h zone',
        happenedAt: now.subtract(const Duration(hours: 2, minutes: 20)),
        speedLevel: 'Medium', proximityLevel: 'Low'),
      WarningEvent(id: id(), type: WarningType.drowsiness,
        detail: 'Frequent yawning detected',
        happenedAt: now.subtract(const Duration(days: 1, hours: 4)),
        speedLevel: 'Low', drowsinessLevel: 'Medium'),
      WarningEvent(id: id(), type: WarningType.vehicleProximity,
        detail: 'Vehicle 3 m ahead',
        happenedAt: now.subtract(const Duration(days: 3)),
        drowsinessLevel: 'Low', proximityLevel: 'Medium'),
    ]);
    incidents.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    warnings.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
  }

  String get shortName => fullName.trim().isEmpty ? 'Rider' : fullName.trim().split(RegExp(r'\s+')).first;
  Uint8List? get avatarBytes => _decode(avatarBase64);
  Uint8List? get coverBytes => _decode(coverBase64);
  Uint8List? _decode(String value) {
    if (value.isEmpty) return null;
    try { return base64Decode(value); } catch (_) { return null; }
  }

  void setLoginDetails({String? name, String? emailAddress}) {
    if (name != null && name.trim().isNotEmpty) fullName = name.trim();
    if (emailAddress != null && emailAddress.trim().isNotEmpty) email = emailAddress.trim();
    _saveProfile();
    notifyListeners();
  }

  Future<void> updateProfile({required String name, required String emailAddress, required String phoneNumber, required String cityName, required String experience}) async {
    fullName = name.trim(); email = emailAddress.trim(); phone = phoneNumber.trim();
    city = cityName.trim(); ridingExperience = experience;
    notifyListeners();
    await _saveProfile();
  }

  Future<void> setProfileImage(Uint8List bytes, {required bool cover}) async {
    if (cover) {
      coverBase64 = base64Encode(bytes);
      await _prefs.setString('rs_cover', coverBase64);
    } else {
      avatarBase64 = base64Encode(bytes);
      await _prefs.setString('rs_avatar', avatarBase64);
    }
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    await _prefs.setString('rs_name', fullName);
    await _prefs.setString('rs_email', email);
    await _prefs.setString('rs_phone', phone);
    await _prefs.setString('rs_city', city);
    await _prefs.setString('rs_experience', ridingExperience);
  }

  Future<void> upsertContact(EmergencyContact value) async {
    final index = contacts.indexWhere((c) => c.id == value.id);
    if (index == -1) { contacts.add(value); } else { contacts[index] = value; }
    notifyListeners();
    await _prefs.setString('rs_contacts', jsonEncode(contacts.map((c) => c.toJson()).toList()));
  }

  Future<void> deleteContact(String id) async {
    contacts.removeWhere((c) => c.id == id);
    notifyListeners();
    await _prefs.setString('rs_contacts', jsonEncode(contacts.map((c) => c.toJson()).toList()));
  }

  Future<void> recordCrash({required String location, required String notificationStatus,
    required bool testOnly}) async {
    incidents.insert(0, CrashIncident(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      happenedAt: DateTime.now(),
      location: location,
      severity: 'Not assessed', sosSent: false,
      notificationStatus: notificationStatus, testOnly: testOnly,
    ));
    notifyListeners();
    await _prefs.setString('rs_incidents', jsonEncode(incidents.map((i) => i.toJson()).toList()));
  }

  Future<void> addDemoIncident({required String severity, required String location, DateTime? at}) async {
    incidents.insert(0, CrashIncident(
      id: _newId(),
      happenedAt: at ?? DateTime.now(), location: location.isEmpty ? 'Demo location not recorded' : location,
      severity: severity, sosSent: false,
    ));
    incidents.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    notifyListeners();
    await _prefs.setString('rs_incidents', jsonEncode(incidents.map((i) => i.toJson()).toList()));
  }

  Future<void> removeIncident(String id) async {
    incidents.removeWhere((i) => i.id == id);
    notifyListeners();
    await _prefs.setString('rs_incidents', jsonEncode(incidents.map((i) => i.toJson()).toList()));
  }

  // ---- Warning history (speed / drowsiness / vehicle proximity) ----

  /// Call this from the speed, drowsiness or proximity detector whenever a
  /// warning is raised, e.g.
  /// `state.recordWarning(type: WarningType.speed, detail: '92 km/h in a 60 zone',
  ///   speedLevel: 'Medium', proximityLevel: 'Low');`
  /// Levels are 'High', 'Medium', 'Low' or null (factor not triggered).
  Future<void> recordWarning({
    required WarningType type,
    String detail = '',
    DateTime? at,
    String? speedLevel,
    String? drowsinessLevel,
    String? proximityLevel,
  }) =>
      addWarning(WarningEvent(
        id: _newId(),
        happenedAt: at ?? DateTime.now(),
        type: type,
        detail: detail,
        speedLevel: speedLevel,
        drowsinessLevel: drowsinessLevel,
        proximityLevel: proximityLevel,
      ));

  /// Adds a ready-made WarningEvent (used by the sample buttons and recordWarning).
  Future<void> addWarning(WarningEvent w) async {
    warnings.insert(0, w);
    warnings.sort((a, b) => b.happenedAt.compareTo(a.happenedAt));
    if (warnings.length > _maxWarnings) warnings.removeRange(_maxWarnings, warnings.length);
    notifyListeners();
    await _saveWarnings();
  }

  Future<void> removeWarning(String id) async {
    warnings.removeWhere((w) => w.id == id);
    notifyListeners();
    await _saveWarnings();
  }

  Future<void> clearWarnings() async {
    warnings.clear();
    notifyListeners();
    await _saveWarnings();
  }

  Future<void> _saveWarnings() =>
    _prefs.setString('rs_warnings', jsonEncode(warnings.map((w) => w.toJson()).toList()));

  void pairDemoHelmet(bool connect) { demoHelmetConnected = connect; notifyListeners(); }
  void setRidePreview(double speed, String risk) {
    demoSpeed = speed; demoRisk = risk; notifyListeners();
  }
  void clearRidePreview() { demoSpeed = 0; demoRisk = 'Not monitoring'; notifyListeners(); }
}