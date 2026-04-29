import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learningx_api/learningx_api.dart';

import '../../app_providers.dart';
import '../../storage/app_settings_store.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notificationSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
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
          Text('알림 시점', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          settings.when(
            data: (value) => Column(
              children: [
                _OffsetSwitchTile(settings: value, offset: const Duration(hours: 24), label: '마감 24시간 전'),
                _OffsetSwitchTile(settings: value, offset: const Duration(hours: 1), label: '마감 1시간 전'),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('설정을 불러오지 못했습니다: $error'),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            onPressed: () => ref.invalidate(learningItemsProvider),
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('알림 다시 예약'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () async {
              await ref.read(accessTokenProvider.notifier).clear();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
            label: const Text('로그아웃'),
          ),
        ],
      ),
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
      onChanged: (enabled) => ref.read(notificationSettingsProvider.notifier).setOffsetEnabled(offset, enabled),
      title: Text(label),
    );
  }
}
