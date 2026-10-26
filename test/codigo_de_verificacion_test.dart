import 'package:enam_app/core/analitica/analitica.dart';
import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/auth/presentation/login_screen.dart';
import 'package:enam_app/features/auth/presentation/register_screen.dart';
import 'package:enam_app/features/auth/presentation/verify_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// El código de verificación del registro. Del 18 al 25/10, un 10-15 % de las
/// cuentas creadas nunca llegó a `signup_verified`. Dos causas en la app:
///
/// - Un código pegado con espacios («123 456») se cortaba en «123 45» antes de
///   limpiarlo, y el servidor lo rechazaba.
/// - Quien cerraba la app antes de escribirlo no podía volver: el registro no
///   deja sesión, y el login con la cuenta sin verificar (403
///   `EMAIL_NOT_VERIFIED`) solo enseñaba un aviso.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('lo que se pega o se escribe', () {
    String limpiar(String texto) => const SoloDigitosDelCodigo(6)
        .formatEditUpdate(TextEditingValue.empty, TextEditingValue(text: texto))
        .text;

    test('quita espacios, guiones y letras, y corta en seis', () {
      expect(limpiar('123 456'), '123456');
      expect(limpiar('123-456'), '123456');
      expect(limpiar('  123456  '), '123456');
      expect(limpiar('Tu código: 123456'), '123456');
      expect(limpiar('1234567'), '123456');
      expect(limpiar('12'), '12');
    });

    test('la pista del spam no habla de nada más', () {
      expect(pistaDeSpam, contains('spam'));
      expect(pistaDeSpam, contains('promociones'));
    });
  });

  group('la pantalla del código', () {
    late _Auth auth;
    late _Analitica analitica;

    Future<void> montar(
      WidgetTester tester, {
      bool recienEnviado = true,
    }) async {
      auth = _Auth();
      analitica = _Analitica();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            analiticaProvider.overrideWithValue(analitica),
            currentUserProvider.overrideWithValue(null),
          ],
          child: MaterialApp.router(
            routerConfig: _router(
              Routes.verifyEmail,
              CodigoPorVerificar('ana@unsa.pe', recienEnviado: recienEnviado),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('pegado con espacios, se limpia y se verifica solo', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'verificacion_pendiente': 'ana@unsa.pe',
      });
      await montar(tester);

      await tester.enterText(find.byType(TextField), '123 456');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(auth.codigos, ['123456']);
      // Verificada: ya no queda nada que retomar desde el login.
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('verificacion_pendiente'), isNull);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('con la pista del spam a la vista', (tester) async {
      await montar(tester);

      expect(find.text(pistaDeSpam), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('un código malo lo dice, limpia el campo y se mide', (
      tester,
    ) async {
      await montar(tester);
      auth.falla = const ValidationFailure(
        'Ese código ya venció o no es válido. Pide uno nuevo.',
        code: 'VALIDATION_ERROR',
      );

      await tester.enterText(find.byType(TextField), '000000');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(
        find.text('Ese código ya venció o no es válido. Pide uno nuevo.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      expect(analitica.registrados, [
        'registro_fallido metodo=correo motivo=codigo_invalido',
      ]);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('recién enviado, el reenvío espera un minuto', (tester) async {
      await montar(tester);

      expect(find.text('Reenviar en 1:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('Reenviar código'), findsOneWidget);
    });

    testWidgets('al volver desde el login, se puede reenviar ya', (
      tester,
    ) async {
      await montar(tester, recienEnviado: false);

      await tester.tap(find.text('Reenviar código'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(auth.reenvios, ['ana@unsa.pe']);
      expect(find.text('Reenviar en 1:00'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('demasiado pronto: espera lo que diga el servidor', (
      tester,
    ) async {
      await montar(tester, recienEnviado: false);
      auth.fallaReenvio = const RateLimitFailure(
        'Espera un momento antes de pedir otro código.',
        Duration(seconds: 25),
      );

      await tester.tap(find.text('Reenviar código'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      expect(find.text('Reenviar en 0:25'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
    });
  });

  group('volver a escribir el código después de cerrar la app', () {
    late _Auth auth;

    Future<GoRouter> montarLogin(
      WidgetTester tester, {
      String inicio = Routes.login,
    }) async {
      auth = _Auth();
      final router = _router(inicio);
      tester.view
        ..physicalSize = const Size(400, 1400) * 3
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            analiticaProvider.overrideWithValue(_Analitica()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await _esperar(tester);
      return router;
    }

    testWidgets('entrar con la cuenta sin verificar lleva al código', (
      tester,
    ) async {
      final router = await montarLogin(tester);
      auth.fallaLogin = const ForbiddenFailure(
        'Verifica tu correo antes de entrar. Te enviamos un código.',
        'EMAIL_NOT_VERIFIED',
      );

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'ana@unsa.pe');
      await tester.enterText(campos.at(1), 'UnaClaveLarga123');
      await tester.tap(find.text('Ingresar'));
      await _esperar(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.verifyEmail,
      );
      expect(
        find.textContaining('ana@unsa.pe', findRichText: true),
        findsOneWidget,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('verificacion_pendiente'), 'ana@unsa.pe');
      await tester.pump(const Duration(seconds: 61));
    });

    testWidgets('con un registro a medias, el login ofrece el código', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'verificacion_pendiente': 'ana@unsa.pe',
      });
      final router = await montarLogin(tester);

      expect(find.text('Te falta verificar ana@unsa.pe.'), findsOneWidget);
      await tester.tap(find.text('Ingresar código'));
      await _esperar(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.verifyEmail,
      );
      // El código pudo vencer mientras tanto: el reenvío está a mano.
      expect(find.text('Reenviar código'), findsOneWidget);
    });

    testWidgets('registrarse con un correo que ya existe ofrece el código', (
      tester,
    ) async {
      // Si el correo del código no salía, el alta se cortaba con la cuenta ya
      // creada, y el reintento decía «Ese correo ya está registrado».
      final router = await montarLogin(tester, inicio: Routes.register);
      auth.fallaRegistro = const ValidationFailure(
        'Ese correo ya está registrado.',
        code: 'EMAIL_TAKEN',
        fieldErrors: {'email': 'Ese correo ya está registrado.'},
      );

      final campos = find.byType(TextField);
      await tester.enterText(campos.at(0), 'Ana');
      await tester.enterText(campos.at(1), 'ana@unsa.pe');
      await tester.enterText(campos.at(2), 'UnaClaveLarga123');
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump();
      await tester.tap(find.text('Crear cuenta'));
      await _esperar(tester);

      await tester.tap(
        find.text('¿No verificaste tu correo? Ingresa el código'),
      );
      await _esperar(tester);

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.verifyEmail,
      );
      expect(find.text('Reenviar código'), findsOneWidget);
    });

    testWidgets('sin nada pendiente, el login no dice nada', (tester) async {
      await montarLogin(tester);

      expect(find.textContaining('Te falta verificar'), findsNothing);
    });
  });
}

/// Login y código, con la misma regla de `extra` que el router de la app.
GoRouter _router(String inicio, [Object? extra]) => GoRouter(
  initialLocation: inicio,
  initialExtra: extra,
  routes: [
    GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
    GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
    GoRoute(
      path: Routes.verifyEmail,
      builder: (_, state) => switch (state.extra) {
        CodigoPorVerificar(:final email, :final recienEnviado) =>
          VerifyEmailScreen(email: email, codigoRecienEnviado: recienEnviado),
        _ => const VerifyEmailScreen(),
      },
    ),
  ],
);

/// El login tiene una animación en bucle: `pumpAndSettle` no termina nunca.
Future<void> _esperar(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

class _Auth extends MockAuthRepository {
  final codigos = <String>[];
  final reenvios = <String>[];
  Failure? falla;
  Failure? fallaReenvio;
  Failure? fallaLogin;
  Failure? fallaRegistro;

  @override
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required bool aceptaTerminos,
    bool? aceptaComerciales,
  }) async {
    if (fallaRegistro case final f?) throw f;
  }

  @override
  Future<User?> verificarConCodigo({
    required String email,
    required String codigo,
  }) async {
    codigos.add(codigo);
    if (falla case final f?) throw f;
    return null;
  }

  @override
  Future<void> reenviarVerificacion(String email) async {
    if (fallaReenvio case final f?) throw f;
    reenvios.add(email);
  }

  @override
  Future<User> login({required String email, required String password}) async {
    if (fallaLogin case final f?) throw f;
    return super.login(email: email, password: password);
  }
}

class _Analitica implements Analitica {
  final registrados = <String>[];

  @override
  void registrar(Evento evento, {Map<String, String> propiedades = const {}}) =>
      registrados.add(
        [
          evento.nombre,
          for (final p in propiedades.entries) '${p.key}=${p.value}',
        ].join(' '),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
