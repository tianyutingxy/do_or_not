import 'dart:convert';

/// 决策记录现场照片，固定 3 个槽位。
class RecordPhotoPaths {
  RecordPhotoPaths._();

  static const slotCount = 3;

  static List<String?> empty() => List<String?>.filled(slotCount, null);

  static List<String?> normalize(List<String?>? paths) {
    final base = List<String?>.from(paths ?? empty());
    while (base.length < slotCount) {
      base.add(null);
    }
    if (base.length > slotCount) {
      return base.sublist(0, slotCount);
    }
    return base;
  }

  static String? encode(List<String?> paths) {
    return jsonEncode(normalize(paths));
  }

  static List<String?> decode(String? raw) {
    if (raw == null || raw.isEmpty) return empty();
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return normalize(list.map((item) => item as String?).toList());
    } catch (_) {
      return empty();
    }
  }
}
