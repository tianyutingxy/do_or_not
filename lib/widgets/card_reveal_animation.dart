import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/decision.dart';
import '../theme/app_theme.dart';
import 'playing_card_widget.dart';
import 'reveal_back_button.dart';
import 'spotlight_overlay.dart';

class CardRevealAnimation extends StatefulWidget {
  const CardRevealAnimation({
    super.key,
    required this.decision,
    required this.onRevealed,
    required this.onDismiss,
  });

  final Decision decision;
  final void Function(Decision decision) onRevealed;
  final VoidCallback onDismiss;

  @override
  State<CardRevealAnimation> createState() => _CardRevealAnimationState();
}

class _CardRevealAnimationState extends State<CardRevealAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _dealCard1Controller;
  late final AnimationController _dealCard2Controller;
  late final AnimationController _flipController;
  late final AnimationController _spotlightController;
  late final AnimationController _resultController;

  bool _showBackButton = false;

  static const _cardWidth = 118.0;
  static const _trailLags = [0.06, 0.13, 0.20, 0.28];

  @override
  void initState() {
    super.initState();

    _dealCard1Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _dealCard2Controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    HapticFeedback.lightImpact();
    await _dealCard1Controller.forward();
    if (!mounted) return;

    HapticFeedback.selectionClick();
    await _dealCard2Controller.forward();
    if (!mounted) return;

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

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
    _dealCard1Controller.dispose();
    _dealCard2Controller.dispose();
    _flipController.dispose();
    _spotlightController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  /// 逆转王牌风格：牌从屏幕右侧长距离水平滑入
  _CardMotion _cardMotion({
    required double t,
    required double startX,
    required double endX,
  }) {
    // 前段快、末段减速刹车，滑动感更明显
    final slide = Curves.easeOutQuart.transform(t.clamp(0.0, 1.0));

    final x = startX + (endX - startX) * slide;
    // 极轻微的弧线，主体是水平滑动
    final y = math.sin(slide * math.pi) * -12;

    final rotZ = (1 - slide) * -0.14 + slide * 0.04 * (endX > 0 ? 1 : -1);
    final speed = (1 - slide).clamp(0.0, 1.0);

    return _CardMotion(
      offset: Offset(x, y),
      rotationZ: rotZ,
      speed: speed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final slideStartX = screenW * 0.55 + _cardWidth;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _dealCard1Controller,
        _dealCard2Controller,
        _flipController,
        _spotlightController,
        _resultController,
      ]),
      builder: (context, _) {
        final deal1 = _dealCard1Controller.value;
        final deal2 = _dealCard2Controller.value;
        final flip = Curves.easeInOutCubic.transform(_flipController.value);
        final spotlight = Curves.easeOut.transform(_spotlightController.value);
        final isRevealed = _flipController.isCompleted;

        final card1 = _cardForDecision(widget.decision, index: 0);
        final card2 = _cardForDecision(widget.decision, index: 1);

        const leftEndX = -78.0;
        const rightEndX = 78.0;

        final motion1 = _cardMotion(t: deal1, startX: slideStartX, endX: leftEndX);
        final motion2 = _cardMotion(t: deal2, startX: slideStartX, endX: rightEndX);
        final flipAngle = flip * math.pi;

        final anySliding = (deal1 > 0 && deal1 < 1) || (deal2 > 0 && deal2 < 1);

        return Container(
          color: AppColors.background,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SpotlightOverlay(
                intensity: isRevealed ? spotlight : 0,
                spotRadius: 0.38,
              ),

              // 滑动方向速度线
              if (anySliding) _speedLines(deal1, deal2),

              // 拖影 — 第一张
              if (deal1 > 0.04 && deal1 < 0.98)
                ..._buildTrails(
                  dealProgress: deal1,
                  startX: slideStartX,
                  endX: leftEndX,
                ),

              // 拖影 — 第二张
              if (deal2 > 0.04 && deal2 < 0.98)
                ..._buildTrails(
                  dealProgress: deal2,
                  startX: slideStartX,
                  endX: rightEndX,
                ),

              _slidingCard(
                motion: motion1,
                flipAngle: flipAngle,
                rank: card1.$1,
                suit: card1.$2,
                highlight: isRevealed && spotlight > 0.5,
                visible: deal1 > 0,
              ),

              _slidingCard(
                motion: motion2,
                flipAngle: flipAngle,
                rank: card2.$1,
                suit: card2.$2,
                highlight: isRevealed && spotlight > 0.5,
                visible: deal2 > 0,
              ),

              if (isRevealed && spotlight > 0.3) ...[
                Positioned(
                  top: 100,
                  child: Opacity(
                    opacity: spotlight * 0.9,
                    child: Text(
                      widget.decision.isDo ? 'Pocket Rockets' : 'The Hammer',
                      style: TextStyle(
                        fontSize: 14,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gold.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: _showBackButton ? 90 : 100,
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
                          widget.decision.isDo
                              ? 'AA — 最强起手牌'
                              : '7♠2♣ — 最烂起手牌',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                          ),
                        ),
                        const SizedBox(height: 2),
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
              ],

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

  List<Widget> _buildTrails({
    required double dealProgress,
    required double startX,
    required double endX,
  }) {
    return _trailLags.map((lag) {
      final lagT = (dealProgress - lag).clamp(0.0, 1.0);
      if (lagT <= 0) return const SizedBox.shrink();

      final motion = _cardMotion(t: lagT, startX: startX, endX: endX);
      final opacity = (0.28 - lag * 0.7).clamp(0.04, 0.28) * (1 - dealProgress * 0.3);

      return _ghostCard(motion: motion, opacity: opacity);
    }).toList();
  }

  Widget _ghostCard({required _CardMotion motion, required double opacity}) {
    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: motion.offset,
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: motion.rotationZ,
              child: PlayingCardWidget(
                rank: ' ',
                suit: Suit.spade,
                width: _cardWidth,
                faceDown: true,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _speedLines(double deal1, double deal2) {
    final intensity = math.max(
      deal1 > 0 && deal1 < 1 ? 1 - deal1 : 0,
      deal2 > 0 && deal2 < 1 ? 1 - deal2 : 0,
    );

    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _SpeedLinePainter(intensity: intensity * 0.5),
        ),
      ),
    );
  }

  Widget _slidingCard({
    required _CardMotion motion,
    required double flipAngle,
    required String rank,
    required Suit suit,
    required bool highlight,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();

    final showFront = flipAngle > math.pi / 2;
    final yFlip = showFront ? flipAngle - math.pi : flipAngle;
    final sliding = motion.speed > 0.08;

    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: motion.offset,
          child: Transform.rotate(
            angle: motion.rotationZ,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(yFlip),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: sliding ? 0.5 : 0.3),
                      blurRadius: sliding ? 20 : 10,
                      offset: Offset(-motion.speed * 18, 6),
                    ),
                  ],
                ),
                child: PlayingCardWidget(
                  rank: rank,
                  suit: suit,
                  width: _cardWidth,
                  faceDown: !showFront,
                  highlight: showFront && highlight,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  (String, Suit) _cardForDecision(Decision decision, {required int index}) {
    if (decision.isDo) {
      return ('A', index == 0 ? Suit.spade : Suit.heart);
    }
    return index == 0 ? ('7', Suit.spade) : ('2', Suit.club);
  }
}

class _CardMotion {
  const _CardMotion({
    required this.offset,
    required this.rotationZ,
    required this.speed,
  });

  final Offset offset;
  final double rotationZ;
  final double speed;
}

/// 水平速度线，强化滑动感
class _SpeedLinePainter extends CustomPainter {
  _SpeedLinePainter({required this.intensity});

  final double intensity;

  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;

    final paint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final centerY = size.height * 0.5;
    for (var i = 0; i < 6; i++) {
      final y = centerY - 60 + i * 24;
      final len = 80.0 + i * 20;
      paint.color = Colors.white.withValues(alpha: intensity * (0.06 + i * 0.02));
      canvas.drawLine(
        Offset(size.width * 0.55, y),
        Offset(size.width * 0.55 - len, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedLinePainter old) => old.intensity != intensity;
}
