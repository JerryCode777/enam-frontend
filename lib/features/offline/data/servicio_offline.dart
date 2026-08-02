import 'dart:async';

import '../../../core/domain/blueprint.dart';
import '../../../core/error/failure.dart';
import '../../session/data/session_repository.dart';
import '../../session/domain/session_models.dart';
import '../domain/offline_models.dart';
import 'almacen_offline.dart';
import 'offline_repository.dart';

/// Todo lo que la app hace para funcionar sin señal (M7 · RF-30 a RF-33).
///
/// Junta las tres piezas —el servidor, la base local y el cifrado— y decide el
/// orden en que ocurren las cosas. Las pantallas hablan con esto, nunca con la
/// base directamente.
///
/// ---
///
/// ## La reserva, y por qué existe
///
/// Descargar preguntas **no alcanza** para practicar sin conexión. El servidor
/// es quien crea las sesiones y quien elige sus preguntas
/// (`POST /sessions/practice`), así que una sesión inventada en el teléfono no
/// existiría para él: al reconectar no habría dónde meter las respuestas y el
/// estudio no contaría para las estadísticas ni para la racha.
///
/// La salida es preparar el terreno **mientras hay internet**: al descargar un
/// área se crea también una práctica de verdad y se guarda entera en el
/// teléfono. Sin señal, esa práctica ya tiene id del servidor y preguntas
/// conocidas, así que `POST /offline/sync` la reconoce y todo encaja.
///
/// Dos cuidados que esto obliga a tener:
///
/// 1. **No se reserva durante la prueba sin empezar.** Crear una sesión arranca
///    las 24 h (`IniciarRelojDePrueba` corre en *todas* las creaciones de
///    sesión). Reservar al descargar le quemaría el día a alguien que solo
///    estaba preparando el viaje. Lo decide quien llama, con [reservar].
/// 2. **Una reserva sin empezar no es «continuar donde quedaste».** El inicio
///    tiene que saltárselas o le ofrecería retomar algo que el usuario nunca
///    abrió; para eso está [idsDeReservasSinEmpezar].
class ServicioOffline {
  ServicioOffline({
    required AlmacenOffline almacen,
    required OfflineRepository remoto,
    required SessionRepository sesiones,
    required String usuarioId,
  }) : _almacen = almacen,
       _remoto = remoto,
       _sesiones = sesiones,
       _usuario = usuarioId;

  final AlmacenOffline _almacen;
  final OfflineRepository _remoto;
  final SessionRepository _sesiones;
  final String _usuario;

  /// Cuántas preguntas tiene la práctica que queda lista para el viaje.
  ///
  /// Veinte es lo que dura un trayecto en micro y lo que el diseño usa como
  /// práctica por defecto. Más preguntas no cuestan más descarga —el banco ya
  /// está bajado— pero sí más sesiones abiertas que cerrar.
  static const preguntasPorReserva = 20;

  // ---------------- Descargas ----------------

  /// Baja el área y la deja lista. Devuelve cuántas preguntas quedaron.
  ///
  /// Con [reservar] en `true` prepara además una práctica para usar sin señal.
  /// Si eso falla, **la descarga sigue siendo buena**: el banco ya está en el
  /// teléfono y sirve para corregir; lo que faltará es la práctica lista, y el
  /// siguiente intento con conexión la crea.
  Future<int> descargar(
    String areaId, {
    required bool reservar,
    void Function(int recibidos, int total)? progreso,
  }) async {
    final paquete = await _remoto.paquete(areaId, progreso: progreso);
    await _almacen.guardarPaquete(_usuario, paquete);

    if (reservar && !await tieneReservaDe(areaId)) {
      try {
        await reservarPractica(areaId);
      } on Failure {
        // Ni se reintenta ni se propaga: la descarga en sí funcionó.
      }
    }

    return paquete.total;
  }

