import 'dart:convert';

/// 决策标签，固定预设 ID，每条记录最多 3 个。
class RecordTags {
  RecordTags._();

  static const maxCount = 3;

  static const work = 'work';
  static const relationship = 'relationship';
  static const spending = 'spending';
  static const health = 'health';
  static const life = 'life';
  static const other = 'other';

  static const presets = [
    work,
    relationship,
    spending,
    health,
    life,
    other,
  ];

  static List<String> normalize(List<String>? tags) {
    final seen = <String>{};
    final result = <String>[];
    for (final tag in tags ?? const []) {
      if (!presets.contains(tag) || seen.contains(tag)) continue;
      seen.add(tag);
      result.add(tag);
      if (result.length >= maxCount) break;
    }
    return result;
  }

  static String? encode(List<String> tags) {
    final normalized = normalize(tags);
    if (normalized.isEmpty) return null;
    return jsonEncode(normalized);
  }

  static List<String> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return normalize(list.map((item) => item as String).toList());
    } catch (_) {
      return const [];
    }
  }
}
