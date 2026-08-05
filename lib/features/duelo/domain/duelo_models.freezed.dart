// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'duelo_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DueloDTO {

 String get id;@JsonKey(unknownEnumValue: EstadoDuelo.desconocido) EstadoDuelo get estado;@JsonKey(unknownEnumValue: OrigenDuelo.desconocido) OrigenDuelo get origen;/// Solo en los de enlace: el PIN de 6 dígitos.
 String? get codigo;/// La URL lista para compartir, ya armada por el servidor.
///
/// La compone el backend para que web y app no tengan cada una su forma de
/// hacerlo: dos formas es una que se queda vieja.
 String? get enlace; bool get contraBot; bool get completo; int get totalPreguntas;/// Cómo se llama el otro, si ya hay otro.
 String? get rival;/// Este duelo lo creó quien pregunta.
///
/// Explícito y no deducido de que `rival` venga vacío: quien abre su propio
/// enlace tiene que ver «este es tu reto, compártelo» y no «te retan».
 bool get esTuyo; DateTime? get expiraEn;/// De qué duelo es la revancha, si lo es (RF-61).
 String? get revanchaDe;/// Cuánto falta para poder pedir el bot. 0 si ya se puede.
 int get faltanParaBotSegundos;
/// Create a copy of DueloDTO
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DueloDTOCopyWith<DueloDTO> get copyWith => _$DueloDTOCopyWithImpl<DueloDTO>(this as DueloDTO, _$identity);

  /// Serializes this DueloDTO to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DueloDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.origen, origen) || other.origen == origen)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.enlace, enlace) || other.enlace == enlace)&&(identical(other.contraBot, contraBot) || other.contraBot == contraBot)&&(identical(other.completo, completo) || other.completo == completo)&&(identical(other.totalPreguntas, totalPreguntas) || other.totalPreguntas == totalPreguntas)&&(identical(other.rival, rival) || other.rival == rival)&&(identical(other.esTuyo, esTuyo) || other.esTuyo == esTuyo)&&(identical(other.expiraEn, expiraEn) || other.expiraEn == expiraEn)&&(identical(other.revanchaDe, revanchaDe) || other.revanchaDe == revanchaDe)&&(identical(other.faltanParaBotSegundos, faltanParaBotSegundos) || other.faltanParaBotSegundos == faltanParaBotSegundos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,estado,origen,codigo,enlace,contraBot,completo,totalPreguntas,rival,esTuyo,expiraEn,revanchaDe,faltanParaBotSegundos);

@override
String toString() {
  return 'DueloDTO(id: $id, estado: $estado, origen: $origen, codigo: $codigo, enlace: $enlace, contraBot: $contraBot, completo: $completo, totalPreguntas: $totalPreguntas, rival: $rival, esTuyo: $esTuyo, expiraEn: $expiraEn, revanchaDe: $revanchaDe, faltanParaBotSegundos: $faltanParaBotSegundos)';
}


}

/// @nodoc
abstract mixin class $DueloDTOCopyWith<$Res>  {
  factory $DueloDTOCopyWith(DueloDTO value, $Res Function(DueloDTO) _then) = _$DueloDTOCopyWithImpl;
@useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: EstadoDuelo.desconocido) EstadoDuelo estado,@JsonKey(unknownEnumValue: OrigenDuelo.desconocido) OrigenDuelo origen, String? codigo, String? enlace, bool contraBot, bool completo, int totalPreguntas, String? rival, bool esTuyo, DateTime? expiraEn, String? revanchaDe, int faltanParaBotSegundos
});




}
/// @nodoc
class _$DueloDTOCopyWithImpl<$Res>
    implements $DueloDTOCopyWith<$Res> {
  _$DueloDTOCopyWithImpl(this._self, this._then);

  final DueloDTO _self;
  final $Res Function(DueloDTO) _then;

/// Create a copy of DueloDTO
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? estado = null,Object? origen = null,Object? codigo = freezed,Object? enlace = freezed,Object? contraBot = null,Object? completo = null,Object? totalPreguntas = null,Object? rival = freezed,Object? esTuyo = null,Object? expiraEn = freezed,Object? revanchaDe = freezed,Object? faltanParaBotSegundos = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDuelo,origen: null == origen ? _self.origen : origen // ignore: cast_nullable_to_non_nullable
as OrigenDuelo,codigo: freezed == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String?,enlace: freezed == enlace ? _self.enlace : enlace // ignore: cast_nullable_to_non_nullable
as String?,contraBot: null == contraBot ? _self.contraBot : contraBot // ignore: cast_nullable_to_non_nullable
as bool,completo: null == completo ? _self.completo : completo // ignore: cast_nullable_to_non_nullable
as bool,totalPreguntas: null == totalPreguntas ? _self.totalPreguntas : totalPreguntas // ignore: cast_nullable_to_non_nullable
as int,rival: freezed == rival ? _self.rival : rival // ignore: cast_nullable_to_non_nullable
as String?,esTuyo: null == esTuyo ? _self.esTuyo : esTuyo // ignore: cast_nullable_to_non_nullable
as bool,expiraEn: freezed == expiraEn ? _self.expiraEn : expiraEn // ignore: cast_nullable_to_non_nullable
as DateTime?,revanchaDe: freezed == revanchaDe ? _self.revanchaDe : revanchaDe // ignore: cast_nullable_to_non_nullable
as String?,faltanParaBotSegundos: null == faltanParaBotSegundos ? _self.faltanParaBotSegundos : faltanParaBotSegundos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [DueloDTO].
extension DueloDTOPatterns on DueloDTO {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DueloDTO value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DueloDTO() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DueloDTO value)  $default,){
final _that = this;
switch (_that) {
case _DueloDTO():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DueloDTO value)?  $default,){
final _that = this;
switch (_that) {
case _DueloDTO() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: EstadoDuelo.desconocido)  EstadoDuelo estado, @JsonKey(unknownEnumValue: OrigenDuelo.desconocido)  OrigenDuelo origen,  String? codigo,  String? enlace,  bool contraBot,  bool completo,  int totalPreguntas,  String? rival,  bool esTuyo,  DateTime? expiraEn,  String? revanchaDe,  int faltanParaBotSegundos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DueloDTO() when $default != null:
return $default(_that.id,_that.estado,_that.origen,_that.codigo,_that.enlace,_that.contraBot,_that.completo,_that.totalPreguntas,_that.rival,_that.esTuyo,_that.expiraEn,_that.revanchaDe,_that.faltanParaBotSegundos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id, @JsonKey(unknownEnumValue: EstadoDuelo.desconocido)  EstadoDuelo estado, @JsonKey(unknownEnumValue: OrigenDuelo.desconocido)  OrigenDuelo origen,  String? codigo,  String? enlace,  bool contraBot,  bool completo,  int totalPreguntas,  String? rival,  bool esTuyo,  DateTime? expiraEn,  String? revanchaDe,  int faltanParaBotSegundos)  $default,) {final _that = this;
switch (_that) {
case _DueloDTO():
return $default(_that.id,_that.estado,_that.origen,_that.codigo,_that.enlace,_that.contraBot,_that.completo,_that.totalPreguntas,_that.rival,_that.esTuyo,_that.expiraEn,_that.revanchaDe,_that.faltanParaBotSegundos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id, @JsonKey(unknownEnumValue: EstadoDuelo.desconocido)  EstadoDuelo estado, @JsonKey(unknownEnumValue: OrigenDuelo.desconocido)  OrigenDuelo origen,  String? codigo,  String? enlace,  bool contraBot,  bool completo,  int totalPreguntas,  String? rival,  bool esTuyo,  DateTime? expiraEn,  String? revanchaDe,  int faltanParaBotSegundos)?  $default,) {final _that = this;
switch (_that) {
case _DueloDTO() when $default != null:
return $default(_that.id,_that.estado,_that.origen,_that.codigo,_that.enlace,_that.contraBot,_that.completo,_that.totalPreguntas,_that.rival,_that.esTuyo,_that.expiraEn,_that.revanchaDe,_that.faltanParaBotSegundos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DueloDTO implements DueloDTO {
  const _DueloDTO({required this.id, @JsonKey(unknownEnumValue: EstadoDuelo.desconocido) required this.estado, @JsonKey(unknownEnumValue: OrigenDuelo.desconocido) required this.origen, this.codigo, this.enlace, this.contraBot = false, this.completo = false, this.totalPreguntas = 10, this.rival, this.esTuyo = false, this.expiraEn, this.revanchaDe, this.faltanParaBotSegundos = 0});
  factory _DueloDTO.fromJson(Map<String, dynamic> json) => _$DueloDTOFromJson(json);

@override final  String id;
@override@JsonKey(unknownEnumValue: EstadoDuelo.desconocido) final  EstadoDuelo estado;
@override@JsonKey(unknownEnumValue: OrigenDuelo.desconocido) final  OrigenDuelo origen;
/// Solo en los de enlace: el PIN de 6 dígitos.
@override final  String? codigo;
/// La URL lista para compartir, ya armada por el servidor.
///
/// La compone el backend para que web y app no tengan cada una su forma de
/// hacerlo: dos formas es una que se queda vieja.
@override final  String? enlace;
@override@JsonKey() final  bool contraBot;
@override@JsonKey() final  bool completo;
@override@JsonKey() final  int totalPreguntas;
/// Cómo se llama el otro, si ya hay otro.
@override final  String? rival;
/// Este duelo lo creó quien pregunta.
///
/// Explícito y no deducido de que `rival` venga vacío: quien abre su propio
/// enlace tiene que ver «este es tu reto, compártelo» y no «te retan».
@override@JsonKey() final  bool esTuyo;
@override final  DateTime? expiraEn;
/// De qué duelo es la revancha, si lo es (RF-61).
@override final  String? revanchaDe;
/// Cuánto falta para poder pedir el bot. 0 si ya se puede.
@override@JsonKey() final  int faltanParaBotSegundos;

/// Create a copy of DueloDTO
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DueloDTOCopyWith<_DueloDTO> get copyWith => __$DueloDTOCopyWithImpl<_DueloDTO>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DueloDTOToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DueloDTO&&(identical(other.id, id) || other.id == id)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.origen, origen) || other.origen == origen)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.enlace, enlace) || other.enlace == enlace)&&(identical(other.contraBot, contraBot) || other.contraBot == contraBot)&&(identical(other.completo, completo) || other.completo == completo)&&(identical(other.totalPreguntas, totalPreguntas) || other.totalPreguntas == totalPreguntas)&&(identical(other.rival, rival) || other.rival == rival)&&(identical(other.esTuyo, esTuyo) || other.esTuyo == esTuyo)&&(identical(other.expiraEn, expiraEn) || other.expiraEn == expiraEn)&&(identical(other.revanchaDe, revanchaDe) || other.revanchaDe == revanchaDe)&&(identical(other.faltanParaBotSegundos, faltanParaBotSegundos) || other.faltanParaBotSegundos == faltanParaBotSegundos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,estado,origen,codigo,enlace,contraBot,completo,totalPreguntas,rival,esTuyo,expiraEn,revanchaDe,faltanParaBotSegundos);

@override
String toString() {
  return 'DueloDTO(id: $id, estado: $estado, origen: $origen, codigo: $codigo, enlace: $enlace, contraBot: $contraBot, completo: $completo, totalPreguntas: $totalPreguntas, rival: $rival, esTuyo: $esTuyo, expiraEn: $expiraEn, revanchaDe: $revanchaDe, faltanParaBotSegundos: $faltanParaBotSegundos)';
}


}