  /// Quita el área del teléfono, con sus reservas sin empezar.
  ///
  /// Las prácticas **ya empezadas** se conservan aunque se borre el área: son
  /// trabajo del estudiante y sus respuestas todavía tienen que llegar al
  /// servidor. Borrarlas para liberar unos megas sería tirar eso.
  Future<void> eliminar(String areaId) async {
    await _almacen.borrarPaquete(_usuario, areaId);

    final reservas = await _almacen.sesiones(
      _usuario,
      estado: EstadoSesionLocal.reservada,
    );
    for (final reserva in reservas.where((s) => s.areaId == areaId)) {
      await _almacen.borrarSesion(_usuario, reserva.sesion.id);
    }
  }

  Future<List<ResumenDePaquete>> resumenes() => _almacen.resumenes(_usuario);

  Future<PaqueteOffline?> paqueteDe(String areaId) =>
      _almacen.paquete(_usuario, areaId);

  // ---------------- Reservas ----------------

  Future<bool> tieneReservaDe(String areaId) async {
    final reservas = await _almacen.sesiones(
      _usuario,
      estado: EstadoSesionLocal.reservada,
    );
    return reservas.any((s) => s.areaId == areaId);
  }

  /// Cuántas prácticas hay listas para usar sin señal.
  Future<int> cuantasReservas() async => (await _almacen.sesiones(
    _usuario,
    estado: EstadoSesionLocal.reservada,
  )).length;

  /// Crea en el servidor una práctica del área y la guarda entera.
  Future<void> reservarPractica(String areaId) async {
    final sesion = await _sesiones.startPractice(
      PracticeConfig(areaIds: [areaId], cantidadPreguntas: preguntasPorReserva),
    );

    await _almacen.guardarSesion(
      _usuario,
      areaId: areaId,
      estado: EstadoSesionLocal.reservada,
      sesion: sesion,
    );
  }

  /// Vuelve a dejar una práctica lista por cada área descargada que se quedó
  /// sin ninguna.
  ///
  /// Se llama al recuperar la señal: es el momento en que se puede hacer y el
  /// estudiante no está esperando nada. Silencioso a propósito —si falla, la
  /// próxima vez lo intenta otra vez— y **de una en una** por área, para no
  /// abrir diez sesiones de golpe en el servidor.
  Future<void> reponerReservas() async {
    final descargadas = await _almacen.resumenes(_usuario);
    final reservas = await _almacen.sesiones(
      _usuario,
      estado: EstadoSesionLocal.reservada,
    );
    final conReserva = {for (final r in reservas) r.areaId};

    for (final area in descargadas) {
      if (conReserva.contains(area.areaId)) continue;
      try {
        await reservarPractica(area.areaId);
      } on Failure {
        return; // Si el servidor no está para esto, tampoco lo estará para la
        // siguiente área.
      }
    }
  }

  /// Ids de las prácticas reservadas que el estudiante todavía no abrió.
  ///
  /// El inicio las esconde de «continuar donde quedaste»: son sesiones que
  /// existen en el servidor pero que, para quien usa la app, no han empezado.
  Future<Set<String>> idsDeReservasSinEmpezar() async {
    final reservas = await _almacen.sesiones(
      _usuario,
      estado: EstadoSesionLocal.reservada,
    );
    return {for (final r in reservas) r.sesion.id};
  }

  /// Toma una práctica reservada para empezarla sin conexión.
  ///
  /// Prefiere la del área pedida; si no hay, cualquiera, que es mejor que
  /// dejar al estudiante sin nada que hacer. Lanza [SinDescargasFailure] si no
  /// queda ninguna.
  Future<StudySession> tomarReserva({
    List<String> areasPreferidas = const [],
  }) async {
    final reservas = await _almacen.sesiones(
      _usuario,
      estado: EstadoSesionLocal.reservada,
    );
    if (reservas.isEmpty) throw const SinDescargasFailure();

    final elegida = reservas.firstWhere(
      (r) => areasPreferidas.contains(r.areaId),
      orElse: () => reservas.first,
    );

    await _almacen.guardarSesion(
      _usuario,
      areaId: elegida.areaId,
      estado: EstadoSesionLocal.enCurso,
      sesion: elegida.sesion,
      creadaEn: elegida.creadaEn,
    );

    return elegida.sesion;
  }

  // ---------------- Practicar sin señal ----------------

  Future<SesionLocal?> sesionLocal(String sesionId) =>
      _almacen.sesion(_usuario, sesionId);

