/// La línea abierta con el servidor durante un duelo.
///
/// # Por qué no se parece a nada más de esta app
///
/// Todo lo demás aquí funciona pidiendo y esperando: la pantalla pregunta, el
/// servidor responde. Un duelo va al revés — el servidor habla cuando quiere:
/// abre la pregunta, avisa de que el rival contestó, cierra el tiempo. Eso no
/// cabe en un repositorio de peticiones, así que este motor vive aparte.
///
/// # Lo que resuelve, además de recibir mensajes
///
///  1. **Autenticación en dos pasos.** No se puede mandar la cabecera
///     `Authorization` al abrir un WebSocket, así que primero se canjea la
///     sesión por un ticket y ese ticket viaja en la URL.
///  2. **Reconexión.** Una conexión se cae sola —el WiFi, el móvil que salta a
///     datos, la app que pasa a segundo plano— y volver NO es retomar: es una
///     conexión nueva, con ticket nuevo, que recibe un `ponte_al_dia`.
///  3. **Saber cuándo NO reconectar.** Si el duelo terminó, insistir sería un
///     bucle infinito contra un duelo que ya no existe.
///  4. **Decir cuándo un mensaje NO salió.** Enviar por un socket cerrado no
///     falla: se pierde en silencio. Por eso [responder] devuelve si salió, y
///     la pantalla no puede dar por contestada una pregunta que nunca llegó.
///
/// # Qué se trajo de la web y qué no
///
/// Las reglas son las mismas —esperas, azar, tope de intentos, el código 4000—
/// porque cada una viene de un fallo que se vio jugando y está explicada donde
/// toca. Lo que no se trajo es la defensa contra el doble montaje de React:
/// aquí no existe ese problema, pero sí el equivalente —soltar la pantalla
/// mientras se espera el ticket—, y de eso se encarga [_vivo].
library;

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../domain/duelo_models.dart';
import 'duelo_repository.dart';

/// Cuánto se espera entre intentos de reconexión.
const _esperasDeReconexion = <Duration>[
  Duration(milliseconds: 500),
  Duration(seconds: 1),
  Duration(seconds: 2),
  Duration(seconds: 3),
  Duration(seconds: 5),
];

/// Se le suma a la espera un azar de hasta 300 ms.
///
/// Sin esto, dos clientes que se caen por lo mismo —el servidor reiniciándose,
/// el WiFi de la universidad— reintentan al mismo milisegundo, y siguen
/// sincronizados en cada intento. Con muchos usuarios eso es una avalancha
/// periódica contra un servidor que acaba de levantarse.
const _azarDeReconexionMs = 300;

/// Cuántos intentos seguidos antes de rendirse.
///
/// Reintentar para siempre parece más amable y no lo es: si el duelo ya no
/// existe, o el acceso venció, la app se queda golpeando la API cada cinco
/// segundos mientras el usuario mira una pantalla que no avanza. Mejor decirlo.
const _intentosMaximos = 8;

/// El servidor cierra con este código cuando otra conexión tomó el relevo.
///
/// Es la mitad cliente de la defensa que evita el bucle: quien recibe este
/// código sabe que no se cayó nada —lo desplazaron— y **no reintenta**. Sin
/// esto, el desplazado reconecta, desplaza al otro, y los dos se turnan para
/// siempre; en la web llegó a haber más de mil conexiones en una sola partida.
///
/// 4000 está en el rango que el estándar reserva para la aplicación. Tiene que
/// coincidir con `CodigoReemplazada` del backend.
const codigoReemplazada = 4000;

/// Los errores del servidor tras los que la pantalla ya no puede seguir.
///
/// El resto —responder dos veces, llegar tarde, mandar de más— son tropiezos de
/// una carrera que sigue corriendo: se cuentan como aviso pasajero y la partida
/// no se toca. Distinguirlos importa porque el trato es opuesto: de estos hay
/// que sacar al usuario, y de los otros sacarlo sería quitarle una partida que
/// seguía en pie.
///
/// Los códigos son los de `mensajes.go`, que los declara estables.
const _erroresQueCierran = <String>{
  'DUEL_NOT_FOUND',
  'DUEL_FINISHED',
  'DUEL_NOT_YOURS',
};

