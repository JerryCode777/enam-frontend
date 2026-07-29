// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AreaPerformance _$AreaPerformanceFromJson(Map<String, dynamic> json) =>
    _AreaPerformance(
      areaId: json['areaId'] as String,
      areaNombre: json['areaNombre'] as String,
      preguntasBlueprint: (json['preguntasBlueprint'] as num).toInt(),
      respondidas: (json['respondidas'] as num?)?.toInt() ?? 0,
      correctas: (json['correctas'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$AreaPerformanceToJson(_AreaPerformance instance) =>
    <String, dynamic>{
      'areaId': instance.areaId,
      'areaNombre': instance.areaNombre,
      'preguntasBlueprint': instance.preguntasBlueprint,
      'respondidas': instance.respondidas,
      'correctas': instance.correctas,
    };

_GradePoint _$GradePointFromJson(Map<String, dynamic> json) => _GradePoint(
  fecha: DateTime.parse(json['fecha'] as String),
  nota: (json['nota'] as num).toDouble(),
  sessionId: json['sessionId'] as String?,
);

Map<String, dynamic> _$GradePointToJson(_GradePoint instance) =>
    <String, dynamic>{
      'fecha': instance.fecha.toIso8601String(),
      'nota': instance.nota,
      'sessionId': instance.sessionId,
    };

_DashboardStats _$DashboardStatsFromJson(
  Map<String, dynamic> json,
) => _DashboardStats(
  notaProyectada: (json['notaProyectada'] as num).toDouble(),
  porArea:
      (json['porArea'] as List<dynamic>?)
          ?.map((e) => AreaPerformance.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  evolucion:
      (json['evolucion'] as List<dynamic>?)
          ?.map((e) => GradePoint.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  preguntasVistas: (json['preguntasVistas'] as num?)?.toInt() ?? 0,
  preguntasTotalesBanco: (json['preguntasTotalesBanco'] as num?)?.toInt() ?? 0,
  simulacrosCompletados: (json['simulacrosCompletados'] as num?)?.toInt() ?? 0,
  preguntasRestantesHoy: (json['preguntasRestantesHoy'] as num?)?.toInt(),
);

Map<String, dynamic> _$DashboardStatsToJson(_DashboardStats instance) =>
    <String, dynamic>{
      'notaProyectada': instance.notaProyectada,
      'porArea': instance.porArea,
      'evolucion': instance.evolucion,
      'preguntasVistas': instance.preguntasVistas,
      'preguntasTotalesBanco': instance.preguntasTotalesBanco,
      'simulacrosCompletados': instance.simulacrosCompletados,
      'preguntasRestantesHoy': instance.preguntasRestantesHoy,
    };

_RankingEntry _$RankingEntryFromJson(Map<String, dynamic> json) =>
    _RankingEntry(
      posicion: (json['posicion'] as num).toInt(),
      usuarioNombre: json['usuarioNombre'] as String,
      promedio: (json['promedio'] as num).toDouble(),
      universidad: json['universidad'] as String?,
      esUsuarioActual: json['esUsuarioActual'] as bool? ?? false,
      tiempoTotalMs: (json['tiempoTotalMs'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RankingEntryToJson(_RankingEntry instance) =>
    <String, dynamic>{
      'posicion': instance.posicion,
      'usuarioNombre': instance.usuarioNombre,
      'promedio': instance.promedio,
      'universidad': instance.universidad,
      'esUsuarioActual': instance.esUsuarioActual,
      'tiempoTotalMs': instance.tiempoTotalMs,
    };
