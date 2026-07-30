// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'session_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$QuestionOption {

 String get id; String get texto;/// Solo llega tras responder (práctica) o al finalizar (simulacro).
/// El servidor NUNCA debe mandarlo antes: sería regalar la respuesta.
 bool? get esCorrecta;/// Explicación del distractor (RF-07). Opcional.
 String? get explicacion;
/// Create a copy of QuestionOption
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionOptionCopyWith<QuestionOption> get copyWith => _$QuestionOptionCopyWithImpl<QuestionOption>(this as QuestionOption, _$identity);

  /// Serializes this QuestionOption to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is QuestionOption&&(identical(other.id, id) || other.id == id)&&(identical(other.texto, texto) || other.texto == texto)&&(identical(other.esCorrecta, esCorrecta) || other.esCorrecta == esCorrecta)&&(identical(other.explicacion, explicacion) || other.explicacion == explicacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,texto,esCorrecta,explicacion);

@override
String toString() {
  return 'QuestionOption(id: $id, texto: $texto, esCorrecta: $esCorrecta, explicacion: $explicacion)';
}


}

/// @nodoc
abstract mixin class $QuestionOptionCopyWith<$Res>  {
  factory $QuestionOptionCopyWith(QuestionOption value, $Res Function(QuestionOption) _then) = _$QuestionOptionCopyWithImpl;
@useResult
$Res call({
 String id, String texto, bool? esCorrecta, String? explicacion
});




}
/// @nodoc
class _$QuestionOptionCopyWithImpl<$Res>
    implements $QuestionOptionCopyWith<$Res> {
  _$QuestionOptionCopyWithImpl(this._self, this._then);

  final QuestionOption _self;
  final $Res Function(QuestionOption) _then;

/// Create a copy of QuestionOption
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? texto = null,Object? esCorrecta = freezed,Object? explicacion = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,esCorrecta: freezed == esCorrecta ? _self.esCorrecta : esCorrecta // ignore: cast_nullable_to_non_nullable
as bool?,explicacion: freezed == explicacion ? _self.explicacion : explicacion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [QuestionOption].
extension QuestionOptionPatterns on QuestionOption {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _QuestionOption value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _QuestionOption() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _QuestionOption value)  $default,){
final _that = this;
switch (_that) {
case _QuestionOption():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _QuestionOption value)?  $default,){
final _that = this;
switch (_that) {
case _QuestionOption() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String texto,  bool? esCorrecta,  String? explicacion)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _QuestionOption() when $default != null:
return $default(_that.id,_that.texto,_that.esCorrecta,_that.explicacion);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String texto,  bool? esCorrecta,  String? explicacion)  $default,) {final _that = this;
switch (_that) {
case _QuestionOption():
return $default(_that.id,_that.texto,_that.esCorrecta,_that.explicacion);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String texto,  bool? esCorrecta,  String? explicacion)?  $default,) {final _that = this;
switch (_that) {
case _QuestionOption() when $default != null:
return $default(_that.id,_that.texto,_that.esCorrecta,_that.explicacion);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _QuestionOption implements QuestionOption {
  const _QuestionOption({required this.id, required this.texto, this.esCorrecta, this.explicacion});
  factory _QuestionOption.fromJson(Map<String, dynamic> json) => _$QuestionOptionFromJson(json);

@override final  String id;
@override final  String texto;
/// Solo llega tras responder (práctica) o al finalizar (simulacro).
/// El servidor NUNCA debe mandarlo antes: sería regalar la respuesta.
@override final  bool? esCorrecta;
/// Explicación del distractor (RF-07). Opcional.
@override final  String? explicacion;

/// Create a copy of QuestionOption
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionOptionCopyWith<_QuestionOption> get copyWith => __$QuestionOptionCopyWithImpl<_QuestionOption>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionOptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _QuestionOption&&(identical(other.id, id) || other.id == id)&&(identical(other.texto, texto) || other.texto == texto)&&(identical(other.esCorrecta, esCorrecta) || other.esCorrecta == esCorrecta)&&(identical(other.explicacion, explicacion) || other.explicacion == explicacion));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,texto,esCorrecta,explicacion);

@override
String toString() {
  return 'QuestionOption(id: $id, texto: $texto, esCorrecta: $esCorrecta, explicacion: $explicacion)';
}


}

