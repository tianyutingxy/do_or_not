import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  late final AnimationController _tossController;
  late final AnimationController _landController;
  late final AnimationController _spotlightController;
  late final AnimationController _resultController;

  late final Animation<double> _tossAnim;
  late final Animation<double> _landAnim;
  late final Animation<double> _spotlightAnim;
  late final Animation<double> _resultScale;

  bool _showChoices = false;

  static const _tossDuration = Duration(milliseconds: 2500);
  static const _landDuration = Duration(milliseconds: 720);
  static const _spotlightDuration = Duration(milliseconds: 800);
  static const _resultDuration = Duration(milliseconds: 1200);

  static const _startY = 92.0;
  static const _peakY = -112.0;
  static const _landY = 0.0;

  @override
  void initState() {
    super.initState();

    _tossController = AnimationController(vsync: this, duration: _tossDuration);
    _landController = AnimationController(vsync: this, duration: _landDuration);
    _spotlightController =
        AnimationController(vsync: this, duration: _spotlightDuration);
    _resultController =
        AnimationController(vsync: this, duration: _resultDuration);

    _tossAnim = CurvedAnimation(parent: _tossController, curve: Curves.linear);
    _landAnim = CurvedAnimation(parent: _landController, curve: Curves.linear);
    _spotlightAnim = CurvedAnimation(
      parent: _spotlightController,
      curve: Curves.easeOut,
    );
    _resultScale = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _resultController, curve: Curves.easeOutCubic),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runSequence();
    });
  }

  Future<void> _runSequence() async {
    HapticFeedback.lightImpact();
    await _tossController.forward();
    if (!mounted) return;

    HapticFeedback.heavyImpact();
    await _landController.forward();
    if (!mounted) return;

    HapticFeedback.lightImpact();
    await _spotlightController.forward();
    _resultController.forward();
    if (!mounted) return;

    widget.onRevealed();
    setState(() => _showChoices = true);
  }

  @override
  void dispose() {
    _tossController.dispose();
    _landController.dispose();
    _spotlightController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  /// 单段抛物线：起点 / 顶点 / 落点速度连续
  double _tossArcY(double t) {
    final p = t.clamp(0.0, 1.0);
    final linear = _startY + (_landY - _startY) * p;
    final bump = (_peakY - (_startY + _landY) / 2) * math.sin(math.pi * p);
    return linear + bump;
  }

  /// 落地衰减弹跳（2 次）
  double _bounceY(double t) {
    final p = t.clamp(0.0, 1.0);
    final decay = (1 - p) * (1 - p);
    return -16 * math.sin(p * math.pi * 2.15) * decay;
  }

  double _coinY(double tossT, double landT) {
    final base = _tossController.isCompleted ? _landY : _tossArcY(tossT);
    if (!_landController.isAnimating && !_landController.isCompleted) {
      return base;
    }
    return base + _bounceY(landT);
  }

  /// 触地挤压
  double _squashX(double landT) {
    final p = landT.clamp(0.0, 1.0);
    if (p < 0.07) return 1.0 + 0.055 * Curves.easeOut.transform(p / 0.07);
    if (p < 0.22) {
      final u = (p - 0.07) / 0.15;
      return 1.055 - 0.055 * Curves.easeOut.transform(u);
    }
    return 1.0;
  }

  double _squashY(double landT) {
    final p = landT.clamp(0.0, 1.0);
    if (p < 0.07) return 1.0 - 0.09 * Curves.easeOut.transform(p / 0.07);
    if (p < 0.22) {
      final u = (p - 0.07) / 0.15;
      return 0.91 + 0.09 * Curves.easeOut.transform(u);
    }
    return 1.0;
  }

  /// 落地微晃（弧度）
  double _wobbleZ(double landT) {
    final p = landT.clamp(0.0, 1.0);
    return math.sin(p * math.pi * 5.5) * 0.032 * (1 - p);
  }

  double _shadowOpacity(double y) {
    final heightFactor =
        ((_startY - y) / (_startY - _peakY)).clamp(0.0, 1.0);
    return (0.32 - heightFactor * 0.24).clamp(0.06, 0.32);
  }

  double _shadowScale(double y) {
    final heightFactor =
        ((_startY - y) / (_startY - _peakY)).clamp(0.0, 1.0);
    return (1.0 - heightFactor * 0.5).clamp(0.42, 1.0);
  }

  /// 触地前收束翻面，落地时角度已锁定
  double _rotationX(double tossT) {
    const totalFlips = 4.5;
    final target = widget.decision.isDo ? 0.0 : math.pi;
    final angle = tossT * totalFlips * 2 * math.pi;

    const settleStart = 0.68;
    const settleEnd = 0.94;
    if (tossT < settleStart) return angle;

    if (tossT >= settleEnd) {
      final rotations = (angle / (2 * math.pi)).floor();
      return rotations * 2 * math.pi + target;
    }

    final t = (tossT - settleStart) / (settleEnd - settleStart);
    final eased = Curves.easeOutCubic.transform(t);
    final currentMod = angle % (2 * math.pi);
    var delta = target - currentMod;
    if (delta > math.pi) delta -= 2 * math.pi;
    if (delta < -math.pi) delta += 2 * math.pi;
    return angle + delta * eased;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _tossAnim,
        _landAnim,
        _spotlightAnim,
        _resultScale,
      ]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final tossT = _tossAnim.value;
        final landT = _landAnim.value;
        final spotlight = _spotlightAnim.value;
        final coinY = _coinY(tossT, landT);
        final landed = _landController.isCompleted;
        final landing = _landController.isAnimating || landed;
        final isRevealed = _tossController.isCompleted && landing;
        final rotationX = _rotationX(tossT);
        final settleScale = landed ? _resultScale.value : 1.0;

        final squashX = landing ? _squashX(landT) : 1.0;
        final squashY = landing ? _squashY(landT) : 1.0;
        final wobble = landing ? _wobbleZ(landT) : 0.0;
        const baseTilt = -0.12;

        return Container(
          color: AppColors.background,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: const Offset(0, 68),
                child: Transform.scale(
                  scale: _shadowScale(coinY),
                  child: Container(
                    width: 130,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withValues(
                        alpha: _shadowOpacity(coinY),
                      ),
                    ),
                  ),
                ),
              ),

              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateZ(baseTilt + wobble),
                child: Transform.translate(
                  offset: Offset(0, coinY),
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scale(squashX, squashY),
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
                  flavorTitle:
                      widget.decision.isDo ? l10n.coinHeads : l10n.coinTails,
                  detailLine: widget.decision.isDo
                      ? l10n.coinDoDetail
                      : l10n.coinNotDetail,
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
