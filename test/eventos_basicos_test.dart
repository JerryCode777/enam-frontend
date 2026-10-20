import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/aula/data/mock_aula_repository.dart';
import 'package:enam_app/features/aula/presentation/aula_providers.dart';
import 'package:enam_app/features/aula/presentation/curso_screen.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/presentation/eventos_de_registro.dart';
import 'package:enam_app/features/auth/presentation/register_screen.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/presentation/muro_de_venta_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Los eventos básicos que la app no mandaba (pedido del director, 20/10/2026):
/// el muro (catálogo 6), el curso (10) y el registro (19). Del 14 al 18/10 el
/// 60 % de las altas fue Android y BI casi no veía qué hacían.
///
/// El cupo agotado y la primera práctica no van aquí: `limite_alcanzado` y
/// `first_practice_completed` los emite el servidor.
void main() {
  group('Lo que viaja', () {
    test('muro_visto: con_oferta viaja como booleano, no como texto', () {
      // El servidor rechaza "false": tiene que ser false.
      expect(
        propiedadesValidas(Evento.muroVisto, {
          'motivo': 'limite',
          'recurso': 'preguntas',
          'con_oferta': 'false',
        }, plataforma: 'android'),
        {'motivo': 'limite', 'recurso': 'preguntas', 'con_oferta': false},
      );
    });

    test('muro_visto: una función que el contrato no conoce se cae sola', () {
      expect(
        propiedadesValidas(Evento.muroVisto, {
          'motivo': 'funcion',
          'funcion': 'sin_conexion',
          'con_oferta': 'false',
        }, plataforma: 'ios'),
        {'motivo': 'funcion', 'con_oferta': false},
      );
      // Sin con_oferta, que es obligatoria, ni se encola.
      expect(
        propiedadesValidas(Evento.muroVisto, {
          'motivo': 'limite',
          'con_oferta': 'no',
        }, plataforma: 'ios'),
        isNull,
      );
    });

    test('curso_visto: curso_id con el patrón del contrato', () {
      expect(
        propiedadesValidas(Evento.cursoVisto, {
          'curso_id': 'gineco-obstetricia',
          'desde': 'catalogo',
        }, plataforma: 'android'),
        {'curso_id': 'gineco-obstetricia', 'desde': 'catalogo'},
      );
      expect(
        propiedadesValidas(Evento.cursoVisto, {
          'curso_id': 'Ginecología y Obstetricia',
          'desde': 'catalogo',
        }, plataforma: 'android'),
        isNull,
      );
    });

    test('registro_fallido: solo lo del contrato', () {
      expect(
        propiedadesValidas(Evento.registroFallido, {
          'metodo': 'google',
          'motivo': 'proveedor_cancelado',
          'pantalla': 'login',
          'dispositivo': 'celular',
          'email': 'valeria@unmsm.edu.pe',
        }, plataforma: 'android'),
        {
          'metodo': 'google',
          'motivo': 'proveedor_cancelado',
          'pantalla': 'login',
          'dispositivo': 'celular',
        },
      );
    });

    test('el motivo de cada fallo', () {
      expect(
        motivoDeFallo(const ValidationFailure('x', code: 'EMAIL_TAKEN')),
        'correo_en_uso',
      );
      expect(
        motivoDeFallo(const ValidationFailure('x', code: 'CONSENT_REQUIRED')),
        'terminos_sin_marcar',
      );
      expect(motivoDeFallo(const ValidationFailure('x')), 'validacion');
      expect(motivoDeFallo(const UnauthorizedFailure()), 'datos_invalidos');
      expect(motivoDeFallo(const NetworkFailure()), 'red');
      expect(motivoDeFallo(const TimeoutFailure()), 'red');
      expect(motivoDeFallo(const ServerFailure()), 'otro');
      // Lo que no es Failure viene de Google o Apple.
      expect(motivoDeFallo(Exception('sign_in_failed')), 'proveedor_error');
    });
  });

  group('En pantalla', () {
    late List<(Evento, Map<String, String>)> registrados;
    setUp(() => registrados = []);

    Override capturar() =>
        analiticaProvider.overrideWithValue(_Capturadora(registrados));

    testWidgets('el muro del cupo: muro_visto, y plans_viewed sigue', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [capturar()],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MuroDeVentaScreen(motivo: CupoAgotado()),
          ),
        ),
      );
      await tester.pump();

      expect(registrados.map((e) => e.$1), [
        Evento.plansViewed,
        Evento.muroVisto,
      ]);
      expect(registrados.last.$2, {
        'motivo': 'limite',
        'recurso': 'preguntas',
        'con_oferta': 'false',
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('el muro de una función: su código', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [capturar()],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const MuroDeVentaScreen(
              motivo: FuncionDePago(FuncionPremium.simulacro),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(registrados.last.$2, {
        'motivo': 'funcion',
        'funcion': 'simulacro',
        'con_oferta': 'false',
      });
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('el curso desde el catálogo: curso_visto una vez', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capturar(),
            aulaRepositoryProvider.overrideWithValue(
              MockAulaRepository(delay: Duration.zero),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CursoScreen(cursoId: 'medicina', desde: 'catalogo'),
          ),
        ),
      );
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(registrados, hasLength(1));
      expect(registrados.single.$1, Evento.cursoVisto);
      expect(registrados.single.$2, {
        'curso_id': 'medicina',
        'desde': 'catalogo',
      });
    });

    testWidgets('sin origen conocido, no se inventa uno', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capturar(),
            aulaRepositoryProvider.overrideWithValue(
              MockAulaRepository(delay: Duration.zero),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            home: const CursoScreen(cursoId: 'medicina'),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(registrados, isEmpty);
    });

    test('la ruta lleva el origen', () {
      expect(
        Routes.cursoOf('medicina', desde: 'catalogo'),
        '/cursos/medicina?desde=catalogo',
      );
      expect(Routes.cursoOf('medicina'), '/cursos/medicina');
    });

    testWidgets('registro: visto al abrir, y fallido con el correo en uso', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(393, 1200) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capturar(),
            authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            routerConfig: GoRouter(
              initialLocation: Routes.register,
              routes: [
                GoRoute(
                  path: Routes.register,
                  builder: (_, _) => const RegisterScreen(),
                ),
                GoRoute(
                  path: Routes.verifyEmail,
                  builder: (_, _) => const Text('verificar'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(registrados.single.$1, Evento.registroVisto);
      expect(registrados.single.$2, {'dispositivo': 'celular'});

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Valeria Rojas');
      await tester.enterText(campos.at(1), 'existente@enam.pe');
      await tester.enterText(campos.at(2), 'una-clave-larga');
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      await tester.tap(find.text('Crear cuenta'));
      // El doble responde con una espera, como la red.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(registrados.last.$1, Evento.registroFallido);
      expect(registrados.last.$2, {
        'metodo': 'correo',
        'motivo': 'correo_en_uso',
        'pantalla': 'registro',
        'dispositivo': 'celular',
      });
      await tester.pump(const Duration(seconds: 5));
    });
  });
}

class _Capturadora implements Analitica {
  _Capturadora(this.eventos);

  final List<(Evento, Map<String, String>)> eventos;

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) =>
      eventos.add((evento, propiedades));

  @override
  Future<void> enviarPendientes() async {}
}
