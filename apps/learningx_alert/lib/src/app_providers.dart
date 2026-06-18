import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:learningx_api/learningx_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dashboard/learning_dashboard_state.dart';
import 'notifications/notification_service.dart';
import 'storage/app_settings_store.dart';
import 'storage/learning_item_cache.dart';
import 'storage/token_store.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main.');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
});

final tokenStoreProvider = Provider<TokenStore>((ref) {
  return TokenStore(ref.watch(secureStorageProvider));
});

final settingsStoreProvider = Provider<AppSettingsStore>((ref) {
  return AppSettingsStore(ref.watch(sharedPreferencesProvider));
});

final learningItemCacheProvider = Provider<LearningItemCache>((ref) {
  return LearningItemCache(ref.watch(sharedPreferencesProvider));
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('NotificationService must be overridden in main.');
});

final accessTokenProvider =
    AsyncNotifierProvider<AccessTokenController, String?>(
      AccessTokenController.new,
    );

class AccessTokenController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => ref.watch(tokenStoreProvider).readAccessToken();

  Future<void> save(String token) async {
    state = const AsyncLoading();
    await ref.read(tokenStoreProvider).writeAccessToken(token);
    state = AsyncData(token);
  }

  Future<void> clear() async {
    await ref.read(tokenStoreProvider).deleteAccessToken();
    await ref.read(learningItemCacheProvider).clear();
    await ref.read(notificationServiceProvider).cancelAll();
    state = const AsyncData(null);
    ref.invalidate(learningDashboardProvider);
    ref.invalidate(lastSyncProvider);
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsController, NotificationSettings>(
      NotificationSettingsController.new,
    );

class NotificationSettingsController
    extends AsyncNotifier<NotificationSettings> {
  @override
  Future<NotificationSettings> build() =>
      ref.watch(settingsStoreProvider).readNotificationSettings();

  Future<void> setOffsetEnabled(Duration offset, bool enabled) async {
    final current = await future;
    final offsets = [...current.offsets];
    if (enabled && !offsets.contains(offset)) offsets.add(offset);
    if (!enabled) offsets.remove(offset);
    offsets.sort((a, b) => b.compareTo(a));
    final next = current.copyWith(offsets: offsets);
    await ref.read(settingsStoreProvider).writeNotificationSettings(next);
    state = AsyncData(next);
    ref.invalidate(learningDashboardProvider);
  }

  Future<void> setAnnouncementAlertsEnabled(bool enabled) async {
    final current = await future;
    final next = current.copyWith(announcementAlertsEnabled: enabled);
    await ref.read(settingsStoreProvider).writeNotificationSettings(next);
    state = AsyncData(next);
  }

  Future<void> setGradeAlertsEnabled(bool enabled) async {
    final current = await future;
    final next = current.copyWith(gradeAlertsEnabled: enabled);
    await ref.read(settingsStoreProvider).writeNotificationSettings(next);
    state = AsyncData(next);
  }
}

final learningDashboardProvider =
    AsyncNotifierProvider<LearningDashboardController, LearningDashboardState>(
      LearningDashboardController.new,
    );

class LearningDashboardController
    extends AsyncNotifier<LearningDashboardState> {
  @override
  Future<LearningDashboardState> build() => _sync();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await _sync());
  }

  Future<LearningDashboardState> _sync() async {
    final token = await ref.watch(accessTokenProvider.future);
    final cache = ref.watch(learningItemCacheProvider);
    final cached = _readCachedDashboard(cache);

    if (token == null || token.isEmpty) return cached;

    final settings = await ref.watch(notificationSettingsProvider.future);
    final api = LearningXApiClient(accessToken: token);
    final errors = <DashboardSectionError>[];
    var courses = cached.courses;
    var deadlines = cached.deadlines;
    var announcements = cached.announcements;
    var gradedSubmissions = cached.gradedSubmissions;
    var hadSuccessfulNetworkSection = false;

    try {
      courses = await api.getActiveCourses();
      await cache.writeCourses(courses);
      hadSuccessfulNetworkSection = true;
    } catch (error) {
      errors.add(_sectionError(DashboardSection.courses, error));
    }

    try {
      deadlines = await api.getUpcomingLearningItems(daysAhead: 60);
      await cache.writeItems(deadlines);
      await ref
          .read(notificationServiceProvider)
          .scheduleLearningItems(deadlines, settings);
      hadSuccessfulNetworkSection = true;
    } catch (error) {
      errors.add(_sectionError(DashboardSection.deadlines, error));
    }

    if (courses.isNotEmpty) {
      final nextAnnouncements = <AnnouncementItem>[];
      final announcementErrors = <DashboardSectionError>[];
      for (final course in courses) {
        try {
          nextAnnouncements.addAll(
            await api.getAnnouncementsForCourse(course, daysBack: 30),
          );
        } catch (error) {
          announcementErrors.add(
            _sectionError(
              DashboardSection.announcements,
              error,
              courseName: course.name,
            ),
          );
        }
      }
      if (nextAnnouncements.isNotEmpty ||
          announcementErrors.length < courses.length) {
        announcements = nextAnnouncements
          ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
        await cache.writeAnnouncements(announcements);
        hadSuccessfulNetworkSection = true;
      }
      errors.addAll(announcementErrors);
    }

    if (courses.isNotEmpty) {
      final nextSubmissions = <GradedSubmissionItem>[];
      final gradeErrors = <DashboardSectionError>[];
      for (final course in courses) {
        try {
          nextSubmissions.addAll(
            await api.getGradedSubmissionsForCourse(course, daysBack: 120),
          );
        } catch (error) {
          gradeErrors.add(
            _sectionError(
              DashboardSection.grades,
              error,
              courseName: course.name,
            ),
          );
        }
      }
      if (nextSubmissions.isNotEmpty || gradeErrors.length < courses.length) {
        nextSubmissions.sort(_compareSubmissions);
        gradedSubmissions = nextSubmissions;
        await cache.writeGradedSubmissions(gradedSubmissions);
        hadSuccessfulNetworkSection = true;
      }
      errors.addAll(gradeErrors);
    }

    final shouldNotifyChanges = cached.lastSyncAt != null;
    final newAnnouncementIds = _newAnnouncementIds(
      previous: cached.announcements,
      next: announcements,
    );
    final changedGradeIds = _changedGradeIds(
      previous: cached.gradedSubmissions,
      next: gradedSubmissions,
    );
    final changedDeadlineIds = _changedDeadlineIds(
      previous: cached.deadlines,
      next: deadlines,
    );

    if (shouldNotifyChanges) {
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.showNewAnnouncementNotifications(
        announcements
            .where((item) => newAnnouncementIds.contains(item.id))
            .toList(growable: false),
        settings,
      );
      await notificationService.showGradeUpdateNotifications(
        gradedSubmissions
            .where((item) => changedGradeIds.contains(item.id))
            .toList(growable: false),
        settings,
      );
    }

    DateTime? lastSyncAt = cached.lastSyncAt;
    if (hadSuccessfulNetworkSection) {
      lastSyncAt = DateTime.now();
      await cache.writeLastSync(lastSyncAt);
      ref.invalidate(lastSyncProvider);
    }

    return LearningDashboardState(
      courses: courses,
      deadlines: deadlines,
      announcements: announcements,
      gradedSubmissions: gradedSubmissions,
      lastSyncAt: lastSyncAt,
      sectionErrors: errors,
      newAnnouncementIds: newAnnouncementIds,
      changedGradeIds: changedGradeIds,
      changedDeadlineIds: changedDeadlineIds,
    );
  }
}

