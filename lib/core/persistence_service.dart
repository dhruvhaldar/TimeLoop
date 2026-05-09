import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'reminder_schedule.dart';

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
      version: 1,
      onCreate: _createDB,
    );
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

  Future<List<ReminderSchedule>> loadReminders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('reminders');

    return List.generate(maps.length, (i) {
      return ReminderSchedule(
        id: maps[i]['id'],
        message: maps[i]['message'],
        interval: Duration(milliseconds: maps[i]['intervalMs']),
        nextTriggerUtc: DateTime.parse(maps[i]['nextTriggerUtc']),
        active: maps[i]['active'] == 1,
      );
    });
  }
}
