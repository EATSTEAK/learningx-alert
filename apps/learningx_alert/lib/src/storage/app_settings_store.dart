import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettings {
  const NotificationSettings({this.offsets = defaultOffsets});

  static const defaultOffsets = [Duration(hours: 24), Duration(hours: 1)];

  final List<Duration> offsets;

  bool contains(Duration offset) => offsets.contains(offset);
}

class AppSettingsStore {
  const AppSettingsStore(this._preferences);

  static const _offsetsKey = 'notification_offsets_minutes';

  final SharedPreferences _preferences;

  Future<NotificationSettings> readNotificationSettings() async {
    final minutes = _preferences.getStringList(_offsetsKey);
    if (minutes == null || minutes.isEmpty) return const NotificationSettings();
    final offsets = minutes
        .map(int.tryParse)
        .whereType<int>()
        .where((value) => value > 0)
        .map((value) => Duration(minutes: value))
        .toList(growable: false);
    return NotificationSettings(offsets: offsets.isEmpty ? NotificationSettings.defaultOffsets : offsets);
  }

  Future<void> writeNotificationSettings(NotificationSettings settings) {
    return _preferences.setStringList(
      _offsetsKey,
      settings.offsets.map((offset) => offset.inMinutes.toString()).toList(growable: false),
    );
  }
}
