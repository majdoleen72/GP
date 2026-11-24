
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ======================================================
// EMERGENCY CONTACT
// ======================================================

class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
  });

  final String id;
  final String name;
  final String phone;
  final String relationship;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };

  factory EmergencyContact.fromJson(
    Map<String, dynamic> j,
  ) =>
      EmergencyContact(
        id: '${j['id'] ?? ''}',
        name: '${j['name'] ?? ''}',
        phone: '${j['phone'] ?? ''}',
        relationship: '${j['relationship'] ?? ''}',
      );
}

// ======================================================
// CRASH INCIDENT
// ======================================================

class CrashIncident {
  const CrashIncident({
    required this.id,
    required this.happenedAt,
    required this.location,
    required this.severity,
    required this.sosSent,
    this.notificationStatus = 'notSent',
    this.testOnly = true,
  });

  final String id;
  final DateTime happenedAt;
  final String location;
  final String severity;
  final bool sosSent;
  final String notificationStatus;
  final bool testOnly;

  Map<String, dynamic> toJson() => {
        'id': id,
        'happenedAt': happenedAt.toIso8601String(),
        'location': location,
        'severity': severity,
        'sosSent': sosSent,
        'notificationStatus': notificationStatus,
        'testOnly': testOnly,
      };

  factory CrashIncident.fromJson(
    Map<String, dynamic> j,
  ) =>
      CrashIncident(
        id: '${j['id'] ?? ''}',
        happenedAt: DateTime.tryParse(
              '${j['happenedAt'] ?? ''}',
            ) ??
            DateTime.now(),
        location: '${j['location'] ?? 'Not recorded'}',
        severity: '${j['severity'] ?? 'Unknown'}',
        sosSent: j['sosSent'] == true,
        notificationStatus:
            '${j['notificationStatus'] ?? 'notSent'}',
        testOnly: j['testOnly'] != false,
      );
}

// ======================================================
// WARNING EVENTS
// ======================================================

enum WarningType {
  speed,
  drowsiness,
  vehicleProximity,
}

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
  final String detail;

  final String? speedLevel;
  final String? drowsinessLevel;
  final String? proximityLevel;

  Map<String, dynamic> toJson() => {
        'id': id,
        'happenedAt': happenedAt.toIso8601String(),
        'type': type.name,
        'detail': detail,
        'speedLevel': speedLevel,
        'drowsinessLevel': drowsinessLevel,
        'proximityLevel': proximityLevel,
      };

  factory WarningEvent.fromJson(
    Map<String, dynamic> j,
  ) =>
      WarningEvent(
        id: '${j['id'] ?? ''}',
        happenedAt: DateTime.tryParse(
              '${j['happenedAt'] ?? ''}',
            ) ??
            DateTime.now(),
        type: WarningType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => WarningType.speed,
        ),
        detail: '${j['detail'] ?? ''}',
        speedLevel: j['speedLevel'] as String?,
        drowsinessLevel:
            j['drowsinessLevel'] as String?,
        proximityLevel:
            j['proximityLevel'] as String?,
      );
}

// ======================================================
// SOS SETTINGS
// ======================================================

class SosSettings {
  static const int minDelay = 5;
  static const int maxDelay = 60;
  static const int step = 1;

  static final ValueNotifier<int> delaySeconds =
      ValueNotifier<int>(10);
}

// ======================================================
// RIDER STATE
// Local prototype state, not real authentication or BLE.
// ======================================================

class RiderState extends ChangeNotifier {
  RiderState._(this._prefs);

  final SharedPreferences _prefs;

  // ====================================================
  // APPEARANCE - LIGHT / DARK MODE
  // ====================================================

  // Default: original Dark Mode.
  bool isLightMode = false;

  // Save theme separately from account information.
  Future<void> setLightMode(bool value) async {
    if (isLightMode == value) return;

    isLightMode = value;
    notifyListeners();

    await _prefs.setBool('rs_light_mode', value);
  }

  // ====================================================
  // PROFILE INFORMATION
  // ====================================================

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

  static const int _maxWarnings = 300;

