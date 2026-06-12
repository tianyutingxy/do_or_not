import 'animation_style.dart';
import 'decision.dart';
import 'record_photo_paths.dart';
import 'user_response.dart';

class DecisionRecord {
  DecisionRecord({
    this.id,
    required this.decidedAt,
    required this.revealStyle,
    required this.objectiveDecision,
    required this.userResponse,
    required this.finalDecision,
    required this.retryCount,
    this.isMarked = false,
    this.isArchived = false,
    this.decisionContext,
    List<String?>? photoPaths,
    this.reflection,
    this.reflectionUpdatedAt,
    this.archivedAt,
    required this.createdAt,
  }) : photoPaths = RecordPhotoPaths.normalize(photoPaths);

  final int? id;
  final DateTime decidedAt;
  final RevealStyle revealStyle;
  final Decision objectiveDecision;
  final UserResponse userResponse;
  final Decision finalDecision;
  final int retryCount;
  final bool isMarked;
  final bool isArchived;
  final String? decisionContext;
  final List<String?> photoPaths;
  final String? reflection;
  final DateTime? reflectionUpdatedAt;
  final DateTime? archivedAt;
  final DateTime createdAt;

  /// 待回顾：已标记且未归档。
  bool get isPendingReview => isMarked && !isArchived;

  bool get isDemoExample =>
      reflection?.startsWith('【示例】') == true ||
      reflection?.startsWith('[Demo]') == true;

  DecisionRecord copyWith({
    int? id,
    DateTime? decidedAt,
    RevealStyle? revealStyle,
    Decision? objectiveDecision,
    UserResponse? userResponse,
    Decision? finalDecision,
    int? retryCount,
    bool? isMarked,
    bool? isArchived,
    String? decisionContext,
    List<String?>? photoPaths,
    String? reflection,
    DateTime? reflectionUpdatedAt,
    DateTime? archivedAt,
    bool clearDecisionContext = false,
    bool clearReflection = false,
    bool clearArchivedAt = false,
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
      isArchived: isArchived ?? this.isArchived,
      decisionContext: clearDecisionContext
          ? null
          : (decisionContext ?? this.decisionContext),
      photoPaths: photoPaths ?? this.photoPaths,
      reflection: clearReflection ? null : (reflection ?? this.reflection),
      reflectionUpdatedAt:
          clearReflection ? null : (reflectionUpdatedAt ?? this.reflectionUpdatedAt),
      archivedAt: clearArchivedAt ? null : (archivedAt ?? this.archivedAt),
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
      isArchived: (row['is_archived'] as int? ?? 0) == 1,
      decisionContext: row['decision_context'] as String?,
      photoPaths: RecordPhotoPaths.decode(row['photo_paths'] as String?),
      reflection: row['reflection'] as String?,
      reflectionUpdatedAt: row['reflection_updated_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              row['reflection_updated_at']! as int,
            ),
      archivedAt: row['archived_at'] == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(row['archived_at']! as int),
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
      'is_archived': isArchived ? 1 : 0,
      'decision_context': decisionContext,
      'photo_paths': RecordPhotoPaths.encode(photoPaths),
      'reflection': reflection,
      'reflection_updated_at': reflectionUpdatedAt?.millisecondsSinceEpoch,
      'archived_at': archivedAt?.millisecondsSinceEpoch,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
}