/// Lo que la pantalla ve del duelo en curso.
@immutable
class EstadoDelDuelo {
  const EstadoDelDuelo({
    this.conectado = false,
    this.reconectando = false,
    this.partida,
    this.pregunta,
    this.aperturaDeLaPregunta = 0,
    this.resultado,
    this.finalDelDuelo,
    this.espera,
    this.rivalCaido = false,
    this.rivalRespondidas,
    this.sinRival = false,
    this.mudadoA,
    this.error,
    this.aviso,
  });

  /// Hay línea abierta ahora mismo.
  final bool conectado;

  /// Se cayó y se está intentando volver.
  final bool reconectando;

  final EstadoDeLaPartida? partida;
  final PreguntaEnJuego? pregunta;

  /// Cuántas veces se ha abierto una pregunta en esta partida.
  ///
  /// No es lo mismo que el orden de la pregunta, y esa diferencia es justo la
  /// que hacía falta: al reconectar, `ponte_al_dia` devuelve **la misma**
  /// pregunta que estaba abierta. Con el orden como única señal, la pantalla no
  /// distinguía «sigo en la misma» de «me la han vuelto a abrir», y se quedaba
  /// con la respuesta dada por buena aunque no hubiera salido de aquí.
  final int aperturaDeLaPregunta;

  final ResultadoDePregunta? resultado;

  /// Se llama así y no `final` porque esa palabra está reservada en Dart.
  final FinalDeDuelo? finalDelDuelo;

  final EsperaDeDuelo? espera;

  /// El rival perdió la conexión, pero todavía puede volver.
  final bool rivalCaido;

  /// Cuántas lleva respondidas el rival, según el último aviso en vivo.
  ///
  /// Llega en `rival_respondio`, que es el ÚNICO mensaje que cuenta lo que hace
  /// el otro mientras la pregunta sigue abierta. El marcador que viaja en
  /// `duelo` no sirve para esto: ese mensaje no lo trae, así que sin este dato
  /// la pantalla no se entera de nada hasta que la pregunta se cierra.
  ///
  /// Es un contador acumulado, no un booleano: comparado con el orden de la
  /// pregunta en curso dice si el rival ya contestó ESTA, sin tener que
  /// reiniciar nada entre preguntas.
  final int? rivalRespondidas;

  /// Se agotó la espera en la cola: toca ofrecer el bot.
  final bool sinRival;

  /// El emparejador fusionó esta espera con otra: hay que ir a ese duelo.
  ///
  /// Pasa cuando dos personas entran a la cola casi a la vez y cada una crea el
  /// suyo sin ver a la otra. El servidor las junta y a la más nueva le dice a
  /// dónde mudarse.
  final String? mudadoA;

  /// Se acabó: desde esta pantalla ya no se puede seguir jugando.
  ///
  /// La línea se cayó del todo, otra pantalla tomó el relevo, o el servidor
  /// dijo que este duelo no existe. Hay que **enseñarlo**: sin esto la partida
  /// se queda con la última pregunta puesta, el reloj corriendo y las
  /// respuestas cayendo al vacío, con el mismo aspecto que una partida sana.
  final String? error;

  /// Algo no se pudo hacer, pero la partida sigue.
  ///
  /// Se limpia solo al abrir la siguiente pregunta: es un comentario sobre lo
  /// que acaba de pasar, no un estado en el que quedarse.
  final String? aviso;

