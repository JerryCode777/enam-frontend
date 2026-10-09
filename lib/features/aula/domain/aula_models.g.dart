// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'aula_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Profe _$ProfeFromJson(Map<String, dynamic> json) => _Profe(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  articulo: json['articulo'] as String?,
  retratoUrl: json['retratoUrl'] as String?,
  retratoMiniUrl: json['retratoMiniUrl'] as String?,
);

Map<String, dynamic> _$ProfeToJson(_Profe instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'articulo': instance.articulo,
  'retratoUrl': instance.retratoUrl,
  'retratoMiniUrl': instance.retratoMiniUrl,
};

_CursoResumen _$CursoResumenFromJson(Map<String, dynamic> json) =>
    _CursoResumen(
      id: json['id'] as String,
      tipo:
          $enumDecodeNullable(
            _$TipoDeCursoEnumMap,
            json['tipo'],
            unknownValue: TipoDeCurso.desconocido,
          ) ??
          TipoDeCurso.area,
      areaId: json['areaId'] as String?,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String? ?? '',
      lema: json['lema'] as String? ?? '',
      profe: json['profe'] == null
          ? null
          : Profe.fromJson(json['profe'] as Map<String, dynamic>),
      portadaUrl: json['portadaUrl'] as String?,
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      publicado: json['publicado'] as bool? ?? false,
      clases: (json['clases'] as num?)?.toInt() ?? 0,
      disponibles: (json['disponibles'] as num?)?.toInt() ?? 0,
      gratis: (json['gratis'] as num?)?.toInt() ?? 0,
      duracionS: (json['duracionS'] as num?)?.toInt() ?? 0,
      completadas: (json['completadas'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CursoResumenToJson(_CursoResumen instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tipo': _$TipoDeCursoEnumMap[instance.tipo]!,
      'areaId': instance.areaId,
      'titulo': instance.titulo,
      'descripcion': instance.descripcion,
      'lema': instance.lema,
      'profe': instance.profe,
      'portadaUrl': instance.portadaUrl,
      'orden': instance.orden,
      'publicado': instance.publicado,
      'clases': instance.clases,
      'disponibles': instance.disponibles,
      'gratis': instance.gratis,
      'duracionS': instance.duracionS,
      'completadas': instance.completadas,
    };

const _$TipoDeCursoEnumMap = {
  TipoDeCurso.area: 'area',
  TipoDeCurso.repaso: 'repaso',
  TipoDeCurso.desconocido: '__desconocido__',
};

_ProgresoDeClase _$ProgresoDeClaseFromJson(Map<String, dynamic> json) =>
    _ProgresoDeClase(
      segundosVistos: (json['segundosVistos'] as num?)?.toInt() ?? 0,
      posicionS: (json['posicionS'] as num?)?.toInt() ?? 0,
      completada: json['completada'] as bool? ?? false,
    );

Map<String, dynamic> _$ProgresoDeClaseToJson(_ProgresoDeClase instance) =>
    <String, dynamic>{
      'segundosVistos': instance.segundosVistos,
      'posicionS': instance.posicionS,
      'completada': instance.completada,
    };

_ClaseResumen _$ClaseResumenFromJson(Map<String, dynamic> json) =>
    _ClaseResumen(
      id: json['id'] as String,
      codigo: json['codigo'] as String? ?? '',
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      titulo: json['titulo'] as String,
      duracionS: (json['duracionS'] as num?)?.toInt() ?? 0,
      estado:
          $enumDecodeNullable(
            _$EstadoDeClaseEnumMap,
            json['estado'],
            unknownValue: EstadoDeClase.desconocido,
          ) ??
          EstadoDeClase.proximamente,
      gratis: json['gratis'] as bool? ?? false,
      bloqueada: json['bloqueada'] as bool? ?? false,
      miniaturaUrl: json['miniaturaUrl'] as String?,
      progreso: json['progreso'] == null
          ? const ProgresoDeClase()
          : ProgresoDeClase.fromJson(json['progreso'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ClaseResumenToJson(_ClaseResumen instance) =>
    <String, dynamic>{
      'id': instance.id,
      'codigo': instance.codigo,
      'orden': instance.orden,
      'titulo': instance.titulo,
      'duracionS': instance.duracionS,
      'estado': _$EstadoDeClaseEnumMap[instance.estado]!,
      'gratis': instance.gratis,
      'bloqueada': instance.bloqueada,
      'miniaturaUrl': instance.miniaturaUrl,
      'progreso': instance.progreso,
    };

const _$EstadoDeClaseEnumMap = {
  EstadoDeClase.disponible: 'disponible',
  EstadoDeClase.proximamente: 'proximamente',
  EstadoDeClase.desconocido: '__desconocido__',
};

_Modulo _$ModuloFromJson(Map<String, dynamic> json) => _Modulo(
  id: json['id'] as String,
  codigo: json['codigo'] as String? ?? '',
  orden: (json['orden'] as num?)?.toInt() ?? 0,
  titulo: json['titulo'] as String,
  descripcion: json['descripcion'] as String? ?? '',
  nodoId: json['nodoId'] as String? ?? '',
  clases:
      (json['clases'] as List<dynamic>?)
          ?.map((e) => ClaseResumen.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ModuloToJson(_Modulo instance) => <String, dynamic>{
  'id': instance.id,
  'codigo': instance.codigo,
  'orden': instance.orden,
  'titulo': instance.titulo,
  'descripcion': instance.descripcion,
  'nodoId': instance.nodoId,
  'clases': instance.clases,
};

_Curso _$CursoFromJson(Map<String, dynamic> json) => _Curso(
  id: json['id'] as String,
  tipo:
      $enumDecodeNullable(
        _$TipoDeCursoEnumMap,
        json['tipo'],
        unknownValue: TipoDeCurso.desconocido,
      ) ??
      TipoDeCurso.area,
  areaId: json['areaId'] as String?,
  titulo: json['titulo'] as String,
  descripcion: json['descripcion'] as String? ?? '',
  lema: json['lema'] as String? ?? '',
  profe: json['profe'] == null
      ? null
      : Profe.fromJson(json['profe'] as Map<String, dynamic>),
  portadaUrl: json['portadaUrl'] as String?,
  clases: (json['clases'] as num?)?.toInt() ?? 0,
  disponibles: (json['disponibles'] as num?)?.toInt() ?? 0,
  gratis: (json['gratis'] as num?)?.toInt() ?? 0,
  duracionS: (json['duracionS'] as num?)?.toInt() ?? 0,
  completadas: (json['completadas'] as num?)?.toInt() ?? 0,
  premium: json['premium'] as bool? ?? false,
  modulos:
      (json['modulos'] as List<dynamic>?)
          ?.map((e) => Modulo.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  continuar: json['continuar'] == null
      ? null
      : ClaseResumen.fromJson(json['continuar'] as Map<String, dynamic>),
);

Map<String, dynamic> _$CursoToJson(_Curso instance) => <String, dynamic>{
  'id': instance.id,
  'tipo': _$TipoDeCursoEnumMap[instance.tipo]!,
  'areaId': instance.areaId,
  'titulo': instance.titulo,
  'descripcion': instance.descripcion,
  'lema': instance.lema,
  'profe': instance.profe,
  'portadaUrl': instance.portadaUrl,
  'clases': instance.clases,
  'disponibles': instance.disponibles,
  'gratis': instance.gratis,
  'duracionS': instance.duracionS,
  'completadas': instance.completadas,
  'premium': instance.premium,
  'modulos': instance.modulos,
  'continuar': instance.continuar,
};

_Referencia _$ReferenciaFromJson(Map<String, dynamic> json) => _Referencia(
  id: json['id'] as String,
  tipo:
      $enumDecodeNullable(
        _$TipoDeReferenciaEnumMap,
        json['tipo'],
        unknownValue: TipoDeReferencia.desconocido,
      ) ??
      TipoDeReferencia.desconocido,
  cita: json['cita'] as String,
  anio: (json['anio'] as num?)?.toInt(),
  edicion: json['edicion'] as String?,
  capitulo: json['capitulo'] as String?,
  paginas: json['paginas'] as String?,
  url: json['url'] as String?,
  doi: json['doi'] as String?,
);

Map<String, dynamic> _$ReferenciaToJson(_Referencia instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tipo': _$TipoDeReferenciaEnumMap[instance.tipo]!,
      'cita': instance.cita,
      'anio': instance.anio,
      'edicion': instance.edicion,
      'capitulo': instance.capitulo,
      'paginas': instance.paginas,
      'url': instance.url,
      'doi': instance.doi,
    };

const _$TipoDeReferenciaEnumMap = {
  TipoDeReferencia.norma: 'norma',
  TipoDeReferencia.guia: 'guia',
  TipoDeReferencia.libro: 'libro',
  TipoDeReferencia.articulo: 'articulo',
  TipoDeReferencia.desconocido: '__desconocido__',
};

_Vecina _$VecinaFromJson(Map<String, dynamic> json) => _Vecina(
  id: json['id'] as String,
  titulo: json['titulo'] as String,
  bloqueada: json['bloqueada'] as bool? ?? false,
);

Map<String, dynamic> _$VecinaToJson(_Vecina instance) => <String, dynamic>{
  'id': instance.id,
  'titulo': instance.titulo,
  'bloqueada': instance.bloqueada,
};

_Clase _$ClaseFromJson(Map<String, dynamic> json) => _Clase(
  id: json['id'] as String,
  codigo: json['codigo'] as String? ?? '',
  titulo: json['titulo'] as String,
  duracionS: (json['duracionS'] as num?)?.toInt() ?? 0,
  estado:
      $enumDecodeNullable(
        _$EstadoDeClaseEnumMap,
        json['estado'],
        unknownValue: EstadoDeClase.desconocido,
      ) ??
      EstadoDeClase.proximamente,
  gratis: json['gratis'] as bool? ?? false,
  bloqueada: json['bloqueada'] as bool? ?? false,
  miniaturaUrl: json['miniaturaUrl'] as String?,
  progreso: json['progreso'] == null
      ? const ProgresoDeClase()
      : ProgresoDeClase.fromJson(json['progreso'] as Map<String, dynamic>),
  cursoId: json['cursoId'] as String,
  cursoTitulo: json['cursoTitulo'] as String? ?? '',
  profe: json['profe'] == null
      ? null
      : Profe.fromJson(json['profe'] as Map<String, dynamic>),
  moduloId: json['moduloId'] as String? ?? '',
  objetivos:
      (json['objetivos'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  temas:
      (json['temas'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  referencias:
      (json['referencias'] as List<dynamic>?)
          ?.map((e) => Referencia.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  videoUrl: json['videoUrl'] as String?,
  subtitulosUrl: json['subtitulosUrl'] as String?,
  practicaDisponible: json['practicaDisponible'] as bool? ?? false,
  anterior: json['anterior'] == null
      ? null
      : Vecina.fromJson(json['anterior'] as Map<String, dynamic>),
  siguiente: json['siguiente'] == null
      ? null
      : Vecina.fromJson(json['siguiente'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ClaseToJson(_Clase instance) => <String, dynamic>{
  'id': instance.id,
  'codigo': instance.codigo,
  'titulo': instance.titulo,
  'duracionS': instance.duracionS,
  'estado': _$EstadoDeClaseEnumMap[instance.estado]!,
  'gratis': instance.gratis,
  'bloqueada': instance.bloqueada,
  'miniaturaUrl': instance.miniaturaUrl,
  'progreso': instance.progreso,
  'cursoId': instance.cursoId,
  'cursoTitulo': instance.cursoTitulo,
  'profe': instance.profe,
  'moduloId': instance.moduloId,
  'objetivos': instance.objetivos,
  'temas': instance.temas,
  'referencias': instance.referencias,
  'videoUrl': instance.videoUrl,
  'subtitulosUrl': instance.subtitulosUrl,
  'practicaDisponible': instance.practicaDisponible,
  'anterior': instance.anterior,
  'siguiente': instance.siguiente,
};

_SeguirViendo _$SeguirViendoFromJson(Map<String, dynamic> json) =>
    _SeguirViendo(
      cursoId: json['cursoId'] as String,
      cursoTitulo: json['cursoTitulo'] as String? ?? '',
      clase: ClaseResumen.fromJson(json['clase'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SeguirViendoToJson(_SeguirViendo instance) =>
    <String, dynamic>{
      'cursoId': instance.cursoId,
      'cursoTitulo': instance.cursoTitulo,
      'clase': instance.clase,
    };
