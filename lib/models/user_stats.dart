import 'decision.dart';
import 'user_response.dart';

class UserStats {
  const UserStats({
    this.doCount = 0,
    this.notCount = 0,
    this.complyCount = 0,
    this.rebelCount = 0,
    this.retryPressCount = 0,
    this.totalRetriesBeforeFinal = 0,
  });

  final int doCount;
  final int notCount;
  final int complyCount;
  final int rebelCount;
  final int retryPressCount;
  final int totalRetriesBeforeFinal;

  int get total => doCount + notCount;

  int get finalizedCount => complyCount + rebelCount;

  double get doRatio => total == 0 ? 0.5 : doCount / total;

  double get doPercent => doRatio * 100;

  double get complyPercent =>
      finalizedCount == 0 ? 0 : complyCount / finalizedCount * 100;

  double get rebelPercent =>
      finalizedCount == 0 ? 0 : rebelCount / finalizedCount * 100;

  /// 每次落定前平均「再来一次」了几轮
  double get avgRetriesBeforeFinal => finalizedCount == 0
      ? 0
      : totalRetriesBeforeFinal / finalizedCount;

  String get doNotLabel {
    if (total == 0) return '还没有最终落定';
    if (doPercent >= 70) return '最终常选择 DO（做）';
    if (doPercent >= 55) return '略偏向 DO（做）';
    if (doPercent >= 45) return 'DO 与 NOT 大致均衡';
    if (doPercent >= 30) return '略偏向 NOT（不做）';
    return '最终常选择 NOT（不做）';
  }

  /// 基于遵从 / 反抗 / 犹豫三维度的性格画像
  String get attitudeLabel {
    if (finalizedCount == 0) return '';

    final complyRatio = complyCount / finalizedCount;
    final rebelRatio = rebelCount / finalizedCount;
    final avg = avgRetriesBeforeFinal;

    final String stance;
    if (complyRatio >= 0.6) {
      stance = '听从命运型';
    } else if (rebelRatio >= 0.6) {
      stance = '反骨逆袭型';
    } else if ((complyRatio - rebelRatio).abs() <= 0.15) {
      stance = '进退自如型';
    } else if (complyRatio > rebelRatio) {
      stance = '偏顺从型';
    } else {
      stance = '偏叛逆型';
    }

    final String hesitation;
    if (avg >= 2.5) {
      hesitation = '，总要多试几手才肯落定';
    } else if (avg >= 1.2) {
      hesitation = '，偶尔会犹豫再三';
    } else if (avg >= 0.4) {
      hesitation = '，很少需要重来';
    } else {
      hesitation = '，几乎一次定音';
    }

    return '$stance$hesitation';
  }

  String get personalityLabel {
    if (finalizedCount == 0) return '还没有记录，去决定一次吧';
    return attitudeLabel;
  }

  UserStats recordChoice({
    required Decision decision,
    required UserResponse response,
    required int retriesThisSession,
  }) {
    assert(response != UserResponse.retry);
    return UserStats(
      doCount: doCount + (decision.isDo ? 1 : 0),
      notCount: notCount + (decision.isDo ? 0 : 1),
      complyCount: complyCount + (response == UserResponse.comply ? 1 : 0),
      rebelCount: rebelCount + (response == UserResponse.rebel ? 1 : 0),
      retryPressCount: retryPressCount,
      totalRetriesBeforeFinal:
          totalRetriesBeforeFinal + retriesThisSession,
    );
  }

  UserStats recordRetryPress() {
    return UserStats(
      doCount: doCount,
      notCount: notCount,
      complyCount: complyCount,
      rebelCount: rebelCount,
      retryPressCount: retryPressCount + 1,
      totalRetriesBeforeFinal: totalRetriesBeforeFinal,
    );
  }

  Map<String, int> toJson() => {
        'do': doCount,
        'not': notCount,
        'comply': complyCount,
        'rebel': rebelCount,
        'retry': retryPressCount,
        'retryRoundsTotal': totalRetriesBeforeFinal,
      };

  factory UserStats.fromJson(Map<String, int> json) {
    return UserStats(
      doCount: json['do'] ?? 0,
      notCount: json['not'] ?? 0,
      complyCount: json['comply'] ?? 0,
      rebelCount: json['rebel'] ?? 0,
      retryPressCount: json['retry'] ?? 0,
      totalRetriesBeforeFinal: json['retryRoundsTotal'] ?? 0,
    );
  }
}
