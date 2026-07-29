// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Area _$AreaFromJson(Map<String, dynamic> json) => _Area(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  grupo: json['grupo'] as String,
  preguntasBlueprint: (json['preguntasBlueprint'] as num).toInt(),
  subtemas:
      (json['subtemas'] as List<dynamic>?)
          ?.map((e) => Subtopic.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  preguntasVistas: (json['preguntasVistas'] as num?)?.toInt() ?? 0,
  preguntasTotales: (json['preguntasTotales'] as num?)?.toInt() ?? 0,
  respuestasCorrectas: (json['respuestasCorrectas'] as num?)?.toInt() ?? 0,
  respuestasTotales: (json['respuestasTotales'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$AreaToJson(_Area instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'grupo': instance.grupo,
  'preguntasBlueprint': instance.preguntasBlueprint,
  'subtemas': instance.subtemas,
  'preguntasVistas': instance.preguntasVistas,
  'preguntasTotales': instance.preguntasTotales,
  'respuestasCorrectas': instance.respuestasCorrectas,
  'respuestasTotales': instance.respuestasTotales,
};

_Subtopic _$SubtopicFromJson(Map<String, dynamic> json) => _Subtopic(
  id: json['id'] as String,
  areaId: json['areaId'] as String,
  nombre: json['nombre'] as String,
  preguntasBlueprint: (json['preguntasBlueprint'] as num).toInt(),
  preguntasVistas: (json['preguntasVistas'] as num?)?.toInt() ?? 0,
  preguntasTotales: (json['preguntasTotales'] as num?)?.toInt() ?? 0,
  respuestasCorrectas: (json['respuestasCorrectas'] as num?)?.toInt() ?? 0,
  respuestasTotales: (json['respuestasTotales'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$SubtopicToJson(_Subtopic instance) => <String, dynamic>{
  'id': instance.id,
  'areaId': instance.areaId,
  'nombre': instance.nombre,
  'preguntasBlueprint': instance.preguntasBlueprint,
  'preguntasVistas': instance.preguntasVistas,
  'preguntasTotales': instance.preguntasTotales,
  'respuestasCorrectas': instance.respuestasCorrectas,
  'respuestasTotales': instance.respuestasTotales,
};
