import 'package:image_picker/image_picker.dart';

import '../database/decision_record_dao.dart';
import '../models/animation_style.dart';
import '../models/decision.dart';
import '../models/decision_record.dart';
import '../models/record_photo_paths.dart';
import '../models/user_response.dart';
import 'demo_record_seeder.dart';
import 'record_photo_storage.dart';

class DecisionRecordService {
  DecisionRecordService({
    DecisionRecordDao? dao,
    DemoRecordSeeder? demoSeeder,
    RecordPhotoStorage? photoStorage,
    ImagePicker? imagePicker,
  })  : _dao = dao ?? DecisionRecordDao(),
        _demoSeeder = demoSeeder ?? DemoRecordSeeder(dao: dao),
        _photoStorage = photoStorage ?? RecordPhotoStorage(),
        _imagePicker = imagePicker ?? ImagePicker();

  final DecisionRecordDao _dao;
  final DemoRecordSeeder _demoSeeder;
  final RecordPhotoStorage _photoStorage;
  final ImagePicker _imagePicker;

  Future<DecisionRecord> createFromSession({
    required RevealStyle revealStyle,
    required Decision objective,
    required Decision finalDecision,
    required UserResponse response,
    required int retryCount,
  }) async {
    final now = DateTime.now();
    return _dao.insert(
      DecisionRecord(
        decidedAt: now,
        revealStyle: revealStyle,
        objectiveDecision: objective,
        userResponse: response,
        finalDecision: finalDecision,
        retryCount: retryCount,
        createdAt: now,
      ),
    );
  }

  Future<void> setMarked(int id, bool isMarked) => _dao.updateMark(id, isMarked);

  Future<void> saveReflection(int id, String? reflection) =>
      _dao.updateReflection(
        id,
        reflection?.trim().isEmpty ?? true ? null : reflection?.trim(),
      );

  Future<void> saveNotes({
    required int id,
    String? decisionContext,
    String? reflection,
  }) =>
      _dao.saveNotes(
        id: id,
        decisionContext: decisionContext,
        reflection: reflection,
      );

  Future<List<String?>?> pickPhotoForSlot({
    required int recordId,
    required int slotIndex,
    required List<String?> currentPaths,
  }) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (picked == null) return null;

    final paths = List<String?>.from(RecordPhotoPaths.normalize(currentPaths));
    final saved = await _photoStorage.persistPhoto(
      recordId: recordId,
      slotIndex: slotIndex,
      sourcePath: picked.path,
      previousPath: paths[slotIndex],
    );
    paths[slotIndex] = saved;
    await _dao.updatePhotoPaths(recordId, paths);
    return paths;
  }

  Future<void> archiveWithReflection(int id, String reflection) =>
      _dao.archive(id, reflection.trim());

  Future<List<DecisionRecord>> listPendingReview() async {
    await _demoSeeder.ensureSeeded();
    return _dao.listPendingReview();
  }

  Future<List<DecisionRecord>> listArchived() async {
    await _demoSeeder.ensureSeeded();
    return _dao.listArchived();
  }

  Future<DecisionRecord?> findById(int id) => _dao.findById(id);

  Future<int> countPendingReview() async {
    await _demoSeeder.ensureSeeded();
    return _dao.countPendingReview();
  }

  Future<void> deleteRecord(int id) async {
    final record = await findById(id);
    if (record != null) {
      await _photoStorage.deleteAll(record.photoPaths);
    }
    await _dao.deleteById(id);
  }
}
