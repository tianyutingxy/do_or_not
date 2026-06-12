import '../models/decision_record.dart';

const decisionHeatmapWeeks = 26;

DateTime decisionDateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime decisionStartOfWeek(DateTime date) {
  final day = decisionDateOnly(date);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

Map<DateTime, List<DecisionRecord>> groupDecisionRecordsByDay(
  List<DecisionRecord> records,
) {
  final grouped = <DateTime, List<DecisionRecord>>{};
  for (final record in records) {
    final day = decisionDateOnly(record.decidedAt);
    grouped.putIfAbsent(day, () => []).add(record);
  }
  for (final entry in grouped.entries) {
    entry.value.sort((a, b) => b.decidedAt.compareTo(a.decidedAt));
  }
  return grouped;
}

int decisionHeatmapLevel(int count) {
  if (count <= 0) return 0;
  if (count == 1) return 1;
  if (count == 2) return 2;
  return 3;
}

class DecisionHeatmapWeekColumn {
  const DecisionHeatmapWeekColumn({required this.days});

  final List<DateTime> days;
}

List<DecisionHeatmapWeekColumn> buildDecisionHeatmapWeeks({
  DateTime? endDate,
  int weeks = decisionHeatmapWeeks,
}) {
  final end = decisionDateOnly(endDate ?? DateTime.now());
  final endWeekStart = decisionStartOfWeek(end);
  final gridStart = endWeekStart.subtract(Duration(days: (weeks - 1) * 7));

  final columns = <DecisionHeatmapWeekColumn>[];
  var weekStart = gridStart;
  for (var i = 0; i < weeks; i++) {
    final weekDays = List.generate(
      7,
      (index) => weekStart.add(Duration(days: index)),
    );
    columns.add(DecisionHeatmapWeekColumn(days: weekDays));
    weekStart = weekStart.add(const Duration(days: 7));
  }
  return columns;
}

class DecisionHeatmapStats {
  const DecisionHeatmapStats({
    required this.totalDecisions,
    required this.activeDays,
    required this.busiestWeekCount,
  });

  final int totalDecisions;
  final int activeDays;
  final int busiestWeekCount;
}

DecisionHeatmapStats computeDecisionHeatmapStats(
  List<DecisionRecord> records, {
  DateTime? endDate,
  int weeks = decisionHeatmapWeeks,
}) {
  final end = decisionDateOnly(endDate ?? DateTime.now());
  final endWeekStart = decisionStartOfWeek(end);
  final rangeStart = endWeekStart.subtract(Duration(days: (weeks - 1) * 7));
  final grouped = groupDecisionRecordsByDay(records);

  var total = 0;
  var activeDays = 0;
  for (final entry in grouped.entries) {
    if (entry.key.isBefore(rangeStart) || entry.key.isAfter(end)) continue;
    total += entry.value.length;
    if (entry.value.isNotEmpty) activeDays++;
  }

  final columns = buildDecisionHeatmapWeeks(endDate: end, weeks: weeks);
  var busiestWeek = 0;
  for (final column in columns) {
    var weekCount = 0;
    for (final day in column.days) {
      if (day.isBefore(rangeStart) || day.isAfter(end)) continue;
      weekCount += grouped[day]?.length ?? 0;
    }
    if (weekCount > busiestWeek) busiestWeek = weekCount;
  }

  return DecisionHeatmapStats(
    totalDecisions: total,
    activeDays: activeDays,
    busiestWeekCount: busiestWeek,
  );
}