/// @nodoc
abstract mixin class _$QuestionOptionCopyWith<$Res> implements $QuestionOptionCopyWith<$Res> {
  factory _$QuestionOptionCopyWith(_QuestionOption value, $Res Function(_QuestionOption) _then) = __$QuestionOptionCopyWithImpl;
@override @useResult
$Res call({
 String id, String texto, bool? esCorrecta, String? explicacion
});




}
/// @nodoc
class __$QuestionOptionCopyWithImpl<$Res>
    implements _$QuestionOptionCopyWith<$Res> {
  __$QuestionOptionCopyWithImpl(this._self, this._then);

  final _QuestionOption _self;
  final $Res Function(_QuestionOption) _then;

/// Create a copy of QuestionOption
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? texto = null,Object? esCorrecta = freezed,Object? explicacion = freezed,}) {
  return _then(_QuestionOption(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,texto: null == texto ? _self.texto : texto // ignore: cast_nullable_to_non_nullable
as String,esCorrecta: freezed == esCorrecta ? _self.esCorrecta : esCorrecta // ignore: cast_nullable_to_non_nullable
as bool?,explicacion: freezed == explicacion ? _self.explicacion : explicacion // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Question {

 String get id; String get enunciado; List<QuestionOption> get opciones;/// Clasificación de la pregunta.
///
/// **Van en `null` durante un simulacro en curso (RN-09):** en el examen
/// real el postulante no ve de qué área es la pregunta, y saberlo daría una
/// pista. Se revelan recién al cerrar la sesión.
 String? get areaId; String? get subtemaId; QuestionType get tipo;/// Dificultad de 1 a 3 (RF-07).
 int get dificultad;/// Año o edición del ENAM de la que proviene. `null` si es de autoría propia.
 int? get origenAnio;/// Imágenes: radiografías, EKG, tablas (RF-10).
 List<String> get imagenes;/// Explicación de la clave. Llega tras responder.
 String? get explicacion;/// % de acierto global de esta pregunta (RF-13). Se muestra al dar feedback.
 double? get porcentajeAciertoGlobal;
/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$QuestionCopyWith<Question> get copyWith => _$QuestionCopyWithImpl<Question>(this as Question, _$identity);

  /// Serializes this Question to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Question&&(identical(other.id, id) || other.id == id)&&(identical(other.enunciado, enunciado) || other.enunciado == enunciado)&&const DeepCollectionEquality().equals(other.opciones, opciones)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.subtemaId, subtemaId) || other.subtemaId == subtemaId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.dificultad, dificultad) || other.dificultad == dificultad)&&(identical(other.origenAnio, origenAnio) || other.origenAnio == origenAnio)&&const DeepCollectionEquality().equals(other.imagenes, imagenes)&&(identical(other.explicacion, explicacion) || other.explicacion == explicacion)&&(identical(other.porcentajeAciertoGlobal, porcentajeAciertoGlobal) || other.porcentajeAciertoGlobal == porcentajeAciertoGlobal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,enunciado,const DeepCollectionEquality().hash(opciones),areaId,subtemaId,tipo,dificultad,origenAnio,const DeepCollectionEquality().hash(imagenes),explicacion,porcentajeAciertoGlobal);

@override
String toString() {
  return 'Question(id: $id, enunciado: $enunciado, opciones: $opciones, areaId: $areaId, subtemaId: $subtemaId, tipo: $tipo, dificultad: $dificultad, origenAnio: $origenAnio, imagenes: $imagenes, explicacion: $explicacion, porcentajeAciertoGlobal: $porcentajeAciertoGlobal)';
}


}

/// @nodoc
abstract mixin class $QuestionCopyWith<$Res>  {
  factory $QuestionCopyWith(Question value, $Res Function(Question) _then) = _$QuestionCopyWithImpl;
@useResult
$Res call({
 String id, String enunciado, List<QuestionOption> opciones, String? areaId, String? subtemaId, QuestionType tipo, int dificultad, int? origenAnio, List<String> imagenes, String? explicacion, double? porcentajeAciertoGlobal
});




}
/// @nodoc
class _$QuestionCopyWithImpl<$Res>
    implements $QuestionCopyWith<$Res> {
  _$QuestionCopyWithImpl(this._self, this._then);

  final Question _self;
  final $Res Function(Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? enunciado = null,Object? opciones = null,Object? areaId = freezed,Object? subtemaId = freezed,Object? tipo = null,Object? dificultad = null,Object? origenAnio = freezed,Object? imagenes = null,Object? explicacion = freezed,Object? porcentajeAciertoGlobal = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,enunciado: null == enunciado ? _self.enunciado : enunciado // ignore: cast_nullable_to_non_nullable
as String,opciones: null == opciones ? _self.opciones : opciones // ignore: cast_nullable_to_non_nullable
as List<QuestionOption>,areaId: freezed == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String?,subtemaId: freezed == subtemaId ? _self.subtemaId : subtemaId // ignore: cast_nullable_to_non_nullable
as String?,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as QuestionType,dificultad: null == dificultad ? _self.dificultad : dificultad // ignore: cast_nullable_to_non_nullable
as int,origenAnio: freezed == origenAnio ? _self.origenAnio : origenAnio // ignore: cast_nullable_to_non_nullable
as int?,imagenes: null == imagenes ? _self.imagenes : imagenes // ignore: cast_nullable_to_non_nullable
as List<String>,explicacion: freezed == explicacion ? _self.explicacion : explicacion // ignore: cast_nullable_to_non_nullable
as String?,porcentajeAciertoGlobal: freezed == porcentajeAciertoGlobal ? _self.porcentajeAciertoGlobal : porcentajeAciertoGlobal // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [Question].
extension QuestionPatterns on Question {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Question value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Question value)  $default,){
final _that = this;
switch (_that) {
case _Question():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Question value)?  $default,){
final _that = this;
switch (_that) {
case _Question() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String enunciado,  List<QuestionOption> opciones,  String? areaId,  String? subtemaId,  QuestionType tipo,  int dificultad,  int? origenAnio,  List<String> imagenes,  String? explicacion,  double? porcentajeAciertoGlobal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.enunciado,_that.opciones,_that.areaId,_that.subtemaId,_that.tipo,_that.dificultad,_that.origenAnio,_that.imagenes,_that.explicacion,_that.porcentajeAciertoGlobal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String enunciado,  List<QuestionOption> opciones,  String? areaId,  String? subtemaId,  QuestionType tipo,  int dificultad,  int? origenAnio,  List<String> imagenes,  String? explicacion,  double? porcentajeAciertoGlobal)  $default,) {final _that = this;
switch (_that) {
case _Question():
return $default(_that.id,_that.enunciado,_that.opciones,_that.areaId,_that.subtemaId,_that.tipo,_that.dificultad,_that.origenAnio,_that.imagenes,_that.explicacion,_that.porcentajeAciertoGlobal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String enunciado,  List<QuestionOption> opciones,  String? areaId,  String? subtemaId,  QuestionType tipo,  int dificultad,  int? origenAnio,  List<String> imagenes,  String? explicacion,  double? porcentajeAciertoGlobal)?  $default,) {final _that = this;
switch (_that) {
case _Question() when $default != null:
return $default(_that.id,_that.enunciado,_that.opciones,_that.areaId,_that.subtemaId,_that.tipo,_that.dificultad,_that.origenAnio,_that.imagenes,_that.explicacion,_that.porcentajeAciertoGlobal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Question implements Question {
  const _Question({required this.id, required this.enunciado, required final  List<QuestionOption> opciones, this.areaId, this.subtemaId, this.tipo = QuestionType.casoClinico, this.dificultad = 2, this.origenAnio, final  List<String> imagenes = const [], this.explicacion, this.porcentajeAciertoGlobal}): _opciones = opciones,_imagenes = imagenes;
  factory _Question.fromJson(Map<String, dynamic> json) => _$QuestionFromJson(json);

@override final  String id;
@override final  String enunciado;
 final  List<QuestionOption> _opciones;
@override List<QuestionOption> get opciones {
  if (_opciones is EqualUnmodifiableListView) return _opciones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_opciones);
}

/// Clasificación de la pregunta.
///
/// **Van en `null` durante un simulacro en curso (RN-09):** en el examen
/// real el postulante no ve de qué área es la pregunta, y saberlo daría una
/// pista. Se revelan recién al cerrar la sesión.
@override final  String? areaId;
@override final  String? subtemaId;
@override@JsonKey() final  QuestionType tipo;
/// Dificultad de 1 a 3 (RF-07).
@override@JsonKey() final  int dificultad;
/// Año o edición del ENAM de la que proviene. `null` si es de autoría propia.
@override final  int? origenAnio;
/// Imágenes: radiografías, EKG, tablas (RF-10).
 final  List<String> _imagenes;
/// Imágenes: radiografías, EKG, tablas (RF-10).
@override@JsonKey() List<String> get imagenes {
  if (_imagenes is EqualUnmodifiableListView) return _imagenes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_imagenes);
}

/// Explicación de la clave. Llega tras responder.
@override final  String? explicacion;
/// % de acierto global de esta pregunta (RF-13). Se muestra al dar feedback.
@override final  double? porcentajeAciertoGlobal;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$QuestionCopyWith<_Question> get copyWith => __$QuestionCopyWithImpl<_Question>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$QuestionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Question&&(identical(other.id, id) || other.id == id)&&(identical(other.enunciado, enunciado) || other.enunciado == enunciado)&&const DeepCollectionEquality().equals(other._opciones, _opciones)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.subtemaId, subtemaId) || other.subtemaId == subtemaId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.dificultad, dificultad) || other.dificultad == dificultad)&&(identical(other.origenAnio, origenAnio) || other.origenAnio == origenAnio)&&const DeepCollectionEquality().equals(other._imagenes, _imagenes)&&(identical(other.explicacion, explicacion) || other.explicacion == explicacion)&&(identical(other.porcentajeAciertoGlobal, porcentajeAciertoGlobal) || other.porcentajeAciertoGlobal == porcentajeAciertoGlobal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,enunciado,const DeepCollectionEquality().hash(_opciones),areaId,subtemaId,tipo,dificultad,origenAnio,const DeepCollectionEquality().hash(_imagenes),explicacion,porcentajeAciertoGlobal);

@override
String toString() {
  return 'Question(id: $id, enunciado: $enunciado, opciones: $opciones, areaId: $areaId, subtemaId: $subtemaId, tipo: $tipo, dificultad: $dificultad, origenAnio: $origenAnio, imagenes: $imagenes, explicacion: $explicacion, porcentajeAciertoGlobal: $porcentajeAciertoGlobal)';
}


}

/// @nodoc
abstract mixin class _$QuestionCopyWith<$Res> implements $QuestionCopyWith<$Res> {
  factory _$QuestionCopyWith(_Question value, $Res Function(_Question) _then) = __$QuestionCopyWithImpl;
@override @useResult
$Res call({
 String id, String enunciado, List<QuestionOption> opciones, String? areaId, String? subtemaId, QuestionType tipo, int dificultad, int? origenAnio, List<String> imagenes, String? explicacion, double? porcentajeAciertoGlobal
});




}
/// @nodoc
class __$QuestionCopyWithImpl<$Res>
    implements _$QuestionCopyWith<$Res> {
  __$QuestionCopyWithImpl(this._self, this._then);

  final _Question _self;
  final $Res Function(_Question) _then;

/// Create a copy of Question
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? enunciado = null,Object? opciones = null,Object? areaId = freezed,Object? subtemaId = freezed,Object? tipo = null,Object? dificultad = null,Object? origenAnio = freezed,Object? imagenes = null,Object? explicacion = freezed,Object? porcentajeAciertoGlobal = freezed,}) {
  return _then(_Question(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,enunciado: null == enunciado ? _self.enunciado : enunciado // ignore: cast_nullable_to_non_nullable
as String,opciones: null == opciones ? _self._opciones : opciones // ignore: cast_nullable_to_non_nullable
as List<QuestionOption>,areaId: freezed == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String?,subtemaId: freezed == subtemaId ? _self.subtemaId : subtemaId // ignore: cast_nullable_to_non_nullable
as String?,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as QuestionType,dificultad: null == dificultad ? _self.dificultad : dificultad // ignore: cast_nullable_to_non_nullable
as int,origenAnio: freezed == origenAnio ? _self.origenAnio : origenAnio // ignore: cast_nullable_to_non_nullable
as int?,imagenes: null == imagenes ? _self._imagenes : imagenes // ignore: cast_nullable_to_non_nullable
as List<String>,explicacion: freezed == explicacion ? _self.explicacion : explicacion // ignore: cast_nullable_to_non_nullable
as String?,porcentajeAciertoGlobal: freezed == porcentajeAciertoGlobal ? _self.porcentajeAciertoGlobal : porcentajeAciertoGlobal // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}


/// @nodoc
mixin _$Answer {

 String get questionId;/// `null` = dejada en blanco. Sin puntaje en contra, vale igual que fallar
/// (RN-01), pero se distingue para las estadísticas.
 String? get optionId; bool? get esCorrecta;/// Tiempo empleado. Se usa para desempatar en simulacros nacionales (RN-05).
 int get tiempoMs;/// Marcada para revisar después (RF-14, RF-17).
 bool get marcada;/// Respondida sin conexión y pendiente de sincronizar (RF-31/32).
 bool get respondidaOffline;
/// Create a copy of Answer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnswerCopyWith<Answer> get copyWith => _$AnswerCopyWithImpl<Answer>(this as Answer, _$identity);

  /// Serializes this Answer to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Answer&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.optionId, optionId) || other.optionId == optionId)&&(identical(other.esCorrecta, esCorrecta) || other.esCorrecta == esCorrecta)&&(identical(other.tiempoMs, tiempoMs) || other.tiempoMs == tiempoMs)&&(identical(other.marcada, marcada) || other.marcada == marcada)&&(identical(other.respondidaOffline, respondidaOffline) || other.respondidaOffline == respondidaOffline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,optionId,esCorrecta,tiempoMs,marcada,respondidaOffline);

@override
String toString() {
  return 'Answer(questionId: $questionId, optionId: $optionId, esCorrecta: $esCorrecta, tiempoMs: $tiempoMs, marcada: $marcada, respondidaOffline: $respondidaOffline)';
}


}

/// @nodoc
abstract mixin class $AnswerCopyWith<$Res>  {
  factory $AnswerCopyWith(Answer value, $Res Function(Answer) _then) = _$AnswerCopyWithImpl;
@useResult
$Res call({
 String questionId, String? optionId, bool? esCorrecta, int tiempoMs, bool marcada, bool respondidaOffline
});




}
/// @nodoc
class _$AnswerCopyWithImpl<$Res>
    implements $AnswerCopyWith<$Res> {
  _$AnswerCopyWithImpl(this._self, this._then);

  final Answer _self;
  final $Res Function(Answer) _then;

/// Create a copy of Answer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? optionId = freezed,Object? esCorrecta = freezed,Object? tiempoMs = null,Object? marcada = null,Object? respondidaOffline = null,}) {
  return _then(_self.copyWith(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,optionId: freezed == optionId ? _self.optionId : optionId // ignore: cast_nullable_to_non_nullable
as String?,esCorrecta: freezed == esCorrecta ? _self.esCorrecta : esCorrecta // ignore: cast_nullable_to_non_nullable
as bool?,tiempoMs: null == tiempoMs ? _self.tiempoMs : tiempoMs // ignore: cast_nullable_to_non_nullable
as int,marcada: null == marcada ? _self.marcada : marcada // ignore: cast_nullable_to_non_nullable
as bool,respondidaOffline: null == respondidaOffline ? _self.respondidaOffline : respondidaOffline // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [Answer].
extension AnswerPatterns on Answer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Answer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Answer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Answer value)  $default,){
final _that = this;
switch (_that) {
case _Answer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Answer value)?  $default,){
final _that = this;
switch (_that) {
case _Answer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String questionId,  String? optionId,  bool? esCorrecta,  int tiempoMs,  bool marcada,  bool respondidaOffline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Answer() when $default != null:
return $default(_that.questionId,_that.optionId,_that.esCorrecta,_that.tiempoMs,_that.marcada,_that.respondidaOffline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String questionId,  String? optionId,  bool? esCorrecta,  int tiempoMs,  bool marcada,  bool respondidaOffline)  $default,) {final _that = this;
switch (_that) {
case _Answer():
return $default(_that.questionId,_that.optionId,_that.esCorrecta,_that.tiempoMs,_that.marcada,_that.respondidaOffline);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String questionId,  String? optionId,  bool? esCorrecta,  int tiempoMs,  bool marcada,  bool respondidaOffline)?  $default,) {final _that = this;
switch (_that) {
case _Answer() when $default != null:
return $default(_that.questionId,_that.optionId,_that.esCorrecta,_that.tiempoMs,_that.marcada,_that.respondidaOffline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Answer implements Answer {
  const _Answer({required this.questionId, this.optionId, this.esCorrecta, this.tiempoMs = 0, this.marcada = false, this.respondidaOffline = false});
  factory _Answer.fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);

@override final  String questionId;
/// `null` = dejada en blanco. Sin puntaje en contra, vale igual que fallar
/// (RN-01), pero se distingue para las estadísticas.
@override final  String? optionId;
@override final  bool? esCorrecta;
/// Tiempo empleado. Se usa para desempatar en simulacros nacionales (RN-05).
@override@JsonKey() final  int tiempoMs;
/// Marcada para revisar después (RF-14, RF-17).
@override@JsonKey() final  bool marcada;
/// Respondida sin conexión y pendiente de sincronizar (RF-31/32).
@override@JsonKey() final  bool respondidaOffline;

/// Create a copy of Answer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnswerCopyWith<_Answer> get copyWith => __$AnswerCopyWithImpl<_Answer>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnswerToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Answer&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.optionId, optionId) || other.optionId == optionId)&&(identical(other.esCorrecta, esCorrecta) || other.esCorrecta == esCorrecta)&&(identical(other.tiempoMs, tiempoMs) || other.tiempoMs == tiempoMs)&&(identical(other.marcada, marcada) || other.marcada == marcada)&&(identical(other.respondidaOffline, respondidaOffline) || other.respondidaOffline == respondidaOffline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,optionId,esCorrecta,tiempoMs,marcada,respondidaOffline);

@override
String toString() {
  return 'Answer(questionId: $questionId, optionId: $optionId, esCorrecta: $esCorrecta, tiempoMs: $tiempoMs, marcada: $marcada, respondidaOffline: $respondidaOffline)';
}


}

/// @nodoc
abstract mixin class _$AnswerCopyWith<$Res> implements $AnswerCopyWith<$Res> {
  factory _$AnswerCopyWith(_Answer value, $Res Function(_Answer) _then) = __$AnswerCopyWithImpl;
@override @useResult
$Res call({
 String questionId, String? optionId, bool? esCorrecta, int tiempoMs, bool marcada, bool respondidaOffline
});




}
/// @nodoc
class __$AnswerCopyWithImpl<$Res>
    implements _$AnswerCopyWith<$Res> {
  __$AnswerCopyWithImpl(this._self, this._then);

  final _Answer _self;
  final $Res Function(_Answer) _then;

/// Create a copy of Answer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? optionId = freezed,Object? esCorrecta = freezed,Object? tiempoMs = null,Object? marcada = null,Object? respondidaOffline = null,}) {
  return _then(_Answer(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,optionId: freezed == optionId ? _self.optionId : optionId // ignore: cast_nullable_to_non_nullable
as String?,esCorrecta: freezed == esCorrecta ? _self.esCorrecta : esCorrecta // ignore: cast_nullable_to_non_nullable
as bool?,tiempoMs: null == tiempoMs ? _self.tiempoMs : tiempoMs // ignore: cast_nullable_to_non_nullable
as int,marcada: null == marcada ? _self.marcada : marcada // ignore: cast_nullable_to_non_nullable
as bool,respondidaOffline: null == respondidaOffline ? _self.respondidaOffline : respondidaOffline // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PracticeConfig {

 List<String> get areaIds; List<String> get subtemaIds; int get cantidadPreguntas; QuestionSource get origen;
/// Create a copy of PracticeConfig
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PracticeConfigCopyWith<PracticeConfig> get copyWith => _$PracticeConfigCopyWithImpl<PracticeConfig>(this as PracticeConfig, _$identity);

  /// Serializes this PracticeConfig to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PracticeConfig&&const DeepCollectionEquality().equals(other.areaIds, areaIds)&&const DeepCollectionEquality().equals(other.subtemaIds, subtemaIds)&&(identical(other.cantidadPreguntas, cantidadPreguntas) || other.cantidadPreguntas == cantidadPreguntas)&&(identical(other.origen, origen) || other.origen == origen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(areaIds),const DeepCollectionEquality().hash(subtemaIds),cantidadPreguntas,origen);

@override
String toString() {
  return 'PracticeConfig(areaIds: $areaIds, subtemaIds: $subtemaIds, cantidadPreguntas: $cantidadPreguntas, origen: $origen)';
}


}

/// @nodoc
abstract mixin class $PracticeConfigCopyWith<$Res>  {
  factory $PracticeConfigCopyWith(PracticeConfig value, $Res Function(PracticeConfig) _then) = _$PracticeConfigCopyWithImpl;
@useResult
$Res call({
 List<String> areaIds, List<String> subtemaIds, int cantidadPreguntas, QuestionSource origen
});




}
/// @nodoc
class _$PracticeConfigCopyWithImpl<$Res>
    implements $PracticeConfigCopyWith<$Res> {
  _$PracticeConfigCopyWithImpl(this._self, this._then);

  final PracticeConfig _self;
  final $Res Function(PracticeConfig) _then;

/// Create a copy of PracticeConfig
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? areaIds = null,Object? subtemaIds = null,Object? cantidadPreguntas = null,Object? origen = null,}) {
  return _then(_self.copyWith(
areaIds: null == areaIds ? _self.areaIds : areaIds // ignore: cast_nullable_to_non_nullable
as List<String>,subtemaIds: null == subtemaIds ? _self.subtemaIds : subtemaIds // ignore: cast_nullable_to_non_nullable
as List<String>,cantidadPreguntas: null == cantidadPreguntas ? _self.cantidadPreguntas : cantidadPreguntas // ignore: cast_nullable_to_non_nullable
as int,origen: null == origen ? _self.origen : origen // ignore: cast_nullable_to_non_nullable
as QuestionSource,
  ));
}

}


/// Adds pattern-matching-related methods to [PracticeConfig].
extension PracticeConfigPatterns on PracticeConfig {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PracticeConfig value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PracticeConfig() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PracticeConfig value)  $default,){
final _that = this;
switch (_that) {
case _PracticeConfig():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PracticeConfig value)?  $default,){
final _that = this;
switch (_that) {
case _PracticeConfig() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> areaIds,  List<String> subtemaIds,  int cantidadPreguntas,  QuestionSource origen)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PracticeConfig() when $default != null:
return $default(_that.areaIds,_that.subtemaIds,_that.cantidadPreguntas,_that.origen);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> areaIds,  List<String> subtemaIds,  int cantidadPreguntas,  QuestionSource origen)  $default,) {final _that = this;
switch (_that) {
case _PracticeConfig():
return $default(_that.areaIds,_that.subtemaIds,_that.cantidadPreguntas,_that.origen);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> areaIds,  List<String> subtemaIds,  int cantidadPreguntas,  QuestionSource origen)?  $default,) {final _that = this;
switch (_that) {
case _PracticeConfig() when $default != null:
return $default(_that.areaIds,_that.subtemaIds,_that.cantidadPreguntas,_that.origen);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PracticeConfig implements PracticeConfig {
  const _PracticeConfig({final  List<String> areaIds = const [], final  List<String> subtemaIds = const [], this.cantidadPreguntas = 20, this.origen = QuestionSource.todas}): _areaIds = areaIds,_subtemaIds = subtemaIds;
  factory _PracticeConfig.fromJson(Map<String, dynamic> json) => _$PracticeConfigFromJson(json);

 final  List<String> _areaIds;
@override@JsonKey() List<String> get areaIds {
  if (_areaIds is EqualUnmodifiableListView) return _areaIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_areaIds);
}

 final  List<String> _subtemaIds;
@override@JsonKey() List<String> get subtemaIds {
  if (_subtemaIds is EqualUnmodifiableListView) return _subtemaIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subtemaIds);
}

@override@JsonKey() final  int cantidadPreguntas;
@override@JsonKey() final  QuestionSource origen;

/// Create a copy of PracticeConfig
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PracticeConfigCopyWith<_PracticeConfig> get copyWith => __$PracticeConfigCopyWithImpl<_PracticeConfig>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PracticeConfigToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PracticeConfig&&const DeepCollectionEquality().equals(other._areaIds, _areaIds)&&const DeepCollectionEquality().equals(other._subtemaIds, _subtemaIds)&&(identical(other.cantidadPreguntas, cantidadPreguntas) || other.cantidadPreguntas == cantidadPreguntas)&&(identical(other.origen, origen) || other.origen == origen));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_areaIds),const DeepCollectionEquality().hash(_subtemaIds),cantidadPreguntas,origen);

@override
String toString() {
  return 'PracticeConfig(areaIds: $areaIds, subtemaIds: $subtemaIds, cantidadPreguntas: $cantidadPreguntas, origen: $origen)';
}


}

/// @nodoc
abstract mixin class _$PracticeConfigCopyWith<$Res> implements $PracticeConfigCopyWith<$Res> {
  factory _$PracticeConfigCopyWith(_PracticeConfig value, $Res Function(_PracticeConfig) _then) = __$PracticeConfigCopyWithImpl;
@override @useResult
$Res call({
 List<String> areaIds, List<String> subtemaIds, int cantidadPreguntas, QuestionSource origen
});




}
/// @nodoc
class __$PracticeConfigCopyWithImpl<$Res>
    implements _$PracticeConfigCopyWith<$Res> {
  __$PracticeConfigCopyWithImpl(this._self, this._then);

  final _PracticeConfig _self;
  final $Res Function(_PracticeConfig) _then;

/// Create a copy of PracticeConfig
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? areaIds = null,Object? subtemaIds = null,Object? cantidadPreguntas = null,Object? origen = null,}) {
  return _then(_PracticeConfig(
areaIds: null == areaIds ? _self._areaIds : areaIds // ignore: cast_nullable_to_non_nullable
as List<String>,subtemaIds: null == subtemaIds ? _self._subtemaIds : subtemaIds // ignore: cast_nullable_to_non_nullable
as List<String>,cantidadPreguntas: null == cantidadPreguntas ? _self.cantidadPreguntas : cantidadPreguntas // ignore: cast_nullable_to_non_nullable
as int,origen: null == origen ? _self.origen : origen // ignore: cast_nullable_to_non_nullable
as QuestionSource,
  ));
}


}


/// @nodoc
mixin _$StudySession {

 String get id; SessionType get tipo; SessionStatus get estado; DateTime get iniciadaEn; List<Question> get preguntas; Map<String, Answer> get respuestas; DateTime? get finalizadaEn;/// Cuándo se acaba el tiempo. Solo en simulacros.
 DateTime? get expiraEn;/// Nota vigesimal. Solo cuando la sesión terminó (RN-01).
 double? get nota;
/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StudySessionCopyWith<StudySession> get copyWith => _$StudySessionCopyWithImpl<StudySession>(this as StudySession, _$identity);

  /// Serializes this StudySession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StudySession&&(identical(other.id, id) || other.id == id)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.iniciadaEn, iniciadaEn) || other.iniciadaEn == iniciadaEn)&&const DeepCollectionEquality().equals(other.preguntas, preguntas)&&const DeepCollectionEquality().equals(other.respuestas, respuestas)&&(identical(other.finalizadaEn, finalizadaEn) || other.finalizadaEn == finalizadaEn)&&(identical(other.expiraEn, expiraEn) || other.expiraEn == expiraEn)&&(identical(other.nota, nota) || other.nota == nota));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tipo,estado,iniciadaEn,const DeepCollectionEquality().hash(preguntas),const DeepCollectionEquality().hash(respuestas),finalizadaEn,expiraEn,nota);

@override
String toString() {
  return 'StudySession(id: $id, tipo: $tipo, estado: $estado, iniciadaEn: $iniciadaEn, preguntas: $preguntas, respuestas: $respuestas, finalizadaEn: $finalizadaEn, expiraEn: $expiraEn, nota: $nota)';
}


}

/// @nodoc
abstract mixin class $StudySessionCopyWith<$Res>  {
  factory $StudySessionCopyWith(StudySession value, $Res Function(StudySession) _then) = _$StudySessionCopyWithImpl;
@useResult
$Res call({
 String id, SessionType tipo, SessionStatus estado, DateTime iniciadaEn, List<Question> preguntas, Map<String, Answer> respuestas, DateTime? finalizadaEn, DateTime? expiraEn, double? nota
});




}
/// @nodoc
class _$StudySessionCopyWithImpl<$Res>
    implements $StudySessionCopyWith<$Res> {
  _$StudySessionCopyWithImpl(this._self, this._then);

  final StudySession _self;
  final $Res Function(StudySession) _then;

/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tipo = null,Object? estado = null,Object? iniciadaEn = null,Object? preguntas = null,Object? respuestas = null,Object? finalizadaEn = freezed,Object? expiraEn = freezed,Object? nota = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as SessionType,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as SessionStatus,iniciadaEn: null == iniciadaEn ? _self.iniciadaEn : iniciadaEn // ignore: cast_nullable_to_non_nullable
as DateTime,preguntas: null == preguntas ? _self.preguntas : preguntas // ignore: cast_nullable_to_non_nullable
as List<Question>,respuestas: null == respuestas ? _self.respuestas : respuestas // ignore: cast_nullable_to_non_nullable
as Map<String, Answer>,finalizadaEn: freezed == finalizadaEn ? _self.finalizadaEn : finalizadaEn // ignore: cast_nullable_to_non_nullable
as DateTime?,expiraEn: freezed == expiraEn ? _self.expiraEn : expiraEn // ignore: cast_nullable_to_non_nullable
as DateTime?,nota: freezed == nota ? _self.nota : nota // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [StudySession].
extension StudySessionPatterns on StudySession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StudySession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StudySession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StudySession value)  $default,){
final _that = this;
switch (_that) {
case _StudySession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StudySession value)?  $default,){
final _that = this;
switch (_that) {
case _StudySession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  SessionType tipo,  SessionStatus estado,  DateTime iniciadaEn,  List<Question> preguntas,  Map<String, Answer> respuestas,  DateTime? finalizadaEn,  DateTime? expiraEn,  double? nota)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StudySession() when $default != null:
return $default(_that.id,_that.tipo,_that.estado,_that.iniciadaEn,_that.preguntas,_that.respuestas,_that.finalizadaEn,_that.expiraEn,_that.nota);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  SessionType tipo,  SessionStatus estado,  DateTime iniciadaEn,  List<Question> preguntas,  Map<String, Answer> respuestas,  DateTime? finalizadaEn,  DateTime? expiraEn,  double? nota)  $default,) {final _that = this;
switch (_that) {
case _StudySession():
return $default(_that.id,_that.tipo,_that.estado,_that.iniciadaEn,_that.preguntas,_that.respuestas,_that.finalizadaEn,_that.expiraEn,_that.nota);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  SessionType tipo,  SessionStatus estado,  DateTime iniciadaEn,  List<Question> preguntas,  Map<String, Answer> respuestas,  DateTime? finalizadaEn,  DateTime? expiraEn,  double? nota)?  $default,) {final _that = this;
switch (_that) {
case _StudySession() when $default != null:
return $default(_that.id,_that.tipo,_that.estado,_that.iniciadaEn,_that.preguntas,_that.respuestas,_that.finalizadaEn,_that.expiraEn,_that.nota);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StudySession extends StudySession {
  const _StudySession({required this.id, required this.tipo, required this.estado, required this.iniciadaEn, final  List<Question> preguntas = const [], final  Map<String, Answer> respuestas = const {}, this.finalizadaEn, this.expiraEn, this.nota}): _preguntas = preguntas,_respuestas = respuestas,super._();
  factory _StudySession.fromJson(Map<String, dynamic> json) => _$StudySessionFromJson(json);

@override final  String id;
@override final  SessionType tipo;
@override final  SessionStatus estado;
@override final  DateTime iniciadaEn;
 final  List<Question> _preguntas;
@override@JsonKey() List<Question> get preguntas {
  if (_preguntas is EqualUnmodifiableListView) return _preguntas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preguntas);
}

 final  Map<String, Answer> _respuestas;
@override@JsonKey() Map<String, Answer> get respuestas {
  if (_respuestas is EqualUnmodifiableMapView) return _respuestas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_respuestas);
}

@override final  DateTime? finalizadaEn;
/// Cuándo se acaba el tiempo. Solo en simulacros.
@override final  DateTime? expiraEn;
/// Nota vigesimal. Solo cuando la sesión terminó (RN-01).
@override final  double? nota;

/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StudySessionCopyWith<_StudySession> get copyWith => __$StudySessionCopyWithImpl<_StudySession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StudySessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StudySession&&(identical(other.id, id) || other.id == id)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.iniciadaEn, iniciadaEn) || other.iniciadaEn == iniciadaEn)&&const DeepCollectionEquality().equals(other._preguntas, _preguntas)&&const DeepCollectionEquality().equals(other._respuestas, _respuestas)&&(identical(other.finalizadaEn, finalizadaEn) || other.finalizadaEn == finalizadaEn)&&(identical(other.expiraEn, expiraEn) || other.expiraEn == expiraEn)&&(identical(other.nota, nota) || other.nota == nota));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,tipo,estado,iniciadaEn,const DeepCollectionEquality().hash(_preguntas),const DeepCollectionEquality().hash(_respuestas),finalizadaEn,expiraEn,nota);

