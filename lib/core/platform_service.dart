import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:window_manager/window_manager.dart';

class PlatformService {
  static final PlatformService instance = PlatformService._();
  PlatformService._();

  bool debugEnabled = false;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize Notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: LinuxInitializationSettings(defaultActionName: 'Open'),
      // Windows initialization is handled by the plugin if available, 
      // but we add it explicitly if the class is found.
    );

    await _notifications.initialize(initializationSettings);

    // Initialize Window Manager for Desktop
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();
      
      WindowOptions windowOptions = const WindowOptions(
        size: Size(800, 600),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.normal,
      );
      
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'timeloop_reminders',
      'TimeLoop Reminders',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const LinuxNotificationDetails linuxPlatformChannelSpecifics =
        LinuxNotificationDetails(
      urgency: LinuxNotificationUrgency.critical,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      linux: linuxPlatformChannelSpecifics,
    );

    if (debugEnabled) {
      File('timeloop_debug.log').writeAsStringSync(
        'Attempting to show notification: $title - $body\n',
        mode: FileMode.append,
      );
    }

    try {
      if (!Platform.isWindows) {
        await _notifications.show(id, title, body, platformChannelSpecifics);
      } else {
        // Sound Fallback for Windows
        Process.run('powershell', [
          '-Command',
          '[System.Console]::Beep(880, 200); [System.Console]::Beep(1100, 200);'
        ]);

        // Visual Fallback (Balloon Tip) for Windows
        final psCommand = """
          [reflection.assembly]::loadwithpartialname('System.Windows.Forms');
          [reflection.assembly]::loadwithpartialname('System.Drawing');
          \$notify = New-Object System.Windows.Forms.NotifyIcon;
          \$notify.Icon = [System.Drawing.SystemIcons]::Information;
          \$notify.Visible = \$true;
          \$notify.ShowBalloonTip(5000, '$title', '$body', [System.Windows.Forms.ToolTipIcon]::Info);
          Start-Sleep -Seconds 6;
          \$notify.Dispose();
        """;
        Process.run('powershell', ['-Command', psCommand]);
      }
    } catch (e) {
      if (debugEnabled) {
        File('timeloop_debug.log').writeAsStringSync(
          'Notification error: $e\n',
          mode: FileMode.append,
        );
      }
    }
  }

  Future<void> setAlwaysOnTop(bool value) async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.setAlwaysOnTop(value);
    }
  }

  Future<void> minimizeToTray() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      await windowManager.hide();
    }
  }
}
