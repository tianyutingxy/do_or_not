import 'package:flutter/material.dart';

/// 精灵条播放方式
enum CatAnimStyle {
  /// 停留期间循环播帧（idle、舔毛等）
  loop,
  /// 播完一遍后停在最后一帧（趴下、伸懒腰等过渡动作）
  playOnceHoldLast,
  /// 单帧静止
  single,
}

/// Pet Cats Pack — Yellow Cat (Cat-1) 精灵条（每帧 50×50，横向排列）。
enum CatAction {
  idle(
    asset: 'assets/images/cat/cat_idle.png',
    frameCount: 10,
    moves: false,
    animStyle: CatAnimStyle.loop,
    loopCycles: 2,
    msPerFrame: 140,
  ),
  walk(
    asset: 'assets/images/cat/cat_walk.png',
    frameCount: 8,
    moves: true,
    speed: 38,
    msPerFrame: 120,
    minMoveDistance: 72,
    maxMoveDistance: 148,
  ),
  run(
    asset: 'assets/images/cat/cat_run.png',
    frameCount: 8,
    moves: true,
    speed: 58,
    msPerFrame: 100,
    minMoveDistance: 110,
    maxMoveDistance: 210,
  ),
  meow(
    asset: 'assets/images/cat/cat_meow.png',
    frameCount: 4,
    moves: false,
    animStyle: CatAnimStyle.loop,
    loopCycles: 2,
    msPerFrame: 130,
  ),
  laying(
    asset: 'assets/images/cat/cat_laying.png',
    frameCount: 8,
    moves: false,
    animStyle: CatAnimStyle.playOnceHoldLast,
    holdLastFrameMs: 2000,
    msPerFrame: 150,
  ),
  sitting(
    asset: 'assets/images/cat/cat_sitting.png',
    frameCount: 1,
    moves: false,
    animStyle: CatAnimStyle.single,
    holdMs: 2400,
    msPerFrame: 120,
  ),
  sleeping1(
    asset: 'assets/images/cat/cat_sleeping1.png',
    frameCount: 1,
    moves: false,
    animStyle: CatAnimStyle.single,
    holdMs: 3000,
    msPerFrame: 120,
  ),
  sleeping2(
    asset: 'assets/images/cat/cat_sleeping2.png',
    frameCount: 1,
    moves: false,
    animStyle: CatAnimStyle.single,
    holdMs: 3400,
    msPerFrame: 120,
  ),
  licking1(
    asset: 'assets/images/cat/cat_licking1.png',
    frameCount: 5,
    moves: false,
    animStyle: CatAnimStyle.loop,
    loopCycles: 2,
    msPerFrame: 130,
  ),
  licking2(
    asset: 'assets/images/cat/cat_licking2.png',
    frameCount: 5,
    moves: false,
    animStyle: CatAnimStyle.loop,
    loopCycles: 2,
    msPerFrame: 130,
  ),
  stretching(
    asset: 'assets/images/cat/cat_stretching.png',
    frameCount: 13,
    moves: false,
    animStyle: CatAnimStyle.playOnceHoldLast,
    holdLastFrameMs: 600,
    msPerFrame: 115,
  ),
  itch(
    asset: 'assets/images/cat/cat_itch.png',
    frameCount: 2,
    moves: false,
    animStyle: CatAnimStyle.loop,
    loopCycles: 3,
    msPerFrame: 130,
  ),
  jumpRun(
    asset: 'assets/images/cat/cat_run.png',
    frameCount: 8,
    moves: false,
    animStyle: CatAnimStyle.loop,
    loopCycles: 1,
    msPerFrame: 95,
  );

  const CatAction({
    required this.asset,
    required this.frameCount,
    required this.moves,
    this.animStyle = CatAnimStyle.loop,
    this.speed = 0,
    this.loopCycles = 1,
    this.holdMs = 0,
    this.holdLastFrameMs = 0,
    this.msPerFrame = 120,
    this.minMoveDistance = 0,
    this.maxMoveDistance = 0,
  });

  final String asset;
  final int frameCount;
  final bool moves;
  final CatAnimStyle animStyle;
  final double speed;
  final int loopCycles;
  final int holdMs;
  final int holdLastFrameMs;
  final int msPerFrame;
  final double minMoveDistance;
  final double maxMoveDistance;

  static const frameSize = 50.0;
  static const displayScale = 2.6;

  static Size get displaySize => Size(
        frameSize * displayScale,
        frameSize * displayScale,
      );

  Duration get holdDuration {
    if (holdMs > 0) return Duration(milliseconds: holdMs);
    return switch (animStyle) {
      CatAnimStyle.playOnceHoldLast => Duration(
          milliseconds: msPerFrame * frameCount + holdLastFrameMs,
        ),
      CatAnimStyle.loop => Duration(
          milliseconds: msPerFrame * frameCount * loopCycles,
        ),
      CatAnimStyle.single => Duration(milliseconds: holdMs),
    };
  }

  bool get loopsWhilePlaying =>
      moves || animStyle == CatAnimStyle.loop;
}

class CatSpriteWidget extends StatelessWidget {
  const CatSpriteWidget({
    super.key,
    required this.action,
    required this.frameIndex,
    required this.facingRight,
    this.squashX = 1,
    this.squashY = 1,
  });

  final CatAction action;
  final int frameIndex;
  final bool facingRight;
  final double squashX;
  final double squashY;

  @override
  Widget build(BuildContext context) {
    final scale = CatAction.displayScale;
    final frame = CatAction.frameSize * scale;
    final sheetWidth = frame * action.frameCount;
    final index = frameIndex.clamp(0, action.frameCount - 1);

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(facingRight ? squashX : -squashX, squashY),
      child: SizedBox(
        width: frame,
        height: frame,
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            minWidth: frame,
            maxWidth: sheetWidth,
            maxHeight: frame,
            child: Transform.translate(
              offset: Offset(-index * frame, 0),
              child: Image.asset(
                action.asset,
                width: sheetWidth,
                height: frame,
                filterQuality: FilterQuality.none,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
