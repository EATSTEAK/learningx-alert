// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'canvas_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CanvasUser _$CanvasUserFromJson(Map<String, dynamic> json) => CanvasUser(
  id: _idToString(json['id']),
  name: json['name'] as String,
  shortName: json['short_name'] as String?,
  sortableName: json['sortable_name'] as String?,
  loginId: json['login_id'] as String?,
  email: json['email'] as String?,
  primaryEmail: json['primary_email'] as String?,
  avatarUrl: json['avatar_url'] as String?,
  timeZone: json['time_zone'] as String?,
  locale: json['locale'] as String?,
);

Map<String, dynamic> _$CanvasUserToJson(CanvasUser instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'short_name': instance.shortName,
      'sortable_name': instance.sortableName,
      'login_id': instance.loginId,
      'email': instance.email,
      'primary_email': instance.primaryEmail,
      'avatar_url': instance.avatarUrl,
      'time_zone': instance.timeZone,
      'locale': instance.locale,
    };
