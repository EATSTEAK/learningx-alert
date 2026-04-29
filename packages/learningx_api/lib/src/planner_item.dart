import 'package:json_annotation/json_annotation.dart';

part 'planner_item.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class PlannerOverride {
  const PlannerOverride({
    this.id,
    this.markedComplete,
    this.dismissed,
    this.workflowState,
  });

  @JsonKey(fromJson: _objectToNullableString)
  final String? id;
  final bool? markedComplete;
  final bool? dismissed;
  final String? workflowState;

  factory PlannerOverride.fromJson(Map<String, dynamic> json) => _$PlannerOverrideFromJson(json);

  Map<String, dynamic> toJson() => _$PlannerOverrideToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
class PlannerItem {
  const PlannerItem({
    required this.plannableId,
    required this.plannableType,
    required this.plannable,
    this.contextType,
    this.courseId,
    this.contextName,
    this.htmlUrl,
    this.submissions,
    this.plannerOverride,
  });

  final String? contextType;
  @JsonKey(fromJson: _objectToNullableString)
  final String? courseId;
  final String? contextName;
  final String? htmlUrl;
  @JsonKey(fromJson: _objectToString)
  final String plannableId;
  final String plannableType;
  final Map<String, dynamic> plannable;
  final Object? submissions;
  final PlannerOverride? plannerOverride;

  factory PlannerItem.fromJson(Map<String, dynamic> json) => _$PlannerItemFromJson(json);

  Map<String, dynamic> toJson() => _$PlannerItemToJson(this);
}

String _objectToString(Object? value) => value?.toString() ?? '';

String? _objectToNullableString(Object? value) => value?.toString();
