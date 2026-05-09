# 🌀 TimeLoop

[![Flutter](https://img.shields.io/badge/Flutter-3.41.9-blue.svg?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Android%20%7C%20Web%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)](#)

**TimeLoop** is a high-precision, cross-platform stopwatch and interval reminder application. Designed for productivity, it features local-first persistence, responsive desktop/mobile layouts, and deep system integration.

## ✨ Key Features

- **High-Precision Stopwatch**: Millisecond accuracy with sleep/wake reconciliation.
- **Smart Reminders**: Customizable recurring intervals with "missed reminder" detection.
- **Responsive Layout**: Sidebar navigation for Desktop; Bottom Tabs for Mobile.
- **Platform Native**: System tray support, native notifications, and "Always on Top" mode.
- **Local First**: Persistence via SQLite (Native) and IndexedDB (Web).

---

## 🚀 Build Instructions

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
- **Windows Only**: [Visual Studio 2022](https://visualstudio.microsoft.com/vs/community/) with "Desktop development with C++" workload.
- **Android Only**: Android SDK and command-line tools.

### 🏁 Getting Started
```bash
flutter pub get
```

### 🪟 Windows
Use the provided automated build script for timestamped releases:
```powershell
./build_windows.ps1
```
Or build manually:
```bash
flutter build windows --release
```

### 🌐 Web
```bash
flutter build web --release
```

### 🤖 Android
```bash
flutter build apk --release
```

### 🐧 Linux
```bash
flutter build linux --release
```

---

## 🛠️ Project Structure

- `lib/core`: Domain logic (Stopwatch engine, Reminder scheduling).
- `lib/ui`: Responsive UI components and layout orchestration.
- `windows_builds/`: Timestamped Windows release artifacts.

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.
