# TimeLoop Software Specification

## 1. Product Overview

- **Product Name:** TimeLoop
- **Product Purpose:** A cross-platform application providing precise stopwatch functionality and customizable, recurring interval-based reminders.
- **Target Platforms:** Android, Web (modern browsers), Windows (10/11), and Linux.
- **Architecture Strategy:** A single codebase approach prioritizing local-first data storage with responsive design to accommodate both mobile and desktop environments.

## 2. Functional Requirements

### 2.1 Stopwatch Module

- **Core Controls:** Start, Pause, Resume, and Reset functionalities.
- **Save/Record (Lap):** Save the current time to a history log without stopping the active timer.
- **Sleep/Wake Recalculation:** If a device (PC or phone) goes to sleep or hibernate, the stopwatch must compare the system Unix timestamp upon waking to instantly calculate and reflect the true elapsed time.
- **Always on Top (Desktop Only):** A toggle allowing the application window to float above other active applications (useful for Windows/Linux users monitoring time while working).

### 2.2 Alarm & Reminder Module

- **Interval Configuration:** Set custom recurring intervals (for example, every 20 minutes or every 1.5 hours).
- **Custom Payloads:** Attach user-defined text messages (for example, “Stand up and stretch”) to specific intervals.
- **Active Toggle:** Easily activate or deactivate schedules without deleting them.
- **Missed Reminder Handling:** If the device wakes from sleep and an interval has passed, the app immediately triggers a missed notification and resyncs the next interval.

## 3. Platform-Specific Implementations

### 3.1 Android

- **Foreground Service:** When the stopwatch is active, a persistent notification must be pinned in the notification shade to reduce the risk of Android battery optimization killing the app process.
- **Exact Alarm Scheduling:** Use `AlarmManager` to ensure reminder intervals trigger precisely, including in Doze mode when needed.

### 3.2 Windows & Linux (Desktop)

- **System Tray / Status Notifier:** Closing the main window (clicking “X”) should minimize the app to the System Tray (Windows) or System Tray/Status Notifier (Linux), rather than terminating the process.
- **Native Notifications:** Use Windows Action Center (Toast notifications) on Windows and libnotify (via D-Bus) on Linux for system-level alerts.

### 3.3 Web

- **Service Workers:** Required for the Reminder module so notifications can trigger even if the browser tab is hidden, inactive, or closed (provided the browser remains open in the background).

## 4. Non-Functional Requirements

### 4.1 Performance & Reliability

- Core timing logic must be decoupled from UI rendering frames.
- Elapsed time must be calculated by comparing the start Unix timestamp against the current Unix timestamp to guarantee millisecond accuracy across all target environments.

### 4.2 Data Storage & Persistence

- **Mobile & Desktop:** Use SQLite for robust, offline, local storage of saved times, lap histories, and reminder configurations.
- **Web:** Use IndexedDB for persistence across browser sessions and page refreshes.

### 4.3 Battery & Resource Optimization

- Avoid constant background loops.
- Schedule reminders ahead of time using host operating system native scheduling tools so the app can sleep between intervals.

## 5. User Interface (UI) & User Experience (UX)

### 5.1 Responsive Layout Strategy

- **Mobile/Narrow View (Android & mobile web):** Use a bottom-tab navigation bar with tabs for Stopwatch and Reminders.
- **Desktop/Wide View (Windows, Linux, desktop web):** Use a left-aligned sidebar navigation to optimize horizontal screen space.

### 5.2 Interface Elements

- **Stopwatch View:** Large digital display (`HH:MM:SS:ms`) with prominent action buttons and a scrollable lap/history list below or to the side, depending on screen width.
- **Reminders View:** A grid or list of reminder cards showing the custom message, interval, and quick-toggle switch.

## 6. Recommended Technical Stack

To achieve this four-platform target efficiently, a hybrid framework compiling to native code and web is required.

| Component | Recommendation | Justification |
| :--- | :--- | :--- |
| **Core Framework** | **Flutter** | Compiles to native ARM/x86 for Android/Windows/Linux and outputs optimized web builds, providing a single UI codebase. |
| **Desktop Window Management** | `window_manager` | Supports “Always on Top” and “Minimize to Tray” requirements for Windows and Linux. |
| **Persistence Layer** | `sqflite` + platform abstractions | Uses SQLite on native platforms and web-compatible storage abstractions backed by IndexedDB in browser builds. |
| **System Notifications** | `flutter_local_notifications` | Cross-platform plugin support for Android notification channels, Windows Toast notifications, and Linux desktop notifications. |
| **Web Backgrounding** | Standard JavaScript Service Workers | Integrates with Flutter Web for browser-level background notification behavior. |
