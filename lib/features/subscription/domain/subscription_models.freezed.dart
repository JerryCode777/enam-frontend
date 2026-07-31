// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Plan {

 String get id; String get nombre;/// En céntimos, para no perder precisión con decimales.
 int get precioCentimos; String get moneda; int get duracionDias;/// Cierto **solo** para el plan de prueba. No existe un plan gratuito que
/// se pueda elegir (RN-03 v2).
 bool get esGratuito; List<String> get beneficios;
/// Create a copy of Plan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanCopyWith<Plan> get copyWith => _$PlanCopyWithImpl<Plan>(this as Plan, _$identity);

  /// Serializes this Plan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Plan&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.precioCentimos, precioCentimos) || other.precioCentimos == precioCentimos)&&(identical(other.moneda, moneda) || other.moneda == moneda)&&(identical(other.duracionDias, duracionDias) || other.duracionDias == duracionDias)&&(identical(other.esGratuito, esGratuito) || other.esGratuito == esGratuito)&&const DeepCollectionEquality().equals(other.beneficios, beneficios));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,precioCentimos,moneda,duracionDias,esGratuito,const DeepCollectionEquality().hash(beneficios));

@override
String toString() {
  return 'Plan(id: $id, nombre: $nombre, precioCentimos: $precioCentimos, moneda: $moneda, duracionDias: $duracionDias, esGratuito: $esGratuito, beneficios: $beneficios)';
}


}

/// @nodoc
abstract mixin class $PlanCopyWith<$Res>  {
  factory $PlanCopyWith(Plan value, $Res Function(Plan) _then) = _$PlanCopyWithImpl;
@useResult
$Res call({
 String id, String nombre, int precioCentimos, String moneda, int duracionDias, bool esGratuito, List<String> beneficios
});




}
/// @nodoc
class _$PlanCopyWithImpl<$Res>
    implements $PlanCopyWith<$Res> {
  _$PlanCopyWithImpl(this._self, this._then);

  final Plan _self;
  final $Res Function(Plan) _then;

/// Create a copy of Plan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? precioCentimos = null,Object? moneda = null,Object? duracionDias = null,Object? esGratuito = null,Object? beneficios = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,precioCentimos: null == precioCentimos ? _self.precioCentimos : precioCentimos // ignore: cast_nullable_to_non_nullable
as int,moneda: null == moneda ? _self.moneda : moneda // ignore: cast_nullable_to_non_nullable
as String,duracionDias: null == duracionDias ? _self.duracionDias : duracionDias // ignore: cast_nullable_to_non_nullable
as int,esGratuito: null == esGratuito ? _self.esGratuito : esGratuito // ignore: cast_nullable_to_non_nullable
as bool,beneficios: null == beneficios ? _self.beneficios : beneficios // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [Plan].
extension PlanPatterns on Plan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Plan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Plan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Plan value)  $default,){
final _that = this;
switch (_that) {
case _Plan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Plan value)?  $default,){
final _that = this;
switch (_that) {
case _Plan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nombre,  int precioCentimos,  String moneda,  int duracionDias,  bool esGratuito,  List<String> beneficios)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Plan() when $default != null:
return $default(_that.id,_that.nombre,_that.precioCentimos,_that.moneda,_that.duracionDias,_that.esGratuito,_that.beneficios);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nombre,  int precioCentimos,  String moneda,  int duracionDias,  bool esGratuito,  List<String> beneficios)  $default,) {final _that = this;
switch (_that) {
case _Plan():
return $default(_that.id,_that.nombre,_that.precioCentimos,_that.moneda,_that.duracionDias,_that.esGratuito,_that.beneficios);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nombre,  int precioCentimos,  String moneda,  int duracionDias,  bool esGratuito,  List<String> beneficios)?  $default,) {final _that = this;
switch (_that) {
case _Plan() when $default != null:
return $default(_that.id,_that.nombre,_that.precioCentimos,_that.moneda,_that.duracionDias,_that.esGratuito,_that.beneficios);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Plan extends Plan {
  const _Plan({required this.id, required this.nombre, required this.precioCentimos, this.moneda = 'PEN', required this.duracionDias, this.esGratuito = false, final  List<String> beneficios = const []}): _beneficios = beneficios,super._();
  factory _Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);

@override final  String id;
@override final  String nombre;
/// En céntimos, para no perder precisión con decimales.
@override final  int precioCentimos;
@override@JsonKey() final  String moneda;
@override final  int duracionDias;
/// Cierto **solo** para el plan de prueba. No existe un plan gratuito que
/// se pueda elegir (RN-03 v2).
@override@JsonKey() final  bool esGratuito;
 final  List<String> _beneficios;
@override@JsonKey() List<String> get beneficios {
  if (_beneficios is EqualUnmodifiableListView) return _beneficios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_beneficios);
}


/// Create a copy of Plan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanCopyWith<_Plan> get copyWith => __$PlanCopyWithImpl<_Plan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Plan&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.precioCentimos, precioCentimos) || other.precioCentimos == precioCentimos)&&(identical(other.moneda, moneda) || other.moneda == moneda)&&(identical(other.duracionDias, duracionDias) || other.duracionDias == duracionDias)&&(identical(other.esGratuito, esGratuito) || other.esGratuito == esGratuito)&&const DeepCollectionEquality().equals(other._beneficios, _beneficios));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,nombre,precioCentimos,moneda,duracionDias,esGratuito,const DeepCollectionEquality().hash(_beneficios));

@override
String toString() {
  return 'Plan(id: $id, nombre: $nombre, precioCentimos: $precioCentimos, moneda: $moneda, duracionDias: $duracionDias, esGratuito: $esGratuito, beneficios: $beneficios)';
}


}

