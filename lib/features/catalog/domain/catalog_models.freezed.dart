// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'catalog_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Area {

 String get id; String get nombre; String get grupo;/// Preguntas que aporta al simulacro de 180 (peso del blueprint).
 int get preguntasBlueprint; List<Subtopic> get subtemas;/// Preguntas del banco que el usuario ya vio en esta área.
 int get preguntasVistas;/// Total de preguntas del banco en esta área.
 int get preguntasTotales;/// Aciertos del usuario en esta área.
 int get respuestasCorrectas;/// Preguntas respondidas por el usuario en esta área.
 int get respuestasTotales;
/// Create a copy of Area
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AreaCopyWith<Area> get copyWith => _$AreaCopyWithImpl<Area>(this as Area, _$identity);

  /// Serializes this Area to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Area&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.grupo, grupo) || other.grupo == grupo)&&(identical(other.preguntasBlueprint, preguntasBlueprint) || other.preguntasBlueprint == preguntasBlueprint)&&const DeepCollectionEquality().equals(other.subtemas, subtemas)&&(identical(other.preguntasVistas, preguntasVistas) || other.preguntasVistas == preguntasVistas)&&(identical(other.preguntasTotales, preguntasTotales) || other.preguntasTotales == preguntasTotales)&&(identical(other.respuestasCorrectas, respuestasCorrectas) || other.respuestasCorrectas == respuestasCorrectas)&&(identical(other.respuestasTotales, respuestasTotales) || other.respuestasTotales == respuestasTotales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,grupo,preguntasBlueprint,const DeepCollectionEquality().hash(subtemas),preguntasVistas,preguntasTotales,respuestasCorrectas,respuestasTotales);

@override
String toString() {
  return 'Area(id: $id, nombre: $nombre, grupo: $grupo, preguntasBlueprint: $preguntasBlueprint, subtemas: $subtemas, preguntasVistas: $preguntasVistas, preguntasTotales: $preguntasTotales, respuestasCorrectas: $respuestasCorrectas, respuestasTotales: $respuestasTotales)';
}


}

