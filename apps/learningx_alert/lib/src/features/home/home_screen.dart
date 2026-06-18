import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:learningx_api/learningx_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app_providers.dart';
import '../../dashboard/learning_dashboard_state.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  var _selectedIndex = 0;
  String? _announcementCourseId;
  String? _gradeCourseId;

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
      ref.invalidate(learningDashboardProvider);
      ref.invalidate(notificationPermissionProvider);
      ref.invalidate(pendingNotificationCountProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(learningDashboardProvider);
    final titles = ['마감', '공지', '성적', '설정'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_selectedIndex]),
        actions: [
          if (_selectedIndex != 3)
            IconButton(
              tooltip: '새로고침',
              onPressed: () =>
                  ref.read(learningDashboardProvider.notifier).refresh(),
              icon: const Icon(Icons.sync),
            ),
        ],
      ),
      body: _selectedIndex == 3
          ? const SettingsView()
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(learningDashboardProvider.notifier).refresh(),
              child: dashboard.when(
                data: _buildDashboardTab,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => _ErrorList(
                  title: '대시보드를 불러오지 못했습니다.',
                  message: '$error',
                  onRetry: () =>
                      ref.read(learningDashboardProvider.notifier).refresh(),
                ),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available),
            label: '마감',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: '공지',
          ),
          NavigationDestination(
            icon: Icon(Icons.grade_outlined),
            selectedIcon: Icon(Icons.grade),
            label: '성적',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(LearningDashboardState dashboard) {
    return switch (_selectedIndex) {
      0 => _DeadlineTab(dashboard: dashboard),
      1 => _AnnouncementTab(
        dashboard: dashboard,
        selectedCourseId: _announcementCourseId,
        onCourseChanged: (value) =>
            setState(() => _announcementCourseId = value),
      ),
      2 => _GradeTab(
        dashboard: dashboard,
        selectedCourseId: _gradeCourseId,
        onCourseChanged: (value) => setState(() => _gradeCourseId = value),
      ),
      _ => const SettingsView(),
    };
  }
}

class _DeadlineTab extends StatelessWidget {
  const _DeadlineTab({required this.dashboard});

  final LearningDashboardState dashboard;

  @override
  Widget build(BuildContext context) {
    final groups = _groupDeadlines(dashboard.deadlines);
    if (dashboard.deadlines.isEmpty) {
      return _DashboardList(
        dashboard: dashboard,
        children: const [
          SizedBox(height: 64),
          Icon(Icons.task_alt, size: 56),
          SizedBox(height: 16),
          Center(child: Text('앞으로 60일 안에 알림 대상 마감이 없습니다.')),
        ],
      );
    }

    return _DashboardList(
      dashboard: dashboard,
      children: [
        for (final entry in groups.entries) ...[
          _SectionHeader(title: entry.key),
          for (final item in entry.value)
            _LearningItemCard(
              item: item,
              changed: dashboard.changedDeadlineIds.contains(item.id),
            ),
        ],
      ],
    );
  }
}

class _AnnouncementTab extends StatelessWidget {
  const _AnnouncementTab({
    required this.dashboard,
    required this.selectedCourseId,
    required this.onCourseChanged,
  });

  final LearningDashboardState dashboard;
  final String? selectedCourseId;
  final ValueChanged<String?> onCourseChanged;

  @override
  Widget build(BuildContext context) {
    final visible = dashboard.announcements
        .where(
          (item) =>
              selectedCourseId == null || item.courseId == selectedCourseId,
        )
        .toList(growable: false);

    return _DashboardList(
      dashboard: dashboard,
      children: [
        _CourseFilter(
          courses: dashboard.courses,
          selectedCourseId: selectedCourseId,
          onChanged: onCourseChanged,
        ),
        if (visible.isEmpty) ...[
          const SizedBox(height: 48),
          const Icon(Icons.campaign_outlined, size: 56),
          const SizedBox(height: 16),
          const Center(child: Text('최근 30일 공지가 없습니다.')),
        ] else
          for (final item in visible)
            _AnnouncementCard(
              item: item,
              isNew: dashboard.newAnnouncementIds.contains(item.id),
            ),
      ],
    );
  }
}

