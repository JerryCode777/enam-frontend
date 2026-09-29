import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:enam_app/features/universidades/data/universidades_repository.dart';
import 'package:enam_app/features/universidades/domain/universidad.dart';
import 'package:enam_app/features/universidades/presentation/buscador_de_universidad.dart';
import 'package:enam_app/features/universidades/presentation/universidades_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

/// El buscador de universidades, en pantalla.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Future<EleccionDeUniversidad?> abrir(
    WidgetTester tester, {
    List<Universidad> catalogo = MockUniversidadesRepository.catalogoDeEjemplo,
  }) async {
    tester.view
      ..physicalSize = const Size(393, 852) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    EleccionDeUniversidad? resultado;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          universidadesRepositoryProvider.overrideWithValue(_Fijo(catalogo)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async =>
                    resultado = await elegirUniversidad(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return resultado;
  }

  testWidgets('se busca por nombre, sin tildes ni mayúsculas', (tester) async {
    await abrir(tester);
    await tester.enterText(find.byType(TextField), 'SAN AGUSTIN');
    await tester.pumpAndSettle();

    expect(
      find.text('Universidad Nacional de San Agustín de Arequipa'),
      findsOneWidget,
    );
    expect(find.text('Universidad Peruana Cayetano Heredia'), findsNothing);
  });

  testWidgets('devuelve el id del catálogo', (tester) async {
    late Future<EleccionDeUniversidad?> futuro;
    tester.view
      ..physicalSize = const Size(393, 852) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          universidadesRepositoryProvider.overrideWithValue(
            _Fijo(MockUniversidadesRepository.catalogoDeEjemplo),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => futuro = elegirUniversidad(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'UNMSM');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Universidad Nacional Mayor de San Marcos'));
    await tester.pumpAndSettle();

    final elegida = await futuro;
    expect(elegida?.id, 'unmsm');
    expect(elegida?.nombre, 'Universidad Nacional Mayor de San Marcos');
  });

  testWidgets('«Otra»: el nombre escrito, con id otra', (tester) async {
    late Future<EleccionDeUniversidad?> futuro;
    tester.view
      ..physicalSize = const Size(393, 852) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          universidadesRepositoryProvider.overrideWithValue(
            _Fijo(MockUniversidadesRepository.catalogoDeEjemplo),
          ),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => futuro = elegirUniversidad(context),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Oxford');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mi universidad no está en la lista'));
    await tester.pumpAndSettle();

    // Lo buscado pasa al campo del nombre.
    expect(find.widgetWithText(TextField, 'Oxford'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Universidad de Oxford');
    await tester.pump();
    await tester.tap(find.text('Usar este nombre'));
    await tester.pumpAndSettle();

    final elegida = await futuro;
    expect(elegida, (id: 'otra', nombre: 'Universidad de Oxford'));
  });

  testWidgets('sin red ni copia del catálogo, se puede escribir «Otra»', (
    tester,
  ) async {
    await abrir(tester, catalogo: const []);

    expect(
      find.textContaining('No pudimos cargar la lista de universidades'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(find.text('Usar este nombre'), findsOneWidget);
  });

  testWidgets('Editar perfil muestra por id y guarda el id', (tester) async {
    tester.view
      ..physicalSize = const Size(393, 1200) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final auth = _AuthQueAnota();
    // La sesión ya cargada, como en la app al llegar a esta pantalla.
    final c = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        authControllerProvider.overrideWith(_ConSesion.new),
        universidadesRepositoryProvider.overrideWithValue(
          _Fijo(MockUniversidadesRepository.catalogoDeEjemplo),
        ),
      ],
    );
    addTearDown(c.dispose);
    await tester.runAsync(() => c.read(authControllerProvider.future));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: GoRouter(
            initialLocation: '/editar',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Text('ajustes'),
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (_, _) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // El perfil trae el id y un texto viejo: se ve el nombre del catálogo.
    expect(find.text('Universidad Nacional de Trujillo'), findsOneWidget);
    expect(find.text('UNT'), findsNothing);

    await tester.tap(find.text('Universidad Nacional de Trujillo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'cayetano');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Universidad Peruana Cayetano Heredia'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    expect(auth.universidadId, 'upch');
    expect(auth.universidad, 'Universidad Peruana Cayetano Heredia');
  });
}

class _Fijo implements UniversidadesRepository {
  _Fijo(this._lista);
  final List<Universidad> _lista;

  @override
  Future<List<Universidad>> catalogo() async => _lista;
}

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => AuthSignedIn(
    User(
      id: 'u1',
      email: 'a@b.pe',
      nombre: 'Ana',
      emailVerificado: true,
      universidadId: 'unt',
      universidad: 'UNT',
      condicion: StudentCondition.interno,
      fechaObjetivo: DateTime(2026, 12, 12),
    ),
  );
}

class _AuthQueAnota extends MockAuthRepository {
  String? universidadId;
  String? universidad;

  @override
  Future<User> updateProfile({
    String? nombre,
    String? universidadId,
    String? universidad,
    StudentCondition? condicion,
    DateTime? fechaObjetivo,
    bool? ocultoEnRanking,
  }) async {
    this.universidadId = universidadId;
    this.universidad = universidad;
    return User(
      id: 'u1',
      email: 'a@b.pe',
      nombre: nombre ?? 'Ana',
      emailVerificado: true,
      universidadId: universidadId,
      universidad: universidad,
    );
  }
}
