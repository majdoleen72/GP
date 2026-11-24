# RiderShield – Mobile Application

## Overview

RiderShield is a Flutter-based mobile application developed as part of a graduation project at King Saud University. The application is designed to enhance motorcycle rider safety through an intuitive dashboard, safety reports, emergency assistance workflows, and smart helmet connectivity interfaces.

## Application Features

### User Account

- Welcome, Sign In, and Sign Up interfaces.
- Input validation.
- Password requirements and strength indicator.
- Google Sign-In interface.
- Local user profile management.
- Sign-out functionality.

### Home Dashboard

- Interactive and rotating 3D helmet model.
- Helmet connection status.
- Safety statistics and warning summaries.
- Rider safety status preview.
- Customizable emergency countdown from 5 to 60 seconds.

### Connect Helmet

- Smart helmet connection interface.
- Animated connection progress.
- Connection and disconnection controls.
- Step-by-step connection instructions.
- Interactive 3D helmet visualization.

### Emergency Assistance

- Add, edit, and delete emergency contacts.
- Manage contact names, phone numbers, and relationships.
- Manual SOS workflow.
- Crash Alert interface.
- Customizable emergency countdown from 5 to 60 seconds, with a default duration of 10 seconds.
- Visual circular countdown indicator.
- Immediate manual SOS action without waiting for the countdown.
- Emergency alert cancellation through the "I'm OK" button.
- Automatic return to the Home Dashboard after alert cancellation.
- Automatic return to the Home Dashboard after successful acceptance of an emergency request.
- Local crash incident recording when the crash countdown expires.
- Emergency response status handling.
- Manual SMS fallback when automatic dispatch is unavailable.

Cancelled crash alerts do not create incident records. Manual SOS requests are handled separately and do not create crash reports.

### Safety Reports

- Warning history.
- Crash history.
- Speed warning records.
- Drowsiness warning records.
- Vehicle proximity warning records.
- Date-based report filtering.
- Detailed warning and crash information.
- Individual record deletion.

### Profile and Settings

- Edit personal information.
- Update profile and cover images.
- Manage riding experience.
- Change Password interface.
- Privacy and Protection settings.
- Switch between Light and Dark Mode.
- Local account preferences.
- Sign-out functionality.

## Application Design

The application provides a consistent and modern user experience through:

- Light Mode and Dark Mode.
- Glass-inspired interface components.
- Custom floating bottom navigation bar.
- Animated screen transitions.
- Interactive 3D helmet models.
- Animated connection indicators.
- Reusable interface components.
- Theme-aware emergency screens.

## Application Navigation

The main bottom navigation bar contains three sections:

- Home
- Emergency
- Connect Helmet

Safety Reports and Profile are accessible through the application header.

Additional screens, including Edit Profile, Change Password, Emergency Contact Management, and Crash Alert, are accessible through their corresponding sections.

## Technologies

| Technology | Purpose |
|---|---|
| Flutter | Mobile application development |
| Dart | Application programming |
| Shared Preferences | Local data storage |
| Image Picker | Profile and cover image selection |
| GLBView | Interactive 3D model visualization |
| URL Launcher | Opening external applications |
| Android SDK | Android application support |

## Project Structure

- `lib/main.dart` — Application entry point.
- `lib/app/` — Application state and configuration.
- `lib/screens/` — Application screens and user interfaces.
- `lib/widgets/` — Reusable interface components.
- `lib/theme/` — Application colors and themes.
- `lib/navigation/` — Navigation and screen transitions.
- `lib/services/` — Application service components.
- `lib/utils/` — Utility and validation functions.
- `assets/images/` — Images and 3D helmet models.
- `android/` — Android platform configuration.
- `pubspec.yaml` — Project dependencies and asset configuration.

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Android SDK
- Android Studio or Visual Studio Code
- Android emulator or physical Android device

### Installation

Open the `RiderShield_App` directory in your development environment.

Install the required dependencies:

```bash
flutter pub get
```

Check the Flutter development environment:

```bash
flutter doctor
```

Check available devices:

```bash
flutter devices
```

Run the application:

```bash
flutter run
```

## Local Data Management

The application uses Shared Preferences to store and retrieve:

- User profile information.
- Profile and cover images.
- Emergency contacts.
- Warning records.
- Crash incident records.
- Emergency countdown preferences.
- Account-specific data.

User information and preferences are maintained locally. Account-specific records are organized according to the user's email address.

## Security and Privacy

The current application uses local storage for user information and application records.

Sensitive credentials, external service keys, and private configuration files must not be included in the source code or repository.

Local storage and authentication mechanisms require further security enhancements before production deployment.

## Application Development

The application follows a modular architecture that separates user interfaces, state management, services, and local data storage. This structure supports maintainability, extensibility, and integration with other RiderShield system components.

## Academic Information

**Project Name:** RiderShield

**University:** King Saud University

**College:** College of Computer and Information Sciences

**Department:** Information Technology

**Project Type:** Graduation Project

---

**RiderShield — Smart Safety for Motorcycle Riders.**
