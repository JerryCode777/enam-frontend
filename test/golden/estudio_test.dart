@Tags(['golden'])
library;

import 'package:enam_app/core/domain/hora_peru.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/offline/domain/offline_models.dart';
import 'package:enam_app/features/offline/presentation/downloads_screen.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/practice_config_screen.dart';
import 'package:enam_app/features/session/presentation/question_screen.dart';
import 'package:enam_app/features/session/presentation/session_summary_screen.dart';
import 'package:enam_app/features/session/presentation/simulacro_hub_screen.dart';
import 'package:enam_app/features/session/presentation/widgets/option_card.dart';
import 'package:enam_app/features/stats/presentation/progress_screen.dart';
import 'package:enam_app/features/subscription/presentation/access_ended_screen.dart';
import 'package:enam_app/features/subscription/presentation/my_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../ayuda/offline.dart';
import '_comun.dart';

/// Banco de capturas de las pantallas de estudio y de cuenta.
///
/// Complementa a `pantallas_test.dart`, que retrata el acceso y el inicio. Aquí
/// van las que el rediseño toca de lleno —la pregunta, su explicación, el
/// resultado, el progreso, la compra y las descargas— y que antes no tenían
/// captura con la que comparar el antes y el después.
///
/// A diferencia del otro banco, estas pantallas necesitan a alguien dentro: se
/// monta un usuario con perfil completo y, para la pregunta, una práctica ya
/// creada en el repositorio de ejemplo.
///
/// ```sh
/// flutter test --update-goldens test/golden/estudio_test.dart
/// ```
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await cargarFuentes();
    congelarReloj(DateTime.utc(2026, 7, 30, 17));

    // Descargas se retrata con un área guardada y su práctica lista: vacía no
    // enseña nada de lo que el rediseño cambia.
    await _almacen.guardarPaquete(
      'u1',
      PaqueteOffline(
        areaId: 'medicina',
        generadoEn: DateTime(2026, 7, 20),
        preguntas: [preguntaDePrueba('q1')],
        total: 40,
      ),
    );
    await _almacen.guardarSesion(
      'u1',
      areaId: 'medicina',
      estado: EstadoSesionLocal.reservada,
      sesion: sesionDePrueba(),
    );
  });

  tearDownAll(soltarReloj);

  /// Cada pantalla recibe su repositorio de sesiones recién hecho, y un paso
  /// previo que la deja en el momento que se quiere retratar.
  final pantallas =
      <
        ({
          String nombre,
          Future<Widget> Function(WidgetTester, MockSessionRepository) montar,
          Future<void> Function(WidgetTester)? despues,
        })
      >[
        (
          nombre: '4.1-configurar',
          montar: (_, _) async => const PracticeConfigScreen(),
          despues: null,
        ),
        (
          nombre: '4.2-pregunta',
          montar: (t, repo) async =>
              QuestionScreen(sessionId: (await _practica(t, repo)).id),
          // Con una alternativa elegida y sin confirmar: es el estado en que
          // más tiempo pasa la pantalla.
          despues: (t) async {
            await t.tap(find.byType(OptionCard).at(1));
          },
        ),
        (
          nombre: '4.3-explicacion',
          montar: (t, repo) async =>
              QuestionScreen(sessionId: (await _practica(t, repo)).id),
          despues: (t) async {
            await t.tap(find.byType(OptionCard).first);
            await t.pump();
            await t.tap(find.text('Responder'));
          },
        ),
        (
          nombre: '4.4-resultados',
          montar: (t, repo) async {
            final sesion = await _practica(t, repo);
            await t.runAsync(() async {
              for (final (i, p) in sesion.preguntas.indexed) {
                await repo.answer(
                  sessionId: sesion.id,
                  questionId: p.id,
                  // Una de cada tres en blanco y el resto la primera: deja un
                  // resultado con aciertos, errores y en blanco a la vez.
                  optionId: i % 3 == 2 ? null : p.opciones.first.id,
                  tiempoMs: 40000,
                );
              }
              await repo.submit(sesion.id);
            });
            return SessionSummaryScreen(sessionId: sesion.id);
          },
          despues: null,
        ),
        (
          nombre: '5.1-progreso',
          montar: (_, _) async => const ProgressScreen(),
          despues: null,
        ),
        (
          nombre: '5.2-simulacros',
          montar: (_, _) async => const SimulacroHubScreen(),
          despues: null,
        ),
        (
          nombre: '8.1-descargas',
          montar: (_, _) async => const DownloadsScreen(),
          despues: null,
        ),
        (
          nombre: '9.1-acceso-terminado',
          montar: (_, _) async => const AccessEndedScreen(),
          despues: null,
        ),
        (
          nombre: '9.2-mi-suscripcion',
          montar: (_, _) async => const MySubscriptionScreen(),
          despues: null,
        ),
      ];

  for (final dispositivo in dispositivos) {
    group(dispositivo.nombre, () {
      for (final pantalla in pantallas) {
        for (final oscuro in [false, true]) {
          final tema = oscuro ? 'oscuro' : 'claro';

          testWidgets('${pantalla.nombre} · $tema', (tester) async {
            tester.view
              ..devicePixelRatio = 2
              ..physicalSize = dispositivo.tamano * 2;
            addTearDown(tester.view.reset);

            final repo = MockSessionRepository();
            final widget = await pantalla.montar(tester, repo);

            await tester.pumpWidget(
              Marco(
                tamano: dispositivo.tamano,
                oscuro: oscuro,
                overrides: _dentro(repo),
                child: widget,
              ),
            );
            for (var i = 0; i < 3; i++) {
              await tester.pump(const Duration(milliseconds: 600));
            }

            if (pantalla.despues case final paso?) {
              await paso(tester);
              for (var i = 0; i < 4; i++) {
                await tester.pump(const Duration(milliseconds: 600));
              }
            }

            // Lo que llega con pausa a propósito —la oferta de «acceso
            // terminado» aparece a los 2,2 s— se retrata ya llegado.
            await tester.pump(const Duration(seconds: 3));

            await precargarImagenes(tester);

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '_imagenes/${dispositivo.nombre}/${pantalla.nombre}-$tema.png',
              ),
            );

            // Las consultas de ejemplo que la pantalla dejó en vuelo terminan
            // aquí, con el árbol ya desmontado, en vez de quedar pendientes.
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 5));
          });
        }
      }
    });
  }
}

/// Una práctica corta del área de medicina, creada fuera del reloj falso.
///
/// El repositorio de ejemplo simula latencia con `Future.delayed`; dentro de
/// `testWidgets` ese tiempo no pasa solo, así que se crea con `runAsync`.
Future<StudySession> _practica(
  WidgetTester tester,
  MockSessionRepository repo,
) async {
  final sesion = await tester.runAsync(
    () => repo.startPractice(
      const PracticeConfig(areaIds: ['medicina'], cantidadPreguntas: 10),
    ),
  );
  return sesion!;
}

final _almacen = AlmacenEnMemoria();

List<Override> _dentro(MockSessionRepository repo) => [
  authControllerProvider.overrideWith(_ConSesion.new),
  sessionRepositoryProvider.overrideWithValue(repo),
  sessionRepositoryRemotoProvider.overrideWithValue(repo),
  almacenOfflineProvider.overrideWithValue(_almacen),
];

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => AuthSignedIn(
    User(
      id: 'u1',
      email: 'valeria.rojas@unmsm.edu.pe',
      nombre: 'Valeria Rojas',
      emailVerificado: true,
      universidad: 'UNMSM',
      condicion: StudentCondition.repitiente,
      fechaObjetivo: DateTime(2026, 12, 12),
    ),
  );
}
