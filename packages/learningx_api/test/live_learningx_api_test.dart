import 'dart:io';

import 'package:learningx_api/learningx_api.dart';
import 'package:test/test.dart';

void main() {
  final accessToken = Platform.environment['LEARNINGX_ACCESS_TOKEN'];
  final baseUrl =
      Platform.environment['LEARNINGX_BASE_URL'] ??
      LearningXApiClient.defaultBaseUrl;
  final daysAhead = _intFromEnv('LEARNINGX_DAYS_AHEAD', defaultValue: 14);
  final printLimit = _intFromEnv('LEARNINGX_PRINT_LIMIT', defaultValue: 30);
  final skipLiveTests = accessToken == null || accessToken.isEmpty;

  group(
    'live LearningX API',
    skip: skipLiveTests
        ? 'Set LEARNINGX_ACCESS_TOKEN to run live API tests.'
        : false,
    () {
      late LearningXApiClient client;

      setUp(() {
        client = LearningXApiClient(
          accessToken: accessToken!,
          baseUri: Uri.parse(baseUrl),
        );
      });

      test('loads the current Canvas profile', () async {
        final user = await client.getSelfProfile();

        expect(user.id, isNotEmpty);
        expect(user.name, isNotEmpty);
      });

      test(
        'prints upcoming LearningX planner items for visual inspection',
        () async {
          final user = await client.getSelfProfile();
          final items = await client.getUpcomingLearningItems(
            daysAhead: daysAhead,
          );

          _printSchedulePreview(
            baseUrl: baseUrl,
            user: user,
            daysAhead: daysAhead,
            printLimit: printLimit,
            items: items,
          );

          expect(items, isA<List<LearningItem>>());
        },
      );
    },
  );
}

int _intFromEnv(String key, {required int defaultValue}) {
  final value = int.tryParse(Platform.environment[key] ?? '');
  if (value == null || value <= 0) return defaultValue;
  return value;
}

void _printSchedulePreview({
  required String baseUrl,
  required CanvasUser user,
  required int daysAhead,
  required int printLimit,
  required List<LearningItem> items,
}) {
  stdout.writeln('');
  stdout.writeln('LearningX live schedule preview');
  stdout.writeln('Base URL: $baseUrl');
  stdout.writeln('User: ${user.name} (${user.id})');
  stdout.writeln('Range: next $daysAhead days');
  stdout.writeln('Fetched items: ${items.length}');

  if (items.isEmpty) {
    stdout.writeln('No upcoming items were returned.');
    return;
  }

  stdout.writeln('');
  stdout.writeln('No. | Due | Type | Course | Title');
  stdout.writeln('----|-----|------|--------|------');

  final visibleCount = items.length < printLimit ? items.length : printLimit;
  for (var index = 0; index < visibleCount; index += 1) {
    final item = items[index];
    stdout.writeln(
      '${index + 1}. | ${_formatDateTime(item.dueAt)} | '
      '${item.type.label} | ${_text(item.courseName)} | ${_text(item.title)}',
    );
  }

  final remaining = items.length - visibleCount;
  if (remaining > 0) {
    stdout.writeln(
      '... $remaining more item(s). Increase LEARNINGX_PRINT_LIMIT to show more.',
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return 'No due date';
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-$month-$day $hour:$minute';
}

String _text(String? value) {
  final text = value?.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text == null || text.isEmpty) return '-';
  return text;
}