final learningItemsProvider = FutureProvider<List<LearningItem>>((ref) async {
  final dashboard = await ref.watch(learningDashboardProvider.future);
  return dashboard.deadlines;
});

final lastSyncProvider = Provider<DateTime?>((ref) {
  return ref.watch(learningItemCacheProvider).readLastSync();
});

String encodeLearningItems(List<LearningItem> items) {
  return jsonEncode(items.map((item) => item.toJson()).toList());
}

final notificationPermissionProvider = FutureProvider<bool?>((ref) {
  return ref.watch(notificationServiceProvider).areNotificationsEnabled();
});

final pendingNotificationCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationServiceProvider).pendingNotificationCount();
});

LearningDashboardState _readCachedDashboard(LearningItemCache cache) {
  return LearningDashboardState(
    courses: cache.readCourses(),
    deadlines: cache.readItems(),
    announcements: cache.readAnnouncements(),
    gradedSubmissions: cache.readGradedSubmissions(),
    lastSyncAt: cache.readLastSync(),
  );
}

DashboardSectionError _sectionError(
  DashboardSection section,
  Object error, {
  String? courseName,
}) {
  return DashboardSectionError(
    section: section,
    courseName: courseName,
    message: error.toString(),
  );
}

Set<String> _newAnnouncementIds({
  required List<AnnouncementItem> previous,
  required List<AnnouncementItem> next,
}) {
  final previousIds = previous.map((item) => item.id).toSet();
  return next
      .where((item) => !previousIds.contains(item.id))
      .map((item) => item.id)
      .toSet();
}

Set<String> _changedGradeIds({
  required List<GradedSubmissionItem> previous,
  required List<GradedSubmissionItem> next,
}) {
  final previousById = {for (final item in previous) item.id: item};
  return next
      .where((item) {
        final old = previousById[item.id];
        if (old == null) return true;
        return old.score != item.score ||
            old.grade != item.grade ||
            old.status != item.status ||
            old.late != item.late ||
            old.missing != item.missing;
      })
      .map((item) => item.id)
      .toSet();
}

Set<String> _changedDeadlineIds({
  required List<LearningItem> previous,
  required List<LearningItem> next,
}) {
  final previousById = {for (final item in previous) item.id: item};
  return next
      .where((item) {
        final old = previousById[item.id];
        if (old == null) return true;
        return old.dueAt != item.dueAt ||
            old.title != item.title ||
            old.isCompleted != item.isCompleted;
      })
      .map((item) => item.id)
      .toSet();
}

int _compareSubmissions(GradedSubmissionItem a, GradedSubmissionItem b) {
  final aDate = a.gradedAt ?? a.submittedAt;
  final bDate = b.gradedAt ?? b.submittedAt;
  if (aDate == null && bDate == null) {
    return a.assignmentName.compareTo(b.assignmentName);
  }
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  return bDate.compareTo(aDate);
}
