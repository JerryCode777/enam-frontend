// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_User _$UserFromJson(Map<String, dynamic> json) => _User(
  id: json['id'] as String,
  email: json['email'] as String,
  nombre: json['nombre'] as String,
  rol:
      $enumDecodeNullable(_$UserRoleEnumMap, json['rol']) ??
      UserRole.estudiante,
  universidad: json['universidad'] as String?,
  condicion: $enumDecodeNullable(_$StudentConditionEnumMap, json['condicion']),
  fechaObjetivo: json['fechaObjetivo'] == null
      ? null
      : DateTime.parse(json['fechaObjetivo'] as String),
  emailVerificado: json['emailVerificado'] as bool? ?? false,
  ocultoEnRanking: json['ocultoEnRanking'] as bool? ?? false,
);

Map<String, dynamic> _$UserToJson(_User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'nombre': instance.nombre,
  'rol': _$UserRoleEnumMap[instance.rol]!,
  'universidad': instance.universidad,
  'condicion': _$StudentConditionEnumMap[instance.condicion],
  'fechaObjetivo': instance.fechaObjetivo?.toIso8601String(),
  'emailVerificado': instance.emailVerificado,
  'ocultoEnRanking': instance.ocultoEnRanking,
};

const _$UserRoleEnumMap = {
  UserRole.estudiante: 'estudiante',
  UserRole.editor: 'editor',
  UserRole.admin: 'admin',
};

const _$StudentConditionEnumMap = {
  StudentCondition.preinterno: 'preinterno',
  StudentCondition.interno: 'interno',
  StudentCondition.egresado: 'egresado',
  StudentCondition.repitiente: 'repitiente',
};

_AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => _AuthSession(
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
  expiresAt: DateTime.parse(json['expiresAt'] as String),
  user: User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$AuthSessionToJson(_AuthSession instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresAt': instance.expiresAt.toIso8601String(),
      'user': instance.user,
    };
