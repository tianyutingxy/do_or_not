import 'package:shared_preferences/shared_preferences.dart';

import '../database/decision_record_dao.dart';
import '../models/animation_style.dart';
import '../models/decision.dart';
import '../models/decision_record.dart';
import '../models/record_tags.dart';
import '../models/user_response.dart';

class DemoRecordSeeder {
  DemoRecordSeeder({DecisionRecordDao? dao}) : _dao = dao ?? DecisionRecordDao();

  final DecisionRecordDao _dao;
  static const _seededKeyV2 = 'demo_records_seeded_v2';

  Future<void> ensureSeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_seededKeyV2) == true) return;

    final now = DateTime.now();
    for (final spec in _timelineDemoSpecs()) {
      await _dao.insert(spec.build(now));
    }

    await prefs.setBool(_seededKeyV2, true);
  }
}

class _DemoSpec {
  const _DemoSpec({
    required this.daysAgo,
    required this.context,
    required this.reflection,
    required this.tags,
    required this.revealStyle,
    required this.objective,
    required this.response,
    required this.finalDecision,
    required this.retryCount,
    this.archivedDaysAgo,
  });

  final int daysAgo;
  final String context;
  final String reflection;
  final List<String> tags;
  final RevealStyle revealStyle;
  final Decision objective;
  final UserResponse response;
  final Decision finalDecision;
  final int retryCount;
  final int? archivedDaysAgo;

  DecisionRecord build(DateTime now) {
    final decidedAt = now.subtract(Duration(days: daysAgo, hours: 4));
    final isArchived = archivedDaysAgo != null;
    final archivedAt =
        isArchived ? now.subtract(Duration(days: archivedDaysAgo!, hours: 2)) : null;

    return DecisionRecord(
      decidedAt: decidedAt,
      revealStyle: revealStyle,
      objectiveDecision: objective,
      userResponse: response,
      finalDecision: finalDecision,
      retryCount: retryCount,
      isMarked: true,
      isArchived: isArchived,
      decisionContext: context,
      tags: tags,
      reflection: reflection,
      reflectionUpdatedAt: archivedAt ?? decidedAt.add(const Duration(hours: 6)),
      archivedAt: archivedAt,
      createdAt: decidedAt,
    );
  }
}

