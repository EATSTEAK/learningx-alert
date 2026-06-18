import 'package:dio/dio.dart';

import 'announcement_item.dart';
import 'canvas_api_exception.dart';
import 'canvas_course.dart';
import 'canvas_user.dart';
import 'graded_submission_item.dart';
import 'learning_item.dart';
import 'planner_item.dart';

class LearningXApiClient {
  LearningXApiClient({required String accessToken, Uri? baseUri, Dio? dio})
    : baseUri = baseUri ?? Uri.parse(defaultBaseUrl),
      _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: (baseUri ?? Uri.parse(defaultBaseUrl)).toString(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json+canvas-string-ids',
      },
    );
  }

  static const defaultBaseUrl = 'https://canvas.ssu.ac.kr';

  final Uri baseUri;
  final Dio _dio;

  Future<CanvasUser> getSelf() async {
    final json = await _getMap('/api/v1/users/self');
    return CanvasUser.fromJson(json);
  }

  Future<CanvasUser> getSelfProfile() async {
    final json = await _getMap('/api/v1/users/self/profile');
    return CanvasUser.fromJson(json);
  }

  Future<List<PlannerItem>> getPlannerItems({
    DateTime? startDate,
    DateTime? endDate,
    String? filter,
  }) async {
    final query = <String, dynamic>{};
    if (startDate != null) query['start_date'] = _dateParam(startDate);
    if (endDate != null) query['end_date'] = _dateParam(endDate);
    if (filter != null) query['filter'] = filter;
    final rows = await _getPaginatedList(
      '/api/v1/planner/items',
      queryParameters: query,
    );
    return rows
        .whereType<Map>()
        .map((row) => PlannerItem.fromJson(Map<String, dynamic>.from(row)))
        .toList(growable: false);
  }

  Future<List<LearningItem>> getUpcomingLearningItems({
    DateTime? from,
    int daysAhead = 60,
  }) async {
    final start = from ?? DateTime.now();
    final end = start.add(Duration(days: daysAhead));
    final plannerItems = await getPlannerItems(
      startDate: start,
      endDate: end,
      filter: 'incomplete_items',
    );
    return plannerItems
        .map(_toLearningItem)
        .where((item) => item != null)
        .cast<LearningItem>()
        .where((item) => !item.isCompleted)
        .toList(growable: false)
      ..sort((a, b) {
        final aDue = a.dueAt;
        final bDue = b.dueAt;
        if (aDue == null && bDue == null) return a.title.compareTo(b.title);
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        return aDue.compareTo(bDue);
      });
  }

  Future<List<CanvasCourse>> getActiveCourses() async {
    final rows = await _getPaginatedList(
      '/api/v1/courses',
      queryParameters: const {
        'enrollment_type': 'student',
        'enrollment_state': 'active',
        'include[]': ['total_scores', 'favorites'],
        'per_page': 100,
      },
    );
    return rows
        .whereType<Map>()
        .map((row) => CanvasCourse.fromJson(Map<String, dynamic>.from(row)))
        .where((course) => course.id.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<List<AnnouncementItem>> getAnnouncements({
    int daysBack = 30,
    List<CanvasCourse>? courses,
  }) async {
    final targetCourses = courses ?? await getActiveCourses();
    final values = <AnnouncementItem>[];
    for (final course in targetCourses) {
      values.addAll(
        await getAnnouncementsForCourse(course, daysBack: daysBack),
      );
    }
    values.sort((a, b) => b.postedAt.compareTo(a.postedAt));
    return values;
  }

  Future<List<AnnouncementItem>> getAnnouncementsForCourse(
    CanvasCourse course, {
    int daysBack = 30,
  }) async {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: daysBack));
    final rows = await _getPaginatedList(
      '/api/v1/announcements',
      queryParameters: {
        'context_codes[]': ['course_${course.id}'],
        'start_date': _dateParam(start),
        'end_date': _dateParam(end),
        'active_only': true,
        'per_page': 100,
      },
    );
    return rows
        .whereType<Map>()
        .map((row) {
          final json = Map<String, dynamic>.from(row);
          json['course_id'] = course.id;
          json['course_name'] = course.name;
          return AnnouncementItem.fromJson(json);
        })
        .where((item) => item.id.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
  }

  Future<List<GradedSubmissionItem>> getGradedSubmissions({
    int daysBack = 120,
    List<CanvasCourse>? courses,
  }) async {
    final targetCourses = courses ?? await getActiveCourses();
    final values = <GradedSubmissionItem>[];
    for (final course in targetCourses) {
      values.addAll(
        await getGradedSubmissionsForCourse(course, daysBack: daysBack),
      );
    }
    values.sort(_compareGradedSubmissions);
    return values;
  }

  Future<List<GradedSubmissionItem>> getGradedSubmissionsForCourse(
    CanvasCourse course, {
    int daysBack = 120,
  }) async {
    final since = DateTime.now().subtract(Duration(days: daysBack));
    final rows = await _getPaginatedList(
      '/api/v1/courses/${course.id}/students/submissions',
      queryParameters: {
        'workflow_state': 'graded',
        'graded_since': _dateParam(since),
        'include[]': ['assignment'],
        'order': 'graded_at',
        'order_direction': 'descending',
        'per_page': 100,
      },
    );
    return rows
        .whereType<Map>()
        .map((row) {
          final json = Map<String, dynamic>.from(row);
          json['course_id'] = course.id;
          json['course_name'] = course.name;
          return GradedSubmissionItem.fromJson(json);
        })
        .where((item) => item.assignmentId.isNotEmpty && item.isGraded)
        .toList(growable: false)
      ..sort(_compareGradedSubmissions);
  }

  Future<Map<String, dynamic>> _getMap(String path) async {
    try {
      final response = await _dio.get<Object?>(path);
      if (response.data is Map<String, dynamic>) {
        return response.data! as Map<String, dynamic>;
      }
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data! as Map);
      }
      throw CanvasApiException(
        'Unexpected Canvas API response.',
        details: response.data,
      );
    } on DioException catch (error) {
      throw CanvasApiException.fromDio(error);
    }
  }

  Future<List<dynamic>> _getPaginatedList(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final values = <dynamic>[];
    String? nextUrl;

    try {
      do {
        final response = nextUrl == null
            ? await _dio.get<Object?>(path, queryParameters: queryParameters)
            : await _dio.getUri<Object?>(Uri.parse(nextUrl));
        final data = response.data;
        if (data is! List) {
          throw CanvasApiException(
            'Unexpected paginated Canvas API response.',
            details: data,
          );
        }
        values.addAll(data);
        nextUrl = _nextLink(response.headers.value('link'));
      } while (nextUrl != null);
      return values;
    } on DioException catch (error) {
      throw CanvasApiException.fromDio(error);
    }
  }
}

