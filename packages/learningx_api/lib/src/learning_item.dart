import 'package:json_annotation/json_annotation.dart';

part 'learning_item.g.dart';

enum LearningItemType {
  assignment,
  quiz,
  discussionTopic,
  wikiPage,
  calendarEvent,
  plannerNote,
  unknown,
}

@JsonSerializable(fieldRename: FieldRename.snake)
class LearningItem {
  const LearningItem({
    required this.id,
    required this.type,
    required this.title,
    required this.courseId,
    required this.htmlUrl,
    required this.isCompleted,
    this.dueAt,
    this.details,
    this.courseName,
  });

  final String id;
  final LearningItemType type;
  final String title;
  final String? courseId;
  final String? courseName;
  final DateTime? dueAt;
  final String? htmlUrl;
  final String? details;
  final bool isCompleted;

  factory LearningItem.fromJson(Map<String, dynamic> json) => _$LearningItemFromJson(json);

  Map<String, dynamic> toJson() => _$LearningItemToJson(this);
}

extension LearningItemTypeLabel on LearningItemType {
  String get label {
    return switch (this) {
      LearningItemType.assignment => '과제',
      LearningItemType.quiz => '퀴즈',
      LearningItemType.discussionTopic => '토론',
      LearningItemType.wikiPage => '페이지',
      LearningItemType.calendarEvent => '일정',
      LearningItemType.plannerNote => '메모',
      LearningItemType.unknown => '항목',
    };
  }
}
