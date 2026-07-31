import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_models.freezed.dart';
part 'subscription_models.g.dart';

/// Medio por el que se activó la suscripción (RF-26, RF-28, RF-43).
@JsonEnum(fieldRename: FieldRename.snake)
enum SubscriptionOrigin {
  /// La prueba de 1 día, que se crea sola al registrarse.
  sistema,

  /// Cobro recurrente por la API de suscripciones de Culqi.
  culqi,

  /// Pago por Yape QR verificado a mano por un admin.
  manual,

  /// Activada desde el canal de WhatsApp (M10, RF-43).
  bot,
}

/// Estado de la suscripción (RN-03 v2, SSD-ENAM-002 §1).
///
/// **No hay plan gratuito permanente.** Todo usuario nace en
/// [pruebaSinIniciar] y termina en [expirada] si no paga.
@JsonEnum(fieldRename: FieldRename.snake)
enum SubscriptionStatus {
  /// Registrado, con el día de prueba sin consumir.
  ///
  /// `expira` viene en `null`: el reloj arranca en la primera práctica o
  /// simulacro, no al registrarse (D-02). Quien se registra un martes a las 11
  /// de la noche no quema su prueba durmiendo.
  pruebaSinIniciar,

  /// Las 24 h corriendo. Acceso **completo**, sin límites.
  prueba,

  /// Plan pagado vigente.
  activa,

  /// Falló el cobro pero conserva acceso 3 días (RF-27).
  enGracia,

  /// Se acabó. Sin acceso hasta que pague (D-01).
  expirada,

  cancelada,
}

/// Un plan de pago, configurable desde el admin (RF-25).
///
/// El plan de prueba nunca llega por `GET /plans`: no se elige, se recibe al
/// registrarse. Solo aparece dentro de la [Subscription] del usuario.
@freezed
abstract class Plan with _$Plan {
  const factory Plan({
    required String id,
    required String nombre,

    /// En céntimos, para no perder precisión con decimales.
    required int precioCentimos,
    @Default('PEN') String moneda,
    required int duracionDias,

    /// Cierto **solo** para el plan de prueba. No existe un plan gratuito que
    /// se pueda elegir (RN-03 v2).
    @Default(false) bool esGratuito,
    @Default([]) List<String> beneficios,
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

    /// `null` mientras la prueba no haya empezado a correr (D-02).
    DateTime? expira,
  }) = _Subscription;

  const Subscription._();

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  /// Si da acceso ahora mismo.
  ///
  /// Es solo para la UI. RN-03 dice que la validación real es del servidor: el
  /// contenido premium no se descarga a un cliente sin plan, así que la app
  /// nunca debe apoyarse solo en esto para mostrar contenido.
  ///
  /// [pruebaSinIniciar] da acceso **sin mirar la fecha**: no tiene fecha que
  /// mirar. Es la única forma correcta de leer un `expira` nulo.
  bool get daAcceso => switch (estado) {
    SubscriptionStatus.pruebaSinIniciar => true,
    SubscriptionStatus.prueba ||
    SubscriptionStatus.activa ||
    SubscriptionStatus.enGracia => expira == null || DateTime.now().isBefore(expira!),
    SubscriptionStatus.expirada || SubscriptionStatus.cancelada => false,
  };

  /// Si está en el día de prueba, haya empezado a correr o no.
  ///
  /// Importa para el bot (RF-42): estar en prueba **no** es tener un plan
  /// pagado vigente, así que se le puede vender a alguien que aún está
  /// probando en vez de responderle "ya tienes acceso" y perder la venta.
  bool get enPrueba =>
      estado == SubscriptionStatus.pruebaSinIniciar ||
      estado == SubscriptionStatus.prueba;

  /// Prueba concedida pero todavía sin consumir (D-02).
  bool get pruebaSinEmpezar => estado == SubscriptionStatus.pruebaSinIniciar;

  /// Plan pagado vigente. Lo que el bot considera "ya es cliente".
  bool get planPagadoVigente => daAcceso && !enPrueba;

  /// Sin acceso: la app queda bloqueada tras la pantalla de pago (D-01).
  bool get sinAcceso => !daAcceso;

  /// Lo que falta para perder el acceso. `null` si no hay fecha todavía.
  Duration? get restante {
    final fin = expira;
    if (fin == null) return null;
    final falta = fin.difference(DateTime.now());
    return falta.isNegative ? Duration.zero : falta;
  }

  int? get diasRestantes => restante?.inDays;

  /// Un plan de pago a punto de vencer. La prueba queda fuera a propósito: son
  /// 24 h, así que "por expirar" sería cierto desde el primer minuto.
  bool get porExpirar {
    final dias = diasRestantes;
    return daAcceso && !enPrueba && dias != null && dias <= 7;
  }
}
