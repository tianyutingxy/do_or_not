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