@override
String toString() {
  return 'StudySession(id: $id, tipo: $tipo, estado: $estado, iniciadaEn: $iniciadaEn, preguntas: $preguntas, respuestas: $respuestas, finalizadaEn: $finalizadaEn, expiraEn: $expiraEn, nota: $nota)';
}


}

/// @nodoc
abstract mixin class _$StudySessionCopyWith<$Res> implements $StudySessionCopyWith<$Res> {
  factory _$StudySessionCopyWith(_StudySession value, $Res Function(_StudySession) _then) = __$StudySessionCopyWithImpl;
@override @useResult
$Res call({
 String id, SessionType tipo, SessionStatus estado, DateTime iniciadaEn, List<Question> preguntas, Map<String, Answer> respuestas, DateTime? finalizadaEn, DateTime? expiraEn, double? nota
});




}
/// @nodoc
class __$StudySessionCopyWithImpl<$Res>
    implements _$StudySessionCopyWith<$Res> {
  __$StudySessionCopyWithImpl(this._self, this._then);

  final _StudySession _self;
  final $Res Function(_StudySession) _then;

/// Create a copy of StudySession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tipo = null,Object? estado = null,Object? iniciadaEn = null,Object? preguntas = null,Object? respuestas = null,Object? finalizadaEn = freezed,Object? expiraEn = freezed,Object? nota = freezed,}) {
  return _then(_StudySession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as SessionType,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as SessionStatus,iniciadaEn: null == iniciadaEn ? _self.iniciadaEn : iniciadaEn // ignore: cast_nullable_to_non_nullable
as DateTime,preguntas: null == preguntas ? _self._preguntas : preguntas // ignore: cast_nullable_to_non_nullable
as List<Question>,respuestas: null == respuestas ? _self._respuestas : respuestas // ignore: cast_nullable_to_non_nullable
as Map<String, Answer>,finalizadaEn: freezed == finalizadaEn ? _self.finalizadaEn : finalizadaEn // ignore: cast_nullable_to_non_nullable
as DateTime?,expiraEn: freezed == expiraEn ? _self.expiraEn : expiraEn // ignore: cast_nullable_to_non_nullable
as DateTime?,nota: freezed == nota ? _self.nota : nota // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
