import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/recordatorios/data/notificador.dart';
import 'package:enam_app/features/recordatorios/domain/recordatorios.dart';
import 'package:enam_app/features/recordatorios/presentation/pre_pantalla_de_recordatorio.dart';
import 'package:enam_app/features/recordatorios/presentation/recordatorios_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recordatorios locales (fase 1 de notificaciones, catálogo 38).
void main() {
  // Martes 28/10/2026, 10:00 de la mañana.
  final ahora = DateTime(2026, 10, 28, 10);
  const encendido = AjustesDeRecordatorio(activo: true);

  group('planDeAvisos', () {
    test('apagado, ninguno', () {
      expect(
        planDeAvisos(ahora: ahora, ajustes: const AjustesDeRecordatorio()),
        isEmpty,
      );
    });

    test('una semana a la hora elegida, uno por día', () {
      final avisos = planDeAvisos(ahora: ahora, ajustes: encendido);
      expect(avisos, hasLength(diasProgramados));
      expect(avisos.first.cuando, DateTime(2026, 10, 28, 20));
      expect(avisos.last.cuando, DateTime(2026, 11, 3, 20));
      expect({for (final a in avisos) a.id}, hasLength(diasProgramados));
      expect(avisos.every((a) => a.tipo == TipoDeAviso.diario), isTrue);
    });

    test('si ya practicó hoy, hoy no se le recuerda', () {
      final avisos = planDeAvisos(
        ahora: ahora,
        ajustes: encendido,
        ultimaPractica: DateTime(2026, 10, 28, 8),
      );
      expect(avisos.first.cuando, DateTime(2026, 10, 29, 20));
    });

    test('pasada la hora de hoy, empieza mañana', () {
      final avisos = planDeAvisos(
        ahora: DateTime(2026, 10, 28, 21),
        ajustes: encendido,
      );
      expect(avisos.first.cuando, DateTime(2026, 10, 29, 20));
    });

    test(
      'topó el cupo hoy: mañana a las 9 «se renovó», y ese día nada más',
      () {
        final avisos = planDeAvisos(
          ahora: ahora,
          ajustes: encendido,
          cupoAgotadoEl: DateTime(2026, 10, 28, 9, 30),
          preguntasGratis: 10,
        );
        final cupo = avisos.singleWhere((a) => a.tipo == TipoDeAviso.cupo);
        expect(cupo.cuando, DateTime(2026, 10, 29, 9));
        expect(cupo.titulo, 'Tu cupo gratis se renovó');
        expect(cupo.cuerpo, contains('10 preguntas'));
        expect(cupo.payload, 'cupo:cupo');
        expect(
          avisos.where(
            (a) =>
                a.tipo == TipoDeAviso.diario &&
                a.cuando.day == 29 &&
                a.cuando.month == 10,
          ),
          isEmpty,
        );
      },
    );

    test('un cupo de ayer ya no se avisa', () {
      final avisos = planDeAvisos(
        ahora: ahora,
        ajustes: encendido,
        cupoAgotadoEl: DateTime(2026, 10, 27, 22),
        preguntasGratis: 10,
      );
      expect(avisos.where((a) => a.tipo == TipoDeAviso.cupo), isEmpty);
    });

    test('el texto rota entre lo que tiene sentido', () {
      final avisos = planDeAvisos(
        ahora: ahora,
        ajustes: encendido,
        racha: 5,
        fechaExamen: DateTime(2026, 11, 22),
        preguntasGratis: 10,
      );
      final variantes = {for (final a in avisos) a.variante};
      expect(
        variantes,
        containsAll([VarianteDeAviso.preguntas, VarianteDeAviso.examen]),
      );
      // La racha, solo hoy o mañana: más adelante ya se habría cortado.
      for (final a in avisos.where(
        (a) => a.variante == VarianteDeAviso.racha,
      )) {
        expect(a.cuando.isBefore(DateTime(2026, 10, 30)), isTrue);
      }
      final examen = avisos.firstWhere(
        (a) => a.variante == VarianteDeAviso.examen,
      );
      final faltan = DateTime(2026, 11, 22)
          .difference(
            DateTime(
              examen.cuando.year,
              examen.cuando.month,
              examen.cuando.day,
            ),
          )
          .inDays;
      expect(examen.titulo, 'Faltan $faltan días para tu ENAM');
    });

    test('sin racha ni fecha, solo «tus preguntas»', () {
      final avisos = planDeAvisos(
        ahora: ahora,
        ajustes: encendido,
        preguntasGratis: 10,
      );
      expect(
        avisos.every((a) => a.variante == VarianteDeAviso.preguntas),
        isTrue,
      );
      expect(avisos.first.titulo, 'Tus 10 preguntas de hoy ya están listas');
      // En Premium no hay cupo que nombrar.
      expect(
        planDeAvisos(ahora: ahora, ajustes: encendido).first.titulo,
        'Tu práctica de hoy ya está lista',
      );
    });

    test('ningún aviso habla de precios, ofertas ni de la web', () {
      final avisos = planDeAvisos(
        ahora: ahora,
        ajustes: encendido,
        racha: 3,
        fechaExamen: DateTime(2026, 12, 1),
        cupoAgotadoEl: ahora,
        preguntasGratis: 10,
      );
      for (final a in avisos) {
        final texto = '${a.titulo} ${a.cuerpo}'.toLowerCase();
        for (final prohibido in const [
          's/',
          'precio',
          'oferta',
          'descuento',
          'premium',
          'web',
          'pagar',
          '%',
        ]) {
          expect(texto, isNot(contains(prohibido)), reason: a.titulo);
        }
      }
    });
  });

  group('el controlador', () {
    late _Notificador notificador;
    late _Analitica analitica;
    late ProviderContainer c;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notificador = _Notificador();
      analitica = _Analitica();
      c = ProviderContainer(
        overrides: [
          notificadorProvider.overrideWithValue(notificador),
          analiticaProvider.overrideWithValue(analitica),
          currentUserProvider.overrideWithValue(null),
          cupoGratisProvider.overrideWithValue(null),
          dashboardProvider.overrideWith((ref) => Future.error('sin red')),
        ],
      );
      addTearDown(c.dispose);
    });

    RecordatoriosController control() => c.read(recordatoriosProvider.notifier);

    test('sí en la pantalla previa: permiso, programado y medido', () async {
      notificador.concede = true;
      expect(await control().debePreguntar(), isTrue);

      expect(await control().activar(OrigenDelPermiso.prePantalla), isTrue);
      expect(notificador.programados, isNotEmpty);
      expect(analitica.registrados, [
        'notif_permiso respuesta=concedido origen=pre_pantalla',
        'notif_programada tipo=diario hora=20',
      ]);
      // Nunca dos veces.
      expect(await control().debePreguntar(), isFalse);
    });

    test('el sistema dice que no: apagado y sin insistir', () async {
      notificador.concede = false;
      expect(await control().activar(OrigenDelPermiso.prePantalla), isFalse);
      expect(notificador.programados, isEmpty);
      expect((await c.read(recordatoriosProvider.future)).encendido, isFalse);
      expect(analitica.registrados, [
        'notif_permiso respuesta=denegado origen=pre_pantalla',
      ]);
      expect(await control().debePreguntar(), isFalse);
    });

    test('«Ahora no»: el sistema ni pregunta', () async {
      await control().rechazarPrePantalla();
      expect(notificador.pedidos, 0);
      expect(analitica.registrados, [
        'notif_permiso respuesta=ahora_no origen=pre_pantalla',
      ]);
      expect(await control().debePreguntar(), isFalse);
    });

    test('el cupo se mide una vez al día', () async {
      notificador.concede = true;
      await control().activar(OrigenDelPermiso.ajustes);
      analitica.registrados.clear();

      await control().cupoAgotado(ahora: ahora);
      await control().cupoAgotado(ahora: ahora.add(const Duration(hours: 1)));
      expect(analitica.registrados, ['notif_programada tipo=cupo']);
    });

    test('apagar borra lo programado', () async {
      notificador.concede = true;
      await control().activar(OrigenDelPermiso.ajustes);
      await control().apagar();
      expect(notificador.programados, isEmpty);
    });

    test('lo que se mide lo acepta el contrato', () async {
      notificador.concede = true;
      await control().activar(OrigenDelPermiso.ajustes);
      await control().cupoAgotado(ahora: ahora);
      for (final e in analitica.eventos) {
        expect(
          propiedadesValidas(e.$1, e.$2, plataforma: 'android'),
          isNotNull,
          reason: '${e.$1.nombre} ${e.$2}',
        );
      }
    });
  });

  testWidgets('la pantalla previa: «Ahora no» no pide el permiso', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final notificador = _Notificador();
    final analitica = _Analitica();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificadorProvider.overrideWithValue(notificador),
          analiticaProvider.overrideWithValue(analitica),
        ],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => ofrecerRecordatorio(context, ref),
                child: const Text('terminar'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('terminar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Te recuerdo practicar cada día?'), findsOneWidget);
    expect(find.textContaining('8:00'), findsOneWidget);

    await tester.tap(find.text('Ahora no'));
    await tester.pumpAndSettle();
    expect(notificador.pedidos, 0);
    expect(analitica.registrados, [
      'notif_permiso respuesta=ahora_no origen=pre_pantalla',
    ]);
  });

  test('notif_abierta sale del payload', () {
    expect(propiedadesDeAbierta('diario:racha'), {
      'tipo': 'diario',
      'variante': 'racha',
    });
    expect(propiedadesDeAbierta('otra:cosa'), isNull);
  });
}

class _Notificador implements Notificador {
  bool concede = false;
  var pedidos = 0;
  List<AvisoProgramado> programados = const [];

  @override
  Future<void> iniciar({
    required void Function(String payload) alTocar,
  }) async {}

  @override
  Future<String?> payloadDeArranque() async => null;

  @override
  Future<bool> pedirPermiso() async {
    pedidos++;
    return concede;
  }

  @override
  Future<bool> permitidos() async => concede;

  @override
  Future<void> reemplazar(List<AvisoProgramado> avisos) async =>
      programados = avisos;
}

class _Analitica implements Analitica {
  final registrados = <String>[];
  final eventos = <(Evento, Map<String, String>)>[];

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) {
    eventos.add((evento, propiedades));
    registrados.add(
      [
        evento.nombre,
        for (final p in propiedades.entries) '${p.key}=${p.value}',
      ].join(' '),
    );
  }

  @override
  Future<void> enviarPendientes() async {}
}
