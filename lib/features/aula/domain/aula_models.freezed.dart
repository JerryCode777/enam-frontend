// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'aula_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Profe {

 String get id; String get nombre; String? get articulo; String? get retratoUrl; String? get retratoMiniUrl;
/// Create a copy of Profe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProfeCopyWith<Profe> get copyWith => _$ProfeCopyWithImpl<Profe>(this as Profe, _$identity);

  /// Serializes this Profe to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Profe&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.articulo, articulo) || other.articulo == articulo)&&(identical(other.retratoUrl, retratoUrl) || other.retratoUrl == retratoUrl)&&(identical(other.retratoMiniUrl, retratoMiniUrl) || other.retratoMiniUrl == retratoMiniUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,articulo,retratoUrl,retratoMiniUrl);

@override
String toString() {
  return 'Profe(id: $id, nombre: $nombre, articulo: $articulo, retratoUrl: $retratoUrl, retratoMiniUrl: $retratoMiniUrl)';
}


}

/// @nodoc
abstract mixin class $ProfeCopyWith<$Res>  {
  factory $ProfeCopyWith(Profe value, $Res Function(Profe) _then) = _$ProfeCopyWithImpl;
@useResult
$Res call({
 String id, String nombre, String? articulo, String? retratoUrl, String? retratoMiniUrl
});




}
/// @nodoc
class _$ProfeCopyWithImpl<$Res>
    implements $ProfeCopyWith<$Res> {
  _$ProfeCopyWithImpl(this._self, this._then);

  final Profe _self;
  final $Res Function(Profe) _then;

/// Create a copy of Profe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? articulo = freezed,Object? retratoUrl = freezed,Object? retratoMiniUrl = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,articulo: freezed == articulo ? _self.articulo : articulo // ignore: cast_nullable_to_non_nullable
as String?,retratoUrl: freezed == retratoUrl ? _self.retratoUrl : retratoUrl // ignore: cast_nullable_to_non_nullable
as String?,retratoMiniUrl: freezed == retratoMiniUrl ? _self.retratoMiniUrl : retratoMiniUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Profe].
extension ProfePatterns on Profe {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Profe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Profe() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Profe value)  $default,){
final _that = this;
switch (_that) {
case _Profe():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Profe value)?  $default,){
final _that = this;
switch (_that) {
case _Profe() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nombre,  String? articulo,  String? retratoUrl,  String? retratoMiniUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Profe() when $default != null:
return $default(_that.id,_that.nombre,_that.articulo,_that.retratoUrl,_that.retratoMiniUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nombre,  String? articulo,  String? retratoUrl,  String? retratoMiniUrl)  $default,) {final _that = this;
switch (_that) {
case _Profe():
return $default(_that.id,_that.nombre,_that.articulo,_that.retratoUrl,_that.retratoMiniUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nombre,  String? articulo,  String? retratoUrl,  String? retratoMiniUrl)?  $default,) {final _that = this;
switch (_that) {
case _Profe() when $default != null:
return $default(_that.id,_that.nombre,_that.articulo,_that.retratoUrl,_that.retratoMiniUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Profe implements Profe {
  const _Profe({required this.id, required this.nombre, this.articulo, this.retratoUrl, this.retratoMiniUrl});
  factory _Profe.fromJson(Map<String, dynamic> json) => _$ProfeFromJson(json);

@override final  String id;
@override final  String nombre;
@override final  String? articulo;
@override final  String? retratoUrl;
@override final  String? retratoMiniUrl;

/// Create a copy of Profe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProfeCopyWith<_Profe> get copyWith => __$ProfeCopyWithImpl<_Profe>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProfeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Profe&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.articulo, articulo) || other.articulo == articulo)&&(identical(other.retratoUrl, retratoUrl) || other.retratoUrl == retratoUrl)&&(identical(other.retratoMiniUrl, retratoMiniUrl) || other.retratoMiniUrl == retratoMiniUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,articulo,retratoUrl,retratoMiniUrl);

@override
String toString() {
  return 'Profe(id: $id, nombre: $nombre, articulo: $articulo, retratoUrl: $retratoUrl, retratoMiniUrl: $retratoMiniUrl)';
}


}

/// @nodoc
abstract mixin class _$ProfeCopyWith<$Res> implements $ProfeCopyWith<$Res> {
  factory _$ProfeCopyWith(_Profe value, $Res Function(_Profe) _then) = __$ProfeCopyWithImpl;
@override @useResult
$Res call({
 String id, String nombre, String? articulo, String? retratoUrl, String? retratoMiniUrl
});




}
/// @nodoc
class __$ProfeCopyWithImpl<$Res>
    implements _$ProfeCopyWith<$Res> {
  __$ProfeCopyWithImpl(this._self, this._then);

  final _Profe _self;
  final $Res Function(_Profe) _then;

/// Create a copy of Profe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? articulo = freezed,Object? retratoUrl = freezed,Object? retratoMiniUrl = freezed,}) {
  return _then(_Profe(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,articulo: freezed == articulo ? _self.articulo : articulo // ignore: cast_nullable_to_non_nullable
as String?,retratoUrl: freezed == retratoUrl ? _self.retratoUrl : retratoUrl // ignore: cast_nullable_to_non_nullable
as String?,retratoMiniUrl: freezed == retratoMiniUrl ? _self.retratoMiniUrl : retratoMiniUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$CursoResumen {

 String get id;@JsonKey(unknownEnumValue: TipoDeCurso.desconocido) TipoDeCurso get tipo;/// Nulo en el repaso final, que no es un área.
 String? get areaId; String get titulo; String get descripcion; String get lema; Profe? get profe; String? get portadaUrl; int get orden;/// Sin ninguna clase disponible no está publicado: «Próximamente».
 bool get publicado;/// Todas las clases del temario, también las que vienen.
 int get clases; int get disponibles; int get gratis;/// Solo de las disponibles.
 int get duracionS; int get completadas;
/// Create a copy of CursoResumen
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CursoResumenCopyWith<CursoResumen> get copyWith => _$CursoResumenCopyWithImpl<CursoResumen>(this as CursoResumen, _$identity);

  /// Serializes this CursoResumen to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CursoResumen&&(identical(other.id, id) || other.id == id)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.lema, lema) || other.lema == lema)&&(identical(other.profe, profe) || other.profe == profe)&&(identical(other.portadaUrl, portadaUrl) || other.portadaUrl == portadaUrl)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.publicado, publicado) || other.publicado == publicado)&&(identical(other.clases, clases) || other.clases == clases)&&(identical(other.disponibles, disponibles) || other.disponibles == disponibles)&&(identical(other.gratis, gratis) || other.gratis == gratis)&&(identical(other.duracionS, duracionS) || other.duracionS == duracionS)&&(identical(other.completadas, completadas) || other.completadas == completadas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tipo,areaId,titulo,descripcion,lema,profe,portadaUrl,orden,publicado,clases,disponibles,gratis,duracionS,completadas);

@override
String toString() {
  return 'CursoResumen(id: $id, tipo: $tipo, areaId: $areaId, titulo: $titulo, descripcion: $descripcion, lema: $lema, profe: $profe, portadaUrl: $portadaUrl, orden: $orden, publicado: $publicado, clases: $clases, disponibles: $disponibles, gratis: $gratis, duracionS: $duracionS, completadas: $completadas)';
}


}

/// @nodoc
abstract mixin class $CursoResumenCopyWith<$Res>  {
  factory $CursoResumenCopyWith(CursoResumen value, $Res Function(CursoResumen) _then) = _$CursoResumenCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: TipoDeCurso.desconocido) TipoDeCurso tipo, String? areaId, String titulo, String descripcion, String lema, Profe? profe, String? portadaUrl, int orden, bool publicado, int clases, int disponibles, int gratis, int duracionS, int completadas
});


$ProfeCopyWith<$Res>? get profe;

}
/// @nodoc
class _$CursoResumenCopyWithImpl<$Res>
    implements $CursoResumenCopyWith<$Res> {
  _$CursoResumenCopyWithImpl(this._self, this._then);

  final CursoResumen _self;
  final $Res Function(CursoResumen) _then;

/// Create a copy of CursoResumen
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tipo = null,Object? areaId = freezed,Object? titulo = null,Object? descripcion = null,Object? lema = null,Object? profe = freezed,Object? portadaUrl = freezed,Object? orden = null,Object? publicado = null,Object? clases = null,Object? disponibles = null,Object? gratis = null,Object? duracionS = null,Object? completadas = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeCurso,areaId: freezed == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String?,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,lema: null == lema ? _self.lema : lema // ignore: cast_nullable_to_non_nullable
as String,profe: freezed == profe ? _self.profe : profe // ignore: cast_nullable_to_non_nullable
as Profe?,portadaUrl: freezed == portadaUrl ? _self.portadaUrl : portadaUrl // ignore: cast_nullable_to_non_nullable
as String?,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,publicado: null == publicado ? _self.publicado : publicado // ignore: cast_nullable_to_non_nullable
as bool,clases: null == clases ? _self.clases : clases // ignore: cast_nullable_to_non_nullable
as int,disponibles: null == disponibles ? _self.disponibles : disponibles // ignore: cast_nullable_to_non_nullable
as int,gratis: null == gratis ? _self.gratis : gratis // ignore: cast_nullable_to_non_nullable
as int,duracionS: null == duracionS ? _self.duracionS : duracionS // ignore: cast_nullable_to_non_nullable
as int,completadas: null == completadas ? _self.completadas : completadas // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CursoResumen
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfeCopyWith<$Res>? get profe {
    if (_self.profe == null) {
    return null;
  }

  return $ProfeCopyWith<$Res>(_self.profe!, (value) {
    return _then(_self.copyWith(profe: value));
  });
}
}


/// Adds pattern-matching-related methods to [CursoResumen].
extension CursoResumenPatterns on CursoResumen {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CursoResumen value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CursoResumen() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CursoResumen value)  $default,){
final _that = this;
switch (_that) {
case _CursoResumen():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CursoResumen value)?  $default,){
final _that = this;
switch (_that) {
case _CursoResumen() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: TipoDeCurso.desconocido)  TipoDeCurso tipo,  String? areaId,  String titulo,  String descripcion,  String lema,  Profe? profe,  String? portadaUrl,  int orden,  bool publicado,  int clases,  int disponibles,  int gratis,  int duracionS,  int completadas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CursoResumen() when $default != null:
return $default(_that.id,_that.tipo,_that.areaId,_that.titulo,_that.descripcion,_that.lema,_that.profe,_that.portadaUrl,_that.orden,_that.publicado,_that.clases,_that.disponibles,_that.gratis,_that.duracionS,_that.completadas);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: TipoDeCurso.desconocido)  TipoDeCurso tipo,  String? areaId,  String titulo,  String descripcion,  String lema,  Profe? profe,  String? portadaUrl,  int orden,  bool publicado,  int clases,  int disponibles,  int gratis,  int duracionS,  int completadas)  $default,) {final _that = this;
switch (_that) {
case _CursoResumen():
return $default(_that.id,_that.tipo,_that.areaId,_that.titulo,_that.descripcion,_that.lema,_that.profe,_that.portadaUrl,_that.orden,_that.publicado,_that.clases,_that.disponibles,_that.gratis,_that.duracionS,_that.completadas);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: TipoDeCurso.desconocido)  TipoDeCurso tipo,  String? areaId,  String titulo,  String descripcion,  String lema,  Profe? profe,  String? portadaUrl,  int orden,  bool publicado,  int clases,  int disponibles,  int gratis,  int duracionS,  int completadas)?  $default,) {final _that = this;
switch (_that) {
case _CursoResumen() when $default != null:
return $default(_that.id,_that.tipo,_that.areaId,_that.titulo,_that.descripcion,_that.lema,_that.profe,_that.portadaUrl,_that.orden,_that.publicado,_that.clases,_that.disponibles,_that.gratis,_that.duracionS,_that.completadas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CursoResumen extends CursoResumen {
  const _CursoResumen({required this.id, @JsonKey(unknownEnumValue: TipoDeCurso.desconocido) this.tipo = TipoDeCurso.area, this.areaId, required this.titulo, this.descripcion = '', this.lema = '', this.profe, this.portadaUrl, this.orden = 0, this.publicado = false, this.clases = 0, this.disponibles = 0, this.gratis = 0, this.duracionS = 0, this.completadas = 0}): super._();
  factory _CursoResumen.fromJson(Map<String, dynamic> json) => _$CursoResumenFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: TipoDeCurso.desconocido) final  TipoDeCurso tipo;
/// Nulo en el repaso final, que no es un área.
@override final  String? areaId;
@override final  String titulo;
@override@JsonKey() final  String descripcion;
@override@JsonKey() final  String lema;
@override final  Profe? profe;
@override final  String? portadaUrl;
@override@JsonKey() final  int orden;
/// Sin ninguna clase disponible no está publicado: «Próximamente».
@override@JsonKey() final  bool publicado;
/// Todas las clases del temario, también las que vienen.
@override@JsonKey() final  int clases;
@override@JsonKey() final  int disponibles;
@override@JsonKey() final  int gratis;
/// Solo de las disponibles.
@override@JsonKey() final  int duracionS;
@override@JsonKey() final  int completadas;

/// Create a copy of CursoResumen
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CursoResumenCopyWith<_CursoResumen> get copyWith => __$CursoResumenCopyWithImpl<_CursoResumen>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CursoResumenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CursoResumen&&(identical(other.id, id) || other.id == id)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.lema, lema) || other.lema == lema)&&(identical(other.profe, profe) || other.profe == profe)&&(identical(other.portadaUrl, portadaUrl) || other.portadaUrl == portadaUrl)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.publicado, publicado) || other.publicado == publicado)&&(identical(other.clases, clases) || other.clases == clases)&&(identical(other.disponibles, disponibles) || other.disponibles == disponibles)&&(identical(other.gratis, gratis) || other.gratis == gratis)&&(identical(other.duracionS, duracionS) || other.duracionS == duracionS)&&(identical(other.completadas, completadas) || other.completadas == completadas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tipo,areaId,titulo,descripcion,lema,profe,portadaUrl,orden,publicado,clases,disponibles,gratis,duracionS,completadas);

