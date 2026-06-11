import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/decision.dart';
import '../models/user_stats.dart';

class StatsService {
  static const _statsKey = 'user_stats';
  static const _styleKey = 'animation_style';

  Future<UserStats> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statsKey);
    if (raw == null) return const UserStats();
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return UserStats.fromJson(
        map.map((k, v) => MapEntry(k, v as int)),
      );
    } catch (_) {
      return const UserStats();
    }
  }

  Future<void> saveStats(UserStats stats) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_statsKey, jsonEncode(stats.toJson()));
  }

  Future<UserStats> record(Decision decision) async {
    final stats = await loadStats();
    final updated = stats.increment(decision);
    await saveStats(updated);
    return updated;
  }

  Future<String?> loadAnimationStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_styleKey);
  }

  Future<void> saveAnimationStyle(String style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_styleKey, style);
  }
}
