// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PaqueteOffline _$PaqueteOfflineFromJson(Map<String, dynamic> json) =>
    _PaqueteOffline(
      areaId: json['areaId'] as String,
      generadoEn: DateTime.parse(json['generadoEn'] as String),
      preguntas:
          (json['preguntas'] as List<dynamic>?)
              ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$PaqueteOfflineToJson(_PaqueteOffline instance) =>
    <String, dynamic>{
      'areaId': instance.areaId,
      'generadoEn': instance.generadoEn.toIso8601String(),
      'preguntas': instance.preguntas,
      'total': instance.total,
    };

_ResultadoDeSync _$ResultadoDeSyncFromJson(Map<String, dynamic> json) =>
    _ResultadoDeSync(
      aceptadas: (json['aceptadas'] as num?)?.toInt() ?? 0,
      sesionesCreadas: (json['sesionesCreadas'] as num?)?.toInt() ?? 0,
      conflictos:
          (json['conflictos'] as List<dynamic>?)
              ?.map((e) => ConflictoDeSync.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ResultadoDeSyncToJson(_ResultadoDeSync instance) =>
    <String, dynamic>{
      'aceptadas': instance.aceptadas,
      'sesionesCreadas': instance.sesionesCreadas,
      'conflictos': instance.conflictos,
    };

_ConflictoDeSync _$ConflictoDeSyncFromJson(Map<String, dynamic> json) =>
    _ConflictoDeSync(
      questionId: json['questionId'] as String,
      motivo: json['motivo'] as String? ?? '',
    );

Map<String, dynamic> _$ConflictoDeSyncToJson(_ConflictoDeSync instance) =>
    <String, dynamic>{
      'questionId': instance.questionId,
      'motivo': instance.motivo,
    };
