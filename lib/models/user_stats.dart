import 'decision.dart';

class UserStats {
  const UserStats({this.doCount = 0, this.notCount = 0});

  final int doCount;
  final int notCount;

  int get total => doCount + notCount;

  double get doRatio => total == 0 ? 0.5 : doCount / total;

  double get doPercent => doRatio * 100;

  String get personalityLabel {
    if (total == 0) return '还没有记录，去决定一次吧';
    if (doPercent >= 70) return '你是坚定的 DO 派';
    if (doPercent >= 55) return '你偏向 DO，但也会犹豫';
    if (doPercent >= 45) return '你在 DO 与 NOT 之间很平衡';
    if (doPercent >= 30) return '你偏向 NOT，三思而后行';
    return '你是冷静的 NOT 派';
  }

  UserStats increment(Decision decision) {
    return UserStats(
      doCount: doCount + (decision.isDo ? 1 : 0),
      notCount: notCount + (decision.isDo ? 0 : 1),
    );
  }

  Map<String, int> toJson() => {'do': doCount, 'not': notCount};

  factory UserStats.fromJson(Map<String, int> json) {
    return UserStats(
      doCount: json['do'] ?? 0,
      notCount: json['not'] ?? 0,
    );
  }
}