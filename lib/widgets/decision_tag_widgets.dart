import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../l10n/record_tag_l10n.dart';
import '../models/record_tags.dart';
import '../theme/app_theme.dart';

class DecisionTagSelector extends StatelessWidget {
  const DecisionTagSelector({
    super.key,
    required this.selectedTagIds,
    required this.onChanged,
  });

  final List<String> selectedTagIds;
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selected = Set<String>.from(selectedTagIds);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tagId in RecordTags.presets)
              FilterChip(
                label: Text(tagId.tagLabel(l10n)),
                selected: selected.contains(tagId),
                onSelected: (isSelected) {
                  final next = List<String>.from(selectedTagIds);
                  if (isSelected) {
                    if (next.length >= RecordTags.maxCount) return;
                    if (!next.contains(tagId)) next.add(tagId);
                  } else {
                    next.remove(tagId);
                  }
                  onChanged(RecordTags.normalize(next));
                },
                selectedColor: AppColors.gold.withValues(alpha: 0.22),
                checkmarkColor: AppColors.gold,
                labelStyle: TextStyle(
                  color: selected.contains(tagId) ? AppColors.gold : Colors.white70,
                  fontSize: 13,
                ),
                side: BorderSide(
                  color: selected.contains(tagId)
                      ? AppColors.gold.withValues(alpha: 0.55)
                      : Colors.white24,
                ),
                backgroundColor: AppColors.surface,
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.journalTagsHint,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
  }
}

class RecordTagBadges extends StatelessWidget {
  const RecordTagBadges({
    super.key,
    required this.tags,
  });

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tagId in tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.28)),
              ),
              child: Text(
                tagId.tagLabel(l10n),
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