class _GradeTab extends StatelessWidget {
  const _GradeTab({
    required this.dashboard,
    required this.selectedCourseId,
    required this.onCourseChanged,
  });

  final LearningDashboardState dashboard;
  final String? selectedCourseId;
  final ValueChanged<String?> onCourseChanged;

  @override
  Widget build(BuildContext context) {
    final visible = dashboard.gradedSubmissions
        .where(
          (item) =>
              selectedCourseId == null || item.courseId == selectedCourseId,
        )
        .toList(growable: false);

    return _DashboardList(
      dashboard: dashboard,
      children: [
        _CourseFilter(
          courses: dashboard.courses,
          selectedCourseId: selectedCourseId,
          onChanged: onCourseChanged,
        ),
        if (visible.isEmpty) ...[
          const SizedBox(height: 48),
          const Icon(Icons.grade_outlined, size: 56),
          const SizedBox(height: 16),
          const Center(child: Text('최근 채점된 과제가 없습니다.')),
        ] else
          for (final item in visible)
            _GradeCard(
              item: item,
              changed: dashboard.changedGradeIds.contains(item.id),
            ),
      ],
    );
  }
}

class _DashboardList extends StatelessWidget {
  const _DashboardList({required this.dashboard, required this.children});

  final LearningDashboardState dashboard;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SyncHeader(dashboard: dashboard),
        const SizedBox(height: 12),
        ...children.expand((child) sync* {
          yield child;
          yield const SizedBox(height: 10);
        }),
      ],
    );
  }
}

class _SyncHeader extends StatelessWidget {
  const _SyncHeader({required this.dashboard});

  final LearningDashboardState dashboard;