/// @nodoc
abstract mixin class _$PlanCopyWith<$Res> implements $PlanCopyWith<$Res> {
  factory _$PlanCopyWith(_Plan value, $Res Function(_Plan) _then) = __$PlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String nombre, int precioCentimos, String moneda, int duracionDias, bool esGratuito, List<String> beneficios
});




}
/// @nodoc
class __$PlanCopyWithImpl<$Res>
    implements _$PlanCopyWith<$Res> {
  __$PlanCopyWithImpl(this._self, this._then);

  final _Plan _self;
  final $Res Function(_Plan) _then;

/// Create a copy of Plan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? precioCentimos = null,Object? moneda = null,Object? duracionDias = null,Object? esGratuito = null,Object? beneficios = null,}) {
  return _then(_Plan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,precioCentimos: null == precioCentimos ? _self.precioCentimos : precioCentimos // ignore: cast_nullable_to_non_nullable
as int,moneda: null == moneda ? _self.moneda : moneda // ignore: cast_nullable_to_non_nullable
as String,duracionDias: null == duracionDias ? _self.duracionDias : duracionDias // ignore: cast_nullable_to_non_nullable
as int,esGratuito: null == esGratuito ? _self.esGratuito : esGratuito // ignore: cast_nullable_to_non_nullable
as bool,beneficios: null == beneficios ? _self._beneficios : beneficios // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$Subscription {

 String get id; Plan get plan; SubscriptionStatus get estado; SubscriptionOrigin get origen; DateTime get inicia;/// `null` mientras la prueba no haya empezado a correr (D-02).
 DateTime? get expira;
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionCopyWith<Subscription> get copyWith => _$SubscriptionCopyWithImpl<Subscription>(this as Subscription, _$identity);

  /// Serializes this Subscription to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.origen, origen) || other.origen == origen)&&(identical(other.inicia, inicia) || other.inicia == inicia)&&(identical(other.expira, expira) || other.expira == expira));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,plan,estado,origen,inicia,expira);

@override
String toString() {
  return 'Subscription(id: $id, plan: $plan, estado: $estado, origen: $origen, inicia: $inicia, expira: $expira)';
}


}

/// @nodoc
abstract mixin class $SubscriptionCopyWith<$Res>  {
  factory $SubscriptionCopyWith(Subscription value, $Res Function(Subscription) _then) = _$SubscriptionCopyWithImpl;
@useResult
$Res call({
 String id, Plan plan, SubscriptionStatus estado, SubscriptionOrigin origen, DateTime inicia, DateTime? expira
});


$PlanCopyWith<$Res> get plan;

}
/// @nodoc
class _$SubscriptionCopyWithImpl<$Res>
    implements $SubscriptionCopyWith<$Res> {
  _$SubscriptionCopyWithImpl(this._self, this._then);

  final Subscription _self;
  final $Res Function(Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? plan = null,Object? estado = null,Object? origen = null,Object? inicia = null,Object? expira = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as Plan,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,origen: null == origen ? _self.origen : origen // ignore: cast_nullable_to_non_nullable
as SubscriptionOrigin,inicia: null == inicia ? _self.inicia : inicia // ignore: cast_nullable_to_non_nullable
as DateTime,expira: freezed == expira ? _self.expira : expira // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}
/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanCopyWith<$Res> get plan {
  
  return $PlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}


/// Adds pattern-matching-related methods to [Subscription].
extension SubscriptionPatterns on Subscription {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Subscription value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Subscription value)  $default,){
final _that = this;
switch (_that) {
case _Subscription():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Subscription value)?  $default,){
final _that = this;
switch (_that) {
case _Subscription() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  Plan plan,  SubscriptionStatus estado,  SubscriptionOrigin origen,  DateTime inicia,  DateTime? expira)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.plan,_that.estado,_that.origen,_that.inicia,_that.expira);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  Plan plan,  SubscriptionStatus estado,  SubscriptionOrigin origen,  DateTime inicia,  DateTime? expira)  $default,) {final _that = this;
switch (_that) {
case _Subscription():
return $default(_that.id,_that.plan,_that.estado,_that.origen,_that.inicia,_that.expira);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  Plan plan,  SubscriptionStatus estado,  SubscriptionOrigin origen,  DateTime inicia,  DateTime? expira)?  $default,) {final _that = this;
switch (_that) {
case _Subscription() when $default != null:
return $default(_that.id,_that.plan,_that.estado,_that.origen,_that.inicia,_that.expira);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Subscription extends Subscription {
  const _Subscription({required this.id, required this.plan, required this.estado, required this.origen, required this.inicia, this.expira}): super._();
  factory _Subscription.fromJson(Map<String, dynamic> json) => _$SubscriptionFromJson(json);

@override final  String id;
@override final  Plan plan;
@override final  SubscriptionStatus estado;
@override final  SubscriptionOrigin origen;
@override final  DateTime inicia;
/// `null` mientras la prueba no haya empezado a correr (D-02).
@override final  DateTime? expira;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionCopyWith<_Subscription> get copyWith => __$SubscriptionCopyWithImpl<_Subscription>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Subscription&&(identical(other.id, id) || other.id == id)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.origen, origen) || other.origen == origen)&&(identical(other.inicia, inicia) || other.inicia == inicia)&&(identical(other.expira, expira) || other.expira == expira));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,plan,estado,origen,inicia,expira);