@override
String toString() {
  return 'CursoResumen(id: $id, tipo: $tipo, areaId: $areaId, titulo: $titulo, descripcion: $descripcion, lema: $lema, profe: $profe, portadaUrl: $portadaUrl, orden: $orden, publicado: $publicado, clases: $clases, disponibles: $disponibles, gratis: $gratis, duracionS: $duracionS, completadas: $completadas)';
}


}

/// @nodoc
abstract mixin class _$CursoResumenCopyWith<$Res> implements $CursoResumenCopyWith<$Res> {
  factory _$CursoResumenCopyWith(_CursoResumen value, $Res Function(_CursoResumen) _then) = __$CursoResumenCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: TipoDeCurso.desconocido) TipoDeCurso tipo, String? areaId, String titulo, String descripcion, String lema, Profe? profe, String? portadaUrl, int orden, bool publicado, int clases, int disponibles, int gratis, int duracionS, int completadas
});


@override $ProfeCopyWith<$Res>? get profe;

}
/// @nodoc
class __$CursoResumenCopyWithImpl<$Res>
    implements _$CursoResumenCopyWith<$Res> {
  __$CursoResumenCopyWithImpl(this._self, this._then);

  final _CursoResumen _self;
  final $Res Function(_CursoResumen) _then;

/// Create a copy of CursoResumen
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tipo = null,Object? areaId = freezed,Object? titulo = null,Object? descripcion = null,Object? lema = null,Object? profe = freezed,Object? portadaUrl = freezed,Object? orden = null,Object? publicado = null,Object? clases = null,Object? disponibles = null,Object? gratis = null,Object? duracionS = null,Object? completadas = null,}) {
  return _then(_CursoResumen(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeCurso,areaId: freezed == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String?,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,lema: null == lema ? _self.lema : lema // ignore: cast_nullable_to_non_nullable
as String,profe: freezed == profe ? _self.profe : profe // ignore: cast_nullable_to_non_nullable
as Profe?,portadaUrl: freezed == portadaUrl ? _self.portadaUrl : portadaUrl // ignore: cast_nullable_to_non_nullable
as String?,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,publicado: null == publicado ? _self.publicado : publicado // ignore: cast_nullable_to_non_nullable
as bool,clases: null == clases ? _self.clases : clases // ignore: cast_nullable_to_non_nullable
as int,disponibles: null == disponibles ? _self.disponibles : disponibles // ignore: cast_nullable_to_non_nullable
as int,gratis: null == gratis ? _self.gratis : gratis // ignore: cast_nullable_to_non_nullable
as int,duracionS: null == duracionS ? _self.duracionS : duracionS // ignore: cast_nullable_to_non_nullable
as int,completadas: null == completadas ? _self.completadas : completadas // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CursoResumen
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfeCopyWith<$Res>? get profe {
    if (_self.profe == null) {
    return null;
  }

  return $ProfeCopyWith<$Res>(_self.profe!, (value) {
    return _then(_self.copyWith(profe: value));
  });
}
}


/// @nodoc
mixin _$ProgresoDeClase {

 int get segundosVistos; int get posicionS; bool get completada;
/// Create a copy of ProgresoDeClase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgresoDeClaseCopyWith<ProgresoDeClase> get copyWith => _$ProgresoDeClaseCopyWithImpl<ProgresoDeClase>(this as ProgresoDeClase, _$identity);

  /// Serializes this ProgresoDeClase to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgresoDeClase&&(identical(other.segundosVistos, segundosVistos) || other.segundosVistos == segundosVistos)&&(identical(other.posicionS, posicionS) || other.posicionS == posicionS)&&(identical(other.completada, completada) || other.completada == completada));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,segundosVistos,posicionS,completada);

@override
String toString() {
  return 'ProgresoDeClase(segundosVistos: $segundosVistos, posicionS: $posicionS, completada: $completada)';
}


}

/// @nodoc
abstract mixin class $ProgresoDeClaseCopyWith<$Res>  {
  factory $ProgresoDeClaseCopyWith(ProgresoDeClase value, $Res Function(ProgresoDeClase) _then) = _$ProgresoDeClaseCopyWithImpl;
@useResult
$Res call({
 int segundosVistos, int posicionS, bool completada
});




}
/// @nodoc
class _$ProgresoDeClaseCopyWithImpl<$Res>
    implements $ProgresoDeClaseCopyWith<$Res> {
  _$ProgresoDeClaseCopyWithImpl(this._self, this._then);

  final ProgresoDeClase _self;
  final $Res Function(ProgresoDeClase) _then;

/// Create a copy of ProgresoDeClase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? segundosVistos = null,Object? posicionS = null,Object? completada = null,}) {
  return _then(_self.copyWith(
segundosVistos: null == segundosVistos ? _self.segundosVistos : segundosVistos // ignore: cast_nullable_to_non_nullable
as int,posicionS: null == posicionS ? _self.posicionS : posicionS // ignore: cast_nullable_to_non_nullable
as int,completada: null == completada ? _self.completada : completada // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgresoDeClase].
extension ProgresoDeClasePatterns on ProgresoDeClase {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgresoDeClase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgresoDeClase() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgresoDeClase value)  $default,){
final _that = this;
switch (_that) {
case _ProgresoDeClase():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgresoDeClase value)?  $default,){
final _that = this;
switch (_that) {
case _ProgresoDeClase() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int segundosVistos,  int posicionS,  bool completada)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgresoDeClase() when $default != null:
return $default(_that.segundosVistos,_that.posicionS,_that.completada);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int segundosVistos,  int posicionS,  bool completada)  $default,) {final _that = this;
switch (_that) {
case _ProgresoDeClase():
return $default(_that.segundosVistos,_that.posicionS,_that.completada);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int segundosVistos,  int posicionS,  bool completada)?  $default,) {final _that = this;
switch (_that) {
case _ProgresoDeClase() when $default != null:
return $default(_that.segundosVistos,_that.posicionS,_that.completada);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgresoDeClase implements ProgresoDeClase {
  const _ProgresoDeClase({this.segundosVistos = 0, this.posicionS = 0, this.completada = false});
  factory _ProgresoDeClase.fromJson(Map<String, dynamic> json) => _$ProgresoDeClaseFromJson(json);

@override@JsonKey() final  int segundosVistos;
@override@JsonKey() final  int posicionS;
@override@JsonKey() final  bool completada;

/// Create a copy of ProgresoDeClase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgresoDeClaseCopyWith<_ProgresoDeClase> get copyWith => __$ProgresoDeClaseCopyWithImpl<_ProgresoDeClase>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgresoDeClaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgresoDeClase&&(identical(other.segundosVistos, segundosVistos) || other.segundosVistos == segundosVistos)&&(identical(other.posicionS, posicionS) || other.posicionS == posicionS)&&(identical(other.completada, completada) || other.completada == completada));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,segundosVistos,posicionS,completada);

@override
String toString() {
  return 'ProgresoDeClase(segundosVistos: $segundosVistos, posicionS: $posicionS, completada: $completada)';
}


}

/// @nodoc
abstract mixin class _$ProgresoDeClaseCopyWith<$Res> implements $ProgresoDeClaseCopyWith<$Res> {
  factory _$ProgresoDeClaseCopyWith(_ProgresoDeClase value, $Res Function(_ProgresoDeClase) _then) = __$ProgresoDeClaseCopyWithImpl;
@override @useResult
$Res call({
 int segundosVistos, int posicionS, bool completada
});




}
/// @nodoc
class __$ProgresoDeClaseCopyWithImpl<$Res>
    implements _$ProgresoDeClaseCopyWith<$Res> {
  __$ProgresoDeClaseCopyWithImpl(this._self, this._then);

  final _ProgresoDeClase _self;
  final $Res Function(_ProgresoDeClase) _then;

/// Create a copy of ProgresoDeClase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? segundosVistos = null,Object? posicionS = null,Object? completada = null,}) {
  return _then(_ProgresoDeClase(
segundosVistos: null == segundosVistos ? _self.segundosVistos : segundosVistos // ignore: cast_nullable_to_non_nullable
as int,posicionS: null == posicionS ? _self.posicionS : posicionS // ignore: cast_nullable_to_non_nullable
as int,completada: null == completada ? _self.completada : completada // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$ClaseResumen {

 String get id; String get codigo; int get orden; String get titulo; int get duracionS;@JsonKey(unknownEnumValue: EstadoDeClase.desconocido) EstadoDeClase get estado;/// De la muestra gratis del curso.
 bool get gratis;/// Sin Premium y no es gratis: se ve en el temario, no se abre.
 bool get bloqueada; String? get miniaturaUrl; ProgresoDeClase get progreso;
/// Create a copy of ClaseResumen
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClaseResumenCopyWith<ClaseResumen> get copyWith => _$ClaseResumenCopyWithImpl<ClaseResumen>(this as ClaseResumen, _$identity);

  /// Serializes this ClaseResumen to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ClaseResumen&&(identical(other.id, id) || other.id == id)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.duracionS, duracionS) || other.duracionS == duracionS)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.gratis, gratis) || other.gratis == gratis)&&(identical(other.bloqueada, bloqueada) || other.bloqueada == bloqueada)&&(identical(other.miniaturaUrl, miniaturaUrl) || other.miniaturaUrl == miniaturaUrl)&&(identical(other.progreso, progreso) || other.progreso == progreso));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,codigo,orden,titulo,duracionS,estado,gratis,bloqueada,miniaturaUrl,progreso);

@override
String toString() {
  return 'ClaseResumen(id: $id, codigo: $codigo, orden: $orden, titulo: $titulo, duracionS: $duracionS, estado: $estado, gratis: $gratis, bloqueada: $bloqueada, miniaturaUrl: $miniaturaUrl, progreso: $progreso)';
}


}

/// @nodoc
abstract mixin class $ClaseResumenCopyWith<$Res>  {
  factory $ClaseResumenCopyWith(ClaseResumen value, $Res Function(ClaseResumen) _then) = _$ClaseResumenCopyWithImpl;
@useResult
$Res call({
 String id, String codigo, int orden, String titulo, int duracionS,@JsonKey(unknownEnumValue: EstadoDeClase.desconocido) EstadoDeClase estado, bool gratis, bool bloqueada, String? miniaturaUrl, ProgresoDeClase progreso
});


$ProgresoDeClaseCopyWith<$Res> get progreso;

}
/// @nodoc
class _$ClaseResumenCopyWithImpl<$Res>
    implements $ClaseResumenCopyWith<$Res> {
  _$ClaseResumenCopyWithImpl(this._self, this._then);

  final ClaseResumen _self;
  final $Res Function(ClaseResumen) _then;

/// Create a copy of ClaseResumen
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? codigo = null,Object? orden = null,Object? titulo = null,Object? duracionS = null,Object? estado = null,Object? gratis = null,Object? bloqueada = null,Object? miniaturaUrl = freezed,Object? progreso = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,codigo: null == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,duracionS: null == duracionS ? _self.duracionS : duracionS // ignore: cast_nullable_to_non_nullable
as int,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDeClase,gratis: null == gratis ? _self.gratis : gratis // ignore: cast_nullable_to_non_nullable
as bool,bloqueada: null == bloqueada ? _self.bloqueada : bloqueada // ignore: cast_nullable_to_non_nullable
as bool,miniaturaUrl: freezed == miniaturaUrl ? _self.miniaturaUrl : miniaturaUrl // ignore: cast_nullable_to_non_nullable
as String?,progreso: null == progreso ? _self.progreso : progreso // ignore: cast_nullable_to_non_nullable
as ProgresoDeClase,
  ));
}
/// Create a copy of ClaseResumen
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgresoDeClaseCopyWith<$Res> get progreso {
  
  return $ProgresoDeClaseCopyWith<$Res>(_self.progreso, (value) {
    return _then(_self.copyWith(progreso: value));
  });
}
}


/// Adds pattern-matching-related methods to [ClaseResumen].
extension ClaseResumenPatterns on ClaseResumen {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ClaseResumen value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ClaseResumen() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ClaseResumen value)  $default,){
final _that = this;
switch (_that) {
case _ClaseResumen():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ClaseResumen value)?  $default,){
final _that = this;
switch (_that) {
case _ClaseResumen() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String codigo,  int orden,  String titulo,  int duracionS, @JsonKey(unknownEnumValue: EstadoDeClase.desconocido)  EstadoDeClase estado,  bool gratis,  bool bloqueada,  String? miniaturaUrl,  ProgresoDeClase progreso)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ClaseResumen() when $default != null:
return $default(_that.id,_that.codigo,_that.orden,_that.titulo,_that.duracionS,_that.estado,_that.gratis,_that.bloqueada,_that.miniaturaUrl,_that.progreso);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String codigo,  int orden,  String titulo,  int duracionS, @JsonKey(unknownEnumValue: EstadoDeClase.desconocido)  EstadoDeClase estado,  bool gratis,  bool bloqueada,  String? miniaturaUrl,  ProgresoDeClase progreso)  $default,) {final _that = this;
switch (_that) {
case _ClaseResumen():
return $default(_that.id,_that.codigo,_that.orden,_that.titulo,_that.duracionS,_that.estado,_that.gratis,_that.bloqueada,_that.miniaturaUrl,_that.progreso);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String codigo,  int orden,  String titulo,  int duracionS, @JsonKey(unknownEnumValue: EstadoDeClase.desconocido)  EstadoDeClase estado,  bool gratis,  bool bloqueada,  String? miniaturaUrl,  ProgresoDeClase progreso)?  $default,) {final _that = this;
switch (_that) {
case _ClaseResumen() when $default != null:
return $default(_that.id,_that.codigo,_that.orden,_that.titulo,_that.duracionS,_that.estado,_that.gratis,_that.bloqueada,_that.miniaturaUrl,_that.progreso);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ClaseResumen extends ClaseResumen {
  const _ClaseResumen({required this.id, this.codigo = '', this.orden = 0, required this.titulo, this.duracionS = 0, @JsonKey(unknownEnumValue: EstadoDeClase.desconocido) this.estado = EstadoDeClase.proximamente, this.gratis = false, this.bloqueada = false, this.miniaturaUrl, this.progreso = const ProgresoDeClase()}): super._();
  factory _ClaseResumen.fromJson(Map<String, dynamic> json) => _$ClaseResumenFromJson(json);

@override final  String id;
@override@JsonKey() final  String codigo;
@override@JsonKey() final  int orden;
@override final  String titulo;
@override@JsonKey() final  int duracionS;
@override@JsonKey(unknownEnumValue: EstadoDeClase.desconocido) final  EstadoDeClase estado;
/// De la muestra gratis del curso.
@override@JsonKey() final  bool gratis;
/// Sin Premium y no es gratis: se ve en el temario, no se abre.
@override@JsonKey() final  bool bloqueada;
@override final  String? miniaturaUrl;
@override@JsonKey() final  ProgresoDeClase progreso;

/// Create a copy of ClaseResumen
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClaseResumenCopyWith<_ClaseResumen> get copyWith => __$ClaseResumenCopyWithImpl<_ClaseResumen>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClaseResumenToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ClaseResumen&&(identical(other.id, id) || other.id == id)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.duracionS, duracionS) || other.duracionS == duracionS)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.gratis, gratis) || other.gratis == gratis)&&(identical(other.bloqueada, bloqueada) || other.bloqueada == bloqueada)&&(identical(other.miniaturaUrl, miniaturaUrl) || other.miniaturaUrl == miniaturaUrl)&&(identical(other.progreso, progreso) || other.progreso == progreso));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,codigo,orden,titulo,duracionS,estado,gratis,bloqueada,miniaturaUrl,progreso);

