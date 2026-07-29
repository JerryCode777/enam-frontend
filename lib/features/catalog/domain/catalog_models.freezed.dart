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
mixin _$CatalogNode {

 String get id; String get nombre;/// `area`, `bloque`, `sub_area` o `tema`.
 String get nivel;/// Preguntas que aporta al examen de 180. `null` en temas.
 int? get peso;/// Solo en nodos de nivel área.
 String? get grupo; List<CatalogNode> get hijos;/// Preguntas del banco disponibles en este nodo.
///
/// Puede ser 0: el banco se carga de forma progresiva, así que durante un
/// tiempo habrá partes del temario sin preguntas todavía. La UI debe decir
/// "aún no disponible", no mostrar una lista vacía sin explicación.
 int get preguntasDisponibles;/// Preguntas de este nodo que el usuario ya vio.
 int get preguntasVistas;/// Respuestas del usuario en este nodo.
 int get respuestasTotales; int get respuestasCorrectas;
/// Create a copy of CatalogNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CatalogNodeCopyWith<CatalogNode> get copyWith => _$CatalogNodeCopyWithImpl<CatalogNode>(this as CatalogNode, _$identity);

  /// Serializes this CatalogNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CatalogNode&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.nivel, nivel) || other.nivel == nivel)&&(identical(other.peso, peso) || other.peso == peso)&&(identical(other.grupo, grupo) || other.grupo == grupo)&&const DeepCollectionEquality().equals(other.hijos, hijos)&&(identical(other.preguntasDisponibles, preguntasDisponibles) || other.preguntasDisponibles == preguntasDisponibles)&&(identical(other.preguntasVistas, preguntasVistas) || other.preguntasVistas == preguntasVistas)&&(identical(other.respuestasTotales, respuestasTotales) || other.respuestasTotales == respuestasTotales)&&(identical(other.respuestasCorrectas, respuestasCorrectas) || other.respuestasCorrectas == respuestasCorrectas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,nivel,peso,grupo,const DeepCollectionEquality().hash(hijos),preguntasDisponibles,preguntasVistas,respuestasTotales,respuestasCorrectas);

@override
String toString() {
  return 'CatalogNode(id: $id, nombre: $nombre, nivel: $nivel, peso: $peso, grupo: $grupo, hijos: $hijos, preguntasDisponibles: $preguntasDisponibles, preguntasVistas: $preguntasVistas, respuestasTotales: $respuestasTotales, respuestasCorrectas: $respuestasCorrectas)';
}


}

