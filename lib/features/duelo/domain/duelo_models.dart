import 'package:freezed_annotation/freezed_annotation.dart';

part 'duelo_models.freezed.dart';
part 'duelo_models.g.dart';

/// El contrato del modo duelo (SSD-ENAM-004 §6).
///
/// # Dos familias, y conviene no mezclarlas
///
///   - **REST** ([DueloDTO]) — la ficha del duelo. La usan las pantallas que
///     todavía no están jugando: elegir oponente, la sala de espera, el enlace.
///   - **Socket** ([MensajeDeDuelo]) — lo que llega por la línea abierta durante
///     la partida. Está escrito desde el punto de vista de quien lo recibe: `tu`
///     y `rival` cambian de significado según a quién se le mande.
///
/// # Por qué esto es una traducción y no una invención
///
/// Los nombres de los campos son los del backend, tal cual. Es la web la que ya
/// hizo el trabajo de decidir qué se necesita en pantalla, y este archivo es su
/// gemelo en Dart: si los dos clientes leen distinto el mismo JSON, el fallo
/// aparece en producción y en uno solo de los dos, que es la peor forma de
/// encontrarlo.

/// En qué punto está un duelo.
@JsonEnum(fieldRename: FieldRename.snake)
enum EstadoDuelo {
  esperando,
  enCurso,
  terminado,
  abandonado,
  caducado,

  /// Un estado que este cliente todavía no conoce.
  ///
  /// Existe por la misma razón que `SessionType.desconocido`: sin él, un estado
  /// nuevo en el servidor revienta la deserialización entera y la app se cae al
  /// abrir el duelo, que es el peor sitio donde enterarse.
  @JsonValue('__desconocido__')
  desconocido;

  bool get terminal =>
      this == terminado || this == abandonado || this == caducado;
}

/// Por qué puerta se creó el duelo.
@JsonEnum(fieldRename: FieldRename.snake)
enum OrigenDuelo {
  aleatorio,
  enlace,
  @JsonValue('__desconocido__')
  desconocido,
}

/// La ficha del duelo, tal como la devuelven los endpoints normales.
@freezed
abstract class DueloDTO with _$DueloDTO {
  const factory DueloDTO({
    required String id,
    @JsonKey(unknownEnumValue: EstadoDuelo.desconocido)
    required EstadoDuelo estado,
    @JsonKey(unknownEnumValue: OrigenDuelo.desconocido)
    required OrigenDuelo origen,

    /// Solo en los de enlace: el PIN de 6 dígitos.
    String? codigo,

    /// La URL lista para compartir, ya armada por el servidor.
    ///
    /// La compone el backend para que web y app no tengan cada una su forma de
    /// hacerlo: dos formas es una que se queda vieja.
    String? enlace,
    @Default(false) bool contraBot,
    @Default(false) bool completo,
    @Default(10) int totalPreguntas,

    /// Cómo se llama el otro, si ya hay otro.
    String? rival,

    /// Este duelo lo creó quien pregunta.
    ///
    /// Explícito y no deducido de que `rival` venga vacío: quien abre su propio
    /// enlace tiene que ver «este es tu reto, compártelo» y no «te retan».
    @Default(false) bool esTuyo,
    DateTime? expiraEn,

    /// De qué duelo es la revancha, si lo es (RF-61).
    String? revanchaDe,

    /// Cuánto falta para poder pedir el bot. 0 si ya se puede.
    @Default(0) int faltanParaBotSegundos,
  }) = _DueloDTO;

  factory DueloDTO.fromJson(Map<String, dynamic> json) =>
      _$DueloDTOFromJson(json);
}

/// El pase diario de quien no tiene plan (RF-65).
///
/// Son **dos** campos y no un número porque «no puedes jugar» significa dos
/// cosas y la pantalla dice cosas distintas:
///
///   - `activo: false` — el pase está apagado, o esta persona tiene plan. No se
///     enseña nada.
///   - `activo: true` con `disponible: false` — le toca, y ya lo gastó hoy. El
///     botón se queda a la vista pero apagado, con «vuelve mañana».
///
/// Con un solo número las dos situaciones eran indistinguibles, y el botón
/// desaparecía después de jugar: quien lo usaba no volvía a saber que existía.
@freezed
abstract class PaseDeDuelo with _$PaseDeDuelo {
  const factory PaseDeDuelo({
    @Default(false) bool activo,
    @Default(false) bool disponible,
    @Default(0) int restantes,
  }) = _PaseDeDuelo;

