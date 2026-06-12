import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// 程序生成的像素猫爪印：四趾弧形 + 下方掌垫，单色剪影。
class PixelPawPainter extends CustomPainter {
  PixelPawPainter({required this.opacity});

  final double opacity;

  static const _fill = AppColors.gold;

  static const _width = 24;
  static const _grid = <String>[
    '........................',
    '.......xxx....xxx.......',
    '.......xxx....xxx.......',
    '..xxxx.xxx....xxx.xxxx..',
    '..xxxx.xxx....xxx.xxxx..',
    '..xxxx.xxx....xxx.xxxx..',
    '..xxxx............xxxx..',
    '........................',
    '........................',
    '........................',
    '........................',
    '........................',
    '.........xxxxxx.........',
    '.......xxxxxxxxxx.......',
    '......xxxxxxxxxxxx......',
    '.....xxxxxxxxxxxxxx.....',
    '.....xxxxxxxxxxxxxx.....',
    '.....xxxxxxxxxxxxxx.....',
    '.....xxxxxxxxxxxxxx.....',
    '......xxxxxxxxxxxx......',
    '.......xxxxxxxxxx.......',
    '.........xxxxxx.........',
    '........................',
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const pixel = 3.0;
    final paint = Paint()..color = _fill.withValues(alpha: opacity);
    final ox = (size.width - _width * pixel) / 2;
    final oy = (size.height - _grid.length * pixel) / 2;

    for (var y = 0; y < _grid.length; y++) {
      final row = _grid[y];
      for (var x = 0; x < row.length; x++) {
        if (row[x] != 'x') continue;
        canvas.drawRect(
          Rect.fromLTWH(ox + x * pixel, oy + y * pixel, pixel, pixel),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PixelPawPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}

/// 猫爪从上方拍下：落下 → 压扁卡片 → 短暂停留。
class PixelPawSlapOverlay extends StatefulWidget {
  const PixelPawSlapOverlay({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<PixelPawSlapOverlay> createState() => _PixelPawSlapOverlayState();
}

class _PixelPawSlapOverlayState extends State<PixelPawSlapOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _impactHapticSent = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        widget.onComplete();
      }
    });
    _controller.addListener(_onTick);
  }

  void _onTick() {
    if (_impactHapticSent) return;
    if (_controller.value >= 0.38) {
      _impactHapticSent = true;
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        final drop = t < 0.42
            ? Curves.easeIn.transform(t / 0.42)
            : 1.0;
        final pawY = -24 * (1 - drop);
        final opacity = t < 0.08 ? t / 0.08 : 1.0;

        final flash = t > 0.36 && t < 0.50
            ? (1 - ((t - 0.36) / 0.14).abs()) * 0.25
            : 0.0;

        return Stack(
          clipBehavior: Clip.none,
          fit: StackFit.expand,
          children: [
            if (flash > 0)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: AppColors.gold.withValues(alpha: flash),
                  ),
                ),
              ),
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, pawY),
                child: Center(
                  child: CustomPaint(
                    size: const Size(72, 69),
                    painter: PixelPawPainter(opacity: opacity),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
