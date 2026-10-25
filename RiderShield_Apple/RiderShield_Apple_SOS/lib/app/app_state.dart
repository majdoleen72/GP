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
  bool demoHelmetConnected = false;
  double demoSpeed = 0;
  String demoRisk = 'Not monitoring';

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
    return s;
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

  Future<void> addDemoIncident({required String severity, required String location}) async {
    incidents.insert(0, CrashIncident(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      happenedAt: DateTime.now(), location: location.isEmpty ? 'Demo location not recorded' : location,
      severity: severity, sosSent: false,
    ));
    notifyListeners();
    await _prefs.setString('rs_incidents', jsonEncode(incidents.map((i) => i.toJson()).toList()));
  }

  Future<void> removeIncident(String id) async {
    incidents.removeWhere((i) => i.id == id);
    notifyListeners();
    await _prefs.setString('rs_incidents', jsonEncode(incidents.map((i) => i.toJson()).toList()));
  }

  void pairDemoHelmet(bool connect) { demoHelmetConnected = connect; notifyListeners(); }
  void setRidePreview(double speed, String risk) {
    demoSpeed = speed; demoRisk = risk; notifyListeners();
  }
  void clearRidePreview() { demoSpeed = 0; demoRisk = 'Not monitoring'; notifyListeners(); }
}
