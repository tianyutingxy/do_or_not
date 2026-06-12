import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../l10n/decision_record_l10n.dart';
import '../models/decision_record.dart';
import '../services/decision_record_service.dart';
import '../theme/app_theme.dart';
import '../utils/record_list_utils.dart';
import '../widgets/decision_tag_filter_bar.dart';
import '../widgets/decision_tag_widgets.dart';
import '../widgets/journal_decision_heatmap.dart';
import '../widgets/journal_timeline_view.dart';
import '../widgets/swipe_delete_record_tile.dart';
import 'journal_detail_screen.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key, DecisionRecordService? service})
      : _service = service;

  final DecisionRecordService? _service;

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  late final DecisionRecordService _service =
      widget._service ?? DecisionRecordService();
  List<DecisionRecord> _records = const [];
  bool _loading = true;
  Set<String> _activeTagFilters = {};
  JournalViewMode _viewMode = JournalViewMode.list;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final records = await _service.listArchived();
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
          service: _service,
        ),
      ),
    );
    if (changed == true) await _load();
  }

  Future<void> _deleteRecord(DecisionRecord record) async {
    await _service.deleteRecord(record.id!);
    await _load();
  }

  Widget _buildTile(DecisionRecord record) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final l10n = AppLocalizations.of(context);

    return SwipeDeleteRecordTile(
      onDeleteConfirmed: () => _deleteRecord(record),
      child: _ArchiveTile(
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
    final filtered = _filteredRecords;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.journalArchiveTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecisionTagFilterBar(
                  selectedTagIds: _activeTagFilters,
                  onChanged: (next) => setState(() => _activeTagFilters = next),
                ),
                Expanded(
                  child: _records.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.inventory_2_outlined,
                                    size: 48, color: Colors.white24),
                                const SizedBox(height: 16),
                                Text(l10n.journalArchiveEmpty,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.journalArchiveEmptyHint,
                                  style: const TextStyle(
                                    color: Colors.white38,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : filtered.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.filter_alt_off_outlined,
                                        size: 40, color: Colors.white24),
                                    const SizedBox(height: 12),
                                    Text(l10n.journalFilterEmpty,
                                        textAlign: TextAlign.center),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.journalFilterEmptyHint,
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 13,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _viewMode == JournalViewMode.list
                              ? ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 16),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 10),
                                  itemBuilder: (context, index) =>
                                      _buildTile(filtered[index]),
                                )
                              : JournalDecisionHeatmap(
                                  records: filtered,
                                  localeName: Localizations.localeOf(context)
                                      .toLanguageTag(),
                                  onRecordTap: _openDetail,
                                ),
                ),
                JournalViewModeBottomBar(
                  mode: _viewMode,
                  onChanged: (mode) => setState(() => _viewMode = mode),
                ),
              ],
            ),
    );
  }
}

class _ArchiveTile extends StatelessWidget {
  const _ArchiveTile({
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
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.journalArchivedBadge,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    if (record.isDemoExample) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          l10n.journalDemoBadge,
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.gold,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      record.formattedDate(l10n, localeName),
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  record.summaryLine(l10n),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                RecordTagBadges(tags: record.tags),
                if (record.reflection != null && record.reflection!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    record.reflection!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
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
