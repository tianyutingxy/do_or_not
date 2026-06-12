import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// 首页顶部灯头：无记录时微光，有记录时亮光；点击进入决策档案。
class JournalLampButton extends StatelessWidget {
  const JournalLampButton({
    super.key,
    required this.isBright,
    this.onTap,
    this.enabled = true,
    this.tooltip,
  });

  final bool isBright;
  final VoidCallback? onTap;
  final bool enabled;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final glowAlpha = isBright ? 0.45 : 0.1;
    final glowBlur = isBright ? 22.0 : 10.0;
    final glowSpread = isBright ? 6.0 : 1.0;
    final outerGlowAlpha = isBright ? 0.18 : 0.05;

    return Semantics(
      button: true,
      label: tooltip,
      child: IconButton(
        onPressed: enabled && onTap != null
            ? () {
                HapticFeedback.selectionClick();
                onTap!();
              }
            : null,
        tooltip: tooltip,
        icon: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: isBright ? 34 : 24,
                height: isBright ? 34 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: glowAlpha),
                      blurRadius: glowBlur,
                      spreadRadius: glowSpread,
                    ),
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: outerGlowAlpha),
                      blurRadius: isBright ? 36 : 16,
                      spreadRadius: isBright ? 10 : 2,
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(28, 28),
                painter: _LampHeadPainter(isBright: isBright),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LampHeadPainter extends CustomPainter {
  _LampHeadPainter({required this.isBright});

  final bool isBright;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = RRect.fromRectAndRadius(
      Rect.fromLTWH(4, 6, 20, 16),
      const Radius.circular(5),
    );

    canvas.drawRRect(
      shade,
      Paint()
        ..color = isBright ? AppColors.gold : const Color(0xFF3A3540),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(7, 9, 14, 11),
        const Radius.circular(3),
      ),
      Paint()
        ..color = isBright
            ? const Color(0xFFFFF2CC)
            : AppColors.gold.withValues(alpha: 0.28),
    );

    canvas.drawRect(
      Rect.fromLTWH(9, 4, 10, 3),
      Paint()..color = isBright ? const Color(0xFF4A4030) : const Color(0xFF2A2830),
    );
  }

  @override
  bool shouldRepaint(covariant _LampHeadPainter oldDelegate) {
    return oldDelegate.isBright != isBright;
  }
}