  factory PaseDeDuelo.fromJson(Map<String, dynamic> json) =>
      _$PaseDeDueloFromJson(json);
}

/// El permiso de un solo uso para abrir el socket.
///
/// Hace falta porque **no se puede mandar la cabecera `Authorization` al abrir
/// un WebSocket**. Así que la sesión se canjea por esto, que vive 30 segundos y
/// vale una vez, y viaja en la URL.
///
/// La URL viene armada desde el servidor —con `ws://` o `wss://` según toque—
/// para que el cliente no tenga que adivinar el esquema.
@freezed
abstract class TicketDeDuelo with _$TicketDeDuelo {
  const factory TicketDeDuelo({
    required String ticket,
    required DateTime expira,
    required String url,
  }) = _TicketDeDuelo;

  factory TicketDeDuelo.fromJson(Map<String, dynamic> json) =>
      _$TicketDeDueloFromJson(json);
}

// ---------------------------------------------------------------------------
// Lo que viaja por el socket
// ---------------------------------------------------------------------------

/// Cómo le fue a alguien con una pregunta, para la fila de puntos.
///
/// La cadena vacía es «todavía no ha contestado», y del rival llegan todas
/// vacías cuando el marcador está oculto: se ve cuántas respondió, no cómo le
/// fue.
enum ResultadoPorPregunta { acierto, fallo, enBlanco, sinContestar }

ResultadoPorPregunta _resultadoDesde(String? valor) => switch (valor) {
  'acierto' => ResultadoPorPregunta.acierto,
  'fallo' => ResultadoPorPregunta.fallo,
  'en_blanco' => ResultadoPorPregunta.enBlanco,
  _ => ResultadoPorPregunta.sinContestar,
};

/// Un participante visto desde quien recibe el mensaje.
///
/// `aciertos` viene en `null` para el rival mientras la partida no termina, y no
/// es un descuido del backend: es la regla que mantiene la tensión. Sabes que va
/// más rápido que tú (`respondidas`), no que va ganando. Por eso es `int?` y no
/// `int` — un cero significaría «va fallando todo».
@freezed
abstract class LadoDuelo with _$LadoDuelo {
  const factory LadoDuelo({
    @Default('') String nombre,
    @Default(false) bool esBot,
    @Default(0) int respondidas,
    int? aciertos,
    @Default(true) bool conectado,
    @Default(<ResultadoPorPregunta>[]) List<ResultadoPorPregunta> resultados,
  }) = _LadoDuelo;

  factory LadoDuelo.fromJson(Map<String, dynamic> json) => LadoDuelo(
    nombre: json['nombre'] as String? ?? '',
    esBot: json['esBot'] as bool? ?? false,
    respondidas: json['respondidas'] as int? ?? 0,
    aciertos: json['aciertos'] as int?,
    conectado: json['conectado'] as bool? ?? true,
    resultados: (json['resultados'] as List<dynamic>? ?? const [])
        .map((r) => _resultadoDesde(r as String?))
        .toList(),
  );
}

/// El estado de la partida que hace falta para pintar la cabecera.
@freezed
abstract class EstadoDeLaPartida with _$EstadoDeLaPartida {
  const factory EstadoDeLaPartida({
    required String id,
    required EstadoDuelo estado,
    @Default(10) int totalPreguntas,
    required LadoDuelo tu,
    required LadoDuelo rival,

    /// El bot es de pago para quien recibe esto (RF-65).
    ///
    /// Es el caso del duelo diario gratuito: la oferta se enseña, apagada.
    /// Viene con el nombre de la consecuencia y no del motivo, porque es lo que
    /// la pantalla tiene que hacer con él.
    @Default(false) bool botBloqueado,
  }) = _EstadoDeLaPartida;

  factory EstadoDeLaPartida.fromJson(Map<String, dynamic> json) =>
      EstadoDeLaPartida(
        id: json['id'] as String? ?? '',
        estado: _estadoDesde(json['estado'] as String?),
        totalPreguntas: json['totalPreguntas'] as int? ?? 10,
        tu: LadoDuelo.fromJson(
          (json['tu'] as Map<String, dynamic>?) ?? const {},
        ),
        rival: LadoDuelo.fromJson(
          (json['rival'] as Map<String, dynamic>?) ?? const {},
        ),
        botBloqueado: json['botBloqueado'] as bool? ?? false,
      );
}

