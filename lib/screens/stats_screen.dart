import 'package:flutter/material.dart';

import '../models/user_stats.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key, required this.stats});

  final UserStats stats;

  @override
  Widget build(BuildContext context) {
    final doPct = stats.doPercent;
    final notPct = 100 - doPct;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的统计'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              stats.personalityLabel,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _RatioBar(doPercent: doPct),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'DO',
                    subtitle: '做',
                    count: stats.doCount,
                    percent: doPct,
                    color: AppColors.doGreen,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    label: 'NOT',
                    subtitle: '不做',
                    count: stats.notCount,
                    percent: notPct,
                    color: AppColors.notRed,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              '共决定 ${stats.total} 次',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            Text(
              stats.total == 0
                  ? '每次抉择都会被记录\n看看你是 DO 派还是 NOT 派'
                  : doPct >= 50
                      ? '你更倾向于行动 (${doPct.toStringAsFixed(0)}% DO)'
                      : '你更倾向于观望 (${notPct.toStringAsFixed(0)}% NOT)',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _RatioBar extends StatelessWidget {
  const _RatioBar({required this.doPercent});

  final double doPercent;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: 24,
        child: Row(
          children: [
            if (doPercent > 0)
              Expanded(
                flex: doPercent.round().clamp(1, 100),
                child: Container(color: AppColors.doGreen),
              ),
            if (doPercent < 100)
              Expanded(
                flex: (100 - doPercent).round().clamp(1, 100),
                child: Container(color: AppColors.notRed),
              ),
            if (doPercent == 0 || doPercent == 100)
              Expanded(
                child: Container(
                  color: doPercent == 100
                      ? AppColors.doGreen
                      : AppColors.notRed,
                ),
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
  });

  final String label;
  final String subtitle;
  final int count;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: color,
            ),
          ),
          Text(subtitle, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 12),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '${percent.toStringAsFixed(0)}%',
            style: TextStyle(color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }
}
