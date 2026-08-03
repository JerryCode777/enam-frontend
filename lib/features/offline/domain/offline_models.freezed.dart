// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'offline_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PaqueteOffline {

 String get areaId; DateTime get generadoEn; List<Question> get preguntas; int get total;
/// Create a copy of PaqueteOffline
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaqueteOfflineCopyWith<PaqueteOffline> get copyWith => _$PaqueteOfflineCopyWithImpl<PaqueteOffline>(this as PaqueteOffline, _$identity);

  /// Serializes this PaqueteOffline to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaqueteOffline&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.generadoEn, generadoEn) || other.generadoEn == generadoEn)&&const DeepCollectionEquality().equals(other.preguntas, preguntas)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,areaId,generadoEn,const DeepCollectionEquality().hash(preguntas),total);

@override
String toString() {
  return 'PaqueteOffline(areaId: $areaId, generadoEn: $generadoEn, preguntas: $preguntas, total: $total)';
}


}

/// @nodoc
abstract mixin class $PaqueteOfflineCopyWith<$Res>  {
  factory $PaqueteOfflineCopyWith(PaqueteOffline value, $Res Function(PaqueteOffline) _then) = _$PaqueteOfflineCopyWithImpl;
@useResult
$Res call({
 String areaId, DateTime generadoEn, List<Question> preguntas, int total
});




}
/// @nodoc
class _$PaqueteOfflineCopyWithImpl<$Res>
    implements $PaqueteOfflineCopyWith<$Res> {
  _$PaqueteOfflineCopyWithImpl(this._self, this._then);

  final PaqueteOffline _self;
  final $Res Function(PaqueteOffline) _then;

/// Create a copy of PaqueteOffline
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? areaId = null,Object? generadoEn = null,Object? preguntas = null,Object? total = null,}) {
  return _then(_self.copyWith(
areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,generadoEn: null == generadoEn ? _self.generadoEn : generadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,preguntas: null == preguntas ? _self.preguntas : preguntas // ignore: cast_nullable_to_non_nullable
as List<Question>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [PaqueteOffline].
extension PaqueteOfflinePatterns on PaqueteOffline {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaqueteOffline value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaqueteOffline() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaqueteOffline value)  $default,){
final _that = this;
switch (_that) {
case _PaqueteOffline():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaqueteOffline value)?  $default,){
final _that = this;
switch (_that) {
case _PaqueteOffline() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String areaId,  DateTime generadoEn,  List<Question> preguntas,  int total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaqueteOffline() when $default != null:
return $default(_that.areaId,_that.generadoEn,_that.preguntas,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String areaId,  DateTime generadoEn,  List<Question> preguntas,  int total)  $default,) {final _that = this;
switch (_that) {
case _PaqueteOffline():
return $default(_that.areaId,_that.generadoEn,_that.preguntas,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String areaId,  DateTime generadoEn,  List<Question> preguntas,  int total)?  $default,) {final _that = this;
switch (_that) {
case _PaqueteOffline() when $default != null:
return $default(_that.areaId,_that.generadoEn,_that.preguntas,_that.total);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PaqueteOffline implements PaqueteOffline {
  const _PaqueteOffline({required this.areaId, required this.generadoEn, final  List<Question> preguntas = const [], this.total = 0}): _preguntas = preguntas;
  factory _PaqueteOffline.fromJson(Map<String, dynamic> json) => _$PaqueteOfflineFromJson(json);

@override final  String areaId;
@override final  DateTime generadoEn;
 final  List<Question> _preguntas;
@override@JsonKey() List<Question> get preguntas {
  if (_preguntas is EqualUnmodifiableListView) return _preguntas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_preguntas);
}

@override@JsonKey() final  int total;

/// Create a copy of PaqueteOffline
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaqueteOfflineCopyWith<_PaqueteOffline> get copyWith => __$PaqueteOfflineCopyWithImpl<_PaqueteOffline>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaqueteOfflineToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaqueteOffline&&(identical(other.areaId, areaId) || other.areaId == areaId)&&(identical(other.generadoEn, generadoEn) || other.generadoEn == generadoEn)&&const DeepCollectionEquality().equals(other._preguntas, _preguntas)&&(identical(other.total, total) || other.total == total));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,areaId,generadoEn,const DeepCollectionEquality().hash(_preguntas),total);

@override
String toString() {
  return 'PaqueteOffline(areaId: $areaId, generadoEn: $generadoEn, preguntas: $preguntas, total: $total)';
}


}

/// @nodoc
abstract mixin class _$PaqueteOfflineCopyWith<$Res> implements $PaqueteOfflineCopyWith<$Res> {
  factory _$PaqueteOfflineCopyWith(_PaqueteOffline value, $Res Function(_PaqueteOffline) _then) = __$PaqueteOfflineCopyWithImpl;
@override @useResult
$Res call({
 String areaId, DateTime generadoEn, List<Question> preguntas, int total
});




}
/// @nodoc
class __$PaqueteOfflineCopyWithImpl<$Res>
    implements _$PaqueteOfflineCopyWith<$Res> {
  __$PaqueteOfflineCopyWithImpl(this._self, this._then);

  final _PaqueteOffline _self;
  final $Res Function(_PaqueteOffline) _then;

/// Create a copy of PaqueteOffline
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? areaId = null,Object? generadoEn = null,Object? preguntas = null,Object? total = null,}) {
  return _then(_PaqueteOffline(
areaId: null == areaId ? _self.areaId : areaId // ignore: cast_nullable_to_non_nullable
as String,generadoEn: null == generadoEn ? _self.generadoEn : generadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,preguntas: null == preguntas ? _self._preguntas : preguntas // ignore: cast_nullable_to_non_nullable
as List<Question>,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ResultadoDeSync {

 int get aceptadas;/// Prácticas hechas sin señal que quedaron registradas en el servidor.
 int get sesionesCreadas; List<ConflictoDeSync> get conflictos;
/// Create a copy of ResultadoDeSync
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ResultadoDeSyncCopyWith<ResultadoDeSync> get copyWith => _$ResultadoDeSyncCopyWithImpl<ResultadoDeSync>(this as ResultadoDeSync, _$identity);

  /// Serializes this ResultadoDeSync to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ResultadoDeSync&&(identical(other.aceptadas, aceptadas) || other.aceptadas == aceptadas)&&(identical(other.sesionesCreadas, sesionesCreadas) || other.sesionesCreadas == sesionesCreadas)&&const DeepCollectionEquality().equals(other.conflictos, conflictos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,aceptadas,sesionesCreadas,const DeepCollectionEquality().hash(conflictos));

@override
String toString() {
  return 'ResultadoDeSync(aceptadas: $aceptadas, sesionesCreadas: $sesionesCreadas, conflictos: $conflictos)';
}


}

/// @nodoc
abstract mixin class $ResultadoDeSyncCopyWith<$Res>  {
  factory $ResultadoDeSyncCopyWith(ResultadoDeSync value, $Res Function(ResultadoDeSync) _then) = _$ResultadoDeSyncCopyWithImpl;
@useResult
$Res call({
 int aceptadas, int sesionesCreadas, List<ConflictoDeSync> conflictos
});




}
/// @nodoc
class _$ResultadoDeSyncCopyWithImpl<$Res>
    implements $ResultadoDeSyncCopyWith<$Res> {
  _$ResultadoDeSyncCopyWithImpl(this._self, this._then);

  final ResultadoDeSync _self;
  final $Res Function(ResultadoDeSync) _then;

/// Create a copy of ResultadoDeSync
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aceptadas = null,Object? sesionesCreadas = null,Object? conflictos = null,}) {
  return _then(_self.copyWith(
aceptadas: null == aceptadas ? _self.aceptadas : aceptadas // ignore: cast_nullable_to_non_nullable
as int,sesionesCreadas: null == sesionesCreadas ? _self.sesionesCreadas : sesionesCreadas // ignore: cast_nullable_to_non_nullable
as int,conflictos: null == conflictos ? _self.conflictos : conflictos // ignore: cast_nullable_to_non_nullable
as List<ConflictoDeSync>,
  ));
}

}


/// Adds pattern-matching-related methods to [ResultadoDeSync].
extension ResultadoDeSyncPatterns on ResultadoDeSync {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ResultadoDeSync value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ResultadoDeSync() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ResultadoDeSync value)  $default,){
final _that = this;
switch (_that) {
case _ResultadoDeSync():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ResultadoDeSync value)?  $default,){
final _that = this;
switch (_that) {
case _ResultadoDeSync() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int aceptadas,  int sesionesCreadas,  List<ConflictoDeSync> conflictos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ResultadoDeSync() when $default != null:
return $default(_that.aceptadas,_that.sesionesCreadas,_that.conflictos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int aceptadas,  int sesionesCreadas,  List<ConflictoDeSync> conflictos)  $default,) {final _that = this;
switch (_that) {
case _ResultadoDeSync():
return $default(_that.aceptadas,_that.sesionesCreadas,_that.conflictos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int aceptadas,  int sesionesCreadas,  List<ConflictoDeSync> conflictos)?  $default,) {final _that = this;
switch (_that) {
case _ResultadoDeSync() when $default != null:
return $default(_that.aceptadas,_that.sesionesCreadas,_that.conflictos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ResultadoDeSync extends ResultadoDeSync {
  const _ResultadoDeSync({this.aceptadas = 0, this.sesionesCreadas = 0, final  List<ConflictoDeSync> conflictos = const []}): _conflictos = conflictos,super._();
  factory _ResultadoDeSync.fromJson(Map<String, dynamic> json) => _$ResultadoDeSyncFromJson(json);

@override@JsonKey() final  int aceptadas;
/// Prácticas hechas sin señal que quedaron registradas en el servidor.
@override@JsonKey() final  int sesionesCreadas;
 final  List<ConflictoDeSync> _conflictos;
@override@JsonKey() List<ConflictoDeSync> get conflictos {
  if (_conflictos is EqualUnmodifiableListView) return _conflictos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_conflictos);
}


/// Create a copy of ResultadoDeSync
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ResultadoDeSyncCopyWith<_ResultadoDeSync> get copyWith => __$ResultadoDeSyncCopyWithImpl<_ResultadoDeSync>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ResultadoDeSyncToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ResultadoDeSync&&(identical(other.aceptadas, aceptadas) || other.aceptadas == aceptadas)&&(identical(other.sesionesCreadas, sesionesCreadas) || other.sesionesCreadas == sesionesCreadas)&&const DeepCollectionEquality().equals(other._conflictos, _conflictos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,aceptadas,sesionesCreadas,const DeepCollectionEquality().hash(_conflictos));

@override
String toString() {
  return 'ResultadoDeSync(aceptadas: $aceptadas, sesionesCreadas: $sesionesCreadas, conflictos: $conflictos)';
}


}

/// @nodoc
abstract mixin class _$ResultadoDeSyncCopyWith<$Res> implements $ResultadoDeSyncCopyWith<$Res> {
  factory _$ResultadoDeSyncCopyWith(_ResultadoDeSync value, $Res Function(_ResultadoDeSync) _then) = __$ResultadoDeSyncCopyWithImpl;
@override @useResult
$Res call({
 int aceptadas, int sesionesCreadas, List<ConflictoDeSync> conflictos
});




}
/// @nodoc
class __$ResultadoDeSyncCopyWithImpl<$Res>
    implements _$ResultadoDeSyncCopyWith<$Res> {
  __$ResultadoDeSyncCopyWithImpl(this._self, this._then);

  final _ResultadoDeSync _self;
  final $Res Function(_ResultadoDeSync) _then;

/// Create a copy of ResultadoDeSync
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aceptadas = null,Object? sesionesCreadas = null,Object? conflictos = null,}) {
  return _then(_ResultadoDeSync(
aceptadas: null == aceptadas ? _self.aceptadas : aceptadas // ignore: cast_nullable_to_non_nullable
as int,sesionesCreadas: null == sesionesCreadas ? _self.sesionesCreadas : sesionesCreadas // ignore: cast_nullable_to_non_nullable
as int,conflictos: null == conflictos ? _self._conflictos : conflictos // ignore: cast_nullable_to_non_nullable
as List<ConflictoDeSync>,
  ));
}


}


/// @nodoc
mixin _$ConflictoDeSync {

 String get questionId; String get motivo;
/// Create a copy of ConflictoDeSync
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConflictoDeSyncCopyWith<ConflictoDeSync> get copyWith => _$ConflictoDeSyncCopyWithImpl<ConflictoDeSync>(this as ConflictoDeSync, _$identity);

  /// Serializes this ConflictoDeSync to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConflictoDeSync&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.motivo, motivo) || other.motivo == motivo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,motivo);

@override
String toString() {
  return 'ConflictoDeSync(questionId: $questionId, motivo: $motivo)';
}


}

/// @nodoc
abstract mixin class $ConflictoDeSyncCopyWith<$Res>  {
  factory $ConflictoDeSyncCopyWith(ConflictoDeSync value, $Res Function(ConflictoDeSync) _then) = _$ConflictoDeSyncCopyWithImpl;
@useResult
$Res call({
 String questionId, String motivo
});




}
/// @nodoc
class _$ConflictoDeSyncCopyWithImpl<$Res>
    implements $ConflictoDeSyncCopyWith<$Res> {
  _$ConflictoDeSyncCopyWithImpl(this._self, this._then);

  final ConflictoDeSync _self;
  final $Res Function(ConflictoDeSync) _then;

/// Create a copy of ConflictoDeSync
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? questionId = null,Object? motivo = null,}) {
  return _then(_self.copyWith(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,motivo: null == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ConflictoDeSync].
extension ConflictoDeSyncPatterns on ConflictoDeSync {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConflictoDeSync value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConflictoDeSync() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConflictoDeSync value)  $default,){
final _that = this;
switch (_that) {
case _ConflictoDeSync():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConflictoDeSync value)?  $default,){
final _that = this;
switch (_that) {
case _ConflictoDeSync() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String questionId,  String motivo)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConflictoDeSync() when $default != null:
return $default(_that.questionId,_that.motivo);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String questionId,  String motivo)  $default,) {final _that = this;
switch (_that) {
case _ConflictoDeSync():
return $default(_that.questionId,_that.motivo);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String questionId,  String motivo)?  $default,) {final _that = this;
switch (_that) {
case _ConflictoDeSync() when $default != null:
return $default(_that.questionId,_that.motivo);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConflictoDeSync implements ConflictoDeSync {
  const _ConflictoDeSync({required this.questionId, this.motivo = ''});
  factory _ConflictoDeSync.fromJson(Map<String, dynamic> json) => _$ConflictoDeSyncFromJson(json);

@override final  String questionId;
@override@JsonKey() final  String motivo;

/// Create a copy of ConflictoDeSync
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConflictoDeSyncCopyWith<_ConflictoDeSync> get copyWith => __$ConflictoDeSyncCopyWithImpl<_ConflictoDeSync>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConflictoDeSyncToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConflictoDeSync&&(identical(other.questionId, questionId) || other.questionId == questionId)&&(identical(other.motivo, motivo) || other.motivo == motivo));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,questionId,motivo);

@override
String toString() {
  return 'ConflictoDeSync(questionId: $questionId, motivo: $motivo)';
}


}

/// @nodoc
abstract mixin class _$ConflictoDeSyncCopyWith<$Res> implements $ConflictoDeSyncCopyWith<$Res> {
  factory _$ConflictoDeSyncCopyWith(_ConflictoDeSync value, $Res Function(_ConflictoDeSync) _then) = __$ConflictoDeSyncCopyWithImpl;
@override @useResult
$Res call({
 String questionId, String motivo
});




}
/// @nodoc
class __$ConflictoDeSyncCopyWithImpl<$Res>
    implements _$ConflictoDeSyncCopyWith<$Res> {
  __$ConflictoDeSyncCopyWithImpl(this._self, this._then);

  final _ConflictoDeSync _self;
  final $Res Function(_ConflictoDeSync) _then;

/// Create a copy of ConflictoDeSync
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? questionId = null,Object? motivo = null,}) {
  return _then(_ConflictoDeSync(
questionId: null == questionId ? _self.questionId : questionId // ignore: cast_nullable_to_non_nullable
as String,motivo: null == motivo ? _self.motivo : motivo // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
