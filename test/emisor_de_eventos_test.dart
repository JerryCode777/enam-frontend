import 'dart:math';

import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/analitica/cola_de_eventos.dart';
import 'package:enam_app/core/analitica/emisor_de_eventos.dart';
import 'package:enam_app/core/analitica/identidad_anonima.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// La cola y el envío de eventos (contrato de eventos, §3 y §4).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  var reloj = DateTime.utc(2026, 9, 29, 12);
  DateTime ahora() => reloj;

  EventoEnCola evento(int i, {DateTime? cuando}) => (
    eventoId: uuidV4(Random(i)),
    tipo: 'plans_viewed',
    ocurridoEn: cuando ?? reloj,
    propiedades: const {'pantalla': 'planes'},
  );

  const comunes = <String, Object>{
    'plataforma': 'android',
    'version_app': '1.0.0+7-dev',
    'version_visual': 'rediseno-2026-09',
    'anonimo_id': '3f0c9a1e-6b2d-4e8f-9a51-2c7d8e4b1f60',
  };

  ({EmisorDeEventos emisor, ColaDeEventos cola, _Servidor servidor}) montar({
    String? token,
    String? renovado,
  }) {
    final cola = ColaDeEventos(AlmacenDeColaPrefs(), reloj: ahora);
    final servidor = _Servidor();
    final emisor = EmisorDeEventos(
      cola: cola,
      transporte: servidor,
      comunes: () async => comunes,
      token: () async => token,
      renovarToken: () async => renovado,
      reloj: ahora,
      azar: Random(1),
    );
    return (emisor: emisor, cola: cola, servidor: servidor);
  }

  group('Cola', () {
    test('sobrevive a cerrar y abrir la app', () async {
      final antes = ColaDeEventos(AlmacenDeColaPrefs(), reloj: ahora);
      await antes.agregar(evento(1));
      await antes.agregar(evento(2));

      // Otra instancia, como tras reiniciar: lee lo mismo del teléfono.
      final despues = ColaDeEventos(AlmacenDeColaPrefs(), reloj: ahora);
      final pendientes = await despues.pendientes();
      expect(pendientes.map((e) => e.eventoId), [
        evento(1).eventoId,
        evento(2).eventoId,
      ]);
    });

    test('guarda 500 como máximo: se pierden los más viejos', () async {
      final cola = ColaDeEventos(AlmacenDeColaPrefs(), reloj: ahora);
      for (var i = 0; i < 505; i++) {
        await cola.agregar(evento(i));
      }
      final pendientes = await cola.pendientes();
      expect(pendientes, hasLength(500));
      expect(pendientes.first.eventoId, evento(5).eventoId);
    });

    test('lo de más de siete días se descarta', () async {
      final cola = ColaDeEventos(AlmacenDeColaPrefs(), reloj: ahora);
      await cola.agregar(
        evento(1, cuando: reloj.subtract(const Duration(days: 8))),
      );
      await cola.agregar(evento(2));
      expect((await cola.pendientes()).single.eventoId, evento(2).eventoId);
    });
  });

  group('Envío', () {
    test('lotes de 50 como máximo', () async {
      final m = montar();
      for (var i = 0; i < 120; i++) {
        await m.cola.agregar(evento(i));
      }
      await m.emisor.vaciar();

      expect(m.servidor.lotes.map((l) => l.eventos.length), [50, 50, 20]);
      expect(await m.cola.pendientes(), isEmpty);
    });

    test('lleva las comunes y nunca usuario_id', () async {
      final m = montar();
      await m.cola.agregar(evento(1));
      await m.emisor.vaciar();

      final cuerpo = m.servidor.lotes.single.cuerpo;
      expect(cuerpo['version_contrato'], 1);
      expect(cuerpo['comunes'], comunes);
      expect(cuerpo.toString(), isNot(contains('usuario_id')));
      final e = (cuerpo['eventos']! as List).single as Map;
      expect(e.keys, {'evento_id', 'tipo', 'ocurrido_en', 'propiedades'});
      expect(e['ocurrido_en'].toString(), endsWith('Z'));
    });

    test('sin red, nada se pierde y se reintenta con los mismos ids', () async {
      final m = montar();
      await m.cola.agregar(evento(1));
      await m.cola.agregar(evento(2));

      m.servidor.status = 0;
      await m.emisor.vaciar();
      expect(await m.cola.pendientes(), hasLength(2));

      // Antes de que pase la espera no se insiste.
      await m.emisor.vaciar();
      expect(m.servidor.lotes, hasLength(1));

      reloj = reloj.add(const Duration(minutes: 2));
      m.servidor.status = 200;
      await m.emisor.vaciar();

      expect(m.servidor.lotes, hasLength(2));
      expect(m.servidor.lotes[1].ids, m.servidor.lotes[0].ids);
      expect(await m.cola.pendientes(), isEmpty);
    });

    test('solo retira lo que el servidor contestó', () async {
      final m = montar();
      for (var i = 0; i < 3; i++) {
        await m.cola.agregar(evento(i));
      }
      m.servidor.respuesta = {
        'aceptados': [0],
        'duplicados': [],
        'rechazados': [
          {'indice': 2, 'codigo': 'PROPIEDAD_INVALIDA'},
        ],
      };
      await m.emisor.vaciar();

      // El 1 no se nombró: queda. El 2 se rechazó: no se reintenta.
      final quedan = await m.cola.pendientes();
      expect(quedan.single.eventoId, evento(1).eventoId);
    });

    test('un sobre inválido (400) se descarta', () async {
      final m = montar();
      await m.cola.agregar(evento(1));
      m.servidor.status = 400;
      await m.emisor.vaciar();
      expect(await m.cola.pendientes(), isEmpty);
    });

    test('con 429 espera lo que diga Retry-After', () async {
      final m = montar();
      await m.cola.agregar(evento(1));
      m.servidor
        ..status = 429
        ..reintentarEn = const Duration(seconds: 30);
      await m.emisor.vaciar();

      expect(
        m.emisor.noAntesDe!.difference(reloj).inSeconds,
        inInclusiveRange(30, 31),
      );
      expect(await m.cola.pendientes(), hasLength(1));
    });

    test('token inválido: se renueva una vez, y si no, sale anónimo', () async {
      final m = montar(token: 'viejo', renovado: 'nuevo');
      await m.cola.agregar(evento(1));
      // Rechaza cualquier token, acepta sin token.
      m.servidor.aceptaToken = false;
      await m.emisor.vaciar();

      expect(m.servidor.lotes.map((l) => l.token), ['viejo', 'nuevo', null]);
      expect(await m.cola.pendientes(), isEmpty);
    });

    test('con el token renovado basta un reintento', () async {
      final m = montar(token: 'viejo', renovado: 'nuevo');
      await m.cola.agregar(evento(1));
      m.servidor.tokenValido = 'nuevo';
      await m.emisor.vaciar();

      expect(m.servidor.lotes.map((l) => l.token), ['viejo', 'nuevo']);
    });
  });

  test('la interfaz encola y manda lo que el contrato admite', () async {
    final m = montar();
    final analitica =
        AnaliticaConCola(
            cola: m.cola,
            emisor: m.emisor,
            plataforma: 'android',
            reloj: ahora,
            demora: Duration.zero,
          )
          // De servidor ya no existe en la app; un iOS-solo en Android, fuera.
          ..registrar(
            Evento.checkoutStarted,
            propiedades: const {'plan_id': 'mensual', 'medio': 'apple'},
          )
          ..registrar(
            Evento.plansViewed,
            propiedades: const {'pantalla': 'otra'},
          );
    await analitica.enviarPendientes();

    final tipos = [
      for (final l in m.servidor.lotes)
        for (final e in l.eventos) e['tipo'],
    ];
    expect(tipos, ['plans_viewed']);
  });
}

class _Servidor implements TransporteDeEventos {
  int status = 200;
  Map<String, dynamic>? respuesta;
  Duration? reintentarEn;
  bool aceptaToken = true;
  String? tokenValido;

  final lotes =
      <
        ({
          Map<String, Object> cuerpo,
          String? token,
          List<Map<String, Object?>> eventos,
          List<Object?> ids,
        })
      >[];

  @override
  Future<RespuestaDeEventos> enviar(
    Map<String, Object> cuerpo, {
    String? token,
  }) async {
    final eventos = (cuerpo['eventos']! as List).cast<Map<String, Object?>>();
    lotes.add((
      cuerpo: cuerpo,
      token: token,
      eventos: eventos,
      ids: [for (final e in eventos) e['evento_id']],
    ));
    if (token != null &&
        (!aceptaToken || (tokenValido != null && token != tokenValido))) {
      return (status: 401, cuerpo: null, reintentarEn: null);
    }
    return (
      status: status,
      cuerpo:
          respuesta ??
          {
            'aceptados': [for (var i = 0; i < eventos.length; i++) i],
            'duplicados': [],
            'rechazados': [],
          },
      reintentarEn: reintentarEn,
    );
  }
}
