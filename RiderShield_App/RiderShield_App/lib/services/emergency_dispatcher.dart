import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../app/app_state.dart';

enum DispatchState { demoOnly, noContacts, noService, accepted, failed }

class EmergencyOutcome {
  const EmergencyOutcome({required this.status, required this.message,
    required this.location, required this.sentAt});
  final DispatchState status;
  final String message;
  final String location;
  final DateTime sentAt;
  bool get accepted => status == DispatchState.accepted;
}

/// Implement this URL with an authenticated HTTPS backend that sends SMS
/// to recipients and responds with {"accepted": true} only after the job
/// is queued durably. Never put SMS provider credentials in this mobile app.
/// A 2xx response alone does not mean a message was delivered.
class EmergencyDispatcher {
  EmergencyDispatcher._();
  static const _apiUrl = String.fromEnvironment('RIDERSHIELD_EMERGENCY_API_URL');
  static bool get configured => _apiUrl.startsWith('https://');

  static Future<String> tryLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return 'Location unavailable (GPS off)';
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return 'Location unavailable (permission denied)';
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 7),
        ),
      ).timeout(const Duration(seconds: 8));
      return 'https://maps.google.com/?q=${position.latitude},${position.longitude}';
    } catch (_) {
      return 'Location unavailable';
    }
  }

  static Future<EmergencyOutcome> dispatch({
    required RiderState rider,
    required bool simulated,
    required String trigger,
  }) async {
    final sentAt = DateTime.now();
    // Never query permissions or transmit anything during a test run.
    if (simulated) {
      return EmergencyOutcome(status: DispatchState.demoOnly,
        message: 'TEST ONLY — no message was sent.',
        location: 'Test location unavailable', sentAt: sentAt);
    }
    if (rider.contacts.isEmpty) {
      return EmergencyOutcome(status: DispatchState.noContacts,
        message: 'No emergency contacts saved. Nothing was sent.',
        location: 'Location not requested', sentAt: sentAt);
    }
    if (!configured) {
      return EmergencyOutcome(status: DispatchState.noService,
        message: 'Emergency delivery service is not configured. Nothing was sent.',
        location: 'Location not requested', sentAt: sentAt);
    }
    final location = await tryLocation();
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'content-type': 'application/json'},
        body: jsonEncode({
          'eventId': 'rs-${sentAt.microsecondsSinceEpoch}',
          'trigger': trigger,
          'person': {'name': rider.fullName, 'phone': rider.phone},
          'occurredAt': sentAt.toUtc().toIso8601String(),
          'location': location,
          'recipients': [
            for (final person in rider.contacts)
              {'name': person.name, 'phone': person.phone,
                'relationship': person.relationship},
          ],
        }),
      ).timeout(const Duration(seconds: 12));
      bool accepted = false;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final body = jsonDecode(response.body);
          accepted = body is Map && body['accepted'] == true;
        } catch (_) { /* Strict success acknowledgement required. */ }
      }
      return EmergencyOutcome(
        status: accepted ? DispatchState.accepted : DispatchState.failed,
        message: accepted
          ? 'Emergency request accepted by the server; SMS delivery is not yet confirmed.'
          : 'Emergency request was not acknowledged. Check your contacts or call emergency services.',
        location: location, sentAt: sentAt,
      );
    } catch (_) {
      return EmergencyOutcome(status: DispatchState.failed,
        message: 'Could not reach the emergency server. No delivery confirmed.',
        location: location, sentAt: sentAt);
    }
  }
}
