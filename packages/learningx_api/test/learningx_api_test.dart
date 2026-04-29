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
}
