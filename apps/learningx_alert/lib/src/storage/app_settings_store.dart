import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  const NotificationSettings({
    this.offsets = defaultOffsets,
    this.announcementAlertsEnabled = true,
    this.gradeAlertsEnabled = true,
  });

  static const defaultOffsets = [
    Duration(days: 7),
    Duration(hours: 24),
    Duration(hours: 3),
    Duration(hours: 1),
    Duration(minutes: 15),
  ];

  final List<Duration> offsets;
  final bool announcementAlertsEnabled;
  final bool gradeAlertsEnabled;

  bool contains(Duration offset) => offsets.contains(offset);

  NotificationSettings copyWith({
    List<Duration>? offsets,
    bool? announcementAlertsEnabled,
    bool? gradeAlertsEnabled,
  }) {
    return NotificationSettings(
      offsets: offsets ?? this.offsets,
      announcementAlertsEnabled:
          announcementAlertsEnabled ?? this.announcementAlertsEnabled,
      gradeAlertsEnabled: gradeAlertsEnabled ?? this.gradeAlertsEnabled,
    );
  }
}

class AppSettingsStore {
  const AppSettingsStore(this._preferences);

  static const _offsetsKey = 'notification_offsets_minutes';
  static const _announcementAlertsKey = 'announcement_alerts_enabled';
  static const _gradeAlertsKey = 'grade_alerts_enabled';

  final SharedPreferences _preferences;

  Future<NotificationSettings> readNotificationSettings() async {
    final minutes = _preferences.getStringList(_offsetsKey);
    final offsets = (minutes ?? const [])
        .map(int.tryParse)
        .whereType<int>()
        .where((value) => value > 0)
        .map((value) => Duration(minutes: value))
        .toList(growable: false);
    return NotificationSettings(
      offsets: offsets.isEmpty ? NotificationSettings.defaultOffsets : offsets,
      announcementAlertsEnabled:
          _preferences.getBool(_announcementAlertsKey) ?? true,
      gradeAlertsEnabled: _preferences.getBool(_gradeAlertsKey) ?? true,
    );
  }

  Future<void> writeNotificationSettings(NotificationSettings settings) async {
    await _preferences.setStringList(
      _offsetsKey,
      settings.offsets
          .map((offset) => offset.inMinutes.toString())
          .toList(growable: false),
    );
    await _preferences.setBool(
      _announcementAlertsKey,
      settings.announcementAlertsEnabled,
    );
    await _preferences.setBool(_gradeAlertsKey, settings.gradeAlertsEnabled);
  }
}