  @override
  Widget build(BuildContext context) {
    final text = dashboard.lastSyncAt == null
        ? '아직 동기화 기록이 없습니다.'
        : '마지막 동기화: ${formatDateTime(dashboard.lastSyncAt!.toLocal())}';
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: dashboard.hasSectionErrors
          ? colorScheme.errorContainer
          : colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  dashboard.hasSectionErrors
                      ? Icons.sync_problem
                      : Icons.notifications_active_outlined,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(text)),
              ],
            ),
            if (dashboard.hasSectionErrors) ...[
              const SizedBox(height: 8),
              Text(
                dashboard.sectionErrors
                    .take(3)
                    .map((error) => error.displayText)
                    .join('\n'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CourseFilter extends StatelessWidget {
  const _CourseFilter({
    required this.courses,
    required this.selectedCourseId,
    required this.onChanged,
  });

  final List<CanvasCourse> courses;
  final String? selectedCourseId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String?>(
      initialValue: selectedCourseId,
      decoration: const InputDecoration(
        labelText: '과목',
        prefixIcon: Icon(Icons.class_outlined),
        border: OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('전체 과목')),
        for (final course in courses)
          DropdownMenuItem<String?>(
            value: course.id,
            child: Text(course.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 2),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _LearningItemCard extends StatelessWidget {
  const _LearningItemCard({required this.item, required this.changed});

  final LearningItem item;
  final bool changed;

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
                _TypeChip(label: item.type.label),
                if (changed) ...[
                  const SizedBox(width: 8),
                  const _StatusChip(label: '변경'),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (item.courseName != null)
              Text(
                item.courseName!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: dueAt == null
                      ? colorScheme.outline
                      : colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dueAt == null
                        ? '마감일 없음'
                        : '${formatDateTime(dueAt)} · ${dDayText(dueAt)}',
                  ),
                ),
                _OpenCanvasButton(url: item.htmlUrl),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.item, required this.isNew});

  final AnnouncementItem item;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isNew) ...[
                  const _StatusChip(label: 'NEW'),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _OpenCanvasButton(url: item.htmlUrl),
              ],
            ),
            const SizedBox(height: 8),
            Text(item.courseName),
            const SizedBox(height: 4),
            Text(
              formatDateTime(item.postedAt.toLocal()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (item.messagePreview != null) ...[
              const SizedBox(height: 10),
              Text(
                item.messagePreview!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({required this.item, required this.changed});

  final GradedSubmissionItem item;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    final score = _scoreText(item);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeChip(label: item.status.label),
                if (item.late || item.missing) ...[
                  const SizedBox(width: 8),
                  _StatusChip(label: item.missing ? '미제출' : '지각'),
                ],
                if (changed) ...[
                  const SizedBox(width: 8),
                  const _StatusChip(label: '업데이트'),
                ],
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.assignmentName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _OpenCanvasButton(url: item.htmlUrl),
              ],
            ),
            const SizedBox(height: 10),
            Text(item.courseName),
            const SizedBox(height: 8),
            Text(score),
            if (item.gradedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                '채점: ${formatDateTime(item.gradedAt!.toLocal())}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: colorScheme.onPrimaryContainer),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _OpenCanvasButton extends StatelessWidget {
  const _OpenCanvasButton({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Canvas에서 열기',
      onPressed: () => _openCanvasUrl(context, url),
      icon: const Icon(Icons.open_in_new),
    );
  }
}

class _ErrorList extends StatelessWidget {
  const _ErrorList({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Icon(Icons.cloud_off, size: 40),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(message),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('다시 시도'),
        ),
      ],
    );
  }
}

Map<String, List<LearningItem>> _groupDeadlines(List<LearningItem> items) {
  final groups = <String, List<LearningItem>>{};
  for (final item in items) {
    final label = deadlineBucketLabel(item.dueAt?.toLocal());
    groups.putIfAbsent(label, () => []).add(item);
  }
  return groups;
}

String deadlineBucketLabel(DateTime? dueAt) {
  if (dueAt == null) return '마감일 없음';
  final now = DateTime.now();
  final today = DateUtils.dateOnly(now);
  final dueDate = DateUtils.dateOnly(dueAt);
  final days = dueDate.difference(today).inDays;
  if (dueAt.isBefore(now)) return '마감 지남';
  if (days == 0) return '오늘';
  if (days == 1) return '내일';
  if (days <= 7) return '7일 이내';
  return '이후';
}

String dDayText(DateTime dueAt) {
  final now = DateTime.now();
  final today = DateUtils.dateOnly(now);
  final dueDate = DateUtils.dateOnly(dueAt);
  final days = dueDate.difference(today).inDays;
  if (dueAt.isBefore(now)) return '마감 지남';
  if (days == 0) return 'D-Day';
  return 'D-$days';
}

String formatDateTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '${value.month}월 ${value.day}일 $hour:$minute';
}

String _scoreText(GradedSubmissionItem item) {
  final values = <String>[];
  if (item.score != null) {
    if (item.pointsPossible != null) {
      values.add('${item.score}/${item.pointsPossible}점');
    } else {
      values.add('${item.score}점');
    }
  }
  if (item.grade != null) values.add(item.grade!);
  return values.isEmpty ? '점수 정보 없음' : values.join(' · ');
}

Future<void> _openCanvasUrl(BuildContext context, String? value) async {
  final uri = _canvasUri(value);
  if (uri == null) return;
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Canvas 링크를 열지 못했습니다.')));
  }
}

Uri? _canvasUri(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final raw = value.trim();
  final uri = Uri.tryParse(raw);
  if (uri == null) return null;
  if (uri.hasScheme) return uri;
  return Uri.parse(LearningXApiClient.defaultBaseUrl).resolve(raw);
}

extension _SubmissionStatusLabel on SubmissionStatus {
  String get label {
    return switch (this) {
      SubmissionStatus.submitted => '제출',
      SubmissionStatus.unsubmitted => '미제출',
      SubmissionStatus.graded => '채점됨',
      SubmissionStatus.pendingReview => '검토중',
      SubmissionStatus.missing => '누락',
      SubmissionStatus.unknown => '상태',
    };
  }
}
