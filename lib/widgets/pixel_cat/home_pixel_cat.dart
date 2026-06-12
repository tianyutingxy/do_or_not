import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'cat_patrol_routine.dart';
import 'cat_sprites.dart';

enum _CatMode { patrol, jump }

/// 首页遛弯猫：每次出现在首页生成新剧本，精灵条动画。
class HomePixelCat extends StatefulWidget {
  const HomePixelCat({
    super.key,
    required this.patrolBounds,
    required this.visible,
    this.frozen = false,
  });

  final Rect patrolBounds;
  final bool visible;
  final bool frozen;

  @override
  State<HomePixelCat> createState() => HomePixelCatState();
}

class HomePixelCatState extends State<HomePixelCat>
    with TickerProviderStateMixin {
  static const _margin = 10.0;

  final _rng = math.Random();
  final _routineGenerator = CatPatrolRoutineGenerator();

  late final AnimationController _segmentController;
  late final AnimationController _jumpController;

  Ticker? _frameTicker;
  Duration _frameElapsed = Duration.zero;
  int _frameMs = CatAction.walk.msPerFrame;

  _CatMode _mode = _CatMode.patrol;
  CatAction _action = CatAction.idle;
  bool _facingRight = true;
  double _squashX = 1;
  double _squashY = 1;
  int _frameIndex = 0;

  Offset _position = Offset.zero;
  Offset _jumpStart = Offset.zero;
  Offset _jumpEnd = Offset.zero;
  Offset _segmentFrom = Offset.zero;
  Offset _segmentTo = Offset.zero;

  Rect _activeBounds = Rect.zero;
  final List<CatAction> _recentActions = [];

  @override
  void initState() {
    super.initState();
    _segmentController = AnimationController(vsync: this)
      ..addListener(_onSegmentTick);

    _jumpController = AnimationController(vsync: this)
      ..addListener(() {
        if (_mode == _CatMode.jump) setState(() {});
      });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.visible || widget.patrolBounds == Rect.zero) {
        return;
      }
      beginHomeSession(widget.patrolBounds);
    });
  }

  @override
  void didUpdateWidget(covariant HomePixelCat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.patrolBounds != oldWidget.patrolBounds &&
        widget.patrolBounds != Rect.zero) {
      _activeBounds = widget.patrolBounds;
      _position = _clampFeet(_position, _activeBounds);
    }
    if (widget.visible && !oldWidget.visible && widget.patrolBounds != Rect.zero) {
      beginHomeSession(widget.patrolBounds);
    }
    if (!widget.visible && oldWidget.visible) {
      _stopPatrolMotion();
    }
    if (widget.frozen && !oldWidget.frozen) {
      freeze();
    }
  }

  /// 定格在当前姿势（点「去吧」时）。
  void freeze() {
    _stopPatrolMotion();
  }

  @override
  void dispose() {
    _stopFrameTicker();
    _segmentController.dispose();
    _jumpController.dispose();
    super.dispose();
  }

  void _stopFrameTicker() {
    _frameTicker?.dispose();
    _frameTicker = null;
  }

  void _stopPatrolMotion() {
    _stopFrameTicker();
    _segmentController.stop();
  }

  void _startFrameAnim(CatAction action) {
    _stopFrameTicker();
    _frameIndex = 0;
    _frameMs = action.msPerFrame;
    _frameElapsed = Duration.zero;

    if (action.frameCount <= 1) return;

    final loops = action.loopsWhilePlaying;

    _frameTicker = createTicker((elapsed) {
      if (_mode != _CatMode.patrol && _mode != _CatMode.jump) return;
      if (_action != action && _mode == _CatMode.patrol) return;

      _frameElapsed = elapsed;
      final step = (_frameElapsed.inMilliseconds / _frameMs).floor();
      final frame = loops
          ? step % action.frameCount
          : step.clamp(0, action.frameCount - 1);
      if (frame != _frameIndex) {
        setState(() => _frameIndex = frame);
      }
    })..start();
  }

  Rect _feetBounds(Rect bounds) {
    final cat = CatAction.displaySize;
    return Rect.fromLTRB(
      bounds.left + cat.width / 2 + _margin,
      bounds.top + cat.height + _margin,
      bounds.right - cat.width / 2 - _margin,
      bounds.bottom - _margin,
    );
  }

  Offset _clampFeet(Offset feet, Rect bounds) {
    final area = _feetBounds(bounds);
    if (area.width <= 0 || area.height <= 0) {
      return Offset(area.left, area.center.dy);
    }
    return Offset(
      feet.dx.clamp(area.left, area.right),
      feet.dy.clamp(area.top, area.bottom),
    );
  }

  Offset _randomFeet(Rect bounds) {
    final area = _feetBounds(bounds);
    if (area.width <= 0 || area.height <= 0) {
      return Offset(area.left, area.center.dy);
    }
    return Offset(
      area.left + _rng.nextDouble() * area.width,
      area.top + _rng.nextDouble() * area.height,
    );
  }

  /// 在巡逻区内沿随机方向走固定距离，避免忽远忽近。
  Offset _moveTarget(Offset from, CatAction action, Rect bounds) {
    final area = _feetBounds(bounds);
    if (area.width <= 0 || area.height <= 0) return from;

    final minD = action.minMoveDistance > 0 ? action.minMoveDistance : 64;
    final maxD = action.maxMoveDistance > 0 ? action.maxMoveDistance : 140;
    final distance = minD + _rng.nextDouble() * (maxD - minD);

    for (var attempt = 0; attempt < 8; attempt++) {
      final angle = _rng.nextDouble() * math.pi * 2;
      final candidate = from +
          Offset(math.cos(angle) * distance, math.sin(angle) * distance * 0.55);
      final clamped = _clampFeet(candidate, bounds);
      if ((clamped - from).distance >= minD * 0.75) {
        return clamped;
      }
    }

    return _clampFeet(
      from + Offset(_facingRight ? distance : -distance, 0),
      bounds,
    );
  }

  void _onSegmentTick() {
    if (_mode != _CatMode.patrol || !_action.moves) return;

    // 匀速线性位移，与步伐帧率解耦
    final t = _segmentController.value;
    final next = Offset.lerp(_segmentFrom, _segmentTo, t)!;
    final prevX = _position.dx;

    setState(() {
      _position = next;
      if ((next.dx - prevX).abs() > 0.25) {
        _facingRight = next.dx >= prevX;
      }
    });
  }

  void _recordAction(CatAction action) {
    _recentActions.add(action);
    if (_recentActions.length > 4) {
      _recentActions.removeAt(0);
    }
  }

  void _advanceBeat() {
    if (!mounted || !widget.visible || widget.frozen || _mode != _CatMode.patrol) {
      return;
    }

    _recordAction(_action);
    final next = _routineGenerator.pickNext(
      _rng,
      previous: _action,
      recent: _recentActions,
    );
    _playBeat(next);
  }

  void _playBeat(CatAction action) {
    if (!mounted || !widget.visible || widget.frozen || _mode != _CatMode.patrol) {
      return;
    }

    setState(() => _action = action);
    _startFrameAnim(action);

    if (action.moves) {
      _startMoveBeat(action);
    } else {
      _startHoldBeat(action);
    }
  }

  void _startHoldBeat(CatAction action) {
    _segmentController.stop();

    Future<void>.delayed(action.holdDuration, () {
      if (!mounted || _mode != _CatMode.patrol || _action != action) return;
      _advanceBeat();
    });
  }

  void _startMoveBeat(CatAction action) {
    _segmentFrom = _clampFeet(_position, _activeBounds);
    _segmentTo = _moveTarget(_segmentFrom, action, _activeBounds);

    final dist = (_segmentTo - _segmentFrom).distance;
    final ms = (dist / action.speed * 1000).round().clamp(900, 4200);
    _facingRight = _segmentTo.dx >= _segmentFrom.dx;

    _segmentController
      ..duration = Duration(milliseconds: ms)
      ..forward(from: 0).whenComplete(() {
        if (!mounted || _mode != _CatMode.patrol || _action != action) return;
        _advanceBeat();
      });
  }

  Future<void> jumpTo(Offset target) async {
    if (!mounted) return;

    _stopPatrolMotion();
    final jumpAction = CatAction.jumpRun;
    final jumpMs = jumpAction.msPerFrame * jumpAction.frameCount;

    _jumpController.duration = Duration(milliseconds: jumpMs);

    setState(() {
      _mode = _CatMode.jump;
      _action = jumpAction;
      _jumpStart = _position;
      _jumpEnd = target -
          Offset(CatAction.displaySize.width / 2, CatAction.displaySize.height);
      _facingRight = _jumpEnd.dx >= _jumpStart.dx;
      _squashX = 1;
      _squashY = 1;
      _frameIndex = 0;
    });
    _startFrameAnim(jumpAction);

    await _jumpController.forward(from: 0);
    if (!mounted) return;

    _stopFrameTicker();
    setState(() {
      _squashX = 1;
      _squashY = 1;
    });
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  /// 巡逻区尺寸变化时保持当前剧本，只更新边界。
  void updateBounds(Rect bounds) {
    if (!mounted) return;
    _activeBounds = bounds;
    _position = _clampFeet(_position, bounds);
  }

  /// 每次进入首页：重新生成随机剧本并开始播放。
  void beginHomeSession(Rect bounds) {
    if (!mounted) return;

    _segmentController.stop();
    _stopFrameTicker();

    _activeBounds = bounds;
    _recentActions.clear();
    _position = _randomFeet(bounds);
    _facingRight = _rng.nextBool();

    setState(() {
      _mode = _CatMode.patrol;
      _squashX = 1;
      _squashY = 1;
    });

    if (widget.visible) {
      final first = _routineGenerator.pickNext(_rng);
      _playBeat(first);
    }
  }

  Offset _jumpPosition() {
    final t = Curves.easeInOut.transform(_jumpController.value);
    final linear = Offset.lerp(_jumpStart, _jumpEnd, t)!;
    final arc = -52 * math.sin(math.pi * t);
    return linear + Offset(0, arc);
  }

  void _updateJumpSquash(double t) {
    if (t < 0.12) {
      _squashY = 1 - 0.08 * (t / 0.12);
      _squashX = 1 + 0.06 * (t / 0.12);
    } else if (t > 0.88) {
      final u = (t - 0.88) / 0.12;
      _squashY = 0.92 + 0.08 * u;
      _squashX = 1.06 - 0.06 * u;
    } else {
      _squashX = 1;
      _squashY = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    final displayPos = _mode == _CatMode.jump ? _jumpPosition() : _position;
    if (_mode == _CatMode.jump) {
      _updateJumpSquash(_jumpController.value);
    }

    final size = CatAction.displaySize;
    return Positioned(
      left: displayPos.dx - size.width / 2,
      top: displayPos.dy - size.height,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: CatSpriteWidget(
            action: _action,
            frameIndex: _frameIndex,
            facingRight: _facingRight,
            squashX: _squashX,
            squashY: _squashY,
          ),
        ),
      ),
    );
  }
}