EstadoDuelo _estadoDesde(String? valor) => switch (valor) {
  'esperando' => EstadoDuelo.esperando,
  'en_curso' => EstadoDuelo.enCurso,
  'terminado' => EstadoDuelo.terminado,
  'abandonado' => EstadoDuelo.abandonado,
  'caducado' => EstadoDuelo.caducado,
  _ => EstadoDuelo.desconocido,
};

/// Una alternativa, sin nada que revele la clave.
@freezed
abstract class OpcionDuelo with _$OpcionDuelo {
  const factory OpcionDuelo({required String id, required String texto}) =
      _OpcionDuelo;

  factory OpcionDuelo.fromJson(Map<String, dynamic> json) =>
      _$OpcionDueloFromJson(json);
}

/// Una pregunta abierta.
///
/// Va sin la clave y sin la explicación: se aplica la vista de examen igual que
/// en un simulacro en curso (RF-16). Mandarlas sería regalar el duelo a quien
/// mire la respuesta de red.
@freezed
abstract class PreguntaEnJuego with _$PreguntaEnJuego {
  const factory PreguntaEnJuego({
    required int orden,
    @Default(10) int totalPreguntas,
    @Default('') String enunciado,
    @Default(<OpcionDuelo>[]) List<OpcionDuelo> opciones,

    /// La hora exacta a la que se cierra. **Es el reloj.**
    ///
    /// Absoluta y no «te quedan 20 s» a propósito: con los segundos restantes,
    /// el retraso de la red se convierte en ventaja para quien tenga mejor
    /// conexión. Con la hora de cierre, los dos cuentan contra el mismo
    /// instante.
    required DateTime cierraEn,
    @Default(30) int segundos,
  }) = _PreguntaEnJuego;

  factory PreguntaEnJuego.fromJson(Map<String, dynamic> json) =>
      _$PreguntaEnJuegoFromJson(json);
}

/// El cierre de una pregunta.
@freezed
abstract class ResultadoDePregunta with _$ResultadoDePregunta {
  const factory ResultadoDePregunta({
    @Default(0) int orden,
    @Default('') String opcionCorrectaId,
    @Default('') String explicacion,
    String? tuOpcionId,
    @Default(false) bool acertaste,
    @Default(0) int tuTiempoMs,
    @Default(0) int tusAciertos,

    /// Que contestó, no si acertó.
    @Default(false) bool rivalRespondio,
    @Default(0) int rivalRespondidas,
    @Default(0) int siguienteEnMs,
    @Default(false) bool esUltima,
  }) = _ResultadoDePregunta;

  factory ResultadoDePregunta.fromJson(Map<String, dynamic> json) =>
      _$ResultadoDePreguntaFromJson(json);
}

/// Cómo le fue a alguien con una pregunta, en la revisión final.
///
/// Son tres y no dos: **no responder no es fallar**. La diferencia se ve al
/// abandonar —la partida se corta y las preguntas que quedan no llegan a
/// abrirse— y pintarlas como fallo hacía creer que se fallaron preguntas que
/// nadie vio.
enum EstadoDeRespuesta { acierto, fallo, enBlanco }

EstadoDeRespuesta _estadoDeRespuestaDesde(String? valor) => switch (valor) {
  'acierto' => EstadoDeRespuesta.acierto,
  'fallo' => EstadoDeRespuesta.fallo,
  _ => EstadoDeRespuesta.enBlanco,
};

@freezed
abstract class OpcionRevisada with _$OpcionRevisada {
  const factory OpcionRevisada({
    required String id,
    required String texto,
    @Default(false) bool esCorrecta,
  }) = _OpcionRevisada;

  factory OpcionRevisada.fromJson(Map<String, dynamic> json) =>
      _$OpcionRevisadaFromJson(json);
}

