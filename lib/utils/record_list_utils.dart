import '../models/decision_record.dart';

List<DecisionRecord> filterRecordsByTags(
  List<DecisionRecord> records,
  Set<String> activeTagIds,
) {
  if (activeTagIds.isEmpty) return records;
  return records
      .where((record) => record.tags.any(activeTagIds.contains))
      .toList();
}