/// @nodoc
abstract mixin class $AreaCopyWith<$Res>  {
  factory $AreaCopyWith(Area value, $Res Function(Area) _then) = _$AreaCopyWithImpl;
@useResult
$Res call({
 String id, String nombre, String grupo, int preguntasBlueprint, List<Subtopic> subtemas, int preguntasVistas, int preguntasTotales, int respuestasCorrectas, int respuestasTotales
});




}
/// @nodoc
class _$AreaCopyWithImpl<$Res>
    implements $AreaCopyWith<$Res> {
  _$AreaCopyWithImpl(this._self, this._then);

  final Area _self;
  final $Res Function(Area) _then;

/// Create a copy of Area
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? grupo = null,Object? preguntasBlueprint = null,Object? subtemas = null,Object? preguntasVistas = null,Object? preguntasTotales = null,Object? respuestasCorrectas = null,Object? respuestasTotales = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,grupo: null == grupo ? _self.grupo : grupo // ignore: cast_nullable_to_non_nullable
as String,preguntasBlueprint: null == preguntasBlueprint ? _self.preguntasBlueprint : preguntasBlueprint // ignore: cast_nullable_to_non_nullable
as int,subtemas: null == subtemas ? _self.subtemas : subtemas // ignore: cast_nullable_to_non_nullable
as List<Subtopic>,preguntasVistas: null == preguntasVistas ? _self.preguntasVistas : preguntasVistas // ignore: cast_nullable_to_non_nullable
as int,preguntasTotales: null == preguntasTotales ? _self.preguntasTotales : preguntasTotales // ignore: cast_nullable_to_non_nullable
as int,respuestasCorrectas: null == respuestasCorrectas ? _self.respuestasCorrectas : respuestasCorrectas // ignore: cast_nullable_to_non_nullable
as int,respuestasTotales: null == respuestasTotales ? _self.respuestasTotales : respuestasTotales // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Area].
extension AreaPatterns on Area {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Area value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Area() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Area value)  $default,){
final _that = this;
switch (_that) {
case _Area():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Area value)?  $default,){
final _that = this;
switch (_that) {
case _Area() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nombre,  String grupo,  int preguntasBlueprint,  List<Subtopic> subtemas,  int preguntasVistas,  int preguntasTotales,  int respuestasCorrectas,  int respuestasTotales)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Area() when $default != null:
return $default(_that.id,_that.nombre,_that.grupo,_that.preguntasBlueprint,_that.subtemas,_that.preguntasVistas,_that.preguntasTotales,_that.respuestasCorrectas,_that.respuestasTotales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nombre,  String grupo,  int preguntasBlueprint,  List<Subtopic> subtemas,  int preguntasVistas,  int preguntasTotales,  int respuestasCorrectas,  int respuestasTotales)  $default,) {final _that = this;
switch (_that) {
case _Area():
return $default(_that.id,_that.nombre,_that.grupo,_that.preguntasBlueprint,_that.subtemas,_that.preguntasVistas,_that.preguntasTotales,_that.respuestasCorrectas,_that.respuestasTotales);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nombre,  String grupo,  int preguntasBlueprint,  List<Subtopic> subtemas,  int preguntasVistas,  int preguntasTotales,  int respuestasCorrectas,  int respuestasTotales)?  $default,) {final _that = this;
switch (_that) {
case _Area() when $default != null:
return $default(_that.id,_that.nombre,_that.grupo,_that.preguntasBlueprint,_that.subtemas,_that.preguntasVistas,_that.preguntasTotales,_that.respuestasCorrectas,_that.respuestasTotales);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Area extends Area {
  const _Area({required this.id, required this.nombre, required this.grupo, required this.preguntasBlueprint, final  List<Subtopic> subtemas = const [], this.preguntasVistas = 0, this.preguntasTotales = 0, this.respuestasCorrectas = 0, this.respuestasTotales = 0}): _subtemas = subtemas,super._();
  factory _Area.fromJson(Map<String, dynamic> json) => _$AreaFromJson(json);

@override final  String id;
@override final  String nombre;
@override final  String grupo;
/// Preguntas que aporta al simulacro de 180 (peso del blueprint).
@override final  int preguntasBlueprint;
 final  List<Subtopic> _subtemas;
@override@JsonKey() List<Subtopic> get subtemas {
  if (_subtemas is EqualUnmodifiableListView) return _subtemas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_subtemas);
}

/// Preguntas del banco que el usuario ya vio en esta área.
@override@JsonKey() final  int preguntasVistas;
/// Total de preguntas del banco en esta área.
@override@JsonKey() final  int preguntasTotales;
/// Aciertos del usuario en esta área.
@override@JsonKey() final  int respuestasCorrectas;
/// Preguntas respondidas por el usuario en esta área.
@override@JsonKey() final  int respuestasTotales;

/// Create a copy of Area
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AreaCopyWith<_Area> get copyWith => __$AreaCopyWithImpl<_Area>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AreaToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Area&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.grupo, grupo) || other.grupo == grupo)&&(identical(other.preguntasBlueprint, preguntasBlueprint) || other.preguntasBlueprint == preguntasBlueprint)&&const DeepCollectionEquality().equals(other._subtemas, _subtemas)&&(identical(other.preguntasVistas, preguntasVistas) || other.preguntasVistas == preguntasVistas)&&(identical(other.preguntasTotales, preguntasTotales) || other.preguntasTotales == preguntasTotales)&&(identical(other.respuestasCorrectas, respuestasCorrectas) || other.respuestasCorrectas == respuestasCorrectas)&&(identical(other.respuestasTotales, respuestasTotales) || other.respuestasTotales == respuestasTotales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,grupo,preguntasBlueprint,const DeepCollectionEquality().hash(_subtemas),preguntasVistas,preguntasTotales,respuestasCorrectas,respuestasTotales);

@override
String toString() {
  return 'Area(id: $id, nombre: $nombre, grupo: $grupo, preguntasBlueprint: $preguntasBlueprint, subtemas: $subtemas, preguntasVistas: $preguntasVistas, preguntasTotales: $preguntasTotales, respuestasCorrectas: $respuestasCorrectas, respuestasTotales: $respuestasTotales)';
}


}

