// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stats_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AreaPerformance {

 String get areaId; String get areaNombre; int get preguntasBlueprint; int get respondidas; int get correctas;
/// Create a copy of AreaPerformance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AreaPerformanceCopyWith<AreaPerformance> get copyWith => _$AreaPerformanceCopyWithImpl<AreaPerformance>(this as AreaPerformance, _$identity);

  /// Serializes this AreaPerformance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AreaPerformance&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.areaNombre, areaNombre) || other.areaNombre == areaNombre)&&(identical(other.preguntasBlueprint, preguntasBlueprint) || other.preguntasBlueprint == preguntasBlueprint)&&(identical(other.respondidas, respondidas) || other.respondidas == respondidas)&&(identical(other.correctas, correctas) || other.correctas == correctas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,areaId,areaNombre,preguntasBlueprint,respondidas,correctas);

@override
String toString() {
  return 'AreaPerformance(areaId: $areaId, areaNombre: $areaNombre, preguntasBlueprint: $preguntasBlueprint, respondidas: $respondidas, correctas: $correctas)';
}


}

/// @nodoc
abstract mixin class $AreaPerformanceCopyWith<$Res>  {
  factory $AreaPerformanceCopyWith(AreaPerformance value, $Res Function(AreaPerformance) _then) = _$AreaPerformanceCopyWithImpl;
@useResult
$Res call({
 String areaId, String areaNombre, int preguntasBlueprint, int respondidas, int correctas
});




}
/// @nodoc
class _$AreaPerformanceCopyWithImpl<$Res>
    implements $AreaPerformanceCopyWith<$Res> {
  _$AreaPerformanceCopyWithImpl(this._self, this._then);

  final AreaPerformance _self;
  final $Res Function(AreaPerformance) _then;

/// Create a copy of AreaPerformance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? areaId = null,Object? areaNombre = null,Object? preguntasBlueprint = null,Object? respondidas = null,Object? correctas = null,}) {
  return _then(_self.copyWith(
areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,areaNombre: null == areaNombre ? _self.areaNombre : areaNombre // ignore: cast_nullable_to_non_nullable
as String,preguntasBlueprint: null == preguntasBlueprint ? _self.preguntasBlueprint : preguntasBlueprint // ignore: cast_nullable_to_non_nullable
as int,respondidas: null == respondidas ? _self.respondidas : respondidas // ignore: cast_nullable_to_non_nullable
as int,correctas: null == correctas ? _self.correctas : correctas // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AreaPerformance].
extension AreaPerformancePatterns on AreaPerformance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AreaPerformance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AreaPerformance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AreaPerformance value)  $default,){
final _that = this;
switch (_that) {
case _AreaPerformance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AreaPerformance value)?  $default,){
final _that = this;
switch (_that) {
case _AreaPerformance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String areaId,  String areaNombre,  int preguntasBlueprint,  int respondidas,  int correctas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AreaPerformance() when $default != null:
return $default(_that.areaId,_that.areaNombre,_that.preguntasBlueprint,_that.respondidas,_that.correctas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String areaId,  String areaNombre,  int preguntasBlueprint,  int respondidas,  int correctas)  $default,) {final _that = this;
switch (_that) {
case _AreaPerformance():
return $default(_that.areaId,_that.areaNombre,_that.preguntasBlueprint,_that.respondidas,_that.correctas);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String areaId,  String areaNombre,  int preguntasBlueprint,  int respondidas,  int correctas)?  $default,) {final _that = this;
switch (_that) {
case _AreaPerformance() when $default != null:
return $default(_that.areaId,_that.areaNombre,_that.preguntasBlueprint,_that.respondidas,_that.correctas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AreaPerformance extends AreaPerformance {
  const _AreaPerformance({required this.areaId, required this.areaNombre, required this.preguntasBlueprint, this.respondidas = 0, this.correctas = 0}): super._();
  factory _AreaPerformance.fromJson(Map<String, dynamic> json) => _$AreaPerformanceFromJson(json);

@override final  String areaId;
@override final  String areaNombre;
@override final  int preguntasBlueprint;
@override@JsonKey() final  int respondidas;
@override@JsonKey() final  int correctas;

/// Create a copy of AreaPerformance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AreaPerformanceCopyWith<_AreaPerformance> get copyWith => __$AreaPerformanceCopyWithImpl<_AreaPerformance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AreaPerformanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AreaPerformance&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.areaNombre, areaNombre) || other.areaNombre == areaNombre)&&(identical(other.preguntasBlueprint, preguntasBlueprint) || other.preguntasBlueprint == preguntasBlueprint)&&(identical(other.respondidas, respondidas) || other.respondidas == respondidas)&&(identical(other.correctas, correctas) || other.correctas == correctas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,areaId,areaNombre,preguntasBlueprint,respondidas,correctas);

@override
String toString() {
  return 'AreaPerformance(areaId: $areaId, areaNombre: $areaNombre, preguntasBlueprint: $preguntasBlueprint, respondidas: $respondidas, correctas: $correctas)';
}


}

/// @nodoc
abstract mixin class _$AreaPerformanceCopyWith<$Res> implements $AreaPerformanceCopyWith<$Res> {
  factory _$AreaPerformanceCopyWith(_AreaPerformance value, $Res Function(_AreaPerformance) _then) = __$AreaPerformanceCopyWithImpl;
@override @useResult
$Res call({
 String areaId, String areaNombre, int preguntasBlueprint, int respondidas, int correctas
});




}
/// @nodoc
class __$AreaPerformanceCopyWithImpl<$Res>
    implements _$AreaPerformanceCopyWith<$Res> {
  __$AreaPerformanceCopyWithImpl(this._self, this._then);

  final _AreaPerformance _self;
  final $Res Function(_AreaPerformance) _then;

/// Create a copy of AreaPerformance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? areaId = null,Object? areaNombre = null,Object? preguntasBlueprint = null,Object? respondidas = null,Object? correctas = null,}) {
  return _then(_AreaPerformance(
areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,areaNombre: null == areaNombre ? _self.areaNombre : areaNombre // ignore: cast_nullable_to_non_nullable
as String,preguntasBlueprint: null == preguntasBlueprint ? _self.preguntasBlueprint : preguntasBlueprint // ignore: cast_nullable_to_non_nullable
as int,respondidas: null == respondidas ? _self.respondidas : respondidas // ignore: cast_nullable_to_non_nullable
as int,correctas: null == correctas ? _self.correctas : correctas // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GradePoint {

 DateTime get fecha; double get nota; String? get sessionId;
/// Create a copy of GradePoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GradePointCopyWith<GradePoint> get copyWith => _$GradePointCopyWithImpl<GradePoint>(this as GradePoint, _$identity);

  /// Serializes this GradePoint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GradePoint&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.nota, nota) || other.nota == nota)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fecha,nota,sessionId);

@override
String toString() {
  return 'GradePoint(fecha: $fecha, nota: $nota, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class $GradePointCopyWith<$Res>  {
  factory $GradePointCopyWith(GradePoint value, $Res Function(GradePoint) _then) = _$GradePointCopyWithImpl;
@useResult
$Res call({
 DateTime fecha, double nota, String? sessionId
});




}
/// @nodoc
class _$GradePointCopyWithImpl<$Res>
    implements $GradePointCopyWith<$Res> {
  _$GradePointCopyWithImpl(this._self, this._then);

  final GradePoint _self;
  final $Res Function(GradePoint) _then;

/// Create a copy of GradePoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fecha = null,Object? nota = null,Object? sessionId = freezed,}) {
  return _then(_self.copyWith(
fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,nota: null == nota ? _self.nota : nota // ignore: cast_nullable_to_non_nullable
as double,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [GradePoint].
extension GradePointPatterns on GradePoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GradePoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GradePoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GradePoint value)  $default,){
final _that = this;
switch (_that) {
case _GradePoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GradePoint value)?  $default,){
final _that = this;
switch (_that) {
case _GradePoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime fecha,  double nota,  String? sessionId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GradePoint() when $default != null:
return $default(_that.fecha,_that.nota,_that.sessionId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime fecha,  double nota,  String? sessionId)  $default,) {final _that = this;
switch (_that) {
case _GradePoint():
return $default(_that.fecha,_that.nota,_that.sessionId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime fecha,  double nota,  String? sessionId)?  $default,) {final _that = this;
switch (_that) {
case _GradePoint() when $default != null:
return $default(_that.fecha,_that.nota,_that.sessionId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GradePoint implements GradePoint {
  const _GradePoint({required this.fecha, required this.nota, this.sessionId});
  factory _GradePoint.fromJson(Map<String, dynamic> json) => _$GradePointFromJson(json);

@override final  DateTime fecha;
@override final  double nota;
@override final  String? sessionId;

/// Create a copy of GradePoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GradePointCopyWith<_GradePoint> get copyWith => __$GradePointCopyWithImpl<_GradePoint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GradePointToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GradePoint&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.nota, nota) || other.nota == nota)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,fecha,nota,sessionId);

@override
String toString() {
  return 'GradePoint(fecha: $fecha, nota: $nota, sessionId: $sessionId)';
}


}

/// @nodoc
abstract mixin class _$GradePointCopyWith<$Res> implements $GradePointCopyWith<$Res> {
  factory _$GradePointCopyWith(_GradePoint value, $Res Function(_GradePoint) _then) = __$GradePointCopyWithImpl;
@override @useResult
$Res call({
 DateTime fecha, double nota, String? sessionId
});




}
/// @nodoc
class __$GradePointCopyWithImpl<$Res>
    implements _$GradePointCopyWith<$Res> {
  __$GradePointCopyWithImpl(this._self, this._then);

  final _GradePoint _self;
  final $Res Function(_GradePoint) _then;

/// Create a copy of GradePoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fecha = null,Object? nota = null,Object? sessionId = freezed,}) {
  return _then(_GradePoint(
fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,nota: null == nota ? _self.nota : nota // ignore: cast_nullable_to_non_nullable
as double,sessionId: freezed == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$DashboardStats {

/// Nota proyectada (RN-04): promedio ponderado del % de acierto por área
/// usando los pesos del blueprint, en escala vigesimal.
///
/// SIEMPRE se muestra junto a la advertencia de que es una estimación.
 double get notaProyectada; List<AreaPerformance> get porArea; List<GradePoint> get evolucion; int get preguntasVistas; int get preguntasTotalesBanco; int get simulacrosCompletados;/// Preguntas que le quedan hoy a un usuario free (RN-03). `null` si es
/// premium (ilimitado).
 int? get preguntasRestantesHoy;
/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardStatsCopyWith<DashboardStats> get copyWith => _$DashboardStatsCopyWithImpl<DashboardStats>(this as DashboardStats, _$identity);

  /// Serializes this DashboardStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardStats&&(identical(other.notaProyectada, notaProyectada) || other.notaProyectada == notaProyectada)&&const DeepCollectionEquality().equals(other.porArea, porArea)&&const DeepCollectionEquality().equals(other.evolucion, evolucion)&&(identical(other.preguntasVistas, preguntasVistas) || other.preguntasVistas == preguntasVistas)&&(identical(other.preguntasTotalesBanco, preguntasTotalesBanco) || other.preguntasTotalesBanco == preguntasTotalesBanco)&&(identical(other.simulacrosCompletados, simulacrosCompletados) || other.simulacrosCompletados == simulacrosCompletados)&&(identical(other.preguntasRestantesHoy, preguntasRestantesHoy) || other.preguntasRestantesHoy == preguntasRestantesHoy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notaProyectada,const DeepCollectionEquality().hash(porArea),const DeepCollectionEquality().hash(evolucion),preguntasVistas,preguntasTotalesBanco,simulacrosCompletados,preguntasRestantesHoy);

@override
String toString() {
  return 'DashboardStats(notaProyectada: $notaProyectada, porArea: $porArea, evolucion: $evolucion, preguntasVistas: $preguntasVistas, preguntasTotalesBanco: $preguntasTotalesBanco, simulacrosCompletados: $simulacrosCompletados, preguntasRestantesHoy: $preguntasRestantesHoy)';
}


}

/// @nodoc
abstract mixin class $DashboardStatsCopyWith<$Res>  {
  factory $DashboardStatsCopyWith(DashboardStats value, $Res Function(DashboardStats) _then) = _$DashboardStatsCopyWithImpl;
@useResult
$Res call({
 double notaProyectada, List<AreaPerformance> porArea, List<GradePoint> evolucion, int preguntasVistas, int preguntasTotalesBanco, int simulacrosCompletados, int? preguntasRestantesHoy
});




}
/// @nodoc
class _$DashboardStatsCopyWithImpl<$Res>
    implements $DashboardStatsCopyWith<$Res> {
  _$DashboardStatsCopyWithImpl(this._self, this._then);

  final DashboardStats _self;
  final $Res Function(DashboardStats) _then;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? notaProyectada = null,Object? porArea = null,Object? evolucion = null,Object? preguntasVistas = null,Object? preguntasTotalesBanco = null,Object? simulacrosCompletados = null,Object? preguntasRestantesHoy = freezed,}) {
  return _then(_self.copyWith(
notaProyectada: null == notaProyectada ? _self.notaProyectada : notaProyectada // ignore: cast_nullable_to_non_nullable
as double,porArea: null == porArea ? _self.porArea : porArea // ignore: cast_nullable_to_non_nullable
as List<AreaPerformance>,evolucion: null == evolucion ? _self.evolucion : evolucion // ignore: cast_nullable_to_non_nullable
as List<GradePoint>,preguntasVistas: null == preguntasVistas ? _self.preguntasVistas : preguntasVistas // ignore: cast_nullable_to_non_nullable
as int,preguntasTotalesBanco: null == preguntasTotalesBanco ? _self.preguntasTotalesBanco : preguntasTotalesBanco // ignore: cast_nullable_to_non_nullable
as int,simulacrosCompletados: null == simulacrosCompletados ? _self.simulacrosCompletados : simulacrosCompletados // ignore: cast_nullable_to_non_nullable
as int,preguntasRestantesHoy: freezed == preguntasRestantesHoy ? _self.preguntasRestantesHoy : preguntasRestantesHoy // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardStats].
extension DashboardStatsPatterns on DashboardStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardStats value)  $default,){
final _that = this;
switch (_that) {
case _DashboardStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardStats value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double notaProyectada,  List<AreaPerformance> porArea,  List<GradePoint> evolucion,  int preguntasVistas,  int preguntasTotalesBanco,  int simulacrosCompletados,  int? preguntasRestantesHoy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
return $default(_that.notaProyectada,_that.porArea,_that.evolucion,_that.preguntasVistas,_that.preguntasTotalesBanco,_that.simulacrosCompletados,_that.preguntasRestantesHoy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double notaProyectada,  List<AreaPerformance> porArea,  List<GradePoint> evolucion,  int preguntasVistas,  int preguntasTotalesBanco,  int simulacrosCompletados,  int? preguntasRestantesHoy)  $default,) {final _that = this;
switch (_that) {
case _DashboardStats():
return $default(_that.notaProyectada,_that.porArea,_that.evolucion,_that.preguntasVistas,_that.preguntasTotalesBanco,_that.simulacrosCompletados,_that.preguntasRestantesHoy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double notaProyectada,  List<AreaPerformance> porArea,  List<GradePoint> evolucion,  int preguntasVistas,  int preguntasTotalesBanco,  int simulacrosCompletados,  int? preguntasRestantesHoy)?  $default,) {final _that = this;
switch (_that) {
case _DashboardStats() when $default != null:
return $default(_that.notaProyectada,_that.porArea,_that.evolucion,_that.preguntasVistas,_that.preguntasTotalesBanco,_that.simulacrosCompletados,_that.preguntasRestantesHoy);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DashboardStats extends DashboardStats {
  const _DashboardStats({required this.notaProyectada, final  List<AreaPerformance> porArea = const [], final  List<GradePoint> evolucion = const [], this.preguntasVistas = 0, this.preguntasTotalesBanco = 0, this.simulacrosCompletados = 0, this.preguntasRestantesHoy}): _porArea = porArea,_evolucion = evolucion,super._();
  factory _DashboardStats.fromJson(Map<String, dynamic> json) => _$DashboardStatsFromJson(json);

/// Nota proyectada (RN-04): promedio ponderado del % de acierto por área
/// usando los pesos del blueprint, en escala vigesimal.
///
/// SIEMPRE se muestra junto a la advertencia de que es una estimación.
@override final  double notaProyectada;
 final  List<AreaPerformance> _porArea;
@override@JsonKey() List<AreaPerformance> get porArea {
  if (_porArea is EqualUnmodifiableListView) return _porArea;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_porArea);
}

 final  List<GradePoint> _evolucion;
@override@JsonKey() List<GradePoint> get evolucion {
  if (_evolucion is EqualUnmodifiableListView) return _evolucion;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_evolucion);
}

@override@JsonKey() final  int preguntasVistas;
@override@JsonKey() final  int preguntasTotalesBanco;
@override@JsonKey() final  int simulacrosCompletados;
/// Preguntas que le quedan hoy a un usuario free (RN-03). `null` si es
/// premium (ilimitado).
@override final  int? preguntasRestantesHoy;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardStatsCopyWith<_DashboardStats> get copyWith => __$DashboardStatsCopyWithImpl<_DashboardStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DashboardStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardStats&&(identical(other.notaProyectada, notaProyectada) || other.notaProyectada == notaProyectada)&&const DeepCollectionEquality().equals(other._porArea, _porArea)&&const DeepCollectionEquality().equals(other._evolucion, _evolucion)&&(identical(other.preguntasVistas, preguntasVistas) || other.preguntasVistas == preguntasVistas)&&(identical(other.preguntasTotalesBanco, preguntasTotalesBanco) || other.preguntasTotalesBanco == preguntasTotalesBanco)&&(identical(other.simulacrosCompletados, simulacrosCompletados) || other.simulacrosCompletados == simulacrosCompletados)&&(identical(other.preguntasRestantesHoy, preguntasRestantesHoy) || other.preguntasRestantesHoy == preguntasRestantesHoy));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,notaProyectada,const DeepCollectionEquality().hash(_porArea),const DeepCollectionEquality().hash(_evolucion),preguntasVistas,preguntasTotalesBanco,simulacrosCompletados,preguntasRestantesHoy);

@override
String toString() {
  return 'DashboardStats(notaProyectada: $notaProyectada, porArea: $porArea, evolucion: $evolucion, preguntasVistas: $preguntasVistas, preguntasTotalesBanco: $preguntasTotalesBanco, simulacrosCompletados: $simulacrosCompletados, preguntasRestantesHoy: $preguntasRestantesHoy)';
}


}

/// @nodoc
abstract mixin class _$DashboardStatsCopyWith<$Res> implements $DashboardStatsCopyWith<$Res> {
  factory _$DashboardStatsCopyWith(_DashboardStats value, $Res Function(_DashboardStats) _then) = __$DashboardStatsCopyWithImpl;
@override @useResult
$Res call({
 double notaProyectada, List<AreaPerformance> porArea, List<GradePoint> evolucion, int preguntasVistas, int preguntasTotalesBanco, int simulacrosCompletados, int? preguntasRestantesHoy
});




}
/// @nodoc
class __$DashboardStatsCopyWithImpl<$Res>
    implements _$DashboardStatsCopyWith<$Res> {
  __$DashboardStatsCopyWithImpl(this._self, this._then);

  final _DashboardStats _self;
  final $Res Function(_DashboardStats) _then;

/// Create a copy of DashboardStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? notaProyectada = null,Object? porArea = null,Object? evolucion = null,Object? preguntasVistas = null,Object? preguntasTotalesBanco = null,Object? simulacrosCompletados = null,Object? preguntasRestantesHoy = freezed,}) {
  return _then(_DashboardStats(
notaProyectada: null == notaProyectada ? _self.notaProyectada : notaProyectada // ignore: cast_nullable_to_non_nullable
as double,porArea: null == porArea ? _self._porArea : porArea // ignore: cast_nullable_to_non_nullable
as List<AreaPerformance>,evolucion: null == evolucion ? _self._evolucion : evolucion // ignore: cast_nullable_to_non_nullable
as List<GradePoint>,preguntasVistas: null == preguntasVistas ? _self.preguntasVistas : preguntasVistas // ignore: cast_nullable_to_non_nullable
as int,preguntasTotalesBanco: null == preguntasTotalesBanco ? _self.preguntasTotalesBanco : preguntasTotalesBanco // ignore: cast_nullable_to_non_nullable
as int,simulacrosCompletados: null == simulacrosCompletados ? _self.simulacrosCompletados : simulacrosCompletados // ignore: cast_nullable_to_non_nullable
as int,preguntasRestantesHoy: freezed == preguntasRestantesHoy ? _self.preguntasRestantesHoy : preguntasRestantesHoy // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$RankingEntry {

 int get posicion; String get usuarioNombre; double get promedio; String? get universidad;/// Si esta fila es la del usuario que está mirando.
 bool get esUsuarioActual;/// Tiempo total, para el desempate de simulacros nacionales (RN-05).
 int? get tiempoTotalMs;
/// Create a copy of RankingEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RankingEntryCopyWith<RankingEntry> get copyWith => _$RankingEntryCopyWithImpl<RankingEntry>(this as RankingEntry, _$identity);

  /// Serializes this RankingEntry to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RankingEntry&&(identical(other.posicion, posicion) || other.posicion == posicion)&&(identical(other.usuarioNombre, usuarioNombre) || other.usuarioNombre == usuarioNombre)&&(identical(other.promedio, promedio) || other.promedio == promedio)&&(identical(other.universidad, universidad) || other.universidad == universidad)&&(identical(other.esUsuarioActual, esUsuarioActual) || other.esUsuarioActual == esUsuarioActual)&&(identical(other.tiempoTotalMs, tiempoTotalMs) || other.tiempoTotalMs == tiempoTotalMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,posicion,usuarioNombre,promedio,universidad,esUsuarioActual,tiempoTotalMs);

@override
String toString() {
  return 'RankingEntry(posicion: $posicion, usuarioNombre: $usuarioNombre, promedio: $promedio, universidad: $universidad, esUsuarioActual: $esUsuarioActual, tiempoTotalMs: $tiempoTotalMs)';
}


}

/// @nodoc
abstract mixin class $RankingEntryCopyWith<$Res>  {
  factory $RankingEntryCopyWith(RankingEntry value, $Res Function(RankingEntry) _then) = _$RankingEntryCopyWithImpl;
@useResult
$Res call({
 int posicion, String usuarioNombre, double promedio, String? universidad, bool esUsuarioActual, int? tiempoTotalMs
});




}
/// @nodoc
class _$RankingEntryCopyWithImpl<$Res>
    implements $RankingEntryCopyWith<$Res> {
  _$RankingEntryCopyWithImpl(this._self, this._then);

  final RankingEntry _self;
  final $Res Function(RankingEntry) _then;

/// Create a copy of RankingEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? posicion = null,Object? usuarioNombre = null,Object? promedio = null,Object? universidad = freezed,Object? esUsuarioActual = null,Object? tiempoTotalMs = freezed,}) {
  return _then(_self.copyWith(
posicion: null == posicion ? _self.posicion : posicion // ignore: cast_nullable_to_non_nullable
as int,usuarioNombre: null == usuarioNombre ? _self.usuarioNombre : usuarioNombre // ignore: cast_nullable_to_non_nullable
as String,promedio: null == promedio ? _self.promedio : promedio // ignore: cast_nullable_to_non_nullable
as double,universidad: freezed == universidad ? _self.universidad : universidad // ignore: cast_nullable_to_non_nullable
as String?,esUsuarioActual: null == esUsuarioActual ? _self.esUsuarioActual : esUsuarioActual // ignore: cast_nullable_to_non_nullable
as bool,tiempoTotalMs: freezed == tiempoTotalMs ? _self.tiempoTotalMs : tiempoTotalMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RankingEntry].
extension RankingEntryPatterns on RankingEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RankingEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RankingEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RankingEntry value)  $default,){
final _that = this;
switch (_that) {
case _RankingEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RankingEntry value)?  $default,){
final _that = this;
switch (_that) {
case _RankingEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int posicion,  String usuarioNombre,  double promedio,  String? universidad,  bool esUsuarioActual,  int? tiempoTotalMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RankingEntry() when $default != null:
return $default(_that.posicion,_that.usuarioNombre,_that.promedio,_that.universidad,_that.esUsuarioActual,_that.tiempoTotalMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int posicion,  String usuarioNombre,  double promedio,  String? universidad,  bool esUsuarioActual,  int? tiempoTotalMs)  $default,) {final _that = this;
switch (_that) {
case _RankingEntry():
return $default(_that.posicion,_that.usuarioNombre,_that.promedio,_that.universidad,_that.esUsuarioActual,_that.tiempoTotalMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int posicion,  String usuarioNombre,  double promedio,  String? universidad,  bool esUsuarioActual,  int? tiempoTotalMs)?  $default,) {final _that = this;
switch (_that) {
case _RankingEntry() when $default != null:
return $default(_that.posicion,_that.usuarioNombre,_that.promedio,_that.universidad,_that.esUsuarioActual,_that.tiempoTotalMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RankingEntry implements RankingEntry {
  const _RankingEntry({required this.posicion, required this.usuarioNombre, required this.promedio, this.universidad, this.esUsuarioActual = false, this.tiempoTotalMs});
  factory _RankingEntry.fromJson(Map<String, dynamic> json) => _$RankingEntryFromJson(json);

@override final  int posicion;
@override final  String usuarioNombre;
@override final  double promedio;
@override final  String? universidad;
/// Si esta fila es la del usuario que está mirando.
@override@JsonKey() final  bool esUsuarioActual;
/// Tiempo total, para el desempate de simulacros nacionales (RN-05).
@override final  int? tiempoTotalMs;

/// Create a copy of RankingEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RankingEntryCopyWith<_RankingEntry> get copyWith => __$RankingEntryCopyWithImpl<_RankingEntry>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RankingEntryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RankingEntry&&(identical(other.posicion, posicion) || other.posicion == posicion)&&(identical(other.usuarioNombre, usuarioNombre) || other.usuarioNombre == usuarioNombre)&&(identical(other.promedio, promedio) || other.promedio == promedio)&&(identical(other.universidad, universidad) || other.universidad == universidad)&&(identical(other.esUsuarioActual, esUsuarioActual) || other.esUsuarioActual == esUsuarioActual)&&(identical(other.tiempoTotalMs, tiempoTotalMs) || other.tiempoTotalMs == tiempoTotalMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,posicion,usuarioNombre,promedio,universidad,esUsuarioActual,tiempoTotalMs);

@override
String toString() {
  return 'RankingEntry(posicion: $posicion, usuarioNombre: $usuarioNombre, promedio: $promedio, universidad: $universidad, esUsuarioActual: $esUsuarioActual, tiempoTotalMs: $tiempoTotalMs)';
}


}

/// @nodoc
abstract mixin class _$RankingEntryCopyWith<$Res> implements $RankingEntryCopyWith<$Res> {
  factory _$RankingEntryCopyWith(_RankingEntry value, $Res Function(_RankingEntry) _then) = __$RankingEntryCopyWithImpl;
@override @useResult
$Res call({
 int posicion, String usuarioNombre, double promedio, String? universidad, bool esUsuarioActual, int? tiempoTotalMs
});




}
/// @nodoc
class __$RankingEntryCopyWithImpl<$Res>
    implements _$RankingEntryCopyWith<$Res> {
  __$RankingEntryCopyWithImpl(this._self, this._then);

  final _RankingEntry _self;
  final $Res Function(_RankingEntry) _then;

/// Create a copy of RankingEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? posicion = null,Object? usuarioNombre = null,Object? promedio = null,Object? universidad = freezed,Object? esUsuarioActual = null,Object? tiempoTotalMs = freezed,}) {
  return _then(_RankingEntry(
posicion: null == posicion ? _self.posicion : posicion // ignore: cast_nullable_to_non_nullable
as int,usuarioNombre: null == usuarioNombre ? _self.usuarioNombre : usuarioNombre // ignore: cast_nullable_to_non_nullable
as String,promedio: null == promedio ? _self.promedio : promedio // ignore: cast_nullable_to_non_nullable
as double,universidad: freezed == universidad ? _self.universidad : universidad // ignore: cast_nullable_to_non_nullable
as String?,esUsuarioActual: null == esUsuarioActual ? _self.esUsuarioActual : esUsuarioActual // ignore: cast_nullable_to_non_nullable
as bool,tiempoTotalMs: freezed == tiempoTotalMs ? _self.tiempoTotalMs : tiempoTotalMs // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
