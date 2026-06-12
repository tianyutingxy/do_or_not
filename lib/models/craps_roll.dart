import 'dart:math';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'decision.dart';

/// Craps 开局掷骰展示：DO = 7/11（天牌），NOT = 2/3/12（投枪）。
/// 决策概率由上层 50/50 决定；此处仅在同类结果内随机展示点数组合。
class CrapsRoll {
  const CrapsRoll({
    required this.die1,
    required this.die2,
    required this.total,
    required this.isNatural,
  });

  final int die1;
  final int die2;
  final int total;
  final bool isNatural;

  String flavorTitle(AppLocalizations l10n) =>
      isNatural ? l10n.diceNaturalTitle : l10n.diceCrapsTitle;

  String detailLine(AppLocalizations l10n) => l10n.diceRollDetail(total);

  static final _rng = Random();

  static CrapsRoll randomFor(Decision decision) {
    if (decision.isDo) {
      final total = _rng.nextBool() ? 7 : 11;
      final pair = _randomPairForTotal(total);
      return CrapsRoll(
        die1: pair.$1,
        die2: pair.$2,
        total: total,
        isNatural: true,
      );
    }

    const crapsTotals = [2, 3, 12];
    final total = crapsTotals[_rng.nextInt(crapsTotals.length)];
    final pair = _randomPairForTotal(total);
    return CrapsRoll(
      die1: pair.$1,
      die2: pair.$2,
      total: total,
      isNatural: false,
    );
  }

  static (int, int) _randomPairForTotal(int total) {
    final pairs = <(int, int)>[];
    for (var a = 1; a <= 6; a++) {
      for (var b = 1; b <= 6; b++) {
        if (a + b == total) pairs.add((a, b));
      }
    }
    return pairs[_rng.nextInt(pairs.length)];
  }
}
