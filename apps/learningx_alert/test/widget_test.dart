import 'package:flutter_test/flutter_test.dart';
import 'package:learningx_alert/src/storage/app_settings_store.dart';
import 'package:learningx_alert/src/storage/learning_item_cache.dart';
import 'package:learningx_alert/src/features/home/home_screen.dart';
import 'package:learningx_api/learningx_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('formats local dates for list rows', () {
    expect(formatDateTime(DateTime(2026, 5, 1, 9, 5)), '5월 1일 09:05');
  });

  test('dashboard cache stores announcements and graded submissions', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final cache = LearningItemCache(preferences);

    await cache.writeCourses([
      const CanvasCourse(id: '42', name: 'Mobile Programming'),
    ]);
    await cache.writeAnnouncements([
      AnnouncementItem(
        id: '7',
        title: 'Exam notice',
        courseId: '42',
        courseName: 'Mobile Programming',
        postedAt: DateTime.utc(2026, 5, 1, 9),
      ),
    ]);
    await cache.writeGradedSubmissions([
      const GradedSubmissionItem(
        id: '42:12',
        courseId: '42',
        courseName: 'Mobile Programming',
        assignmentId: '12',
        assignmentName: 'Project 1',
        status: SubmissionStatus.graded,
        score: 18,
        pointsPossible: 20,
      ),
    ]);

    expect(cache.readCourses().single.name, 'Mobile Programming');
    expect(cache.readAnnouncements().single.title, 'Exam notice');
    expect(cache.readGradedSubmissions().single.score, 18);
  });

  test('notification settings default to expanded alert types', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final store = AppSettingsStore(preferences);

    final settings = await store.readNotificationSettings();

    expect(settings.contains(const Duration(days: 7)), isTrue);
    expect(settings.contains(const Duration(minutes: 15)), isTrue);
    expect(settings.announcementAlertsEnabled, isTrue);
    expect(settings.gradeAlertsEnabled, isTrue);
  });
}
