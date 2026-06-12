import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../l10n/user_stats_l10n.dart';
import '../models/user_stats.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final doPct = stats.doPercent;
    final notPct = 100 - doPct;
    final complyPct = stats.complyPercent;
    final rebelPct = stats.rebelPercent;
    final avgRetry = stats.avgRetriesBeforeFinal;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.statsTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              stats.personalityLabel(l10n),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 22,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            _SectionTitle(l10n.statsAttitudeSection),
            const SizedBox(height: 12),
            _RatioBar(
              leftPercent: complyPct,
              leftColor: AppColors.doGreen,
              rightColor: AppColors.notRed,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: l10n.choiceComply,
                    subtitle: l10n.choiceComplySubtitle,
                    count: stats.complyCount,
                    percent: complyPct,
                    color: AppColors.doGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: l10n.choiceRebel,
                    subtitle: l10n.choiceRebelSubtitle,
                    count: stats.rebelCount,
                    percent: rebelPct,
                    color: AppColors.notRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _SectionTitle(l10n.statsHesitationSection),
            const SizedBox(height: 12),
            _StatCard(
              label: l10n.choiceRetry,
              subtitle: l10n.choiceRetrySubtitle,
              count: stats.retryPressCount,
              percent: null,
              color: AppColors.gold,
              wide: true,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.25)),
              ),
              child: Column(
                children: [
                  Text(
                    avgRetry.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.statsRetriesPerRound,
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    stats.finalizedCount == 0
                        ? l10n.statsRetriesPending
                        : l10n.statsAvgRetries(avgRetry.toStringAsFixed(1)),
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            _SectionTitle(l10n.statsFinalChoiceSection),
            const SizedBox(height: 12),
            _RatioBar(
              leftPercent: doPct,
              leftColor: AppColors.doGreen,
              rightColor: AppColors.notRed,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'DO',
                    subtitle: l10n.decisionDoSubtitle,
                    count: stats.doCount,
                    percent: doPct,
                    color: AppColors.doGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'NOT',
                    subtitle: l10n.decisionNotSubtitle,
                    count: stats.notCount,
                    percent: notPct,
                    color: AppColors.notRed,
                  ),
                ),
              ],
            ),
            if (stats.finalizedCount > 0) ...[
              const SizedBox(height: 10),
              Text(
                stats.doNotLabel(l10n),
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.statsFinalizedCount(stats.finalizedCount),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.statsLegend,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        letterSpacing: 2,
        fontWeight: FontWeight.w600,
        color: Colors.white38,
      ),
    );
  }
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({
    required this.leftPercent,
    required this.leftColor,
    required this.rightColor,
  });

  final double leftPercent;
  final Color leftColor;
  final Color rightColor;

  @override
  Widget build(BuildContext context) {
    if (leftPercent <= 0 || leftPercent >= 100) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 8,
          child: Container(
            color: leftPercent >= 100 ? leftColor : rightColor,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 8,
        child: Row(
          children: [
            if (leftPercent > 0)
              Expanded(
                flex: leftPercent.round().clamp(1, 100),
                child: Container(color: leftColor),
              ),
            if (leftPercent < 100)
              Expanded(
                flex: (100 - leftPercent).round().clamp(1, 100),
                child: Container(color: rightColor),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.subtitle,
    required this.count,
    required this.percent,
    required this.color,
    this.wide = false,
  });

  final String label;
  final String subtitle;
  final int count;
  final double? percent;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: wide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: wide ? 22 : 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 10),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (percent != null)
            Text(
              '${percent!.toStringAsFixed(0)}%',
              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 13),
            ),
        ],
      ),
    );
  }
}
