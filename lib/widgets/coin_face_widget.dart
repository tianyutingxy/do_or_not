import 'package:flutter/material.dart';

import '../models/decision.dart';
import '../theme/app_theme.dart';

class CoinFaceWidget extends StatelessWidget {
  const CoinFaceWidget({
    super.key,
    required this.decision,
    this.diameter = 160,
    this.highlight = false,
  });

  final Decision decision;
  final double diameter;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final isDo = decision.isDo;
    final faceColor = isDo
        ? const Color(0xFFFFD166)
        : const Color(0xFFB8B8C0);
    final rimColor = isDo
        ? const Color(0xFFC9A227)
        : const Color(0xFF6B6B78);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: highlight
                ? AppColors.gold.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.5),
            blurRadius: highlight ? 30 : 16,
            spreadRadius: highlight ? 4 : 0,
          ),
        ],
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 0.9,
          colors: [
            faceColor,
            faceColor.withValues(alpha: 0.85),
            rimColor,
          ],
          stops: const [0.3, 0.7, 1.0],
        ),
        border: Border.all(color: rimColor, width: 3),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 内圈纹理
          Container(
            width: diameter * 0.88,
            height: diameter * 0.88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: rimColor.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                decision.label,
                style: TextStyle(
                  fontSize: diameter * 0.22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: isDo
                      ? const Color(0xFF2D3436)
                      : const Color(0xFF2D3436),
                ),
              ),
              SizedBox(height: diameter * 0.02),
              Text(
                decision.subtitle,
                style: TextStyle(
                  fontSize: diameter * 0.14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D3436).withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          // 高光点
          Positioned(
            top: diameter * 0.12,
            left: diameter * 0.18,
            child: Container(
              width: diameter * 0.18,
              height: diameter * 0.1,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(diameter),
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
