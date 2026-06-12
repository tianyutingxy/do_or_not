import 'package:do_or_not/database/app_database.dart';
import 'package:do_or_not/database/decision_record_dao.dart';
import 'package:do_or_not/models/animation_style.dart';
import 'package:do_or_not/models/decision.dart';
import 'package:do_or_not/models/decision_record.dart';
import 'package:do_or_not/models/user_response.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await AppDatabase.resetForTesting();
    AppDatabase.overridePathForTesting(inMemoryDatabasePath);
  });

  tearDown(() async {
    await AppDatabase.resetForTesting();
  });

  DecisionRecord sampleRecord({bool isMarked = false}) {
    final now = DateTime(2026, 6, 12, 14, 30);
    return DecisionRecord(
      decidedAt: now,
      revealStyle: RevealStyle.coin,
      objectiveDecision: Decision.doIt,
      userResponse: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 2,
      isMarked: isMarked,
      createdAt: now,
    );
  }

  test('insert and findById round trip', () async {
    final dao = DecisionRecordDao();
    final inserted = await dao.insert(sampleRecord());

    expect(inserted.id, isNotNull);

    final found = await dao.findById(inserted.id!);
    expect(found, isNotNull);
    expect(found!.objectiveDecision, Decision.doIt);
    expect(found.retryCount, 2);
    expect(found.isMarked, isFalse);
    expect(found.isArchived, isFalse);
  });

  test('listPendingReview only returns marked unarchived records', () async {
    final dao = DecisionRecordDao();
    await dao.insert(sampleRecord());
    final marked = await dao.insert(sampleRecord(isMarked: true));
    await dao.insert(sampleRecord(isMarked: true));

    final results = await dao.listPendingReview();
    expect(results, hasLength(2));
    expect(results.every((r) => r.isPendingReview), isTrue);
    expect(results.first.id, marked.id);
  });

  test('updateMark toggles visibility in listPendingReview', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord());

    await dao.updateMark(record.id!, true);
    expect(await dao.countPendingReview(), 1);

    await dao.updateMark(record.id!, false);
    expect(await dao.countPendingReview(), 0);
    expect(await dao.listPendingReview(), isEmpty);
  });

  test('updateReflection persists text', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord(isMarked: true));

    await dao.updateReflection(record.id!, '后来证明是对的');
    final updated = await dao.findById(record.id!);

    expect(updated?.reflection, '后来证明是对的');
    expect(updated?.reflectionUpdatedAt, isNotNull);
  });

  test('archive moves record out of pending and into archived list', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord(isMarked: true));

    await dao.archive(record.id!, '这次决定很正确');
    final archived = await dao.findById(record.id!);

    expect(archived?.isArchived, isTrue);
    expect(archived?.archivedAt, isNotNull);
    expect(archived?.reflection, '这次决定很正确');
    expect(await dao.listPendingReview(), isEmpty);
    expect(await dao.countPendingReview(), 0);
    expect(await dao.listArchived(), hasLength(1));
  });

  test('updateMark does not affect archived records', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord(isMarked: true));
    await dao.archive(record.id!, '心得');

    await dao.updateMark(record.id!, false);
    final stillArchived = await dao.findById(record.id!);

    expect(stillArchived?.isArchived, isTrue);
    expect(stillArchived?.isMarked, isTrue);
  });

  test('updateReflection works on archived records', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord(isMarked: true));
    await dao.archive(record.id!, '初稿');

    await dao.updateReflection(record.id!, '修订后的心得');
    final updated = await dao.findById(record.id!);

    expect(updated?.isArchived, isTrue);
    expect(updated?.reflection, '修订后的心得');
  });

  test('saveNotes persists context and reflection', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord(isMarked: true));

    await dao.saveNotes(
      id: record.id!,
      decisionContext: '是否买房',
      reflection: '后来证明是对的',
    );
    final updated = await dao.findById(record.id!);

    expect(updated?.decisionContext, '是否买房');
    expect(updated?.reflection, '后来证明是对的');
    expect(updated?.reflectionUpdatedAt, isNotNull);
  });

  test('updatePhotoPaths persists encoded paths', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord(isMarked: true));

    await dao.updatePhotoPaths(record.id!, [
      '/tmp/a.jpg',
      null,
      '/tmp/c.jpg',
    ]);
    final updated = await dao.findById(record.id!);

    expect(updated?.photoPaths[0], '/tmp/a.jpg');
    expect(updated?.photoPaths[1], isNull);
    expect(updated?.photoPaths[2], '/tmp/c.jpg');
  });

  test('deleteById removes record', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord(isMarked: true));

    await dao.deleteById(record.id!);

    expect(await dao.findById(record.id!), isNull);
    expect(await dao.listPendingReview(), isEmpty);
  });
}
