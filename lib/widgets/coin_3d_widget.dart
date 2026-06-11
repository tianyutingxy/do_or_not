import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Microsoft Weary Cat（Windows 11 24H2），本地 PNG 强制渲染
const _wearyCatAsset = 'assets/images/weary_cat_microsoft.png';

/// 侧面视角 3D 硬币：正面数字 10，反面猫头浮雕，统一金色
class Coin3DWidget extends StatelessWidget {
  const Coin3DWidget({
    super.key,
    this.diameter = 180,
    required this.rotationX,
    this.highlight = false,
    this.highlightStrength = 1.0,
  });

  final double diameter;
  final double rotationX;
  final bool highlight;
  final double highlightStrength;

  static const _thicknessRatio = 0.11;

  @override
  Widget build(BuildContext context) {
    final thickness = diameter * _thicknessRatio;
    final half = thickness / 2;
    final glow = highlight ? highlightStrength.clamp(0.0, 1.0) : 0.0;

    final cosX = math.cos(rotationX);
    final sinX = math.sin(rotationX).abs();
    final showFront = cosX > 0.12;
    final showBack = cosX < -0.12;
    final showEdge = sinX > 0.28;

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..setEntry(3, 2, 0.0013),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..rotateX(rotationX),
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              if (showFront)
                _faceAt(
                  z: half,
                  child: _CoinObverse10(diameter: diameter, glow: glow),
                ),
              if (showBack)
                _faceAt(
                  z: -half,
                  rotateY: math.pi,
                  child: _CoinReverseCat(diameter: diameter, glow: glow),
                ),
              if (showEdge) _CoinRim(diameter: diameter, thickness: thickness),
            ],
          ),
        ),
      ),
    );
  }

  Widget _faceAt({
    required double z,
    required Widget child,
    double rotateY = 0,
  }) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..translate(0.0, 0.0, z)
        ..rotateY(rotateY),
      child: child,
    );
  }
}

/// 统一金色色板 — 仅用明暗变化表现凹凸
abstract final class _Gold {
  static const highlight = Color(0xFFFFF0C2);
  static const light = Color(0xFFFFE082);
  static const mid = Color(0xFFFFD166);
  static const base = Color(0xFFE6B84A);
  static const shadow = Color(0xFFC9A227);
  static const deep = Color(0xFF9A7B1A);
  static const carved = Color(0xFF7A5E10);

  static RadialGradient faceGradient(Alignment center, double radius) {
    return RadialGradient(
      center: center,
      radius: radius,
      colors: const [highlight, light, mid, base, shadow],
      stops: const [0.0, 0.28, 0.55, 0.8, 1.0],
    );
  }

  static void embossedCircle(
    Canvas canvas,
    Offset center,
    double radius, {
    bool raised = true,
  }) {
    final offset = raised ? Offset(radius * 0.04, radius * 0.05) : Offset.zero;
    canvas.drawCircle(
      center + offset,
      radius,
      Paint()..color = raised ? deep : carved,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: raised
              ? [light, mid, base]
              : [base, shadow, deep],
          stops: const [0.2, 0.6, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    if (raised) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.92),
        -math.pi * 0.75,
        math.pi * 0.45,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.06
          ..color = highlight.withValues(alpha: 0.45),
      );
    }
  }
}

class _CoinObverse10 extends StatelessWidget {
  const _CoinObverse10({required this.diameter, required this.glow});

  final double diameter;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow > 0
                ? AppColors.gold.withValues(alpha: 0.65 * glow)
                : Colors.black.withValues(alpha: 0.5),
            blurRadius: 12 + 14 * glow,
            spreadRadius: 1.5 * glow,
          ),
        ],
        gradient: _Gold.faceGradient(const Alignment(-0.25, -0.3), 1.05),
      ),
      child: CustomPaint(
        size: Size(diameter, diameter),
        painter: _Obverse10Painter(),
      ),
    );
  }
}

