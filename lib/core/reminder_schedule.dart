class ReminderSchedule {
  ReminderSchedule({
    required this.id,
    required this.message,
    required this.interval,
    required this.nextTriggerUtc,
    this.active = true,
  });

  final String id;
  final String message;
  final Duration interval;
  bool active;
  DateTime nextTriggerUtc;

  ReminderTickResult reconcile(DateTime nowUtc) {
    if (!active) {
      return ReminderTickResult.none(nowUtc.toUtc());
    }

    final now = nowUtc.toUtc();
    if (now.isBefore(nextTriggerUtc)) {
      return ReminderTickResult.none(nextTriggerUtc);
    }

    final elapsed = now.difference(nextTriggerUtc);
    final missedCount = (elapsed.inMilliseconds ~/ interval.inMilliseconds) + 1;
    nextTriggerUtc = nextTriggerUtc.add(interval * missedCount);

    return ReminderTickResult.triggered(
      missed: missedCount > 1,
      missedCount: missedCount - 1,
      nextTriggerUtc: nextTriggerUtc,
    );
  }
}

class ReminderTickResult {
  ReminderTickResult._({
    required this.shouldNotify,
    required this.missed,
    required this.missedCount,
    required this.nextTriggerUtc,
  });

  factory ReminderTickResult.none(DateTime nextTriggerUtc) => ReminderTickResult._(
        shouldNotify: false,
        missed: false,
        missedCount: 0,
        nextTriggerUtc: nextTriggerUtc,
      );

  factory ReminderTickResult.triggered({
    required bool missed,
    required int missedCount,
    required DateTime nextTriggerUtc,
  }) =>
      ReminderTickResult._(
        shouldNotify: true,
        missed: missed,
        missedCount: missedCount,
        nextTriggerUtc: nextTriggerUtc,
      );

  final bool shouldNotify;
  final bool missed;
  final int missedCount;
  final DateTime nextTriggerUtc;
}
