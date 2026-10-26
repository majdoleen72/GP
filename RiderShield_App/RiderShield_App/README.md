# RiderShield — Apple-inspired forms & emergency workflow

This is the updated **RiderShield Flutter/Dart source**, based on the previous Refined UI project. The existing welcome, profile, reports, helmet connection, 5-tab floating navigation, assets, and local storage are preserved.

## New features

- **Apple-inspired inset-grouped fields:** Sign in, sign up, edit profile, and add/edit emergency contacts now use compact single-group rows with always-visible labels, 48pt-ish hit targets, readable text, and clear separators. Space is preserved instead of allocating a large card to each field. They are iOS-inspired, not Apple proprietary widgets.
- **Crash Alert:** `CrashAlertScreen(crashDetected: true)` presents a ten-second countdown and prominent **I'm OK — Cancel alert** button. Cancelling neither dispatches SOS nor creates an incident. On timeout it records a crash incident in Safety Report and attempts to dispatch through a configured HTTPS backend.
- **Crash test:** `CrashAlertScreen(crashDetected: true, testOnly: true)` can be opened from Home or Emergency. The demo has a visible TEST MODE label and never sends emergency data, even if a backend URL is configured. Timeout creates a TEST crash record; cancel does not.
- **Manual SOS:** On Emergency tab, select **Manual SOS** -> **Send manual SOS**. It doesn't create a crash report.
- **Optional GPS lookup:** If a real dispatch is configured, checks location service and permission, then attempts to attach a Google Maps coordinates link. If unavailable, the dispatch still continues with an explicit unavailable value.
- **Delivery status:** Only a backend response containing `{"accepted": true}` counts as request accepted. **Accepted is not delivered**. No data transmission is ever claimed in demo mode or without an acknowledged backend.
- **Manual fallback:** When real dispatch isn't configured or fails, the user can open the SMS composer for each saved contact, then must press Send in Messages. Opening the composer is never claimed to be an SMS sent.

## Android Studio setup

1. Unzip this archive and open the inner `RiderShield_Apple_SOS` folder (containing `pubspec.yaml`) in Android Studio.
2. In Android Studio Terminal (PowerShell), run:

```powershell
powershell -ExecutionPolicy Bypass -File .\SETUP_ANDROID.ps1
```

The setup script uses the SDK at `C:\Users\majdo\Downloads\flutter\flutter\bin\flutter.bat` when available. Otherwise Flutter must be on PATH. It creates any missing Android platform files, adds INTERNET/FINE/COARSE location permissions to the Android manifest without deleting other entries, and runs pub get. It does **not** rewrite the Dart source or assets.

3. Open your existing Pixel 5 emulator.
4. Run:

```powershell
& "C:\Users\majdo\Downloads\flutter\flutter\bin\flutter.bat" run -d emulator-5554
```

You can also run from Android Studio's Run button after platform setup.

## Existing project — patch instead of replacement

Copy `lib` and `pubspec.yaml` from this archive to your existing project, replacing matching files. Retain your existing `android` directory and `assets`. Add the following **direct children of** `<manifest>` in `android/app/src/main/AndroidManifest.xml` if missing (or run the supplied setup script from the existing project root):

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

Then run `flutter pub get` and do a **full restart** (not Hot Reload), because plugin registrations and class structures changed.

## Emergency delivery API (NOT configured by default)

This UI **does not send automatic SMS out of the box**. The mobile client cannot safely contain SMS provider credentials. To test actual dispatch against **your own authenticated and secured backend**, build a backend accepting HTTPS POST as documented below, then run with:

```powershell
& "C:\Users\majdo\Downloads\flutter\flutter\bin\flutter.bat" run -d emulator-5554 --dart-define=RIDERSHIELD_EMERGENCY_API_URL=https://your-secure-server.example/api/emergencies
```

The API receives an `eventId`, `trigger` (`crash_timeout` or `manual_sos`), `person` (`name`, `phone`), `occurredAt` (UTC ISO timestamp), `location` (maps URL or unavailable string) and `recipients` array of name/phone/relationship. Only respond `{"accepted": true}` after authenticating the user, validating input, applying abuse/rate controls, and DURABLY queuing notifications to your SMS provider. An accepted request is **not a delivery receipt**. Implement per-recipient status reporting and retries before actual field use. Use HTTPS, securely manage consent, and never include provider API secrets in the app. At present demo authentication is not real, so this prototype is **not suitable for production SOS delivery** even with the URL set. The URL example is illustrative and not a deployed endpoint.

## Crash detection integration

The app currently has **no sensor-based crash detector**. The existing TEST button is not detection. Your phone crash-detection logic can navigate to:

```dart
Navigator.of(context).push(MaterialPageRoute<void>(
  builder: (_) => const CrashAlertScreen(crashDetected: true, testOnly: false),
));
```

Important: The ten-second timer runs inside the Flutter UI while the screen is active. Flutter UI timers may be suspended in background, the app might be terminated or permissions blocked, and mobile connectivity can fail. For reliability, a production emergency workflow requires **platform-native foreground/background scheduling, pre-granted permissions, persistent retry queues and server-side delivery verification**, plus comprehensive testing. The user needs an easy way to cancel false positives. This app is currently for demonstration and evaluation, **not a substitute for emergency services**.

## iPhone support later

To create iOS platform files on a Mac: `flutter create --platforms=ios .` and add `NSLocationWhenInUseUsageDescription` to `ios/Runner/Info.plist`, explaining emergency location sharing. The repo here targets Android Studio on Windows. Do not request Always location access unnecessarily.

## Safety Report rule

Only crash incidents with completed countdowns and manual **TEST crash** records appear in Safety Report. Normal Safe/Careful/Unsafe warnings do not generate reports, and pressing Manual SOS by itself does not create a crash entry. Records are currently stored in local `shared_preferences` (not encrypted or backed up by a server); use encrypted/secure storage and a real black-box sync design for production.

## Testing checklist

- Check Sign Up on Pixel 5 with keyboard closed: compact input group, password strength indicator, Create Account and sign-in/social actions accessible.
- Tap Home -> Test crash countdown; press I'm OK within 10s: returns with **no new report**.
- Let TEST countdown reach zero: displays **TEST ONLY**, logs one test crash in Safety Report, no SMS sent.
- Add/edit/delete emergency contacts, then open Manual SOS. With no configured backend, it must say **nothing was sent**; SMS composer fallback is only available for real (non-demo) actions and requires manually pressing Send.
- Verify the floating 5-tab navbar and pinned header remain consistent with existing design.
