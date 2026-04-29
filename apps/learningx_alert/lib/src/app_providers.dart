import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:learningx_api/learningx_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final next = NotificationSettings(offsets: offsets);
    await ref.read(settingsStoreProvider).writeNotificationSettings(next);
    state = AsyncData(next);
  }
}

final learningItemsProvider = FutureProvider<List<LearningItem>>((ref) async {
  final token = await ref.watch(accessTokenProvider.future);
  final cache = ref.watch(learningItemCacheProvider);

  if (token == null || token.isEmpty) {
    return cache.readItems();
  }

  final settings = await ref.watch(notificationSettingsProvider.future);
  final api = LearningXApiClient(accessToken: token);
  final items = await api.getUpcomingLearningItems(daysAhead: 60);

  await cache.writeItems(items);
  await cache.writeLastSync(DateTime.now());
  ref.invalidate(lastSyncProvider);
  await ref
      .watch(notificationServiceProvider)
      .scheduleLearningItems(items, settings);

  return items;
});

final lastSyncProvider = Provider<DateTime?>((ref) {
  return ref.watch(learningItemCacheProvider).readLastSync();
});

String encodeLearningItems(List<LearningItem> items) {
  return jsonEncode(items.map((item) => item.toJson()).toList());
}
