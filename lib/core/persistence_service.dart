import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'reminder_schedule.dart';
import 'checklist_item.dart';

class PersistenceService {
  static final PersistenceService instance = PersistenceService._();
  PersistenceService._();

  Database? _database;
  String? _savesPath;

  Future<String> get _lapsFilePath async {
    if (_savesPath != null) return _savesPath!;
    final directory = await getApplicationSupportDirectory();
    _savesPath = join(directory.path, 'saved_times.txt');
    return _savesPath!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  void _log(String message) {
    print(message);
    try {
      File('persistence.log').writeAsStringSync('$message\n', mode: FileMode.append);
    } catch (e) {}
  }

  Future<Database> _initDB() async {
    if (kIsWeb) {
      throw UnimplementedError("Web persistence not implemented yet.");
    }
    
    final directory = await getApplicationSupportDirectory();
    String path = join(directory.path, 'timeloop.db');
    _log('Initializing DB at path: $path');
    
    return await openDatabase(
      path,
      version: 4,
      onCreate: (db, version) async {
        _log('Creating DB version $version');
        await _createDB(db, version);
      },
      onUpgrade: (db, oldV, newV) async {
        _log('Updating DB from $oldV to $newV');
        await _onUpgrade(db, oldV, newV);
      },
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS checklist (
          id TEXT PRIMARY KEY,
          text TEXT,
          isCompleted INTEGER
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE checklist ADD COLUMN position INTEGER DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS stopwatch_state (
          id INTEGER PRIMARY KEY,
          isRunning INTEGER,
          startUtc TEXT,
          accumulatedMs INTEGER
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE reminders (
        id TEXT PRIMARY KEY,
        message TEXT,
        intervalMs INTEGER,
        nextTriggerUtc TEXT,
        active INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE laps (
        id INTEGER PRIMARY KEY AUTO_INCREMENT,
        timestamp TEXT,
        durationMs INTEGER
      )
    ''');
    
    await db.execute('''
      CREATE TABLE checklist (
        id TEXT PRIMARY KEY,
        text TEXT,
        isCompleted INTEGER,
        position INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE stopwatch_state (
        id INTEGER PRIMARY KEY,
        isRunning INTEGER,
        startUtc TEXT,
        accumulatedMs INTEGER
      )
    ''');
  }

  Future<void> saveReminder(ReminderSchedule reminder) async {
    final db = await database;
    await db.insert(
      'reminders',
      {
        'id': reminder.id,
        'message': reminder.message,
        'intervalMs': reminder.interval.inMilliseconds,
        'nextTriggerUtc': reminder.nextTriggerUtc.toIso8601String(),
        'active': reminder.active ? 1 : 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveSaves(List<Duration> saves) async {
    final path = await _lapsFilePath;
    final file = File(path);
    final content = saves.map((d) => d.inMilliseconds.toString()).join('\n');
    await file.writeAsString(content);
  }

  Future<List<Duration>> loadSaves() async {
    final path = await _lapsFilePath;
    final file = File(path);
    if (!await file.exists()) return [];
    
    final content = await file.readAsString();
    if (content.isEmpty) return [];
    
    return content
        .split('\n')
        .where((s) => s.isNotEmpty)
        .map((s) => Duration(milliseconds: int.parse(s)))
        .toList();
  }

  // --- Stopwatch State ---

  Future<Map<String, dynamic>?> loadStopwatchState() async {
    final db = await database;
    final results = await db.query('stopwatch_state', where: 'id = 1');
    return results.isNotEmpty ? results.first : null;
  }

  Future<void> saveStopwatchState({
    required bool isRunning,
    DateTime? startUtc,
    required int accumulatedMs,
  }) async {
    final db = await database;
    await db.insert(
      'stopwatch_state',
      {
        'id': 1,
        'isRunning': isRunning ? 1 : 0,
        'startUtc': startUtc?.toIso8601String(),
        'accumulatedMs': accumulatedMs,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- Checklist Methods ---

  Future<List<ChecklistItem>> loadChecklist() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('checklist', orderBy: 'position ASC');
    return List.generate(maps.length, (i) => ChecklistItem.fromMap(maps[i]));
  }

  Future<void> saveChecklistItem(ChecklistItem item, {int? position}) async {
    _log('Saving checklist item: ${item.text}');
    final db = await database;
    final data = item.toMap();
    if (position != null) {
      data['position'] = position;
    }
    await db.insert(
      'checklist',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveChecklistOrder(List<ChecklistItem> items) async {
    final db = await database;
    await db.transaction((txn) async {
      for (int i = 0; i < items.length; i++) {
        await txn.update(
          'checklist',
          {'position': i},
          where: 'id = ?',
          whereArgs: [items[i].id],
        );
      }
    });
  }

  Future<void> deleteChecklistItem(String id) async {
    final db = await database;
    await db.delete(
      'checklist',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Backup & Restore ---

  Future<String> exportBackup() async {
    final db = await database;
    
    // Get reminders
    final reminders = await db.query('reminders');
    
    // Get checklist
    final checklist = await db.query('checklist');
    
    // Get laps (from file)
    final laps = await loadSaves();
    final lapsData = laps.map((d) => d.inMilliseconds).toList();

    final backup = {
      'version': 1,
      'timestamp': DateTime.now().toIso8601String(),
      'reminders': reminders,
      'checklist': checklist,
      'laps': lapsData,
    };

    final jsonString = jsonEncode(backup);
    final backupFile = File('timeloop_backup.json');
    await backupFile.writeAsString(jsonString);
    
    return backupFile.absolute.path;
  }

  Future<void> importBackup(String jsonString) async {
    final Map<String, dynamic> backup = jsonDecode(jsonString);
    final db = await database;

    await db.transaction((txn) async {
      // Clear existing
      await txn.delete('reminders');
      await txn.delete('checklist');

      // Restore reminders
      if (backup['reminders'] != null) {
        for (var r in backup['reminders']) {
          await txn.insert('reminders', r);
        }
      }

      // Restore checklist
      if (backup['checklist'] != null) {
        for (var c in backup['checklist']) {
          await txn.insert('checklist', c);
        }
      }
    });

    // Restore laps
    if (backup['laps'] != null) {
      final laps = (backup['laps'] as List).map((ms) => Duration(milliseconds: ms as int)).toList();
      await saveSaves(laps);
    }
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('reminders');
      await txn.delete('checklist');
      await txn.delete('laps');
    });
    
    final path = await _lapsFilePath;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