@freezed
abstract class PreguntaRevisada with _$PreguntaRevisada {
  const factory PreguntaRevisada({
    required int orden,
    @Default('') String enunciado,
    @Default(<OpcionRevisada>[]) List<OpcionRevisada> opciones,
    @Default('') String explicacion,
    String? tuOpcionId,
    @Default(false) bool acertaste,
    String? rivalOpcionId,
    @Default(false) bool rivalAcerto,
    @Default(EstadoDeRespuesta.enBlanco) EstadoDeRespuesta tuEstado,
    @Default(EstadoDeRespuesta.enBlanco) EstadoDeRespuesta rivalEstado,
  }) = _PreguntaRevisada;

  factory PreguntaRevisada.fromJson(Map<String, dynamic> json) =>
      PreguntaRevisada(
        orden: json['orden'] as int? ?? 0,
        enunciado: json['enunciado'] as String? ?? '',
        opciones: (json['opciones'] as List<dynamic>? ?? const [])
            .map((o) => OpcionRevisada.fromJson(o as Map<String, dynamic>))
            .toList(),
        explicacion: json['explicacion'] as String? ?? '',
        tuOpcionId: json['tuOpcionId'] as String?,
        acertaste: json['acertaste'] as bool? ?? false,
        rivalOpcionId: json['rivalOpcionId'] as String?,
        rivalAcerto: json['rivalAcerto'] as bool? ?? false,
        tuEstado: _estadoDeRespuestaDesde(json['tuEstado'] as String?),
        rivalEstado: _estadoDeRespuestaDesde(json['rivalEstado'] as String?),
      );
}

/// Cómo acabó el duelo para quien recibe el mensaje.
enum Desenlace { ganaste, perdiste, empate }

Desenlace _desenlaceDesde(String? valor) => switch (valor) {
  'ganaste' => Desenlace.ganaste,
  'perdiste' => Desenlace.perdiste,
  _ => Desenlace.empate,
};

@freezed
abstract class FinalDeDuelo with _$FinalDeDuelo {
  const factory FinalDeDuelo({
    @Default(Desenlace.empate) Desenlace desenlace,
    @Default(0) int tusAciertos,
    @Default(0) int rivalAciertos,
    @Default(0) double tuNota,
    @Default(0) double rivalNota,
    @Default(0) int tuTiempoTotalMs,
    @Default(0) int rivalTiempoTotalMs,

    /// El rival se fue y por eso ganaste. Cambia el texto: «ganaste» a secas
    /// cuando el otro abandonó se lee como una burla.
    @Default(false) bool porAbandono,

    /// Se desempató por tiempo. Merece decirse: es la parte que sorprende.
    @Default(false) bool porTiempo,

    /// Se jugó con el duelo diario gratuito (RF-65).
    ///
    /// Viene explícito y no se deduce de que `revision` llegue vacía: deducirlo
    /// funcionaría hoy y mentiría el día que la revisión falte por otro motivo.
    @Default(false) bool conPaseGratis,
    @Default(<PreguntaRevisada>[]) List<PreguntaRevisada> revision,
  }) = _FinalDeDuelo;

  factory FinalDeDuelo.fromJson(Map<String, dynamic> json) => FinalDeDuelo(
    desenlace: _desenlaceDesde(json['desenlace'] as String?),
    tusAciertos: json['tusAciertos'] as int? ?? 0,
    rivalAciertos: json['rivalAciertos'] as int? ?? 0,
    tuNota: (json['tuNota'] as num?)?.toDouble() ?? 0,
    rivalNota: (json['rivalNota'] as num?)?.toDouble() ?? 0,
    tuTiempoTotalMs: json['tuTiempoTotalMs'] as int? ?? 0,
    rivalTiempoTotalMs: json['rivalTiempoTotalMs'] as int? ?? 0,
    porAbandono: json['porAbandono'] as bool? ?? false,
    porTiempo: json['porTiempo'] as bool? ?? false,
    conPaseGratis: json['conPaseGratis'] as bool? ?? false,
    revision: (json['revision'] as List<dynamic>? ?? const [])
        .map((p) => PreguntaRevisada.fromJson(p as Map<String, dynamic>))
        .toList(),
  );
}

/// Cuánto se lleva esperando en la cola.
@freezed
abstract class EsperaDeDuelo with _$EsperaDeDuelo {
  const factory EsperaDeDuelo({
    @Default(0) int esperandoSegundos,
    @Default(0) int faltanSegundos,
    String? codigo,
    DateTime? expiraEn,
  }) = _EsperaDeDuelo;

  factory EsperaDeDuelo.fromJson(Map<String, dynamic> json) =>
      _$EsperaDeDueloFromJson(json);
}

