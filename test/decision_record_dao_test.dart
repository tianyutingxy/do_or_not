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
  });

  test('listMarked only returns marked records', () async {
    final dao = DecisionRecordDao();
    await dao.insert(sampleRecord());
    final marked = await dao.insert(sampleRecord(isMarked: true));
    await dao.insert(sampleRecord(isMarked: true));

    final results = await dao.listMarked();
    expect(results, hasLength(2));
    expect(results.every((r) => r.isMarked), isTrue);
    expect(results.first.id, marked.id);
  });

  test('updateMark toggles visibility in listMarked', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord());

    await dao.updateMark(record.id!, true);
    expect(await dao.countMarked(), 1);

    await dao.updateMark(record.id!, false);
    expect(await dao.countMarked(), 0);
    expect(await dao.listMarked(), isEmpty);
  });

  test('updateReflection persists text', () async {
    final dao = DecisionRecordDao();
    final record = await dao.insert(sampleRecord(isMarked: true));

    await dao.updateReflection(record.id!, '后来证明是对的');
    final updated = await dao.findById(record.id!);

    expect(updated?.reflection, '后来证明是对的');
    expect(updated?.reflectionUpdatedAt, isNotNull);
  });
}