/// @nodoc
abstract mixin class _$DueloDTOCopyWith<$Res> implements $DueloDTOCopyWith<$Res> {
  factory _$DueloDTOCopyWith(_DueloDTO value, $Res Function(_DueloDTO) _then) = __$DueloDTOCopyWithImpl;
@override @useResult
$Res call({
 String id,@JsonKey(unknownEnumValue: EstadoDuelo.desconocido) EstadoDuelo estado,@JsonKey(unknownEnumValue: OrigenDuelo.desconocido) OrigenDuelo origen, String? codigo, String? enlace, bool contraBot, bool completo, int totalPreguntas, String? rival, bool esTuyo, DateTime? expiraEn, String? revanchaDe, int faltanParaBotSegundos
});




}
/// @nodoc
class __$DueloDTOCopyWithImpl<$Res>
    implements _$DueloDTOCopyWith<$Res> {
  __$DueloDTOCopyWithImpl(this._self, this._then);

  final _DueloDTO _self;
  final $Res Function(_DueloDTO) _then;

/// Create a copy of DueloDTO
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? estado = null,Object? origen = null,Object? codigo = freezed,Object? enlace = freezed,Object? contraBot = null,Object? completo = null,Object? totalPreguntas = null,Object? rival = freezed,Object? esTuyo = null,Object? expiraEn = freezed,Object? revanchaDe = freezed,Object? faltanParaBotSegundos = null,}) {
  return _then(_DueloDTO(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDuelo,origen: null == origen ? _self.origen : origen // ignore: cast_nullable_to_non_nullable
as OrigenDuelo,codigo: freezed == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String?,enlace: freezed == enlace ? _self.enlace : enlace // ignore: cast_nullable_to_non_nullable
as String?,contraBot: null == contraBot ? _self.contraBot : contraBot // ignore: cast_nullable_to_non_nullable
as bool,completo: null == completo ? _self.completo : completo // ignore: cast_nullable_to_non_nullable
as bool,totalPreguntas: null == totalPreguntas ? _self.totalPreguntas : totalPreguntas // ignore: cast_nullable_to_non_nullable
as int,rival: freezed == rival ? _self.rival : rival // ignore: cast_nullable_to_non_nullable
as String?,esTuyo: null == esTuyo ? _self.esTuyo : esTuyo // ignore: cast_nullable_to_non_nullable
as bool,expiraEn: freezed == expiraEn ? _self.expiraEn : expiraEn // ignore: cast_nullable_to_non_nullable
as DateTime?,revanchaDe: freezed == revanchaDe ? _self.revanchaDe : revanchaDe // ignore: cast_nullable_to_non_nullable
as String?,faltanParaBotSegundos: null == faltanParaBotSegundos ? _self.faltanParaBotSegundos : faltanParaBotSegundos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$PaseDeDuelo {

 bool get activo; bool get disponible; int get restantes;
/// Create a copy of PaseDeDuelo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaseDeDueloCopyWith<PaseDeDuelo> get copyWith => _$PaseDeDueloCopyWithImpl<PaseDeDuelo>(this as PaseDeDuelo, _$identity);

  /// Serializes this PaseDeDuelo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaseDeDuelo&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.disponible, disponible) || other.disponible == disponible)&&(identical(other.restantes, restantes) || other.restantes == restantes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activo,disponible,restantes);

@override
String toString() {
  return 'PaseDeDuelo(activo: $activo, disponible: $disponible, restantes: $restantes)';
}


}

/// @nodoc
abstract mixin class $PaseDeDueloCopyWith<$Res>  {
  factory $PaseDeDueloCopyWith(PaseDeDuelo value, $Res Function(PaseDeDuelo) _then) = _$PaseDeDueloCopyWithImpl;
@useResult
$Res call({
 bool activo, bool disponible, int restantes
});




}
/// @nodoc
class _$PaseDeDueloCopyWithImpl<$Res>
    implements $PaseDeDueloCopyWith<$Res> {
  _$PaseDeDueloCopyWithImpl(this._self, this._then);

  final PaseDeDuelo _self;
  final $Res Function(PaseDeDuelo) _then;

/// Create a copy of PaseDeDuelo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activo = null,Object? disponible = null,Object? restantes = null,}) {
  return _then(_self.copyWith(
activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,disponible: null == disponible ? _self.disponible : disponible // ignore: cast_nullable_to_non_nullable
as bool,restantes: null == restantes ? _self.restantes : restantes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PaseDeDuelo].
extension PaseDeDueloPatterns on PaseDeDuelo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaseDeDuelo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaseDeDuelo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaseDeDuelo value)  $default,){
final _that = this;
switch (_that) {
case _PaseDeDuelo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaseDeDuelo value)?  $default,){
final _that = this;
switch (_that) {
case _PaseDeDuelo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool activo,  bool disponible,  int restantes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaseDeDuelo() when $default != null:
return $default(_that.activo,_that.disponible,_that.restantes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool activo,  bool disponible,  int restantes)  $default,) {final _that = this;
switch (_that) {
case _PaseDeDuelo():
return $default(_that.activo,_that.disponible,_that.restantes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool activo,  bool disponible,  int restantes)?  $default,) {final _that = this;
switch (_that) {
case _PaseDeDuelo() when $default != null:
return $default(_that.activo,_that.disponible,_that.restantes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaseDeDuelo implements PaseDeDuelo {
  const _PaseDeDuelo({this.activo = false, this.disponible = false, this.restantes = 0});
  factory _PaseDeDuelo.fromJson(Map<String, dynamic> json) => _$PaseDeDueloFromJson(json);

@override@JsonKey() final  bool activo;
@override@JsonKey() final  bool disponible;
@override@JsonKey() final  int restantes;

/// Create a copy of PaseDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaseDeDueloCopyWith<_PaseDeDuelo> get copyWith => __$PaseDeDueloCopyWithImpl<_PaseDeDuelo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaseDeDueloToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaseDeDuelo&&(identical(other.activo, activo) || other.activo == activo)&&(identical(other.disponible, disponible) || other.disponible == disponible)&&(identical(other.restantes, restantes) || other.restantes == restantes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activo,disponible,restantes);

@override
String toString() {
  return 'PaseDeDuelo(activo: $activo, disponible: $disponible, restantes: $restantes)';
}


}

/// @nodoc
abstract mixin class _$PaseDeDueloCopyWith<$Res> implements $PaseDeDueloCopyWith<$Res> {
  factory _$PaseDeDueloCopyWith(_PaseDeDuelo value, $Res Function(_PaseDeDuelo) _then) = __$PaseDeDueloCopyWithImpl;
@override @useResult
$Res call({
 bool activo, bool disponible, int restantes
});




}
/// @nodoc
class __$PaseDeDueloCopyWithImpl<$Res>
    implements _$PaseDeDueloCopyWith<$Res> {
  __$PaseDeDueloCopyWithImpl(this._self, this._then);

  final _PaseDeDuelo _self;
  final $Res Function(_PaseDeDuelo) _then;

/// Create a copy of PaseDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activo = null,Object? disponible = null,Object? restantes = null,}) {
  return _then(_PaseDeDuelo(
activo: null == activo ? _self.activo : activo // ignore: cast_nullable_to_non_nullable
as bool,disponible: null == disponible ? _self.disponible : disponible // ignore: cast_nullable_to_non_nullable
as bool,restantes: null == restantes ? _self.restantes : restantes // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$TicketDeDuelo {

 String get ticket; DateTime get expira; String get url;
/// Create a copy of TicketDeDuelo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TicketDeDueloCopyWith<TicketDeDuelo> get copyWith => _$TicketDeDueloCopyWithImpl<TicketDeDuelo>(this as TicketDeDuelo, _$identity);

  /// Serializes this TicketDeDuelo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TicketDeDuelo&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.expira, expira) || other.expira == expira)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticket,expira,url);

@override
String toString() {
  return 'TicketDeDuelo(ticket: $ticket, expira: $expira, url: $url)';
}


}

/// @nodoc
abstract mixin class $TicketDeDueloCopyWith<$Res>  {
  factory $TicketDeDueloCopyWith(TicketDeDuelo value, $Res Function(TicketDeDuelo) _then) = _$TicketDeDueloCopyWithImpl;
@useResult
$Res call({
 String ticket, DateTime expira, String url
});




}
/// @nodoc
class _$TicketDeDueloCopyWithImpl<$Res>
    implements $TicketDeDueloCopyWith<$Res> {
  _$TicketDeDueloCopyWithImpl(this._self, this._then);

  final TicketDeDuelo _self;
  final $Res Function(TicketDeDuelo) _then;

/// Create a copy of TicketDeDuelo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ticket = null,Object? expira = null,Object? url = null,}) {
  return _then(_self.copyWith(
ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as String,expira: null == expira ? _self.expira : expira // ignore: cast_nullable_to_non_nullable
as DateTime,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [TicketDeDuelo].
extension TicketDeDueloPatterns on TicketDeDuelo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TicketDeDuelo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TicketDeDuelo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TicketDeDuelo value)  $default,){
final _that = this;
switch (_that) {
case _TicketDeDuelo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TicketDeDuelo value)?  $default,){
final _that = this;
switch (_that) {
case _TicketDeDuelo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String ticket,  DateTime expira,  String url)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TicketDeDuelo() when $default != null:
return $default(_that.ticket,_that.expira,_that.url);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String ticket,  DateTime expira,  String url)  $default,) {final _that = this;
switch (_that) {
case _TicketDeDuelo():
return $default(_that.ticket,_that.expira,_that.url);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String ticket,  DateTime expira,  String url)?  $default,) {final _that = this;
switch (_that) {
case _TicketDeDuelo() when $default != null:
return $default(_that.ticket,_that.expira,_that.url);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TicketDeDuelo implements TicketDeDuelo {
  const _TicketDeDuelo({required this.ticket, required this.expira, required this.url});
  factory _TicketDeDuelo.fromJson(Map<String, dynamic> json) => _$TicketDeDueloFromJson(json);

@override final  String ticket;
@override final  DateTime expira;
@override final  String url;

/// Create a copy of TicketDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TicketDeDueloCopyWith<_TicketDeDuelo> get copyWith => __$TicketDeDueloCopyWithImpl<_TicketDeDuelo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TicketDeDueloToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TicketDeDuelo&&(identical(other.ticket, ticket) || other.ticket == ticket)&&(identical(other.expira, expira) || other.expira == expira)&&(identical(other.url, url) || other.url == url));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ticket,expira,url);

@override
String toString() {
  return 'TicketDeDuelo(ticket: $ticket, expira: $expira, url: $url)';
}


}

/// @nodoc
abstract mixin class _$TicketDeDueloCopyWith<$Res> implements $TicketDeDueloCopyWith<$Res> {
  factory _$TicketDeDueloCopyWith(_TicketDeDuelo value, $Res Function(_TicketDeDuelo) _then) = __$TicketDeDueloCopyWithImpl;
@override @useResult
$Res call({
 String ticket, DateTime expira, String url
});




}
/// @nodoc
class __$TicketDeDueloCopyWithImpl<$Res>
    implements _$TicketDeDueloCopyWith<$Res> {
  __$TicketDeDueloCopyWithImpl(this._self, this._then);

  final _TicketDeDuelo _self;
  final $Res Function(_TicketDeDuelo) _then;

/// Create a copy of TicketDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ticket = null,Object? expira = null,Object? url = null,}) {
  return _then(_TicketDeDuelo(
ticket: null == ticket ? _self.ticket : ticket // ignore: cast_nullable_to_non_nullable
as String,expira: null == expira ? _self.expira : expira // ignore: cast_nullable_to_non_nullable
as DateTime,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$LadoDuelo {

 String get nombre; bool get esBot; int get respondidas; int? get aciertos; bool get conectado; List<ResultadoPorPregunta> get resultados;
/// Create a copy of LadoDuelo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LadoDueloCopyWith<LadoDuelo> get copyWith => _$LadoDueloCopyWithImpl<LadoDuelo>(this as LadoDuelo, _$identity);

  /// Serializes this LadoDuelo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LadoDuelo&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.esBot, esBot) || other.esBot == esBot)&&(identical(other.respondidas, respondidas) || other.respondidas == respondidas)&&(identical(other.aciertos, aciertos) || other.aciertos == aciertos)&&(identical(other.conectado, conectado) || other.conectado == conectado)&&const DeepCollectionEquality().equals(other.resultados, resultados));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nombre,esBot,respondidas,aciertos,conectado,const DeepCollectionEquality().hash(resultados));

@override
String toString() {
  return 'LadoDuelo(nombre: $nombre, esBot: $esBot, respondidas: $respondidas, aciertos: $aciertos, conectado: $conectado, resultados: $resultados)';
}


}

/// @nodoc
abstract mixin class $LadoDueloCopyWith<$Res>  {
  factory $LadoDueloCopyWith(LadoDuelo value, $Res Function(LadoDuelo) _then) = _$LadoDueloCopyWithImpl;
@useResult
$Res call({
 String nombre, bool esBot, int respondidas, int? aciertos, bool conectado, List<ResultadoPorPregunta> resultados
});




}
/// @nodoc
class _$LadoDueloCopyWithImpl<$Res>
    implements $LadoDueloCopyWith<$Res> {
  _$LadoDueloCopyWithImpl(this._self, this._then);

  final LadoDuelo _self;
  final $Res Function(LadoDuelo) _then;

/// Create a copy of LadoDuelo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nombre = null,Object? esBot = null,Object? respondidas = null,Object? aciertos = freezed,Object? conectado = null,Object? resultados = null,}) {
  return _then(_self.copyWith(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,esBot: null == esBot ? _self.esBot : esBot // ignore: cast_nullable_to_non_nullable
as bool,respondidas: null == respondidas ? _self.respondidas : respondidas // ignore: cast_nullable_to_non_nullable
as int,aciertos: freezed == aciertos ? _self.aciertos : aciertos // ignore: cast_nullable_to_non_nullable
as int?,conectado: null == conectado ? _self.conectado : conectado // ignore: cast_nullable_to_non_nullable
as bool,resultados: null == resultados ? _self.resultados : resultados // ignore: cast_nullable_to_non_nullable
as List<ResultadoPorPregunta>,
  ));
}

}


/// Adds pattern-matching-related methods to [LadoDuelo].
extension LadoDueloPatterns on LadoDuelo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LadoDuelo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LadoDuelo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LadoDuelo value)  $default,){
final _that = this;
switch (_that) {
case _LadoDuelo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LadoDuelo value)?  $default,){
final _that = this;
switch (_that) {
case _LadoDuelo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String nombre,  bool esBot,  int respondidas,  int? aciertos,  bool conectado,  List<ResultadoPorPregunta> resultados)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LadoDuelo() when $default != null:
return $default(_that.nombre,_that.esBot,_that.respondidas,_that.aciertos,_that.conectado,_that.resultados);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String nombre,  bool esBot,  int respondidas,  int? aciertos,  bool conectado,  List<ResultadoPorPregunta> resultados)  $default,) {final _that = this;
switch (_that) {
case _LadoDuelo():
return $default(_that.nombre,_that.esBot,_that.respondidas,_that.aciertos,_that.conectado,_that.resultados);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String nombre,  bool esBot,  int respondidas,  int? aciertos,  bool conectado,  List<ResultadoPorPregunta> resultados)?  $default,) {final _that = this;
switch (_that) {
case _LadoDuelo() when $default != null:
return $default(_that.nombre,_that.esBot,_that.respondidas,_that.aciertos,_that.conectado,_that.resultados);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _LadoDuelo implements LadoDuelo {
  const _LadoDuelo({this.nombre = '', this.esBot = false, this.respondidas = 0, this.aciertos, this.conectado = true, final  List<ResultadoPorPregunta> resultados = const <ResultadoPorPregunta>[]}): _resultados = resultados;
  factory _LadoDuelo.fromJson(Map<String, dynamic> json) => _$LadoDueloFromJson(json);

@override@JsonKey() final  String nombre;
@override@JsonKey() final  bool esBot;
@override@JsonKey() final  int respondidas;
@override final  int? aciertos;
@override@JsonKey() final  bool conectado;
 final  List<ResultadoPorPregunta> _resultados;
@override@JsonKey() List<ResultadoPorPregunta> get resultados {
  if (_resultados is EqualUnmodifiableListView) return _resultados;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_resultados);
}


/// Create a copy of LadoDuelo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LadoDueloCopyWith<_LadoDuelo> get copyWith => __$LadoDueloCopyWithImpl<_LadoDuelo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$LadoDueloToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LadoDuelo&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.esBot, esBot) || other.esBot == esBot)&&(identical(other.respondidas, respondidas) || other.respondidas == respondidas)&&(identical(other.aciertos, aciertos) || other.aciertos == aciertos)&&(identical(other.conectado, conectado) || other.conectado == conectado)&&const DeepCollectionEquality().equals(other._resultados, _resultados));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nombre,esBot,respondidas,aciertos,conectado,const DeepCollectionEquality().hash(_resultados));

@override
String toString() {
  return 'LadoDuelo(nombre: $nombre, esBot: $esBot, respondidas: $respondidas, aciertos: $aciertos, conectado: $conectado, resultados: $resultados)';
}


}

/// @nodoc
abstract mixin class _$LadoDueloCopyWith<$Res> implements $LadoDueloCopyWith<$Res> {
  factory _$LadoDueloCopyWith(_LadoDuelo value, $Res Function(_LadoDuelo) _then) = __$LadoDueloCopyWithImpl;
@override @useResult
$Res call({
 String nombre, bool esBot, int respondidas, int? aciertos, bool conectado, List<ResultadoPorPregunta> resultados
});




}
/// @nodoc
class __$LadoDueloCopyWithImpl<$Res>
    implements _$LadoDueloCopyWith<$Res> {
  __$LadoDueloCopyWithImpl(this._self, this._then);

  final _LadoDuelo _self;
  final $Res Function(_LadoDuelo) _then;

/// Create a copy of LadoDuelo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nombre = null,Object? esBot = null,Object? respondidas = null,Object? aciertos = freezed,Object? conectado = null,Object? resultados = null,}) {
  return _then(_LadoDuelo(
nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,esBot: null == esBot ? _self.esBot : esBot // ignore: cast_nullable_to_non_nullable
as bool,respondidas: null == respondidas ? _self.respondidas : respondidas // ignore: cast_nullable_to_non_nullable
as int,aciertos: freezed == aciertos ? _self.aciertos : aciertos // ignore: cast_nullable_to_non_nullable
as int?,conectado: null == conectado ? _self.conectado : conectado // ignore: cast_nullable_to_non_nullable
as bool,resultados: null == resultados ? _self._resultados : resultados // ignore: cast_nullable_to_non_nullable
as List<ResultadoPorPregunta>,
  ));
}


}


/// @nodoc
mixin _$EstadoDeLaPartida {

 String get id; EstadoDuelo get estado; int get totalPreguntas; LadoDuelo get tu; LadoDuelo get rival;/// El bot es de pago para quien recibe esto (RF-65).
///
/// Es el caso del duelo diario gratuito: la oferta se enseña, apagada.
/// Viene con el nombre de la consecuencia y no del motivo, porque es lo que
/// la pantalla tiene que hacer con él.
 bool get botBloqueado;
/// Create a copy of EstadoDeLaPartida
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EstadoDeLaPartidaCopyWith<EstadoDeLaPartida> get copyWith => _$EstadoDeLaPartidaCopyWithImpl<EstadoDeLaPartida>(this as EstadoDeLaPartida, _$identity);

  /// Serializes this EstadoDeLaPartida to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EstadoDeLaPartida&&(identical(other.id, id) || other.id == id)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.totalPreguntas, totalPreguntas) || other.totalPreguntas == totalPreguntas)&&(identical(other.tu, tu) || other.tu == tu)&&(identical(other.rival, rival) || other.rival == rival)&&(identical(other.botBloqueado, botBloqueado) || other.botBloqueado == botBloqueado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,estado,totalPreguntas,tu,rival,botBloqueado);

@override
String toString() {
  return 'EstadoDeLaPartida(id: $id, estado: $estado, totalPreguntas: $totalPreguntas, tu: $tu, rival: $rival, botBloqueado: $botBloqueado)';
}


}

/// @nodoc
abstract mixin class $EstadoDeLaPartidaCopyWith<$Res>  {
  factory $EstadoDeLaPartidaCopyWith(EstadoDeLaPartida value, $Res Function(EstadoDeLaPartida) _then) = _$EstadoDeLaPartidaCopyWithImpl;
@useResult
$Res call({
 String id, EstadoDuelo estado, int totalPreguntas, LadoDuelo tu, LadoDuelo rival, bool botBloqueado
});


$LadoDueloCopyWith<$Res> get tu;$LadoDueloCopyWith<$Res> get rival;

}
/// @nodoc
class _$EstadoDeLaPartidaCopyWithImpl<$Res>
    implements $EstadoDeLaPartidaCopyWith<$Res> {
  _$EstadoDeLaPartidaCopyWithImpl(this._self, this._then);

  final EstadoDeLaPartida _self;
  final $Res Function(EstadoDeLaPartida) _then;

/// Create a copy of EstadoDeLaPartida
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? estado = null,Object? totalPreguntas = null,Object? tu = null,Object? rival = null,Object? botBloqueado = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDuelo,totalPreguntas: null == totalPreguntas ? _self.totalPreguntas : totalPreguntas // ignore: cast_nullable_to_non_nullable
as int,tu: null == tu ? _self.tu : tu // ignore: cast_nullable_to_non_nullable
as LadoDuelo,rival: null == rival ? _self.rival : rival // ignore: cast_nullable_to_non_nullable
as LadoDuelo,botBloqueado: null == botBloqueado ? _self.botBloqueado : botBloqueado // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of EstadoDeLaPartida
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LadoDueloCopyWith<$Res> get tu {
  
  return $LadoDueloCopyWith<$Res>(_self.tu, (value) {
    return _then(_self.copyWith(tu: value));
  });
}/// Create a copy of EstadoDeLaPartida
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LadoDueloCopyWith<$Res> get rival {
  
  return $LadoDueloCopyWith<$Res>(_self.rival, (value) {
    return _then(_self.copyWith(rival: value));
  });
}
}


/// Adds pattern-matching-related methods to [EstadoDeLaPartida].
extension EstadoDeLaPartidaPatterns on EstadoDeLaPartida {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EstadoDeLaPartida value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EstadoDeLaPartida() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EstadoDeLaPartida value)  $default,){
final _that = this;
switch (_that) {
case _EstadoDeLaPartida():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EstadoDeLaPartida value)?  $default,){
final _that = this;
switch (_that) {
case _EstadoDeLaPartida() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  EstadoDuelo estado,  int totalPreguntas,  LadoDuelo tu,  LadoDuelo rival,  bool botBloqueado)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EstadoDeLaPartida() when $default != null:
return $default(_that.id,_that.estado,_that.totalPreguntas,_that.tu,_that.rival,_that.botBloqueado);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  EstadoDuelo estado,  int totalPreguntas,  LadoDuelo tu,  LadoDuelo rival,  bool botBloqueado)  $default,) {final _that = this;
switch (_that) {
case _EstadoDeLaPartida():
return $default(_that.id,_that.estado,_that.totalPreguntas,_that.tu,_that.rival,_that.botBloqueado);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  EstadoDuelo estado,  int totalPreguntas,  LadoDuelo tu,  LadoDuelo rival,  bool botBloqueado)?  $default,) {final _that = this;
switch (_that) {
case _EstadoDeLaPartida() when $default != null:
return $default(_that.id,_that.estado,_that.totalPreguntas,_that.tu,_that.rival,_that.botBloqueado);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EstadoDeLaPartida implements EstadoDeLaPartida {
  const _EstadoDeLaPartida({required this.id, required this.estado, this.totalPreguntas = 10, required this.tu, required this.rival, this.botBloqueado = false});
  factory _EstadoDeLaPartida.fromJson(Map<String, dynamic> json) => _$EstadoDeLaPartidaFromJson(json);

@override final  String id;
@override final  EstadoDuelo estado;
@override@JsonKey() final  int totalPreguntas;
@override final  LadoDuelo tu;
@override final  LadoDuelo rival;
/// El bot es de pago para quien recibe esto (RF-65).
///
/// Es el caso del duelo diario gratuito: la oferta se enseña, apagada.
/// Viene con el nombre de la consecuencia y no del motivo, porque es lo que
/// la pantalla tiene que hacer con él.
@override@JsonKey() final  bool botBloqueado;

/// Create a copy of EstadoDeLaPartida
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EstadoDeLaPartidaCopyWith<_EstadoDeLaPartida> get copyWith => __$EstadoDeLaPartidaCopyWithImpl<_EstadoDeLaPartida>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EstadoDeLaPartidaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EstadoDeLaPartida&&(identical(other.id, id) || other.id == id)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.totalPreguntas, totalPreguntas) || other.totalPreguntas == totalPreguntas)&&(identical(other.tu, tu) || other.tu == tu)&&(identical(other.rival, rival) || other.rival == rival)&&(identical(other.botBloqueado, botBloqueado) || other.botBloqueado == botBloqueado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,estado,totalPreguntas,tu,rival,botBloqueado);

@override
String toString() {
  return 'EstadoDeLaPartida(id: $id, estado: $estado, totalPreguntas: $totalPreguntas, tu: $tu, rival: $rival, botBloqueado: $botBloqueado)';
}


}

/// @nodoc
abstract mixin class _$EstadoDeLaPartidaCopyWith<$Res> implements $EstadoDeLaPartidaCopyWith<$Res> {
  factory _$EstadoDeLaPartidaCopyWith(_EstadoDeLaPartida value, $Res Function(_EstadoDeLaPartida) _then) = __$EstadoDeLaPartidaCopyWithImpl;
@override @useResult
$Res call({
 String id, EstadoDuelo estado, int totalPreguntas, LadoDuelo tu, LadoDuelo rival, bool botBloqueado
});


@override $LadoDueloCopyWith<$Res> get tu;@override $LadoDueloCopyWith<$Res> get rival;

}
/// @nodoc
class __$EstadoDeLaPartidaCopyWithImpl<$Res>
    implements _$EstadoDeLaPartidaCopyWith<$Res> {
  __$EstadoDeLaPartidaCopyWithImpl(this._self, this._then);

  final _EstadoDeLaPartida _self;
  final $Res Function(_EstadoDeLaPartida) _then;

/// Create a copy of EstadoDeLaPartida
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? estado = null,Object? totalPreguntas = null,Object? tu = null,Object? rival = null,Object? botBloqueado = null,}) {
  return _then(_EstadoDeLaPartida(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoDuelo,totalPreguntas: null == totalPreguntas ? _self.totalPreguntas : totalPreguntas // ignore: cast_nullable_to_non_nullable
as int,tu: null == tu ? _self.tu : tu // ignore: cast_nullable_to_non_nullable
as LadoDuelo,rival: null == rival ? _self.rival : rival // ignore: cast_nullable_to_non_nullable
as LadoDuelo,botBloqueado: null == botBloqueado ? _self.botBloqueado : botBloqueado // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of EstadoDeLaPartida
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LadoDueloCopyWith<$Res> get tu {
  
  return $LadoDueloCopyWith<$Res>(_self.tu, (value) {
    return _then(_self.copyWith(tu: value));
  });
}/// Create a copy of EstadoDeLaPartida
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LadoDueloCopyWith<$Res> get rival {
  
  return $LadoDueloCopyWith<$Res>(_self.rival, (value) {
    return _then(_self.copyWith(rival: value));
  });
}
}


/// @nodoc
mixin _$OpcionDuelo {

 String get id; String get texto;
/// Create a copy of OpcionDuelo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpcionDueloCopyWith<OpcionDuelo> get copyWith => _$OpcionDueloCopyWithImpl<OpcionDuelo>(this as OpcionDuelo, _$identity);

  /// Serializes this OpcionDuelo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpcionDuelo&&(identical(other.id, id) || other.id == id)&&(identical(other.texto, texto) || other.texto == texto));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,texto);

@override
String toString() {
  return 'OpcionDuelo(id: $id, texto: $texto)';
}


}

/// @nodoc
abstract mixin class $OpcionDueloCopyWith<$Res>  {
  factory $OpcionDueloCopyWith(OpcionDuelo value, $Res Function(OpcionDuelo) _then) = _$OpcionDueloCopyWithImpl;
@useResult
$Res call({
 String id, String texto
});




}
/// @nodoc
class _$OpcionDueloCopyWithImpl<$Res>
    implements $OpcionDueloCopyWith<$Res> {
  _$OpcionDueloCopyWithImpl(this._self, this._then);

  final OpcionDuelo _self;
  final $Res Function(OpcionDuelo) _then;

/// Create a copy of OpcionDuelo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? texto = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [OpcionDuelo].
extension OpcionDueloPatterns on OpcionDuelo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpcionDuelo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpcionDuelo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpcionDuelo value)  $default,){
final _that = this;
switch (_that) {
case _OpcionDuelo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpcionDuelo value)?  $default,){
final _that = this;
switch (_that) {
case _OpcionDuelo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String texto)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpcionDuelo() when $default != null:
return $default(_that.id,_that.texto);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String texto)  $default,) {final _that = this;
switch (_that) {
case _OpcionDuelo():
return $default(_that.id,_that.texto);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String texto)?  $default,) {final _that = this;
switch (_that) {
case _OpcionDuelo() when $default != null:
return $default(_that.id,_that.texto);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpcionDuelo implements OpcionDuelo {
  const _OpcionDuelo({required this.id, required this.texto});
  factory _OpcionDuelo.fromJson(Map<String, dynamic> json) => _$OpcionDueloFromJson(json);

@override final  String id;
@override final  String texto;

/// Create a copy of OpcionDuelo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpcionDueloCopyWith<_OpcionDuelo> get copyWith => __$OpcionDueloCopyWithImpl<_OpcionDuelo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpcionDueloToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpcionDuelo&&(identical(other.id, id) || other.id == id)&&(identical(other.texto, texto) || other.texto == texto));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,texto);

@override
String toString() {
  return 'OpcionDuelo(id: $id, texto: $texto)';
}


}

/// @nodoc
abstract mixin class _$OpcionDueloCopyWith<$Res> implements $OpcionDueloCopyWith<$Res> {
  factory _$OpcionDueloCopyWith(_OpcionDuelo value, $Res Function(_OpcionDuelo) _then) = __$OpcionDueloCopyWithImpl;
@override @useResult
$Res call({
 String id, String texto
});




}
/// @nodoc
class __$OpcionDueloCopyWithImpl<$Res>
    implements _$OpcionDueloCopyWith<$Res> {
  __$OpcionDueloCopyWithImpl(this._self, this._then);

  final _OpcionDuelo _self;
  final $Res Function(_OpcionDuelo) _then;

/// Create a copy of OpcionDuelo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? texto = null,}) {
  return _then(_OpcionDuelo(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$PreguntaEnJuego {

 int get orden; int get totalPreguntas; String get enunciado; List<OpcionDuelo> get opciones;/// La hora exacta a la que se cierra. **Es el reloj.**
///
/// Absoluta y no «te quedan 20 s» a propósito: con los segundos restantes,
/// el retraso de la red se convierte en ventaja para quien tenga mejor
/// conexión. Con la hora de cierre, los dos cuentan contra el mismo
/// instante.
 DateTime get cierraEn; int get segundos;
/// Create a copy of PreguntaEnJuego
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreguntaEnJuegoCopyWith<PreguntaEnJuego> get copyWith => _$PreguntaEnJuegoCopyWithImpl<PreguntaEnJuego>(this as PreguntaEnJuego, _$identity);

  /// Serializes this PreguntaEnJuego to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreguntaEnJuego&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.totalPreguntas, totalPreguntas) || other.totalPreguntas == totalPreguntas)&&(identical(other.enunciado, enunciado) || other.enunciado == enunciado)&&const DeepCollectionEquality().equals(other.opciones, opciones)&&(identical(other.cierraEn, cierraEn) || other.cierraEn == cierraEn)&&(identical(other.segundos, segundos) || other.segundos == segundos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orden,totalPreguntas,enunciado,const DeepCollectionEquality().hash(opciones),cierraEn,segundos);

@override
String toString() {
  return 'PreguntaEnJuego(orden: $orden, totalPreguntas: $totalPreguntas, enunciado: $enunciado, opciones: $opciones, cierraEn: $cierraEn, segundos: $segundos)';
}


}

/// @nodoc
abstract mixin class $PreguntaEnJuegoCopyWith<$Res>  {
  factory $PreguntaEnJuegoCopyWith(PreguntaEnJuego value, $Res Function(PreguntaEnJuego) _then) = _$PreguntaEnJuegoCopyWithImpl;
@useResult
$Res call({
 int orden, int totalPreguntas, String enunciado, List<OpcionDuelo> opciones, DateTime cierraEn, int segundos
});




}
/// @nodoc
class _$PreguntaEnJuegoCopyWithImpl<$Res>
    implements $PreguntaEnJuegoCopyWith<$Res> {
  _$PreguntaEnJuegoCopyWithImpl(this._self, this._then);

  final PreguntaEnJuego _self;
  final $Res Function(PreguntaEnJuego) _then;

/// Create a copy of PreguntaEnJuego
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orden = null,Object? totalPreguntas = null,Object? enunciado = null,Object? opciones = null,Object? cierraEn = null,Object? segundos = null,}) {
  return _then(_self.copyWith(
orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,totalPreguntas: null == totalPreguntas ? _self.totalPreguntas : totalPreguntas // ignore: cast_nullable_to_non_nullable
as int,enunciado: null == enunciado ? _self.enunciado : enunciado // ignore: cast_nullable_to_non_nullable
as String,opciones: null == opciones ? _self.opciones : opciones // ignore: cast_nullable_to_non_nullable
as List<OpcionDuelo>,cierraEn: null == cierraEn ? _self.cierraEn : cierraEn // ignore: cast_nullable_to_non_nullable
as DateTime,segundos: null == segundos ? _self.segundos : segundos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PreguntaEnJuego].
extension PreguntaEnJuegoPatterns on PreguntaEnJuego {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreguntaEnJuego value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreguntaEnJuego() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreguntaEnJuego value)  $default,){
final _that = this;
switch (_that) {
case _PreguntaEnJuego():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreguntaEnJuego value)?  $default,){
final _that = this;
switch (_that) {
case _PreguntaEnJuego() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int orden,  int totalPreguntas,  String enunciado,  List<OpcionDuelo> opciones,  DateTime cierraEn,  int segundos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreguntaEnJuego() when $default != null:
return $default(_that.orden,_that.totalPreguntas,_that.enunciado,_that.opciones,_that.cierraEn,_that.segundos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int orden,  int totalPreguntas,  String enunciado,  List<OpcionDuelo> opciones,  DateTime cierraEn,  int segundos)  $default,) {final _that = this;
switch (_that) {
case _PreguntaEnJuego():
return $default(_that.orden,_that.totalPreguntas,_that.enunciado,_that.opciones,_that.cierraEn,_that.segundos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int orden,  int totalPreguntas,  String enunciado,  List<OpcionDuelo> opciones,  DateTime cierraEn,  int segundos)?  $default,) {final _that = this;
switch (_that) {
case _PreguntaEnJuego() when $default != null:
return $default(_that.orden,_that.totalPreguntas,_that.enunciado,_that.opciones,_that.cierraEn,_that.segundos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreguntaEnJuego implements PreguntaEnJuego {
  const _PreguntaEnJuego({required this.orden, this.totalPreguntas = 10, this.enunciado = '', final  List<OpcionDuelo> opciones = const <OpcionDuelo>[], required this.cierraEn, this.segundos = 30}): _opciones = opciones;
  factory _PreguntaEnJuego.fromJson(Map<String, dynamic> json) => _$PreguntaEnJuegoFromJson(json);

@override final  int orden;
@override@JsonKey() final  int totalPreguntas;
@override@JsonKey() final  String enunciado;
 final  List<OpcionDuelo> _opciones;
@override@JsonKey() List<OpcionDuelo> get opciones {
  if (_opciones is EqualUnmodifiableListView) return _opciones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_opciones);
}

/// La hora exacta a la que se cierra. **Es el reloj.**
///
/// Absoluta y no «te quedan 20 s» a propósito: con los segundos restantes,
/// el retraso de la red se convierte en ventaja para quien tenga mejor
/// conexión. Con la hora de cierre, los dos cuentan contra el mismo
/// instante.
@override final  DateTime cierraEn;
@override@JsonKey() final  int segundos;

/// Create a copy of PreguntaEnJuego
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreguntaEnJuegoCopyWith<_PreguntaEnJuego> get copyWith => __$PreguntaEnJuegoCopyWithImpl<_PreguntaEnJuego>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreguntaEnJuegoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreguntaEnJuego&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.totalPreguntas, totalPreguntas) || other.totalPreguntas == totalPreguntas)&&(identical(other.enunciado, enunciado) || other.enunciado == enunciado)&&const DeepCollectionEquality().equals(other._opciones, _opciones)&&(identical(other.cierraEn, cierraEn) || other.cierraEn == cierraEn)&&(identical(other.segundos, segundos) || other.segundos == segundos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orden,totalPreguntas,enunciado,const DeepCollectionEquality().hash(_opciones),cierraEn,segundos);

@override
String toString() {
  return 'PreguntaEnJuego(orden: $orden, totalPreguntas: $totalPreguntas, enunciado: $enunciado, opciones: $opciones, cierraEn: $cierraEn, segundos: $segundos)';
}


}

/// @nodoc
abstract mixin class _$PreguntaEnJuegoCopyWith<$Res> implements $PreguntaEnJuegoCopyWith<$Res> {
  factory _$PreguntaEnJuegoCopyWith(_PreguntaEnJuego value, $Res Function(_PreguntaEnJuego) _then) = __$PreguntaEnJuegoCopyWithImpl;
@override @useResult
$Res call({
 int orden, int totalPreguntas, String enunciado, List<OpcionDuelo> opciones, DateTime cierraEn, int segundos
});




}
/// @nodoc
class __$PreguntaEnJuegoCopyWithImpl<$Res>
    implements _$PreguntaEnJuegoCopyWith<$Res> {
  __$PreguntaEnJuegoCopyWithImpl(this._self, this._then);

  final _PreguntaEnJuego _self;
  final $Res Function(_PreguntaEnJuego) _then;

/// Create a copy of PreguntaEnJuego
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orden = null,Object? totalPreguntas = null,Object? enunciado = null,Object? opciones = null,Object? cierraEn = null,Object? segundos = null,}) {
  return _then(_PreguntaEnJuego(
orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,totalPreguntas: null == totalPreguntas ? _self.totalPreguntas : totalPreguntas // ignore: cast_nullable_to_non_nullable
as int,enunciado: null == enunciado ? _self.enunciado : enunciado // ignore: cast_nullable_to_non_nullable
as String,opciones: null == opciones ? _self._opciones : opciones // ignore: cast_nullable_to_non_nullable
as List<OpcionDuelo>,cierraEn: null == cierraEn ? _self.cierraEn : cierraEn // ignore: cast_nullable_to_non_nullable
as DateTime,segundos: null == segundos ? _self.segundos : segundos // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ResultadoDePregunta {

 int get orden; String get opcionCorrectaId; String get explicacion; String? get tuOpcionId; bool get acertaste; int get tuTiempoMs; int get tusAciertos;/// Que contestó, no si acertó.
 bool get rivalRespondio; int get rivalRespondidas; int get siguienteEnMs; bool get esUltima;
/// Create a copy of ResultadoDePregunta
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResultadoDePreguntaCopyWith<ResultadoDePregunta> get copyWith => _$ResultadoDePreguntaCopyWithImpl<ResultadoDePregunta>(this as ResultadoDePregunta, _$identity);

  /// Serializes this ResultadoDePregunta to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResultadoDePregunta&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.opcionCorrectaId, opcionCorrectaId) || other.opcionCorrectaId == opcionCorrectaId)&&(identical(other.explicacion, explicacion) || other.explicacion == explicacion)&&(identical(other.tuOpcionId, tuOpcionId) || other.tuOpcionId == tuOpcionId)&&(identical(other.acertaste, acertaste) || other.acertaste == acertaste)&&(identical(other.tuTiempoMs, tuTiempoMs) || other.tuTiempoMs == tuTiempoMs)&&(identical(other.tusAciertos, tusAciertos) || other.tusAciertos == tusAciertos)&&(identical(other.rivalRespondio, rivalRespondio) || other.rivalRespondio == rivalRespondio)&&(identical(other.rivalRespondidas, rivalRespondidas) || other.rivalRespondidas == rivalRespondidas)&&(identical(other.siguienteEnMs, siguienteEnMs) || other.siguienteEnMs == siguienteEnMs)&&(identical(other.esUltima, esUltima) || other.esUltima == esUltima));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orden,opcionCorrectaId,explicacion,tuOpcionId,acertaste,tuTiempoMs,tusAciertos,rivalRespondio,rivalRespondidas,siguienteEnMs,esUltima);

@override
String toString() {
  return 'ResultadoDePregunta(orden: $orden, opcionCorrectaId: $opcionCorrectaId, explicacion: $explicacion, tuOpcionId: $tuOpcionId, acertaste: $acertaste, tuTiempoMs: $tuTiempoMs, tusAciertos: $tusAciertos, rivalRespondio: $rivalRespondio, rivalRespondidas: $rivalRespondidas, siguienteEnMs: $siguienteEnMs, esUltima: $esUltima)';
}


}

/// @nodoc
abstract mixin class $ResultadoDePreguntaCopyWith<$Res>  {
  factory $ResultadoDePreguntaCopyWith(ResultadoDePregunta value, $Res Function(ResultadoDePregunta) _then) = _$ResultadoDePreguntaCopyWithImpl;
@useResult
$Res call({
 int orden, String opcionCorrectaId, String explicacion, String? tuOpcionId, bool acertaste, int tuTiempoMs, int tusAciertos, bool rivalRespondio, int rivalRespondidas, int siguienteEnMs, bool esUltima
});




}
/// @nodoc
class _$ResultadoDePreguntaCopyWithImpl<$Res>
    implements $ResultadoDePreguntaCopyWith<$Res> {
  _$ResultadoDePreguntaCopyWithImpl(this._self, this._then);

  final ResultadoDePregunta _self;
  final $Res Function(ResultadoDePregunta) _then;

/// Create a copy of ResultadoDePregunta
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orden = null,Object? opcionCorrectaId = null,Object? explicacion = null,Object? tuOpcionId = freezed,Object? acertaste = null,Object? tuTiempoMs = null,Object? tusAciertos = null,Object? rivalRespondio = null,Object? rivalRespondidas = null,Object? siguienteEnMs = null,Object? esUltima = null,}) {
  return _then(_self.copyWith(
orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,opcionCorrectaId: null == opcionCorrectaId ? _self.opcionCorrectaId : opcionCorrectaId // ignore: cast_nullable_to_non_nullable
as String,explicacion: null == explicacion ? _self.explicacion : explicacion // ignore: cast_nullable_to_non_nullable
as String,tuOpcionId: freezed == tuOpcionId ? _self.tuOpcionId : tuOpcionId // ignore: cast_nullable_to_non_nullable
as String?,acertaste: null == acertaste ? _self.acertaste : acertaste // ignore: cast_nullable_to_non_nullable
as bool,tuTiempoMs: null == tuTiempoMs ? _self.tuTiempoMs : tuTiempoMs // ignore: cast_nullable_to_non_nullable
as int,tusAciertos: null == tusAciertos ? _self.tusAciertos : tusAciertos // ignore: cast_nullable_to_non_nullable
as int,rivalRespondio: null == rivalRespondio ? _self.rivalRespondio : rivalRespondio // ignore: cast_nullable_to_non_nullable
as bool,rivalRespondidas: null == rivalRespondidas ? _self.rivalRespondidas : rivalRespondidas // ignore: cast_nullable_to_non_nullable
as int,siguienteEnMs: null == siguienteEnMs ? _self.siguienteEnMs : siguienteEnMs // ignore: cast_nullable_to_non_nullable
as int,esUltima: null == esUltima ? _self.esUltima : esUltima // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ResultadoDePregunta].
extension ResultadoDePreguntaPatterns on ResultadoDePregunta {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResultadoDePregunta value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResultadoDePregunta() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResultadoDePregunta value)  $default,){
final _that = this;
switch (_that) {
case _ResultadoDePregunta():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResultadoDePregunta value)?  $default,){
final _that = this;
switch (_that) {
case _ResultadoDePregunta() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int orden,  String opcionCorrectaId,  String explicacion,  String? tuOpcionId,  bool acertaste,  int tuTiempoMs,  int tusAciertos,  bool rivalRespondio,  int rivalRespondidas,  int siguienteEnMs,  bool esUltima)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResultadoDePregunta() when $default != null:
return $default(_that.orden,_that.opcionCorrectaId,_that.explicacion,_that.tuOpcionId,_that.acertaste,_that.tuTiempoMs,_that.tusAciertos,_that.rivalRespondio,_that.rivalRespondidas,_that.siguienteEnMs,_that.esUltima);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int orden,  String opcionCorrectaId,  String explicacion,  String? tuOpcionId,  bool acertaste,  int tuTiempoMs,  int tusAciertos,  bool rivalRespondio,  int rivalRespondidas,  int siguienteEnMs,  bool esUltima)  $default,) {final _that = this;
switch (_that) {
case _ResultadoDePregunta():
return $default(_that.orden,_that.opcionCorrectaId,_that.explicacion,_that.tuOpcionId,_that.acertaste,_that.tuTiempoMs,_that.tusAciertos,_that.rivalRespondio,_that.rivalRespondidas,_that.siguienteEnMs,_that.esUltima);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int orden,  String opcionCorrectaId,  String explicacion,  String? tuOpcionId,  bool acertaste,  int tuTiempoMs,  int tusAciertos,  bool rivalRespondio,  int rivalRespondidas,  int siguienteEnMs,  bool esUltima)?  $default,) {final _that = this;
switch (_that) {
case _ResultadoDePregunta() when $default != null:
return $default(_that.orden,_that.opcionCorrectaId,_that.explicacion,_that.tuOpcionId,_that.acertaste,_that.tuTiempoMs,_that.tusAciertos,_that.rivalRespondio,_that.rivalRespondidas,_that.siguienteEnMs,_that.esUltima);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResultadoDePregunta implements ResultadoDePregunta {
  const _ResultadoDePregunta({this.orden = 0, this.opcionCorrectaId = '', this.explicacion = '', this.tuOpcionId, this.acertaste = false, this.tuTiempoMs = 0, this.tusAciertos = 0, this.rivalRespondio = false, this.rivalRespondidas = 0, this.siguienteEnMs = 0, this.esUltima = false});
  factory _ResultadoDePregunta.fromJson(Map<String, dynamic> json) => _$ResultadoDePreguntaFromJson(json);

@override@JsonKey() final  int orden;
@override@JsonKey() final  String opcionCorrectaId;
@override@JsonKey() final  String explicacion;
@override final  String? tuOpcionId;
@override@JsonKey() final  bool acertaste;
@override@JsonKey() final  int tuTiempoMs;
@override@JsonKey() final  int tusAciertos;
/// Que contestó, no si acertó.
@override@JsonKey() final  bool rivalRespondio;
@override@JsonKey() final  int rivalRespondidas;
@override@JsonKey() final  int siguienteEnMs;
@override@JsonKey() final  bool esUltima;

/// Create a copy of ResultadoDePregunta
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResultadoDePreguntaCopyWith<_ResultadoDePregunta> get copyWith => __$ResultadoDePreguntaCopyWithImpl<_ResultadoDePregunta>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResultadoDePreguntaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResultadoDePregunta&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.opcionCorrectaId, opcionCorrectaId) || other.opcionCorrectaId == opcionCorrectaId)&&(identical(other.explicacion, explicacion) || other.explicacion == explicacion)&&(identical(other.tuOpcionId, tuOpcionId) || other.tuOpcionId == tuOpcionId)&&(identical(other.acertaste, acertaste) || other.acertaste == acertaste)&&(identical(other.tuTiempoMs, tuTiempoMs) || other.tuTiempoMs == tuTiempoMs)&&(identical(other.tusAciertos, tusAciertos) || other.tusAciertos == tusAciertos)&&(identical(other.rivalRespondio, rivalRespondio) || other.rivalRespondio == rivalRespondio)&&(identical(other.rivalRespondidas, rivalRespondidas) || other.rivalRespondidas == rivalRespondidas)&&(identical(other.siguienteEnMs, siguienteEnMs) || other.siguienteEnMs == siguienteEnMs)&&(identical(other.esUltima, esUltima) || other.esUltima == esUltima));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orden,opcionCorrectaId,explicacion,tuOpcionId,acertaste,tuTiempoMs,tusAciertos,rivalRespondio,rivalRespondidas,siguienteEnMs,esUltima);

@override
String toString() {
  return 'ResultadoDePregunta(orden: $orden, opcionCorrectaId: $opcionCorrectaId, explicacion: $explicacion, tuOpcionId: $tuOpcionId, acertaste: $acertaste, tuTiempoMs: $tuTiempoMs, tusAciertos: $tusAciertos, rivalRespondio: $rivalRespondio, rivalRespondidas: $rivalRespondidas, siguienteEnMs: $siguienteEnMs, esUltima: $esUltima)';
}


}

/// @nodoc
abstract mixin class _$ResultadoDePreguntaCopyWith<$Res> implements $ResultadoDePreguntaCopyWith<$Res> {
  factory _$ResultadoDePreguntaCopyWith(_ResultadoDePregunta value, $Res Function(_ResultadoDePregunta) _then) = __$ResultadoDePreguntaCopyWithImpl;
@override @useResult
$Res call({
 int orden, String opcionCorrectaId, String explicacion, String? tuOpcionId, bool acertaste, int tuTiempoMs, int tusAciertos, bool rivalRespondio, int rivalRespondidas, int siguienteEnMs, bool esUltima
});




}
/// @nodoc
class __$ResultadoDePreguntaCopyWithImpl<$Res>
    implements _$ResultadoDePreguntaCopyWith<$Res> {
  __$ResultadoDePreguntaCopyWithImpl(this._self, this._then);

  final _ResultadoDePregunta _self;
  final $Res Function(_ResultadoDePregunta) _then;

/// Create a copy of ResultadoDePregunta
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orden = null,Object? opcionCorrectaId = null,Object? explicacion = null,Object? tuOpcionId = freezed,Object? acertaste = null,Object? tuTiempoMs = null,Object? tusAciertos = null,Object? rivalRespondio = null,Object? rivalRespondidas = null,Object? siguienteEnMs = null,Object? esUltima = null,}) {
  return _then(_ResultadoDePregunta(
orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,opcionCorrectaId: null == opcionCorrectaId ? _self.opcionCorrectaId : opcionCorrectaId // ignore: cast_nullable_to_non_nullable
as String,explicacion: null == explicacion ? _self.explicacion : explicacion // ignore: cast_nullable_to_non_nullable
as String,tuOpcionId: freezed == tuOpcionId ? _self.tuOpcionId : tuOpcionId // ignore: cast_nullable_to_non_nullable
as String?,acertaste: null == acertaste ? _self.acertaste : acertaste // ignore: cast_nullable_to_non_nullable
as bool,tuTiempoMs: null == tuTiempoMs ? _self.tuTiempoMs : tuTiempoMs // ignore: cast_nullable_to_non_nullable
as int,tusAciertos: null == tusAciertos ? _self.tusAciertos : tusAciertos // ignore: cast_nullable_to_non_nullable
as int,rivalRespondio: null == rivalRespondio ? _self.rivalRespondio : rivalRespondio // ignore: cast_nullable_to_non_nullable
as bool,rivalRespondidas: null == rivalRespondidas ? _self.rivalRespondidas : rivalRespondidas // ignore: cast_nullable_to_non_nullable
as int,siguienteEnMs: null == siguienteEnMs ? _self.siguienteEnMs : siguienteEnMs // ignore: cast_nullable_to_non_nullable
as int,esUltima: null == esUltima ? _self.esUltima : esUltima // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$OpcionRevisada {

 String get id; String get texto; bool get esCorrecta;
/// Create a copy of OpcionRevisada
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OpcionRevisadaCopyWith<OpcionRevisada> get copyWith => _$OpcionRevisadaCopyWithImpl<OpcionRevisada>(this as OpcionRevisada, _$identity);

  /// Serializes this OpcionRevisada to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OpcionRevisada&&(identical(other.id, id) || other.id == id)&&(identical(other.texto, texto) || other.texto == texto)&&(identical(other.esCorrecta, esCorrecta) || other.esCorrecta == esCorrecta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,texto,esCorrecta);

@override
String toString() {
  return 'OpcionRevisada(id: $id, texto: $texto, esCorrecta: $esCorrecta)';
}


}

/// @nodoc
abstract mixin class $OpcionRevisadaCopyWith<$Res>  {
  factory $OpcionRevisadaCopyWith(OpcionRevisada value, $Res Function(OpcionRevisada) _then) = _$OpcionRevisadaCopyWithImpl;
@useResult
$Res call({
 String id, String texto, bool esCorrecta
});




}
/// @nodoc
class _$OpcionRevisadaCopyWithImpl<$Res>
    implements $OpcionRevisadaCopyWith<$Res> {
  _$OpcionRevisadaCopyWithImpl(this._self, this._then);

  final OpcionRevisada _self;
  final $Res Function(OpcionRevisada) _then;

/// Create a copy of OpcionRevisada
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? texto = null,Object? esCorrecta = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,esCorrecta: null == esCorrecta ? _self.esCorrecta : esCorrecta // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [OpcionRevisada].
extension OpcionRevisadaPatterns on OpcionRevisada {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OpcionRevisada value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OpcionRevisada() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OpcionRevisada value)  $default,){
final _that = this;
switch (_that) {
case _OpcionRevisada():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OpcionRevisada value)?  $default,){
final _that = this;
switch (_that) {
case _OpcionRevisada() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String texto,  bool esCorrecta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OpcionRevisada() when $default != null:
return $default(_that.id,_that.texto,_that.esCorrecta);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String texto,  bool esCorrecta)  $default,) {final _that = this;
switch (_that) {
case _OpcionRevisada():
return $default(_that.id,_that.texto,_that.esCorrecta);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String texto,  bool esCorrecta)?  $default,) {final _that = this;
switch (_that) {
case _OpcionRevisada() when $default != null:
return $default(_that.id,_that.texto,_that.esCorrecta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OpcionRevisada implements OpcionRevisada {
  const _OpcionRevisada({required this.id, required this.texto, this.esCorrecta = false});
  factory _OpcionRevisada.fromJson(Map<String, dynamic> json) => _$OpcionRevisadaFromJson(json);

@override final  String id;
@override final  String texto;
@override@JsonKey() final  bool esCorrecta;

/// Create a copy of OpcionRevisada
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OpcionRevisadaCopyWith<_OpcionRevisada> get copyWith => __$OpcionRevisadaCopyWithImpl<_OpcionRevisada>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OpcionRevisadaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OpcionRevisada&&(identical(other.id, id) || other.id == id)&&(identical(other.texto, texto) || other.texto == texto)&&(identical(other.esCorrecta, esCorrecta) || other.esCorrecta == esCorrecta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,texto,esCorrecta);

@override
String toString() {
  return 'OpcionRevisada(id: $id, texto: $texto, esCorrecta: $esCorrecta)';
}


}

/// @nodoc
abstract mixin class _$OpcionRevisadaCopyWith<$Res> implements $OpcionRevisadaCopyWith<$Res> {
  factory _$OpcionRevisadaCopyWith(_OpcionRevisada value, $Res Function(_OpcionRevisada) _then) = __$OpcionRevisadaCopyWithImpl;
@override @useResult
$Res call({
 String id, String texto, bool esCorrecta
});




}
/// @nodoc
class __$OpcionRevisadaCopyWithImpl<$Res>
    implements _$OpcionRevisadaCopyWith<$Res> {
  __$OpcionRevisadaCopyWithImpl(this._self, this._then);

  final _OpcionRevisada _self;
  final $Res Function(_OpcionRevisada) _then;

/// Create a copy of OpcionRevisada
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? texto = null,Object? esCorrecta = null,}) {
  return _then(_OpcionRevisada(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,esCorrecta: null == esCorrecta ? _self.esCorrecta : esCorrecta // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PreguntaRevisada {

 int get orden; String get enunciado; List<OpcionRevisada> get opciones; String get explicacion; String? get tuOpcionId; bool get acertaste; String? get rivalOpcionId; bool get rivalAcerto; EstadoDeRespuesta get tuEstado; EstadoDeRespuesta get rivalEstado;
/// Create a copy of PreguntaRevisada
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PreguntaRevisadaCopyWith<PreguntaRevisada> get copyWith => _$PreguntaRevisadaCopyWithImpl<PreguntaRevisada>(this as PreguntaRevisada, _$identity);

  /// Serializes this PreguntaRevisada to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PreguntaRevisada&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.enunciado, enunciado) || other.enunciado == enunciado)&&const DeepCollectionEquality().equals(other.opciones, opciones)&&(identical(other.explicacion, explicacion) || other.explicacion == explicacion)&&(identical(other.tuOpcionId, tuOpcionId) || other.tuOpcionId == tuOpcionId)&&(identical(other.acertaste, acertaste) || other.acertaste == acertaste)&&(identical(other.rivalOpcionId, rivalOpcionId) || other.rivalOpcionId == rivalOpcionId)&&(identical(other.rivalAcerto, rivalAcerto) || other.rivalAcerto == rivalAcerto)&&(identical(other.tuEstado, tuEstado) || other.tuEstado == tuEstado)&&(identical(other.rivalEstado, rivalEstado) || other.rivalEstado == rivalEstado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orden,enunciado,const DeepCollectionEquality().hash(opciones),explicacion,tuOpcionId,acertaste,rivalOpcionId,rivalAcerto,tuEstado,rivalEstado);

@override
String toString() {
  return 'PreguntaRevisada(orden: $orden, enunciado: $enunciado, opciones: $opciones, explicacion: $explicacion, tuOpcionId: $tuOpcionId, acertaste: $acertaste, rivalOpcionId: $rivalOpcionId, rivalAcerto: $rivalAcerto, tuEstado: $tuEstado, rivalEstado: $rivalEstado)';
}


}

/// @nodoc
abstract mixin class $PreguntaRevisadaCopyWith<$Res>  {
  factory $PreguntaRevisadaCopyWith(PreguntaRevisada value, $Res Function(PreguntaRevisada) _then) = _$PreguntaRevisadaCopyWithImpl;
@useResult
$Res call({
 int orden, String enunciado, List<OpcionRevisada> opciones, String explicacion, String? tuOpcionId, bool acertaste, String? rivalOpcionId, bool rivalAcerto, EstadoDeRespuesta tuEstado, EstadoDeRespuesta rivalEstado
});




}
/// @nodoc
class _$PreguntaRevisadaCopyWithImpl<$Res>
    implements $PreguntaRevisadaCopyWith<$Res> {
  _$PreguntaRevisadaCopyWithImpl(this._self, this._then);

  final PreguntaRevisada _self;
  final $Res Function(PreguntaRevisada) _then;

/// Create a copy of PreguntaRevisada
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? orden = null,Object? enunciado = null,Object? opciones = null,Object? explicacion = null,Object? tuOpcionId = freezed,Object? acertaste = null,Object? rivalOpcionId = freezed,Object? rivalAcerto = null,Object? tuEstado = null,Object? rivalEstado = null,}) {
  return _then(_self.copyWith(
orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,enunciado: null == enunciado ? _self.enunciado : enunciado // ignore: cast_nullable_to_non_nullable
as String,opciones: null == opciones ? _self.opciones : opciones // ignore: cast_nullable_to_non_nullable
as List<OpcionRevisada>,explicacion: null == explicacion ? _self.explicacion : explicacion // ignore: cast_nullable_to_non_nullable
as String,tuOpcionId: freezed == tuOpcionId ? _self.tuOpcionId : tuOpcionId // ignore: cast_nullable_to_non_nullable
as String?,acertaste: null == acertaste ? _self.acertaste : acertaste // ignore: cast_nullable_to_non_nullable
as bool,rivalOpcionId: freezed == rivalOpcionId ? _self.rivalOpcionId : rivalOpcionId // ignore: cast_nullable_to_non_nullable
as String?,rivalAcerto: null == rivalAcerto ? _self.rivalAcerto : rivalAcerto // ignore: cast_nullable_to_non_nullable
as bool,tuEstado: null == tuEstado ? _self.tuEstado : tuEstado // ignore: cast_nullable_to_non_nullable
as EstadoDeRespuesta,rivalEstado: null == rivalEstado ? _self.rivalEstado : rivalEstado // ignore: cast_nullable_to_non_nullable
as EstadoDeRespuesta,
  ));
}

}


/// Adds pattern-matching-related methods to [PreguntaRevisada].
extension PreguntaRevisadaPatterns on PreguntaRevisada {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PreguntaRevisada value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PreguntaRevisada() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PreguntaRevisada value)  $default,){
final _that = this;
switch (_that) {
case _PreguntaRevisada():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PreguntaRevisada value)?  $default,){
final _that = this;
switch (_that) {
case _PreguntaRevisada() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int orden,  String enunciado,  List<OpcionRevisada> opciones,  String explicacion,  String? tuOpcionId,  bool acertaste,  String? rivalOpcionId,  bool rivalAcerto,  EstadoDeRespuesta tuEstado,  EstadoDeRespuesta rivalEstado)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PreguntaRevisada() when $default != null:
return $default(_that.orden,_that.enunciado,_that.opciones,_that.explicacion,_that.tuOpcionId,_that.acertaste,_that.rivalOpcionId,_that.rivalAcerto,_that.tuEstado,_that.rivalEstado);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int orden,  String enunciado,  List<OpcionRevisada> opciones,  String explicacion,  String? tuOpcionId,  bool acertaste,  String? rivalOpcionId,  bool rivalAcerto,  EstadoDeRespuesta tuEstado,  EstadoDeRespuesta rivalEstado)  $default,) {final _that = this;
switch (_that) {
case _PreguntaRevisada():
return $default(_that.orden,_that.enunciado,_that.opciones,_that.explicacion,_that.tuOpcionId,_that.acertaste,_that.rivalOpcionId,_that.rivalAcerto,_that.tuEstado,_that.rivalEstado);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int orden,  String enunciado,  List<OpcionRevisada> opciones,  String explicacion,  String? tuOpcionId,  bool acertaste,  String? rivalOpcionId,  bool rivalAcerto,  EstadoDeRespuesta tuEstado,  EstadoDeRespuesta rivalEstado)?  $default,) {final _that = this;
switch (_that) {
case _PreguntaRevisada() when $default != null:
return $default(_that.orden,_that.enunciado,_that.opciones,_that.explicacion,_that.tuOpcionId,_that.acertaste,_that.rivalOpcionId,_that.rivalAcerto,_that.tuEstado,_that.rivalEstado);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PreguntaRevisada implements PreguntaRevisada {
  const _PreguntaRevisada({required this.orden, this.enunciado = '', final  List<OpcionRevisada> opciones = const <OpcionRevisada>[], this.explicacion = '', this.tuOpcionId, this.acertaste = false, this.rivalOpcionId, this.rivalAcerto = false, this.tuEstado = EstadoDeRespuesta.enBlanco, this.rivalEstado = EstadoDeRespuesta.enBlanco}): _opciones = opciones;
  factory _PreguntaRevisada.fromJson(Map<String, dynamic> json) => _$PreguntaRevisadaFromJson(json);

@override final  int orden;
@override@JsonKey() final  String enunciado;
 final  List<OpcionRevisada> _opciones;
@override@JsonKey() List<OpcionRevisada> get opciones {
  if (_opciones is EqualUnmodifiableListView) return _opciones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_opciones);
}

@override@JsonKey() final  String explicacion;
@override final  String? tuOpcionId;
@override@JsonKey() final  bool acertaste;
@override final  String? rivalOpcionId;
@override@JsonKey() final  bool rivalAcerto;
@override@JsonKey() final  EstadoDeRespuesta tuEstado;
@override@JsonKey() final  EstadoDeRespuesta rivalEstado;

/// Create a copy of PreguntaRevisada
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PreguntaRevisadaCopyWith<_PreguntaRevisada> get copyWith => __$PreguntaRevisadaCopyWithImpl<_PreguntaRevisada>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PreguntaRevisadaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PreguntaRevisada&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.enunciado, enunciado) || other.enunciado == enunciado)&&const DeepCollectionEquality().equals(other._opciones, _opciones)&&(identical(other.explicacion, explicacion) || other.explicacion == explicacion)&&(identical(other.tuOpcionId, tuOpcionId) || other.tuOpcionId == tuOpcionId)&&(identical(other.acertaste, acertaste) || other.acertaste == acertaste)&&(identical(other.rivalOpcionId, rivalOpcionId) || other.rivalOpcionId == rivalOpcionId)&&(identical(other.rivalAcerto, rivalAcerto) || other.rivalAcerto == rivalAcerto)&&(identical(other.tuEstado, tuEstado) || other.tuEstado == tuEstado)&&(identical(other.rivalEstado, rivalEstado) || other.rivalEstado == rivalEstado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,orden,enunciado,const DeepCollectionEquality().hash(_opciones),explicacion,tuOpcionId,acertaste,rivalOpcionId,rivalAcerto,tuEstado,rivalEstado);

@override
String toString() {
  return 'PreguntaRevisada(orden: $orden, enunciado: $enunciado, opciones: $opciones, explicacion: $explicacion, tuOpcionId: $tuOpcionId, acertaste: $acertaste, rivalOpcionId: $rivalOpcionId, rivalAcerto: $rivalAcerto, tuEstado: $tuEstado, rivalEstado: $rivalEstado)';
}


}

/// @nodoc
abstract mixin class _$PreguntaRevisadaCopyWith<$Res> implements $PreguntaRevisadaCopyWith<$Res> {
  factory _$PreguntaRevisadaCopyWith(_PreguntaRevisada value, $Res Function(_PreguntaRevisada) _then) = __$PreguntaRevisadaCopyWithImpl;
@override @useResult
$Res call({
 int orden, String enunciado, List<OpcionRevisada> opciones, String explicacion, String? tuOpcionId, bool acertaste, String? rivalOpcionId, bool rivalAcerto, EstadoDeRespuesta tuEstado, EstadoDeRespuesta rivalEstado
});




}
/// @nodoc
class __$PreguntaRevisadaCopyWithImpl<$Res>
    implements _$PreguntaRevisadaCopyWith<$Res> {
  __$PreguntaRevisadaCopyWithImpl(this._self, this._then);

  final _PreguntaRevisada _self;
  final $Res Function(_PreguntaRevisada) _then;

/// Create a copy of PreguntaRevisada
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? orden = null,Object? enunciado = null,Object? opciones = null,Object? explicacion = null,Object? tuOpcionId = freezed,Object? acertaste = null,Object? rivalOpcionId = freezed,Object? rivalAcerto = null,Object? tuEstado = null,Object? rivalEstado = null,}) {
  return _then(_PreguntaRevisada(
orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,enunciado: null == enunciado ? _self.enunciado : enunciado // ignore: cast_nullable_to_non_nullable
as String,opciones: null == opciones ? _self._opciones : opciones // ignore: cast_nullable_to_non_nullable
as List<OpcionRevisada>,explicacion: null == explicacion ? _self.explicacion : explicacion // ignore: cast_nullable_to_non_nullable
as String,tuOpcionId: freezed == tuOpcionId ? _self.tuOpcionId : tuOpcionId // ignore: cast_nullable_to_non_nullable
as String?,acertaste: null == acertaste ? _self.acertaste : acertaste // ignore: cast_nullable_to_non_nullable
as bool,rivalOpcionId: freezed == rivalOpcionId ? _self.rivalOpcionId : rivalOpcionId // ignore: cast_nullable_to_non_nullable
as String?,rivalAcerto: null == rivalAcerto ? _self.rivalAcerto : rivalAcerto // ignore: cast_nullable_to_non_nullable
as bool,tuEstado: null == tuEstado ? _self.tuEstado : tuEstado // ignore: cast_nullable_to_non_nullable
as EstadoDeRespuesta,rivalEstado: null == rivalEstado ? _self.rivalEstado : rivalEstado // ignore: cast_nullable_to_non_nullable
as EstadoDeRespuesta,
  ));
}


}


/// @nodoc
mixin _$FinalDeDuelo {

 Desenlace get desenlace; int get tusAciertos; int get rivalAciertos; double get tuNota; double get rivalNota; int get tuTiempoTotalMs; int get rivalTiempoTotalMs;/// El rival se fue y por eso ganaste. Cambia el texto: «ganaste» a secas
/// cuando el otro abandonó se lee como una burla.
 bool get porAbandono;/// Se desempató por tiempo. Merece decirse: es la parte que sorprende.
 bool get porTiempo;/// Se jugó con el duelo diario gratuito (RF-65).
///
/// Viene explícito y no se deduce de que `revision` llegue vacía: deducirlo
/// funcionaría hoy y mentiría el día que la revisión falte por otro motivo.
 bool get conPaseGratis; List<PreguntaRevisada> get revision;
/// Create a copy of FinalDeDuelo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FinalDeDueloCopyWith<FinalDeDuelo> get copyWith => _$FinalDeDueloCopyWithImpl<FinalDeDuelo>(this as FinalDeDuelo, _$identity);

  /// Serializes this FinalDeDuelo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FinalDeDuelo&&(identical(other.desenlace, desenlace) || other.desenlace == desenlace)&&(identical(other.tusAciertos, tusAciertos) || other.tusAciertos == tusAciertos)&&(identical(other.rivalAciertos, rivalAciertos) || other.rivalAciertos == rivalAciertos)&&(identical(other.tuNota, tuNota) || other.tuNota == tuNota)&&(identical(other.rivalNota, rivalNota) || other.rivalNota == rivalNota)&&(identical(other.tuTiempoTotalMs, tuTiempoTotalMs) || other.tuTiempoTotalMs == tuTiempoTotalMs)&&(identical(other.rivalTiempoTotalMs, rivalTiempoTotalMs) || other.rivalTiempoTotalMs == rivalTiempoTotalMs)&&(identical(other.porAbandono, porAbandono) || other.porAbandono == porAbandono)&&(identical(other.porTiempo, porTiempo) || other.porTiempo == porTiempo)&&(identical(other.conPaseGratis, conPaseGratis) || other.conPaseGratis == conPaseGratis)&&const DeepCollectionEquality().equals(other.revision, revision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,desenlace,tusAciertos,rivalAciertos,tuNota,rivalNota,tuTiempoTotalMs,rivalTiempoTotalMs,porAbandono,porTiempo,conPaseGratis,const DeepCollectionEquality().hash(revision));

@override
String toString() {
  return 'FinalDeDuelo(desenlace: $desenlace, tusAciertos: $tusAciertos, rivalAciertos: $rivalAciertos, tuNota: $tuNota, rivalNota: $rivalNota, tuTiempoTotalMs: $tuTiempoTotalMs, rivalTiempoTotalMs: $rivalTiempoTotalMs, porAbandono: $porAbandono, porTiempo: $porTiempo, conPaseGratis: $conPaseGratis, revision: $revision)';
}


}

/// @nodoc
abstract mixin class $FinalDeDueloCopyWith<$Res>  {
  factory $FinalDeDueloCopyWith(FinalDeDuelo value, $Res Function(FinalDeDuelo) _then) = _$FinalDeDueloCopyWithImpl;
@useResult
$Res call({
 Desenlace desenlace, int tusAciertos, int rivalAciertos, double tuNota, double rivalNota, int tuTiempoTotalMs, int rivalTiempoTotalMs, bool porAbandono, bool porTiempo, bool conPaseGratis, List<PreguntaRevisada> revision
});




}
/// @nodoc
class _$FinalDeDueloCopyWithImpl<$Res>
    implements $FinalDeDueloCopyWith<$Res> {
  _$FinalDeDueloCopyWithImpl(this._self, this._then);

  final FinalDeDuelo _self;
  final $Res Function(FinalDeDuelo) _then;

/// Create a copy of FinalDeDuelo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? desenlace = null,Object? tusAciertos = null,Object? rivalAciertos = null,Object? tuNota = null,Object? rivalNota = null,Object? tuTiempoTotalMs = null,Object? rivalTiempoTotalMs = null,Object? porAbandono = null,Object? porTiempo = null,Object? conPaseGratis = null,Object? revision = null,}) {
  return _then(_self.copyWith(
desenlace: null == desenlace ? _self.desenlace : desenlace // ignore: cast_nullable_to_non_nullable
as Desenlace,tusAciertos: null == tusAciertos ? _self.tusAciertos : tusAciertos // ignore: cast_nullable_to_non_nullable
as int,rivalAciertos: null == rivalAciertos ? _self.rivalAciertos : rivalAciertos // ignore: cast_nullable_to_non_nullable
as int,tuNota: null == tuNota ? _self.tuNota : tuNota // ignore: cast_nullable_to_non_nullable
as double,rivalNota: null == rivalNota ? _self.rivalNota : rivalNota // ignore: cast_nullable_to_non_nullable
as double,tuTiempoTotalMs: null == tuTiempoTotalMs ? _self.tuTiempoTotalMs : tuTiempoTotalMs // ignore: cast_nullable_to_non_nullable
as int,rivalTiempoTotalMs: null == rivalTiempoTotalMs ? _self.rivalTiempoTotalMs : rivalTiempoTotalMs // ignore: cast_nullable_to_non_nullable
as int,porAbandono: null == porAbandono ? _self.porAbandono : porAbandono // ignore: cast_nullable_to_non_nullable
as bool,porTiempo: null == porTiempo ? _self.porTiempo : porTiempo // ignore: cast_nullable_to_non_nullable
as bool,conPaseGratis: null == conPaseGratis ? _self.conPaseGratis : conPaseGratis // ignore: cast_nullable_to_non_nullable
as bool,revision: null == revision ? _self.revision : revision // ignore: cast_nullable_to_non_nullable
as List<PreguntaRevisada>,
  ));
}

}


/// Adds pattern-matching-related methods to [FinalDeDuelo].
extension FinalDeDueloPatterns on FinalDeDuelo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FinalDeDuelo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FinalDeDuelo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FinalDeDuelo value)  $default,){
final _that = this;
switch (_that) {
case _FinalDeDuelo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FinalDeDuelo value)?  $default,){
final _that = this;
switch (_that) {
case _FinalDeDuelo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Desenlace desenlace,  int tusAciertos,  int rivalAciertos,  double tuNota,  double rivalNota,  int tuTiempoTotalMs,  int rivalTiempoTotalMs,  bool porAbandono,  bool porTiempo,  bool conPaseGratis,  List<PreguntaRevisada> revision)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FinalDeDuelo() when $default != null:
return $default(_that.desenlace,_that.tusAciertos,_that.rivalAciertos,_that.tuNota,_that.rivalNota,_that.tuTiempoTotalMs,_that.rivalTiempoTotalMs,_that.porAbandono,_that.porTiempo,_that.conPaseGratis,_that.revision);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Desenlace desenlace,  int tusAciertos,  int rivalAciertos,  double tuNota,  double rivalNota,  int tuTiempoTotalMs,  int rivalTiempoTotalMs,  bool porAbandono,  bool porTiempo,  bool conPaseGratis,  List<PreguntaRevisada> revision)  $default,) {final _that = this;
switch (_that) {
case _FinalDeDuelo():
return $default(_that.desenlace,_that.tusAciertos,_that.rivalAciertos,_that.tuNota,_that.rivalNota,_that.tuTiempoTotalMs,_that.rivalTiempoTotalMs,_that.porAbandono,_that.porTiempo,_that.conPaseGratis,_that.revision);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Desenlace desenlace,  int tusAciertos,  int rivalAciertos,  double tuNota,  double rivalNota,  int tuTiempoTotalMs,  int rivalTiempoTotalMs,  bool porAbandono,  bool porTiempo,  bool conPaseGratis,  List<PreguntaRevisada> revision)?  $default,) {final _that = this;
switch (_that) {
case _FinalDeDuelo() when $default != null:
return $default(_that.desenlace,_that.tusAciertos,_that.rivalAciertos,_that.tuNota,_that.rivalNota,_that.tuTiempoTotalMs,_that.rivalTiempoTotalMs,_that.porAbandono,_that.porTiempo,_that.conPaseGratis,_that.revision);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FinalDeDuelo implements FinalDeDuelo {
  const _FinalDeDuelo({this.desenlace = Desenlace.empate, this.tusAciertos = 0, this.rivalAciertos = 0, this.tuNota = 0, this.rivalNota = 0, this.tuTiempoTotalMs = 0, this.rivalTiempoTotalMs = 0, this.porAbandono = false, this.porTiempo = false, this.conPaseGratis = false, final  List<PreguntaRevisada> revision = const <PreguntaRevisada>[]}): _revision = revision;
  factory _FinalDeDuelo.fromJson(Map<String, dynamic> json) => _$FinalDeDueloFromJson(json);

@override@JsonKey() final  Desenlace desenlace;
@override@JsonKey() final  int tusAciertos;
@override@JsonKey() final  int rivalAciertos;
@override@JsonKey() final  double tuNota;
@override@JsonKey() final  double rivalNota;
@override@JsonKey() final  int tuTiempoTotalMs;
@override@JsonKey() final  int rivalTiempoTotalMs;
/// El rival se fue y por eso ganaste. Cambia el texto: «ganaste» a secas
/// cuando el otro abandonó se lee como una burla.
@override@JsonKey() final  bool porAbandono;
/// Se desempató por tiempo. Merece decirse: es la parte que sorprende.
@override@JsonKey() final  bool porTiempo;
/// Se jugó con el duelo diario gratuito (RF-65).
///
/// Viene explícito y no se deduce de que `revision` llegue vacía: deducirlo
/// funcionaría hoy y mentiría el día que la revisión falte por otro motivo.
@override@JsonKey() final  bool conPaseGratis;
 final  List<PreguntaRevisada> _revision;
@override@JsonKey() List<PreguntaRevisada> get revision {
  if (_revision is EqualUnmodifiableListView) return _revision;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_revision);
}


/// Create a copy of FinalDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FinalDeDueloCopyWith<_FinalDeDuelo> get copyWith => __$FinalDeDueloCopyWithImpl<_FinalDeDuelo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FinalDeDueloToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FinalDeDuelo&&(identical(other.desenlace, desenlace) || other.desenlace == desenlace)&&(identical(other.tusAciertos, tusAciertos) || other.tusAciertos == tusAciertos)&&(identical(other.rivalAciertos, rivalAciertos) || other.rivalAciertos == rivalAciertos)&&(identical(other.tuNota, tuNota) || other.tuNota == tuNota)&&(identical(other.rivalNota, rivalNota) || other.rivalNota == rivalNota)&&(identical(other.tuTiempoTotalMs, tuTiempoTotalMs) || other.tuTiempoTotalMs == tuTiempoTotalMs)&&(identical(other.rivalTiempoTotalMs, rivalTiempoTotalMs) || other.rivalTiempoTotalMs == rivalTiempoTotalMs)&&(identical(other.porAbandono, porAbandono) || other.porAbandono == porAbandono)&&(identical(other.porTiempo, porTiempo) || other.porTiempo == porTiempo)&&(identical(other.conPaseGratis, conPaseGratis) || other.conPaseGratis == conPaseGratis)&&const DeepCollectionEquality().equals(other._revision, _revision));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,desenlace,tusAciertos,rivalAciertos,tuNota,rivalNota,tuTiempoTotalMs,rivalTiempoTotalMs,porAbandono,porTiempo,conPaseGratis,const DeepCollectionEquality().hash(_revision));

@override
String toString() {
  return 'FinalDeDuelo(desenlace: $desenlace, tusAciertos: $tusAciertos, rivalAciertos: $rivalAciertos, tuNota: $tuNota, rivalNota: $rivalNota, tuTiempoTotalMs: $tuTiempoTotalMs, rivalTiempoTotalMs: $rivalTiempoTotalMs, porAbandono: $porAbandono, porTiempo: $porTiempo, conPaseGratis: $conPaseGratis, revision: $revision)';
}


}

/// @nodoc
abstract mixin class _$FinalDeDueloCopyWith<$Res> implements $FinalDeDueloCopyWith<$Res> {
  factory _$FinalDeDueloCopyWith(_FinalDeDuelo value, $Res Function(_FinalDeDuelo) _then) = __$FinalDeDueloCopyWithImpl;
@override @useResult
$Res call({
 Desenlace desenlace, int tusAciertos, int rivalAciertos, double tuNota, double rivalNota, int tuTiempoTotalMs, int rivalTiempoTotalMs, bool porAbandono, bool porTiempo, bool conPaseGratis, List<PreguntaRevisada> revision
});




}
/// @nodoc
class __$FinalDeDueloCopyWithImpl<$Res>
    implements _$FinalDeDueloCopyWith<$Res> {
  __$FinalDeDueloCopyWithImpl(this._self, this._then);

  final _FinalDeDuelo _self;
  final $Res Function(_FinalDeDuelo) _then;

/// Create a copy of FinalDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? desenlace = null,Object? tusAciertos = null,Object? rivalAciertos = null,Object? tuNota = null,Object? rivalNota = null,Object? tuTiempoTotalMs = null,Object? rivalTiempoTotalMs = null,Object? porAbandono = null,Object? porTiempo = null,Object? conPaseGratis = null,Object? revision = null,}) {
  return _then(_FinalDeDuelo(
desenlace: null == desenlace ? _self.desenlace : desenlace // ignore: cast_nullable_to_non_nullable
as Desenlace,tusAciertos: null == tusAciertos ? _self.tusAciertos : tusAciertos // ignore: cast_nullable_to_non_nullable
as int,rivalAciertos: null == rivalAciertos ? _self.rivalAciertos : rivalAciertos // ignore: cast_nullable_to_non_nullable
as int,tuNota: null == tuNota ? _self.tuNota : tuNota // ignore: cast_nullable_to_non_nullable
as double,rivalNota: null == rivalNota ? _self.rivalNota : rivalNota // ignore: cast_nullable_to_non_nullable
as double,tuTiempoTotalMs: null == tuTiempoTotalMs ? _self.tuTiempoTotalMs : tuTiempoTotalMs // ignore: cast_nullable_to_non_nullable
as int,rivalTiempoTotalMs: null == rivalTiempoTotalMs ? _self.rivalTiempoTotalMs : rivalTiempoTotalMs // ignore: cast_nullable_to_non_nullable
as int,porAbandono: null == porAbandono ? _self.porAbandono : porAbandono // ignore: cast_nullable_to_non_nullable
as bool,porTiempo: null == porTiempo ? _self.porTiempo : porTiempo // ignore: cast_nullable_to_non_nullable
as bool,conPaseGratis: null == conPaseGratis ? _self.conPaseGratis : conPaseGratis // ignore: cast_nullable_to_non_nullable
as bool,revision: null == revision ? _self._revision : revision // ignore: cast_nullable_to_non_nullable
as List<PreguntaRevisada>,
  ));
}


}


/// @nodoc
mixin _$EsperaDeDuelo {

 int get esperandoSegundos; int get faltanSegundos; String? get codigo; DateTime? get expiraEn;
/// Create a copy of EsperaDeDuelo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EsperaDeDueloCopyWith<EsperaDeDuelo> get copyWith => _$EsperaDeDueloCopyWithImpl<EsperaDeDuelo>(this as EsperaDeDuelo, _$identity);

  /// Serializes this EsperaDeDuelo to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EsperaDeDuelo&&(identical(other.esperandoSegundos, esperandoSegundos) || other.esperandoSegundos == esperandoSegundos)&&(identical(other.faltanSegundos, faltanSegundos) || other.faltanSegundos == faltanSegundos)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.expiraEn, expiraEn) || other.expiraEn == expiraEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,esperandoSegundos,faltanSegundos,codigo,expiraEn);

@override
String toString() {
  return 'EsperaDeDuelo(esperandoSegundos: $esperandoSegundos, faltanSegundos: $faltanSegundos, codigo: $codigo, expiraEn: $expiraEn)';
}


}

/// @nodoc
abstract mixin class $EsperaDeDueloCopyWith<$Res>  {
  factory $EsperaDeDueloCopyWith(EsperaDeDuelo value, $Res Function(EsperaDeDuelo) _then) = _$EsperaDeDueloCopyWithImpl;
@useResult
$Res call({
 int esperandoSegundos, int faltanSegundos, String? codigo, DateTime? expiraEn
});




}
/// @nodoc
class _$EsperaDeDueloCopyWithImpl<$Res>
    implements $EsperaDeDueloCopyWith<$Res> {
  _$EsperaDeDueloCopyWithImpl(this._self, this._then);

  final EsperaDeDuelo _self;
  final $Res Function(EsperaDeDuelo) _then;

/// Create a copy of EsperaDeDuelo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? esperandoSegundos = null,Object? faltanSegundos = null,Object? codigo = freezed,Object? expiraEn = freezed,}) {
  return _then(_self.copyWith(
esperandoSegundos: null == esperandoSegundos ? _self.esperandoSegundos : esperandoSegundos // ignore: cast_nullable_to_non_nullable
as int,faltanSegundos: null == faltanSegundos ? _self.faltanSegundos : faltanSegundos // ignore: cast_nullable_to_non_nullable
as int,codigo: freezed == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String?,expiraEn: freezed == expiraEn ? _self.expiraEn : expiraEn // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [EsperaDeDuelo].
extension EsperaDeDueloPatterns on EsperaDeDuelo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EsperaDeDuelo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EsperaDeDuelo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EsperaDeDuelo value)  $default,){
final _that = this;
switch (_that) {
case _EsperaDeDuelo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EsperaDeDuelo value)?  $default,){
final _that = this;
switch (_that) {
case _EsperaDeDuelo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int esperandoSegundos,  int faltanSegundos,  String? codigo,  DateTime? expiraEn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EsperaDeDuelo() when $default != null:
return $default(_that.esperandoSegundos,_that.faltanSegundos,_that.codigo,_that.expiraEn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int esperandoSegundos,  int faltanSegundos,  String? codigo,  DateTime? expiraEn)  $default,) {final _that = this;
switch (_that) {
case _EsperaDeDuelo():
return $default(_that.esperandoSegundos,_that.faltanSegundos,_that.codigo,_that.expiraEn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int esperandoSegundos,  int faltanSegundos,  String? codigo,  DateTime? expiraEn)?  $default,) {final _that = this;
switch (_that) {
case _EsperaDeDuelo() when $default != null:
return $default(_that.esperandoSegundos,_that.faltanSegundos,_that.codigo,_that.expiraEn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EsperaDeDuelo implements EsperaDeDuelo {
  const _EsperaDeDuelo({this.esperandoSegundos = 0, this.faltanSegundos = 0, this.codigo, this.expiraEn});
  factory _EsperaDeDuelo.fromJson(Map<String, dynamic> json) => _$EsperaDeDueloFromJson(json);

@override@JsonKey() final  int esperandoSegundos;
@override@JsonKey() final  int faltanSegundos;
@override final  String? codigo;
@override final  DateTime? expiraEn;

/// Create a copy of EsperaDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EsperaDeDueloCopyWith<_EsperaDeDuelo> get copyWith => __$EsperaDeDueloCopyWithImpl<_EsperaDeDuelo>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EsperaDeDueloToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _EsperaDeDuelo&&(identical(other.esperandoSegundos, esperandoSegundos) || other.esperandoSegundos == esperandoSegundos)&&(identical(other.faltanSegundos, faltanSegundos) || other.faltanSegundos == faltanSegundos)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.expiraEn, expiraEn) || other.expiraEn == expiraEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,esperandoSegundos,faltanSegundos,codigo,expiraEn);

@override
String toString() {
  return 'EsperaDeDuelo(esperandoSegundos: $esperandoSegundos, faltanSegundos: $faltanSegundos, codigo: $codigo, expiraEn: $expiraEn)';
}


}

/// @nodoc
abstract mixin class _$EsperaDeDueloCopyWith<$Res> implements $EsperaDeDueloCopyWith<$Res> {
  factory _$EsperaDeDueloCopyWith(_EsperaDeDuelo value, $Res Function(_EsperaDeDuelo) _then) = __$EsperaDeDueloCopyWithImpl;
@override @useResult
$Res call({
 int esperandoSegundos, int faltanSegundos, String? codigo, DateTime? expiraEn
});




}
/// @nodoc
class __$EsperaDeDueloCopyWithImpl<$Res>
    implements _$EsperaDeDueloCopyWith<$Res> {
  __$EsperaDeDueloCopyWithImpl(this._self, this._then);

  final _EsperaDeDuelo _self;
  final $Res Function(_EsperaDeDuelo) _then;

/// Create a copy of EsperaDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? esperandoSegundos = null,Object? faltanSegundos = null,Object? codigo = freezed,Object? expiraEn = freezed,}) {
  return _then(_EsperaDeDuelo(
esperandoSegundos: null == esperandoSegundos ? _self.esperandoSegundos : esperandoSegundos // ignore: cast_nullable_to_non_nullable
as int,faltanSegundos: null == faltanSegundos ? _self.faltanSegundos : faltanSegundos // ignore: cast_nullable_to_non_nullable
as int,codigo: freezed == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String?,expiraEn: freezed == expiraEn ? _self.expiraEn : expiraEn // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$MensajeDeDuelo {

 TipoMensajeDuelo get tipo; EstadoDeLaPartida? get duelo; PreguntaEnJuego? get pregunta; ResultadoDePregunta? get resultado; FinalDeDuelo? get final$; EsperaDeDuelo? get espera;/// En `te_mudaron`: a qué duelo hay que ir.
 String? get dueloId; String? get codigo; String? get mensaje;
/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MensajeDeDueloCopyWith<MensajeDeDuelo> get copyWith => _$MensajeDeDueloCopyWithImpl<MensajeDeDuelo>(this as MensajeDeDuelo, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MensajeDeDuelo&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.duelo, duelo) || other.duelo == duelo)&&(identical(other.pregunta, pregunta) || other.pregunta == pregunta)&&(identical(other.resultado, resultado) || other.resultado == resultado)&&(identical(other.final$, final$) || other.final$ == final$)&&(identical(other.espera, espera) || other.espera == espera)&&(identical(other.dueloId, dueloId) || other.dueloId == dueloId)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.mensaje, mensaje) || other.mensaje == mensaje));
}


@override
int get hashCode => Object.hash(runtimeType,tipo,duelo,pregunta,resultado,final$,espera,dueloId,codigo,mensaje);

@override
String toString() {
  return 'MensajeDeDuelo(tipo: $tipo, duelo: $duelo, pregunta: $pregunta, resultado: $resultado, final\$: ${final$}, espera: $espera, dueloId: $dueloId, codigo: $codigo, mensaje: $mensaje)';
}


}

/// @nodoc
abstract mixin class $MensajeDeDueloCopyWith<$Res>  {
  factory $MensajeDeDueloCopyWith(MensajeDeDuelo value, $Res Function(MensajeDeDuelo) _then) = _$MensajeDeDueloCopyWithImpl;
@useResult
$Res call({
 TipoMensajeDuelo tipo, EstadoDeLaPartida? duelo, PreguntaEnJuego? pregunta, ResultadoDePregunta? resultado, FinalDeDuelo? final$, EsperaDeDuelo? espera, String? dueloId, String? codigo, String? mensaje
});


$EstadoDeLaPartidaCopyWith<$Res>? get duelo;$PreguntaEnJuegoCopyWith<$Res>? get pregunta;$ResultadoDePreguntaCopyWith<$Res>? get resultado;$FinalDeDueloCopyWith<$Res>? get final$;$EsperaDeDueloCopyWith<$Res>? get espera;

}
/// @nodoc
class _$MensajeDeDueloCopyWithImpl<$Res>
    implements $MensajeDeDueloCopyWith<$Res> {
  _$MensajeDeDueloCopyWithImpl(this._self, this._then);

  final MensajeDeDuelo _self;
  final $Res Function(MensajeDeDuelo) _then;

/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tipo = null,Object? duelo = freezed,Object? pregunta = freezed,Object? resultado = freezed,Object? final$ = freezed,Object? espera = freezed,Object? dueloId = freezed,Object? codigo = freezed,Object? mensaje = freezed,}) {
  return _then(_self.copyWith(
tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoMensajeDuelo,duelo: freezed == duelo ? _self.duelo : duelo // ignore: cast_nullable_to_non_nullable
as EstadoDeLaPartida?,pregunta: freezed == pregunta ? _self.pregunta : pregunta // ignore: cast_nullable_to_non_nullable
as PreguntaEnJuego?,resultado: freezed == resultado ? _self.resultado : resultado // ignore: cast_nullable_to_non_nullable
as ResultadoDePregunta?,final$: freezed == final$ ? _self.final$ : final$ // ignore: cast_nullable_to_non_nullable
as FinalDeDuelo?,espera: freezed == espera ? _self.espera : espera // ignore: cast_nullable_to_non_nullable
as EsperaDeDuelo?,dueloId: freezed == dueloId ? _self.dueloId : dueloId // ignore: cast_nullable_to_non_nullable
as String?,codigo: freezed == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String?,mensaje: freezed == mensaje ? _self.mensaje : mensaje // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EstadoDeLaPartidaCopyWith<$Res>? get duelo {
    if (_self.duelo == null) {
    return null;
  }

  return $EstadoDeLaPartidaCopyWith<$Res>(_self.duelo!, (value) {
    return _then(_self.copyWith(duelo: value));
  });
}/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PreguntaEnJuegoCopyWith<$Res>? get pregunta {
    if (_self.pregunta == null) {
    return null;
  }

  return $PreguntaEnJuegoCopyWith<$Res>(_self.pregunta!, (value) {
    return _then(_self.copyWith(pregunta: value));
  });
}/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResultadoDePreguntaCopyWith<$Res>? get resultado {
    if (_self.resultado == null) {
    return null;
  }

  return $ResultadoDePreguntaCopyWith<$Res>(_self.resultado!, (value) {
    return _then(_self.copyWith(resultado: value));
  });
}/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinalDeDueloCopyWith<$Res>? get final$ {
    if (_self.final$ == null) {
    return null;
  }

  return $FinalDeDueloCopyWith<$Res>(_self.final$!, (value) {
    return _then(_self.copyWith(final$: value));
  });
}/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EsperaDeDueloCopyWith<$Res>? get espera {
    if (_self.espera == null) {
    return null;
  }

  return $EsperaDeDueloCopyWith<$Res>(_self.espera!, (value) {
    return _then(_self.copyWith(espera: value));
  });
}
}


/// Adds pattern-matching-related methods to [MensajeDeDuelo].
extension MensajeDeDueloPatterns on MensajeDeDuelo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MensajeDeDuelo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MensajeDeDuelo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MensajeDeDuelo value)  $default,){
final _that = this;
switch (_that) {
case _MensajeDeDuelo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MensajeDeDuelo value)?  $default,){
final _that = this;
switch (_that) {
case _MensajeDeDuelo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( TipoMensajeDuelo tipo,  EstadoDeLaPartida? duelo,  PreguntaEnJuego? pregunta,  ResultadoDePregunta? resultado,  FinalDeDuelo? final$,  EsperaDeDuelo? espera,  String? dueloId,  String? codigo,  String? mensaje)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MensajeDeDuelo() when $default != null:
return $default(_that.tipo,_that.duelo,_that.pregunta,_that.resultado,_that.final$,_that.espera,_that.dueloId,_that.codigo,_that.mensaje);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( TipoMensajeDuelo tipo,  EstadoDeLaPartida? duelo,  PreguntaEnJuego? pregunta,  ResultadoDePregunta? resultado,  FinalDeDuelo? final$,  EsperaDeDuelo? espera,  String? dueloId,  String? codigo,  String? mensaje)  $default,) {final _that = this;
switch (_that) {
case _MensajeDeDuelo():
return $default(_that.tipo,_that.duelo,_that.pregunta,_that.resultado,_that.final$,_that.espera,_that.dueloId,_that.codigo,_that.mensaje);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( TipoMensajeDuelo tipo,  EstadoDeLaPartida? duelo,  PreguntaEnJuego? pregunta,  ResultadoDePregunta? resultado,  FinalDeDuelo? final$,  EsperaDeDuelo? espera,  String? dueloId,  String? codigo,  String? mensaje)?  $default,) {final _that = this;
switch (_that) {
case _MensajeDeDuelo() when $default != null:
return $default(_that.tipo,_that.duelo,_that.pregunta,_that.resultado,_that.final$,_that.espera,_that.dueloId,_that.codigo,_that.mensaje);case _:
  return null;

}
}

}

/// @nodoc


class _MensajeDeDuelo implements MensajeDeDuelo {
  const _MensajeDeDuelo({required this.tipo, this.duelo, this.pregunta, this.resultado, this.final$, this.espera, this.dueloId, this.codigo, this.mensaje});
  

@override final  TipoMensajeDuelo tipo;
@override final  EstadoDeLaPartida? duelo;
@override final  PreguntaEnJuego? pregunta;
@override final  ResultadoDePregunta? resultado;
@override final  FinalDeDuelo? final$;
@override final  EsperaDeDuelo? espera;
/// En `te_mudaron`: a qué duelo hay que ir.
@override final  String? dueloId;
@override final  String? codigo;
@override final  String? mensaje;

/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MensajeDeDueloCopyWith<_MensajeDeDuelo> get copyWith => __$MensajeDeDueloCopyWithImpl<_MensajeDeDuelo>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MensajeDeDuelo&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.duelo, duelo) || other.duelo == duelo)&&(identical(other.pregunta, pregunta) || other.pregunta == pregunta)&&(identical(other.resultado, resultado) || other.resultado == resultado)&&(identical(other.final$, final$) || other.final$ == final$)&&(identical(other.espera, espera) || other.espera == espera)&&(identical(other.dueloId, dueloId) || other.dueloId == dueloId)&&(identical(other.codigo, codigo) || other.codigo == codigo)&&(identical(other.mensaje, mensaje) || other.mensaje == mensaje));
}


@override
int get hashCode => Object.hash(runtimeType,tipo,duelo,pregunta,resultado,final$,espera,dueloId,codigo,mensaje);

@override
String toString() {
  return 'MensajeDeDuelo(tipo: $tipo, duelo: $duelo, pregunta: $pregunta, resultado: $resultado, final\$: ${final$}, espera: $espera, dueloId: $dueloId, codigo: $codigo, mensaje: $mensaje)';
}


}

/// @nodoc
abstract mixin class _$MensajeDeDueloCopyWith<$Res> implements $MensajeDeDueloCopyWith<$Res> {
  factory _$MensajeDeDueloCopyWith(_MensajeDeDuelo value, $Res Function(_MensajeDeDuelo) _then) = __$MensajeDeDueloCopyWithImpl;
@override @useResult
$Res call({
 TipoMensajeDuelo tipo, EstadoDeLaPartida? duelo, PreguntaEnJuego? pregunta, ResultadoDePregunta? resultado, FinalDeDuelo? final$, EsperaDeDuelo? espera, String? dueloId, String? codigo, String? mensaje
});


@override $EstadoDeLaPartidaCopyWith<$Res>? get duelo;@override $PreguntaEnJuegoCopyWith<$Res>? get pregunta;@override $ResultadoDePreguntaCopyWith<$Res>? get resultado;@override $FinalDeDueloCopyWith<$Res>? get final$;@override $EsperaDeDueloCopyWith<$Res>? get espera;

}
/// @nodoc
class __$MensajeDeDueloCopyWithImpl<$Res>
    implements _$MensajeDeDueloCopyWith<$Res> {
  __$MensajeDeDueloCopyWithImpl(this._self, this._then);

  final _MensajeDeDuelo _self;
  final $Res Function(_MensajeDeDuelo) _then;

/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tipo = null,Object? duelo = freezed,Object? pregunta = freezed,Object? resultado = freezed,Object? final$ = freezed,Object? espera = freezed,Object? dueloId = freezed,Object? codigo = freezed,Object? mensaje = freezed,}) {
  return _then(_MensajeDeDuelo(
tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoMensajeDuelo,duelo: freezed == duelo ? _self.duelo : duelo // ignore: cast_nullable_to_non_nullable
as EstadoDeLaPartida?,pregunta: freezed == pregunta ? _self.pregunta : pregunta // ignore: cast_nullable_to_non_nullable
as PreguntaEnJuego?,resultado: freezed == resultado ? _self.resultado : resultado // ignore: cast_nullable_to_non_nullable
as ResultadoDePregunta?,final$: freezed == final$ ? _self.final$ : final$ // ignore: cast_nullable_to_non_nullable
as FinalDeDuelo?,espera: freezed == espera ? _self.espera : espera // ignore: cast_nullable_to_non_nullable
as EsperaDeDuelo?,dueloId: freezed == dueloId ? _self.dueloId : dueloId // ignore: cast_nullable_to_non_nullable
as String?,codigo: freezed == codigo ? _self.codigo : codigo // ignore: cast_nullable_to_non_nullable
as String?,mensaje: freezed == mensaje ? _self.mensaje : mensaje // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EstadoDeLaPartidaCopyWith<$Res>? get duelo {
    if (_self.duelo == null) {
    return null;
  }

  return $EstadoDeLaPartidaCopyWith<$Res>(_self.duelo!, (value) {
    return _then(_self.copyWith(duelo: value));
  });
}/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PreguntaEnJuegoCopyWith<$Res>? get pregunta {
    if (_self.pregunta == null) {
    return null;
  }

  return $PreguntaEnJuegoCopyWith<$Res>(_self.pregunta!, (value) {
    return _then(_self.copyWith(pregunta: value));
  });
}/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ResultadoDePreguntaCopyWith<$Res>? get resultado {
    if (_self.resultado == null) {
    return null;
  }

  return $ResultadoDePreguntaCopyWith<$Res>(_self.resultado!, (value) {
    return _then(_self.copyWith(resultado: value));
  });
}/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FinalDeDueloCopyWith<$Res>? get final$ {
    if (_self.final$ == null) {
    return null;
  }

  return $FinalDeDueloCopyWith<$Res>(_self.final$!, (value) {
    return _then(_self.copyWith(final$: value));
  });
}/// Create a copy of MensajeDeDuelo
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EsperaDeDueloCopyWith<$Res>? get espera {
    if (_self.espera == null) {
    return null;
  }

  return $EsperaDeDueloCopyWith<$Res>(_self.espera!, (value) {
    return _then(_self.copyWith(espera: value));
  });
}
}

// dart format on
