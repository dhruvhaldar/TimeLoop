import 'dart:async';
import 'dart:io';
import 'reminder_schedule.dart';
import 'stopwatch_engine.dart';
import 'platform_service.dart';

class AppRuntime {
  AppRuntime({
    StopwatchEngine? stopwatch,
    List<ReminderSchedule>? reminders,
  })  : stopwatch = stopwatch ?? StopwatchEngine(),
        reminders = reminders ?? <ReminderSchedule>[] {
    _startTicker();
  }

  final StopwatchEngine stopwatch;
  final List<ReminderSchedule> reminders;
  Timer? _ticker;
  bool debugEnabled = false;

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (debugEnabled) {
        File('timeloop_debug.log').writeAsStringSync(
          'Ticker ran at ${now.toIso8601String()}\n',
          mode: FileMode.append,
        );
      }
      reconcileReminders(now);
    });
  }

  void reconcileReminders(DateTime nowUtc) {
    for (final reminder in reminders) {
      final result = reminder.reconcile(nowUtc);
      if (result.shouldNotify) {
        String body = reminder.message;
        if (result.missed) {
          body = "[MISSED ${result.missedCount}] $body";
        }
        
        PlatformService.instance.showNotification(
          id: reminder.id.hashCode,
          title: "TimeLoop Reminder",
          body: body,
        );
      }
    }
  }

  void dispose() {
    _ticker?.cancel();
  }
}
