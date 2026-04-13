import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class LocalDbService {
  static Database? _database;
  static const String tableTasks = 'tasks';
  static bool _isSupported = true;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // sqflite is not supported on web
      if (kIsWeb) {
        _isSupported = false;
        throw Exception('SQLite not supported on web');
      }
      String path = join(await getDatabasesPath(), 'strm_tasks.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
    } catch (e) {
      debugPrint('Database init failed: $e');
      _isSupported = false;
      throw Exception('Database initialization failed: $e');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableTasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        status TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  Future<int> insertDraft(Task task) async {
    try {
      if (!_isSupported) return -1;
      final db = await database;
      return await db.insert(tableTasks, task.toMap());
    } catch (e) {
      debugPrint('Insert draft failed: $e');
      return -1;
    }
  }

  Future<List<Task>> getUnsyncedDrafts() async {
    try {
      if (!_isSupported) return [];
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        tableTasks,
        where: 'synced = ?',
        whereArgs: [0],
      );
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Get drafts failed: $e');
      return [];
    }
  }

  Future<List<Task>> getAllLocalTasks() async {
    try {
      if (!_isSupported) return [];
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(tableTasks);
      return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
    } catch (e) {
      debugPrint('Get local tasks failed: $e');
      return [];
    }
  }

  Future<int> markSynced(int id) async {
    try {
      if (!_isSupported) return -1;
      final db = await database;
      return await db.update(
        tableTasks,
        {'synced': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Mark synced failed: $e');
      return -1;
    }
  }

  Future<int> deleteTask(int id) async {
    try {
      if (!_isSupported) return -1;
      final db = await database;
      return await db.delete(
        tableTasks,
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Delete task failed: $e');
      return -1;
    }
  }

  Future<int> updateTaskStatus(int id, String status) async {
    try {
      if (!_isSupported) return -1;
      final db = await database;
      return await db.update(
        tableTasks,
        {'status': status, 'synced': 0},
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      debugPrint('Update task status failed: $e');
      return -1;
    }
  }
}