  int _seq = 0;

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_seq++}';

  // ====================================================
  // INITIALIZE
  // ====================================================

  static Future<RiderState> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final s = RiderState._(prefs);

    // Restore the user's selected theme.
    // If no choice exists, keep the original Dark Mode.
    s.isLightMode =
        prefs.getBool('rs_light_mode') ?? false;

    s.fullName = prefs.getString('rs_name') ?? '';
    s.email = prefs.getString('rs_email') ?? '';
    s.phone = prefs.getString('rs_phone') ?? '';
    s.city = prefs.getString('rs_city') ?? '';

    s.ridingExperience =
        prefs.getString('rs_experience') ?? 'Beginner';

    s.avatarBase64 =
        prefs.getString('rs_avatar') ?? '';

    s.coverBase64 =
        prefs.getString('rs_cover') ?? '';

    final savedDelay = prefs.getInt('rs_sos_delay');

    if (savedDelay != null) {
      SosSettings.delaySeconds.value =
          _clampDelay(savedDelay);
    }

    SosSettings.delaySeconds.addListener(
      s._onSosDelayChanged,
    );

    try {
      final raw = jsonDecode(
        prefs.getString('rs_contacts') ?? '[]',
      ) as List<dynamic>;

      s.contacts.addAll(
        raw.map(
          (e) => EmergencyContact.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        ),
      );
    } catch (_) {
      // Keep contacts empty if corrupted.
    }

    try {
      final raw = jsonDecode(
        prefs.getString('rs_incidents') ?? '[]',
      ) as List<dynamic>;

      s.incidents.addAll(
        raw.map(
          (e) => CrashIncident.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        ),
      );

      s.incidents.sort(
        (a, b) => b.happenedAt.compareTo(a.happenedAt),
      );
    } catch (_) {
      // Keep incidents empty if corrupted.
    }

    try {
      final raw = jsonDecode(
        prefs.getString('rs_warnings') ?? '[]',
      ) as List<dynamic>;

      s.warnings.addAll(
        raw.map(
          (e) => WarningEvent.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        ),
      );

      s.warnings.sort(
        (a, b) => b.happenedAt.compareTo(a.happenedAt),
      );
    } catch (_) {
      // Keep warnings empty if corrupted.
    }

    // Temporary supervisor demo data.
    if (!(prefs.getBool('rs_demo_seeded_v4') ?? false)) {
      s._seedSamples();

      await prefs.setString(
        'rs_incidents',
        jsonEncode(
          s.incidents.map((i) => i.toJson()).toList(),
        ),
      );

      await prefs.setString(
        'rs_warnings',
        jsonEncode(
          s.warnings.map((w) => w.toJson()).toList(),
        ),
      );

      await prefs.setBool('rs_demo_seeded_v4', true);
    }

    // Temporary sample contacts.
    if (!(prefs.getBool('rs_demo_contacts_v1') ??
        false)) {
      if (s.contacts.isEmpty) {
        s.contacts.addAll(const [
          EmergencyContact(
            id: 'sample_1',
            name: 'Sara Alharbi',
            relationship: 'Sister',
            phone: '+966500000001',
          ),
          EmergencyContact(
            id: 'sample_2',
            name: 'Khalid Alharbi',
            relationship: 'Father',
            phone: '+966500000002',
          ),
          EmergencyContact(
            id: 'sample_3',
            name: 'Noura Alqahtani',
            relationship: 'Friend',
            phone: '+966500000003',
          ),
        ]);

        await prefs.setString(
          'rs_contacts',
          jsonEncode(
            s.contacts.map((c) => c.toJson()).toList(),
          ),
        );
      }

      await prefs.setBool(
        'rs_demo_contacts_v1',
        true,
      );
    }

    if (s._ensureSampleProfile()) {
      await s._persistLive();
      s._saveSnapshot();
    }

    return s;
  }

  // ====================================================
  // SAMPLE REPORTS
  // ====================================================

  void _seedSamples() {
    final now = DateTime.now();

    var n = 0;

    String id() =>
        '${now.microsecondsSinceEpoch}_s${n++}';

    incidents.removeWhere(
      (i) => i.testOnly || i.id.contains('_s'),
    );

    warnings.clear();

    incidents.addAll([
      CrashIncident(
        id: id(),
        happenedAt: now.subtract(
          const Duration(days: 5, hours: 2),
        ),
        location:
            'https://maps.google.com/?q=24.7136,46.6753',
        severity: 'Minor',
        sosSent: false,
        notificationStatus: 'notSent',
        testOnly: false,
      ),
      CrashIncident(
        id: id(),
        happenedAt: now.subtract(
          const Duration(days: 2, hours: 6),
        ),
        location:
            'https://maps.google.com/?q=24.8000,46.6400',
        severity: 'Moderate',
        sosSent: true,
        notificationStatus: 'accepted',
        testOnly: false,
      ),
      CrashIncident(
        id: id(),
        happenedAt: now.subtract(
          const Duration(hours: 3),
        ),
        location:
            'https://maps.google.com/?q=24.9570,46.6980',
        severity: 'Severe',
        sosSent: true,
        notificationStatus: 'accepted',
        testOnly: false,
      ),
    ]);

    warnings.addAll([
      WarningEvent(
        id: id(),
        type: WarningType.vehicleProximity,
        detail: 'Vehicle 2 m ahead',
        happenedAt: now.subtract(
          const Duration(minutes: 40),
        ),
        speedLevel: 'Medium',
        drowsinessLevel: 'Low',
        proximityLevel: 'High',
      ),
      WarningEvent(
        id: id(),
        type: WarningType.drowsiness,
        detail: 'Eyes closed for 3 seconds',
        happenedAt: now.subtract(
          const Duration(days: 2, hours: 1),
        ),
        drowsinessLevel: 'High',
        proximityLevel: 'Low',
      ),
      WarningEvent(
        id: id(),
        type: WarningType.speed,
        detail: '92 km/h in a 60 km/h zone',
        happenedAt: now.subtract(
          const Duration(hours: 2, minutes: 20),
        ),
        speedLevel: 'Medium',
        proximityLevel: 'Low',
      ),
      WarningEvent(
        id: id(),
        type: WarningType.drowsiness,
        detail: 'Frequent yawning detected',
        happenedAt: now.subtract(
          const Duration(days: 1, hours: 4),
        ),
        speedLevel: 'Low',
        drowsinessLevel: 'Medium',
      ),
      WarningEvent(
        id: id(),
        type: WarningType.vehicleProximity,
        detail: 'Vehicle 3 m ahead',
        happenedAt: now.subtract(
          const Duration(days: 3),
        ),
        drowsinessLevel: 'Low',
        proximityLevel: 'Medium',
      ),
    ]);

    incidents.sort(
      (a, b) => b.happenedAt.compareTo(a.happenedAt),
    );

    warnings.sort(
      (a, b) => b.happenedAt.compareTo(a.happenedAt),
    );
  }

  // ====================================================
  // NAME AND PROFILE GETTERS
  // ====================================================

  String get shortName {
    final name = fullName.trim();

    if (name.isNotEmpty) {
      return name.split(RegExp(r'\s+')).first;
    }

    final emailName = email.trim().split('@').first;

    if (emailName.isNotEmpty) {
      return emailName;
    }

    return 'Rider';
  }

  Uint8List? get avatarBytes => _decode(avatarBase64);

  Uint8List? get coverBytes => _decode(coverBase64);

  Uint8List? _decode(String value) {
    if (value.isEmpty) return null;

    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  // ====================================================
  // LOGIN DETAILS - UPDATED
  // ====================================================

  Future<void> setLoginDetails({
    String? name,
    String? emailAddress,
  }) async {
    final newEmail = (emailAddress ?? '').trim();
    final newName = (name ?? '').trim();

    final switchingAccount =
        newEmail.isNotEmpty &&
        newEmail.toLowerCase() !=
            email.trim().toLowerCase();

    if (switchingAccount) {
      // Save previous account.
      _saveSnapshot();

      // Clear previous account.
      _blank();

      // Restore saved data for new account.
      _loadSnapshot(newEmail);
    }

    if (newEmail.isNotEmpty) {
      email = newEmail;
    }

    // Never overwrite a saved real name with an
    // empty value from the sign-in screen.
    if (newName.isNotEmpty) {
      fullName = newName;
    }

    _ensureSampleProfile();

    // Persist after all values are updated.
    await _persistLive();

    _saveSnapshot();

    notifyListeners();
  }

  // ====================================================
  // UPDATE PROFILE
  // ====================================================

  Future<void> updateProfile({
    required String name,
    required String emailAddress,
    required String phoneNumber,
    required String cityName,
    required String experience,
  }) async {
    fullName = name.trim();
    email = emailAddress.trim();
    phone = phoneNumber.trim();
    city = cityName.trim();
    ridingExperience = experience;

    notifyListeners();

    await _saveProfile();
    _saveSnapshot();
  }

  Future<void> setProfileImage(
    Uint8List bytes, {
    required bool cover,
  }) async {
    if (cover) {
      coverBase64 = base64Encode(bytes);

      await _prefs.setString(
        'rs_cover',
        coverBase64,
      );
    } else {
      avatarBase64 = base64Encode(bytes);

      await _prefs.setString(
        'rs_avatar',
        avatarBase64,
      );
    }

    _saveSnapshot();
    notifyListeners();
  }

  Future<void> _saveProfile() async {
    await _prefs.setString('rs_name', fullName);
    await _prefs.setString('rs_email', email);
    await _prefs.setString('rs_phone', phone);
    await _prefs.setString('rs_city', city);

    await _prefs.setString(
      'rs_experience',
      ridingExperience,
    );
  }

  // ====================================================
  // EMERGENCY CONTACTS
  // ====================================================

  Future<void> upsertContact(
    EmergencyContact value,
  ) async {
    final index = contacts.indexWhere(
      (c) => c.id == value.id,
    );

    if (index == -1) {
      contacts.add(value);
    } else {
      contacts[index] = value;
    }

    notifyListeners();

    await _prefs.setString(
      'rs_contacts',
      jsonEncode(
        contacts.map((c) => c.toJson()).toList(),
      ),
    );

    _saveSnapshot();
  }

  Future<void> deleteContact(String id) async {
    contacts.removeWhere((c) => c.id == id);

    notifyListeners();

    await _prefs.setString(
      'rs_contacts',
      jsonEncode(
        contacts.map((c) => c.toJson()).toList(),
      ),
    );

    _saveSnapshot();
  }

  // ====================================================
  // CRASH INCIDENTS
  // ====================================================

  Future<void> recordCrash({
    required String location,
    required String notificationStatus,
    required bool testOnly,
  }) async {
    incidents.insert(
      0,
      CrashIncident(
        id: DateTime.now()
            .microsecondsSinceEpoch
            .toString(),
        happenedAt: DateTime.now(),
        location: location,
        severity: 'Not assessed',
        sosSent: false,
        notificationStatus: notificationStatus,
        testOnly: testOnly,
      ),
    );

    notifyListeners();

    await _prefs.setString(
      'rs_incidents',
      jsonEncode(
        incidents.map((i) => i.toJson()).toList(),
      ),
    );

    _saveSnapshot();
  }

  Future<void> addDemoIncident({
    required String severity,
    required String location,
    DateTime? at,
  }) async {
    incidents.insert(
      0,
      CrashIncident(
        id: _newId(),
        happenedAt: at ?? DateTime.now(),
        location: location.isEmpty
            ? 'Demo location not recorded'
            : location,
        severity: severity,
        sosSent: false,
      ),
    );

    incidents.sort(
      (a, b) => b.happenedAt.compareTo(a.happenedAt),
    );

    notifyListeners();

    await _prefs.setString(
      'rs_incidents',
      jsonEncode(
        incidents.map((i) => i.toJson()).toList(),
      ),
    );

    _saveSnapshot();
  }

  Future<void> removeIncident(String id) async {
    incidents.removeWhere((i) => i.id == id);

    notifyListeners();

    await _prefs.setString(
      'rs_incidents',
      jsonEncode(
        incidents.map((i) => i.toJson()).toList(),
      ),
    );

    _saveSnapshot();
  }

  // ====================================================
  // WARNING HISTORY
  // ====================================================

  Future<void> recordWarning({
    required WarningType type,
    String detail = '',
    DateTime? at,
    String? speedLevel,
    String? drowsinessLevel,
    String? proximityLevel,
  }) =>
      addWarning(
        WarningEvent(
          id: _newId(),
          happenedAt: at ?? DateTime.now(),
          type: type,
          detail: detail,
          speedLevel: speedLevel,
          drowsinessLevel: drowsinessLevel,
          proximityLevel: proximityLevel,
        ),
      );

  Future<void> addWarning(WarningEvent w) async {
    warnings.insert(0, w);

    warnings.sort(
      (a, b) => b.happenedAt.compareTo(a.happenedAt),
    );

    if (warnings.length > _maxWarnings) {
      warnings.removeRange(
        _maxWarnings,
        warnings.length,
      );
    }

    notifyListeners();

    await _saveWarnings();
    _saveSnapshot();
  }

  Future<void> removeWarning(String id) async {
    warnings.removeWhere((w) => w.id == id);

    notifyListeners();

    await _saveWarnings();
    _saveSnapshot();
  }

  Future<void> clearWarnings() async {
    warnings.clear();

    notifyListeners();

    await _saveWarnings();
    _saveSnapshot();
  }

  Future<void> _saveWarnings() =>
      _prefs.setString(
        'rs_warnings',
        jsonEncode(
          warnings.map((w) => w.toJson()).toList(),
        ),
      );

  // ====================================================
  // SAMPLE PROFILE
  // ====================================================

  static const _sampleEmail = 's@gmail.com';

  bool _ensureSampleProfile() {
    if (email.trim().toLowerCase() != _sampleEmail) {
      return false;
    }

    if (contacts.isNotEmpty ||
        incidents.isNotEmpty ||
        warnings.isNotEmpty ||
        phone.isNotEmpty ||
        city.isNotEmpty) {
      return false;
    }

    if (fullName.isEmpty) {
      fullName = 'Souha';
    }

    phone = '+966500000000';
    city = 'Riyadh';

    contacts.addAll(const [
      EmergencyContact(
        id: 'sample_1',
        name: 'Sara Alharbi',
        relationship: 'Sister',
        phone: '+966500000001',
      ),
      EmergencyContact(
        id: 'sample_2',
        name: 'Khalid Alharbi',
        relationship: 'Father',
        phone: '+966500000002',
      ),
      EmergencyContact(
        id: 'sample_3',
        name: 'Noura Alqahtani',
        relationship: 'Friend',
        phone: '+966500000003',
      ),
    ]);

    _seedSamples();

    return true;
  }

  // ====================================================
  // SOS COUNTDOWN PER ACCOUNT
  // ====================================================

  bool _suspendSosSave = false;

  static int _clampDelay(int v) {
    if (v < SosSettings.minDelay) {
      return SosSettings.minDelay;
    }

    if (v > SosSettings.maxDelay) {
      return SosSettings.maxDelay;
    }

    return v;
  }

  void _setDelay(int v) {
    _suspendSosSave = true;

    SosSettings.delaySeconds.value = v;

    _suspendSosSave = false;
  }

  void _onSosDelayChanged() {
    if (_suspendSosSave) return;

    _prefs.setInt(
      'rs_sos_delay',
      SosSettings.delaySeconds.value,
    );

    _saveSnapshot();
  }

  // ====================================================
  // ACCOUNT SNAPSHOTS
  // ====================================================

  String _accKey(String e) =>
      'rs_acc_${e.trim().toLowerCase()}';

  Map<String, dynamic> _snapshot() => {
        'name': fullName,
        'email': email,
        'phone': phone,
        'city': city,
        'experience': ridingExperience,
        'avatar': avatarBase64,
        'cover': coverBase64,
        'contacts':
            contacts.map((c) => c.toJson()).toList(),
        'incidents':
            incidents.map((i) => i.toJson()).toList(),
        'warnings':
            warnings.map((w) => w.toJson()).toList(),
        'sosDelay': SosSettings.delaySeconds.value,
      };

  void _saveSnapshot() {
    if (email.trim().isEmpty) return;

    _prefs.setString(
      _accKey(email),
      jsonEncode(_snapshot()),
    );
  }

  void _blank() {
    fullName = '';
    email = '';
    phone = '';
    city = '';

    ridingExperience = 'Beginner';

    avatarBase64 = '';
    coverBase64 = '';

    contacts.clear();
    incidents.clear();
    warnings.clear();

    demoHelmetConnected = false;
    demoSpeed = 0;
    demoRisk = 'Not monitoring';

    _setDelay(10);
  }

  void _loadSnapshot(String e) {
    final raw = _prefs.getString(_accKey(e));

    if (raw == null) return;

    try {
      final j = Map<String, dynamic>.from(
        jsonDecode(raw) as Map,
      );

      fullName = '${j['name'] ?? ''}';
      email = '${j['email'] ?? ''}';
      phone = '${j['phone'] ?? ''}';
      city = '${j['city'] ?? ''}';

      ridingExperience =
          '${j['experience'] ?? 'Beginner'}';

      avatarBase64 = '${j['avatar'] ?? ''}';
      coverBase64 = '${j['cover'] ?? ''}';

      final d = j['sosDelay'];

      _setDelay(
        _clampDelay(d is int ? d : 10),
      );

      contacts.addAll(
        ((j['contacts'] as List?) ?? []).map(
          (x) => EmergencyContact.fromJson(
            Map<String, dynamic>.from(x as Map),
          ),
        ),
      );

      incidents.addAll(
        ((j['incidents'] as List?) ?? []).map(
          (x) => CrashIncident.fromJson(
            Map<String, dynamic>.from(x as Map),
          ),
        ),
      );

      warnings.addAll(
        ((j['warnings'] as List?) ?? []).map(
          (x) => WarningEvent.fromJson(
            Map<String, dynamic>.from(x as Map),
          ),
        ),
      );

      incidents.sort(
        (a, b) => b.happenedAt.compareTo(a.happenedAt),
      );

      warnings.sort(
        (a, b) => b.happenedAt.compareTo(a.happenedAt),
      );
    } catch (_) {
      // Corrupted account snapshot.
    }
  }

  // ====================================================
  // PERSIST CURRENT ACCOUNT
  // ====================================================

  Future<void> _persistLive() async {
    await Future.wait([
      _prefs.setString('rs_name', fullName),
      _prefs.setString('rs_email', email),
      _prefs.setString('rs_phone', phone),
      _prefs.setString('rs_city', city),
      _prefs.setString(
        'rs_experience',
        ridingExperience,
      ),
      _prefs.setString(
        'rs_avatar',
        avatarBase64,
      ),
      _prefs.setString(
        'rs_cover',
        coverBase64,
      ),
      _prefs.setString(
        'rs_contacts',
        jsonEncode(
          contacts.map((c) => c.toJson()).toList(),
        ),
      ),
      _prefs.setString(
        'rs_incidents',
        jsonEncode(
          incidents.map((i) => i.toJson()).toList(),
        ),
      ),
      _prefs.setString(
        'rs_warnings',
        jsonEncode(
          warnings.map((w) => w.toJson()).toList(),
        ),
      ),
      _prefs.setInt(
        'rs_sos_delay',
        SosSettings.delaySeconds.value,
      ),
      _prefs.setBool(
        'rs_demo_seeded_v4',
        true,
      ),
      _prefs.setBool(
        'rs_demo_contacts_v1',
        true,
      ),
    ]);
  }

  // ====================================================
  // SIGN OUT
  // ====================================================

  Future<void> signOut() async {
    _saveSnapshot();

    _blank();

    notifyListeners();

    await _persistLive();
  }

  // ====================================================
  // DEMO HELMET
  // ====================================================

  void pairDemoHelmet(bool connect) {
    demoHelmetConnected = connect;
    notifyListeners();
  }

  void setRidePreview(
    double speed,
    String risk,
  ) {
    demoSpeed = speed;
    demoRisk = risk;
    notifyListeners();
  }

  void clearRidePreview() {
    demoSpeed = 0;
    demoRisk = 'Not monitoring';
    notifyListeners();
  }

  @override
  void dispose() {
    SosSettings.delaySeconds.removeListener(
      _onSosDelayChanged,
    );
    super.dispose();
  }
}
