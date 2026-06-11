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
    final resultColor =
        decision.isDo ? AppColors.doGreen : AppColors.notRed;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
            child: Column(
              children: [
                if (flavorTitle != null) ...[
                  Text(
                    flavorTitle!,
                    style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 3,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  '命运给出了 ${decision.label}',
                  style: TextStyle(
                    fontSize: 13,
                    letterSpacing: 2,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  decision.label,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    color: resultColor,
                  ),
                ),
                if (detailLine != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    detailLine!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white60,
                    ),
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
