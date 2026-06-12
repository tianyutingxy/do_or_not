import 'animation_style.dart';
import 'decision.dart';
import 'user_response.dart';

class DecisionRecord {
  const DecisionRecord({
    this.id,
    required this.decidedAt,
    required this.revealStyle,
    required this.objectiveDecision,
    required this.userResponse,
    required this.finalDecision,
    required this.retryCount,
    this.isMarked = false,
    this.reflection,
    this.reflectionUpdatedAt,
    required this.createdAt,
  });

  final int? id;
  final DateTime decidedAt;
  final RevealStyle revealStyle;
  final Decision objectiveDecision;
  final UserResponse userResponse;
  final Decision finalDecision;
  final int retryCount;
  final bool isMarked;
  final String? reflection;
  final DateTime? reflectionUpdatedAt;
  final DateTime createdAt;

  DecisionRecord copyWith({
    int? id,
    DateTime? decidedAt,
    RevealStyle? revealStyle,
    Decision? objectiveDecision,
    UserResponse? userResponse,
    Decision? finalDecision,
    int? retryCount,
    bool? isMarked,
    String? reflection,
    DateTime? reflectionUpdatedAt,
    bool clearReflection = false,
    DateTime? createdAt,
  }) {
    return DecisionRecord(
      id: id ?? this.id,
      decidedAt: decidedAt ?? this.decidedAt,
      revealStyle: revealStyle ?? this.revealStyle,
      objectiveDecision: objectiveDecision ?? this.objectiveDecision,
      userResponse: userResponse ?? this.userResponse,
      finalDecision: finalDecision ?? this.finalDecision,
      retryCount: retryCount ?? this.retryCount,
      isMarked: isMarked ?? this.isMarked,
      reflection: clearReflection ? null : (reflection ?? this.reflection),
      reflectionUpdatedAt:
          clearReflection ? null : (reflectionUpdatedAt ?? this.reflectionUpdatedAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DecisionRecord.fromRow(Map<String, Object?> row) {
    return DecisionRecord(
      id: row['id'] as int?,
      decidedAt: DateTime.fromMillisecondsSinceEpoch(row['decided_at']! as int),
      revealStyle: RevealStyle.values.byName(row['reveal_style']! as String),
      objectiveDecision:
          Decision.values.byName(row['objective_decision']! as String),
      userResponse: UserResponse.values.byName(row['user_response']! as String),
      finalDecision: Decision.values.byName(row['final_decision']! as String),
      retryCount: row['retry_count']! as int,
      isMarked: (row['is_marked']! as int) == 1,
      reflection: row['reflection'] as String?,
      reflectionUpdatedAt: row['reflection_updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row['reflection_updated_at']! as int,
            ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at']! as int),
    );
  }

  Map<String, Object?> toRow({bool includeId = false}) {
    return {
      if (includeId && id != null) 'id': id,
      'decided_at': decidedAt.millisecondsSinceEpoch,
      'reveal_style': revealStyle.name,
      'objective_decision': objectiveDecision.name,
      'user_response': userResponse.name,
      'final_decision': finalDecision.name,
      'retry_count': retryCount,
      'is_marked': isMarked ? 1 : 0,
      'reflection': reflection,
      'reflection_updated_at': reflectionUpdatedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
