import 'dart:convert';

import 'package:learningx_api/learningx_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LearningItemCache {
  const LearningItemCache(this._preferences);

  static const _itemsKey = 'cached_learning_items';
  static const _coursesKey = 'cached_canvas_courses';
  static const _announcementsKey = 'cached_announcements';
  static const _gradedSubmissionsKey = 'cached_graded_submissions';
  static const _lastSyncKey = 'last_sync_at';

  final SharedPreferences _preferences;

  List<LearningItem> readItems() {
    return _readList(_itemsKey, (item) => LearningItem.fromJson(item));
  }

  Future<void> writeItems(List<LearningItem> items) {
    final raw = jsonEncode(
      items.map((item) => item.toJson()).toList(growable: false),
    );
    return _preferences.setString(_itemsKey, raw);
  }

  List<CanvasCourse> readCourses() {
    return _readList(_coursesKey, (item) => CanvasCourse.fromJson(item));
  }

  Future<void> writeCourses(List<CanvasCourse> courses) {
    final raw = jsonEncode(
      courses.map((course) => course.toJson()).toList(growable: false),
    );
    return _preferences.setString(_coursesKey, raw);
  }

  List<AnnouncementItem> readAnnouncements() {
    return _readList(
      _announcementsKey,
      (item) => AnnouncementItem.fromJson(item),
    );
  }

  Future<void> writeAnnouncements(List<AnnouncementItem> announcements) {
    final raw = jsonEncode(
      announcements.map((item) => item.toJson()).toList(growable: false),
    );
    return _preferences.setString(_announcementsKey, raw);
  }

  List<GradedSubmissionItem> readGradedSubmissions() {
    return _readList(
      _gradedSubmissionsKey,
      (item) => GradedSubmissionItem.fromJson(item),
    );
  }

  Future<void> writeGradedSubmissions(List<GradedSubmissionItem> submissions) {
    final raw = jsonEncode(
      submissions.map((item) => item.toJson()).toList(growable: false),
    );
    return _preferences.setString(_gradedSubmissionsKey, raw);
  }

  DateTime? readLastSync() {
    final raw = _preferences.getString(_lastSyncKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeLastSync(DateTime value) {
    return _preferences.setString(
      _lastSyncKey,
      value.toUtc().toIso8601String(),
    );
  }

  Future<void> clear() async {
    await _preferences.remove(_itemsKey);
    await _preferences.remove(_coursesKey);
    await _preferences.remove(_announcementsKey);
    await _preferences.remove(_gradedSubmissionsKey);
    await _preferences.remove(_lastSyncKey);
  }

  List<T> _readList<T>(
    String key,
    T Function(Map<String, dynamic> item) decode,
  ) {
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) => decode(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }
}
