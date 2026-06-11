import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/decision.dart';
import '../theme/app_theme.dart';
import 'coin_face_widget.dart';
import 'reveal_back_button.dart';
import 'spotlight_overlay.dart';

class CoinRevealAnimation extends StatefulWidget {
  const CoinRevealAnimation({
    super.key,
    required this.decision,
    required this.onRevealed,
    required this.onDismiss,
  });

  final Decision decision;
  final void Function(Decision decision) onRevealed;
  final VoidCallback onDismiss;

  @override
  State<CoinRevealAnimation> createState() => _CoinRevealAnimationState();
}

class _CoinRevealAnimationState extends State<CoinRevealAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _flipController;
  late final AnimationController _spotlightController;
  late final AnimationController _resultController;

  late final Animation<double> _flipAnim;
  late final Animation<double> _spotlightAnim;
  late final Animation<double> _resultScale;

  bool _showBackButton = false;

  static const _spinDuration = Duration(milliseconds: 2200);
  static const _spotlightDuration = Duration(milliseconds: 800);
  static const _resultDuration = Duration(milliseconds: 1200);

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(vsync: this, duration: _spinDuration);
    _spotlightController =
        AnimationController(vsync: this, duration: _spotlightDuration);
    _resultController =
        AnimationController(vsync: this, duration: _resultDuration);

    _flipAnim = CurvedAnimation(
      parent: _flipController,
      curve: Curves.easeOutCubic,
    );
    _spotlightAnim = CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.easeOut,
    );
    _resultScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await _flipController.forward();
    if (!mounted) return;

    HapticFeedback.heavyImpact();
    await _spotlightController.forward();
    _resultController.forward();
    if (!mounted) return;

    widget.onRevealed(widget.decision);
    setState(() => _showBackButton = true);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _spotlightController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  bool _showFront(double progress) {
    // 目标面：DO=正面(0)，NOT=反面(π)
    final target = widget.decision.isDo ? 0.0 : math.pi;
    final totalRotations = 5.5;
    final angle = progress * totalRotations * 2 * math.pi;

    // 缓动到目标角度
    final settleStart = 0.75;
    final finalAngle = progress < settleStart
        ? angle
        : angle + (target - (angle % (2 * math.pi))) * ((progress - settleStart) / (1 - settleStart));

    final normalized = finalAngle % (2 * math.pi);
    return math.cos(normalized) >= 0;
  }

  double _rotationY(double progress) {
    final totalRotations = 5.5;
    final angle = progress * totalRotations * 2 * math.pi;
    final target = widget.decision.isDo ? 0.0 : math.pi;

    final settleStart = 0.75;
    if (progress < settleStart) return angle;

    final t = (progress - settleStart) / (1 - settleStart);
    final currentMod = angle % (2 * math.pi);
    var delta = target - currentMod;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    return angle + delta * Curves.easeOutCubic.transform(t);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _flipAnim,
        _spotlightAnim,
        _resultScale,
      ]),
      builder: (context, _) {
        final progress = _flipAnim.value;
        final spotlight = _spotlightAnim.value;
        final isRevealed = progress > 0.85;
        final showFront = _showFront(progress);
        final rotationY = _rotationY(progress);

        final displayDecision = showFront ? Decision.doIt : Decision.notIt;

        return Container(
          color: AppColors.background,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SpotlightOverlay(
                intensity: isRevealed ? spotlight : progress * 0.15,
                spotRadius: 0.28,
              ),
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(rotationY),
                child: Transform.scale(
                  scale: isRevealed ? _resultScale.value : 1.0,
                  child: CoinFaceWidget(
                    decision: isRevealed ? widget.decision : displayDecision,
                    diameter: 180,
                    highlight: isRevealed && spotlight > 0.5,
                  ),
                ),
              ),
              if (isRevealed && spotlight > 0.3)
                Positioned(
                  bottom: _showBackButton ? 100 : 120,
                  child: Opacity(
                    opacity: spotlight,
                    child: Column(
                      children: [
                        Text(
                          widget.decision.label,
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: widget.decision.isDo
                                ? AppColors.doGreen
                                : AppColors.notRed,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.decision.subtitle,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_showBackButton)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RevealBackButton(onPressed: widget.onDismiss),
                ),
            ],
          ),
        );
      },
    );
  }
}
