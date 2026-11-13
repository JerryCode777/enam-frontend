import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/domain/correo.dart';
import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/presentation/register_screen.dart';
import 'package:enam_app/features/auth/presentation/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Correos mal escritos al registrarse (`gmail.con`, `outlok.es`): el código
/// no llegaba y la persona se registraba de nuevo con otro correo. 28 casos
/// en 30 días, casi todos desde la app.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('sugerenciaDeCorreo', () {
    test('los errores de tipeo de siempre', () {
      expect(sugerenciaDeCorreo('ana@gmail.con'), 'ana@gmail.com');
      expect(sugerenciaDeCorreo('ana@hotmail.con'), 'ana@hotmail.com');
      expect(sugerenciaDeCorreo('ana@outlok.es'), 'ana@outlook.es');
      expect(sugerenciaDeCorreo('ana@gmial.com'), 'ana@gmail.com');
      expect(sugerenciaDeCorreo('ana@gmai.com'), 'ana@gmail.com');
      expect(sugerenciaDeCorreo('ana@hotmial.com'), 'ana@hotmail.com');
      expect(sugerenciaDeCorreo('ana@yaho.com'), 'ana@yahoo.com');
      expect(sugerenciaDeCorreo('ana@gmail.co'), 'ana@gmail.com');
      expect(sugerenciaDeCorreo('ana@gmail.comgr'), 'ana@gmail.com');
      expect(sugerenciaDeCorreo('ana@umsaac.edu.pe'), 'ana@unsaac.edu.pe');
      expect(sugerenciaDeCorreo('ana@unsa.edu.p'), 'ana@unsa.edu.pe');
      expect(sugerenciaDeCorreo('ana@empresa.con'), 'ana@empresa.com');
      expect(sugerenciaDeCorreo('ana@empresa.con.pe'), 'ana@empresa.com.pe');
      expect(
        sugerenciaDeCorreo(' Ana.Perez@GMAIL.CON '),
        'Ana.Perez@gmail.com',
      );
    });

    test('los que están bien no se tocan', () {
      for (final bien in [
        'ana@gmail.com',
        'ana@hotmail.es',
        'ana@outlook.com',
        'ana@icloud.com',
        'ana@unsa.edu.pe',
        'ana@upch.pe',
        'ana@unmsm.edu.pe',
        'ana@mail.com',
        'ana@ymail.com',
        'ana@email.com',
        'ana@yahoo.com.pe',
        'ana@hospital.gob.pe',
        'ana@empresa.co',
        'ana@hotmail.com.pe',
        'ana@proton.me',
      ]) {
        expect(sugerenciaDeCorreo(bien), isNull, reason: bien);
      }
    });

    test('sin arroba o sin dominio, nada', () {
      expect(sugerenciaDeCorreo('ana'), isNull);
      expect(sugerenciaDeCorreo('ana@'), isNull);
      expect(sugerenciaDeCorreo('@gmail.con'), isNull);
    });
  });

  group('el registro', () {
    late _Auth auth;

    Future<GoRouter> montar(WidgetTester tester) async {
      auth = _Auth();
      final router = GoRouter(
        initialLocation: Routes.register,
        routes: [
          GoRoute(
            path: Routes.register,
            builder: (_, _) => const RegisterScreen(),
          ),
          GoRoute(
            path: Routes.verifyEmail,
            builder: (_, state) => switch (state.extra) {
              CodigoPorVerificar(:final email, :final password) =>
                VerifyEmailScreen(email: email, password: password),
              _ => const VerifyEmailScreen(),
            },
          ),
          GoRoute(path: Routes.login, builder: (_, _) => const SizedBox()),
        ],
      );
      await tester.binding.setSurfaceSize(const Size(412, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            analiticaProvider.overrideWithValue(_Analitica()),
            currentUserProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      return router;
    }

    Future<void> llenar(WidgetTester tester, String correo) async {
      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Ana');
      await tester.enterText(campos.at(1), correo);
      await tester.enterText(campos.at(2), 'Clave-segura-123');
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
    }

    Future<void> crear(WidgetTester tester) async {
      await tester.tap(find.text('Crear cuenta'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));
    }

    testWidgets('gmail.con: pregunta antes de crear, y corrige', (
      tester,
    ) async {
      final router = await montar(tester);
      await llenar(tester, 'ana@gmail.con');
      await crear(tester);

      expect(auth.registrados, isEmpty);
      expect(find.text('¿Quisiste decir '), findsNothing);
      expect(find.textContaining('ana@gmail.com'), findsOneWidget);

      await tester.tap(find.text('Sí, corregir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(auth.registrados, ['ana@gmail.com']);
      expect(router.state.matchedLocation, Routes.verifyEmail);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('«No, está bien» crea la cuenta con el que escribió', (
      tester,
    ) async {
      await montar(tester);
      await llenar(tester, 'ana@gmial.com');
      await crear(tester);
      await tester.tap(find.text('No, está bien'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(auth.registrados, ['ana@gmial.com']);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('un correo normal no pregunta nada', (tester) async {
      await montar(tester);
      await llenar(tester, 'ana@unsa.edu.pe');
      await crear(tester);

      expect(auth.registrados, ['ana@unsa.edu.pe']);
      expect(find.text('Sí, corregir'), findsNothing);
      await tester.pump(const Duration(seconds: 61));
    });
  });

  group('la pantalla del código', () {
    late _Auth auth;

    Future<GoRouter> montar(
      WidgetTester tester, {
      String correo = 'ana@gmail.con',
      String? password = 'Clave-segura-123',
    }) async {
      auth = _Auth();
      final router = GoRouter(
        initialLocation: Routes.verifyEmail,
        initialExtra: CodigoPorVerificar(correo, password: password),
        routes: [
          GoRoute(
            path: Routes.verifyEmail,
            builder: (_, state) => switch (state.extra) {
              CodigoPorVerificar(:final email, :final password) =>
                VerifyEmailScreen(email: email, password: password),
              _ => const VerifyEmailScreen(),
            },
          ),
          GoRoute(
            path: Routes.login,
            builder: (_, _) => const Scaffold(body: Text('login')),
          ),
          GoRoute(
            path: Routes.register,
            builder: (_, _) => const Scaffold(body: Text('registro')),
          ),
        ],
      );
      await tester.binding.setSurfaceSize(const Size(412, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            analiticaProvider.overrideWithValue(_Analitica()),
            currentUserProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      return router;
    }

    Future<void> abrirHoja(WidgetTester tester) async {
      await tester.tap(find.text('¿Correo equivocado? Cámbialo'));
      await _esperar(tester);
    }

    Future<void> enviar(WidgetTester tester) async {
      await tester.tap(find.text('Enviar el código ahí'));
      await tester.pump();
      await _esperar(tester);
    }

    testWidgets('con la contraseña en memoria: un toque, misma cuenta', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'verificacion_pendiente': 'ana@gmail.con',
      });
      final router = await montar(tester);
      // El dominio malo se avisa bajo el correo.
      expect(find.text('Corregir'), findsOneWidget);

      await tester.tap(find.text('Corregir'));
      await _esperar(tester);
      // Sin pedir la contraseña otra vez, y con la corrección ya escrita.
      expect(find.text('Tu contraseña'), findsNothing);
      expect(find.widgetWithText(TextField, 'ana@gmail.com'), findsOneWidget);
      await enviar(tester);

      expect(auth.cambios, [
        ('ana@gmail.con', 'Clave-segura-123', 'ana@gmail.com'),
      ]);
      expect(router.state.matchedLocation, Routes.verifyEmail);
      expect(find.textContaining('ana@gmail.com'), findsWidgets);
      expect(find.text('Corregir'), findsNothing);
      // El login retoma el correo nuevo, no el malo.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('verificacion_pendiente'), 'ana@gmail.com');
      // Y el reenvío va al nuevo.
      await tester.pump(const Duration(seconds: 61));
      await tester.tap(find.text('Reenviar código'));
      await tester.pump();
      expect(auth.reenvios, ['ana@gmail.com']);
    });

    testWidgets('sin contraseña en memoria, la pide', (tester) async {
      await montar(tester, correo: 'ana@unsa.pe', password: null);
      expect(find.text('Corregir'), findsNothing);
      await abrirHoja(tester);

      expect(find.text('Tu contraseña'), findsOneWidget);
      final campos = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(TextField),
      );
      await tester.enterText(campos.at(0), 'ana@unsa.edu.pe');
      await tester.enterText(campos.at(1), 'otra-clave');
      await enviar(tester);

      expect(auth.cambios, [('ana@unsa.pe', 'otra-clave', 'ana@unsa.edu.pe')]);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('contraseña mala: la pide y lo dice', (tester) async {
      await montar(tester);
      auth.fallaCambio = const UnauthorizedFailure(
        'Correo o contraseña incorrectos.',
        'INVALID_CREDENTIALS',
      );
      await abrirHoja(tester);
      await enviar(tester);

      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(find.text('Tu contraseña'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('el correo nuevo ya tiene cuenta', (tester) async {
      await montar(tester);
      auth.fallaCambio = const ValidationFailure(
        'Ese correo ya está registrado.',
        code: 'EMAIL_TAKEN',
        fieldErrors: {'emailNuevo': 'Ese correo ya está registrado.'},
      );
      await abrirHoja(tester);
      await enviar(tester);

      expect(find.text('Ese correo ya está registrado.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('la cuenta ya estaba verificada: al login', (tester) async {
      SharedPreferences.setMockInitialValues({
        'verificacion_pendiente': 'ana@gmail.con',
      });
      final router = await montar(tester);
      auth.yaVerificada = true;
      await abrirHoja(tester);
      await enviar(tester);

      expect(router.state.matchedLocation, Routes.login);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('verificacion_pendiente'), isNull);
    });

    testWidgets('el mismo correo no se manda', (tester) async {
      await montar(tester, correo: 'ana@unsa.pe');
      await abrirHoja(tester);
      await enviar(tester);

      expect(find.text('Es el mismo correo de ahora.'), findsOneWidget);
      expect(auth.cambios, isEmpty);
      await tester.pump(const Duration(seconds: 61));
    });
  });
}

/// El sobre y la cuenta atrás no paran: `pumpAndSettle` no termina nunca.
Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _Auth extends MockAuthRepository {
  final registrados = <String>[];
  final cambios = <(String, String, String)>[];
  final reenvios = <String>[];
  Failure? fallaCambio;
  bool yaVerificada = false;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required bool aceptaTerminos,
    bool? aceptaComerciales,
  }) async => registrados.add(email);

  @override
  Future<String?> cambiarCorreo({
    required String email,
    required String password,
    required String emailNuevo,
  }) async {
    if (fallaCambio case final f?) throw f;
    if (yaVerificada) return null;
    cambios.add((email, password, emailNuevo));
    return emailNuevo;
  }

  @override
  Future<void> reenviarVerificacion(String email) async => reenvios.add(email);
}

class _Analitica implements Analitica {
  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
