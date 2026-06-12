import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../l10n/decision_record_l10n.dart';
import '../models/decision_record.dart';
import '../services/decision_record_service.dart';
import '../theme/app_theme.dart';
import '../utils/record_list_utils.dart';
import '../screens/journal_detail_screen.dart';
import 'decision_tag_filter_bar.dart';
import 'decision_tag_widgets.dart';
import 'journal_decision_heatmap.dart';
import 'journal_timeline_view.dart';
import 'swipe_delete_record_tile.dart';

/// 决策档案列表面板（仅待回顾项）。
class JournalPanel extends StatefulWidget {
  const JournalPanel({
    super.key,
    required this.service,
    this.onRecordsChanged,
  });

  final DecisionRecordService service;
  final VoidCallback? onRecordsChanged;

  @override
  State<JournalPanel> createState() => JournalPanelState();
}

class JournalPanelState extends State<JournalPanel> {
  List<DecisionRecord> _records = const [];
  bool _loading = true;
  Set<String> _activeTagFilters = {};
  JournalViewMode _viewMode = JournalViewMode.list;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    setState(() => _loading = true);
    final records = await widget.service.listPendingReview();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  List<DecisionRecord> get _filteredRecords =>
      filterRecordsByTags(_records, _activeTagFilters);

  Future<void> _openDetail(DecisionRecord record) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => JournalDetailScreen(
          recordId: record.id!,
          service: widget.service,
        ),
      ),
    );
    if (changed == true) {
      await reload();
      widget.onRecordsChanged?.call();
    }
  }

  Future<void> _deleteRecord(DecisionRecord record) async {
    await widget.service.deleteRecord(record.id!);
    await reload();
    widget.onRecordsChanged?.call();
  }

  Widget _buildTile(DecisionRecord record) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final l10n = AppLocalizations.of(context);

    return SwipeDeleteRecordTile(
      onDeleteConfirmed: () => _deleteRecord(record),
      child: _PendingRecordTile(
        record: record,
        localeName: localeName,
        l10n: l10n,
        onTap: () => _openDetail(record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }

    final filtered = _filteredRecords;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecisionTagFilterBar(
          selectedTagIds: _activeTagFilters,
          onChanged: (next) => setState(() => _activeTagFilters = next),
        ),
        Expanded(
          child: _records.isEmpty
              ? _EmptyState(
                  title: l10n.journalEmpty,
                  hint: l10n.journalEmptyHint,
                )
              : filtered.isEmpty
                  ? _EmptyState(
                      title: l10n.journalFilterEmpty,
                      hint: l10n.journalFilterEmptyHint,
                    )
                  : _viewMode == JournalViewMode.list
                      ? ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _buildTile(filtered[index]),
                        )
                      : JournalDecisionHeatmap(
                          records: filtered,
                          localeName:
                              Localizations.localeOf(context).toLanguageTag(),
                          onRecordTap: _openDetail,
                        ),
        ),
        JournalViewModeBottomBar(
          mode: _viewMode,
          onChanged: (mode) => setState(() => _viewMode = mode),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_outline_rounded, size: 40, color: Colors.white24),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            Text(
              hint,
              style: const TextStyle(color: Colors.white38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PendingRecordTile extends StatelessWidget {
  const _PendingRecordTile({
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
      color: AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (record.isDemoExample) ...[
                      _DemoBadge(label: l10n.journalDemoBadge),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      record.formattedDate(l10n, localeName),
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  record.summaryLine(l10n),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                RecordTagBadges(tags: record.tags),
                if (record.reflection != null && record.reflection!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    record.reflection!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoBadge extends StatelessWidget {
  const _DemoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.gold,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