  /// Las prácticas que el estudiante dejó a medias en el teléfono.
  Future<List<SesionLocal>> sesionesEnCurso() =>
      _almacen.sesiones(_usuario, estado: EstadoSesionLocal.enCurso);

  /// Cuántas respuestas de esa sesión esperan turno para viajar.
  ///
  /// Mientras haya alguna, la copia local está más al día que el servidor.
  Future<int> pendientesDe(String sesionId) async {
    final pendientes = await _almacen.pendientes(_usuario);
    return pendientes.where((r) => r.sesionId == sesionId).length;
  }

  /// Corrige una respuesta con las claves del paquete descargado.
  ///
  /// Si el área no está descargada —o la pregunta no está en el paquete—
  /// devuelve la respuesta **sin corregir** (`esCorrecta` en nulo) en vez de
  /// inventarse un resultado: el servidor la corregirá al sincronizar. Es
  /// preferible no decir nada a decir «fallaste» sin saberlo.
  Future<Answer> responderSinConexion(
    SesionLocal local, {
    required String preguntaId,
    String? opcionId,
    required int tiempoMs,
    bool marcada = false,
  }) async {
    final pregunta = local.sesion.preguntas.firstWhere(
      (p) => p.id == preguntaId,
      orElse: () => throw const NotFoundFailure(
        'Esa pregunta no está en la práctica descargada.',
      ),
    );

    final clave = await _claveDe(pregunta);
    final respuesta = Answer(
      questionId: preguntaId,
      optionId: opcionId,
      esCorrecta: clave == null || opcionId == null ? null : opcionId == clave,
      tiempoMs: tiempoMs,
      marcada: marcada,
      respondidaOffline: true,
    );

    // La sesión guardada se actualiza en el momento: si la app se cierra en el
    // bus, al volver a abrirla la práctica sigue por donde iba.
    final actualizada = local.sesion.copyWith(
      preguntas: await _conFeedback(local.sesion.preguntas, preguntaId),
      respuestas: {...local.sesion.respuestas, preguntaId: respuesta},
    );

    await _almacen.guardarSesion(
      _usuario,
      areaId: local.areaId,
      estado: EstadoSesionLocal.enCurso,
      sesion: actualizada,
      creadaEn: local.creadaEn,
    );

    await _almacen.encolar(_usuario, (
      sesionId: local.sesion.id,
      preguntaId: preguntaId,
      opcionId: opcionId,
      tiempoMs: tiempoMs,
      marcada: marcada,
      respondidaEn: DateTime.now(),
    ));

    return respuesta;
  }

  /// La opción correcta de una pregunta, según el paquete de su área.
  Future<String?> _claveDe(Question pregunta) async {
    // La que ya viene revelada dentro de la sesión gana: es la misma clave y
    // ahorra descifrar el paquete entero.
    final enLaSesion = pregunta.opciones
        .where((o) => o.esCorrecta == true)
        .firstOrNull;
    if (enLaSesion != null) return enLaSesion.id;

    final areaId = pregunta.areaId;
    if (areaId == null) return null;

    final paquete = await _almacen.paquete(_usuario, areaId);
    final delPaquete = paquete?.preguntas
        .where((p) => p.id == pregunta.id)
        .firstOrNull;

    return delPaquete?.opciones
        .where((o) => o.esCorrecta == true)
        .firstOrNull
        ?.id;
  }

  /// Pone la clave y la explicación en la pregunta respondida, que es lo que
  /// la pantalla de práctica muestra al corregir (RF-13).
  Future<List<Question>> _conFeedback(
    List<Question> preguntas,
    String preguntaId,
  ) async {
    final indice = preguntas.indexWhere((p) => p.id == preguntaId);
    if (indice == -1) return preguntas;

    final pregunta = preguntas[indice];
    final areaId = pregunta.areaId;
    if (areaId == null) return preguntas;

    final paquete = await _almacen.paquete(_usuario, areaId);
    final revelada = paquete?.preguntas
        .where((p) => p.id == preguntaId)
        .firstOrNull;
    if (revelada == null) return preguntas;

    return [
      for (var i = 0; i < preguntas.length; i++)
        if (i == indice)
          preguntas[i].copyWith(
            opciones: revelada.opciones,
            explicacion: revelada.explicacion ?? preguntas[i].explicacion,
            porcentajeAciertoGlobal: revelada.porcentajeAciertoGlobal,
          )
        else
          preguntas[i],
    ];
  }