/// @nodoc
abstract mixin class _$AreaCopyWith<$Res> implements $AreaCopyWith<$Res> {
  factory _$AreaCopyWith(_Area value, $Res Function(_Area) _then) = __$AreaCopyWithImpl;
@override @useResult
$Res call({
 String id, String nombre, String grupo, int preguntasBlueprint, List<Subtopic> subtemas, int preguntasVistas, int preguntasTotales, int respuestasCorrectas, int respuestasTotales
});




}
/// @nodoc
class __$AreaCopyWithImpl<$Res>
    implements _$AreaCopyWith<$Res> {
  __$AreaCopyWithImpl(this._self, this._then);

  final _Area _self;
  final $Res Function(_Area) _then;

/// Create a copy of Area
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? grupo = null,Object? preguntasBlueprint = null,Object? subtemas = null,Object? preguntasVistas = null,Object? preguntasTotales = null,Object? respuestasCorrectas = null,Object? respuestasTotales = null,}) {
  return _then(_Area(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,grupo: null == grupo ? _self.grupo : grupo // ignore: cast_nullable_to_non_nullable
as String,preguntasBlueprint: null == preguntasBlueprint ? _self.preguntasBlueprint : preguntasBlueprint // ignore: cast_nullable_to_non_nullable
as int,subtemas: null == subtemas ? _self._subtemas : subtemas // ignore: cast_nullable_to_non_nullable
as List<Subtopic>,preguntasVistas: null == preguntasVistas ? _self.preguntasVistas : preguntasVistas // ignore: cast_nullable_to_non_nullable
as int,preguntasTotales: null == preguntasTotales ? _self.preguntasTotales : preguntasTotales // ignore: cast_nullable_to_non_nullable
as int,respuestasCorrectas: null == respuestasCorrectas ? _self.respuestasCorrectas : respuestasCorrectas // ignore: cast_nullable_to_non_nullable
as int,respuestasTotales: null == respuestasTotales ? _self.respuestasTotales : respuestasTotales // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$Subtopic {

 String get id; String get areaId; String get nombre; int get preguntasBlueprint; int get preguntasVistas; int get preguntasTotales; int get respuestasCorrectas; int get respuestasTotales;
/// Create a copy of Subtopic
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubtopicCopyWith<Subtopic> get copyWith => _$SubtopicCopyWithImpl<Subtopic>(this as Subtopic, _$identity);

  /// Serializes this Subtopic to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subtopic&&(identical(other.id, id) || other.id == id)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.preguntasBlueprint, preguntasBlueprint) || other.preguntasBlueprint == preguntasBlueprint)&&(identical(other.preguntasVistas, preguntasVistas) || other.preguntasVistas == preguntasVistas)&&(identical(other.preguntasTotales, preguntasTotales) || other.preguntasTotales == preguntasTotales)&&(identical(other.respuestasCorrectas, respuestasCorrectas) || other.respuestasCorrectas == respuestasCorrectas)&&(identical(other.respuestasTotales, respuestasTotales) || other.respuestasTotales == respuestasTotales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,areaId,nombre,preguntasBlueprint,preguntasVistas,preguntasTotales,respuestasCorrectas,respuestasTotales);

@override
String toString() {
  return 'Subtopic(id: $id, areaId: $areaId, nombre: $nombre, preguntasBlueprint: $preguntasBlueprint, preguntasVistas: $preguntasVistas, preguntasTotales: $preguntasTotales, respuestasCorrectas: $respuestasCorrectas, respuestasTotales: $respuestasTotales)';
}


}

/// @nodoc
abstract mixin class $SubtopicCopyWith<$Res>  {
  factory $SubtopicCopyWith(Subtopic value, $Res Function(Subtopic) _then) = _$SubtopicCopyWithImpl;
@useResult
$Res call({
 String id, String areaId, String nombre, int preguntasBlueprint, int preguntasVistas, int preguntasTotales, int respuestasCorrectas, int respuestasTotales
});




}
/// @nodoc
class _$SubtopicCopyWithImpl<$Res>
    implements $SubtopicCopyWith<$Res> {
  _$SubtopicCopyWithImpl(this._self, this._then);

  final Subtopic _self;
  final $Res Function(Subtopic) _then;

/// Create a copy of Subtopic
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? areaId = null,Object? nombre = null,Object? preguntasBlueprint = null,Object? preguntasVistas = null,Object? preguntasTotales = null,Object? respuestasCorrectas = null,Object? respuestasTotales = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,preguntasBlueprint: null == preguntasBlueprint ? _self.preguntasBlueprint : preguntasBlueprint // ignore: cast_nullable_to_non_nullable
as int,preguntasVistas: null == preguntasVistas ? _self.preguntasVistas : preguntasVistas // ignore: cast_nullable_to_non_nullable
as int,preguntasTotales: null == preguntasTotales ? _self.preguntasTotales : preguntasTotales // ignore: cast_nullable_to_non_nullable
as int,respuestasCorrectas: null == respuestasCorrectas ? _self.respuestasCorrectas : respuestasCorrectas // ignore: cast_nullable_to_non_nullable
as int,respuestasTotales: null == respuestasTotales ? _self.respuestasTotales : respuestasTotales // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Subtopic].
extension SubtopicPatterns on Subtopic {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subtopic value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subtopic() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subtopic value)  $default,){
final _that = this;
switch (_that) {
case _Subtopic():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subtopic value)?  $default,){
final _that = this;
switch (_that) {
case _Subtopic() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String areaId,  String nombre,  int preguntasBlueprint,  int preguntasVistas,  int preguntasTotales,  int respuestasCorrectas,  int respuestasTotales)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subtopic() when $default != null:
return $default(_that.id,_that.areaId,_that.nombre,_that.preguntasBlueprint,_that.preguntasVistas,_that.preguntasTotales,_that.respuestasCorrectas,_that.respuestasTotales);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String areaId,  String nombre,  int preguntasBlueprint,  int preguntasVistas,  int preguntasTotales,  int respuestasCorrectas,  int respuestasTotales)  $default,) {final _that = this;
switch (_that) {
case _Subtopic():
return $default(_that.id,_that.areaId,_that.nombre,_that.preguntasBlueprint,_that.preguntasVistas,_that.preguntasTotales,_that.respuestasCorrectas,_that.respuestasTotales);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String areaId,  String nombre,  int preguntasBlueprint,  int preguntasVistas,  int preguntasTotales,  int respuestasCorrectas,  int respuestasTotales)?  $default,) {final _that = this;
switch (_that) {
case _Subtopic() when $default != null:
return $default(_that.id,_that.areaId,_that.nombre,_that.preguntasBlueprint,_that.preguntasVistas,_that.preguntasTotales,_that.respuestasCorrectas,_that.respuestasTotales);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subtopic extends Subtopic {
  const _Subtopic({required this.id, required this.areaId, required this.nombre, required this.preguntasBlueprint, this.preguntasVistas = 0, this.preguntasTotales = 0, this.respuestasCorrectas = 0, this.respuestasTotales = 0}): super._();
  factory _Subtopic.fromJson(Map<String, dynamic> json) => _$SubtopicFromJson(json);

@override final  String id;
@override final  String areaId;
@override final  String nombre;
@override final  int preguntasBlueprint;
@override@JsonKey() final  int preguntasVistas;
@override@JsonKey() final  int preguntasTotales;
@override@JsonKey() final  int respuestasCorrectas;
@override@JsonKey() final  int respuestasTotales;

/// Create a copy of Subtopic
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubtopicCopyWith<_Subtopic> get copyWith => __$SubtopicCopyWithImpl<_Subtopic>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubtopicToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subtopic&&(identical(other.id, id) || other.id == id)&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.preguntasBlueprint, preguntasBlueprint) || other.preguntasBlueprint == preguntasBlueprint)&&(identical(other.preguntasVistas, preguntasVistas) || other.preguntasVistas == preguntasVistas)&&(identical(other.preguntasTotales, preguntasTotales) || other.preguntasTotales == preguntasTotales)&&(identical(other.respuestasCorrectas, respuestasCorrectas) || other.respuestasCorrectas == respuestasCorrectas)&&(identical(other.respuestasTotales, respuestasTotales) || other.respuestasTotales == respuestasTotales));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,areaId,nombre,preguntasBlueprint,preguntasVistas,preguntasTotales,respuestasCorrectas,respuestasTotales);

