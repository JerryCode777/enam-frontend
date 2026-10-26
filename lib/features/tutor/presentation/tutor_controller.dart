import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../data/tutor_repository.dart';
import '../domain/tutor_models.dart';

/// El interruptor de compilación (`--dart-define=TUTOR_ACTIVO=true`).
///
/// Es un provider y no la constante a secas para que las pruebas lo enciendan.
final tutorActivoProvider = Provider<bool>((ref) => AppConfig.tutorActivo);

final tutorRepositoryProvider = Provider<TutorRepository>((ref) {
  if (AppConfig.useMocks) return FakeTutorRepository();
  return ApiTutorRepository(ref.watch(apiClientProvider));
});

/// `GET /tutor/estado`, o `null` con el interruptor apagado.
///
/// Un fallo se lee como «no disponible»: un punto de entrada que lleva a un
/// error no ayuda a nadie, y el tutor no es imprescindible para estudiar.
final estadoDelServicioProvider = FutureProvider<EstadoDelServicio?>((
  ref,
) async {
  if (!ref.watch(tutorActivoProvider)) return null;
  try {
    return await ref.watch(tutorRepositoryProvider).estado();
  } on Failure {
    return null;
  }
});

/// Si se enseñan los puntos de entrada: el interruptor de la app **y** el del
/// servidor para esta cuenta (`disponible`).
final tutorVisibleProvider = Provider<bool>((ref) {
  return ref.watch(estadoDelServicioProvider).value?.disponible ?? false;
});

/// Una conversación con el tutor. Vive lo que vive la pantalla.
class TutorController extends Notifier<EstadoDelTutor> {
  StreamSubscription<EventoDelTutor>? _escucha;
  ContextoDelTutor? _contexto;

  /// Si el contexto ya viajó: el servidor lo usa con el primer mensaje.
  bool _contextoEnviado = false;
  var _locales = 0;

  @override
  EstadoDelTutor build() {
    ref.onDispose(() => _escucha?.cancel());
    // El estado puede llegar después de abrir la pantalla: el contador de la
    // prueba se toma de ahí mientras ninguna respuesta haya traído uno nuevo.
    ref.listen(estadoDelServicioProvider, (_, e) {
      final restantes = e.value?.restantesPrueba;
      if (restantes != null && state.restantesPrueba == null) {
        state = state.copyWith(restantesPrueba: restantes);
      }
    });
    final servicio = ref.read(estadoDelServicioProvider).value;
    return EstadoDelTutor(restantesPrueba: servicio?.restantesPrueba);
  }

  TutorRepository get _repo => ref.read(tutorRepositoryProvider);

  /// Con qué se abrió la pantalla. Se llama una vez, antes del primer mensaje.
  void iniciar(ContextoDelTutor contexto) => _contexto = contexto;

  /// El alumno manda un mensaje (escrito, sugerencia o respuesta rápida).
  void enviar(String texto, {TipoDeMensaje tipo = TipoDeMensaje.normal}) {
    final limpio = texto.trim();
    if (limpio.isEmpty || state.respondiendo || state.bloqueo != null) return;

    final alumno = MensajeDelTutor(
      id: _idLocal(),
      autor: AutorDelMensaje.alumno,
      texto: limpio,
    );
    _responder(previos: [...state.mensajes, alumno], texto: limpio, tipo: tipo);
  }

  /// «No entiendo»: un mensaje más, que el servidor contesta más simple.
  void noEntiendo(String explicacion) {
    final detalle = explicacion.trim();
    enviar(
      detalle.isEmpty ? 'No entendí esto.' : 'No entendí esto: $detalle',
      tipo: TipoDeMensaje.noEntiendo,
    );
  }

  /// Vuelve a pedir la última respuesta, que se cortó.
  void reintentar() {
    if (state.respondiendo || state.mensajes.isEmpty) return;
    final ultimo = state.mensajes.last;
    if (!ultimo.esDelTutor || ultimo.estado != EstadoDelMensaje.fallo) return;
    _responder(
      previos: state.mensajes.sublist(0, state.mensajes.length - 1),
      texto: '',
      tipo: TipoDeMensaje.reintento,
    );
  }

  /// 👍 / 👎. Tocar el que ya está marcado lo quita.
  Future<void> valorar(String mensajeId, bool util) async {
    final mensaje = state.mensajes.where((m) => m.id == mensajeId).firstOrNull;
    if (mensaje == null) return;
    final nuevo = mensaje.util == util ? null : util;
    _cambiar(mensajeId, (m) => m.copyWith(util: () => nuevo));
    try {
      await _repo.valorar(mensajeId, util: nuevo);
    } on Failure {
      // Vuelve como estaba: el pulgar marcado tiene que decir la verdad.
      _cambiar(mensajeId, (m) => m.copyWith(util: () => mensaje.util));
    }
  }

