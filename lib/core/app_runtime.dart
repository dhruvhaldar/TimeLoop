import 'reminder_schedule.dart';
import 'stopwatch_engine.dart';

class AppRuntime {
  AppRuntime({
    StopwatchEngine? stopwatch,
    List<ReminderSchedule>? reminders,
  })  : stopwatch = stopwatch ?? StopwatchEngine(),
        reminders = reminders ?? <ReminderSchedule>[];

  final StopwatchEngine stopwatch;
  final List<ReminderSchedule> reminders;

  List<ReminderTickResult> reconcileReminders(DateTime nowUtc) {
    final results = <ReminderTickResult>[];
    for (final reminder in reminders) {
      final result = reminder.reconcile(nowUtc);
      if (result.shouldNotify) {
        results.add(result);
      }
    }
    return results;
  }
}
