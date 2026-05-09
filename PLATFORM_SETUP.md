# Platform Build and Run Instructions

This project is currently a Dart domain/runtime implementation with tests. The next step is to wrap this runtime in a Flutter app shell for Android, Web, Windows, and Linux.

## Prerequisites

- Install Flutter stable (includes Dart SDK).
- Verify toolchain:
  - `flutter doctor -v`
  - `dart --version`

## Common Commands

```bash
flutter pub get
flutter test
```

## Android

```bash
flutter config --enable-android
flutter build apk --release
flutter run -d android
```

Notes:
- Add foreground service notification when stopwatch is active.
- Use exact alarms (`AlarmManager`) for recurring reminders.

## Web

```bash
flutter config --enable-web
flutter build web --release
flutter run -d chrome
```

Notes:
- Register service worker hooks for reminder notifications.
- Ensure browser notification permissions are requested and persisted.

## Windows

```bash
flutter config --enable-windows-desktop
flutter build windows --release
flutter run -d windows
```

Notes:
- Support minimize-to-tray behavior on window close.
- Support always-on-top window toggle.

## Linux

```bash
flutter config --enable-linux-desktop
flutter build linux --release
flutter run -d linux
```

Notes:
- Integrate status notifier/system tray behavior.
- Use native Linux desktop notifications (libnotify/D-Bus).

## CI Compiler Build Matrix (recommended)

Use a CI matrix with:
- `flutter test`
- `flutter build apk --release`
- `flutter build web --release`
- `flutter build windows --release`
- `flutter build linux --release`
