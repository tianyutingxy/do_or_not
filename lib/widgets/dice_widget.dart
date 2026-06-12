import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dice_dots_painter.dart';

/// 平面骰子面（预览用）；揭晓动画请用 [Dice3DWidget]
class DiceWidget extends StatelessWidget {
  const DiceWidget({
    super.key,
    required this.value,
    this.size = 88,
    this.highlight = false,
    this.highlightStrength = 1.0,
    this.opacity = 1.0,
  });

  final int value;
  final double size;
  final bool highlight;
  final double highlightStrength;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final t = opacity.clamp(0.0, 1.0);
    final glow = highlight ? highlightStrength.clamp(0.0, 1.0) : 0.0;

    return Opacity(
      opacity: t,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: AppColors.cardWhite,
          border: Border.all(
            color: glow > 0
                ? AppColors.gold.withValues(alpha: 0.5 + 0.5 * glow)
                : Colors.white.withValues(alpha: 0.15),
            width: glow > 0 ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: glow > 0
                  ? AppColors.gold.withValues(alpha: 0.55 * glow)
                  : Colors.black.withValues(alpha: 0.45),
              blurRadius: 12 + 14 * glow,
              spreadRadius: 1 + 2 * glow,
            ),
          ],
        ),
        child: CustomPaint(
          painter: DiceDotsPainter(value: value),
        ),
      ),
    );
  }
}
