import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'dice_dots_painter.dart';

/// 六面体 3D 骰子：+Z 前 1、-Z 后 6、+X 右 3、-X 左 4、-Y 上 5、+Y 下 2
class Dice3DWidget extends StatelessWidget {
  const Dice3DWidget({
    super.key,
    this.size = 88,
    required this.rotationX,
    required this.rotationY,
    required this.rotationZ,
    this.highlight = false,
    this.highlightStrength = 1.0,
  });

  final double size;
  final double rotationX;
  final double rotationY;
  final double rotationZ;
  final bool highlight;
  final double highlightStrength;

  @override
  Widget build(BuildContext context) {
    final half = size / 2;
    final glow = highlight ? highlightStrength.clamp(0.0, 1.0) : 0.0;

    final rotation = Matrix4.rotationX(rotationX) *
        Matrix4.rotationY(rotationY) *
        Matrix4.rotationZ(rotationZ);

    return DecoratedBox(
      decoration: glow > 0
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.45 * glow),
                  blurRadius: 24 + 20 * glow,
                  spreadRadius: 2 * glow,
                ),
              ],
            )
          : const BoxDecoration(),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..setEntry(3, 2, 0.0014),
        child: Transform(
          alignment: Alignment.center,
          transform: rotation,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                _faceAt(
                  z: half,
                  child: _DiceFace(value: 1, size: size, glow: glow, shaded: false),
                ),
                _faceAt(
                  z: -half,
                  rotateY: math.pi,
                  child: _DiceFace(value: 6, size: size, glow: glow, shaded: true),
                ),
                _faceAt(
                  x: half,
                  rotateY: math.pi / 2,
                  child: _DiceFace(value: 3, size: size, glow: glow, shaded: true),
                ),
                _faceAt(
                  x: -half,
                  rotateY: -math.pi / 2,
                  child: _DiceFace(value: 4, size: size, glow: glow, shaded: true),
                ),
                _faceAt(
                  y: -half,
                  rotateX: -math.pi / 2,
                  child: _DiceFace(value: 5, size: size, glow: glow, shaded: false),
                ),
                _faceAt(
                  y: half,
                  rotateX: math.pi / 2,
                  child: _DiceFace(value: 2, size: size, glow: glow, shaded: true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 与 [Coin3DWidget] 一致：仅用 double 参数的 translate，避免 Matrix4 类型错误
  Widget _faceAt({
    double x = 0.0,
    double y = 0.0,
    double z = 0.0,
    double rotateX = 0.0,
    double rotateY = 0.0,
    required Widget child,
  }) {
    final matrix = Matrix4.identity();
    if (x != 0.0 || y != 0.0 || z != 0.0) {
      matrix.translate(x, y, z);
    }
    if (rotateX != 0.0) matrix.rotateX(rotateX);
    if (rotateY != 0.0) matrix.rotateY(rotateY);

    return Transform(
      alignment: Alignment.center,
      transform: matrix,
      child: child,
    );
  }
}

/// 让指定点数朝上（-Y），并带轻微俯视倾角便于看到顶面
class Dice3DOrientation {
  const Dice3DOrientation(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;

  static const _viewTilt = 0.32;

  static final Map<int, Dice3DOrientation> _baseTop = {
    1: Dice3DOrientation(-math.pi / 2, 0.0, 0.0),
    2: Dice3DOrientation(math.pi / 2, 0.0, 0.0),
    3: Dice3DOrientation(-math.pi / 2, math.pi / 2, 0.0),
    4: Dice3DOrientation(-math.pi / 2, -math.pi / 2, 0.0),
    5: Dice3DOrientation(0.0, 0.0, 0.0),
    6: Dice3DOrientation(-math.pi / 2, math.pi, 0.0),
  };

  static Dice3DOrientation showingTop(int face) {
    final base = _baseTop[face.clamp(1, 6)] ?? _baseTop[1]!;
    return Dice3DOrientation(base.x - _viewTilt, base.y, base.z);
  }

  Dice3DOrientation blend(Dice3DOrientation other, double t) {
    final u = t.clamp(0.0, 1.0);
    return Dice3DOrientation(
      x + (other.x - x) * u,
      y + (other.y - y) * u,
      z + (other.z - z) * u,
    );
  }

  Dice3DOrientation addSpin(double sx, double sy, double sz) {
    return Dice3DOrientation(x + sx, y + sy, z + sz);
  }
}

class _DiceFace extends StatelessWidget {
  const _DiceFace({
    required this.value,
    required this.size,
    required this.glow,
    required this.shaded,
  });

  final int value;
  final double size;
  final double glow;
  final bool shaded;

  @override
  Widget build(BuildContext context) {
    final faceColor =
        shaded ? const Color(0xFFE4E0D8) : AppColors.cardWhite;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.14),
        color: faceColor,
        border: Border.all(
          color: glow > 0
              ? AppColors.gold.withValues(alpha: 0.5 + 0.4 * glow)
              : const Color(0xFFC8C4BC),
          width: glow > 0 ? 2.0 : 1.0,
        ),
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: DiceDotsPainter(value: value),
      ),
    );
  }
}
