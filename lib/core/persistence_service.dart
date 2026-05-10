import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'reminder_schedule.dart';
import 'checklist_item.dart';

class PersistenceService {
  static final PersistenceService instance = PersistenceService._();
  PersistenceService._();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    if (kIsWeb) {
      // For web, we might need a different approach, but for now we'll use a mock
      // or a simple local storage if we had the dependency.
      // Returning a mock database or throwing if not supported.
      throw UnimplementedError("Web persistence not implemented yet.");
    }

    String path = join(await getDatabasesPath(), 'timeloop.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
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
        isCompleted INTEGER
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
    final file = File('saved_times.txt');
    final content = saves.map((d) => d.inMilliseconds.toString()).join('\n');
    await file.writeAsString(content);
  }

  Future<List<Duration>> loadSaves() async {
    final file = File('saved_times.txt');
    if (!await file.exists()) return [];
    
    final content = await file.readAsString();
    if (content.isEmpty) return [];
    
    return content
        .split('\n')
        .where((s) => s.isNotEmpty)
        .map((s) => Duration(milliseconds: int.parse(s)))
        .toList();
  }

  // --- Checklist Methods ---

  Future<List<ChecklistItem>> loadChecklist() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('checklist');
    return List.generate(maps.length, (i) => ChecklistItem.fromMap(maps[i]));
  }

  Future<void> saveChecklistItem(ChecklistItem item) async {
    final db = await database;
    await db.insert(
      'checklist',
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
}
