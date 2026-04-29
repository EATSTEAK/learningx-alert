import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:learningx_api/learningx_api.dart';

import '../../app_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(learningItemsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(learningItemsProvider);
    final lastSync = ref.watch(lastSyncProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('마감 알림'),
        actions: [
          IconButton(
            tooltip: '새로고침',
            onPressed: () => ref.invalidate(learningItemsProvider),
            icon: const Icon(Icons.sync),
          ),
          IconButton(
            tooltip: '설정',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(learningItemsProvider.future),
        child: items.when(
          data: (value) => _LearningItemList(items: value, lastSync: lastSync),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(Icons.cloud_off, size: 40),
              const SizedBox(height: 12),
              Text('동기화 실패', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text('$error'),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => ref.invalidate(learningItemsProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearningItemList extends StatelessWidget {
  const _LearningItemList({required this.items, required this.lastSync});

  final List<LearningItem> items;
  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SyncHeader(lastSync: lastSync),
          const SizedBox(height: 64),
          const Icon(Icons.task_alt, size: 56),
          const SizedBox(height: 16),
          Text('앞으로 60일 안에 알림 대상 마감이 없습니다.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) return _SyncHeader(lastSync: lastSync);
        return _LearningItemCard(item: items[index - 1]);
      },
    );
  }
}

class _SyncHeader extends StatelessWidget {
  const _SyncHeader({required this.lastSync});

  final DateTime? lastSync;

  @override
  Widget build(BuildContext context) {
    final text = lastSync == null ? '아직 동기화 기록이 없습니다.' : '마지막 동기화: ${formatDateTime(lastSync!.toLocal())}';
    return Card(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.notifications_active_outlined),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
      ),
    );
  }
}

class _LearningItemCard extends StatelessWidget {
  const _LearningItemCard({required this.item});

  final LearningItem item;

  @override
  Widget build(BuildContext context) {
    final dueAt = item.dueAt?.toLocal();
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(item.type.label, style: TextStyle(color: colorScheme.onPrimaryContainer)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(item.title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.courseName != null) Text(item.courseName!, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.schedule, size: 18, color: dueAt == null ? colorScheme.outline : colorScheme.primary),
                const SizedBox(width: 8),
                Text(dueAt == null ? '마감일 없음' : formatDateTime(dueAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.month}월 ${value.day}일 $hour:$minute';
}
