import 'package:flutter_test/flutter_test.dart';
import 'package:learningx_alert/src/features/home/home_screen.dart';

void main() {
  test('formats local dates for list rows', () {
    expect(formatDateTime(DateTime(2026, 5, 1, 9, 5)), '5월 1일 09:05');
  });
}