@override
String toString() {
  return 'ClaseResumen(id: $id, codigo: $codigo, orden: $orden, titulo: $titulo, duracionS: $duracionS, estado: $estado, gratis: $gratis, bloqueada: $bloqueada, miniaturaUrl: $miniaturaUrl, progreso: $progreso)';
}


}

/// @nodoc
abstract mixin class _$ClaseResumenCopyWith<$Res> implements $ClaseResumenCopyWith<$Res> {
  factory _$ClaseResumenCopyWith(_ClaseResumen value, $Res Function(_ClaseResumen) _then) = __$ClaseResumenCopyWithImpl;
@override @useResult
$Res call({
 String id, String codigo, int orden, String titulo, int duracionS,@JsonKey(unknownEnumValue: EstadoDeClase.desconocido) EstadoDeClase estado, bool gratis, bool bloqueada, String? miniaturaUrl, ProgresoDeClase progreso
});


@override $ProgresoDeClaseCopyWith<$Res> get progreso;

}
/// @nodoc
class __$ClaseResumenCopyWithImpl<$Res>
    implements _$ClaseResumenCopyWith<$Res> {
  __$ClaseResumenCopyWithImpl(this._self, this._then);

  final _ClaseResumen _self;
  final $Res Function(_ClaseResumen) _then;

/// Create a copy of ClaseResumen
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? codigo = null,Object? orden = null,Object? titulo = null,Object? duracionS = null,Object? estado = null,Object? gratis = null,Object? bloqueada = null,Object? miniaturaUrl = freezed,Object? progreso = null,}) {
  return _then(_ClaseResumen(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,codigo: null == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,duracionS: null == duracionS ? _self.duracionS : duracionS // ignore: cast_nullable_to_non_nullable
as int,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDeClase,gratis: null == gratis ? _self.gratis : gratis // ignore: cast_nullable_to_non_nullable
as bool,bloqueada: null == bloqueada ? _self.bloqueada : bloqueada // ignore: cast_nullable_to_non_nullable
as bool,miniaturaUrl: freezed == miniaturaUrl ? _self.miniaturaUrl : miniaturaUrl // ignore: cast_nullable_to_non_nullable
as String?,progreso: null == progreso ? _self.progreso : progreso // ignore: cast_nullable_to_non_nullable
as ProgresoDeClase,
  ));
}

/// Create a copy of ClaseResumen
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgresoDeClaseCopyWith<$Res> get progreso {
  
  return $ProgresoDeClaseCopyWith<$Res>(_self.progreso, (value) {
    return _then(_self.copyWith(progreso: value));
  });
}
}


/// @nodoc
mixin _$Modulo {

 String get id; String get codigo; int get orden; String get titulo; String get descripcion; String get nodoId; List<ClaseResumen> get clases;
/// Create a copy of Modulo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ModuloCopyWith<Modulo> get copyWith => _$ModuloCopyWithImpl<Modulo>(this as Modulo, _$identity);

  /// Serializes this Modulo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Modulo&&(identical(other.id, id) || other.id == id)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.nodoId, nodoId) || other.nodoId == nodoId)&&const DeepCollectionEquality().equals(other.clases, clases));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,codigo,orden,titulo,descripcion,nodoId,const DeepCollectionEquality().hash(clases));

@override
String toString() {
  return 'Modulo(id: $id, codigo: $codigo, orden: $orden, titulo: $titulo, descripcion: $descripcion, nodoId: $nodoId, clases: $clases)';
}


}

