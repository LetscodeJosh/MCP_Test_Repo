import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/corenergy_engage.dart';

class DbHelper {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final pathString = join(dbPath, 'pims_mcp_offline.db');
    return await openDatabase(
      pathString,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_engagements (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            temp_id TEXT UNIQUE,
            data TEXT,
            action_type TEXT,
            timestamp INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE pending_institutions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            temp_id TEXT UNIQUE,
            data TEXT,
            timestamp INTEGER
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE pending_institutions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              temp_id TEXT UNIQUE,
              data TEXT,
              timestamp INTEGER
            )
          ''');
        }
      },
    );
  }

  static Future<void> insertPendingEngagement(COREnergyEngage engage, String actionType) async {
    final db = await database;
    final dataString = jsonEncode(engage.toJson());
    await db.insert(
      'pending_engagements',
      {
        'temp_id': engage.name,
        'data': dataString,
        'action_type': actionType,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingEngagements() async {
    final db = await database;
    return await db.query('pending_engagements', orderBy: 'timestamp ASC');
  }

  static Future<void> deletePendingEngagement(String tempId) async {
    final db = await database;
    await db.delete(
      'pending_engagements',
      where: 'temp_id = ?',
      whereArgs: [tempId],
    );
  }

  static Future<void> insertPendingInstitution(Map<String, dynamic> instJson, String tempId) async {
    final db = await database;
    final dataString = jsonEncode(instJson);
    await db.insert(
      'pending_institutions',
      {
        'temp_id': tempId,
        'data': dataString,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingInstitutions() async {
    final db = await database;
    return await db.query('pending_institutions', orderBy: 'timestamp ASC');
  }

  static Future<void> deletePendingInstitution(String tempId) async {
    final db = await database;
    await db.delete(
      'pending_institutions',
      where: 'temp_id = ?',
      whereArgs: [tempId],
    );
  }

  static Future<void> clearAll() async {
    final db = await database;
    await db.delete('pending_engagements');
    await db.delete('pending_institutions');
  }
}
