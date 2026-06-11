import 'package:flutter/material.dart';

import '../models/decision.dart';
import '../theme/app_theme.dart';

/// 结果展示 — 固定在顶部，避免与牌面 / 按钮重叠
class RevealResultHeader extends StatelessWidget {
  const RevealResultHeader({
    super.key,
    required this.decision,
    required this.opacity,
    this.flavorTitle,
    this.detailLine,
  });

  final Decision decision;
  final double opacity;
  final String? flavorTitle;
  final String? detailLine;

  @override
  Widget build(BuildContext context) {
    final t = opacity.clamp(0.0, 1.0);
    if (t <= 0) return const SizedBox.shrink();

    final resultColor =
        decision.isDo ? AppColors.doGreen : AppColors.notRed;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (flavorTitle != null) ...[
                Text(
                  flavorTitle!,
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold.withValues(alpha: 0.85 * t),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                '命运给出了',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  color: Colors.white.withValues(alpha: 0.45 * t),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                decision.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  color: resultColor.withValues(alpha: t),
                ),
              ),
              if (detailLine != null) ...[
                const SizedBox(height: 4),
                Text(
                  detailLine!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withValues(alpha: 0.6 * t),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
