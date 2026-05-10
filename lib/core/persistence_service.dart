import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'reminder_schedule.dart';
import 'checklist_item.dart';

class PersistenceService {
  static final PersistenceService instance = PersistenceService._();
  PersistenceService._();

  Future<File> get _dataFile async {
    final directory = await getApplicationSupportDirectory();
    return File(join(directory.path, 'timeloop_v2_data.json'));
  }

  Future<Map<String, dynamic>> _readAll() async {
    try {
      final file = await _dataFile;
      if (!await file.exists()) return {};
      final content = await file.readAsString();
      return jsonDecode(content);
    } catch (e) {
      _log('Read error: $e');
      return {};
    }
  }

  Future<void> _writeAll(Map<String, dynamic> data) async {
    try {
      final file = await _dataFile;
      await file.writeAsString(jsonEncode(data));
      _log('Data saved to: ${file.path}');
    } catch (e) {
      _log('Write error: $e');
    }
  }

  void _log(String message) {
    print(message);
    try {
      // Log to a file in the same directory as data for debugging
      getApplicationSupportDirectory().then((dir) {
        File(join(dir.path, 'debug.log')).writeAsStringSync('${DateTime.now()}: $message\n', mode: FileMode.append);
      });
    } catch (e) {}
  }

  // --- Reminders ---

  Future<void> saveReminder(ReminderSchedule reminder) async {
    final data = await _readAll();
    final List<dynamic> reminders = data['reminders'] ?? [];
    reminders.removeWhere((r) => r['id'] == reminder.id);
    reminders.add({
      'id': reminder.id,
      'message': reminder.message,
      'intervalMs': reminder.interval.inMilliseconds,
      'nextTriggerUtc': reminder.nextTriggerUtc.toIso8601String(),
      'active': reminder.active ? 1 : 0,
    });
    data['reminders'] = reminders;
    await _writeAll(data);
  }

  Future<void> deleteReminder({String? reminderId, bool all = false}) async {
    final data = await _readAll();
    if (all) {
      data['reminders'] = [];
    } else if (reminderId != null) {
      final List<dynamic> reminders = data['reminders'] ?? [];
      reminders.removeWhere((r) => r['id'] == reminderId);
      data['reminders'] = reminders;
    }
    await _writeAll(data);
  }

  Future<List<ReminderSchedule>> loadReminders() async {
    final data = await _readAll();
    final List<dynamic> items = data['reminders'] ?? [];
    return items.map((r) {
      return ReminderSchedule(
        id: r['id'],
        message: r['message'],
        interval: Duration(milliseconds: r['intervalMs']),
        nextTriggerUtc: DateTime.parse(r['nextTriggerUtc']),
        active: r['active'] == 1,
      );
    }).toList();
  }

  // --- Laps ---

  Future<void> saveSaves(List<Duration> saves) async {
    final data = await _readAll();
    data['laps'] = saves.map((d) => d.inMilliseconds).toList();
    await _writeAll(data);
  }

  Future<List<Duration>> loadSaves() async {
    final data = await _readAll();
    final List<dynamic> laps = data['laps'] ?? [];
    return laps.map((ms) => Duration(milliseconds: ms as int)).toList();
  }

  // --- Stopwatch State ---

  Future<Map<String, dynamic>?> loadStopwatchState() async {
    final data = await _readAll();
    return data['stopwatch_state'];
  }

  Future<void> saveStopwatchState({
    required bool isRunning,
    DateTime? startUtc,
    required int accumulatedMs,
  }) async {
    final data = await _readAll();
    data['stopwatch_state'] = {
      'isRunning': isRunning ? 1 : 0,
      'startUtc': startUtc?.toIso8601String(),
      'accumulatedMs': accumulatedMs,
    };
    await _writeAll(data);
  }

  // --- Checklist ---

  Future<List<ChecklistItem>> loadChecklist() async {
    final data = await _readAll();
    final List<dynamic> items = data['checklist'] ?? [];
    final list = items.map((i) => ChecklistItem.fromMap(Map<String, dynamic>.from(i))).toList();
    list.sort((a, b) {
      final posA = (items.firstWhere((it) => it['id'] == a.id)['position'] ?? 0) as int;
      final posB = (items.firstWhere((it) => it['id'] == b.id)['position'] ?? 0) as int;
      return posA.compareTo(posB);
    });
    return list;
  }

  Future<void> saveChecklistItem(ChecklistItem item, {int? position}) async {
    final data = await _readAll();
    final List<dynamic> items = data['checklist'] ?? [];
    final existingIndex = items.indexWhere((i) => i['id'] == item.id);
    
    final itemMap = item.toMap();
    if (position != null) {
      itemMap['position'] = position;
    } else if (existingIndex != -1) {
      itemMap['position'] = items[existingIndex]['position'] ?? 0;
    } else {
      itemMap['position'] = items.length;
    }

    if (existingIndex != -1) {
      items[existingIndex] = itemMap;
    } else {
      items.add(itemMap);
    }
    
    data['checklist'] = items;
    await _writeAll(data);
  }

  Future<void> saveChecklistOrder(List<ChecklistItem> items) async {
    final data = await _readAll();
    final List<dynamic> checklist = [];
    for (int i = 0; i < items.length; i++) {
      final map = items[i].toMap();
      map['position'] = i;
      checklist.add(map);
    }
    data['checklist'] = checklist;
    await _writeAll(data);
  }

  Future<void> deleteChecklistItem(String id) async {
    final data = await _readAll();
    final List<dynamic> items = data['checklist'] ?? [];
    items.removeWhere((i) => i['id'] == id);
    data['checklist'] = items;
    await _writeAll(data);
  }

  // --- Backup & Restore ---

  Future<String> exportBackup() async {
    final data = await _readAll();
    final jsonString = jsonEncode({
      'version': 2,
      'timestamp': DateTime.now().toIso8601String(),
      'data': data,
    });
    final backupFile = File('timeloop_backup.json');
    await backupFile.writeAsString(jsonString);
    return backupFile.absolute.path;
  }

  Future<void> importBackup(String jsonString) async {
    final backup = jsonDecode(jsonString);
    if (backup['data'] != null) {
      await _writeAll(backup['data']);
    }
  }

  Future<void> clearAllData() async {
    await _writeAll({});
  }
}
