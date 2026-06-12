import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// 猫爪从上方拍下，落在选项卡片右下角。
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

  static const _pawEmoji = '🐾';
  static const _pawSize = 56.0;
  static const _slant = -0.42;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
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
    if (_controller.value >= 0.36) {
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
        final drop = t < 0.40
            ? Curves.easeIn.transform(t / 0.40)
            : 1.0;
        final pawY = -28 * (1 - drop);
        final opacity = t < 0.08 ? t / 0.08 : 1.0;

        final flash = t > 0.34 && t < 0.48
            ? (1 - ((t - 0.34) / 0.14).abs()) * 0.18
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
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 0),
                child: Transform.translate(
                  offset: Offset(2, pawY),
                  child: Transform.rotate(
                    angle: _slant,
                    child: Opacity(
                      opacity: opacity,
                      child: ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            AppColors.gold,
                            AppColors.gold,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          _pawEmoji,
                          style: const TextStyle(
                            fontSize: _pawSize,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
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