/// @nodoc
abstract mixin class $ModuloCopyWith<$Res>  {
  factory $ModuloCopyWith(Modulo value, $Res Function(Modulo) _then) = _$ModuloCopyWithImpl;
@useResult
$Res call({
 String id, String codigo, int orden, String titulo, String descripcion, String nodoId, List<ClaseResumen> clases
});




}
/// @nodoc
class _$ModuloCopyWithImpl<$Res>
    implements $ModuloCopyWith<$Res> {
  _$ModuloCopyWithImpl(this._self, this._then);

  final Modulo _self;
  final $Res Function(Modulo) _then;

/// Create a copy of Modulo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? codigo = null,Object? orden = null,Object? titulo = null,Object? descripcion = null,Object? nodoId = null,Object? clases = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,codigo: null == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,nodoId: null == nodoId ? _self.nodoId : nodoId // ignore: cast_nullable_to_non_nullable
as String,clases: null == clases ? _self.clases : clases // ignore: cast_nullable_to_non_nullable
as List<ClaseResumen>,
  ));
}

}


/// Adds pattern-matching-related methods to [Modulo].
extension ModuloPatterns on Modulo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Modulo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Modulo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Modulo value)  $default,){
final _that = this;
switch (_that) {
case _Modulo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Modulo value)?  $default,){
final _that = this;
switch (_that) {
case _Modulo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String codigo,  int orden,  String titulo,  String descripcion,  String nodoId,  List<ClaseResumen> clases)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Modulo() when $default != null:
return $default(_that.id,_that.codigo,_that.orden,_that.titulo,_that.descripcion,_that.nodoId,_that.clases);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String codigo,  int orden,  String titulo,  String descripcion,  String nodoId,  List<ClaseResumen> clases)  $default,) {final _that = this;
switch (_that) {
case _Modulo():
return $default(_that.id,_that.codigo,_that.orden,_that.titulo,_that.descripcion,_that.nodoId,_that.clases);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String codigo,  int orden,  String titulo,  String descripcion,  String nodoId,  List<ClaseResumen> clases)?  $default,) {final _that = this;
switch (_that) {
case _Modulo() when $default != null:
return $default(_that.id,_that.codigo,_that.orden,_that.titulo,_that.descripcion,_that.nodoId,_that.clases);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Modulo extends Modulo {
  const _Modulo({required this.id, this.codigo = '', this.orden = 0, required this.titulo, this.descripcion = '', this.nodoId = '', final  List<ClaseResumen> clases = const []}): _clases = clases,super._();
  factory _Modulo.fromJson(Map<String, dynamic> json) => _$ModuloFromJson(json);

@override final  String id;
@override@JsonKey() final  String codigo;
@override@JsonKey() final  int orden;
@override final  String titulo;
@override@JsonKey() final  String descripcion;
@override@JsonKey() final  String nodoId;
 final  List<ClaseResumen> _clases;
@override@JsonKey() List<ClaseResumen> get clases {
  if (_clases is EqualUnmodifiableListView) return _clases;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_clases);
}


/// Create a copy of Modulo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ModuloCopyWith<_Modulo> get copyWith => __$ModuloCopyWithImpl<_Modulo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ModuloToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Modulo&&(identical(other.id, id) || other.id == id)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.nodoId, nodoId) || other.nodoId == nodoId)&&const DeepCollectionEquality().equals(other._clases, _clases));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,codigo,orden,titulo,descripcion,nodoId,const DeepCollectionEquality().hash(_clases));

@override
String toString() {
  return 'Modulo(id: $id, codigo: $codigo, orden: $orden, titulo: $titulo, descripcion: $descripcion, nodoId: $nodoId, clases: $clases)';
}


}

/// @nodoc
abstract mixin class _$ModuloCopyWith<$Res> implements $ModuloCopyWith<$Res> {
  factory _$ModuloCopyWith(_Modulo value, $Res Function(_Modulo) _then) = __$ModuloCopyWithImpl;
@override @useResult
$Res call({
 String id, String codigo, int orden, String titulo, String descripcion, String nodoId, List<ClaseResumen> clases
});




}
/// @nodoc
class __$ModuloCopyWithImpl<$Res>
    implements _$ModuloCopyWith<$Res> {
  __$ModuloCopyWithImpl(this._self, this._then);

  final _Modulo _self;
  final $Res Function(_Modulo) _then;

/// Create a copy of Modulo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? codigo = null,Object? orden = null,Object? titulo = null,Object? descripcion = null,Object? nodoId = null,Object? clases = null,}) {
  return _then(_Modulo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,codigo: null == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,nodoId: null == nodoId ? _self.nodoId : nodoId // ignore: cast_nullable_to_non_nullable
as String,clases: null == clases ? _self._clases : clases // ignore: cast_nullable_to_non_nullable
as List<ClaseResumen>,
  ));
}


}


/// @nodoc
mixin _$Curso {

 String get id;@JsonKey(unknownEnumValue: TipoDeCurso.desconocido) TipoDeCurso get tipo; String? get areaId; String get titulo; String get descripcion; String get lema; Profe? get profe; String? get portadaUrl; int get clases; int get disponibles; int get gratis; int get duracionS; int get completadas;/// La cuenta ve todo el curso.
 bool get premium; List<Modulo> get modulos;/// La próxima clase sin completar que la cuenta puede abrir. La decide el
/// servidor, como en la web.
 ClaseResumen? get continuar;
/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CursoCopyWith<Curso> get copyWith => _$CursoCopyWithImpl<Curso>(this as Curso, _$identity);

  /// Serializes this Curso to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Curso&&(identical(other.id, id) || other.id == id)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.lema, lema) || other.lema == lema)&&(identical(other.profe, profe) || other.profe == profe)&&(identical(other.portadaUrl, portadaUrl) || other.portadaUrl == portadaUrl)&&(identical(other.clases, clases) || other.clases == clases)&&(identical(other.disponibles, disponibles) || other.disponibles == disponibles)&&(identical(other.gratis, gratis) || other.gratis == gratis)&&(identical(other.duracionS, duracionS) || other.duracionS == duracionS)&&(identical(other.completadas, completadas) || other.completadas == completadas)&&(identical(other.premium, premium) || other.premium == premium)&&const DeepCollectionEquality().equals(other.modulos, modulos)&&(identical(other.continuar, continuar) || other.continuar == continuar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tipo,areaId,titulo,descripcion,lema,profe,portadaUrl,clases,disponibles,gratis,duracionS,completadas,premium,const DeepCollectionEquality().hash(modulos),continuar);

@override
String toString() {
  return 'Curso(id: $id, tipo: $tipo, areaId: $areaId, titulo: $titulo, descripcion: $descripcion, lema: $lema, profe: $profe, portadaUrl: $portadaUrl, clases: $clases, disponibles: $disponibles, gratis: $gratis, duracionS: $duracionS, completadas: $completadas, premium: $premium, modulos: $modulos, continuar: $continuar)';
}


}

/// @nodoc
abstract mixin class $CursoCopyWith<$Res>  {
  factory $CursoCopyWith(Curso value, $Res Function(Curso) _then) = _$CursoCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: TipoDeCurso.desconocido) TipoDeCurso tipo, String? areaId, String titulo, String descripcion, String lema, Profe? profe, String? portadaUrl, int clases, int disponibles, int gratis, int duracionS, int completadas, bool premium, List<Modulo> modulos, ClaseResumen? continuar
});


$ProfeCopyWith<$Res>? get profe;$ClaseResumenCopyWith<$Res>? get continuar;

}
/// @nodoc
class _$CursoCopyWithImpl<$Res>
    implements $CursoCopyWith<$Res> {
  _$CursoCopyWithImpl(this._self, this._then);

  final Curso _self;
  final $Res Function(Curso) _then;

/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tipo = null,Object? areaId = freezed,Object? titulo = null,Object? descripcion = null,Object? lema = null,Object? profe = freezed,Object? portadaUrl = freezed,Object? clases = null,Object? disponibles = null,Object? gratis = null,Object? duracionS = null,Object? completadas = null,Object? premium = null,Object? modulos = null,Object? continuar = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeCurso,areaId: freezed == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String?,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,lema: null == lema ? _self.lema : lema // ignore: cast_nullable_to_non_nullable
as String,profe: freezed == profe ? _self.profe : profe // ignore: cast_nullable_to_non_nullable
as Profe?,portadaUrl: freezed == portadaUrl ? _self.portadaUrl : portadaUrl // ignore: cast_nullable_to_non_nullable
as String?,clases: null == clases ? _self.clases : clases // ignore: cast_nullable_to_non_nullable
as int,disponibles: null == disponibles ? _self.disponibles : disponibles // ignore: cast_nullable_to_non_nullable
as int,gratis: null == gratis ? _self.gratis : gratis // ignore: cast_nullable_to_non_nullable
as int,duracionS: null == duracionS ? _self.duracionS : duracionS // ignore: cast_nullable_to_non_nullable
as int,completadas: null == completadas ? _self.completadas : completadas // ignore: cast_nullable_to_non_nullable
as int,premium: null == premium ? _self.premium : premium // ignore: cast_nullable_to_non_nullable
as bool,modulos: null == modulos ? _self.modulos : modulos // ignore: cast_nullable_to_non_nullable
as List<Modulo>,continuar: freezed == continuar ? _self.continuar : continuar // ignore: cast_nullable_to_non_nullable
as ClaseResumen?,
  ));
}
/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfeCopyWith<$Res>? get profe {
    if (_self.profe == null) {
    return null;
  }

  return $ProfeCopyWith<$Res>(_self.profe!, (value) {
    return _then(_self.copyWith(profe: value));
  });
}/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClaseResumenCopyWith<$Res>? get continuar {
    if (_self.continuar == null) {
    return null;
  }

  return $ClaseResumenCopyWith<$Res>(_self.continuar!, (value) {
    return _then(_self.copyWith(continuar: value));
  });
}
}


