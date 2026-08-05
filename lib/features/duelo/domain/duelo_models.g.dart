// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'duelo_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DueloDTO _$DueloDTOFromJson(Map<String, dynamic> json) => _DueloDTO(
  id: json['id'] as String,
  estado: $enumDecode(
    _$EstadoDueloEnumMap,
    json['estado'],
    unknownValue: EstadoDuelo.desconocido,
  ),
  origen: $enumDecode(
    _$OrigenDueloEnumMap,
    json['origen'],
    unknownValue: OrigenDuelo.desconocido,
  ),
  codigo: json['codigo'] as String?,
  enlace: json['enlace'] as String?,
  contraBot: json['contraBot'] as bool? ?? false,
  completo: json['completo'] as bool? ?? false,
  totalPreguntas: (json['totalPreguntas'] as num?)?.toInt() ?? 10,
  rival: json['rival'] as String?,
  esTuyo: json['esTuyo'] as bool? ?? false,
  expiraEn: json['expiraEn'] == null
      ? null
      : DateTime.parse(json['expiraEn'] as String),
  revanchaDe: json['revanchaDe'] as String?,
  faltanParaBotSegundos: (json['faltanParaBotSegundos'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$DueloDTOToJson(_DueloDTO instance) => <String, dynamic>{
  'id': instance.id,
  'estado': _$EstadoDueloEnumMap[instance.estado]!,
  'origen': _$OrigenDueloEnumMap[instance.origen]!,
  'codigo': instance.codigo,
  'enlace': instance.enlace,
  'contraBot': instance.contraBot,
  'completo': instance.completo,
  'totalPreguntas': instance.totalPreguntas,
  'rival': instance.rival,
  'esTuyo': instance.esTuyo,
  'expiraEn': instance.expiraEn?.toIso8601String(),
  'revanchaDe': instance.revanchaDe,
  'faltanParaBotSegundos': instance.faltanParaBotSegundos,
};

const _$EstadoDueloEnumMap = {
  EstadoDuelo.esperando: 'esperando',
  EstadoDuelo.enCurso: 'en_curso',
  EstadoDuelo.terminado: 'terminado',
  EstadoDuelo.abandonado: 'abandonado',
  EstadoDuelo.caducado: 'caducado',
  EstadoDuelo.desconocido: '__desconocido__',
};

const _$OrigenDueloEnumMap = {
  OrigenDuelo.aleatorio: 'aleatorio',
  OrigenDuelo.enlace: 'enlace',
  OrigenDuelo.desconocido: '__desconocido__',
};

_PaseDeDuelo _$PaseDeDueloFromJson(Map<String, dynamic> json) => _PaseDeDuelo(
  activo: json['activo'] as bool? ?? false,
  disponible: json['disponible'] as bool? ?? false,
  restantes: (json['restantes'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$PaseDeDueloToJson(_PaseDeDuelo instance) =>
    <String, dynamic>{
      'activo': instance.activo,
      'disponible': instance.disponible,
      'restantes': instance.restantes,
    };

_TicketDeDuelo _$TicketDeDueloFromJson(Map<String, dynamic> json) =>
    _TicketDeDuelo(
      ticket: json['ticket'] as String,
      expira: DateTime.parse(json['expira'] as String),
      url: json['url'] as String,
    );

Map<String, dynamic> _$TicketDeDueloToJson(_TicketDeDuelo instance) =>
    <String, dynamic>{
      'ticket': instance.ticket,
      'expira': instance.expira.toIso8601String(),
      'url': instance.url,
    };

_LadoDuelo _$LadoDueloFromJson(Map<String, dynamic> json) => _LadoDuelo(
  nombre: json['nombre'] as String? ?? '',
  esBot: json['esBot'] as bool? ?? false,
  respondidas: (json['respondidas'] as num?)?.toInt() ?? 0,
  aciertos: (json['aciertos'] as num?)?.toInt(),
  conectado: json['conectado'] as bool? ?? true,
  resultados:
      (json['resultados'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$ResultadoPorPreguntaEnumMap, e))
          .toList() ??
      const <ResultadoPorPregunta>[],
);

Map<String, dynamic> _$LadoDueloToJson(_LadoDuelo instance) =>
    <String, dynamic>{
      'nombre': instance.nombre,
      'esBot': instance.esBot,
      'respondidas': instance.respondidas,
      'aciertos': instance.aciertos,
      'conectado': instance.conectado,
      'resultados': instance.resultados
          .map((e) => _$ResultadoPorPreguntaEnumMap[e]!)
          .toList(),
    };

const _$ResultadoPorPreguntaEnumMap = {
  ResultadoPorPregunta.acierto: 'acierto',
  ResultadoPorPregunta.fallo: 'fallo',
  ResultadoPorPregunta.enBlanco: 'enBlanco',
  ResultadoPorPregunta.sinContestar: 'sinContestar',
};

_EstadoDeLaPartida _$EstadoDeLaPartidaFromJson(Map<String, dynamic> json) =>
    _EstadoDeLaPartida(
      id: json['id'] as String,
      estado: $enumDecode(_$EstadoDueloEnumMap, json['estado']),
      totalPreguntas: (json['totalPreguntas'] as num?)?.toInt() ?? 10,
      tu: LadoDuelo.fromJson(json['tu'] as Map<String, dynamic>),
      rival: LadoDuelo.fromJson(json['rival'] as Map<String, dynamic>),
      botBloqueado: json['botBloqueado'] as bool? ?? false,
    );

Map<String, dynamic> _$EstadoDeLaPartidaToJson(_EstadoDeLaPartida instance) =>
    <String, dynamic>{
      'id': instance.id,
      'estado': _$EstadoDueloEnumMap[instance.estado]!,
      'totalPreguntas': instance.totalPreguntas,
      'tu': instance.tu,
      'rival': instance.rival,
      'botBloqueado': instance.botBloqueado,
    };

_OpcionDuelo _$OpcionDueloFromJson(Map<String, dynamic> json) =>
    _OpcionDuelo(id: json['id'] as String, texto: json['texto'] as String);

Map<String, dynamic> _$OpcionDueloToJson(_OpcionDuelo instance) =>
    <String, dynamic>{'id': instance.id, 'texto': instance.texto};

_PreguntaEnJuego _$PreguntaEnJuegoFromJson(Map<String, dynamic> json) =>
    _PreguntaEnJuego(
      orden: (json['orden'] as num).toInt(),
      totalPreguntas: (json['totalPreguntas'] as num?)?.toInt() ?? 10,
      enunciado: json['enunciado'] as String? ?? '',
      opciones:
          (json['opciones'] as List<dynamic>?)
              ?.map((e) => OpcionDuelo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OpcionDuelo>[],
      cierraEn: DateTime.parse(json['cierraEn'] as String),
      segundos: (json['segundos'] as num?)?.toInt() ?? 30,
    );

Map<String, dynamic> _$PreguntaEnJuegoToJson(_PreguntaEnJuego instance) =>
    <String, dynamic>{
      'orden': instance.orden,
      'totalPreguntas': instance.totalPreguntas,
      'enunciado': instance.enunciado,
      'opciones': instance.opciones,
      'cierraEn': instance.cierraEn.toIso8601String(),
      'segundos': instance.segundos,
    };

_ResultadoDePregunta _$ResultadoDePreguntaFromJson(Map<String, dynamic> json) =>
    _ResultadoDePregunta(
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      opcionCorrectaId: json['opcionCorrectaId'] as String? ?? '',
      explicacion: json['explicacion'] as String? ?? '',
      tuOpcionId: json['tuOpcionId'] as String?,
      acertaste: json['acertaste'] as bool? ?? false,
      tuTiempoMs: (json['tuTiempoMs'] as num?)?.toInt() ?? 0,
      tusAciertos: (json['tusAciertos'] as num?)?.toInt() ?? 0,
      rivalRespondio: json['rivalRespondio'] as bool? ?? false,
      rivalRespondidas: (json['rivalRespondidas'] as num?)?.toInt() ?? 0,
      siguienteEnMs: (json['siguienteEnMs'] as num?)?.toInt() ?? 0,
      esUltima: json['esUltima'] as bool? ?? false,
    );

Map<String, dynamic> _$ResultadoDePreguntaToJson(
  _ResultadoDePregunta instance,
) => <String, dynamic>{
  'orden': instance.orden,
  'opcionCorrectaId': instance.opcionCorrectaId,
  'explicacion': instance.explicacion,
  'tuOpcionId': instance.tuOpcionId,
  'acertaste': instance.acertaste,
  'tuTiempoMs': instance.tuTiempoMs,
  'tusAciertos': instance.tusAciertos,
  'rivalRespondio': instance.rivalRespondio,
  'rivalRespondidas': instance.rivalRespondidas,
  'siguienteEnMs': instance.siguienteEnMs,
  'esUltima': instance.esUltima,
};

_OpcionRevisada _$OpcionRevisadaFromJson(Map<String, dynamic> json) =>
    _OpcionRevisada(
      id: json['id'] as String,
      texto: json['texto'] as String,
      esCorrecta: json['esCorrecta'] as bool? ?? false,
    );

Map<String, dynamic> _$OpcionRevisadaToJson(_OpcionRevisada instance) =>
    <String, dynamic>{
      'id': instance.id,
      'texto': instance.texto,
      'esCorrecta': instance.esCorrecta,
    };

_PreguntaRevisada _$PreguntaRevisadaFromJson(Map<String, dynamic> json) =>
    _PreguntaRevisada(
      orden: (json['orden'] as num).toInt(),
      enunciado: json['enunciado'] as String? ?? '',
      opciones:
          (json['opciones'] as List<dynamic>?)
              ?.map((e) => OpcionRevisada.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <OpcionRevisada>[],
      explicacion: json['explicacion'] as String? ?? '',
      tuOpcionId: json['tuOpcionId'] as String?,
      acertaste: json['acertaste'] as bool? ?? false,
      rivalOpcionId: json['rivalOpcionId'] as String?,
      rivalAcerto: json['rivalAcerto'] as bool? ?? false,
      tuEstado:
          $enumDecodeNullable(_$EstadoDeRespuestaEnumMap, json['tuEstado']) ??
          EstadoDeRespuesta.enBlanco,
      rivalEstado:
          $enumDecodeNullable(
            _$EstadoDeRespuestaEnumMap,
            json['rivalEstado'],
          ) ??
          EstadoDeRespuesta.enBlanco,
    );

Map<String, dynamic> _$PreguntaRevisadaToJson(_PreguntaRevisada instance) =>
    <String, dynamic>{
      'orden': instance.orden,
      'enunciado': instance.enunciado,
      'opciones': instance.opciones,
      'explicacion': instance.explicacion,
      'tuOpcionId': instance.tuOpcionId,
      'acertaste': instance.acertaste,
      'rivalOpcionId': instance.rivalOpcionId,
      'rivalAcerto': instance.rivalAcerto,
      'tuEstado': _$EstadoDeRespuestaEnumMap[instance.tuEstado]!,
      'rivalEstado': _$EstadoDeRespuestaEnumMap[instance.rivalEstado]!,
    };

const _$EstadoDeRespuestaEnumMap = {
  EstadoDeRespuesta.acierto: 'acierto',
  EstadoDeRespuesta.fallo: 'fallo',
  EstadoDeRespuesta.enBlanco: 'enBlanco',
};

_FinalDeDuelo _$FinalDeDueloFromJson(Map<String, dynamic> json) =>
    _FinalDeDuelo(
      desenlace:
          $enumDecodeNullable(_$DesenlaceEnumMap, json['desenlace']) ??
          Desenlace.empate,
      tusAciertos: (json['tusAciertos'] as num?)?.toInt() ?? 0,
      rivalAciertos: (json['rivalAciertos'] as num?)?.toInt() ?? 0,
      tuNota: (json['tuNota'] as num?)?.toDouble() ?? 0,
      rivalNota: (json['rivalNota'] as num?)?.toDouble() ?? 0,
      tuTiempoTotalMs: (json['tuTiempoTotalMs'] as num?)?.toInt() ?? 0,
      rivalTiempoTotalMs: (json['rivalTiempoTotalMs'] as num?)?.toInt() ?? 0,
      porAbandono: json['porAbandono'] as bool? ?? false,
      porTiempo: json['porTiempo'] as bool? ?? false,
      conPaseGratis: json['conPaseGratis'] as bool? ?? false,
      revision:
          (json['revision'] as List<dynamic>?)
              ?.map((e) => PreguntaRevisada.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <PreguntaRevisada>[],
    );

Map<String, dynamic> _$FinalDeDueloToJson(_FinalDeDuelo instance) =>
    <String, dynamic>{
      'desenlace': _$DesenlaceEnumMap[instance.desenlace]!,
      'tusAciertos': instance.tusAciertos,
      'rivalAciertos': instance.rivalAciertos,
      'tuNota': instance.tuNota,
      'rivalNota': instance.rivalNota,
      'tuTiempoTotalMs': instance.tuTiempoTotalMs,
      'rivalTiempoTotalMs': instance.rivalTiempoTotalMs,
      'porAbandono': instance.porAbandono,
      'porTiempo': instance.porTiempo,
      'conPaseGratis': instance.conPaseGratis,
      'revision': instance.revision,
    };

const _$DesenlaceEnumMap = {
  Desenlace.ganaste: 'ganaste',
  Desenlace.perdiste: 'perdiste',
  Desenlace.empate: 'empate',
};

_EsperaDeDuelo _$EsperaDeDueloFromJson(Map<String, dynamic> json) =>
    _EsperaDeDuelo(
      esperandoSegundos: (json['esperandoSegundos'] as num?)?.toInt() ?? 0,
      faltanSegundos: (json['faltanSegundos'] as num?)?.toInt() ?? 0,
      codigo: json['codigo'] as String?,
      expiraEn: json['expiraEn'] == null
          ? null
          : DateTime.parse(json['expiraEn'] as String),
    );

Map<String, dynamic> _$EsperaDeDueloToJson(_EsperaDeDuelo instance) =>
    <String, dynamic>{
      'esperandoSegundos': instance.esperandoSegundos,
      'faltanSegundos': instance.faltanSegundos,
      'codigo': instance.codigo,
      'expiraEn': instance.expiraEn?.toIso8601String(),
    };
