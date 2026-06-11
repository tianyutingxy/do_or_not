import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/decision.dart';
import '../models/user_response.dart';
import '../theme/app_theme.dart';
import 'playing_card_widget.dart';
import 'reveal_choice_panel.dart';
import 'reveal_result_header.dart';
import 'spotlight_overlay.dart';

class CardRevealAnimation extends StatefulWidget {
  const CardRevealAnimation({
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
  State<CardRevealAnimation> createState() => _CardRevealAnimationState();
}

class _CardRevealAnimationState extends State<CardRevealAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _dealCard1Controller;
  late final AnimationController _dealCard2Controller;
  late final AnimationController _flipController;
  late final AnimationController _spotlightController;
  late final AnimationController _resultController;

  late final _HandCards _hand;

  bool _showChoices = false;

  static const _cardWidth = 118.0;
  static const _trailLags = [0.06, 0.13, 0.20, 0.28];
  // 必须为整数圈，否则结束时角度无法回到正面
  static const _flipRotations = 3;

  @override
  void initState() {
    super.initState();

    _hand = _HandCards.randomFor(widget.decision);

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
      duration: const Duration(milliseconds: 2600),
    );
    _spotlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _resultController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _runSequence();
    });
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

    widget.onRevealed();
    setState(() => _showChoices = true);
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

  /// 慢 → 快 → 慢，用于连续翻牌
  double _slowFastSlow(double t) {
    return -(math.cos(math.pi * t.clamp(0.0, 1.0)) - 1) / 2;
  }

  double _flipAngle(double t) {
    return _slowFastSlow(t) * _flipRotations * 2 * math.pi;
  }

  /// 将翻转角度归一化到 [0, 2π)，落定后强制回正
  double _displayRotateY(double flipAngle, bool flipDone) {
    if (flipDone) return 0;
    final norm = flipAngle % (2 * math.pi);
    return math.cos(norm) >= 0 ? norm : norm - math.pi;
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
        final flipT = _flipController.value;
        final flipAngle = _flipAngle(flipT);
        final spotlight = Curves.easeOut.transform(_spotlightController.value);
        final flipDone = _flipController.isCompleted;
        final isRevealed = flipDone;

        const leftEndX = -78.0;
        const rightEndX = 78.0;

        final motion1 = _cardMotion(t: deal1, startX: slideStartX, endX: leftEndX);
        final motion2 = _cardMotion(t: deal2, startX: slideStartX, endX: rightEndX);

        final anySliding = (deal1 > 0 && deal1 < 1) || (deal2 > 0 && deal2 < 1);

        return Container(
          color: AppColors.background,
          child: Stack(
            alignment: Alignment.center,
            children: [
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
                flipDone: flipDone,
                use3D: _flipController.isAnimating || flipDone,
                rank: _hand.card1Rank,
                suit: _hand.card1Suit,
                highlight: isRevealed && spotlight > 0,
                highlightStrength: spotlight,
                visible: deal1 > 0,
              ),

              _slidingCard(
                motion: motion2,
                flipAngle: flipAngle,
                flipDone: flipDone,
                use3D: _flipController.isAnimating || flipDone,
                rank: _hand.card2Rank,
                suit: _hand.card2Suit,
                highlight: isRevealed && spotlight > 0,
                highlightStrength: spotlight,
                visible: deal2 > 0,
              ),

              if (isRevealed && spotlight > 0)
                RepaintBoundary(
                  child: SpotlightOverlay(
                    intensity: spotlight,
                    spotRadius: 0.38,
                  ),
                ),

              if (isRevealed && spotlight > 0.3)
                RevealResultHeader(
                  decision: widget.decision,
                  opacity: spotlight,
                  flavorTitle: widget.decision.isDo
                      ? 'Pocket Rockets'
                      : 'The Hammer',
                  detailLine: _hand.handLabel,
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
    final t = opacity.clamp(0.0, 1.0);

    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: motion.offset,
          child: Transform.rotate(
            angle: motion.rotationZ,
            child: Container(
              width: _cardWidth,
              height: _cardWidth * 1.4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1E3A5F).withValues(alpha: 0.75 * t),
                    const Color(0xFF0D1B2A).withValues(alpha: 0.75 * t),
                  ],
                ),
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
    required bool flipDone,
    required bool use3D,
    required String rank,
    required Suit suit,
    required bool highlight,
    required double highlightStrength,
    required bool visible,
  }) {
    if (!visible) return const SizedBox.shrink();

    final yFlip = _displayRotateY(flipAngle, flipDone);
    final faceDown = !flipDone;
    final sliding = motion.speed > 0.08;

    final card = DecoratedBox(
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
        faceDown: faceDown,
        highlight: !faceDown && highlight,
        highlightStrength: highlightStrength,
      ),
    );

    final rotated = Transform.rotate(angle: motion.rotationZ, child: card);

    final Widget flipped;
    if (use3D) {
      flipped = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(yFlip),
        child: rotated,
      );
    } else {
      flipped = rotated;
    }

    return Positioned.fill(
      child: Center(
        child: Transform.translate(offset: motion.offset, child: flipped),
      ),
    );
  }

}

/// 起手牌组合，NOT 时随机不同花色
class _HandCards {
  const _HandCards({
    required this.card1Rank,
    required this.card1Suit,
    required this.card2Rank,
    required this.card2Suit,
    required this.handLabel,
  });

  final String card1Rank;
  final Suit card1Suit;
  final String card2Rank;
  final Suit card2Suit;
  final String handLabel;

  static final _rng = math.Random();

  static _HandCards randomFor(Decision decision) {
    if (decision.isDo) {
      final suits = List<Suit>.from(Suit.values)..shuffle(_rng);
      final s1 = suits[0];
      final s2 = suits[1];
      return _HandCards(
        card1Rank: 'A',
        card1Suit: s1,
        card2Rank: 'A',
        card2Suit: s2,
        handLabel: '最强起手牌',
      );
    }

    final suits = List<Suit>.from(Suit.values)..shuffle(_rng);
    final s1 = suits[0];
    var s2 = suits[1];
    if (s1 == s2) {
      s2 = suits.firstWhere((s) => s != s1);
    }

    // 7 和 2 随机左右，但保持不同花
    final sevenFirst = _rng.nextBool();
    final rank1 = sevenFirst ? '7' : '2';
    final suit1 = sevenFirst ? s1 : s2;
    final rank2 = sevenFirst ? '2' : '7';
    final suit2 = sevenFirst ? s2 : s1;

    return _HandCards(
      card1Rank: rank1,
      card1Suit: suit1,
      card2Rank: rank2,
      card2Suit: suit2,
      handLabel: '最烂起手牌',
    );
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