/// Adds pattern-matching-related methods to [Curso].
extension CursoPatterns on Curso {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Curso value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Curso() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Curso value)  $default,){
final _that = this;
switch (_that) {
case _Curso():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Curso value)?  $default,){
final _that = this;
switch (_that) {
case _Curso() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: TipoDeCurso.desconocido)  TipoDeCurso tipo,  String? areaId,  String titulo,  String descripcion,  String lema,  Profe? profe,  String? portadaUrl,  int clases,  int disponibles,  int gratis,  int duracionS,  int completadas,  bool premium,  List<Modulo> modulos,  ClaseResumen? continuar)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Curso() when $default != null:
return $default(_that.id,_that.tipo,_that.areaId,_that.titulo,_that.descripcion,_that.lema,_that.profe,_that.portadaUrl,_that.clases,_that.disponibles,_that.gratis,_that.duracionS,_that.completadas,_that.premium,_that.modulos,_that.continuar);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: TipoDeCurso.desconocido)  TipoDeCurso tipo,  String? areaId,  String titulo,  String descripcion,  String lema,  Profe? profe,  String? portadaUrl,  int clases,  int disponibles,  int gratis,  int duracionS,  int completadas,  bool premium,  List<Modulo> modulos,  ClaseResumen? continuar)  $default,) {final _that = this;
switch (_that) {
case _Curso():
return $default(_that.id,_that.tipo,_that.areaId,_that.titulo,_that.descripcion,_that.lema,_that.profe,_that.portadaUrl,_that.clases,_that.disponibles,_that.gratis,_that.duracionS,_that.completadas,_that.premium,_that.modulos,_that.continuar);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: TipoDeCurso.desconocido)  TipoDeCurso tipo,  String? areaId,  String titulo,  String descripcion,  String lema,  Profe? profe,  String? portadaUrl,  int clases,  int disponibles,  int gratis,  int duracionS,  int completadas,  bool premium,  List<Modulo> modulos,  ClaseResumen? continuar)?  $default,) {final _that = this;
switch (_that) {
case _Curso() when $default != null:
return $default(_that.id,_that.tipo,_that.areaId,_that.titulo,_that.descripcion,_that.lema,_that.profe,_that.portadaUrl,_that.clases,_that.disponibles,_that.gratis,_that.duracionS,_that.completadas,_that.premium,_that.modulos,_that.continuar);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Curso extends Curso {
  const _Curso({required this.id, @JsonKey(unknownEnumValue: TipoDeCurso.desconocido) this.tipo = TipoDeCurso.area, this.areaId, required this.titulo, this.descripcion = '', this.lema = '', this.profe, this.portadaUrl, this.clases = 0, this.disponibles = 0, this.gratis = 0, this.duracionS = 0, this.completadas = 0, this.premium = false, final  List<Modulo> modulos = const [], this.continuar}): _modulos = modulos,super._();
  factory _Curso.fromJson(Map<String, dynamic> json) => _$CursoFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: TipoDeCurso.desconocido) final  TipoDeCurso tipo;
@override final  String? areaId;
@override final  String titulo;
@override@JsonKey() final  String descripcion;
@override@JsonKey() final  String lema;
@override final  Profe? profe;
@override final  String? portadaUrl;
@override@JsonKey() final  int clases;
@override@JsonKey() final  int disponibles;
@override@JsonKey() final  int gratis;
@override@JsonKey() final  int duracionS;
@override@JsonKey() final  int completadas;
/// La cuenta ve todo el curso.
@override@JsonKey() final  bool premium;
 final  List<Modulo> _modulos;
@override@JsonKey() List<Modulo> get modulos {
  if (_modulos is EqualUnmodifiableListView) return _modulos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_modulos);
}

/// La próxima clase sin completar que la cuenta puede abrir. La decide el
/// servidor, como en la web.
@override final  ClaseResumen? continuar;

/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CursoCopyWith<_Curso> get copyWith => __$CursoCopyWithImpl<_Curso>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CursoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Curso&&(identical(other.id, id) || other.id == id)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.lema, lema) || other.lema == lema)&&(identical(other.profe, profe) || other.profe == profe)&&(identical(other.portadaUrl, portadaUrl) || other.portadaUrl == portadaUrl)&&(identical(other.clases, clases) || other.clases == clases)&&(identical(other.disponibles, disponibles) || other.disponibles == disponibles)&&(identical(other.gratis, gratis) || other.gratis == gratis)&&(identical(other.duracionS, duracionS) || other.duracionS == duracionS)&&(identical(other.completadas, completadas) || other.completadas == completadas)&&(identical(other.premium, premium) || other.premium == premium)&&const DeepCollectionEquality().equals(other._modulos, _modulos)&&(identical(other.continuar, continuar) || other.continuar == continuar));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tipo,areaId,titulo,descripcion,lema,profe,portadaUrl,clases,disponibles,gratis,duracionS,completadas,premium,const DeepCollectionEquality().hash(_modulos),continuar);

@override
String toString() {
  return 'Curso(id: $id, tipo: $tipo, areaId: $areaId, titulo: $titulo, descripcion: $descripcion, lema: $lema, profe: $profe, portadaUrl: $portadaUrl, clases: $clases, disponibles: $disponibles, gratis: $gratis, duracionS: $duracionS, completadas: $completadas, premium: $premium, modulos: $modulos, continuar: $continuar)';
}


}

/// @nodoc
abstract mixin class _$CursoCopyWith<$Res> implements $CursoCopyWith<$Res> {
  factory _$CursoCopyWith(_Curso value, $Res Function(_Curso) _then) = __$CursoCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: TipoDeCurso.desconocido) TipoDeCurso tipo, String? areaId, String titulo, String descripcion, String lema, Profe? profe, String? portadaUrl, int clases, int disponibles, int gratis, int duracionS, int completadas, bool premium, List<Modulo> modulos, ClaseResumen? continuar
});


@override $ProfeCopyWith<$Res>? get profe;@override $ClaseResumenCopyWith<$Res>? get continuar;

}
/// @nodoc
class __$CursoCopyWithImpl<$Res>
    implements _$CursoCopyWith<$Res> {
  __$CursoCopyWithImpl(this._self, this._then);

  final _Curso _self;
  final $Res Function(_Curso) _then;

/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tipo = null,Object? areaId = freezed,Object? titulo = null,Object? descripcion = null,Object? lema = null,Object? profe = freezed,Object? portadaUrl = freezed,Object? clases = null,Object? disponibles = null,Object? gratis = null,Object? duracionS = null,Object? completadas = null,Object? premium = null,Object? modulos = null,Object? continuar = freezed,}) {
  return _then(_Curso(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeCurso,areaId: freezed == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String?,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,lema: null == lema ? _self.lema : lema // ignore: cast_nullable_to_non_nullable
as String,profe: freezed == profe ? _self.profe : profe // ignore: cast_nullable_to_non_nullable
as Profe?,portadaUrl: freezed == portadaUrl ? _self.portadaUrl : portadaUrl // ignore: cast_nullable_to_non_nullable
as String?,clases: null == clases ? _self.clases : clases // ignore: cast_nullable_to_non_nullable
as int,disponibles: null == disponibles ? _self.disponibles : disponibles // ignore: cast_nullable_to_non_nullable
as int,gratis: null == gratis ? _self.gratis : gratis // ignore: cast_nullable_to_non_nullable
as int,duracionS: null == duracionS ? _self.duracionS : duracionS // ignore: cast_nullable_to_non_nullable
as int,completadas: null == completadas ? _self.completadas : completadas // ignore: cast_nullable_to_non_nullable
as int,premium: null == premium ? _self.premium : premium // ignore: cast_nullable_to_non_nullable
as bool,modulos: null == modulos ? _self._modulos : modulos // ignore: cast_nullable_to_non_nullable
as List<Modulo>,continuar: freezed == continuar ? _self.continuar : continuar // ignore: cast_nullable_to_non_nullable
as ClaseResumen?,
  ));
}

/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfeCopyWith<$Res>? get profe {
    if (_self.profe == null) {
    return null;
  }

  return $ProfeCopyWith<$Res>(_self.profe!, (value) {
    return _then(_self.copyWith(profe: value));
  });
}/// Create a copy of Curso
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClaseResumenCopyWith<$Res>? get continuar {
    if (_self.continuar == null) {
    return null;
  }

  return $ClaseResumenCopyWith<$Res>(_self.continuar!, (value) {
    return _then(_self.copyWith(continuar: value));
  });
}
}


/// @nodoc
mixin _$Referencia {

 String get id;@JsonKey(unknownEnumValue: TipoDeReferencia.desconocido) TipoDeReferencia get tipo; String get cita; int? get anio; String? get edicion; String? get capitulo; String? get paginas; String? get url; String? get doi;
/// Create a copy of Referencia
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReferenciaCopyWith<Referencia> get copyWith => _$ReferenciaCopyWithImpl<Referencia>(this as Referencia, _$identity);

  /// Serializes this Referencia to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Referencia&&(identical(other.id, id) || other.id == id)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.cita, cita) || other.cita == cita)&&(identical(other.anio, anio) || other.anio == anio)&&(identical(other.edicion, edicion) || other.edicion == edicion)&&(identical(other.capitulo, capitulo) || other.capitulo == capitulo)&&(identical(other.paginas, paginas) || other.paginas == paginas)&&(identical(other.url, url) || other.url == url)&&(identical(other.doi, doi) || other.doi == doi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tipo,cita,anio,edicion,capitulo,paginas,url,doi);

@override
String toString() {
  return 'Referencia(id: $id, tipo: $tipo, cita: $cita, anio: $anio, edicion: $edicion, capitulo: $capitulo, paginas: $paginas, url: $url, doi: $doi)';
}


}

/// @nodoc
abstract mixin class $ReferenciaCopyWith<$Res>  {
  factory $ReferenciaCopyWith(Referencia value, $Res Function(Referencia) _then) = _$ReferenciaCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: TipoDeReferencia.desconocido) TipoDeReferencia tipo, String cita, int? anio, String? edicion, String? capitulo, String? paginas, String? url, String? doi
});




}
/// @nodoc
class _$ReferenciaCopyWithImpl<$Res>
    implements $ReferenciaCopyWith<$Res> {
  _$ReferenciaCopyWithImpl(this._self, this._then);

  final Referencia _self;
  final $Res Function(Referencia) _then;

/// Create a copy of Referencia
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tipo = null,Object? cita = null,Object? anio = freezed,Object? edicion = freezed,Object? capitulo = freezed,Object? paginas = freezed,Object? url = freezed,Object? doi = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeReferencia,cita: null == cita ? _self.cita : cita // ignore: cast_nullable_to_non_nullable
as String,anio: freezed == anio ? _self.anio : anio // ignore: cast_nullable_to_non_nullable
as int?,edicion: freezed == edicion ? _self.edicion : edicion // ignore: cast_nullable_to_non_nullable
as String?,capitulo: freezed == capitulo ? _self.capitulo : capitulo // ignore: cast_nullable_to_non_nullable
as String?,paginas: freezed == paginas ? _self.paginas : paginas // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,doi: freezed == doi ? _self.doi : doi // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Referencia].
extension ReferenciaPatterns on Referencia {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Referencia value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Referencia() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Referencia value)  $default,){
final _that = this;
switch (_that) {
case _Referencia():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Referencia value)?  $default,){
final _that = this;
switch (_that) {
case _Referencia() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: TipoDeReferencia.desconocido)  TipoDeReferencia tipo,  String cita,  int? anio,  String? edicion,  String? capitulo,  String? paginas,  String? url,  String? doi)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Referencia() when $default != null:
return $default(_that.id,_that.tipo,_that.cita,_that.anio,_that.edicion,_that.capitulo,_that.paginas,_that.url,_that.doi);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: TipoDeReferencia.desconocido)  TipoDeReferencia tipo,  String cita,  int? anio,  String? edicion,  String? capitulo,  String? paginas,  String? url,  String? doi)  $default,) {final _that = this;
switch (_that) {
case _Referencia():
return $default(_that.id,_that.tipo,_that.cita,_that.anio,_that.edicion,_that.capitulo,_that.paginas,_that.url,_that.doi);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: TipoDeReferencia.desconocido)  TipoDeReferencia tipo,  String cita,  int? anio,  String? edicion,  String? capitulo,  String? paginas,  String? url,  String? doi)?  $default,) {final _that = this;
switch (_that) {
case _Referencia() when $default != null:
return $default(_that.id,_that.tipo,_that.cita,_that.anio,_that.edicion,_that.capitulo,_that.paginas,_that.url,_that.doi);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Referencia extends Referencia {
  const _Referencia({required this.id, @JsonKey(unknownEnumValue: TipoDeReferencia.desconocido) this.tipo = TipoDeReferencia.desconocido, required this.cita, this.anio, this.edicion, this.capitulo, this.paginas, this.url, this.doi}): super._();
  factory _Referencia.fromJson(Map<String, dynamic> json) => _$ReferenciaFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: TipoDeReferencia.desconocido) final  TipoDeReferencia tipo;
@override final  String cita;
@override final  int? anio;
@override final  String? edicion;
@override final  String? capitulo;
@override final  String? paginas;
@override final  String? url;
@override final  String? doi;

/// Create a copy of Referencia
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReferenciaCopyWith<_Referencia> get copyWith => __$ReferenciaCopyWithImpl<_Referencia>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReferenciaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Referencia&&(identical(other.id, id) || other.id == id)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.cita, cita) || other.cita == cita)&&(identical(other.anio, anio) || other.anio == anio)&&(identical(other.edicion, edicion) || other.edicion == edicion)&&(identical(other.capitulo, capitulo) || other.capitulo == capitulo)&&(identical(other.paginas, paginas) || other.paginas == paginas)&&(identical(other.url, url) || other.url == url)&&(identical(other.doi, doi) || other.doi == doi));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tipo,cita,anio,edicion,capitulo,paginas,url,doi);

