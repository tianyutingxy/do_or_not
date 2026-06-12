import 'package:sqflite/sqflite.dart';

import '../models/decision_record.dart';
import '../models/record_photo_paths.dart';
import '../models/record_tags.dart';
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
      where: 'id = ? AND is_archived = 0',
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

  Future<void> updatePhotoPaths(int id, List<String?> paths) async {
    final db = await _db;
    await db.update(
      'decision_records',
      {'photo_paths': RecordPhotoPaths.encode(paths)},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> saveNotes({
    required int id,
    String? decisionContext,
    String? reflection,
    List<String>? tags,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _db;
    final trimmedContext = decisionContext?.trim();
    final trimmedReflection = reflection?.trim();
    await db.update(
      'decision_records',
      {
        'decision_context':
            trimmedContext == null || trimmedContext.isEmpty ? null : trimmedContext,
        'reflection':
            trimmedReflection == null || trimmedReflection.isEmpty ? null : trimmedReflection,
        'reflection_updated_at':
            trimmedReflection == null || trimmedReflection.isEmpty ? null : now,
        'tags': RecordTags.encode(RecordTags.normalize(tags)),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> archive(int id, String reflection) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _db;
    await db.update(
      'decision_records',
      {
        'is_archived': 1,
        'archived_at': now,
        'reflection': reflection,
        'reflection_updated_at': now,
      },
      where: 'id = ? AND is_marked = 1 AND is_archived = 0',
      whereArgs: [id],
    );
  }

  /// 待回顾：已标记、未归档。
  Future<List<DecisionRecord>> listPendingReview({
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'decision_records',
      where: 'is_marked = 1 AND is_archived = 0',
      orderBy: 'decided_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(DecisionRecord.fromRow).toList();
  }

  Future<List<DecisionRecord>> listArchived({
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'decision_records',
      where: 'is_archived = 1',
      orderBy: 'archived_at DESC',
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

  /// 亮灯计数：待回顾的标记决定。
  Future<int> countPendingReview() async {
    final db = await _db;
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM decision_records WHERE is_marked = 1 AND is_archived = 0',
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteById(int id) async {
    final db = await _db;
    await db.delete(
      'decision_records',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
