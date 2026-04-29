import 'package:json_annotation/json_annotation.dart';

part 'canvas_user.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CanvasUser {
  const CanvasUser({
    required this.id,
    required this.name,
    this.shortName,
    this.sortableName,
    this.loginId,
    this.email,
    this.primaryEmail,
    this.avatarUrl,
    this.timeZone,
    this.locale,
  });

  @JsonKey(fromJson: _idToString)
  final String id;
  final String name;
  final String? shortName;
  final String? sortableName;
  final String? loginId;
  final String? email;
  final String? primaryEmail;
  final String? avatarUrl;
  final String? timeZone;
  final String? locale;

  factory CanvasUser.fromJson(Map<String, dynamic> json) => _$CanvasUserFromJson(json);

  Map<String, dynamic> toJson() => _$CanvasUserToJson(this);
}

String _idToString(Object? value) => value?.toString() ?? '';
