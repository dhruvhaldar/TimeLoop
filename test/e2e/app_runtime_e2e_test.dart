import 'package:test/test.dart';
import 'package:timeloop/core/app_runtime.dart';
import 'package:timeloop/core/reminder_schedule.dart';

void main() {
  group('AppRuntime E2E flows', () {
    test('mobile-like stopwatch flow with wake reconciliation and lap recording', () {
      final app = AppRuntime();
      final t0 = DateTime.utc(2026, 4, 1, 8, 0, 0);

      app.stopwatch.start(t0);
      final lap1 = app.stopwatch.recordLap(t0.add(const Duration(seconds: 30)));
      expect(lap1, const Duration(seconds: 30));

      app.stopwatch.pause(t0.add(const Duration(minutes: 5)));
      expect(app.stopwatch.elapsed(t0.add(const Duration(minutes: 10))), const Duration(minutes: 5));

      app.stopwatch.resume(t0.add(const Duration(minutes: 12)));

      final wakeElapsed = app.stopwatch.reconcileAfterWake(
        t0.add(const Duration(minutes: 45, seconds: 10)),
      );

      expect(wakeElapsed, const Duration(minutes: 38, seconds: 10));
      expect(app.stopwatch.laps.length, 1);
    });

    test('desktop/web reminder flow catches missed intervals and resyncs', () {
      final app = AppRuntime(
        reminders: [
          ReminderSchedule(
            id: 'stretch',
            message: 'Stand up and stretch',
            interval: const Duration(minutes: 20),
            nextTriggerUtc: DateTime.utc(2026, 4, 1, 9, 0, 0),
          ),
          ReminderSchedule(
            id: 'hydrate',
            message: 'Drink water',
            interval: const Duration(minutes: 30),
            nextTriggerUtc: DateTime.utc(2026, 4, 1, 9, 15, 0),
          ),
        ],
      );

      final firstTick = app.reconcileReminders(DateTime.utc(2026, 4, 1, 9, 0, 0));
      expect(firstTick.length, 1);
      expect(firstTick.first.missed, isFalse);

      final wakeTick = app.reconcileReminders(DateTime.utc(2026, 4, 1, 10, 46, 0));
      expect(wakeTick.length, 2);

      final stretch = wakeTick.firstWhere((r) => r.missedCount == 4);
      final hydrate = wakeTick.firstWhere((r) => r.missedCount == 2);

      expect(stretch.missed, isTrue);
      expect(hydrate.missed, isTrue);
      expect(app.reminders[0].nextTriggerUtc, DateTime.utc(2026, 4, 1, 11, 0, 0));
      expect(app.reminders[1].nextTriggerUtc, DateTime.utc(2026, 4, 1, 11, 15, 0));
    });

    test('inactive reminder does not notify until re-enabled', () {
      final reminder = ReminderSchedule(
        id: 'focus',
        message: 'Take a screen break',
        interval: const Duration(minutes: 50),
        nextTriggerUtc: DateTime.utc(2026, 4, 1, 13, 0, 0),
        active: false,
      );

      final app = AppRuntime(reminders: [reminder]);

      final inactiveTick = app.reconcileReminders(DateTime.utc(2026, 4, 1, 14, 30, 0));
      expect(inactiveTick, isEmpty);

      reminder.active = true;
      reminder.nextTriggerUtc = DateTime.utc(2026, 4, 1, 14, 0, 0);
      final activeTick = app.reconcileReminders(DateTime.utc(2026, 4, 1, 14, 30, 0));

      expect(activeTick.length, 1);
      expect(activeTick.first.shouldNotify, isTrue);
      expect(activeTick.first.missed, isFalse);
      expect(reminder.nextTriggerUtc, DateTime.utc(2026, 4, 1, 14, 50, 0));
    });
  });
}