class _Obverse10Painter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final c = Offset(d / 2, d / 2);

    // 外圈凸起压边
    canvas.drawCircle(
      c,
      d * 0.48,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = d * 0.05
        ..shader = const SweepGradient(
          colors: [_Gold.shadow, _Gold.highlight, _Gold.deep, _Gold.light, _Gold.shadow],
        ).createShader(Rect.fromCircle(center: c, radius: d * 0.48)),
    );

    // 内场微凹
    _Gold.embossedCircle(canvas, c, d * 0.38, raised: false);

    // 数字 10 — 金色浮雕
    _drawEmbossedText(canvas, c, d, '10', fontSize: d * 0.36);

    // 顶缘高光弧
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: d * 0.44),
      -math.pi * 0.82,
      math.pi * 0.45,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = d * 0.016
        ..color = _Gold.highlight.withValues(alpha: 0.35),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CoinReverseCat extends StatelessWidget {
  const _CoinReverseCat({required this.diameter, required this.glow});

  final double diameter;
  final double glow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glow > 0
                ? AppColors.gold.withValues(alpha: 0.6 * glow)
                : Colors.black.withValues(alpha: 0.5),
            blurRadius: 12 + 12 * glow,
          ),
        ],
        gradient: _Gold.faceGradient(const Alignment(-0.2, -0.28), 1.05),
      ),
      child: CustomPaint(
        size: Size(diameter, diameter),
        painter: _ReverseCatPainter(diameter: diameter),
        child: Center(
          child: _GoldEmbossedCat(size: diameter * 0.5),
        ),
      ),
    );
  }
}

/// 保留原图眼/嘴惊恐细节，色彩矩阵转金色 + 偏移阴影浮雕
class _GoldEmbossedCat extends StatelessWidget {
  const _GoldEmbossedCat({required this.size});

  final double size;

  /// 暖金色调，保留明暗对比（眼、嘴轮廓仍在）
  static const _goldTone = ColorFilter.matrix([
    0.52, 0.42, 0.06, 0, 38,
    0.40, 0.34, 0.05, 0, 28,
    0.10, 0.08, 0.02, 0, 6,
    0, 0, 0, 1, 0,
  ]);

  static const _shadowTone = ColorFilter.matrix([
    0.28, 0.22, 0.04, 0, 8,
    0.22, 0.18, 0.03, 0, 6,
    0.06, 0.05, 0.01, 0, 2,
    0, 0, 0, 0.85, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final shadow = Offset(size * 0.022, size * 0.028);

    return Transform.rotate(
      angle: math.pi,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Transform.translate(
              offset: shadow,
              child: _tintedCat(_shadowTone),
            ),
            _tintedCat(_goldTone),
          ],
        ),
      ),
    );
  }

  Widget _tintedCat(ColorFilter filter) {
    return ColorFiltered(
      colorFilter: filter,
      child: Image.asset(
        _wearyCatAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

class _ReverseCatPainter extends CustomPainter {
  _ReverseCatPainter({required this.diameter});

  final double diameter;

  @override
  void paint(Canvas canvas, Size size) {
    final d = size.width;
    final c = Offset(d / 2, d / 2);

    canvas.drawCircle(
      c,
      d * 0.48,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = d * 0.05
        ..shader = const SweepGradient(
          colors: [_Gold.shadow, _Gold.highlight, _Gold.deep, _Gold.light, _Gold.shadow],
        ).createShader(Rect.fromCircle(center: c, radius: d * 0.48)),
    );

    _Gold.embossedCircle(canvas, c, d * 0.34, raised: true);
  }

  @override
  bool shouldRepaint(covariant _ReverseCatPainter oldDelegate) =>
      oldDelegate.diameter != diameter;
}

void _drawEmbossedText(
  Canvas canvas,
  Offset center,
  double d,
  String text, {
  required double fontSize,
}) {
  final shadowPainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1,
        color: _Gold.deep,
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();

  final offset = Offset(
    center.dx - shadowPainter.width / 2,
    center.dy - shadowPainter.height / 2 + d * 0.02,
  );
  shadowPainter.paint(canvas, offset + Offset(d * 0.014, d * 0.016));

  final facePainter = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        height: 1,
        foreground: Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_Gold.highlight, _Gold.mid, _Gold.shadow],
            stops: [0.0, 0.45, 1.0],
          ).createShader(Rect.fromLTWH(0, offset.dy, shadowPainter.width, fontSize)),
      ),
    ),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
  )..layout();
  facePainter.paint(canvas, offset);
}

class _CoinRim extends StatelessWidget {
  const _CoinRim({required this.diameter, required this.thickness});

  final double diameter;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(math.pi / 2),
      child: CustomPaint(
        size: Size(thickness, diameter * 0.98),
        painter: _ReededEdgePainter(),
      ),
    );
  }
}

class _ReededEdgePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _Gold.highlight,
            _Gold.mid,
            _Gold.deep,
            _Gold.mid,
            _Gold.highlight,
          ],
        ).createShader(rect),
    );

    final groove = Paint()
      ..color = _Gold.carved.withValues(alpha: 0.5)
      ..strokeWidth = 0.8;
    final step = size.width / 5;
    for (var x = step; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), groove);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
