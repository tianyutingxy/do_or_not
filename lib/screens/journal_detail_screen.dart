import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../l10n/decision_record_l10n.dart';
import '../l10n/reveal_style_l10n.dart';
import '../models/decision.dart';
import '../models/decision_record.dart';
import '../models/user_response.dart';
import '../services/decision_record_service.dart';
import '../theme/app_theme.dart';

class JournalDetailScreen extends StatefulWidget {
  const JournalDetailScreen({
    super.key,
    required this.recordId,
    DecisionRecordService? service,
  }) : _service = service;

  final int recordId;
  final DecisionRecordService? _service;

  @override
  State<JournalDetailScreen> createState() => _JournalDetailScreenState();
}

class _JournalDetailScreenState extends State<JournalDetailScreen> {
  late final DecisionRecordService _service =
      widget._service ?? DecisionRecordService();
  final _reflectionController = TextEditingController();
  DecisionRecord? _record;
  bool _loading = true;
  bool _saving = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final record = await _service.findById(widget.recordId);
    if (!mounted) return;
    setState(() {
      _record = record;
      _loading = false;
      _reflectionController.text = record?.reflection ?? '';
    });
  }

  Future<void> _saveReflection() async {
    final record = _record;
    if (record?.id == null || _saving) return;

    setState(() => _saving = true);
    final text = _reflectionController.text.trim();
    await _service.saveReflection(record!.id!, text.isEmpty ? null : text);
    if (!mounted) return;

    final updated = await _service.findById(record.id!);
    setState(() {
      _record = updated;
      _saving = false;
      _changed = true;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).reflectionSaved)),
    );
  }

  Future<void> _toggleMark() async {
    final record = _record;
    if (record?.id == null) return;

    HapticFeedback.selectionClick();
    await _service.setMarked(record!.id!, false);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.journalTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    final record = _record;
    if (record == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.journalTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Record not found')),
      );
    }

    final localeName = Localizations.localeOf(context).toLanguageTag();
    final responseColor = record.userResponse == UserResponse.comply
        ? AppColors.doGreen
        : AppColors.notRed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(l10n.journalTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _toggleMark,
            child: Text(l10n.unmarkDecision),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  record.formattedDate(l10n, localeName),
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SnapshotCard(
              label: l10n.journalFateLabel,
              value: record.objectiveDecision.label,
              color: record.objectiveDecision.isDo
                  ? AppColors.doGreen
                  : AppColors.notRed,
            ),
            const SizedBox(height: 10),
            _SnapshotCard(
              label: l10n.journalResponseLabel,
              value: record.userResponse.label(l10n),
              color: responseColor,
            ),
            const SizedBox(height: 10),
            _SnapshotCard(
              label: l10n.journalFinalLabel,
              value: record.finalDecision.label,
              color: record.finalDecision.isDo
                  ? AppColors.doGreen
                  : AppColors.notRed,
            ),
            const SizedBox(height: 10),
            _SnapshotCard(
              label: l10n.journalStyleLabel,
              value: record.revealStyle.title(l10n),
              color: AppColors.gold,
            ),
            const SizedBox(height: 10),
            _SnapshotCard(
              label: l10n.journalRetriesLabel,
              value: '${record.retryCount}',
              color: AppColors.gold,
            ),
            const SizedBox(height: 28),
            Text(
              l10n.journalReflectionLabel,
              style: const TextStyle(
                fontSize: 13,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
                color: Colors.white38,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reflectionController,
              minLines: 5,
              maxLines: 10,
              decoration: InputDecoration(
                hintText: l10n.reflectionPlaceholder,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Colors.white12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: AppColors.gold.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _saveReflection,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.journalSaveReflection),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _SnapshotCard extends StatelessWidget {
  const _SnapshotCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
