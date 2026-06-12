import 'package:shared_preferences/shared_preferences.dart';

import '../database/decision_record_dao.dart';
import '../models/animation_style.dart';
import '../models/decision.dart';
import '../models/decision_record.dart';
import '../models/user_response.dart';

class DemoRecordSeeder {
  DemoRecordSeeder({DecisionRecordDao? dao}) : _dao = dao ?? DecisionRecordDao();

  final DecisionRecordDao _dao;
  static const _seededKey = 'demo_records_seeded_v1';

  Future<void> ensureSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKey) == true) return;

    final now = DateTime.now();

    await _dao.insert(
      DecisionRecord(
        decidedAt: now.subtract(const Duration(days: 2, hours: 3)),
        revealStyle: RevealStyle.coin,
        objectiveDecision: Decision.doIt,
        userResponse: UserResponse.comply,
        finalDecision: Decision.doIt,
        retryCount: 1,
        isMarked: true,
        decisionContext: '【示例】是否接受这份新工作',
        reflection: '【示例】这是一次值得回看的决定，你可以在这里写下心得。',
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
      ),
    );

    final archivedAt = now.subtract(const Duration(days: 5));
    await _dao.insert(
      DecisionRecord(
        decidedAt: archivedAt.subtract(const Duration(hours: 2)),
        revealStyle: RevealStyle.cards,
        objectiveDecision: Decision.notIt,
        userResponse: UserResponse.rebel,
        finalDecision: Decision.doIt,
        retryCount: 0,
        isMarked: true,
        isArchived: true,
        decisionContext: '【示例】要不要搬去新城市',
        reflection: '【示例】已完成回顾并归档的决定，仅作界面示意。',
        reflectionUpdatedAt: archivedAt,
        archivedAt: archivedAt,
        createdAt: archivedAt.subtract(const Duration(hours: 2)),
      ),
    );

    await prefs.setBool(_seededKey, true);
  }
}
