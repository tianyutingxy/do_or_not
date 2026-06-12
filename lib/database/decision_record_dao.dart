import 'package:sqflite/sqflite.dart';

import '../models/decision_record.dart';
import 'app_database.dart';

class DecisionRecordDao {
  DecisionRecordDao({Database? database}) : _database = database;

  final Database? _database;

  Future<Database> get _db async => _database ?? AppDatabase.instance();

  Future<DecisionRecord> insert(DecisionRecord record) async {
    final db = await _db;
    final id = await db.insert('decision_records', record.toRow());
    return record.copyWith(id: id);
  }

  Future<void> updateMark(int id, bool isMarked) async {
    final db = await _db;
    await db.update(
      'decision_records',
      {'is_marked': isMarked ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateReflection(int id, String? reflection) async {
    final db = await _db;
    await db.update(
      'decision_records',
      {
        'reflection': reflection,
        'reflection_updated_at': reflection == null
            ? null
            : DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DecisionRecord>> listMarked({int limit = 100, int offset = 0}) async {
    final db = await _db;
    final rows = await db.query(
      'decision_records',
      where: 'is_marked = ?',
      whereArgs: [1],
      orderBy: 'decided_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(DecisionRecord.fromRow).toList();
  }

  Future<DecisionRecord?> findById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'decision_records',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DecisionRecord.fromRow(rows.first);
  }

  Future<int> countMarked() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM decision_records WHERE is_marked = 1',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }
}
