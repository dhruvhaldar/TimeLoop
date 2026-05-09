# TimeLoop

TimeLoop is a cross-platform stopwatch and interval reminder app targeting Android, Web, Windows, and Linux.

## What is implemented

- Core stopwatch domain engine (`StopwatchEngine`): start/pause/resume/reset, lap recording, wake reconciliation.
- Core reminder domain engine (`ReminderSchedule`): recurring interval handling, missed-reminder detection, next-trigger resync.
- App runtime orchestrator (`AppRuntime`) to reconcile all reminders against current UTC time.
- Unit + E2E domain tests covering stopwatch flow, reminder recovery, active/inactive schedule behavior.

## Project files

- `SOFTWARE_SPEC.md`: comprehensive product and platform specification.
- `PLATFORM_SETUP.md`: platform compiler/build instructions for Android, Web, Windows, Linux.

## Test

```bash
dart pub get
dart test
```


## DartPad Validation

Use `DARTPAD_TESTING.md` to validate the core logic in https://dartpad.dev/.
