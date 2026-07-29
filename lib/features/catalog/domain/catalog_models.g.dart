// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CatalogNode _$CatalogNodeFromJson(Map<String, dynamic> json) => _CatalogNode(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  nivel: json['nivel'] as String,
  peso: (json['peso'] as num?)?.toInt(),
  grupo: json['grupo'] as String?,
  hijos:
      (json['hijos'] as List<dynamic>?)
          ?.map((e) => CatalogNode.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  preguntasDisponibles: (json['preguntasDisponibles'] as num?)?.toInt() ?? 0,
  preguntasVistas: (json['preguntasVistas'] as num?)?.toInt() ?? 0,
  respuestasTotales: (json['respuestasTotales'] as num?)?.toInt() ?? 0,
  respuestasCorrectas: (json['respuestasCorrectas'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$CatalogNodeToJson(_CatalogNode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'nivel': instance.nivel,
      'peso': instance.peso,
      'grupo': instance.grupo,
      'hijos': instance.hijos,
      'preguntasDisponibles': instance.preguntasDisponibles,
      'preguntasVistas': instance.preguntasVistas,
      'respuestasTotales': instance.respuestasTotales,
      'respuestasCorrectas': instance.respuestasCorrectas,
    };