String _dateParam(DateTime value) => value.toUtc().toIso8601String();

String? _nextLink(String? header) {
  if (header == null || header.isEmpty) return null;
  for (final part in header.split(',')) {
    final sections = part.split(';');
    if (sections.length < 2) continue;
    final urlPart = sections.first.trim();
    final relPart = sections.skip(1).map((section) => section.trim()).join(';');
    if (!relPart.contains('rel="next"')) continue;
    if (urlPart.startsWith('<') && urlPart.endsWith('>')) {
      return urlPart.substring(1, urlPart.length - 1);
    }
  }
  return null;
}

LearningItem? _toLearningItem(PlannerItem item) {
  final override = item.plannerOverride;
  if (override?.markedComplete == true || override?.dismissed == true) {
    return null;
  }

  final type = _typeFromPlanner(item.plannableType);
  if (!_defaultLearningTypes.contains(type)) return null;

  final title = _stringField(item.plannable, ['title', 'name']) ?? 'Untitled';
  final dueAt = _dateField(item.plannable, ['due_at', 'todo_date']);
  final htmlUrl = item.htmlUrl ?? _stringField(item.plannable, ['html_url']);
  final details = _stringField(item.plannable, ['description', 'details']);

  return LearningItem(
    id: '${item.plannableType}:${item.plannableId}',
    type: type,
    title: title,
    courseId: item.courseId,
    courseName: item.contextName,
    dueAt: dueAt,
    htmlUrl: htmlUrl,
    details: details,
    isCompleted: _submissionCompleted(item.submissions),
  );
}

const _defaultLearningTypes = {
  LearningItemType.assignment,
  LearningItemType.quiz,
  LearningItemType.discussionTopic,
  LearningItemType.wikiPage,
};

LearningItemType _typeFromPlanner(String rawType) {
  return switch (rawType.toLowerCase()) {
    'assignment' => LearningItemType.assignment,
    'quiz' => LearningItemType.quiz,
    'discussion_topic' => LearningItemType.discussionTopic,
    'wiki_page' => LearningItemType.wikiPage,
    'calendar_event' => LearningItemType.calendarEvent,
    'planner_note' => LearningItemType.plannerNote,
    _ => LearningItemType.unknown,
  };
}

String? _stringField(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value;
    if (value != null && value is! Map && value is! Iterable) {
      return value.toString();
    }
  }
  return null;
}

DateTime? _dateField(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  }
  return null;
}

bool _submissionCompleted(Object? submissions) {
  if (submissions is! Map) return false;
  final data = Map<String, dynamic>.from(submissions);
  if (data['excused'] == true ||
      data['graded'] == true ||
      data['submitted'] == true ||
      data['needs_grading'] == true ||
      data['with_feedback'] == true) {
    return true;
  }
  final workflow = data['workflow_state'];
  if (workflow is String) {
    return workflow == 'submitted' || workflow == 'graded';
  }
  return data['submitted_at'] != null;
}

int _compareGradedSubmissions(GradedSubmissionItem a, GradedSubmissionItem b) {
  final aDate = a.gradedAt ?? a.submittedAt;
  final bDate = b.gradedAt ?? b.submittedAt;
  if (aDate == null && bDate == null) {
    return a.assignmentName.compareTo(b.assignmentName);
  }
  if (aDate == null) return 1;
  if (bDate == null) return -1;
  return bDate.compareTo(aDate);
}