  void _responder({
    required List<MensajeDelTutor> previos,
    required String texto,
    required TipoDeMensaje tipo,
  }) {
    final idLocal = _idLocal();
    var idDelTutor = idLocal;
    state = state.copyWith(
      mensajes: [
        ...previos,
        MensajeDelTutor(
          id: idLocal,
          autor: AutorDelMensaje.tutor,
          texto: '',
          estado: EstadoDelMensaje.pensando,
        ),
      ],
    );

    final contexto = _contextoEnviado ? null : _contexto;
    _contextoEnviado = true;

    _escucha?.cancel();
    _escucha = _repo
        .enviar(
          mensaje: texto,
          sesionId: state.sesionId,
          tipo: tipo,
          contexto: contexto,
        )
        .listen(
          (evento) {
            switch (evento) {
              case InicioDeRespuesta(:final sesionId, :final mensajeId):
                state = state.copyWith(sesionId: sesionId);
                if (mensajeId.isNotEmpty) {
                  _cambiar(idDelTutor, (m) => m.copyWith(id: mensajeId));
                  idDelTutor = mensajeId;
                }
              case FaseDeRespuesta():
                _cambiar(
                  idDelTutor,
                  (m) => m.copyWith(fase: () => evento.texto),
                );
              case TrozoDeRespuesta(texto: final trozo):
                _cambiar(
                  idDelTutor,
                  (m) => m.copyWith(
                    texto: m.texto + trozo,
                    estado: EstadoDelMensaje.escribiendo,
                    fase: () => null,
                  ),
                );
              case FinDeRespuesta(:final mensajeId, :final restantesPrueba):
                _cambiar(
                  idDelTutor,
                  (m) => m.copyWith(
                    id: mensajeId,
                    estado: EstadoDelMensaje.listo,
                    fase: () => null,
                  ),
                );
                if (mensajeId != null) idDelTutor = mensajeId;
                if (restantesPrueba != null) {
                  state = state.copyWith(restantesPrueba: restantesPrueba);
                }
              case FalloDeRespuesta(:final mensaje):
                _fallar(idDelTutor, mensaje);
            }
          },
          onError: (Object error) {
            if (_bloqueoPor(error) case final bloqueo?) {
              // El mensaje del alumno no se respondió ni se cobró: se quita la
              // burbuja del tutor y queda el muro o el aviso en su lugar.
              state = EstadoDelTutor(
                mensajes: [
                  for (final m in state.mensajes)
                    if (m.id != idDelTutor) m,
                ],
                sesionId: state.sesionId,
                bloqueo: bloqueo,
                restantesPrueba: bloqueo == BloqueoDelTutor.gratisAgotado
                    ? 0
                    : state.restantesPrueba,
              );
              return;
            }
            _fallar(
              idDelTutor,
              error is Failure
                  ? error.message
                  : 'No pudimos hablar con el tutor. Inténtalo de nuevo.',
            );
          },
          onDone: () {
            // Sin `fin` ni `error`: la conexión se cayó. Lo que llegó se queda
            // (el servidor también lo guarda) y se puede reintentar.
            final m = state.mensajes
                .where((m) => m.id == idDelTutor)
                .firstOrNull;
            if (m != null && m.enCurso) {
              _fallar(idDelTutor, 'Se cortó la conexión con el tutor.');
            }
          },
        );
  }

  void _fallar(String id, String mensaje) => _cambiar(
    id,
    (m) => m.copyWith(
      estado: EstadoDelMensaje.fallo,
      error: mensaje,
      fase: () => null,
    ),
  );

  void _cambiar(String id, MensajeDelTutor Function(MensajeDelTutor) cambio) {
    state = state.copyWith(
      mensajes: [for (final m in state.mensajes) m.id == id ? cambio(m) : m],
    );
  }

  String _idLocal() => 'local-${_locales++}';
}

/// Los dos 403 del contrato que cierran el tutor.
BloqueoDelTutor? _bloqueoPor(Object error) {
  if (error is! ForbiddenFailure) return null;
  return switch ((error.code, error.details)) {
    ('FUNCION_PREMIUM', {'funcion': 'tutor'}) => BloqueoDelTutor.gratisAgotado,
    ('LIMITE_DIARIO', {'recurso': 'tutor'}) => BloqueoDelTutor.limiteDelDia,
    _ => null,
  };
}

final tutorControllerProvider =
    NotifierProvider.autoDispose<TutorController, EstadoDelTutor>(
      TutorController.new,
    );
