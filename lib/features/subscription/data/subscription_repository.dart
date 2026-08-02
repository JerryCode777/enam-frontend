import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../domain/subscription_models.dart';

/// Suscripciones y planes (Módulo 6 del SSD).
///
/// Es la fuente de verdad del **acceso** en la app: RN-03 v2 no tiene plan
/// gratuito, así que ya no se deduce nada de las estadísticas. Antes el acceso
/// salía de `preguntasRestantesHoy`, un campo del dashboard: si el usuario
/// entraba a una pantalla que no pedía estadísticas, la app no sabía qué plan
/// tenía.
abstract interface class SubscriptionRepository {
  /// La suscripción del usuario. **Nunca es nula**: todo usuario tiene una
  /// desde que se registra, aunque sea la prueba de 1 día.
  Future<Subscription> current();

  /// Manda al correo el enlace para completar la suscripción en la web.
  ///
  /// Es el camino de **Android**: la app no cobra ni enseña precios, manda un
  /// correo y el pago se cierra en el navegador. El enlace abre sesión sola, y
  /// por eso vive 15 minutos y sirve una sola vez.
  ///
  /// En iOS esto no se ofrece: allí la app solo enseña la dirección del sitio.
  /// Ver `widgets/opciones_de_pago.dart`.
  Future<void> enviarEnlaceDeSuscripcion(String email);

  /// Detiene la renovación. No quita el acceso ya pagado (RN-07).
  Future<void> cancelar();
}

class ApiSubscriptionRepository implements SubscriptionRepository {
  ApiSubscriptionRepository(this._client);

  final ApiClient _client;

  @override
  Future<Subscription> current() async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.subscription,
    );
    return Subscription.fromJson(data);
  }

  @override
  Future<void> enviarEnlaceDeSuscripcion(String email) async {
    // El correo va en el cuerpo porque el endpoint es público: lo comparte con
    // la web, donde quien lo usa todavía no tiene sesión. La respuesta es la
    // misma exista o no la cuenta.
    await _client.post<Map<String, dynamic>>(
      ApiEndpoints.activationLink,
      data: {'email': email},
    );
  }

  @override
  Future<void> cancelar() async {
    await _client.post<Map<String, dynamic>>(ApiEndpoints.cancelSubscription);
  }
}

/// El plan pagado, solo para poder mostrar su NOMBRE en «Mi suscripción».
///
/// La app no lista planes ni enseña precios: eso vive en la web y en el correo
/// (ver `widgets/opciones_de_pago.dart`). Lo único que necesita saber una app
/// es cómo se llama el plan que el usuario ya tiene y hasta cuándo le vale.
const _planPagado = Plan(
  id: 'mensual',
  nombre: 'Premium mensual',
  precioCentimos: 5900,
  duracionDias: 30,
  beneficios: [
    'Banco completo y práctica ilimitada',
    'Simulacros de 180 y nacionales con ranking',
    'Estadísticas completas y nota proyectada',
    'Modo offline por áreas',
  ],
);

const _planPrueba = Plan(
  id: 'prueba',
  nombre: 'Prueba de 1 día',
  precioCentimos: 0,
  duracionDias: 1,
  esGratuito: true,
  beneficios: ['Acceso completo por 24 horas'],
);

class MockSubscriptionRepository implements SubscriptionRepository {
  MockSubscriptionRepository({SubscriptionStatus? estado, this.inicioPrueba})
    : _estadoForzado = estado;

  /// Estado fijo, para revisar una pantalla concreta sin esperar 24 h. El
  /// atajo para elegirlo es el correo con el que se inicia sesión: ver
  /// `providers.dart`.
  final SubscriptionStatus? _estadoForzado;

  /// Cuándo arrancó el día de prueba, o `null` si el usuario aún no ha hecho su
  /// primera práctica (D-02).
  final DateTime? inicioPrueba;

  /// Cuánto dura la prueba (RN-03 v2).
  static const duracion = Duration(hours: 24);

  /// El estado que toca ahora mismo.
  ///
  /// Sin correo especial, sale del reloj: sin arrancar → `pruebaSinIniciar`;
  /// dentro de las 24 h → `prueba`; pasadas → `expirada`.
  SubscriptionStatus get estado {
    if (_cancelada) return SubscriptionStatus.cancelada;

    final forzado = _estadoForzado;
    if (forzado != null) return forzado;

    final inicio = inicioPrueba;
    if (inicio == null) return SubscriptionStatus.pruebaSinIniciar;

    return DateTime.now().isBefore(inicio.add(duracion))
        ? SubscriptionStatus.prueba
        : SubscriptionStatus.expirada;
  }

  @override
  Future<void> enviarEnlaceDeSuscripcion(String email) =>
      Future<void>.delayed(const Duration(milliseconds: 700));

  @override
  Future<void> cancelar() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    _cancelada = true;
  }

  /// Cancelar de verdad cambia el estado, también en el mock.
  ///
  /// Antes la pantalla solo sacaba un mensaje de "renovación cancelada" y no
  /// pasaba nada: se podía cancelar diez veces seguidas y la suscripción seguía
  /// activa. Un mock que no refleja el efecto deja el camino sin probar.
  bool _cancelada = false;

  @override
  Future<Subscription> current() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final ahora = DateTime.now();

    return switch (estado) {
      // La prueba sin empezar no tiene fecha de fin: el reloj arranca en la
      // primera práctica (D-02).
      SubscriptionStatus.pruebaSinIniciar => Subscription(
        id: 'sub-prueba',
        plan: _planPrueba,
        estado: estado,
        origen: SubscriptionOrigin.sistema,
        inicia: ahora,
      ),

      // Con el reloj de verdad se usan sus fechas; sin él (correo forzado) se
      // simula una prueba empezada hace 7 h.
      SubscriptionStatus.prueba => Subscription(
        id: 'sub-prueba',
        plan: _planPrueba,
        estado: estado,
        origen: SubscriptionOrigin.sistema,
        inicia: inicioPrueba ?? ahora.subtract(const Duration(hours: 7)),
        expira: (inicioPrueba ?? ahora.subtract(const Duration(hours: 7)))
            .add(duracion),
      ),

      SubscriptionStatus.activa || SubscriptionStatus.enGracia => Subscription(
        id: 'sub-mensual',
        plan: _planPagado,
        estado: estado,
        origen: SubscriptionOrigin.culqi,
        inicia: ahora.subtract(const Duration(days: 24)),
        expira: ahora.add(const Duration(days: 6)),
      ),

      SubscriptionStatus.expirada || SubscriptionStatus.cancelada =>
        Subscription(
          id: 'sub-prueba',
          plan: _planPrueba,
          estado: estado,
          origen: SubscriptionOrigin.sistema,
          inicia: inicioPrueba ?? ahora.subtract(const Duration(days: 3)),
          expira: inicioPrueba?.add(duracion) ??
              ahora.subtract(const Duration(days: 2)),
        ),
    };
  }
}
