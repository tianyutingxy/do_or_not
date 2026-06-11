import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/decision.dart';
import '../models/user_response.dart';
import '../theme/app_theme.dart';
import 'coin_3d_widget.dart';
import 'reveal_choice_panel.dart';
import 'reveal_result_header.dart';
import 'spotlight_overlay.dart';

class CoinRevealAnimation extends StatefulWidget {
  const CoinRevealAnimation({
    super.key,
    required this.decision,
    required this.onRevealed,
    required this.onChoice,
    this.choiceLocked = false,
    this.shakingChoice,
    this.confirmedChoice,
  });

  final Decision decision;
  final VoidCallback onRevealed;
  final void Function(UserResponse response) onChoice;
  final bool choiceLocked;
  final UserResponse? shakingChoice;
  final UserResponse? confirmedChoice;

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

  bool _showChoices = false;

  static const _tossDuration = Duration(milliseconds: 2600);
  static const _spotlightDuration = Duration(milliseconds: 800);
  static const _resultDuration = Duration(milliseconds: 1200);

  // 竖直抛掷：下 → 上 → 下
  static const _startY = 92.0;
  static const _peakY = -112.0;
  static const _landY = 0.0;
  static const _ascentRatio = 0.46;

  @override
  void initState() {
    super.initState();

    _flipController = AnimationController(vsync: this, duration: _tossDuration);
    _spotlightController =
        AnimationController(vsync: this, duration: _spotlightDuration);
    _resultController =
        AnimationController(vsync: this, duration: _resultDuration);

    _flipAnim = CurvedAnimation(parent: _flipController, curve: Curves.linear);
    _spotlightAnim = CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.easeOut,
    );
    _resultScale = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runSequence();
    });
  }

  Future<void> _runSequence() async {
    HapticFeedback.lightImpact();
    await _flipController.forward();
    if (!mounted) return;

    HapticFeedback.heavyImpact();
    await _spotlightController.forward();
    _resultController.forward();
    if (!mounted) return;

    widget.onRevealed();
    setState(() => _showChoices = true);
  }

  @override
  void dispose() {
    _flipController.dispose();
    _spotlightController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  /// 物理感抛掷：上升减速至顶点，下落加速落地
  double _tossYOffset(double t) {
    final p = t.clamp(0.0, 1.0);
    if (p <= _ascentRatio) {
      final u = p / _ascentRatio;
      final eased = Curves.easeOut.transform(u);
      return _startY + (_peakY - _startY) * eased;
    }
    final u = (p - _ascentRatio) / (1 - _ascentRatio);
    final eased = Curves.easeIn.transform(u);
    return _peakY + (_landY - _peakY) * eased;
  }

  double _shadowOpacity(double t) {
    final y = _tossYOffset(t);
    final heightFactor =
        ((_startY - y) / (_startY - _peakY)).clamp(0.0, 1.0);
    return (0.32 - heightFactor * 0.24).clamp(0.06, 0.32);
  }

  double _shadowScale(double t) {
    final y = _tossYOffset(t);
    final heightFactor =
        ((_startY - y) / (_startY - _peakY)).clamp(0.0, 1.0);
    return (1.0 - heightFactor * 0.5).clamp(0.45, 1.0);
  }

  /// 侧面翻转：绕水平轴 rotateX，DO=正面 10，NOT=猫头
  double _rotationX(double progress) {
    const totalFlips = 4.5;
    final target = widget.decision.isDo ? 0.0 : math.pi;
    final angle = progress * totalFlips * 2 * math.pi;

    const settleStart = 0.8;
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
        final isRevealed = progress > 0.9;
        final rotationX = _rotationX(progress);
        final settleScale = isRevealed ? _resultScale.value : 1.0;

        return Container(
          color: AppColors.background,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, 68),
                child: Transform.scale(
                  scale: _shadowScale(progress),
                  child: Container(
                    width: 130,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withValues(
                        alpha: _shadowOpacity(progress),
                      ),
                    ),
                  ),
                ),
              ),

              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateZ(-0.12),
                child: Transform.translate(
                  offset: Offset(0, _tossYOffset(progress)),
                  child: Transform.scale(
                    scale: settleScale,
                    child: Coin3DWidget(
                      diameter: 180,
                      rotationX: rotationX,
                      highlight: isRevealed && spotlight > 0,
                      highlightStrength: spotlight,
                    ),
                  ),
                ),
              ),

              if (isRevealed && spotlight > 0)
                RepaintBoundary(
                  child: SpotlightOverlay(
                    intensity: spotlight,
                    spotRadius: 0.28,
                  ),
                ),
              if (isRevealed && spotlight > 0.3)
                RevealResultHeader(
                  decision: widget.decision,
                  opacity: spotlight,
                  flavorTitle: widget.decision.isDo ? '正面' : '反面',
                  detailLine: widget.decision.isDo
                      ? '天秤导向了行动'
                      : '喵喵劝你收手',
                ),
              if (_showChoices)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: RevealChoicePanel(
                    onChoice: widget.onChoice,
                    locked: widget.choiceLocked,
                    shaking: widget.shakingChoice,
                    confirmed: widget.confirmedChoice,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
