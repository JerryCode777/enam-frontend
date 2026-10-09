import 'dart:io';

import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/aula/data/mock_aula_repository.dart';
import 'package:enam_app/features/aula/presentation/aula_providers.dart';
import 'package:enam_app/features/aula/presentation/clase_screen.dart';
import 'package:enam_app/features/aula/presentation/curso_screen.dart';
import 'package:enam_app/features/aula/presentation/cursos_screen.dart';
import 'package:enam_app/features/aula/presentation/widgets/presentacion.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Las pantallas del aula con el doble del servidor.
///
/// El doble es el de los mocks: once cursos, el repaso final entre ellos, dos
/// sin clases, y en cada curso con clases tres gratis, una que viene y una a
/// medias. El reproductor tiene su propia prueba.
void main() {
  late GoRouter router;

  /// Lleva [f] a la vista y lo toca. Falla si el toque no le llega.
  Future<void> tocar(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  Widget montar(
    WidgetTester tester, {
    required String en,
    bool premium = true,
    bool conPortadas = false,
  }) {
    // Un teléfono: con el 800×600 por defecto, la lista perezosa deja fuera
    // la mitad de lo que se prueba.
    tester.view
      ..devicePixelRatio = 3
      ..physicalSize = const Size(412 * 3, 915 * 3);
    addTearDown(tester.view.reset);
    router = GoRouter(
      initialLocation: en,
      routes: [
        GoRoute(
          path: Routes.cursos,
          builder: (_, _) => const CursosScreen(),
          routes: [
            GoRoute(
              path: ':curso',
              builder: (_, s) =>
                  CursoScreen(cursoId: s.pathParameters['curso']!),
              routes: [
                GoRoute(
                  path: 'clase/:clase',
                  builder: (_, s) => ClaseScreen(
                    cursoId: s.pathParameters['curso']!,
                    claseId: s.pathParameters['clase']!,
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: Routes.practiceSession,
          builder: (_, s) => Text('Sesión ${s.pathParameters['id']}'),
        ),
        GoRoute(
          path: Routes.accessEnded,
          builder: (_, _) => const Text('Pago'),
        ),
      ],
    );
    return ProviderScope(
      overrides: [
        aulaRepositoryProvider.overrideWithValue(
          MockAulaRepository(
            premium: premium,
            conPortadas: conPortadas,
            sesiones: _Sesiones(),
            delay: Duration.zero,
          ),
        ),
        imagenDeRedProvider.overrideWithValue(_portadaLocal),
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: router),
    );
  }

  group('Catálogo', () {
    testWidgets('el repaso final va primero y destacado', (tester) async {
      await tester.pumpWidget(montar(tester, en: Routes.cursos));
      await tester.pumpAndSettle();

      expect(find.text('Cursos'), findsOneWidget);
      expect(find.text('Para las últimas semanas'), findsOneWidget);
      final repaso = tester.getTopLeft(find.text('Repaso final ENAM').first);
      final medicina = tester.getTopLeft(find.text('Medicina').first);
      expect(repaso.dy, lessThan(medicina.dy));
    });

    testWidgets('«Seguir viendo» lleva a la clase a medias', (tester) async {
      await tester.pumpWidget(montar(tester, en: Routes.cursos));
      await tester.pumpAndSettle();

      expect(find.text('Seguir viendo · Pediatría'), findsOneWidget);
      await tocar(tester, find.text('Seguir viendo · Pediatría'));

      expect(
        router.state.uri.path,
        Routes.claseOf('pediatria', 'pediatria.01-02'),
      );
    });

    testWidgets('un curso sin clases sale como «Próximamente» y no se abre', (
      tester,
    ) async {
      await tester.pumpWidget(montar(tester, en: Routes.cursos));
      await tester.pumpAndSettle();

      await tocar(tester, find.text('¿Quién es el responsable?'));

      expect(router.state.uri.path, Routes.cursos);
    });
  });

  group('Curso', () {
    testWidgets('con algo visto, el botón es «Seguir con el curso»', (
      tester,
    ) async {
      await tester.pumpWidget(montar(tester, en: Routes.cursoOf('pediatria')));
      await tester.pumpAndSettle();

      expect(find.text('1 de 9 clases vistas'), findsOneWidget);
      await tocar(tester, find.text('Seguir con el curso'));

      // `continuar` lo decide el servidor: la primera sin completar.
      expect(
        router.state.uri.path,
        Routes.claseOf('pediatria', 'pediatria.01-02'),
      );
    });

    testWidgets('sin nada visto, «Empezar el curso»', (tester) async {
      await tester.pumpWidget(montar(tester, en: Routes.cursoOf('medicina')));
      await tester.pumpAndSettle();

      expect(find.text('Empezar el curso'), findsOneWidget);
    });

    testWidgets('en gratis: «Gratis» en la muestra y candado en el resto', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(tester, en: Routes.cursoOf('medicina'), premium: false),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Tienes 3 clases gratis'), findsOneWidget);
      expect(find.text('Gratis'), findsNWidgets(3));

      // Una clase con candado abre el muro sin pedir la clase.
      await tocar(tester, find.text('Esquema nacional de vacunación'));

      expect(find.text('Los cursos completos son de Premium'), findsOneWidget);
      expect(router.state.uri.path, Routes.cursoOf('medicina'));
    });
  });

  group('Muro en Android', () {
    // Los tests corren en el host, que no es iOS: es la variante de Android.
    testWidgets('no ofrece comprar: ni «Ver Premium» ni precio', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(tester, en: Routes.cursoOf('medicina'), premium: false),
      );
      await tester.pumpAndSettle();

      // Tampoco el aviso de las clases gratis lleva botón.
      expect(find.text('Ver Premium'), findsNothing);

      await tocar(tester, find.text('Esquema nacional de vacunación'));

      expect(find.text('Ver Premium'), findsNothing);
      expect(
        find.text('Tu acceso Premium se activa con tu cuenta de ENAM Prep.'),
        findsOneWidget,
      );
      expect(find.text('Entendido'), findsOneWidget);
    });
  });

  group('Portadas compuestas', () {
    testWidgets('en el catálogo, la portada sola: sin lema ni profe encima', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(tester, en: Routes.cursos, conPortadas: true),
      );
      await tester.pumpAndSettle();

      // La portada ya trae el nombre, el profe y las clases.
      expect(find.text('Esto cae seguro'), findsNothing);
      expect(find.text('Profe Andrea'), findsNothing);
      expect(find.text('Para las últimas semanas'), findsNothing);
      // El título queda para el lector de pantalla.
      expect(find.bySemanticsLabel('Repaso final ENAM'), findsOneWidget);
    });

    testWidgets('debajo de la portada, el avance y «Seguir viendo»', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(tester, en: Routes.cursos, conPortadas: true),
      );
      await tester.pumpAndSettle();

      // La lista es perezosa: Pediatría está más abajo.
      await tester.scrollUntilVisible(
        find.text('1 de 9 vistas'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('1 de 9 vistas'), findsOneWidget);

      // Solo en la tarjeta del curso a medias.
      final seguir = find.widgetWithText(TextButton, 'Seguir viendo');
      expect(seguir, findsOneWidget);
      await tocar(tester, seguir);

      expect(
        router.state.uri.path,
        Routes.claseOf('pediatria', 'pediatria.01-02'),
      );
    });

    testWidgets('en el curso: portada, avance y el botón, sin lema ni profe', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(tester, en: Routes.cursoOf('pediatria'), conPortadas: true),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Pediatría'), findsOneWidget);
      expect(find.text('Primero, la norma'), findsNothing);
      expect(find.text('Profe del curso'), findsNothing);
      expect(find.text('1 de 9 clases vistas'), findsOneWidget);
      expect(find.text('Seguir con el curso'), findsOneWidget);
    });

    test('la caché no cambia con la firma', () {
      // CloudFront firma cada vez distinto: con la URL entera como clave, la
      // portada se volvería a bajar y decodificar en cada visita.
      const a =
          'https://cdn.example/medicina/portada-v2.jpg?Expires=1&Signature=a';
      const b =
          'https://cdn.example/medicina/portada-v2.jpg?Expires=2&Signature=b';
      expect(sinFirma(a), sinFirma(b));

      final imagen = ProviderContainer().read(imagenDeRedProvider);
      expect(imagen(a, ancho: 800), imagen(b, ancho: 800));
      expect(imagen(a, ancho: 800), isNot(imagen(a, ancho: 1200)));
    });
  });

  group('Los profes', () {
    // Jerry: nunca se dice cómo están hechos los profes ni sus voces.
    const prohibidas = [
      'virtual',
      'ilustrad',
      'voz generada',
      'inteligencia artificial',
    ];

    for (final (nombre, ruta) in [
      ('el catálogo', Routes.cursos),
      ('el curso', Routes.cursoOf('pediatria')),
      ('la clase', Routes.claseOf('pediatria', 'pediatria.01-03')),
    ]) {
      testWidgets('en $nombre no se dice cómo están hechos', (tester) async {
        await tester.pumpWidget(montar(tester, en: ruta));
        await tester.pumpAndSettle();
        // Hasta el final de la página, que es donde iba el aviso.
        await tester.drag(
          find.byType(Scrollable).first,
          const Offset(0, -6000),
        );
        await tester.pumpAndSettle();

        final textos = tester
            .widgetList<Text>(find.byType(Text))
            .map(
              (t) => (t.data ?? t.textSpan?.toPlainText() ?? '').toLowerCase(),
            )
            .join('\n');
        for (final p in prohibidas) {
          expect(textos, isNot(contains(p)), reason: '«$p» en $nombre');
        }
      });
    }

    testWidgets('el profe es «Profe del curso»', (tester) async {
      await tester.pumpWidget(montar(tester, en: Routes.cursoOf('pediatria')));
      await tester.pumpAndSettle();

      expect(find.text('Profe del curso'), findsOneWidget);
    });
  });

  group('Clase', () {
    testWidgets('«Practicar este tema» abre la sesión de práctica', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(tester, en: Routes.claseOf('pediatria', 'pediatria.01-03')),
      );
      await tester.pumpAndSettle();

      // El título, y la fila en el temario de abajo.
      expect(find.text('Desnutrición crónica infantil'), findsWidgets);
      await tocar(tester, find.text('Practicar este tema'));

      expect(find.text('Sesión practica-aula'), findsOneWidget);
    });

    testWidgets('las referencias, con su tipo y su fuente', (tester) async {
      await tester.pumpWidget(
        montar(tester, en: Routes.claseOf('pediatria', 'pediatria.01-03')),
      );
      await tester.pumpAndSettle();

      await tocar(tester, find.text('Referencias (2)'));

      expect(find.text('R1 · Norma'), findsOneWidget);
      expect(find.text('R2 · Libro'), findsOneWidget);
      expect(find.text('21.ª ed. · cap. 482 · 2020'), findsOneWidget);
      expect(find.text('Abrir la fuente'), findsOneWidget);
    });

    testWidgets('una clase de pago abre el muro y deja el aviso detrás', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(
          tester,
          en: Routes.claseOf('medicina', 'medicina.01-04'),
          premium: false,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Los cursos completos son de Premium'), findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();

      expect(find.text('Esta clase es de Premium'), findsOneWidget);
      expect(find.text('Ver el temario'), findsOneWidget);
    });

    testWidgets('sin video: «Esta clase llega pronto», sin práctica', (
      tester,
    ) async {
      await tester.pumpWidget(
        montar(tester, en: Routes.claseOf('pediatria', 'pediatria.02-05')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Esta clase llega pronto'), findsOneWidget);
      expect(find.text('Practicar este tema'), findsNothing);
    });
  });
}

/// Arma la sesión de la práctica sin latencia.
class _Sesiones extends MockSessionRepository {
  @override
  Future<StudySession> startPractice(PracticeConfig config) async =>
      StudySession(
        id: 'practica-aula',
        tipo: SessionType.practica,
        estado: SessionStatus.enCurso,
        iniciadaEn: DateTime(2026, 10, 9),
      );
}

/// Las portadas de prueba: las de producción, reducidas, en
/// `test/fixtures/portadas`. Un curso sin la suya usa la de Medicina.
ImageProvider _portadaLocal(String url, {int? ancho}) {
  final curso = Uri.parse(url).pathSegments.first;
  // Una por curso, siempre la misma: un MemoryImage nuevo es otra clave para
  // la caché, y la imagen se volvería a cargar en cada construcción.
  return _portadas.putIfAbsent(curso, () {
    final archivo = File('test/fixtures/portadas/$curso.jpg');
    return MemoryImage(
      (archivo.existsSync()
              ? archivo
              : File('test/fixtures/portadas/medicina.jpg'))
          .readAsBytesSync(),
    );
  });
}

final _portadas = <String, MemoryImage>{};
