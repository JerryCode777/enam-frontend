import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:enam_app/features/duelo/data/duelo_repository.dart';
import 'package:enam_app/features/duelo/data/duelo_socket.dart';
import 'package:enam_app/features/duelo/domain/duelo_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// El motor de la conexión del duelo.
///
/// # Por qué esto se prueba y las pantallas menos
///
/// Porque es donde estuvieron TODOS los fallos caros de la versión web, y
/// ninguno se veía leyendo el código: la app abría mil sockets por partida, el
/// aviso de «se cortó la conexión» parpadeaba sin motivo, y una respuesta que
/// no salía se daba por enviada mientras el servidor la contaba en blanco.
///
/// Cada test de aquí abajo fija una de esas reglas.
void main() {
  group('conectar', () {
    test('abre la línea con la URL del ticket, no con una compuesta', () async {
      // El servidor manda la URL ya armada, con ws:// o wss:// resuelto. Si el
      // cliente la compusiera, tendría que adivinar el esquema — y ese es
      // justo el detalle que se equivoca al pasar de local a producción.
      final canal = _CanalFalso();
      final motor = _motor(canal: canal, url: 'wss://api.test/duelo/abc');

      await motor.conectar();

      expect(canal.urlPedida.toString(), 'wss://api.test/duelo/abc');
      expect(motor.estado.conectado, isTrue);
      await motor.cerrar();
    });

    test('soltar la pantalla mientras llega el ticket no abre nada', () async {
      // El equivalente en Dart del fallo que en React abría mil conexiones: el
      // `await` del ticket termina DESPUÉS de que la pantalla se haya ido, y
      // sin esta comprobación deja un socket vivo que nadie va a cerrar.
      final canal = _CanalFalso();
      final repo = _RepoLento();
      final motor = DueloSocket(
        repositorio: repo,
        dueloId: 'duelo-1',
        abrirCanal: canal.abrir,
      );

      final conectando = motor.conectar();
      await motor.cerrar(); // se suelta la pantalla mientras espera el ticket
      repo.entregarTicket();
      await conectando;

      expect(canal.veces, 0, reason: 'no debía abrirse ningún socket');
    });
  });

  group('reconexión', () {
    test('una caída deja el motor reconectando', () async {
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();

      canal.caerse();
      await _dejarCorrer();

      expect(motor.estado.conectado, isFalse);
      expect(motor.estado.reconectando, isTrue);
      expect(motor.estado.error, isNull, reason: 'todavía puede volver');
      await motor.cerrar();
    });

    test('el código 4000 NO reintenta: es un relevo, no una caída', () async {
      // La mitad cliente de la defensa contra el bucle. Sin esto, el
      // desplazado reconecta, desplaza al otro, y los dos se turnan para
      // siempre.
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();

      canal.caerse(codigo: codigoReemplazada);
      await _dejarCorrer();

      expect(motor.estado.reconectando, isFalse);
      expect(motor.estado.error, contains('otro sitio'));
      expect(canal.veces, 1, reason: 'no debía volver a intentarlo');
      await motor.cerrar();
    });

    test('se rinde tras 8 intentos y lo dice, en vez de insistir', () async {
      // Reintentar para siempre parece más amable y no lo es: deja al usuario
      // mirando una pantalla que no avanza mientras la app golpea la API.
      //
      // El servidor está caído de verdad: cada intento revienta al abrir. Con
      // un canal que sí abre, el contador se reiniciaba en cada vuelta y esto
      // no llegaba nunca al tope — que fue exactamente lo que pasó al
      // escribirlo.
      final canal = _CanalFalso()..fallarAlAbrir = true;
      // Sin azar: aquí se cuenta CUÁNTAS veces reintenta, y con el azar de
      // verdad la espera total varía entre unos milisegundos y casi tres
      // segundos. Un test que depende de eso falla un día de cada diez.
      final motor = _motor(canal: canal, azar: _SinAzar());

      await motor.conectar();
      await _dejarCorrer(const Duration(milliseconds: 300));

      expect(motor.estado.error, contains('No pudimos volver a conectar'));
      expect(motor.estado.reconectando, isFalse);
      expect(
        canal.veces,
        _intentosEsperados,
        reason: 'el primero más ocho reintentos, y ni uno más',
      );
      await motor.cerrar();
    });

    test('tras terminar el duelo no se reconecta nunca', () async {
      // Insistir contra un duelo que ya acabó es un bucle infinito contra algo
      // que no existe.
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();

      canal.mandar({'tipo': 'terminado', 'final': {'desenlace': 'ganaste'}});
      await _dejarCorrer();
      canal.caerse();
      await _dejarCorrer(const Duration(milliseconds: 60));

      expect(canal.veces, 1);
      expect(motor.estado.reconectando, isFalse);
      await motor.cerrar();
    });
  });

  group('responder', () {
    test('devuelve false si la línea está caída, y no miente', () async {
      // El fallo más traicionero de todos: mandar por un socket cerrado no
      // falla, se pierde en silencio. La pantalla decía «Respondiste» y el
      // servidor contaba la pregunta en blanco.
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();
      canal.mandar(_preguntaAbierta());
      await _dejarCorrer();

      expect(motor.responder('a'), isTrue);

      canal.caerse();
      await _dejarCorrer();

      expect(motor.responder('a'), isFalse);
      await motor.cerrar();
    });

    test('sin pregunta abierta no manda nada', () async {
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();

      expect(motor.responder('a'), isFalse);
      expect(canal.enviados, isEmpty);
      await motor.cerrar();
    });
  });

  group('mensajes', () {
    test('una pregunta nueva limpia el resultado anterior', () async {
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();

      canal.mandar({
        'tipo': 'resultado_pregunta',
        'resultado': {'orden': 1, 'acertaste': true},
      });
      await _dejarCorrer();
      expect(motor.estado.resultado, isNotNull);

      canal.mandar(_preguntaAbierta(orden: 2));
      await _dejarCorrer();

      expect(motor.estado.resultado, isNull);
      expect(motor.estado.pregunta?.orden, 2);
      await motor.cerrar();
    });

    test('cada apertura cuenta, aunque sea la misma pregunta', () async {
      // Es lo que distingue «sigo en la misma» de «me la han vuelto a abrir»
      // al reconectar. Con el orden como única señal, la pantalla se quedaba
      // con la respuesta dada por buena aunque no hubiera salido de aquí.
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();

      canal.mandar(_preguntaAbierta(orden: 3));
      await _dejarCorrer();
      final primera = motor.estado.aperturaDeLaPregunta;

      canal.mandar({
        'tipo': 'ponte_al_dia',
        'pregunta': _preguntaAbierta(orden: 3)['pregunta'],
      });
      await _dejarCorrer();

      expect(motor.estado.aperturaDeLaPregunta, primera + 1);
      await motor.cerrar();
    });

    test('rival_respondio NO pisa el resultado que está en pantalla', () async {
      // Ese mensaje viene a medio llenar y con `orden: 0`. Aplicarlo entero
      // borraba el resultado de verdad de la pregunta anterior, que sigue en
      // pantalla durante la pausa.
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();

      canal.mandar({
        'tipo': 'resultado_pregunta',
        'resultado': {'orden': 4, 'acertaste': true, 'tusAciertos': 3},
      });
      await _dejarCorrer();

      canal.mandar({
        'tipo': 'rival_respondio',
        'resultado': {'orden': 0, 'rivalRespondidas': 5},
      });
      await _dejarCorrer();

      expect(motor.estado.resultado?.orden, 4);
      expect(motor.estado.resultado?.tusAciertos, 3);
      expect(motor.estado.rivalRespondidas, 5);
      await motor.cerrar();
    });

    test('un error conocido cierra; uno pasajero solo avisa', () async {
      // Equivocarse por un lado deja un aviso de más; por el otro, echa a
      // alguien de una partida que seguía viva.
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();

      canal.mandar({
        'tipo': 'error',
        'codigo': 'DUEL_ALREADY_ANSWERED',
        'mensaje': 'Ya respondiste esta.',
      });
      await _dejarCorrer();
      expect(motor.estado.aviso, 'Ya respondiste esta.');
      expect(motor.estado.error, isNull);

      canal.mandar({
        'tipo': 'error',
        'codigo': 'DUEL_NOT_FOUND',
        'mensaje': 'Este duelo no existe.',
      });
      await _dejarCorrer();
      expect(motor.estado.error, 'Este duelo no existe.');
      await motor.cerrar();
    });

    test('un tipo desconocido no tira la partida', () async {
      // El servidor va a añadir mensajes, y una app publicada no se actualiza
      // sola. Un tipo nuevo tiene que ser inofensivo.
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();
      canal.mandar(_preguntaAbierta(orden: 7));
      await _dejarCorrer();

      canal.mandar({'tipo': 'algo_que_no_existe_todavia'});
      canal.mandarCrudo('{esto no es json');
      await _dejarCorrer();

      expect(motor.estado.pregunta?.orden, 7);
      expect(motor.estado.error, isNull);
      await motor.cerrar();
    });

    test('te_mudaron dice a dónde ir y deja de reconectar', () async {
      final canal = _CanalFalso();
      final motor = _motor(canal: canal);
      await motor.conectar();

      canal.mandar({'tipo': 'te_mudaron', 'dueloId': 'duelo-nuevo'});
      await _dejarCorrer();
      canal.caerse();
      await _dejarCorrer(const Duration(milliseconds: 60));

      expect(motor.estado.mudadoA, 'duelo-nuevo');
      expect(canal.veces, 1, reason: 'el duelo se fusionó: no hay a dónde volver');
      await motor.cerrar();
    });
  });
}

