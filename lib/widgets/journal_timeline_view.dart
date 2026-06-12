import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../theme/app_theme.dart';

enum JournalViewMode { list, heatmap }

class JournalViewModeToggle extends StatelessWidget {
  const JournalViewModeToggle({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final JournalViewMode mode;
  final ValueChanged<JournalViewMode> onChanged;

  Color _segmentColor(JournalViewMode value) {
    return mode == value ? Colors.black : Colors.white70;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SegmentedButton<JournalViewMode>(
      segments: [
        ButtonSegment(
          value: JournalViewMode.list,
          label: Text(l10n.journalViewList),
          icon: Icon(
            Icons.view_list_outlined,
            size: 16,
            color: _segmentColor(JournalViewMode.list),
          ),
        ),
        ButtonSegment(
          value: JournalViewMode.heatmap,
          label: Text(l10n.journalViewHeatmap),
          icon: Icon(
            Icons.apps_rounded,
            size: 16,
            color: _segmentColor(JournalViewMode.heatmap),
          ),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        iconColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.black
              : Colors.white70,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.black
              : Colors.white70,
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.surface,
        ),
      ),
    );
  }
}

class JournalViewModeBottomBar extends StatelessWidget {
  const JournalViewModeBottomBar({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final JournalViewMode mode;
  final ValueChanged<JournalViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: JournalViewModeToggle(mode: mode, onChanged: onChanged),
      ),
    );
  }
}
