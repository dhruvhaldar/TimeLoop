import 'package:test/test.dart';
import 'package:timeloop/core/reminder_schedule.dart';

void main() {
  test('reconcile triggers on due reminder and advances next trigger', () {
    final schedule = ReminderSchedule(
      id: '1',
      message: 'Stand up',
      interval: const Duration(minutes: 20),
      nextTriggerUtc: DateTime.utc(2026, 1, 1, 10, 0, 0),
    );

    final result = schedule.reconcile(DateTime.utc(2026, 1, 1, 10, 0, 0));

    expect(result.shouldNotify, isTrue);
    expect(result.missed, isFalse);
    expect(schedule.nextTriggerUtc, DateTime.utc(2026, 1, 1, 10, 20, 0));
  });

  test('reconcile marks missed reminders after wake', () {
    final schedule = ReminderSchedule(
      id: '2',
      message: 'Hydrate',
      interval: const Duration(minutes: 15),
      nextTriggerUtc: DateTime.utc(2026, 1, 1, 10, 0, 0),
    );

    final result = schedule.reconcile(DateTime.utc(2026, 1, 1, 10, 46, 0));

    expect(result.shouldNotify, isTrue);
    expect(result.missed, isTrue);
    expect(result.missedCount, 3);
    expect(schedule.nextTriggerUtc, DateTime.utc(2026, 1, 1, 11, 0, 0));
  });
}
