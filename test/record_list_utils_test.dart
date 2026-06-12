import 'package:do_or_not/models/animation_style.dart';
import 'package:do_or_not/models/decision.dart';
import 'package:do_or_not/models/decision_record.dart';
import 'package:do_or_not/models/record_tags.dart';
import 'package:do_or_not/models/user_response.dart';
import 'package:do_or_not/utils/decision_heatmap_utils.dart';
import 'package:do_or_not/utils/record_list_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DecisionRecord recordAt(DateTime decidedAt, {List<String> tags = const []}) {
    return DecisionRecord(
      decidedAt: decidedAt,
      revealStyle: RevealStyle.coin,
      objectiveDecision: Decision.doIt,
      userResponse: UserResponse.comply,
      finalDecision: Decision.doIt,
      retryCount: 0,
      isMarked: true,
      tags: tags,
      createdAt: decidedAt,
    );
  }

  test('filterRecordsByTags returns all when no filters', () {
    final records = [
      recordAt(DateTime(2026, 6, 1), tags: const [RecordTags.work]),
      recordAt(DateTime(2026, 5, 1), tags: const [RecordTags.life]),
    ];

    expect(filterRecordsByTags(records, {}), records);
  });

  test('filterRecordsByTags matches any selected tag', () {
    final work = recordAt(DateTime(2026, 6, 1), tags: const [RecordTags.work]);
    final life = recordAt(DateTime(2026, 5, 1), tags: const [RecordTags.life]);

    final filtered = filterRecordsByTags(
      [work, life],
      {RecordTags.work},
    );

    expect(filtered, [work]);
  });

  test('groupDecisionRecordsByDay groups records on same date', () {
    final day = DateTime(2026, 6, 12, 9);
    final grouped = groupDecisionRecordsByDay([
      recordAt(day),
      recordAt(day.add(const Duration(hours: 5))),
      recordAt(DateTime(2026, 6, 11)),
    ]);

    expect(grouped[DateTime(2026, 6, 12)], hasLength(2));
    expect(grouped[DateTime(2026, 6, 11)], hasLength(1));
  });

  test('decisionHeatmapLevel maps counts to four levels', () {
    expect(decisionHeatmapLevel(0), 0);
    expect(decisionHeatmapLevel(1), 1);
    expect(decisionHeatmapLevel(2), 2);
    expect(decisionHeatmapLevel(5), 3);
  });

  test('buildDecisionHeatmapWeeks returns fixed number of week columns', () {
    final columns = buildDecisionHeatmapWeeks(
      endDate: DateTime(2026, 6, 12),
      weeks: 26,
    );

    expect(columns, hasLength(26));
    expect(columns.first.days, hasLength(7));
  });
}