@override
String toString() {
  return 'Referencia(id: $id, tipo: $tipo, cita: $cita, anio: $anio, edicion: $edicion, capitulo: $capitulo, paginas: $paginas, url: $url, doi: $doi)';
}


}

/// @nodoc
abstract mixin class _$ReferenciaCopyWith<$Res> implements $ReferenciaCopyWith<$Res> {
  factory _$ReferenciaCopyWith(_Referencia value, $Res Function(_Referencia) _then) = __$ReferenciaCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: TipoDeReferencia.desconocido) TipoDeReferencia tipo, String cita, int? anio, String? edicion, String? capitulo, String? paginas, String? url, String? doi
});




}
/// @nodoc
class __$ReferenciaCopyWithImpl<$Res>
    implements _$ReferenciaCopyWith<$Res> {
  __$ReferenciaCopyWithImpl(this._self, this._then);

  final _Referencia _self;
  final $Res Function(_Referencia) _then;

/// Create a copy of Referencia
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tipo = null,Object? cita = null,Object? anio = freezed,Object? edicion = freezed,Object? capitulo = freezed,Object? paginas = freezed,Object? url = freezed,Object? doi = freezed,}) {
  return _then(_Referencia(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoDeReferencia,cita: null == cita ? _self.cita : cita // ignore: cast_nullable_to_non_nullable
as String,anio: freezed == anio ? _self.anio : anio // ignore: cast_nullable_to_non_nullable
as int?,edicion: freezed == edicion ? _self.edicion : edicion // ignore: cast_nullable_to_non_nullable
as String?,capitulo: freezed == capitulo ? _self.capitulo : capitulo // ignore: cast_nullable_to_non_nullable
as String?,paginas: freezed == paginas ? _self.paginas : paginas // ignore: cast_nullable_to_non_nullable
as String?,url: freezed == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String?,doi: freezed == doi ? _self.doi : doi // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Vecina {

 String get id; String get titulo; bool get bloqueada;
/// Create a copy of Vecina
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VecinaCopyWith<Vecina> get copyWith => _$VecinaCopyWithImpl<Vecina>(this as Vecina, _$identity);

  /// Serializes this Vecina to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Vecina&&(identical(other.id, id) || other.id == id)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.bloqueada, bloqueada) || other.bloqueada == bloqueada));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titulo,bloqueada);

@override
String toString() {
  return 'Vecina(id: $id, titulo: $titulo, bloqueada: $bloqueada)';
}


}

/// @nodoc
abstract mixin class $VecinaCopyWith<$Res>  {
  factory $VecinaCopyWith(Vecina value, $Res Function(Vecina) _then) = _$VecinaCopyWithImpl;
@useResult
$Res call({
 String id, String titulo, bool bloqueada
});




}
/// @nodoc
class _$VecinaCopyWithImpl<$Res>
    implements $VecinaCopyWith<$Res> {
  _$VecinaCopyWithImpl(this._self, this._then);

  final Vecina _self;
  final $Res Function(Vecina) _then;

/// Create a copy of Vecina
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? titulo = null,Object? bloqueada = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,bloqueada: null == bloqueada ? _self.bloqueada : bloqueada // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Vecina].
extension VecinaPatterns on Vecina {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Vecina value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Vecina() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Vecina value)  $default,){
final _that = this;
switch (_that) {
case _Vecina():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Vecina value)?  $default,){
final _that = this;
switch (_that) {
case _Vecina() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String titulo,  bool bloqueada)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Vecina() when $default != null:
return $default(_that.id,_that.titulo,_that.bloqueada);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String titulo,  bool bloqueada)  $default,) {final _that = this;
switch (_that) {
case _Vecina():
return $default(_that.id,_that.titulo,_that.bloqueada);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String titulo,  bool bloqueada)?  $default,) {final _that = this;
switch (_that) {
case _Vecina() when $default != null:
return $default(_that.id,_that.titulo,_that.bloqueada);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Vecina implements Vecina {
  const _Vecina({required this.id, required this.titulo, this.bloqueada = false});
  factory _Vecina.fromJson(Map<String, dynamic> json) => _$VecinaFromJson(json);

@override final  String id;
@override final  String titulo;
@override@JsonKey() final  bool bloqueada;

/// Create a copy of Vecina
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$VecinaCopyWith<_Vecina> get copyWith => __$VecinaCopyWithImpl<_Vecina>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VecinaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Vecina&&(identical(other.id, id) || other.id == id)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.bloqueada, bloqueada) || other.bloqueada == bloqueada));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,titulo,bloqueada);

@override
String toString() {
  return 'Vecina(id: $id, titulo: $titulo, bloqueada: $bloqueada)';
}


}

/// @nodoc
abstract mixin class _$VecinaCopyWith<$Res> implements $VecinaCopyWith<$Res> {
  factory _$VecinaCopyWith(_Vecina value, $Res Function(_Vecina) _then) = __$VecinaCopyWithImpl;
@override @useResult
$Res call({
 String id, String titulo, bool bloqueada
});




}
/// @nodoc
class __$VecinaCopyWithImpl<$Res>
    implements _$VecinaCopyWith<$Res> {
  __$VecinaCopyWithImpl(this._self, this._then);

  final _Vecina _self;
  final $Res Function(_Vecina) _then;

/// Create a copy of Vecina
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? titulo = null,Object? bloqueada = null,}) {
  return _then(_Vecina(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,bloqueada: null == bloqueada ? _self.bloqueada : bloqueada // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$Clase {

 String get id; String get codigo; String get titulo; int get duracionS;@JsonKey(unknownEnumValue: EstadoDeClase.desconocido) EstadoDeClase get estado; bool get gratis; bool get bloqueada; String? get miniaturaUrl; ProgresoDeClase get progreso; String get cursoId; String get cursoTitulo; Profe? get profe; String get moduloId; List<String> get objetivos; List<String> get temas; List<Referencia> get referencias;/// Firmadas: caducan a las 4 h. Solo si la clase está disponible.
 String? get videoUrl; String? get subtitulosUrl;/// El nodo de la clase tiene preguntas publicadas.
 bool get practicaDisponible; Vecina? get anterior; Vecina? get siguiente;
/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ClaseCopyWith<Clase> get copyWith => _$ClaseCopyWithImpl<Clase>(this as Clase, _$identity);

  /// Serializes this Clase to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Clase&&(identical(other.id, id) || other.id == id)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.duracionS, duracionS) || other.duracionS == duracionS)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.gratis, gratis) || other.gratis == gratis)&&(identical(other.bloqueada, bloqueada) || other.bloqueada == bloqueada)&&(identical(other.miniaturaUrl, miniaturaUrl) || other.miniaturaUrl == miniaturaUrl)&&(identical(other.progreso, progreso) || other.progreso == progreso)&&(identical(other.cursoId, cursoId) || other.cursoId == cursoId)&&(identical(other.cursoTitulo, cursoTitulo) || other.cursoTitulo == cursoTitulo)&&(identical(other.profe, profe) || other.profe == profe)&&(identical(other.moduloId, moduloId) || other.moduloId == moduloId)&&const DeepCollectionEquality().equals(other.objetivos, objetivos)&&const DeepCollectionEquality().equals(other.temas, temas)&&const DeepCollectionEquality().equals(other.referencias, referencias)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.subtitulosUrl, subtitulosUrl) || other.subtitulosUrl == subtitulosUrl)&&(identical(other.practicaDisponible, practicaDisponible) || other.practicaDisponible == practicaDisponible)&&(identical(other.anterior, anterior) || other.anterior == anterior)&&(identical(other.siguiente, siguiente) || other.siguiente == siguiente));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,codigo,titulo,duracionS,estado,gratis,bloqueada,miniaturaUrl,progreso,cursoId,cursoTitulo,profe,moduloId,const DeepCollectionEquality().hash(objetivos),const DeepCollectionEquality().hash(temas),const DeepCollectionEquality().hash(referencias),videoUrl,subtitulosUrl,practicaDisponible,anterior,siguiente]);

@override
String toString() {
  return 'Clase(id: $id, codigo: $codigo, titulo: $titulo, duracionS: $duracionS, estado: $estado, gratis: $gratis, bloqueada: $bloqueada, miniaturaUrl: $miniaturaUrl, progreso: $progreso, cursoId: $cursoId, cursoTitulo: $cursoTitulo, profe: $profe, moduloId: $moduloId, objetivos: $objetivos, temas: $temas, referencias: $referencias, videoUrl: $videoUrl, subtitulosUrl: $subtitulosUrl, practicaDisponible: $practicaDisponible, anterior: $anterior, siguiente: $siguiente)';
}


}

/// @nodoc
abstract mixin class $ClaseCopyWith<$Res>  {
  factory $ClaseCopyWith(Clase value, $Res Function(Clase) _then) = _$ClaseCopyWithImpl;
@useResult
$Res call({
 String id, String codigo, String titulo, int duracionS,@JsonKey(unknownEnumValue: EstadoDeClase.desconocido) EstadoDeClase estado, bool gratis, bool bloqueada, String? miniaturaUrl, ProgresoDeClase progreso, String cursoId, String cursoTitulo, Profe? profe, String moduloId, List<String> objetivos, List<String> temas, List<Referencia> referencias, String? videoUrl, String? subtitulosUrl, bool practicaDisponible, Vecina? anterior, Vecina? siguiente
});


$ProgresoDeClaseCopyWith<$Res> get progreso;$ProfeCopyWith<$Res>? get profe;$VecinaCopyWith<$Res>? get anterior;$VecinaCopyWith<$Res>? get siguiente;

}
/// @nodoc
class _$ClaseCopyWithImpl<$Res>
    implements $ClaseCopyWith<$Res> {
  _$ClaseCopyWithImpl(this._self, this._then);

  final Clase _self;
  final $Res Function(Clase) _then;

/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? codigo = null,Object? titulo = null,Object? duracionS = null,Object? estado = null,Object? gratis = null,Object? bloqueada = null,Object? miniaturaUrl = freezed,Object? progreso = null,Object? cursoId = null,Object? cursoTitulo = null,Object? profe = freezed,Object? moduloId = null,Object? objetivos = null,Object? temas = null,Object? referencias = null,Object? videoUrl = freezed,Object? subtitulosUrl = freezed,Object? practicaDisponible = null,Object? anterior = freezed,Object? siguiente = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,codigo: null == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,duracionS: null == duracionS ? _self.duracionS : duracionS // ignore: cast_nullable_to_non_nullable
as int,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDeClase,gratis: null == gratis ? _self.gratis : gratis // ignore: cast_nullable_to_non_nullable
as bool,bloqueada: null == bloqueada ? _self.bloqueada : bloqueada // ignore: cast_nullable_to_non_nullable
as bool,miniaturaUrl: freezed == miniaturaUrl ? _self.miniaturaUrl : miniaturaUrl // ignore: cast_nullable_to_non_nullable
as String?,progreso: null == progreso ? _self.progreso : progreso // ignore: cast_nullable_to_non_nullable
as ProgresoDeClase,cursoId: null == cursoId ? _self.cursoId : cursoId // ignore: cast_nullable_to_non_nullable
as String,cursoTitulo: null == cursoTitulo ? _self.cursoTitulo : cursoTitulo // ignore: cast_nullable_to_non_nullable
as String,profe: freezed == profe ? _self.profe : profe // ignore: cast_nullable_to_non_nullable
as Profe?,moduloId: null == moduloId ? _self.moduloId : moduloId // ignore: cast_nullable_to_non_nullable
as String,objetivos: null == objetivos ? _self.objetivos : objetivos // ignore: cast_nullable_to_non_nullable
as List<String>,temas: null == temas ? _self.temas : temas // ignore: cast_nullable_to_non_nullable
as List<String>,referencias: null == referencias ? _self.referencias : referencias // ignore: cast_nullable_to_non_nullable
as List<Referencia>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,subtitulosUrl: freezed == subtitulosUrl ? _self.subtitulosUrl : subtitulosUrl // ignore: cast_nullable_to_non_nullable
as String?,practicaDisponible: null == practicaDisponible ? _self.practicaDisponible : practicaDisponible // ignore: cast_nullable_to_non_nullable
as bool,anterior: freezed == anterior ? _self.anterior : anterior // ignore: cast_nullable_to_non_nullable
as Vecina?,siguiente: freezed == siguiente ? _self.siguiente : siguiente // ignore: cast_nullable_to_non_nullable
as Vecina?,
  ));
}
/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgresoDeClaseCopyWith<$Res> get progreso {
  
  return $ProgresoDeClaseCopyWith<$Res>(_self.progreso, (value) {
    return _then(_self.copyWith(progreso: value));
  });
}/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfeCopyWith<$Res>? get profe {
    if (_self.profe == null) {
    return null;
  }

  return $ProfeCopyWith<$Res>(_self.profe!, (value) {
    return _then(_self.copyWith(profe: value));
  });
}/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VecinaCopyWith<$Res>? get anterior {
    if (_self.anterior == null) {
    return null;
  }

  return $VecinaCopyWith<$Res>(_self.anterior!, (value) {
    return _then(_self.copyWith(anterior: value));
  });
}/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VecinaCopyWith<$Res>? get siguiente {
    if (_self.siguiente == null) {
    return null;
  }

  return $VecinaCopyWith<$Res>(_self.siguiente!, (value) {
    return _then(_self.copyWith(siguiente: value));
  });
}
}