  EstadoDelDuelo copyWith({
    bool? conectado,
    bool? reconectando,
    EstadoDeLaPartida? partida,
    PreguntaEnJuego? pregunta,
    bool limpiarPregunta = false,
    int? aperturaDeLaPregunta,
    ResultadoDePregunta? resultado,
    bool limpiarResultado = false,
    FinalDeDuelo? finalDelDuelo,
    EsperaDeDuelo? espera,
    bool limpiarEspera = false,
    bool? rivalCaido,
    int? rivalRespondidas,
    bool? sinRival,
    String? mudadoA,
    String? error,
    bool limpiarError = false,
    String? aviso,
    bool limpiarAviso = false,
  }) => EstadoDelDuelo(
    conectado: conectado ?? this.conectado,
    reconectando: reconectando ?? this.reconectando,
    partida: partida ?? this.partida,
    pregunta: limpiarPregunta ? null : (pregunta ?? this.pregunta),
    aperturaDeLaPregunta: aperturaDeLaPregunta ?? this.aperturaDeLaPregunta,
    resultado: limpiarResultado ? null : (resultado ?? this.resultado),
    finalDelDuelo: finalDelDuelo ?? this.finalDelDuelo,
    espera: limpiarEspera ? null : (espera ?? this.espera),
    rivalCaido: rivalCaido ?? this.rivalCaido,
    rivalRespondidas: rivalRespondidas ?? this.rivalRespondidas,
    sinRival: sinRival ?? this.sinRival,
    mudadoA: mudadoA ?? this.mudadoA,
    error: limpiarError ? null : (error ?? this.error),
    aviso: limpiarAviso ? null : (aviso ?? this.aviso),
  );
}

/// Abre la línea, la mantiene y la cierra.
///
/// No sabe nada de pantallas: expone un [Stream] de estados y dos verbos. Quien
/// lo conecta con la interfaz es `DueloController`.
class DueloSocket {
  DueloSocket({
    required DueloRepository repositorio,
    required this.dueloId,
    WebSocketChannel Function(Uri url)? abrirCanal,
    Random? azar,
    List<Duration>? esperas,
  }) : _repo = repositorio,
       _abrirCanal = abrirCanal ?? WebSocketChannel.connect,
       _azar = azar ?? Random(),
       _esperas = esperas ?? _esperasDeReconexion;

  final DueloRepository _repo;
  final String dueloId;

  /// Inyectable para poder probar el motor sin un servidor de verdad.
  final WebSocketChannel Function(Uri url) _abrirCanal;
  final Random _azar;

  /// Las esperas entre intentos. Inyectables por la misma razón que en el
  /// servidor: probar que se rinde a los ocho intentos con las esperas de
  /// verdad son casi treinta segundos de test, y un test que tarda tanto acaba
  /// borrado por lento en vez de corregido.
  final List<Duration> _esperas;

  final _estados = StreamController<EstadoDelDuelo>.broadcast();
  Stream<EstadoDelDuelo> get estados => _estados.stream;

  EstadoDelDuelo _estado = const EstadoDelDuelo();
  EstadoDelDuelo get estado => _estado;

  WebSocketChannel? _canal;

  // Se cancela en `_cerrarCanalEnSilencio`, que llaman tanto `cerrar()` como el
  // siguiente intento de conexión. El análisis solo reconoce el `cancel` cuando
  // ocurre en la misma función donde se creó la suscripción.
  // ignore: cancel_subscriptions
  StreamSubscription<dynamic>? _escucha;
  Timer? _temporizador;
  int _intento = 0;

  /// ¿Sigue vivo este motor?
  ///
  /// Se apaga en [cerrar] y lo consultan todos los caminos asíncronos. El caso
  /// real es soltar la pantalla mientras se espera el ticket: sin esta
  /// comprobación, el `await` termina después y abre un socket que ya no tiene
  /// dueño — vivo, contra el servidor, y sin nadie que lo cierre.
  bool _vivo = true;

  /// El duelo acabó: no hay a dónde reconectar.
  bool _terminado = false;

  void _emitir(EstadoDelDuelo nuevo) {
    _estado = nuevo;
    if (!_estados.isClosed) _estados.add(nuevo);
  }

  /// Arranca la conexión. Llamar dos veces no duplica nada.
  Future<void> conectar() async {
    if (!_vivo || _terminado) return;

    try {
      final ticket = await _repo.pedirTicket(dueloId);

      // Entre pedir el ticket y tenerlo pudo soltarse la pantalla o acabarse el
      // duelo. Abrir el socket ahora sería dejar una conexión huérfana.
      if (!_vivo || _terminado) return;

      // Solo puede haber una conexión viva. Si quedara alguna de un intento
      // anterior, el servidor la cerraría al llegar esta — y ese cierre se
      // leería como una caída.
      await _cerrarCanalEnSilencio();

      final canal = _abrirCanal(Uri.parse(ticket.url));
      _canal = canal;

      _escucha = canal.stream.listen(
        _alLlegarMensaje,
        onDone: _alCerrarse,
        // A un error le sigue siempre el `onDone`, y la reconexión cuelga de
        // ahí. Actuar en los dos sitios reintentaría dos veces.
        onError: (_) {},
        cancelOnError: false,
      );

      _emitir(
        _estado.copyWith(
          conectado: true,
          reconectando: false,
          limpiarError: true,
        ),
      );
      _intento = 0;
    } catch (_) {
      if (!_vivo || _terminado) return;
      _emitir(_estado.copyWith(conectado: false, reconectando: true));
      _programarReintento();
    }
  }