  /// Cierra una práctica sin conexión: calcula la nota como la calcula el
  /// servidor y apunta que falta cerrarla de verdad.
  Future<StudySession> terminarSinConexion(SesionLocal local) async {
    final sesion = local.sesion;
    final terminada = sesion.copyWith(
      estado: SessionStatus.finalizada,
      finalizadaEn: DateTime.now(),
      nota: Blueprint.toVigesimal(
        sesion.correctas,
        total: sesion.totalPreguntas,
      ),
    );

    await _almacen.guardarSesion(
      _usuario,
      areaId: local.areaId,
      estado: EstadoSesionLocal.terminada,
      sesion: terminada,
      creadaEn: local.creadaEn,
    );
    await _almacen.marcarPorEnviar(_usuario, sesion.id, DateTime.now());

    return terminada;
  }

  // ---------------- Sincronización ----------------

  Future<int> cuantasPendientes() => _almacen.cuantasPendientes(_usuario);

  /// Manda lo que se hizo sin conexión (RF-32) y cierra lo que quedó abierto.
  ///
  /// Devuelve el resultado del servidor, o `null` si no había nada que mandar.
  ///
  /// Reglas:
  /// - Lo aceptado **y lo rechazado** se saca de la bandeja. Un conflicto no se
  ///   arregla reintentando —el servidor ya decidió que gana otra respuesta— y
  ///   reintentarlo dejaría la bandeja llena para siempre.
  /// - Si la petición falla por red, **no se toca nada**: se vuelve a intentar
  ///   cuando haya señal.
  Future<ResultadoDeSync?> sincronizar({bool reponerReservas = false}) async {
    final pendientes = await _almacen.pendientes(_usuario);

    ResultadoDeSync? resultado;
    if (pendientes.isNotEmpty) {
      resultado = await _remoto.sincronizar(pendientes);

      for (final sesionId in pendientes.map((r) => r.sesionId).toSet()) {
        await _almacen.quitarPendientes(
          _usuario,
          sesionId,
          pendientes
              .where((r) => r.sesionId == sesionId)
              .map((r) => r.preguntaId),
        );
      }
    }

    await _cerrarLoQueQuedoAbierto();

    // Con señal y con la bandeja vacía es el mejor momento para volver a dejar
    // preparado lo del próximo viaje.
    if (reponerReservas) await this.reponerReservas();

    return resultado;
  }

  /// Cierra en el servidor las prácticas que se terminaron sin señal.
  ///
  /// El envío va **después** de las respuestas y de una en una: cerrar antes de
  /// que lleguen las respuestas daría una nota calculada sobre lo que el
  /// servidor tenía, que es menos de lo que el estudiante respondió.
  Future<void> _cerrarLoQueQuedoAbierto() async {
    for (final sesionId in await _almacen.porEnviar(_usuario)) {
      try {
        final cerrada = await _sesiones.submit(sesionId);
        await _almacen.quitarPorEnviar(_usuario, sesionId);

        // Ya está en el servidor con su nota oficial: la copia local deja de
        // hacer falta y liberarla evita que la práctica aparezca dos veces.
        await _almacen.borrarSesion(_usuario, sesionId);
        _ultimaNotaSincronizada = cerrada.nota;
      } on NetworkFailure {
        return; // Sin señal: se reintenta en la próxima.
      } on TimeoutFailure {
        return;
      } on Failure {
        // La sesión ya no existe, o ya estaba cerrada. Insistir cada vez que
        // vuelva la señal no la va a arreglar.
        await _almacen.quitarPorEnviar(_usuario, sesionId);
      }
    }
  }

  double? _ultimaNotaSincronizada;

  /// La nota que puso el servidor al cerrar la última práctica sincronizada.
  double? get ultimaNotaSincronizada => _ultimaNotaSincronizada;

  /// Borra todo lo del usuario y su llave de cifrado. Al cerrar sesión.
  Future<void> olvidarTodo() => _almacen.olvidarTodo(_usuario);
}
