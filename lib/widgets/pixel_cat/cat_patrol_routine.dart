import 'dart:math' as math;

import 'cat_sprites.dart';

/// 一次「回家」周期内的一拍：做什么动作。
class CatPatrolBeat {
  const CatPatrolBeat(this.action);

  final CatAction action;
}

/// 一整条遛弯剧本（预览 / 调试用）。
class CatPatrolRoutine {
  const CatPatrolRoutine(this.beats);

  final List<CatPatrolBeat> beats;
}

enum CatPosture { move, upright, lying, groom }

extension CatActionBehavior on CatAction {
  CatPosture get posture {
    if (moves) return CatPosture.move;
    return switch (this) {
      CatAction.laying ||
      CatAction.sleeping1 ||
      CatAction.sleeping2 =>
        CatPosture.lying,
      CatAction.meow ||
      CatAction.itch ||
      CatAction.licking1 ||
      CatAction.licking2 ||
      CatAction.stretching =>
        CatPosture.groom,
      _ => CatPosture.upright,
    };
  }

  /// 连续播放会像 bug 的相近动作
  bool isTooSimilar(CatAction other) {
    if (this == other) return true;
    if (posture == CatPosture.lying && other.posture == CatPosture.lying) {
      return true;
    }
    final selfLick = this == CatAction.licking1 || this == CatAction.licking2;
    final otherLick =
        other == CatAction.licking1 || other == CatAction.licking2;
    if (selfLick && otherLick) return true;
    if (this == CatAction.stretching && other == CatAction.stretching) {
      return true;
    }
    return false;
  }
}

class _WeightedAction {
  const _WeightedAction(this.action, this.weight);

  final CatAction action;
  final int weight;
}

/// 根据上一动作，用转移权重挑选下一动作（非纯随机）。
/// 主基调：到处走 + 趴睡；伸懒腰 / 理毛等点缀动作低频出现。
class CatPatrolRoutineGenerator {
  static const _groomActions = {
    CatAction.meow,
    CatAction.itch,
    CatAction.licking1,
    CatAction.licking2,
    CatAction.stretching,
  };

  /// 生成一整条预览序列（测试 / 调试）
  CatPatrolRoutine generate(math.Random rng, {int? seed, int beatCount = 6}) {
    final random = seed == null ? rng : math.Random(seed);
    final beats = <CatPatrolBeat>[];
    final recent = <CatAction>[];
    CatAction? previous;

    for (var i = 0; i < beatCount; i++) {
      final next = pickNext(random, previous: previous, recent: recent);
      beats.add(CatPatrolBeat(next));
      recent.add(next);
      if (recent.length > 4) recent.removeAt(0);
      previous = next;
    }
    return CatPatrolRoutine(beats);
  }

  /// 遛弯时逐步调用：根据上一拍选出自然衔接的下一拍。
  CatAction pickNext(
    math.Random random, {
    CatAction? previous,
    List<CatAction> recent = const [],
  }) {
    final pool = _candidates(previous);
    final filtered = pool.where((e) {
      if (previous != null && e.action.isTooSimilar(previous)) return false;
      for (final past in recent.reversed.take(2)) {
        if (e.action.isTooSimilar(past)) return false;
      }
      // 点缀动作：最近 3 拍内出现过就不再伸懒腰 / 理毛
      if (_groomActions.contains(e.action) && _recentlyGroomed(recent)) {
        return false;
      }
      return true;
    }).toList();

    final choices = filtered.isNotEmpty ? filtered : pool;
    return _weightedPick(random, choices);
  }

  bool _recentlyGroomed(List<CatAction> recent) {
    return recent.reversed
        .take(3)
        .any((a) => _groomActions.contains(a));
  }

  List<_WeightedAction> _candidates(CatAction? previous) {
    if (previous == null) {
      return const [
        _WeightedAction(CatAction.walk, 9),
        _WeightedAction(CatAction.run, 2),
        _WeightedAction(CatAction.laying, 2),
        _WeightedAction(CatAction.idle, 1),
        _WeightedAction(CatAction.sitting, 1),
        _WeightedAction(CatAction.sleeping1, 1),
      ];
    }

    return switch (previous.posture) {
      // 走完 / 跑完：继续溜达为主，偶尔趴一下
      CatPosture.move => const [
        _WeightedAction(CatAction.walk, 7),
        _WeightedAction(CatAction.run, 3),
        _WeightedAction(CatAction.laying, 4),
        _WeightedAction(CatAction.idle, 2),
        _WeightedAction(CatAction.sitting, 2),
        _WeightedAction(CatAction.sleeping1, 1),
        _WeightedAction(CatAction.meow, 1),
        _WeightedAction(CatAction.stretching, 1),
      ],
      // 站着 / 坐着：继续走为主
      CatPosture.upright => const [
        _WeightedAction(CatAction.walk, 8),
        _WeightedAction(CatAction.run, 3),
        _WeightedAction(CatAction.laying, 3),
        _WeightedAction(CatAction.idle, 2),
        _WeightedAction(CatAction.sitting, 2),
        _WeightedAction(CatAction.sleeping1, 1),
        _WeightedAction(CatAction.licking1, 1),
        _WeightedAction(CatAction.stretching, 1),
      ],
      // 趴睡完：起身继续溜达
      CatPosture.lying => const [
        _WeightedAction(CatAction.walk, 9),
        _WeightedAction(CatAction.run, 3),
        _WeightedAction(CatAction.idle, 2),
        _WeightedAction(CatAction.sitting, 2),
        _WeightedAction(CatAction.laying, 1),
        _WeightedAction(CatAction.stretching, 1),
      ],
      // 玩耍 / 理毛完：回到溜达主循环
      CatPosture.groom => const [
        _WeightedAction(CatAction.walk, 8),
        _WeightedAction(CatAction.run, 3),
        _WeightedAction(CatAction.laying, 3),
        _WeightedAction(CatAction.idle, 2),
        _WeightedAction(CatAction.sitting, 2),
        _WeightedAction(CatAction.sleeping1, 1),
      ],
    };
  }

  CatAction _weightedPick(math.Random random, List<_WeightedAction> pool) {
    final total = pool.fold<int>(0, (sum, e) => sum + e.weight);
    var roll = random.nextInt(total);
    for (final entry in pool) {
      roll -= entry.weight;
      if (roll < 0) return entry.action;
    }
    return pool.last.action;
  }
}