// ---------------------------------------------------------------------------
// Andamiaje
// ---------------------------------------------------------------------------

DueloSocket _motor({
  required _CanalFalso canal,
  String? url,
  Random? azar,
  List<Duration>? esperas,
}) => DueloSocket(
  repositorio: _RepoDePrueba(url: url ?? 'wss://api.test/ws'),
  dueloId: 'duelo-1',
  abrirCanal: canal.abrir,
  azar: azar ?? Random(7),
  // Esperas de juguete: lo que se prueba es CUÁNTAS veces reintenta, no
  // cuánto tarda. Con las de verdad este fichero pasaría medio minuto
  // durmiendo.
  esperas: esperas ?? const [Duration(milliseconds: 5)],
);

/// Un azar que nunca añade nada, para que las esperas sean exactas.
class _SinAzar implements Random {
  @override
  int nextInt(int max) => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// El primer intento más los ocho reintentos del tope.
const _intentosEsperados = 9;

/// Deja correr los temporizadores y los streams.
Future<void> _dejarCorrer([Duration cuanto = const Duration(milliseconds: 20)]) =>
    Future<void>.delayed(cuanto);

Map<String, dynamic> _preguntaAbierta({int orden = 1}) => {
  'tipo': 'pregunta',
  'pregunta': {
    'orden': orden,
    'totalPreguntas': 10,
    'enunciado': '¿Cuál es la conducta?',
    'opciones': [
      {'id': 'a', 'texto': 'A'},
      {'id': 'b', 'texto': 'B'},
    ],
    'cierraEn': DateTime.now()
        .add(const Duration(seconds: 30))
        .toUtc()
        .toIso8601String(),
    'segundos': 30,
  },
};

/// Lo que lanza el canal falso cuando se le pide que no abra.
class SocketExceptionDePrueba implements Exception {
  const SocketExceptionDePrueba();
  @override
  String toString() => 'no se pudo abrir el socket';
}

/// Un canal que se puede abrir, alimentar y tirar a mano.
class _CanalFalso {
  int veces = 0;

