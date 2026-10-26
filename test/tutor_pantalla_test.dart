import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/tutor/data/tutor_repository.dart';
import 'package:enam_app/features/tutor/domain/tutor_models.dart';
import 'package:enam_app/features/tutor/presentation/tutor_controller.dart';
import 'package:enam_app/features/tutor/presentation/tutor_screen.dart';
import 'package:enam_app/features/tutor/presentation/widgets/piezas_del_tutor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// La pantalla del tutor contra el doble, que responde por trozos como el
/// servidor (TUTOR-CONTRATO v3).
void main() {
  testWidgets('el estado vacío ofrece una sugerencia por categoría', (
    tester,
  ) async {
    await _montar(tester, _rapido());

    expect(find.text('¿En qué te ayudo hoy?'), findsOneWidget);
    expect(find.text('ENTENDER'), findsOneWidget);
    expect(find.text('PRACTICAR'), findsOneWidget);
    expect(find.text('PLAN'), findsOneWidget);
    // El nombre del servidor; el doble no manda ninguno.
    expect(find.text('Tu tutor ENAM'), findsOneWidget);
  });

  testWidgets('una sugerencia se responde por partes, con citas y opciones', (
    tester,
  ) async {
    final fake = _rapido();
    await _montar(tester, fake);

    await tester.tap(
      find.text('¿Por qué la metformina es primera línea en DM2?'),
    );
    await tester.pump();
    // Lo primero es «Pensando…», antes del primer trozo.
    expect(find.text('Pensando…'), findsOneWidget);

    await _esperar(tester);
    expect(fake.enviados.single.tipo, TipoDeMensaje.sugerencia);
    expect(find.text('Pensando…'), findsNothing);
    expect(find.text('Metformina en la DM2'), findsOneWidget);
    expect(find.text('Ver pregunta'), findsOneWidget);
    expect(find.text('Ver clase'), findsOneWidget);
    // Los marcadores no se ven como texto.
    expect(find.textContaining('[pregunta', findRichText: true), findsNothing);
    expect(find.text('Sí, pregúntame'), findsOneWidget);

    // Una respuesta rápida es un mensaje más, y ya no se ofrece dos veces.
    await tester.tap(find.text('Sí, pregúntame'));
    await _esperar(tester);
    expect(fake.enviados.last.mensaje, 'Sí, pregúntame');
    expect(fake.enviados.last.tipo, TipoDeMensaje.sugerencia);
    expect(find.text('Sí, pregúntame'), findsOneWidget); // la burbuja
    expect(find.text('Practicar ahora'), findsOneWidget);
  });

  testWidgets('«Practicar ahora» crea la práctica solo al tocar', (
    tester,
  ) async {
    await _montar(tester, _rapido());
    await _escribir(tester, 'Quiero practicar');
    expect(find.text('Practicar ahora'), findsOneWidget);
    expect(find.textContaining('10 preguntas de Gine'), findsOneWidget);

    await tester.tap(find.text('Empezar'));
    await _esperar(tester);
    expect(find.textContaining('PRACTICA practica-'), findsOneWidget);
  });

  testWidgets('el chip de una pregunta la abre con su explicación', (
    tester,
  ) async {
    await _montar(tester, _rapido());
    await _escribir(tester, 'Explícame la metformina');

    await tester.tap(find.text('Ver pregunta'));
    await _esperar(tester);
    // El doble sirve la pregunta 2 del banco falso, la de la gestante.
    expect(find.textContaining('Gestante de 32 años'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Por qué es esta'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Por qué es esta'), findsOneWidget);
  });

  testWidgets('desde una pregunta, el contexto viaja con el primer mensaje', (
    tester,
  ) async {
    final fake = _rapido();
    await _montar(
      tester,
      fake,
      contexto: const ContextoDelTutor.pregunta(
        id: 'q-7',
        enunciado: 'Paciente varón de 58 años…',
      ),
    );

    expect(find.text('¿Qué quieres saber de esta pregunta?'), findsOneWidget);
    expect(find.text('Paciente varón de 58 años…'), findsOneWidget);

    await tester.tap(find.text('¿Por qué esta es la correcta?'));
    await _esperar(tester);
    await _escribir(tester, 'Y la B?');

    expect([for (final e in fake.enviados) e.preguntaId], ['q-7', null]);
  });

  testWidgets('👍 se guarda y tocarlo otra vez lo quita', (tester) async {
    final fake = _rapido();
    await _montar(tester, fake);
    await _escribir(tester, 'Hola');

    await tester.tap(find.byTooltip('Me sirvió'));
    await tester.pump();
    expect(fake.valoraciones, {'tmsg-1': true});

    await tester.tap(find.byTooltip('Me sirvió'));
    await tester.pump();
    expect(fake.valoraciones, {'tmsg-1': null});
  });

  testWidgets('«No entiendo» abre un formulario y manda un mensaje', (
    tester,
  ) async {
    final fake = _rapido();
    await _montar(tester, fake);
    await _escribir(tester, 'Hola');

    await tester.tap(find.byTooltip('No entiendo'));
    await tester.pump();
    expect(find.text('¿Qué parte no entendiste?'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(
        TextField,
        'Por ejemplo: no entiendo por qué no es la B',
      ),
      'lo de la TFG',
    );
    await tester.tap(find.text('Enviar'));
    await _esperar(tester);

    expect(fake.enviados.last.tipo, TipoDeMensaje.noEntiendo);
    expect(fake.enviados.last.mensaje, 'No entendí esto: lo de la TFG');
    expect(
      find.textContaining('cerrar la llave', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('si se corta a mitad, deja lo recibido y ofrece reintentar', (
    tester,
  ) async {
    final fake = _rapido(fallarAMitad: true);
    await _montar(tester, fake);
    await _escribir(tester, 'Hola');

    expect(
      find.text('Se cortó la respuesta del tutor. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Me sirvió'), findsNothing);

    await tester.tap(find.text('Reintentar'));
    await _esperar(tester);
    expect(fake.enviados.last.tipo, TipoDeMensaje.reintento);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.byTooltip('Me sirvió'), findsOneWidget);
  });

  testWidgets('el contador sale con pocos mensajes y, al acabarse, el muro', (
    tester,
  ) async {
    await _montar(tester, _rapido(restantesPrueba: 6));
    expect(find.textContaining('Te quedan'), findsNothing);

    await _escribir(tester, 'Hola');
    expect(find.text('Te quedan 5 mensajes de prueba'), findsOneWidget);

    for (var i = 0; i < 5; i++) {
      await _escribir(tester, 'Otra $i');
    }
    expect(find.text('Te quedan 1 mensajes de prueba'), findsNothing);

    // El 403 FUNCION_PREMIUM {funcion: tutor}: el muro, con el tutor de motivo.
    await _escribir(tester, 'Una más');
    expect(find.text('MURO tutor'), findsOneWidget);

    // Al cerrarlo queda la tarjeta en lugar de la caja de texto.
    final router = GoRouter.of(tester.element(find.text('MURO tutor')));
    router.pop();
    await _esperar(tester);
    expect(find.text('Usaste tus mensajes de prueba'), findsOneWidget);
    expect(find.text('Ver Premium'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  group('«Pregúntale al tutor»', () {
    testWidgets('no ocupa nada con el interruptor apagado', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tutorActivoProvider.overrideWithValue(false),
            tutorRepositoryProvider.overrideWithValue(_rapido()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: PreguntaleAlTutor(preguntaId: 'q-1')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Pregúntale al tutor'), findsNothing);
    });

    testWidgets('abre el tutor con la pregunta como contexto', (tester) async {
      final fake = _rapido();
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(
              body: PreguntaleAlTutor(
                preguntaId: 'q-3',
                enunciado: 'Gestante…',
              ),
            ),
          ),
          GoRoute(
            path: Routes.tutor,
            builder: (_, s) =>
                TutorScreen(contexto: s.extra! as ContextoDelTutor),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            tutorActivoProvider.overrideWithValue(true),
            tutorRepositoryProvider.overrideWithValue(fake),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await _esperar(tester);

      await tester.tap(find.text('Pregúntale al tutor'));
      await _esperar(tester);
      expect(find.text('Gestante…'), findsOneWidget);
    });
  });
}

/// El doble sin las pausas entre palabras: la prueba no mide la velocidad.
FakeTutorRepository _rapido({
  bool fallarAMitad = false,
  int restantesPrueba = 15,
}) => FakeTutorRepository(
  pausa: Duration.zero,
  pensar: const Duration(milliseconds: 100),
  fallarAMitad: fallarAMitad,
  restantesPrueba: restantesPrueba,
);

Future<void> _montar(
  WidgetTester tester,
  FakeTutorRepository fake, {
  ContextoDelTutor contexto = const ContextoDelTutor(),
}) async {
  tester.view.physicalSize = const Size(412, 915) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final router = GoRouter(
    initialLocation: Routes.tutor,
    routes: [
      GoRoute(
        path: Routes.tutor,
        builder: (_, _) => TutorScreen(contexto: contexto),
      ),
      GoRoute(
        path: Routes.premium,
        builder: (_, s) =>
            Scaffold(body: Text('MURO ${s.uri.queryParameters['funcion']}')),
      ),
      GoRoute(
        path: Routes.practiceSession,
        builder: (_, s) =>
            Scaffold(body: Text('PRACTICA ${s.pathParameters['id']}')),
      ),
      GoRoute(
        path: Routes.clase,
        builder: (_, s) =>
            Scaffold(body: Text('CLASE ${s.pathParameters['clase']}')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        tutorActivoProvider.overrideWithValue(true),
        tutorRepositoryProvider.overrideWithValue(fake),
        sessionRepositoryProvider.overrideWithValue(MockSessionRepository()),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    ),
  );
  await _esperar(tester);
}

Future<void> _escribir(WidgetTester tester, String texto) async {
  await tester.enterText(find.byType(TextField).last, texto);
  await tester.pump();
  await tester.tap(find.byTooltip('Enviar'));
  await _esperar(tester);
}

/// El doble responde con pausas y el avatar late mientras piensa, así que no
/// se puede esperar a que todo se calme: se avanza el reloj a mano.
Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
