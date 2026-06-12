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
import '../widgets/journal_photo_slots.dart';

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
  final _contextController = TextEditingController();
  final _reflectionController = TextEditingController();
  DecisionRecord? _record;
  bool _loading = true;
  bool _saving = false;
  bool _archiving = false;
  bool _pickingPhoto = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contextController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final record = await _service.findById(widget.recordId);
    if (!mounted) return;
    setState(() {
      _record = record;
      _loading = false;
      _contextController.text = record?.decisionContext ?? '';
      _reflectionController.text = record?.reflection ?? '';
    });
  }

  Future<void> _pickPhoto(int slotIndex) async {
    final record = _record;
    if (record?.id == null || _pickingPhoto) return;

    setState(() => _pickingPhoto = true);
    try {
      final paths = await _service.pickPhotoForSlot(
        recordId: record!.id!,
        slotIndex: slotIndex,
        currentPaths: record.photoPaths,
      );
      if (paths != null && mounted) {
        setState(() {
          _record = record.copyWith(photoPaths: paths);
          _changed = true;
        });
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).journalPhotoPickError)),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _saveNotes() async {
    final record = _record;
    if (record?.id == null || _saving) return;

    setState(() => _saving = true);
    await _service.saveNotes(
      id: record!.id!,
      decisionContext: _contextController.text,
      reflection: _reflectionController.text,
    );
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
    if (record?.id == null || record!.isArchived) return;

    HapticFeedback.selectionClick();
    await _service.setMarked(record.id!, false);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<bool> _confirmArchive(AppLocalizations l10n) async {
    final first = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.journalArchiveConfirmTitle),
        content: Text(l10n.journalArchiveConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.journalCompleteReview),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return false;

    final second = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.journalArchiveConfirmAgainTitle),
        content: Text(l10n.journalArchiveConfirmAgainBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.journalArchiveTitle),
          ),
        ],
      ),
    );
    return second == true;
  }

  Future<void> _completeReviewAndArchive() async {
    final record = _record;
    if (record?.id == null || record!.isArchived || _archiving) return;

    final reflection = _reflectionController.text.trim();
    if (reflection.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).journalReflectionRequired)),
      );
      return;
    }

    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirmArchive(l10n);
    if (!confirmed || !mounted) return;

    setState(() => _archiving = true);
    await _service.saveNotes(
      id: record.id!,
      decisionContext: _contextController.text,
      reflection: reflection,
    );
    await _service.archiveWithReflection(record.id!, reflection);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.journalArchiveSuccess)),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.journalDetailTitle),
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
          title: Text(l10n.journalDetailTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: const Center(child: Text('Record not found')),
      );
    }

    final isArchived = record.isArchived;
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
          title: Text(l10n.journalDetailTitle),
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            if (!isArchived)
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
              if (isArchived) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.inventory_2_outlined,
                          size: 18, color: Colors.white54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.journalArchivedHint,
                          style: const TextStyle(color: Colors.white54, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  Icon(
                    isArchived ? Icons.inventory_2_outlined : Icons.star_rounded,
                    color: isArchived ? Colors.white54 : AppColors.gold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.formattedDate(l10n, localeName),
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  if (isArchived) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        l10n.journalArchivedBadge,
                        style: const TextStyle(fontSize: 11, color: Colors.white54),
                      ),
                    ),
                  ],
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
                l10n.journalContextLabel,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contextController,
                minLines: 2,
                maxLines: 4,
                decoration: _noteFieldDecoration(l10n.journalContextPlaceholder),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.journalPhotosLabel,
                style: const TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                ),
              ),
              const SizedBox(height: 12),
              JournalPhotoSlots(
                photoPaths: record.photoPaths,
                onPickSlot: _pickingPhoto ? (_) {} : _pickPhoto,
              ),
              const SizedBox(height: 24),
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
                decoration: _noteFieldDecoration(l10n.reflectionPlaceholder),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _saveNotes,
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
                    : Text(l10n.journalSave),
              ),
              if (!isArchived) ...[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _archiving ? null : _completeReviewAndArchive,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gold,
                    side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _archiving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.journalCompleteReview),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _noteFieldDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
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
  );
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