/// @nodoc
abstract mixin class $CatalogNodeCopyWith<$Res>  {
  factory $CatalogNodeCopyWith(CatalogNode value, $Res Function(CatalogNode) _then) = _$CatalogNodeCopyWithImpl;
@useResult
$Res call({
 String id, String nombre, String nivel, int? peso, String? grupo, List<CatalogNode> hijos, int preguntasDisponibles, int preguntasVistas, int respuestasTotales, int respuestasCorrectas
});




}
/// @nodoc
class _$CatalogNodeCopyWithImpl<$Res>
    implements $CatalogNodeCopyWith<$Res> {
  _$CatalogNodeCopyWithImpl(this._self, this._then);

  final CatalogNode _self;
  final $Res Function(CatalogNode) _then;

/// Create a copy of CatalogNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? nivel = null,Object? peso = freezed,Object? grupo = freezed,Object? hijos = null,Object? preguntasDisponibles = null,Object? preguntasVistas = null,Object? respuestasTotales = null,Object? respuestasCorrectas = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as String,peso: freezed == peso ? _self.peso : peso // ignore: cast_nullable_to_non_nullable
as int?,grupo: freezed == grupo ? _self.grupo : grupo // ignore: cast_nullable_to_non_nullable
as String?,hijos: null == hijos ? _self.hijos : hijos // ignore: cast_nullable_to_non_nullable
as List<CatalogNode>,preguntasDisponibles: null == preguntasDisponibles ? _self.preguntasDisponibles : preguntasDisponibles // ignore: cast_nullable_to_non_nullable
as int,preguntasVistas: null == preguntasVistas ? _self.preguntasVistas : preguntasVistas // ignore: cast_nullable_to_non_nullable
as int,respuestasTotales: null == respuestasTotales ? _self.respuestasTotales : respuestasTotales // ignore: cast_nullable_to_non_nullable
as int,respuestasCorrectas: null == respuestasCorrectas ? _self.respuestasCorrectas : respuestasCorrectas // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CatalogNode].
extension CatalogNodePatterns on CatalogNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CatalogNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CatalogNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CatalogNode value)  $default,){
final _that = this;
switch (_that) {
case _CatalogNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CatalogNode value)?  $default,){
final _that = this;
switch (_that) {
case _CatalogNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nombre,  String nivel,  int? peso,  String? grupo,  List<CatalogNode> hijos,  int preguntasDisponibles,  int preguntasVistas,  int respuestasTotales,  int respuestasCorrectas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CatalogNode() when $default != null:
return $default(_that.id,_that.nombre,_that.nivel,_that.peso,_that.grupo,_that.hijos,_that.preguntasDisponibles,_that.preguntasVistas,_that.respuestasTotales,_that.respuestasCorrectas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nombre,  String nivel,  int? peso,  String? grupo,  List<CatalogNode> hijos,  int preguntasDisponibles,  int preguntasVistas,  int respuestasTotales,  int respuestasCorrectas)  $default,) {final _that = this;
switch (_that) {
case _CatalogNode():
return $default(_that.id,_that.nombre,_that.nivel,_that.peso,_that.grupo,_that.hijos,_that.preguntasDisponibles,_that.preguntasVistas,_that.respuestasTotales,_that.respuestasCorrectas);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nombre,  String nivel,  int? peso,  String? grupo,  List<CatalogNode> hijos,  int preguntasDisponibles,  int preguntasVistas,  int respuestasTotales,  int respuestasCorrectas)?  $default,) {final _that = this;
switch (_that) {
case _CatalogNode() when $default != null:
return $default(_that.id,_that.nombre,_that.nivel,_that.peso,_that.grupo,_that.hijos,_that.preguntasDisponibles,_that.preguntasVistas,_that.respuestasTotales,_that.respuestasCorrectas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CatalogNode extends CatalogNode {
  const _CatalogNode({required this.id, required this.nombre, required this.nivel, this.peso, this.grupo, final  List<CatalogNode> hijos = const [], this.preguntasDisponibles = 0, this.preguntasVistas = 0, this.respuestasTotales = 0, this.respuestasCorrectas = 0}): _hijos = hijos,super._();
  factory _CatalogNode.fromJson(Map<String, dynamic> json) => _$CatalogNodeFromJson(json);

@override final  String id;
@override final  String nombre;
/// `area`, `bloque`, `sub_area` o `tema`.
@override final  String nivel;
/// Preguntas que aporta al examen de 180. `null` en temas.
@override final  int? peso;
/// Solo en nodos de nivel área.
@override final  String? grupo;
 final  List<CatalogNode> _hijos;
@override@JsonKey() List<CatalogNode> get hijos {
  if (_hijos is EqualUnmodifiableListView) return _hijos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hijos);
}

/// Preguntas del banco disponibles en este nodo.
///
/// Puede ser 0: el banco se carga de forma progresiva, así que durante un
/// tiempo habrá partes del temario sin preguntas todavía. La UI debe decir
/// "aún no disponible", no mostrar una lista vacía sin explicación.
@override@JsonKey() final  int preguntasDisponibles;
/// Preguntas de este nodo que el usuario ya vio.
@override@JsonKey() final  int preguntasVistas;
/// Respuestas del usuario en este nodo.
@override@JsonKey() final  int respuestasTotales;
@override@JsonKey() final  int respuestasCorrectas;

/// Create a copy of CatalogNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CatalogNodeCopyWith<_CatalogNode> get copyWith => __$CatalogNodeCopyWithImpl<_CatalogNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CatalogNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CatalogNode&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.nivel, nivel) || other.nivel == nivel)&&(identical(other.peso, peso) || other.peso == peso)&&(identical(other.grupo, grupo) || other.grupo == grupo)&&const DeepCollectionEquality().equals(other._hijos, _hijos)&&(identical(other.preguntasDisponibles, preguntasDisponibles) || other.preguntasDisponibles == preguntasDisponibles)&&(identical(other.preguntasVistas, preguntasVistas) || other.preguntasVistas == preguntasVistas)&&(identical(other.respuestasTotales, respuestasTotales) || other.respuestasTotales == respuestasTotales)&&(identical(other.respuestasCorrectas, respuestasCorrectas) || other.respuestasCorrectas == respuestasCorrectas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,nivel,peso,grupo,const DeepCollectionEquality().hash(_hijos),preguntasDisponibles,preguntasVistas,respuestasTotales,respuestasCorrectas);

@override
String toString() {
  return 'CatalogNode(id: $id, nombre: $nombre, nivel: $nivel, peso: $peso, grupo: $grupo, hijos: $hijos, preguntasDisponibles: $preguntasDisponibles, preguntasVistas: $preguntasVistas, respuestasTotales: $respuestasTotales, respuestasCorrectas: $respuestasCorrectas)';
}


}

/// @nodoc
abstract mixin class _$CatalogNodeCopyWith<$Res> implements $CatalogNodeCopyWith<$Res> {
  factory _$CatalogNodeCopyWith(_CatalogNode value, $Res Function(_CatalogNode) _then) = __$CatalogNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String nombre, String nivel, int? peso, String? grupo, List<CatalogNode> hijos, int preguntasDisponibles, int preguntasVistas, int respuestasTotales, int respuestasCorrectas
});




}
/// @nodoc
class __$CatalogNodeCopyWithImpl<$Res>
    implements _$CatalogNodeCopyWith<$Res> {
  __$CatalogNodeCopyWithImpl(this._self, this._then);

  final _CatalogNode _self;
  final $Res Function(_CatalogNode) _then;

/// Create a copy of CatalogNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? nivel = null,Object? peso = freezed,Object? grupo = freezed,Object? hijos = null,Object? preguntasDisponibles = null,Object? preguntasVistas = null,Object? respuestasTotales = null,Object? respuestasCorrectas = null,}) {
  return _then(_CatalogNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,nivel: null == nivel ? _self.nivel : nivel // ignore: cast_nullable_to_non_nullable
as String,peso: freezed == peso ? _self.peso : peso // ignore: cast_nullable_to_non_nullable
as int?,grupo: freezed == grupo ? _self.grupo : grupo // ignore: cast_nullable_to_non_nullable
as String?,hijos: null == hijos ? _self._hijos : hijos // ignore: cast_nullable_to_non_nullable
as List<CatalogNode>,preguntasDisponibles: null == preguntasDisponibles ? _self.preguntasDisponibles : preguntasDisponibles // ignore: cast_nullable_to_non_nullable
as int,preguntasVistas: null == preguntasVistas ? _self.preguntasVistas : preguntasVistas // ignore: cast_nullable_to_non_nullable
as int,respuestasTotales: null == respuestasTotales ? _self.respuestasTotales : respuestasTotales // ignore: cast_nullable_to_non_nullable
as int,respuestasCorrectas: null == respuestasCorrectas ? _self.respuestasCorrectas : respuestasCorrectas // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