/// Adds pattern-matching-related methods to [Clase].
extension ClasePatterns on Clase {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Clase value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Clase() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Clase value)  $default,){
final _that = this;
switch (_that) {
case _Clase():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Clase value)?  $default,){
final _that = this;
switch (_that) {
case _Clase() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String codigo,  String titulo,  int duracionS, @JsonKey(unknownEnumValue: EstadoDeClase.desconocido)  EstadoDeClase estado,  bool gratis,  bool bloqueada,  String? miniaturaUrl,  ProgresoDeClase progreso,  String cursoId,  String cursoTitulo,  Profe? profe,  String moduloId,  List<String> objetivos,  List<String> temas,  List<Referencia> referencias,  String? videoUrl,  String? subtitulosUrl,  bool practicaDisponible,  Vecina? anterior,  Vecina? siguiente)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Clase() when $default != null:
return $default(_that.id,_that.codigo,_that.titulo,_that.duracionS,_that.estado,_that.gratis,_that.bloqueada,_that.miniaturaUrl,_that.progreso,_that.cursoId,_that.cursoTitulo,_that.profe,_that.moduloId,_that.objetivos,_that.temas,_that.referencias,_that.videoUrl,_that.subtitulosUrl,_that.practicaDisponible,_that.anterior,_that.siguiente);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String codigo,  String titulo,  int duracionS, @JsonKey(unknownEnumValue: EstadoDeClase.desconocido)  EstadoDeClase estado,  bool gratis,  bool bloqueada,  String? miniaturaUrl,  ProgresoDeClase progreso,  String cursoId,  String cursoTitulo,  Profe? profe,  String moduloId,  List<String> objetivos,  List<String> temas,  List<Referencia> referencias,  String? videoUrl,  String? subtitulosUrl,  bool practicaDisponible,  Vecina? anterior,  Vecina? siguiente)  $default,) {final _that = this;
switch (_that) {
case _Clase():
return $default(_that.id,_that.codigo,_that.titulo,_that.duracionS,_that.estado,_that.gratis,_that.bloqueada,_that.miniaturaUrl,_that.progreso,_that.cursoId,_that.cursoTitulo,_that.profe,_that.moduloId,_that.objetivos,_that.temas,_that.referencias,_that.videoUrl,_that.subtitulosUrl,_that.practicaDisponible,_that.anterior,_that.siguiente);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String codigo,  String titulo,  int duracionS, @JsonKey(unknownEnumValue: EstadoDeClase.desconocido)  EstadoDeClase estado,  bool gratis,  bool bloqueada,  String? miniaturaUrl,  ProgresoDeClase progreso,  String cursoId,  String cursoTitulo,  Profe? profe,  String moduloId,  List<String> objetivos,  List<String> temas,  List<Referencia> referencias,  String? videoUrl,  String? subtitulosUrl,  bool practicaDisponible,  Vecina? anterior,  Vecina? siguiente)?  $default,) {final _that = this;
switch (_that) {
case _Clase() when $default != null:
return $default(_that.id,_that.codigo,_that.titulo,_that.duracionS,_that.estado,_that.gratis,_that.bloqueada,_that.miniaturaUrl,_that.progreso,_that.cursoId,_that.cursoTitulo,_that.profe,_that.moduloId,_that.objetivos,_that.temas,_that.referencias,_that.videoUrl,_that.subtitulosUrl,_that.practicaDisponible,_that.anterior,_that.siguiente);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Clase extends Clase {
  const _Clase({required this.id, this.codigo = '', required this.titulo, this.duracionS = 0, @JsonKey(unknownEnumValue: EstadoDeClase.desconocido) this.estado = EstadoDeClase.proximamente, this.gratis = false, this.bloqueada = false, this.miniaturaUrl, this.progreso = const ProgresoDeClase(), required this.cursoId, this.cursoTitulo = '', this.profe, this.moduloId = '', final  List<String> objetivos = const [], final  List<String> temas = const [], final  List<Referencia> referencias = const [], this.videoUrl, this.subtitulosUrl, this.practicaDisponible = false, this.anterior, this.siguiente}): _objetivos = objetivos,_temas = temas,_referencias = referencias,super._();
  factory _Clase.fromJson(Map<String, dynamic> json) => _$ClaseFromJson(json);

@override final  String id;
@override@JsonKey() final  String codigo;
@override final  String titulo;
@override@JsonKey() final  int duracionS;
@override@JsonKey(unknownEnumValue: EstadoDeClase.desconocido) final  EstadoDeClase estado;
@override@JsonKey() final  bool gratis;
@override@JsonKey() final  bool bloqueada;
@override final  String? miniaturaUrl;
@override@JsonKey() final  ProgresoDeClase progreso;
@override final  String cursoId;
@override@JsonKey() final  String cursoTitulo;
@override final  Profe? profe;
@override@JsonKey() final  String moduloId;
 final  List<String> _objetivos;
@override@JsonKey() List<String> get objetivos {
  if (_objetivos is EqualUnmodifiableListView) return _objetivos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_objetivos);
}

 final  List<String> _temas;
@override@JsonKey() List<String> get temas {
  if (_temas is EqualUnmodifiableListView) return _temas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_temas);
}

 final  List<Referencia> _referencias;
@override@JsonKey() List<Referencia> get referencias {
  if (_referencias is EqualUnmodifiableListView) return _referencias;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_referencias);
}

/// Firmadas: caducan a las 4 h. Solo si la clase está disponible.
@override final  String? videoUrl;
@override final  String? subtitulosUrl;
/// El nodo de la clase tiene preguntas publicadas.
@override@JsonKey() final  bool practicaDisponible;
@override final  Vecina? anterior;
@override final  Vecina? siguiente;

/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ClaseCopyWith<_Clase> get copyWith => __$ClaseCopyWithImpl<_Clase>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ClaseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Clase&&(identical(other.id, id) || other.id == id)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.titulo, titulo) || other.titulo == titulo)&&(identical(other.duracionS, duracionS) || other.duracionS == duracionS)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.gratis, gratis) || other.gratis == gratis)&&(identical(other.bloqueada, bloqueada) || other.bloqueada == bloqueada)&&(identical(other.miniaturaUrl, miniaturaUrl) || other.miniaturaUrl == miniaturaUrl)&&(identical(other.progreso, progreso) || other.progreso == progreso)&&(identical(other.cursoId, cursoId) || other.cursoId == cursoId)&&(identical(other.cursoTitulo, cursoTitulo) || other.cursoTitulo == cursoTitulo)&&(identical(other.profe, profe) || other.profe == profe)&&(identical(other.moduloId, moduloId) || other.moduloId == moduloId)&&const DeepCollectionEquality().equals(other._objetivos, _objetivos)&&const DeepCollectionEquality().equals(other._temas, _temas)&&const DeepCollectionEquality().equals(other._referencias, _referencias)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.subtitulosUrl, subtitulosUrl) || other.subtitulosUrl == subtitulosUrl)&&(identical(other.practicaDisponible, practicaDisponible) || other.practicaDisponible == practicaDisponible)&&(identical(other.anterior, anterior) || other.anterior == anterior)&&(identical(other.siguiente, siguiente) || other.siguiente == siguiente));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,codigo,titulo,duracionS,estado,gratis,bloqueada,miniaturaUrl,progreso,cursoId,cursoTitulo,profe,moduloId,const DeepCollectionEquality().hash(_objetivos),const DeepCollectionEquality().hash(_temas),const DeepCollectionEquality().hash(_referencias),videoUrl,subtitulosUrl,practicaDisponible,anterior,siguiente]);

@override
String toString() {
  return 'Clase(id: $id, codigo: $codigo, titulo: $titulo, duracionS: $duracionS, estado: $estado, gratis: $gratis, bloqueada: $bloqueada, miniaturaUrl: $miniaturaUrl, progreso: $progreso, cursoId: $cursoId, cursoTitulo: $cursoTitulo, profe: $profe, moduloId: $moduloId, objetivos: $objetivos, temas: $temas, referencias: $referencias, videoUrl: $videoUrl, subtitulosUrl: $subtitulosUrl, practicaDisponible: $practicaDisponible, anterior: $anterior, siguiente: $siguiente)';
}


}