@override
String toString() {
  return 'Subtopic(id: $id, areaId: $areaId, nombre: $nombre, preguntasBlueprint: $preguntasBlueprint, preguntasVistas: $preguntasVistas, preguntasTotales: $preguntasTotales, respuestasCorrectas: $respuestasCorrectas, respuestasTotales: $respuestasTotales)';
}


}

/// @nodoc
abstract mixin class _$SubtopicCopyWith<$Res> implements $SubtopicCopyWith<$Res> {
  factory _$SubtopicCopyWith(_Subtopic value, $Res Function(_Subtopic) _then) = __$SubtopicCopyWithImpl;
@override @useResult
$Res call({
 String id, String areaId, String nombre, int preguntasBlueprint, int preguntasVistas, int preguntasTotales, int respuestasCorrectas, int respuestasTotales
});




}
/// @nodoc
class __$SubtopicCopyWithImpl<$Res>
    implements _$SubtopicCopyWith<$Res> {
  __$SubtopicCopyWithImpl(this._self, this._then);

  final _Subtopic _self;
  final $Res Function(_Subtopic) _then;

/// Create a copy of Subtopic
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? areaId = null,Object? nombre = null,Object? preguntasBlueprint = null,Object? preguntasVistas = null,Object? preguntasTotales = null,Object? respuestasCorrectas = null,Object? respuestasTotales = null,}) {
  return _then(_Subtopic(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,preguntasBlueprint: null == preguntasBlueprint ? _self.preguntasBlueprint : preguntasBlueprint // ignore: cast_nullable_to_non_nullable
as int,preguntasVistas: null == preguntasVistas ? _self.preguntasVistas : preguntasVistas // ignore: cast_nullable_to_non_nullable
as int,preguntasTotales: null == preguntasTotales ? _self.preguntasTotales : preguntasTotales // ignore: cast_nullable_to_non_nullable
as int,respuestasCorrectas: null == respuestasCorrectas ? _self.respuestasCorrectas : respuestasCorrectas // ignore: cast_nullable_to_non_nullable
as int,respuestasTotales: null == respuestasTotales ? _self.respuestasTotales : respuestasTotales // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
