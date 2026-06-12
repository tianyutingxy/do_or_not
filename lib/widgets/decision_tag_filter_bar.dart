import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../l10n/record_tag_l10n.dart';
import '../models/record_tags.dart';
import '../theme/app_theme.dart';

class DecisionTagFilterBar extends StatelessWidget {
  const DecisionTagFilterBar({
    super.key,
    required this.selectedTagIds,
    required this.onChanged,
  });

  final Set<String> selectedTagIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          _FilterChip(
            label: l10n.journalFilterAll,
            selected: selectedTagIds.isEmpty,
            onTap: () => onChanged({}),
          ),
          for (final tagId in RecordTags.presets) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: tagId.tagLabel(l10n),
              selected: selectedTagIds.contains(tagId),
              onTap: () {
                final next = Set<String>.from(selectedTagIds);
                if (next.contains(tagId)) {
                  next.remove(tagId);
                } else {
                  next.add(tagId);
                }
                onChanged(next);
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.gold.withValues(alpha: 0.22),
      checkmarkColor: AppColors.gold,
      labelStyle: TextStyle(
        color: selected ? AppColors.gold : Colors.white70,
        fontSize: 13,
      ),
      side: BorderSide(
        color: selected ? AppColors.gold.withValues(alpha: 0.55) : Colors.white24,
      ),
      backgroundColor: AppColors.surface,
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