/// @nodoc
abstract mixin class _$ClaseCopyWith<$Res> implements $ClaseCopyWith<$Res> {
  factory _$ClaseCopyWith(_Clase value, $Res Function(_Clase) _then) = __$ClaseCopyWithImpl;
@override @useResult
$Res call({
 String id, String codigo, String titulo, int duracionS,@JsonKey(unknownEnumValue: EstadoDeClase.desconocido) EstadoDeClase estado, bool gratis, bool bloqueada, String? miniaturaUrl, ProgresoDeClase progreso, String cursoId, String cursoTitulo, Profe? profe, String moduloId, List<String> objetivos, List<String> temas, List<Referencia> referencias, String? videoUrl, String? subtitulosUrl, bool practicaDisponible, Vecina? anterior, Vecina? siguiente
});


@override $ProgresoDeClaseCopyWith<$Res> get progreso;@override $ProfeCopyWith<$Res>? get profe;@override $VecinaCopyWith<$Res>? get anterior;@override $VecinaCopyWith<$Res>? get siguiente;

}
/// @nodoc
class __$ClaseCopyWithImpl<$Res>
    implements _$ClaseCopyWith<$Res> {
  __$ClaseCopyWithImpl(this._self, this._then);

  final _Clase _self;
  final $Res Function(_Clase) _then;

/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? codigo = null,Object? titulo = null,Object? duracionS = null,Object? estado = null,Object? gratis = null,Object? bloqueada = null,Object? miniaturaUrl = freezed,Object? progreso = null,Object? cursoId = null,Object? cursoTitulo = null,Object? profe = freezed,Object? moduloId = null,Object? objetivos = null,Object? temas = null,Object? referencias = null,Object? videoUrl = freezed,Object? subtitulosUrl = freezed,Object? practicaDisponible = null,Object? anterior = freezed,Object? siguiente = freezed,}) {
  return _then(_Clase(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,codigo: null == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String,titulo: null == titulo ? _self.titulo : titulo // ignore: cast_nullable_to_non_nullable
as String,duracionS: null == duracionS ? _self.duracionS : duracionS // ignore: cast_nullable_to_non_nullable
as int,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDeClase,gratis: null == gratis ? _self.gratis : gratis // ignore: cast_nullable_to_non_nullable
as bool,bloqueada: null == bloqueada ? _self.bloqueada : bloqueada // ignore: cast_nullable_to_non_nullable
as bool,miniaturaUrl: freezed == miniaturaUrl ? _self.miniaturaUrl : miniaturaUrl // ignore: cast_nullable_to_non_nullable
as String?,progreso: null == progreso ? _self.progreso : progreso // ignore: cast_nullable_to_non_nullable
as ProgresoDeClase,cursoId: null == cursoId ? _self.cursoId : cursoId // ignore: cast_nullable_to_non_nullable
as String,cursoTitulo: null == cursoTitulo ? _self.cursoTitulo : cursoTitulo // ignore: cast_nullable_to_non_nullable
as String,profe: freezed == profe ? _self.profe : profe // ignore: cast_nullable_to_non_nullable
as Profe?,moduloId: null == moduloId ? _self.moduloId : moduloId // ignore: cast_nullable_to_non_nullable
as String,objetivos: null == objetivos ? _self._objetivos : objetivos // ignore: cast_nullable_to_non_nullable
as List<String>,temas: null == temas ? _self._temas : temas // ignore: cast_nullable_to_non_nullable
as List<String>,referencias: null == referencias ? _self._referencias : referencias // ignore: cast_nullable_to_non_nullable
as List<Referencia>,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,subtitulosUrl: freezed == subtitulosUrl ? _self.subtitulosUrl : subtitulosUrl // ignore: cast_nullable_to_non_nullable
as String?,practicaDisponible: null == practicaDisponible ? _self.practicaDisponible : practicaDisponible // ignore: cast_nullable_to_non_nullable
as bool,anterior: freezed == anterior ? _self.anterior : anterior // ignore: cast_nullable_to_non_nullable
as Vecina?,siguiente: freezed == siguiente ? _self.siguiente : siguiente // ignore: cast_nullable_to_non_nullable
as Vecina?,
  ));
}

/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProgresoDeClaseCopyWith<$Res> get progreso {
  
  return $ProgresoDeClaseCopyWith<$Res>(_self.progreso, (value) {
    return _then(_self.copyWith(progreso: value));
  });
}/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ProfeCopyWith<$Res>? get profe {
    if (_self.profe == null) {
    return null;
  }

  return $ProfeCopyWith<$Res>(_self.profe!, (value) {
    return _then(_self.copyWith(profe: value));
  });
}/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VecinaCopyWith<$Res>? get anterior {
    if (_self.anterior == null) {
    return null;
  }

  return $VecinaCopyWith<$Res>(_self.anterior!, (value) {
    return _then(_self.copyWith(anterior: value));
  });
}/// Create a copy of Clase
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$VecinaCopyWith<$Res>? get siguiente {
    if (_self.siguiente == null) {
    return null;
  }

  return $VecinaCopyWith<$Res>(_self.siguiente!, (value) {
    return _then(_self.copyWith(siguiente: value));
  });
}
}


/// @nodoc
mixin _$SeguirViendo {

 String get cursoId; String get cursoTitulo; ClaseResumen get clase;
/// Create a copy of SeguirViendo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeguirViendoCopyWith<SeguirViendo> get copyWith => _$SeguirViendoCopyWithImpl<SeguirViendo>(this as SeguirViendo, _$identity);

  /// Serializes this SeguirViendo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeguirViendo&&(identical(other.cursoId, cursoId) || other.cursoId == cursoId)&&(identical(other.cursoTitulo, cursoTitulo) || other.cursoTitulo == cursoTitulo)&&(identical(other.clase, clase) || other.clase == clase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cursoId,cursoTitulo,clase);

@override
String toString() {
  return 'SeguirViendo(cursoId: $cursoId, cursoTitulo: $cursoTitulo, clase: $clase)';
}


}

/// @nodoc
abstract mixin class $SeguirViendoCopyWith<$Res>  {
  factory $SeguirViendoCopyWith(SeguirViendo value, $Res Function(SeguirViendo) _then) = _$SeguirViendoCopyWithImpl;
@useResult
$Res call({
 String cursoId, String cursoTitulo, ClaseResumen clase
});


$ClaseResumenCopyWith<$Res> get clase;

}
/// @nodoc
class _$SeguirViendoCopyWithImpl<$Res>
    implements $SeguirViendoCopyWith<$Res> {
  _$SeguirViendoCopyWithImpl(this._self, this._then);

  final SeguirViendo _self;
  final $Res Function(SeguirViendo) _then;

/// Create a copy of SeguirViendo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cursoId = null,Object? cursoTitulo = null,Object? clase = null,}) {
  return _then(_self.copyWith(
cursoId: null == cursoId ? _self.cursoId : cursoId // ignore: cast_nullable_to_non_nullable
as String,cursoTitulo: null == cursoTitulo ? _self.cursoTitulo : cursoTitulo // ignore: cast_nullable_to_non_nullable
as String,clase: null == clase ? _self.clase : clase // ignore: cast_nullable_to_non_nullable
as ClaseResumen,
  ));
}
/// Create a copy of SeguirViendo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClaseResumenCopyWith<$Res> get clase {
  
  return $ClaseResumenCopyWith<$Res>(_self.clase, (value) {
    return _then(_self.copyWith(clase: value));
  });
}
}


/// Adds pattern-matching-related methods to [SeguirViendo].
extension SeguirViendoPatterns on SeguirViendo {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeguirViendo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeguirViendo() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeguirViendo value)  $default,){
final _that = this;
switch (_that) {
case _SeguirViendo():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeguirViendo value)?  $default,){
final _that = this;
switch (_that) {
case _SeguirViendo() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String cursoId,  String cursoTitulo,  ClaseResumen clase)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeguirViendo() when $default != null:
return $default(_that.cursoId,_that.cursoTitulo,_that.clase);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String cursoId,  String cursoTitulo,  ClaseResumen clase)  $default,) {final _that = this;
switch (_that) {
case _SeguirViendo():
return $default(_that.cursoId,_that.cursoTitulo,_that.clase);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String cursoId,  String cursoTitulo,  ClaseResumen clase)?  $default,) {final _that = this;
switch (_that) {
case _SeguirViendo() when $default != null:
return $default(_that.cursoId,_that.cursoTitulo,_that.clase);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeguirViendo implements SeguirViendo {
  const _SeguirViendo({required this.cursoId, this.cursoTitulo = '', required this.clase});
  factory _SeguirViendo.fromJson(Map<String, dynamic> json) => _$SeguirViendoFromJson(json);

@override final  String cursoId;
@override@JsonKey() final  String cursoTitulo;
@override final  ClaseResumen clase;

/// Create a copy of SeguirViendo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeguirViendoCopyWith<_SeguirViendo> get copyWith => __$SeguirViendoCopyWithImpl<_SeguirViendo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeguirViendoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeguirViendo&&(identical(other.cursoId, cursoId) || other.cursoId == cursoId)&&(identical(other.cursoTitulo, cursoTitulo) || other.cursoTitulo == cursoTitulo)&&(identical(other.clase, clase) || other.clase == clase));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,cursoId,cursoTitulo,clase);

@override
String toString() {
  return 'SeguirViendo(cursoId: $cursoId, cursoTitulo: $cursoTitulo, clase: $clase)';
}


}

/// @nodoc
abstract mixin class _$SeguirViendoCopyWith<$Res> implements $SeguirViendoCopyWith<$Res> {
  factory _$SeguirViendoCopyWith(_SeguirViendo value, $Res Function(_SeguirViendo) _then) = __$SeguirViendoCopyWithImpl;
@override @useResult
$Res call({
 String cursoId, String cursoTitulo, ClaseResumen clase
});


@override $ClaseResumenCopyWith<$Res> get clase;

}
/// @nodoc
class __$SeguirViendoCopyWithImpl<$Res>
    implements _$SeguirViendoCopyWith<$Res> {
  __$SeguirViendoCopyWithImpl(this._self, this._then);

  final _SeguirViendo _self;
  final $Res Function(_SeguirViendo) _then;

/// Create a copy of SeguirViendo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cursoId = null,Object? cursoTitulo = null,Object? clase = null,}) {
  return _then(_SeguirViendo(
cursoId: null == cursoId ? _self.cursoId : cursoId // ignore: cast_nullable_to_non_nullable
as String,cursoTitulo: null == cursoTitulo ? _self.cursoTitulo : cursoTitulo // ignore: cast_nullable_to_non_nullable
as String,clase: null == clase ? _self.clase : clase // ignore: cast_nullable_to_non_nullable
as ClaseResumen,
  ));
}

/// Create a copy of SeguirViendo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ClaseResumenCopyWith<$Res> get clase {
  
  return $ClaseResumenCopyWith<$Res>(_self.clase, (value) {
    return _then(_self.copyWith(clase: value));
  });
}
}

// dart format on