List<_DemoSpec> _timelineDemoSpecs() {
  return [
    _DemoSpec(
      daysAgo: 3,
      context: '【示例】是否接受这份新工作',
      reflection: '【示例】刚落定，还在适应期，值得过阵子再回看。',
      tags: const [RecordTags.work],
      revealStyle: RevealStyle.coin,
      objective: Decision.doIt,
      response: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 1,
    ),
    _DemoSpec(
      daysAgo: 11,
      context: '【示例】周末要不要去参加婚礼',
      reflection: '【示例】人情和休息之间，最后选了去。',
      tags: const [RecordTags.relationship, RecordTags.life],
      revealStyle: RevealStyle.cards,
      objective: Decision.doIt,
      response: UserResponse.rebel,
      finalDecision: Decision.notIt,
      retryCount: 0,
    ),
    _DemoSpec(
      daysAgo: 24,
      context: '【示例】要不要买新耳机',
      reflection: '【示例】消费冲动的一晚，还好忍住了。',
      tags: const [RecordTags.spending],
      revealStyle: RevealStyle.coin,
      objective: Decision.notIt,
      response: UserResponse.comply,
      finalDecision: Decision.notIt,
      retryCount: 2,
      archivedDaysAgo: 18,
    ),
    _DemoSpec(
      daysAgo: 38,
      context: '【示例】开始跑步计划',
      reflection: '【示例】已归档：坚持了三周，算是个好决定。',
      tags: const [RecordTags.health],
      revealStyle: RevealStyle.cards,
      objective: Decision.doIt,
      response: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 0,
      archivedDaysAgo: 30,
    ),
    _DemoSpec(
      daysAgo: 52,
      context: '【示例】是否换租更大的房子',
      reflection: '【示例】还在纠结通勤和预算，先标记回头再看。',
      tags: const [RecordTags.life, RecordTags.spending],
      revealStyle: RevealStyle.coin,
      objective: Decision.doIt,
      response: UserResponse.retry,
      finalDecision: Decision.doIt,
      retryCount: 3,
    ),
    _DemoSpec(
      daysAgo: 67,
      context: '【示例】项目要不要接',
      reflection: '【示例】已归档：接了，但节奏比预想紧。',
      tags: const [RecordTags.work],
      revealStyle: RevealStyle.cards,
      objective: Decision.notIt,
      response: UserResponse.rebel,
      finalDecision: Decision.doIt,
      retryCount: 1,
      archivedDaysAgo: 58,
    ),
    _DemoSpec(
      daysAgo: 83,
      context: '【示例】过年回谁家',
      reflection: '【示例】家庭议题，当时选了折中方案。',
      tags: const [RecordTags.relationship, RecordTags.life],
      revealStyle: RevealStyle.coin,
      objective: Decision.doIt,
      response: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 4,
    ),
    _DemoSpec(
      daysAgo: 101,
      context: '【示例】是否报瑜伽课',
      reflection: '【示例】已归档：去了几次，整体还不错。',
      tags: const [RecordTags.health],
      revealStyle: RevealStyle.cards,
      objective: Decision.doIt,
      response: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 0,
      archivedDaysAgo: 92,
    ),
    _DemoSpec(
      daysAgo: 118,
      context: '【示例】换手机还是再等等',
      reflection: '【示例】典型消费纠结，最后选择再等等。',
      tags: const [RecordTags.spending, RecordTags.other],
      revealStyle: RevealStyle.coin,
      objective: Decision.notIt,
      response: UserResponse.comply,
      finalDecision: Decision.notIt,
      retryCount: 2,
    ),
    _DemoSpec(
      daysAgo: 136,
      context: '【示例】要不要离职休息一阵',
      reflection: '【示例】已归档：没离，但调整了工作边界。',
      tags: const [RecordTags.work, RecordTags.health],
      revealStyle: RevealStyle.cards,
      objective: Decision.notIt,
      response: UserResponse.rebel,
      finalDecision: Decision.doIt,
      retryCount: 5,
      archivedDaysAgo: 125,
    ),
    _DemoSpec(
      daysAgo: 158,
      context: '【示例】朋友创业要不要入股',
      reflection: '【示例】高风险决定，标记下来以后复盘。',
      tags: const [RecordTags.spending, RecordTags.relationship],
      revealStyle: RevealStyle.coin,
      objective: Decision.doIt,
      response: UserResponse.retry,
      finalDecision: Decision.notIt,
      retryCount: 3,
    ),
    _DemoSpec(
      daysAgo: 179,
      context: '【示例】领养一只猫',
      reflection: '【示例】已归档：领养了，生活快乐指数上升。',
      tags: const [RecordTags.life],
      revealStyle: RevealStyle.cards,
      objective: Decision.doIt,
      response: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 1,
      archivedDaysAgo: 170,
    ),
    _DemoSpec(
      daysAgo: 203,
      context: '【示例】是否去异地出差三个月',
      reflection: '【示例】当时选了去，见识多了也真累。',
      tags: const [RecordTags.work, RecordTags.life],
      revealStyle: RevealStyle.coin,
      objective: Decision.doIt,
      response: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 2,
    ),
    _DemoSpec(
      daysAgo: 228,
      context: '【示例】牙齿矫正要不要开始',
      reflection: '【示例】已归档：开始了，长期工程。',
      tags: const [RecordTags.health],
      revealStyle: RevealStyle.cards,
      objective: Decision.doIt,
      response: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 0,
      archivedDaysAgo: 215,
    ),
    _DemoSpec(
      daysAgo: 256,
      context: '【示例】双11要不要清空购物车',
      reflection: '【示例】最后只买了真正需要的。',
      tags: const [RecordTags.spending],
      revealStyle: RevealStyle.coin,
      objective: Decision.notIt,
      response: UserResponse.rebel,
      finalDecision: Decision.doIt,
      retryCount: 4,
    ),
    _DemoSpec(
      daysAgo: 289,
      context: '【示例】是否和室友续租',
      reflection: '【示例】已归档：续了，相处模式也谈清楚了。',
      tags: const [RecordTags.life],
      revealStyle: RevealStyle.cards,
      objective: Decision.doIt,
      response: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 1,
      archivedDaysAgo: 276,
    ),
    _DemoSpec(
      daysAgo: 318,
      context: '【示例】要不要报在职研究生',
      reflection: '【示例】跨度很长的决定，值得慢慢回看。',
      tags: const [RecordTags.work, RecordTags.other],
      revealStyle: RevealStyle.coin,
      objective: Decision.notIt,
      response: UserResponse.retry,
      finalDecision: Decision.notIt,
      retryCount: 6,
    ),
    _DemoSpec(
      daysAgo: 347,
      context: '【示例】春节旅行去南方还是在家',
      reflection: '【示例】已归档：去了南方，除了冷场都挺好。',
      tags: const [RecordTags.life, RecordTags.relationship],
      revealStyle: RevealStyle.cards,
      objective: Decision.doIt,
      response: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 2,
      archivedDaysAgo: 335,
    ),
    _DemoSpec(
      daysAgo: 376,
      context: '【示例】是否开始学吉他',
      reflection: '【示例】三分钟热度预警，但开局还算顺利。',
      tags: const [RecordTags.other, RecordTags.life],
      revealStyle: RevealStyle.coin,
      objective: Decision.doIt,
      response: UserResponse.rebel,
      finalDecision: Decision.notIt,
      retryCount: 1,
    ),
    _DemoSpec(
      daysAgo: 410,
      context: '【示例】要不要搬去新城市',
      reflection: '【示例】已归档：没搬，但打开了远程工作的可能。',
      tags: const [RecordTags.life, RecordTags.work],
      revealStyle: RevealStyle.cards,
      objective: Decision.notIt,
      response: UserResponse.rebel,
      finalDecision: Decision.doIt,
      retryCount: 0,
      archivedDaysAgo: 398,
    ),
  ];
}
