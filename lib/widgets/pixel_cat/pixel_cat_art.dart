import 'package:flutter/material.dart';

/// 程序生成的像素猫精灵（无外部素材）。
/// 字符图例：. 透明 o 橘身 g 高光 d 深橘 w 眼白 p 瞳孔 m 嘴 n 鼻
class PixelCatArt {
  PixelCatArt._();

  static const pixelSize = 3.0;
  static const frameWidth = 20;
  static const frameHeight = 14;

  static const _palette = <String, Color>{
    'o': Color(0xFFF0A030),
    'g': Color(0xFFFFD166),
    'd': Color(0xFFC47A28),
    'w': Color(0xFFF8F8FF),
    'p': Color(0xFF1A1020),
    'm': Color(0xFF5A3018),
    'n': Color(0xFFE88888),
  };

  static const walkFrames = <List<String>>[
  // 0 — 迈步
    [
      '......oooooooo......',
      '....ooooggggooo.....',
      '...oogggggggggoo....',
      '..oogggweewgggoo....',
      '..oogggwpppwggoo....',
      '..oogggwpppwggoo....',
      '..oogggmmnggoo......',
      '...oogggggggoo......',
      '....oogggggoo.......',
      '.....ooddddo........',
      '......od..do........',
      '......od..d.........',
      '......od............',
      '....................',
    ],
    // 1 — 抬腿
    [
      '......oooooooo......',
      '....ooooggggooo.....',
      '...oogggggggggoo....',
      '..oogggweewgggoo....',
      '..oogggwpppwggoo....',
      '..oogggwpppwggoo....',
      '..oogggmmnggoo......',
      '...oogggggggoo......',
      '....oogggggoo.......',
      '.....ooddddo........',
      '.....od...do........',
      '....od....do........',
      '....od..............',
      '....................',
    ],
    // 2 — 中间
    [
      '......oooooooo......',
      '....ooooggggooo.....',
      '...oogggggggggoo....',
      '..oogggweewgggoo....',
      '..oogggwpppwggoo....',
      '..oogggwpppwggoo....',
      '..oogggmmnggoo......',
      '...oogggggggoo......',
      '....oogggggoo.......',
      '.....ooddddo........',
      '......od..do........',
      '......od..do........',
      '......od............',
      '....................',
    ],
    // 3 — 换腿
    [
      '......oooooooo......',
      '....ooooggggooo.....',
      '...oogggggggggoo....',
      '..oogggweewgggoo....',
      '..oogggwpppwggoo....',
      '..oogggwpppwggoo....',
      '..oogggmmnggoo......',
      '...oogggggggoo......',
      '....oogggggoo.......',
      '.....ooddddo........',
      '......do..od........',
      '.......do..od.......',
      '.........do.od......',
      '....................',
    ],
  ];

  static const jumpFrame = <String>[
    '......oooooooooo....',
    '....oooogggggooo....',
    '...ooggggggggggoo...',
    '..oogggwewwewggoo...',
    '..oogggwppppwggoo...',
    '..oogggwppppwggoo...',
    '..oogggmmnnggoo.....',
    '...ooggggggggoo.....',
    '....ooggggggoo......',
    '.....oodddddo.......',
    '......oddddo........',
    '.......oddo.........',
    '........oo..........',
    '....................',
  ];

  static Size get displaySize => Size(
        frameWidth * pixelSize,
        frameHeight * pixelSize,
      );

  static void paintFrame(
    Canvas canvas,
    List<String> frame, {
    required bool facingRight,
    double squashX = 1,
    double squashY = 1,
  }) {
    final w = frameWidth * pixelSize;
    final h = frameHeight * pixelSize;

    canvas.save();
    if (!facingRight) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }
    if (squashX != 1 || squashY != 1) {
      canvas.translate(w / 2, h);
      canvas.scale(squashX, squashY);
      canvas.translate(-w / 2, -h);
    }

    final paint = Paint();
    for (var y = 0; y < frame.length; y++) {
      final row = frame[y];
      for (var x = 0; x < row.length; x++) {
        final ch = row[x];
        if (ch == '.') continue;
        final color = _palette[ch];
        if (color == null) continue;
        paint.color = color;
        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelSize,
            y * pixelSize,
            pixelSize,
            pixelSize,
          ),
          paint,
        );
      }
    }
    canvas.restore();
  }
}

class PixelCatPainter extends CustomPainter {
  PixelCatPainter({
    required this.frame,
    required this.facingRight,
    this.squashX = 1,
    this.squashY = 1,
  });

  final List<String> frame;
  final bool facingRight;
  final double squashX;
  final double squashY;

  @override
  void paint(Canvas canvas, Size size) {
    PixelCatArt.paintFrame(
      canvas,
      frame,
      facingRight: facingRight,
      squashX: squashX,
      squashY: squashY,
    );
  }

  @override
  bool shouldRepaint(covariant PixelCatPainter oldDelegate) {
    return oldDelegate.frame != frame ||
        oldDelegate.facingRight != facingRight ||
        oldDelegate.squashX != squashX ||
        oldDelegate.squashY != squashY;
  }
}
