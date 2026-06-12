import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _database;
  static String? _overridePath;

  static const _dbName = 'do_or_not.db';
  static const _version = 1;

  static void overridePathForTesting(String path) {
    _overridePath = path;
    _database = null;
  }

  static Future<void> resetForTesting() async {
    if (_database != null) {
      await _database!.close();
    }
    _database = null;
    _overridePath = null;
  }

  static Future<Database> instance() async {
    if (_database != null) return _database!;

    final path = _overridePath ?? p.join(await getDatabasesPath(), _dbName);
    _database = await openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE decision_records (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            decided_at INTEGER NOT NULL,
            reveal_style TEXT NOT NULL,
            objective_decision TEXT NOT NULL,
            user_response TEXT NOT NULL,
            final_decision TEXT NOT NULL,
            retry_count INTEGER NOT NULL DEFAULT 0,
            is_marked INTEGER NOT NULL DEFAULT 0,
            reflection TEXT,
            reflection_updated_at INTEGER,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_decision_marked_time
          ON decision_records (is_marked, decided_at DESC)
        ''');
      },
    );
    return _database!;
  }
}
