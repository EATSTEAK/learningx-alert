import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learningx_api/learningx_api.dart';

import '../../app_providers.dart';
import '../../storage/app_settings_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: const SettingsView(),
    );
  }
}

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    final notificationsEnabled = ref.watch(notificationPermissionProvider);
    final pendingCount = ref.watch(pendingNotificationCountProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: const Text('Canvas API'),
            subtitle: const Text(LearningXApiClient.defaultBaseUrl),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('알림 상태'),
                subtitle: Text(
                  [
                    '권한: ${notificationsEnabled.statusText}',
                    '예약된 알림: ${pendingCount.countText}',
                  ].join('\n'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ref
                          .read(notificationServiceProvider)
                          .showTestNotification();
                      ref.invalidate(notificationPermissionProvider);
                      ref.invalidate(pendingNotificationCountProvider);
                    },
                    icon: const Icon(Icons.notifications_active_outlined),
                    label: const Text('테스트 알림 보내기'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('마감 알림', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        settings.when(
          data: (value) => Column(
            children: [
              _OffsetSwitchTile(
                settings: value,
                offset: const Duration(days: 7),
                label: '마감 7일 전',
              ),
              _OffsetSwitchTile(
                settings: value,
                offset: const Duration(hours: 24),
                label: '마감 24시간 전',
              ),
              _OffsetSwitchTile(
                settings: value,
                offset: const Duration(hours: 3),
                label: '마감 3시간 전',
              ),
              _OffsetSwitchTile(
                settings: value,
                offset: const Duration(hours: 1),
                label: '마감 1시간 전',
              ),
              _OffsetSwitchTile(
                settings: value,
                offset: const Duration(minutes: 15),
                label: '마감 15분 전',
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: value.announcementAlertsEnabled,
                onChanged: (enabled) => ref
                    .read(notificationSettingsProvider.notifier)
                    .setAnnouncementAlertsEnabled(enabled),
                secondary: const Icon(Icons.campaign_outlined),
                title: const Text('새 공지 알림'),
              ),
              SwitchListTile(
                value: value.gradeAlertsEnabled,
                onChanged: (enabled) => ref
                    .read(notificationSettingsProvider.notifier)
                    .setGradeAlertsEnabled(enabled),
                secondary: const Icon(Icons.grade_outlined),
                title: const Text('성적 업데이트 알림'),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Text('설정을 불러오지 못했습니다: $error'),
        ),
        const SizedBox(height: 24),
        FilledButton.tonalIcon(
          onPressed: () {
            ref.invalidate(learningDashboardProvider);
            ref.invalidate(pendingNotificationCountProvider);
          },
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('동기화 및 알림 다시 예약'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            await ref.read(accessTokenProvider.notifier).clear();
            if (context.mounted) context.go('/login');
          },
          icon: const Icon(Icons.logout),
          label: const Text('로그아웃'),
        ),
      ],
    );
  }
}

class _OffsetSwitchTile extends ConsumerWidget {
  const _OffsetSwitchTile({
    required this.settings,
    required this.offset,
    required this.label,
  });

  final NotificationSettings settings;
  final Duration offset;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SwitchListTile(
      value: settings.contains(offset),
      onChanged: (enabled) => ref
          .read(notificationSettingsProvider.notifier)
          .setOffsetEnabled(offset, enabled),
      title: Text(label),
    );
  }
}

extension _PermissionText on AsyncValue<bool?> {
  String get statusText {
    return when(
      data: (value) => switch (value) {
        true => '허용됨',
        false => '차단됨',
        null => '확인 불가',
      },
      loading: () => '확인 중',
      error: (_, _) => '확인 실패',
    );
  }
}

extension _PendingCountText on AsyncValue<int> {
  String get countText {
    return when(
      data: (value) => '$value개',
      loading: () => '확인 중',
      error: (_, _) => '확인 실패',
    );
  }
}