  /// Abrir revienta, como cuando el servidor está caído de verdad.
  bool fallarAlAbrir = false;
  late Uri urlPedida;
  final enviados = <String>[];

  // ignore: close_sinks — el StreamController y el sink son dobles de prueba;
  // `caerse()` cierra el controlador y el resto muere con el test.
  StreamController<dynamic>? _entrada;
  // ignore: close_sinks
  _SinkFalso? _sink;
  int? _codigoDeCierre;

  WebSocketChannel abrir(Uri url) {
    veces++;
    urlPedida = url;
    if (fallarAlAbrir) throw const SocketExceptionDePrueba();
    // ignore: close_sinks — lo cierra `caerse()`, o muere con el test.
    final entrada = StreamController<dynamic>.broadcast();
    _entrada = entrada;
    _sink = _SinkFalso(enviados);
    _codigoDeCierre = null;
    return _CanalDePrueba(entrada.stream, _sink!, () => _codigoDeCierre);
  }

  void mandar(Map<String, dynamic> mensaje) => mandarCrudo(jsonEncode(mensaje));

  void mandarCrudo(String texto) {
    if (_entrada?.isClosed ?? true) return;
    _entrada!.add(texto);
  }

  void caerse({int codigo = 1006}) {
    _codigoDeCierre = codigo;
    _entrada?.close();
    _entrada = null;
  }
}

class _CanalDePrueba extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  _CanalDePrueba(this._stream, this._sink, this._codigo);

  final Stream<dynamic> _stream;
  final WebSocketSink _sink;
  final int? Function() _codigo;

  @override
  Stream<dynamic> get stream => _stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  int? get closeCode => _codigo();

  @override
  String? get closeReason => null;

  @override
  String? get protocol => null;

  @override
  Future<void> get ready => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

// ignore: close_sinks — es un doble de prueba: su `close` no hace nada y el
// canal falso muere con el test.
class _SinkFalso implements WebSocketSink {
  _SinkFalso(this._enviados);

  final List<String> _enviados;

  @override
  void add(dynamic data) => _enviados.add(data as String);

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> get done => Future.value();
}

class _RepoDePrueba implements DueloRepository {
  _RepoDePrueba({required this.url});

  final String url;

  @override
  Future<TicketDeDuelo> pedirTicket(String dueloId) async => TicketDeDuelo(
    ticket: 't',
    expira: DateTime.now().add(const Duration(seconds: 30)),
    url: url,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

/// Entrega el ticket cuando se le dice, para poder soltar la pantalla en medio.
class _RepoLento implements DueloRepository {
  final _completador = Completer<TicketDeDuelo>();

  void entregarTicket() => _completador.complete(
    TicketDeDuelo(
      ticket: 't',
      expira: DateTime.now().add(const Duration(seconds: 30)),
      url: 'wss://api.test/ws',
    ),
  );

  @override
  Future<TicketDeDuelo> pedirTicket(String dueloId) => _completador.future;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}
