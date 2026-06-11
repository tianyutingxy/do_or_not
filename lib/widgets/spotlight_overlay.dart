import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 舞台打光：暗角 + 中心聚光灯 + 顶部光束
class SpotlightOverlay extends StatelessWidget {
  const SpotlightOverlay({
    super.key,
    required this.intensity,
    this.center = Alignment.center,
    this.spotRadius = 0.35,
  });

  final double intensity;
  final Alignment center;
  final double spotRadius;

  @override
  Widget build(BuildContext context) {
    final t = intensity.clamp(0.0, 1.0);
    if (t <= 0) return const SizedBox.shrink();

    return IgnorePointer(
      child: CustomPaint(
        painter: _SpotlightPainter(
          intensity: t,
          center: center,
          spotRadius: spotRadius,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.intensity,
    required this.center,
    required this.spotRadius,
  });

  final double intensity;
  final Alignment center;
  final double spotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final focal = center.alongSize(size);
    final maxRadius = math.max(size.width, size.height);

    // 暗角
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: center,
          radius: 0.9,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.55 * intensity),
            Colors.black.withValues(alpha: 0.85 * intensity),
          ],
          stops: const [0.2, 0.65, 1.0],
        ).createShader(Offset.zero & size),
    );

    // 主聚光灯
    final spotRect = Rect.fromCircle(
      center: focal,
      radius: maxRadius * spotRadius,
    );
    final spotPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.55,
        colors: [
          const Color(0xFFFFF8E7).withValues(alpha: 0.55 * intensity),
          const Color(0xFFFFD166).withValues(alpha: 0.18 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(spotRect)
      ..blendMode = BlendMode.screen;
    canvas.drawOval(spotRect, spotPaint);

    // 顶部光束
    final beamPath = Path()
      ..moveTo(focal.dx - maxRadius * 0.12, -size.height * 0.1)
      ..lineTo(focal.dx + maxRadius * 0.12, -size.height * 0.1)
      ..lineTo(focal.dx + maxRadius * spotRadius * 0.9, focal.dy)
      ..lineTo(focal.dx - maxRadius * spotRadius * 0.9, focal.dy)
      ..close();

    canvas.drawPath(
      beamPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF8E7).withValues(alpha: 0.35 * intensity),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, focal.dy + 20))
        ..blendMode = BlendMode.screen,
    );

    // 光晕边缘闪烁
    canvas.drawCircle(
      focal,
      maxRadius * spotRadius * 0.95,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFFFD166).withValues(alpha: 0.25 * intensity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter old) =>
      old.intensity != intensity ||
      old.center != center ||
      old.spotRadius != spotRadius;
}
