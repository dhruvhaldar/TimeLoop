# DartPad Testing Guide

This document explains how to validate TimeLoop core logic using [DartPad](https://dartpad.dev/).

## 1) Open DartPad

- Go to: https://dartpad.dev/
- Click **New Pad**.
- Set mode to **Dart** (not Flutter) because these tests target core domain logic.

## 2) Paste the Validation Program

Copy/paste the full snippet below into DartPad and click **Run**.

```dart
class StopwatchEngine {
  DateTime? _startUtc;
  Duration _accumulated = Duration.zero;
  bool _running = false;
  final List<Duration> _laps = <Duration>[];

  bool get isRunning => _running;
  List<Duration> get laps => List<Duration>.unmodifiable(_laps);

  void start(DateTime nowUtc) {
    if (_running) return;
    _running = true;
    _startUtc = nowUtc.toUtc();
  }

  void pause(DateTime nowUtc) {
    if (!_running || _startUtc == null) return;
    _accumulated += nowUtc.toUtc().difference(_startUtc!);
    _startUtc = null;
    _running = false;
  }

  void resume(DateTime nowUtc) => start(nowUtc);

  void reset() {
    _running = false;
    _startUtc = null;
    _accumulated = Duration.zero;
    _laps.clear();
  }

  Duration elapsed(DateTime nowUtc) {
    if (!_running || _startUtc == null) {
      return _accumulated;
    }
    return _accumulated + nowUtc.toUtc().difference(_startUtc!);
  }

  Duration recordLap(DateTime nowUtc) {
    final value = elapsed(nowUtc);
    _laps.add(value);
    return value;
  }
}

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

void expectCondition(String name, bool condition) {
  if (!condition) {
    throw StateError('FAILED: $name');
  }
  print('PASS: $name');
}

void main() {
  final sw = StopwatchEngine();
  final t0 = DateTime.utc(2026, 1, 1, 0, 0, 0);

  sw.start(t0);
  expectCondition('elapsed after 10s',
      sw.elapsed(t0.add(const Duration(seconds: 10))) == const Duration(seconds: 10));

  sw.pause(t0.add(const Duration(seconds: 12)));
  expectCondition('pause freezes elapsed',
      sw.elapsed(t0.add(const Duration(seconds: 20))) == const Duration(seconds: 12));

  sw.resume(t0.add(const Duration(seconds: 30)));
  expectCondition('resume continues elapsed',
      sw.elapsed(t0.add(const Duration(seconds: 35))) == const Duration(seconds: 17));

  final lap = sw.recordLap(t0.add(const Duration(seconds: 35)));
  expectCondition('lap saved', lap == const Duration(seconds: 17));
  expectCondition('one lap', sw.laps.length == 1);

  final reminder = ReminderSchedule(
    id: 'hydrate',
    message: 'Drink water',
    interval: const Duration(minutes: 15),
    nextTriggerUtc: DateTime.utc(2026, 1, 1, 10, 0, 0),
  );

  final r = reminder.reconcile(DateTime.utc(2026, 1, 1, 10, 46, 0));
  expectCondition('reminder should notify', r.shouldNotify);
  expectCondition('missed reminder detected', r.missed);
  expectCondition('missed count = 3', r.missedCount == 3);
  expectCondition('next trigger advanced',
      reminder.nextTriggerUtc == DateTime.utc(2026, 1, 1, 11, 0, 0));

  print('All DartPad checks passed.');
}
```

## 3) Expected Output

DartPad console should print multiple `PASS: ...` lines followed by:

- `All DartPad checks passed.`

If any condition fails, DartPad will throw `StateError` identifying the failed case.