/// Los tipos de mensaje que manda el servidor.
///
/// `desconocido` no es un descuido: un tipo nuevo en el servidor no puede tirar
/// una partida en curso. Se ignora y se sigue jugando.
enum TipoMensajeDuelo {
  emparejado,
  esperandoRival,
  sinRival,
  pregunta,
  rivalRespondio,
  resultadoPregunta,
  terminado,
  rivalAbandono,
  rivalSeCayo,
  ponteAlDia,
  teMudaron,
  error,
  desconocido,
}

TipoMensajeDuelo _tipoDesde(String? valor) => switch (valor) {
  'emparejado' => TipoMensajeDuelo.emparejado,
  'esperando_rival' => TipoMensajeDuelo.esperandoRival,
  'sin_rival' => TipoMensajeDuelo.sinRival,
  'pregunta' => TipoMensajeDuelo.pregunta,
  'rival_respondio' => TipoMensajeDuelo.rivalRespondio,
  'resultado_pregunta' => TipoMensajeDuelo.resultadoPregunta,
  'terminado' => TipoMensajeDuelo.terminado,
  'rival_abandono' => TipoMensajeDuelo.rivalAbandono,
  'rival_se_cayo' => TipoMensajeDuelo.rivalSeCayo,
  'ponte_al_dia' => TipoMensajeDuelo.ponteAlDia,
  'te_mudaron' => TipoMensajeDuelo.teMudaron,
  'error' => TipoMensajeDuelo.error,
  _ => TipoMensajeDuelo.desconocido,
};

/// El sobre común de todo lo que llega por el socket.
///
/// Un sobre único en vez de un tipo por mensaje porque el cliente hace un
/// `switch` sobre `tipo` de todas formas, y así la forma del JSON es una sola.
@freezed
abstract class MensajeDeDuelo with _$MensajeDeDuelo {
  const factory MensajeDeDuelo({
    required TipoMensajeDuelo tipo,
    EstadoDeLaPartida? duelo,
    PreguntaEnJuego? pregunta,
    ResultadoDePregunta? resultado,
    FinalDeDuelo? final$,
    EsperaDeDuelo? espera,

    /// En `te_mudaron`: a qué duelo hay que ir.
    String? dueloId,
    String? codigo,
    String? mensaje,
  }) = _MensajeDeDuelo;

  factory MensajeDeDuelo.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? mapa(String clave) =>
        json[clave] as Map<String, dynamic>?;

    final duelo = mapa('duelo');
    final pregunta = mapa('pregunta');
    final resultado = mapa('resultado');
    final finalDelDuelo = mapa('final');
    final espera = mapa('espera');

    return MensajeDeDuelo(
      tipo: _tipoDesde(json['tipo'] as String?),
      duelo: duelo == null ? null : EstadoDeLaPartida.fromJson(duelo),
      pregunta: pregunta == null ? null : PreguntaEnJuego.fromJson(pregunta),
      resultado: resultado == null
          ? null
          : ResultadoDePregunta.fromJson(resultado),
      final$: finalDelDuelo == null
          ? null
          : FinalDeDuelo.fromJson(finalDelDuelo),
      espera: espera == null ? null : EsperaDeDuelo.fromJson(espera),
      dueloId: json['dueloId'] as String?,
      codigo: json['codigo'] as String?,
      mensaje: json['mensaje'] as String?,
    );
  }
}

/// Los dos únicos verbos del cliente.
///
/// Todo lo demás —abrir preguntas, cerrar el tiempo, terminar la partida— lo
/// decide el servidor. Es lo que impide hacer trampa mandando un mensaje antes
/// de tiempo.
sealed class MensajeDelCliente {
  const MensajeDelCliente();

  Map<String, dynamic> toJson();
}

final class Responder extends MensajeDelCliente {
  const Responder({required this.orden, required this.opcionId});

  final int orden;

  /// `null` es «se acabó el tiempo y no marqué nada».
  final String? opcionId;

  @override
  Map<String, dynamic> toJson() => {
    'tipo': 'responder',
    'orden': orden,
    'opcionId': opcionId,
  };
}

final class Abandonar extends MensajeDelCliente {
  const Abandonar();

  @override
  Map<String, dynamic> toJson() => {'tipo': 'abandonar'};
}
