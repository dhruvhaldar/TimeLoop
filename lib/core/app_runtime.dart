import 'dart:async';
import 'dart:io';
import 'reminder_schedule.dart';
import 'stopwatch_engine.dart';
import 'platform_service.dart';
import 'persistence_service.dart';
import 'checklist_item.dart';
import 'package:flutter/material.dart';

enum ReminderMode { beepOnly, beepAndPopup }
enum TimerFormat { full, minutesOnly }

class AppRuntime with ChangeNotifier {
  AppRuntime({
    StopwatchEngine? stopwatch,
    List<ReminderSchedule>? reminders,
    List<ChecklistItem>? checklistItems,
  })  : stopwatch = stopwatch ?? StopwatchEngine(),
        reminders = reminders ?? <ReminderSchedule>[],
        checklistItems = checklistItems ?? <ChecklistItem>[] {
    _log('AppRuntime Initializing...');
    _startTicker();
    _loadState().then((_) {
      _log('Initial state load complete.');
      notifyListeners();
    }).catchError((e) {
      _log('Error loading initial state: $e');
    });
  }

  void _log(String message) {
    print(message);
    try {
      File('runtime.log').writeAsStringSync('${DateTime.now().toIso8601String()}: $message\n', mode: FileMode.append);
    } catch (e) {}
  }

  Future<void> _loadState() async {
    _log('Loading state...');
    final saves = await PersistenceService.instance.loadSaves();
    _log('Loaded ${saves.length} stopwatch saves.');
    stopwatch.loadSaves(saves);
    
    final items = await PersistenceService.instance.loadChecklist();
    _log('Loaded ${items.length} checklist items.');
    checklistItems.clear();
    checklistItems.addAll(items);

    final loadedReminders = await PersistenceService.instance.loadReminders();
    _log('Loaded ${loadedReminders.length} reminders.');
    reminders.clear();
    reminders.addAll(loadedReminders);

    final swState = await PersistenceService.instance.loadStopwatchState();
    if (swState != null) {
      stopwatch.restoreState(
        isRunning: swState['isRunning'] == 1,
        startUtc: swState['startUtc'] != null ? DateTime.parse(swState['startUtc']) : null,
        accumulated: Duration(milliseconds: swState['accumulatedMs']),
      );
    }

    final formatStr = await PersistenceService.instance.loadSetting('timerFormat');
    if (formatStr != null) {
      timerFormat = TimerFormat.values.firstWhere((e) => e.name == formatStr, orElse: () => TimerFormat.full);
    }
  }

  final StopwatchEngine stopwatch;
  final List<ReminderSchedule> reminders;
  final List<ChecklistItem> checklistItems;
  Timer? _ticker;
  bool debugEnabled = false;
  ReminderMode reminderMode = ReminderMode.beepAndPopup;
  TimerFormat timerFormat = TimerFormat.full;

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      if (debugEnabled) {
        File('timeloop_debug.log').writeAsStringSync(
          'Ticker ran at ${now.toIso8601String()}\n',
          mode: FileMode.append,
        );
      }
      
      // Save stopwatch state periodically
      _saveStopwatchState();

      reconcileReminders(now);
    });
  }

  void _saveStopwatchState() {
    PersistenceService.instance.saveStopwatchState(
      isRunning: stopwatch.isRunning,
      startUtc: stopwatch.startUtc,
      accumulatedMs: stopwatch.accumulated.inMilliseconds,
    );
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

  // --- Reminder Actions ---

  void addReminder(ReminderSchedule reminder) {
    reminders.add(reminder);
    PersistenceService.instance.saveReminder(reminder);
    notifyListeners();
  }

  void toggleReminder(ReminderSchedule reminder) {
    reminder.active = !reminder.active;
    PersistenceService.instance.saveReminder(reminder);
    notifyListeners();
  }

  void deleteReminder(ReminderSchedule reminder) {
    reminders.remove(reminder);
    // Note: In JSON mode, we save the whole list or delete from it.
    // My PersistenceService saveReminder handles upsert, but I need a delete.
    _saveAllReminders();
    notifyListeners();
  }

  void _saveAllReminders() {
    // For now, I'll just save each one, but in JSON it's better to save the list.
    // I'll add a deleteReminder to PersistenceService.
    PersistenceService.instance.deleteReminder(reminderId: reminders.isEmpty ? null : reminders.first.id, all: true);
    for (final r in reminders) {
      PersistenceService.instance.saveReminder(r);
    }
  }

  // --- Checklist Actions ---

  void addChecklistItem(String text) {
    final item = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
    );
    checklistItems.add(item);
    PersistenceService.instance.saveChecklistItem(item, position: checklistItems.length - 1);
    notifyListeners();
  }

  void toggleChecklistItem(ChecklistItem item) {
    item.isCompleted = !item.isCompleted;
    PersistenceService.instance.saveChecklistItem(item);
    notifyListeners();
  }

  void deleteChecklistItem(String id) {
    checklistItems.removeWhere((i) => i.id == id);
    PersistenceService.instance.deleteChecklistItem(id);
    notifyListeners();
  }

  void clearCompletedChecklist() {
    final toRemove = checklistItems.where((i) => i.isCompleted).toList();
    for (final item in toRemove) {
      checklistItems.remove(item);
      PersistenceService.instance.deleteChecklistItem(item.id);
    }
    notifyListeners();
  }

  void reorderChecklistItem(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = checklistItems.removeAt(oldIndex);
    checklistItems.insert(newIndex, item);
    PersistenceService.instance.saveChecklistOrder(checklistItems);
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await PersistenceService.instance.clearAllData();
    reminders.clear();
    checklistItems.clear();
    stopwatch.reset();
    stopwatch.loadSaves([]);
  }
}
