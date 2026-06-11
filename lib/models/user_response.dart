import 'decision.dart';

enum UserResponse { comply, rebel, retry }

extension UserResponseX on UserResponse {
  /// 根据客观结果，计算用户最终计入统计的选择
  Decision finalDecision(Decision objective) => switch (this) {
        UserResponse.comply => objective,
        UserResponse.rebel => objective.opposite,
        UserResponse.retry => objective, // 不计入，仅占位
      };
}

extension DecisionOpposite on Decision {
  Decision get opposite => isDo ? Decision.notIt : Decision.doIt;
}
