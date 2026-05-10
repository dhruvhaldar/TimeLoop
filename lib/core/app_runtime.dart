import 'dart:async';
import 'dart:io';
import 'reminder_schedule.dart';
import 'stopwatch_engine.dart';
import 'platform_service.dart';
import 'persistence_service.dart';
import 'checklist_item.dart';

enum ReminderMode { beepOnly, beepAndPopup }

class AppRuntime {
  AppRuntime({
    StopwatchEngine? stopwatch,
    List<ReminderSchedule>? reminders,
    List<ChecklistItem>? checklistItems,
  })  : stopwatch = stopwatch ?? StopwatchEngine(),
        reminders = reminders ?? <ReminderSchedule>[],
        checklistItems = checklistItems ?? <ChecklistItem>[] {
    _startTicker();
    _loadState();
  }

  Future<void> _loadState() async {
    final saves = await PersistenceService.instance.loadSaves();
    stopwatch.loadSaves(saves);
    
    final items = await PersistenceService.instance.loadChecklist();
    checklistItems.clear();
    checklistItems.addAll(items);
  }

  final StopwatchEngine stopwatch;
  final List<ReminderSchedule> reminders;
  final List<ChecklistItem> checklistItems;
  Timer? _ticker;
  bool debugEnabled = false;
  ReminderMode reminderMode = ReminderMode.beepAndPopup;

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
          showPopup: reminderMode == ReminderMode.beepAndPopup,
        );
      }
    }
  }

  void dispose() {
    _ticker?.cancel();
  }

  // --- Checklist Actions ---

  void addChecklistItem(String text) {
    final item = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
    );
    checklistItems.add(item);
    PersistenceService.instance.saveChecklistItem(item);
  }

  void toggleChecklistItem(ChecklistItem item) {
    item.isCompleted = !item.isCompleted;
    PersistenceService.instance.saveChecklistItem(item);
  }

  void deleteChecklistItem(String id) {
    checklistItems.removeWhere((i) => i.id == id);
    PersistenceService.instance.deleteChecklistItem(id);
  }

  void clearCompletedChecklist() {
    final toRemove = checklistItems.where((i) => i.isCompleted).toList();
    for (final item in toRemove) {
      checklistItems.remove(item);
      PersistenceService.instance.deleteChecklistItem(item.id);
    }
  }
}
