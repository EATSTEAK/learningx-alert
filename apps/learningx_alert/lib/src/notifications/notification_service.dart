import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:learningx_api/learningx_api.dart';
import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../storage/app_settings_store.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    timezone_data.initializeTimeZones();
    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(const InitializationSettings(android: android, iOS: ios));

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  Future<void> scheduleLearningItems(
    List<LearningItem> items,
    NotificationSettings settings,
  ) async {
    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final item in items) {
      final dueAt = item.dueAt;
      if (dueAt == null || item.isCompleted) continue;
      for (final offset in settings.offsets) {
        final scheduledAt = dueAt.toLocal().subtract(offset);
        if (!scheduledAt.isAfter(now)) continue;
        await _plugin.zonedSchedule(
          _stableId('${item.id}:${offset.inMinutes}'),
          _titleForOffset(offset),
          '${item.title} 마감: ${_formatDue(dueAt)}',
          tz.TZDateTime.from(scheduledAt, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'learningx_deadlines',
              'LearningX deadlines',
              channelDescription: 'Assignment and learning item deadline reminders.',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
  }
}

int _stableId(String value) {
  var hash = 0;
  for (final codeUnit in value.codeUnits) {
    hash = 0x1fffffff & (hash + codeUnit);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= hash >> 6;
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= hash >> 11;
  hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  return max(1, hash);
}

String _titleForOffset(Duration offset) {
  if (offset.inHours >= 24) return '마감 ${offset.inDays}일 전';
  if (offset.inHours >= 1) return '마감 ${offset.inHours}시간 전';
  return '마감 ${offset.inMinutes}분 전';
}

String _formatDue(DateTime dueAt) {
  final local = dueAt.toLocal();
  return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
