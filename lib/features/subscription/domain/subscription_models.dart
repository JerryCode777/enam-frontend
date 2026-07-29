import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_models.freezed.dart';
part 'subscription_models.g.dart';

/// Medio por el que se activó la suscripción (RF-26, RF-28).
@JsonEnum(fieldRename: FieldRename.snake)
enum SubscriptionOrigin {
  /// Cobro recurrente por la API de suscripciones de Culqi.
  culqi,

  /// Pago por Yape QR verificado a mano por un admin.
  manual,
}

@JsonEnum(fieldRename: FieldRename.snake)
enum SubscriptionStatus {
  activa,

  /// Falló el cobro pero sigue con acceso: 3 días de gracia (RF-27).
  enGracia,
  expirada,
  cancelada,
}

/// Un plan configurable desde el admin (RF-25).
@freezed
abstract class Plan with _$Plan {
  const factory Plan({
    required String id,
    required String nombre,

    /// En céntimos, para no perder precisión con decimales.
    required int precioCentimos,
    @Default('PEN') String moneda,
    required int duracionDias,
    @Default(false) bool esGratuito,
    @Default([]) List<String> beneficios,

    /// Límites del plan. Para free: `{"preguntas_dia": 20, "simulacros": 1}`.
    /// Es informativo para la UI; RN-03 exige que el servidor los valide.
    @Default({}) Map<String, dynamic> limites,
  }) = _Plan;

  const Plan._();

  factory Plan.fromJson(Map<String, dynamic> json) => _$PlanFromJson(json);

  double get precio => precioCentimos / 100;

  /// Precio formateado para mostrar: `S/ 49.00`.
  String get precioFormateado =>
      esGratuito ? 'Gratis' : 'S/ ${precio.toStringAsFixed(2)}';
}

@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    required String id,
    required Plan plan,
    required SubscriptionStatus estado,
    required SubscriptionOrigin origen,
    required DateTime inicia,
    required DateTime expira,
  }) = _Subscription;

  const Subscription._();

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  /// Si da acceso premium ahora mismo.
  ///
  /// Es solo para la UI. RN-03 dice que la validación real es del servidor: el
  /// contenido premium no se descarga a un cliente sin plan, así que la app
  /// nunca debe apoyarse solo en esto para mostrar contenido.
  bool get daAcceso =>
      (estado == SubscriptionStatus.activa ||
          estado == SubscriptionStatus.enGracia) &&
      DateTime.now().isBefore(expira);

  int get diasRestantes => expira.difference(DateTime.now()).inDays;

  bool get porExpirar => daAcceso && diasRestantes <= 7;
}
