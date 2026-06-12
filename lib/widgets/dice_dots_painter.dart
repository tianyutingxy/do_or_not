import 'package:flutter/material.dart';

/// 骰子面点数绘制（1–6）
class DiceDotsPainter extends CustomPainter {
  DiceDotsPainter({required this.value});

  final int value;

  static const _dotColor = Color(0xFF1A1A2E);

  @override
  void paint(Canvas canvas, Size size) {
    final face = value.clamp(1, 6);
    final dotR = size.width * 0.09;
    final paint = Paint()..color = _dotColor;

    for (final cell in _cellsFor(face)) {
      canvas.drawCircle(
        Offset(size.width * cell.dx, size.height * cell.dy),
        dotR,
        paint,
      );
    }
  }

  static List<Offset> _cellsFor(int v) {
    const tl = Offset(0.28, 0.28);
    const tr = Offset(0.72, 0.28);
    const ml = Offset(0.28, 0.50);
    const mc = Offset(0.50, 0.50);
    const mr = Offset(0.72, 0.50);
    const bl = Offset(0.28, 0.72);
    const br = Offset(0.72, 0.72);

    return switch (v) {
      1 => [mc],
      2 => [tl, br],
      3 => [tl, mc, br],
      4 => [tl, tr, bl, br],
      5 => [tl, tr, mc, bl, br],
      6 => [tl, tr, ml, mr, bl, br],
      _ => [mc],
    };
  }

  @override
  bool shouldRepaint(covariant DiceDotsPainter oldDelegate) =>
      oldDelegate.value != value;
}
