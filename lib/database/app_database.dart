import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static Database? _database;
  static String? _overridePath;

  static const _dbName = 'do_or_not.db';
  static const _version = 5;

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
      onCreate: _createSchema,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE decision_records ADD COLUMN is_archived INTEGER NOT NULL DEFAULT 0',
          );
          await db.execute(
            'ALTER TABLE decision_records ADD COLUMN archived_at INTEGER',
          );
          await db.execute('''
            CREATE INDEX IF NOT EXISTS idx_decision_active_marked
            ON decision_records (is_marked, is_archived, decided_at DESC)
          ''');
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE decision_records ADD COLUMN decision_context TEXT',
          );
        }
        if (oldVersion < 4) {
          await db.execute(
            'ALTER TABLE decision_records ADD COLUMN photo_paths TEXT',
          );
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE decision_records ADD COLUMN tags TEXT',
          );
        }
      },
    );
    return _database!;
  }

  static Future<void> _createSchema(Database db, int version) async {
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
        is_archived INTEGER NOT NULL DEFAULT 0,
        decision_context TEXT,
        photo_paths TEXT,
        tags TEXT,
        reflection TEXT,
        reflection_updated_at INTEGER,
        archived_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX idx_decision_active_marked
      ON decision_records (is_marked, is_archived, decided_at DESC)
    ''');
  }
}