  void _alLlegarMensaje(dynamic crudo) {
    if (!_vivo) return;
    try {
      final json = jsonDecode(crudo as String) as Map<String, dynamic>;
      _aplicar(MensajeDeDuelo.fromJson(json));
    } catch (_) {
      // Un mensaje ilegible no puede tirar la partida.
    }
  }

  void _alCerrarse() {
    _escucha = null;
    if (!_vivo || _terminado) return;

    // Nos desplazó otra conexión —otra pantalla, o un socket nuestro que se
    // coló—. No se cayó nada: reintentar aquí es entrar en el bucle.
    if (_canal?.closeCode == codigoReemplazada) {
      _emitir(
        _estado.copyWith(
          conectado: false,
          reconectando: false,
          error:
              'Abriste este duelo en otro sitio. Sigue jugando allí, o vuelve '
              'a tomar el control desde aquí.',
        ),
      );
      return;
    }

    _emitir(_estado.copyWith(conectado: false, reconectando: true));
    _programarReintento();
  }

  void _programarReintento() {
    if (!_vivo || _terminado) return;

    if (_intento >= _intentosMaximos) {
      _emitir(
        _estado.copyWith(
          reconectando: false,
          // Sin culpar a la conexión del usuario: el corte puede ser nuestro, y
          // en cualquier caso no puede hacer nada con esa instrucción.
          error:
              'No pudimos volver a conectar con el duelo. Puedes intentarlo '
              'otra vez.',
        ),
      );
      return;
    }

    final base = _esperas[min(_intento, _esperas.length - 1)];
    _intento += 1;

    _temporizador?.cancel();
    _temporizador = Timer(
      base + Duration(milliseconds: _azar.nextInt(_azarDeReconexionMs)),
      () => unawaited(conectar()),
    );
  }

