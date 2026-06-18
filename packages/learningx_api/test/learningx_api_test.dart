import 'package:dio/dio.dart';
import 'package:learningx_api/learningx_api.dart';
import 'package:test/test.dart';

void main() {
  test('LearningItem serializes cache payloads', () {
    final item = LearningItem(
      id: 'assignment:1',
      type: LearningItemType.assignment,
      title: 'Report',
      courseId: '42',
      htmlUrl: 'https://canvas.ssu.ac.kr/courses/42/assignments/1',
      dueAt: DateTime.utc(2026, 5, 1, 9),
      isCompleted: false,
    );

    expect(LearningItem.fromJson(item.toJson()).title, 'Report');
  });

  test('loads active courses with score fields', () async {
    final client = LearningXApiClient(
      accessToken: 'token',
      dio: _fakeDio((request) {
        expect(request.path, '/api/v1/courses');
        expect(request.queryParameters['include[]'], contains('total_scores'));
        return [
          {
            'id': 42,
            'name': 'Mobile Programming',
            'course_code': 'CS101',
            'is_favorite': true,
            'enrollments': [
              {
                'type': 'StudentEnrollment',
                'grades': {
                  'html_url': 'https://canvas.ssu.ac.kr/courses/42/grades',
                  'current_score': 91.5,
                  'current_grade': 'A0',
                },
              },
            ],
          },
        ];
      }),
    );

    final courses = await client.getActiveCourses();

    expect(courses.single.id, '42');
    expect(courses.single.name, 'Mobile Programming');
    expect(courses.single.currentScore, 91.5);
    expect(courses.single.currentGrade, 'A0');
    expect(courses.single.isFavorite, isTrue);
  });

  test('loads announcements with course names and text previews', () async {
    final course = CanvasCourse(id: '42', name: 'Mobile Programming');
    final client = LearningXApiClient(
      accessToken: 'token',
      dio: _fakeDio((request) {
        expect(request.path, '/api/v1/announcements');
        expect(request.queryParameters['context_codes[]'], ['course_42']);
        return [
          {
            'id': 7,
            'title': 'Exam notice',
            'message': '<p>Hello&nbsp;students</p>',
            'posted_at': '2026-05-01T09:00:00Z',
            'context_code': 'course_42',
            'html_url':
                'https://canvas.ssu.ac.kr/courses/42/discussion_topics/7',
          },
        ];
      }),
    );

    final announcements = await client.getAnnouncements(courses: [course]);

    expect(announcements.single.courseName, 'Mobile Programming');
    expect(announcements.single.messagePreview, 'Hello students');
    expect(announcements.single.postedAt, DateTime.utc(2026, 5, 1, 9));
  });

  test('loads graded submissions with assignment metadata', () async {
    final course = CanvasCourse(id: '42', name: 'Mobile Programming');
    final client = LearningXApiClient(
      accessToken: 'token',
      dio: _fakeDio((request) {
        expect(request.path, '/api/v1/courses/42/students/submissions');
        expect(request.queryParameters['workflow_state'], 'graded');
        expect(request.queryParameters['include[]'], ['assignment']);
        return [
          {
            'id': 99,
            'assignment_id': 12,
            'workflow_state': 'graded',
            'score': 18,
            'grade': '18',
            'late': true,
            'submitted_at': '2026-05-01T08:00:00Z',
            'graded_at': '2026-05-02T08:00:00Z',
            'assignment': {
              'id': 12,
              'name': 'Project 1',
              'points_possible': 20,
              'html_url': 'https://canvas.ssu.ac.kr/courses/42/assignments/12',
            },
          },
        ];
      }),
    );

    final submissions = await client.getGradedSubmissions(courses: [course]);

    expect(submissions.single.courseName, 'Mobile Programming');
    expect(submissions.single.assignmentName, 'Project 1');
    expect(submissions.single.status, SubmissionStatus.graded);
    expect(submissions.single.score, 18);
    expect(submissions.single.pointsPossible, 20);
    expect(submissions.single.late, isTrue);
  });

  test(
    'upcoming items request incomplete planner items and skip overrides',
    () async {
      final client = LearningXApiClient(
        accessToken: 'token',
        dio: _fakeDio((request) {
          expect(request.path, '/api/v1/planner/items');
          expect(request.queryParameters['filter'], 'incomplete_items');
          return [
            {
              'context_type': 'Course',
              'course_id': 42,
              'context_name': 'Mobile Programming',
              'plannable_id': 1,
              'plannable_type': 'assignment',
              'plannable': {
                'title': 'Visible report',
                'due_at': '2026-05-01T09:00:00Z',
              },
              'html_url': '/courses/42/assignments/1',
              'submissions': false,
            },
            {
              'context_type': 'Course',
              'course_id': 42,
              'context_name': 'Mobile Programming',
              'plannable_id': 2,
              'plannable_type': 'assignment',
              'plannable': {
                'title': 'Hidden report',
                'due_at': '2026-05-02T09:00:00Z',
              },
              'planner_override': {'marked_complete': true},
              'submissions': false,
            },
          ];
        }),
      );

      final items = await client.getUpcomingLearningItems(
        from: DateTime.utc(2026, 4, 30),
      );

      expect(items, hasLength(1));
      expect(items.single.title, 'Visible report');
    },
  );
}

Dio _fakeDio(Object? Function(RequestOptions request) responseFor) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (request, handler) {
        handler.resolve(
          Response<Object?>(
            requestOptions: request,
            data: responseFor(request),
          ),
        );
      },
    ),
  );
  return dio;
}
