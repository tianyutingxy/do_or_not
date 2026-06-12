import '../database/decision_record_dao.dart';
import '../models/animation_style.dart';
import '../models/decision.dart';
import '../models/decision_record.dart';
import '../models/user_response.dart';

class DecisionRecordService {
  DecisionRecordService({DecisionRecordDao? dao}) : _dao = dao ?? DecisionRecordDao();

  final DecisionRecordDao _dao;

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
      _dao.updateReflection(id, reflection?.trim().isEmpty ?? true ? null : reflection?.trim());

  Future<List<DecisionRecord>> listMarked() => _dao.listMarked();

  Future<DecisionRecord?> findById(int id) => _dao.findById(id);

  Future<int> countMarked() => _dao.countMarked();
}
