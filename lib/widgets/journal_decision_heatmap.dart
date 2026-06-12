import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';

import '../l10n/decision_record_l10n.dart';
import '../models/decision_record.dart';
import '../theme/app_theme.dart';
import '../utils/decision_heatmap_utils.dart';
import 'decision_tag_widgets.dart';

class JournalDecisionHeatmap extends StatelessWidget {
  const JournalDecisionHeatmap({
    super.key,
    required this.records,
    required this.localeName,
    required this.onRecordTap,
  });

  final List<DecisionRecord> records;
  final String localeName;
  final ValueChanged<DecisionRecord> onRecordTap;

  static const _cellSize = 11.0;
  static const _cellGap = 3.0;

  Color _cellColor(int level) {
    return switch (level) {
      0 => AppColors.surface,
      1 => AppColors.gold.withValues(alpha: 0.28),
      2 => AppColors.gold.withValues(alpha: 0.58),
      _ => AppColors.gold,
    };
  }

  void _openDaySheet(
    BuildContext context,
    DateTime day,
    List<DecisionRecord> dayRecords,
  ) {
    if (dayRecords.isEmpty) return;

    HapticFeedback.selectionClick();
    final l10n = AppLocalizations.of(context);
    final dateLabel = DateFormat.yMMMd(localeName).format(day);

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.journalHeatmapDayTitle(dateLabel, dayRecords.length),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.45,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: dayRecords.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final record = dayRecords[index];
                      return _HeatmapDayRecordTile(
                        record: record,
                        localeName: localeName,
                        l10n: l10n,
                        onTap: () {
                          Navigator.of(context).pop();
                          onRecordTap(record);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final grouped = groupDecisionRecordsByDay(records);
    final columns = buildDecisionHeatmapWeeks();
    final stats = computeDecisionHeatmapStats(records);
    final end = decisionDateOnly(DateTime.now());
    final endWeekStart = decisionStartOfWeek(end);
    final rangeStart = endWeekStart.subtract(
      Duration(days: (decisionHeatmapWeeks - 1) * 7),
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Text(
          l10n.journalHeatmapSummary(
            decisionHeatmapWeeks,
            stats.totalDecisions,
            stats.activeDays,
          ),
          style: const TextStyle(color: Colors.white60, fontSize: 13),
        ),
        if (stats.busiestWeekCount > 0) ...[
          const SizedBox(height: 6),
          Text(
            l10n.journalHeatmapBusiestWeek(stats.busiestWeekCount),
            style: const TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WeekdayLabels(l10n: l10n),
              const SizedBox(width: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var columnIndex = 0;
                      columnIndex < columns.length;
                      columnIndex++) ...[
                    if (columnIndex > 0) SizedBox(width: _cellGap),
                    _HeatmapWeekColumn(
                      column: columns[columnIndex],
                      grouped: grouped,
                      rangeStart: rangeStart,
                      rangeEnd: end,
                      localeName: localeName,
                      cellSize: _cellSize,
                      cellGap: _cellGap,
                      cellColor: _cellColor,
                      onDayTap: (day, dayRecords) =>
                          _openDaySheet(context, day, dayRecords),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              l10n.journalHeatmapLess,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
            const SizedBox(width: 8),
            for (var level = 0; level <= 3; level++) ...[
              if (level > 0) const SizedBox(width: 4),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _cellColor(level),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.white10),
                ),
              ),
            ],
            const SizedBox(width: 8),
            Text(
              l10n.journalHeatmapMore,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final labels = [
      l10n.journalHeatmapMon,
      '',
      l10n.journalHeatmapWed,
      '',
      l10n.journalHeatmapFri,
      '',
      '',
    ];

    return Column(
      children: [
        const SizedBox(height: 18),
        for (final label in labels)
          SizedBox(
            height: JournalDecisionHeatmap._cellSize + JournalDecisionHeatmap._cellGap,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeatmapWeekColumn extends StatelessWidget {
  const _HeatmapWeekColumn({
    required this.column,
    required this.grouped,
    required this.rangeStart,
    required this.rangeEnd,
    required this.localeName,
    required this.cellSize,
    required this.cellGap,
    required this.cellColor,
    required this.onDayTap,
  });

  final DecisionHeatmapWeekColumn column;
  final Map<DateTime, List<DecisionRecord>> grouped;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final String localeName;
  final double cellSize;
  final double cellGap;
  final Color Function(int level) cellColor;
  final void Function(DateTime day, List<DecisionRecord> records) onDayTap;

  @override
  Widget build(BuildContext context) {
    final monthLabel = _shouldShowMonthLabel()
        ? DateFormat.MMM(localeName).format(column.days.first)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 14,
          child: Text(
            monthLabel,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ),
        const SizedBox(height: 4),
        for (final day in column.days) ...[
          _HeatmapCell(
            day: day,
            count: _countForDay(day),
            inRange: !day.isBefore(rangeStart) && !day.isAfter(rangeEnd),
            cellSize: cellSize,
            cellColor: cellColor,
            onTap: () => onDayTap(day, grouped[day] ?? const []),
          ),
          SizedBox(height: cellGap),
        ],
      ],
    );
  }

  bool _shouldShowMonthLabel() {
    final day = column.days.firstWhere(
      (item) => !item.isBefore(rangeStart) && !item.isAfter(rangeEnd),
      orElse: () => column.days.first,
    );
    return day.day <= 7;
  }

  int _countForDay(DateTime day) {
    if (day.isBefore(rangeStart) || day.isAfter(rangeEnd)) return 0;
    return grouped[day]?.length ?? 0;
  }
}

class _HeatmapCell extends StatelessWidget {
  const _HeatmapCell({
    required this.day,
    required this.count,
    required this.inRange,
    required this.cellSize,
    required this.cellColor,
    required this.onTap,
  });

  final DateTime day;
  final int count;
  final bool inRange;
  final double cellSize;
  final Color Function(int level) cellColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = inRange ? decisionHeatmapLevel(count) : 0;
    final color = inRange ? cellColor(level) : AppColors.background;

    return Semantics(
      button: count > 0,
      label: '${day.month}/${day.day}: $count',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: count > 0 ? onTap : null,
          borderRadius: BorderRadius.circular(2),
          child: Ink(
            width: cellSize,
            height: cellSize,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(
                color: count > 0
                    ? AppColors.gold.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeatmapDayRecordTile extends StatelessWidget {
  const _HeatmapDayRecordTile({
    required this.record,
    required this.localeName,
    required this.l10n,
    required this.onTap,
  });

  final DecisionRecord record;
  final String localeName;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.Hm(localeName).format(record.decidedAt),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Text(
                record.summaryLine(l10n),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              RecordTagBadges(tags: record.tags),
            ],
          ),
        ),
      ),
    );
  }
}
