import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/craps_roll.dart';
import '../models/decision.dart';
import '../models/user_response.dart';
import '../theme/app_theme.dart';
import 'dice_3d_widget.dart';
import 'reveal_choice_panel.dart';
import 'reveal_result_header.dart';
import 'spotlight_overlay.dart';

class DiceRevealAnimation extends StatefulWidget {
  const DiceRevealAnimation({
    super.key,
    required this.decision,
    required this.onRevealed,
    required this.onChoice,
    this.choiceLocked = false,
    this.shakingChoice,
    this.confirmedChoice,
    this.isMarked = false,
    this.onMarkToggle,
  });

  final Decision decision;
  final VoidCallback onRevealed;
  final void Function(UserResponse response) onChoice;
  final bool choiceLocked;
  final UserResponse? shakingChoice;
  final UserResponse? confirmedChoice;
  final bool isMarked;
  final ValueChanged<bool>? onMarkToggle;

  @override
  State<DiceRevealAnimation> createState() => _DiceRevealAnimationState();
}

class _DiceRevealAnimationState extends State<DiceRevealAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _throwController;
  late final AnimationController _spotlightController;
  late final AnimationController _resultController;

  late final CrapsRoll _roll;
  late final _ThrowPath _path1;
  late final _ThrowPath _path2;

  bool _showChoices = false;

  static const _diceSize = 88.0;

  @override
  void initState() {
    super.initState();

    _roll = CrapsRoll.randomFor(widget.decision);
    _path1 = _ThrowPath(
      start: const Offset(72, -240),
      end: const Offset(-58, 6),
      peak: 108,
    );
    _path2 = _ThrowPath(
      start: const Offset(-64, -280),
      end: const Offset(58, 6),
      peak: 118,
    );

    _throwController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
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
    HapticFeedback.mediumImpact();
    await _throwController.forward();
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
    _throwController.dispose();
    _spotlightController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  double _dieT(double master, {required double delay, required double duration}) {
    if (master <= delay) return 0;
    return ((master - delay) / duration).clamp(0.0, 1.0);
  }

  Offset _throwOffset(double t, _ThrowPath path) {
    if (t <= 0) return path.start;

    final fly = Curves.easeInCubic.transform(t.clamp(0.0, 1.0));
    final x = path.start.dx + (path.end.dx - path.start.dx) * fly;
    final baseY = path.start.dy + (path.end.dy - path.start.dy) * fly;
    final arc = 4 * path.peak * fly * (1 - fly);

    double bounce = 0;
    if (t > 0.88) {
      final bt = (t - 0.88) / 0.12;
      bounce = math.sin(bt * math.pi) * 10 * (1 - bt);
    }

    return Offset(x, baseY - arc + bounce);
  }

  Dice3DOrientation _throwRotation(double t, int topFace) {
    final rest = Dice3DOrientation.showingTop(topFace);
    if (t <= 0) {
      return rest.addSpin(-math.pi * 0.4, math.pi * 0.3, 0);
    }

    final spinDecay = (1 - t) * math.pi * 7;
    final wild = rest.addSpin(
      math.sin(t * math.pi * 8) * spinDecay,
      math.cos(t * math.pi * 6.5) * spinDecay * 0.92,
      math.sin(t * math.pi * 5.5) * spinDecay * 0.78,
    );

    final settle = Curves.easeOutCubic.transform(
      ((t - 0.55) / 0.45).clamp(0.0, 1.0),
    );
    return wild.blend(rest, settle);
  }

  double _impactScale(double t) {
    if (t < 0.82 || t > 0.96) return 1;
    final bt = (t - 0.82) / 0.14;
    return 1 - math.sin(bt * math.pi) * 0.06;
  }

  double _shadowOpacity(double t) {
    return Curves.easeOut.transform(((t - 0.35) / 0.65).clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _throwController,
        _spotlightController,
        _resultController,
      ]),
      builder: (context, _) {
        final l10n = AppLocalizations.of(context);
        final master = _throwController.value;
        final t1 = _dieT(master, delay: 0, duration: 0.88);
        final t2 = _dieT(master, delay: 0.14, duration: 0.88);
        final spotlight = Curves.easeOut.transform(_spotlightController.value);
        final settled = _throwController.isCompleted;

        return Container(
          color: AppColors.background,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (t1 > 0.1)
                _tableShadow(
                  offset: _throwOffset(t1, _path1),
                  opacity: _shadowOpacity(t1),
                ),
              if (t2 > 0.1)
                _tableShadow(
                  offset: _throwOffset(t2, _path2),
                  opacity: _shadowOpacity(t2),
                ),

              _thrownDie(
                t: t1,
                path: _path1,
                topFace: _roll.die1,
                highlight: settled && spotlight > 0,
                highlightStrength: spotlight,
              ),

              _thrownDie(
                t: t2,
                path: _path2,
                topFace: _roll.die2,
                highlight: settled && spotlight > 0,
                highlightStrength: spotlight,
              ),

              if (settled && spotlight > 0)
                RepaintBoundary(
                  child: SpotlightOverlay(
                    intensity: spotlight,
                    spotRadius: 0.38,
                  ),
                ),

              if (settled && spotlight > 0.3)
                RevealResultHeader(
                  decision: widget.decision,
                  opacity: spotlight,
                  flavorTitle: _roll.flavorTitle(l10n),
                  detailLine: _roll.detailLine(l10n),
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
                    isMarked: widget.isMarked,
                    onMarkToggle: widget.onMarkToggle,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _tableShadow({required Offset offset, required double opacity}) {
    if (opacity <= 0) return const SizedBox.shrink();

    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: offset + const Offset(0, 52),
          child: Opacity(
            opacity: opacity * 0.45,
            child: Container(
              width: _diceSize * 1.1,
              height: _diceSize * 0.28,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(_diceSize * 0.14),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _thrownDie({
    required double t,
    required _ThrowPath path,
    required int topFace,
    required bool highlight,
    required double highlightStrength,
  }) {
    if (t <= 0) return const SizedBox.shrink();

    final offset = _throwOffset(t, path);
    final orient = _throwRotation(t, topFace);
    final scale = _impactScale(t);

    return Positioned.fill(
      child: Center(
        child: Transform.translate(
          offset: offset,
          child: Transform.scale(
            scale: scale,
            child: Dice3DWidget(
              size: _diceSize,
              rotationX: orient.x,
              rotationY: orient.y,
              rotationZ: orient.z,
              highlight: highlight,
              highlightStrength: highlightStrength,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThrowPath {
  const _ThrowPath({
    required this.start,
    required this.end,
    required this.peak,
  });

  final Offset start;
  final Offset end;
  final double peak;
}
