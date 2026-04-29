// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'learning_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LearningItem _$LearningItemFromJson(Map<String, dynamic> json) => LearningItem(
  id: json['id'] as String,
  type: $enumDecode(_$LearningItemTypeEnumMap, json['type']),
  title: json['title'] as String,
  courseId: json['course_id'] as String?,
  htmlUrl: json['html_url'] as String?,
  isCompleted: json['is_completed'] as bool,
  dueAt: json['due_at'] == null
      ? null
      : DateTime.parse(json['due_at'] as String),
  details: json['details'] as String?,
  courseName: json['course_name'] as String?,
);

Map<String, dynamic> _$LearningItemToJson(LearningItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$LearningItemTypeEnumMap[instance.type]!,
      'title': instance.title,
      'course_id': instance.courseId,
      'course_name': instance.courseName,
      'due_at': instance.dueAt?.toIso8601String(),
      'html_url': instance.htmlUrl,
      'details': instance.details,
      'is_completed': instance.isCompleted,
    };

const _$LearningItemTypeEnumMap = {
  LearningItemType.assignment: 'assignment',
  LearningItemType.quiz: 'quiz',
  LearningItemType.discussionTopic: 'discussionTopic',
  LearningItemType.wikiPage: 'wikiPage',
  LearningItemType.calendarEvent: 'calendarEvent',
  LearningItemType.plannerNote: 'plannerNote',
  LearningItemType.unknown: 'unknown',
};
