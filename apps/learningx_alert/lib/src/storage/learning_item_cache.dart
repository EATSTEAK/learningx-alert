import 'dart:convert';

import 'package:learningx_api/learningx_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearningItemCache {
  const LearningItemCache(this._preferences);

  static const _itemsKey = 'cached_learning_items';
  static const _lastSyncKey = 'last_sync_at';

  final SharedPreferences _preferences;

  List<LearningItem> readItems() {
    final raw = _preferences.getString(_itemsKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => LearningItem.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<void> writeItems(List<LearningItem> items) {
    final raw = jsonEncode(items.map((item) => item.toJson()).toList(growable: false));
    return _preferences.setString(_itemsKey, raw);
  }

  DateTime? readLastSync() {
    final raw = _preferences.getString(_lastSyncKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeLastSync(DateTime value) {
    return _preferences.setString(_lastSyncKey, value.toUtc().toIso8601String());
  }

  Future<void> clear() async {
    await _preferences.remove(_itemsKey);
    await _preferences.remove(_lastSyncKey);
  }
}
