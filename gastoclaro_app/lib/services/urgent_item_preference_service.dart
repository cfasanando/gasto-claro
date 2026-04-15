import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class UrgentItemPreferenceService {
  static const String _storageKey = 'dashboard_manual_urgency';

  Future<Map<String, String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);

    if (raw == null || raw.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(raw);

      if (decoded is! Map) {
        return {};
      }

      return decoded.map(
            (key, value) => MapEntry(
          key.toString(),
          value.toString(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> setPriority(String itemKey, String priority) async {
    final data = await getAll();
    data[itemKey] = priority;
    await _save(data);
  }

  Future<void> clearPriority(String itemKey) async {
    final data = await getAll();
    data.remove(itemKey);
    await _save(data);
  }

  Future<void> _save(Map<String, String> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data));
  }
}