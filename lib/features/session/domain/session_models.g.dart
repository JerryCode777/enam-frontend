// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_QuestionOption _$QuestionOptionFromJson(Map<String, dynamic> json) =>
    _QuestionOption(
      id: json['id'] as String,
      texto: json['texto'] as String,
      esCorrecta: json['esCorrecta'] as bool?,
      explicacion: json['explicacion'] as String?,
    );

Map<String, dynamic> _$QuestionOptionToJson(_QuestionOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'texto': instance.texto,
      'esCorrecta': instance.esCorrecta,
      'explicacion': instance.explicacion,
    };

_Question _$QuestionFromJson(Map<String, dynamic> json) => _Question(
  id: json['id'] as String,
  enunciado: json['enunciado'] as String,
  opciones: (json['opciones'] as List<dynamic>)
      .map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
      .toList(),
  areaId: json['areaId'] as String?,
  subtemaId: json['subtemaId'] as String?,
  tipo:
      $enumDecodeNullable(_$QuestionTypeEnumMap, json['tipo']) ??
      QuestionType.casoClinico,
  dificultad: (json['dificultad'] as num?)?.toInt() ?? 2,
  origenAnio: (json['origenAnio'] as num?)?.toInt(),
  imagenes:
      (json['imagenes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  explicacion: json['explicacion'] as String?,
  porcentajeAciertoGlobal: (json['porcentajeAciertoGlobal'] as num?)
      ?.toDouble(),
);

Map<String, dynamic> _$QuestionToJson(_Question instance) => <String, dynamic>{
  'id': instance.id,
  'enunciado': instance.enunciado,
  'opciones': instance.opciones,
  'areaId': instance.areaId,
  'subtemaId': instance.subtemaId,
  'tipo': _$QuestionTypeEnumMap[instance.tipo]!,
  'dificultad': instance.dificultad,
  'origenAnio': instance.origenAnio,
  'imagenes': instance.imagenes,
  'explicacion': instance.explicacion,
  'porcentajeAciertoGlobal': instance.porcentajeAciertoGlobal,
};

const _$QuestionTypeEnumMap = {
  QuestionType.casoClinico: 'caso_clinico',
  QuestionType.directa: 'directa',
};

_Answer _$AnswerFromJson(Map<String, dynamic> json) => _Answer(
  questionId: json['questionId'] as String,
  optionId: json['optionId'] as String?,
  esCorrecta: json['esCorrecta'] as bool?,
  tiempoMs: (json['tiempoMs'] as num?)?.toInt() ?? 0,
  marcada: json['marcada'] as bool? ?? false,
  respondidaOffline: json['respondidaOffline'] as bool? ?? false,
);

Map<String, dynamic> _$AnswerToJson(_Answer instance) => <String, dynamic>{
  'questionId': instance.questionId,
  'optionId': instance.optionId,
  'esCorrecta': instance.esCorrecta,
  'tiempoMs': instance.tiempoMs,
  'marcada': instance.marcada,
  'respondidaOffline': instance.respondidaOffline,
};

_PracticeConfig _$PracticeConfigFromJson(Map<String, dynamic> json) =>
    _PracticeConfig(
      areaIds:
          (json['areaIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      subtemaIds:
          (json['subtemaIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      cantidadPreguntas: (json['cantidadPreguntas'] as num?)?.toInt() ?? 20,
      origen:
          $enumDecodeNullable(_$QuestionSourceEnumMap, json['origen']) ??
          QuestionSource.todas,
    );

Map<String, dynamic> _$PracticeConfigToJson(_PracticeConfig instance) =>
    <String, dynamic>{
      'areaIds': instance.areaIds,
      'subtemaIds': instance.subtemaIds,
      'cantidadPreguntas': instance.cantidadPreguntas,
      'origen': _$QuestionSourceEnumMap[instance.origen]!,
    };

const _$QuestionSourceEnumMap = {
  QuestionSource.todas: 'todas',
  QuestionSource.noVistas: 'no_vistas',
  QuestionSource.falladas: 'falladas',
};

_OpenSession _$OpenSessionFromJson(Map<String, dynamic> json) => _OpenSession(
  id: json['id'] as String,
  tipo: $enumDecode(_$SessionTypeEnumMap, json['tipo']),
  iniciadaEn: DateTime.parse(json['iniciadaEn'] as String),
  expiraEn: json['expiraEn'] == null
      ? null
      : DateTime.parse(json['expiraEn'] as String),
  respondidas: (json['respondidas'] as num?)?.toInt() ?? 0,
  totalPreguntas: (json['totalPreguntas'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$OpenSessionToJson(_OpenSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tipo': _$SessionTypeEnumMap[instance.tipo]!,
      'iniciadaEn': instance.iniciadaEn.toIso8601String(),
      'expiraEn': instance.expiraEn?.toIso8601String(),
      'respondidas': instance.respondidas,
      'totalPreguntas': instance.totalPreguntas,
    };

const _$SessionTypeEnumMap = {
  SessionType.practica: 'practica',
  SessionType.simulacro: 'simulacro',
  SessionType.simulacroNacional: 'simulacro_nacional',
};

_NationalMock _$NationalMockFromJson(Map<String, dynamic> json) =>
    _NationalMock(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      inicio: DateTime.parse(json['inicio'] as String),
      fin: DateTime.parse(json['fin'] as String),
      duracionMinutos: (json['duracionMinutos'] as num?)?.toInt() ?? 0,
      participantes: (json['participantes'] as num?)?.toInt() ?? 0,
      inscrito: json['inscrito'] as bool? ?? false,
      estado:
          $enumDecodeNullable(_$NationalMockStatusEnumMap, json['estado']) ??
          NationalMockStatus.programado,
      totalPreguntas: (json['totalPreguntas'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NationalMockToJson(_NationalMock instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nombre': instance.nombre,
      'inicio': instance.inicio.toIso8601String(),
      'fin': instance.fin.toIso8601String(),
      'duracionMinutos': instance.duracionMinutos,
      'participantes': instance.participantes,
      'inscrito': instance.inscrito,
      'estado': _$NationalMockStatusEnumMap[instance.estado]!,
      'totalPreguntas': instance.totalPreguntas,
    };

const _$NationalMockStatusEnumMap = {
  NationalMockStatus.programado: 'programado',
  NationalMockStatus.enCurso: 'en_curso',
  NationalMockStatus.cerrado: 'cerrado',
};

_StudySession _$StudySessionFromJson(Map<String, dynamic> json) =>
    _StudySession(
      id: json['id'] as String,
      tipo: $enumDecode(_$SessionTypeEnumMap, json['tipo']),
      estado: $enumDecode(_$SessionStatusEnumMap, json['estado']),
      iniciadaEn: DateTime.parse(json['iniciadaEn'] as String),
      preguntas:
          (json['preguntas'] as List<dynamic>?)
              ?.map((e) => Question.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      respuestas:
          (json['respuestas'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, Answer.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      finalizadaEn: json['finalizadaEn'] == null
          ? null
          : DateTime.parse(json['finalizadaEn'] as String),
      expiraEn: json['expiraEn'] == null
          ? null
          : DateTime.parse(json['expiraEn'] as String),
      nota: (json['nota'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$StudySessionToJson(_StudySession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tipo': _$SessionTypeEnumMap[instance.tipo]!,
      'estado': _$SessionStatusEnumMap[instance.estado]!,
      'iniciadaEn': instance.iniciadaEn.toIso8601String(),
      'preguntas': instance.preguntas,
      'respuestas': instance.respuestas,
      'finalizadaEn': instance.finalizadaEn?.toIso8601String(),
      'expiraEn': instance.expiraEn?.toIso8601String(),
      'nota': instance.nota,
    };

const _$SessionStatusEnumMap = {
  SessionStatus.enCurso: 'en_curso',
  SessionStatus.finalizada: 'finalizada',
  SessionStatus.expirada: 'expirada',
};
