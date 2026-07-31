// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Plan _$PlanFromJson(Map<String, dynamic> json) => _Plan(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  precioCentimos: (json['precioCentimos'] as num).toInt(),
  moneda: json['moneda'] as String? ?? 'PEN',
  duracionDias: (json['duracionDias'] as num).toInt(),
  esGratuito: json['esGratuito'] as bool? ?? false,
  beneficios:
      (json['beneficios'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$PlanToJson(_Plan instance) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'precioCentimos': instance.precioCentimos,
  'moneda': instance.moneda,
  'duracionDias': instance.duracionDias,
  'esGratuito': instance.esGratuito,
  'beneficios': instance.beneficios,
};

_Subscription _$SubscriptionFromJson(Map<String, dynamic> json) =>
    _Subscription(
      id: json['id'] as String,
      plan: Plan.fromJson(json['plan'] as Map<String, dynamic>),
      estado: $enumDecode(_$SubscriptionStatusEnumMap, json['estado']),
      origen: $enumDecode(_$SubscriptionOriginEnumMap, json['origen']),
      inicia: DateTime.parse(json['inicia'] as String),
      expira: json['expira'] == null
          ? null
          : DateTime.parse(json['expira'] as String),
    );

Map<String, dynamic> _$SubscriptionToJson(_Subscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'plan': instance.plan,
      'estado': _$SubscriptionStatusEnumMap[instance.estado]!,
      'origen': _$SubscriptionOriginEnumMap[instance.origen]!,
      'inicia': instance.inicia.toIso8601String(),
      'expira': instance.expira?.toIso8601String(),
    };

const _$SubscriptionStatusEnumMap = {
  SubscriptionStatus.pruebaSinIniciar: 'prueba_sin_iniciar',
  SubscriptionStatus.prueba: 'prueba',
  SubscriptionStatus.activa: 'activa',
  SubscriptionStatus.enGracia: 'en_gracia',
  SubscriptionStatus.expirada: 'expirada',
  SubscriptionStatus.cancelada: 'cancelada',
};

const _$SubscriptionOriginEnumMap = {
  SubscriptionOrigin.sistema: 'sistema',
  SubscriptionOrigin.culqi: 'culqi',
  SubscriptionOrigin.manual: 'manual',
  SubscriptionOrigin.bot: 'bot',
};