@override
String toString() {
  return 'Subscription(id: $id, plan: $plan, estado: $estado, origen: $origen, inicia: $inicia, expira: $expira)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionCopyWith<$Res> implements $SubscriptionCopyWith<$Res> {
  factory _$SubscriptionCopyWith(_Subscription value, $Res Function(_Subscription) _then) = __$SubscriptionCopyWithImpl;
@override @useResult
$Res call({
 String id, Plan plan, SubscriptionStatus estado, SubscriptionOrigin origen, DateTime inicia, DateTime? expira
});


@override $PlanCopyWith<$Res> get plan;

}
/// @nodoc
class __$SubscriptionCopyWithImpl<$Res>
    implements _$SubscriptionCopyWith<$Res> {
  __$SubscriptionCopyWithImpl(this._self, this._then);

  final _Subscription _self;
  final $Res Function(_Subscription) _then;

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? plan = null,Object? estado = null,Object? origen = null,Object? inicia = null,Object? expira = freezed,}) {
  return _then(_Subscription(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as Plan,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as SubscriptionStatus,origen: null == origen ? _self.origen : origen // ignore: cast_nullable_to_non_nullable
as SubscriptionOrigin,inicia: null == inicia ? _self.inicia : inicia // ignore: cast_nullable_to_non_nullable
as DateTime,expira: freezed == expira ? _self.expira : expira // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

/// Create a copy of Subscription
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PlanCopyWith<$Res> get plan {
  
  return $PlanCopyWith<$Res>(_self.plan, (value) {
    return _then(_self.copyWith(plan: value));
  });
}
}

// dart format on