  void _aplicar(MensajeDeDuelo msg) {
    var nuevo = _estado;
    if (msg.duelo != null) nuevo = nuevo.copyWith(partida: msg.duelo);

    switch (msg.tipo) {
      case TipoMensajeDuelo.emparejado:
        nuevo = nuevo.copyWith(
          limpiarEspera: true,
          sinRival: false,
          rivalCaido: false,
        );

      case TipoMensajeDuelo.esperandoRival:
        nuevo = nuevo.copyWith(espera: msg.espera);

      case TipoMensajeDuelo.sinRival:
        nuevo = nuevo.copyWith(espera: msg.espera, sinRival: true);

      case TipoMensajeDuelo.pregunta:
        // El resultado anterior se limpia al abrir la siguiente, no antes:
        // durante la pausa la pantalla lo sigue mostrando.
        nuevo = nuevo.copyWith(
          limpiarResultado: true,
          pregunta: msg.pregunta,
          aperturaDeLaPregunta: nuevo.aperturaDeLaPregunta + 1,
          limpiarAviso: true,
        );

      case TipoMensajeDuelo.resultadoPregunta:
        nuevo = nuevo.copyWith(resultado: msg.resultado);

      case TipoMensajeDuelo.rivalRespondio:
        // El único aviso en vivo de lo que hace el otro. NO se toca
        // `resultado` con lo que trae: ese objeto viene a medio llenar y con
        // `orden: 0`, así que aplicarlo pisaría el resultado de verdad de la
        // pregunta anterior, que todavía está en pantalla durante la pausa.
        if (msg.resultado != null) {
          nuevo = nuevo.copyWith(
            rivalRespondidas: msg.resultado!.rivalRespondidas,
          );
        }

      case TipoMensajeDuelo.rivalSeCayo:
        nuevo = nuevo.copyWith(rivalCaido: true);

      case TipoMensajeDuelo.rivalAbandono:
        // No hace falta actuar: detrás viene `terminado`, con `porAbandono`
        // puesto, y la pantalla de resultado ya lo cuenta con el nombre del
        // rival delante. Un estado aparte sería contar dos veces lo mismo, y
        // el segundo llegaría tarde.
        break;

      case TipoMensajeDuelo.ponteAlDia:
        // Reconexión: puede traer la pregunta en curso o no, según si ya se
        // había contestado o si venció mientras se estaba fuera.
        nuevo = nuevo.copyWith(
          pregunta: msg.pregunta,
          limpiarPregunta: msg.pregunta == null,
          // Si la trae, el servidor NO tiene respuesta nuestra: la pregunta
          // vuelve a estar abierta y la pantalla tiene que dejar contestar.
          aperturaDeLaPregunta: msg.pregunta == null
              ? nuevo.aperturaDeLaPregunta
              : nuevo.aperturaDeLaPregunta + 1,
          rivalCaido: false,
          limpiarAviso: true,
        );

      case TipoMensajeDuelo.terminado:
        // Se marca ANTES de que llegue el cierre del socket: si no, el cierre
        // intentaría reconectar a un duelo ya acabado.
        _terminado = true;
        nuevo = nuevo.copyWith(
          finalDelDuelo: msg.final$,
          limpiarPregunta: true,
        );

      case TipoMensajeDuelo.teMudaron:
        // El servidor cierra este socket justo después, así que se marca como
        // terminado: reconectar aquí sería insistir con un duelo que acaba de
        // fusionarse con otro.
        _terminado = true;
        nuevo = nuevo.copyWith(mudadoA: msg.dueloId);

      case TipoMensajeDuelo.error:
        final texto = msg.mensaje ?? 'Algo salió mal en el duelo.';
        if (msg.codigo != null && _erroresQueCierran.contains(msg.codigo)) {
          _terminado = true;
          nuevo = nuevo.copyWith(error: texto);
        } else {
          // Un código que no se conoce se trata como pasajero a propósito:
          // equivocarse por aquí deja un aviso de más, y equivocarse por el
          // otro lado echa a alguien de una partida que seguía viva.
          nuevo = nuevo.copyWith(aviso: texto);
        }

      case TipoMensajeDuelo.desconocido:
        // Un tipo que este cliente no conoce no puede tirar la partida.
        break;
    }

    _emitir(nuevo);
  }

  /// Manda la respuesta y devuelve **si salió de verdad**.
  ///
  /// Un socket cerrado se traga lo que le echen sin protestar, y esa es
  /// exactamente la trampa: la pantalla decía «Respondiste» y el servidor
  /// contaba la pregunta en blanco.
  bool responder(String? opcionId) {
    final pregunta = _estado.pregunta;
    if (pregunta == null) return false;
    return _enviar(Responder(orden: pregunta.orden, opcionId: opcionId));
  }

  /// Salirse a propósito. Se marca terminado antes de mandar: al cerrarse el
  /// socket detrás, no hay que reconectar a nada.
  void abandonar() {
    _terminado = true;
    _enviar(const Abandonar());
  }

  /// Vuelve a intentarlo desde cero, a petición del usuario.
  Future<void> reintentar() async {
    _intento = 0;
    _terminado = false;
    _temporizador?.cancel();
    _emitir(_estado.copyWith(limpiarError: true, reconectando: true));
    await conectar();
  }

  bool _enviar(MensajeDelCliente mensaje) {
    final canal = _canal;
    if (canal == null || !_estado.conectado) return false;
    try {
      canal.sink.add(jsonEncode(mensaje.toJson()));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _cerrarCanalEnSilencio() async {
    final escucha = _escucha;
    final canal = _canal;
    _escucha = null;
    _canal = null;

    // Se anula la escucha ANTES de cerrar: si no, el propio cierre dispara el
    // `onDone` y el motor lo lee como una caída que hay que reconectar.
    await escucha?.cancel();
    await canal?.sink.close();
  }

  /// Suelta todo. Después de esto el motor no vuelve a emitir nada.
  Future<void> cerrar() async {
    _vivo = false;
    _temporizador?.cancel();
    await _cerrarCanalEnSilencio();
    await _estados.close();
  }
}
