// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planner_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlannerOverride _$PlannerOverrideFromJson(Map<String, dynamic> json) =>
    PlannerOverride(
      id: _objectToNullableString(json['id']),
      markedComplete: json['marked_complete'] as bool?,
      dismissed: json['dismissed'] as bool?,
      workflowState: json['workflow_state'] as String?,
    );

Map<String, dynamic> _$PlannerOverrideToJson(PlannerOverride instance) =>
    <String, dynamic>{
      'id': instance.id,
      'marked_complete': instance.markedComplete,
      'dismissed': instance.dismissed,
      'workflow_state': instance.workflowState,
    };

PlannerItem _$PlannerItemFromJson(Map<String, dynamic> json) => PlannerItem(
  plannableId: _objectToString(json['plannable_id']),
  plannableType: json['plannable_type'] as String,
  plannable: json['plannable'] as Map<String, dynamic>,
  contextType: json['context_type'] as String?,
  courseId: _objectToNullableString(json['course_id']),
  contextName: json['context_name'] as String?,
  htmlUrl: json['html_url'] as String?,
  submissions: json['submissions'],
  plannerOverride: json['planner_override'] == null
      ? null
      : PlannerOverride.fromJson(
          json['planner_override'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$PlannerItemToJson(PlannerItem instance) =>
    <String, dynamic>{
      'context_type': instance.contextType,
      'course_id': instance.courseId,
      'context_name': instance.contextName,
      'html_url': instance.htmlUrl,
      'plannable_id': instance.plannableId,
      'plannable_type': instance.plannableType,
      'plannable': instance.plannable,
      'submissions': instance.submissions,
      'planner_override': instance.plannerOverride,
    };
