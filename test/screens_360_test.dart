import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/auth/presentation/complete_profile_screen.dart';
import 'package:enam_app/features/auth/presentation/forgot_password_screen.dart';
import 'package:enam_app/features/auth/presentation/login_screen.dart';
import 'package:enam_app/features/auth/presentation/onboarding_screen.dart';
import 'package:enam_app/features/auth/presentation/register_screen.dart';
import 'package:enam_app/features/auth/presentation/reset_password_screen.dart';
import 'package:enam_app/features/auth/presentation/splash_screen.dart';
import 'package:enam_app/features/auth/presentation/verify_email_screen.dart';
import 'package:enam_app/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Verifica que ninguna pantalla desborde a **360 px de ancho** (RNF-09) ni en
/// tema claro ni en oscuro, y que aguante la fuente del sistema ampliada.
///
/// El diseño se entregó dibujado a 390 px y sin comprobar 360. Esto lo comprueba
/// de forma automática, así que deja de depender de que alguien se acuerde.
void main() {
  // Igual que en `main()`: sin esto, DateFormat con locale 'es' revienta.
  setUpAll(() => initializeDateFormatting('es'));

  /// El teléfono más angosto que soportamos, y uno bajo para forzar desborde
  /// vertical si una pantalla no es desplazable.
  const anchoMinimo = 360.0;
  const altoBajo = 640.0;

  final pantallas = <String, Widget>{
    'Splash': const SplashScreen(),
    'Onboarding': const OnboardingScreen(),
    'Login': const LoginScreen(),
    'Registro': const RegisterScreen(),
    'Verificar correo': const VerifyEmailScreen(email: 'valeria@unmsm.edu.pe'),
    'Recuperar contraseña': const ForgotPasswordScreen(),
    'Nueva contraseña': const ResetPasswordScreen(token: 'tok'),
    'Perfil inicial': const CompleteProfileScreen(),
    'Inicio': const HomeScreen(),
  };

  for (final entry in pantallas.entries) {
    for (final brightness in Brightness.values) {
      final tema = brightness == Brightness.light ? 'claro' : 'oscuro';

      testWidgets('${entry.key} entra en 360 px · tema $tema', (tester) async {
        tester.view
          ..physicalSize = const Size(anchoMinimo * 3, altoBajo * 3)
          ..devicePixelRatio = 3.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(_harness(entry.value, brightness));
        await tester.pump(const Duration(seconds: 1));

        expect(
          tester.takeException(),
          isNull,
          reason: '"${entry.key}" desborda o falla a $anchoMinimo px en $tema',
        );
      });
    }
  }

  testWidgets('las pantallas de formulario aguantan la fuente al 140 %', (
    tester,
  ) async {
    // 1.4 es el tope que fija la app en `EnamApp.builder`.
    tester.view
      ..physicalSize = const Size(anchoMinimo * 3, altoBajo * 3)
      ..devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    for (final pantalla in [
      const RegisterScreen(),
      const CompleteProfileScreen(),
      const ResetPasswordScreen(token: 'tok'),
    ]) {
      await tester.pumpWidget(
        _harness(pantalla, Brightness.light, textScale: 1.4),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    }
  });
}

/// Envuelve la pantalla con lo mínimo para pintarla, con mocks y sesión activa.
Widget _harness(Widget screen, Brightness brightness, {double textScale = 1.0}) {
  return ProviderScope(
    overrides: [
      // Un usuario con perfil completo, para que el Home tenga qué mostrar.
      authControllerProvider.overrideWith(_FakeAuthController.new),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light : AppTheme.dark,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: screen,
      ),
    ),
  );
}

class _FakeAuthController extends AuthController {
  @override
  Future<AuthState> build() async => AuthSignedIn(
    User(
      id: 'u1',
      email: 'valeria.rojas@unmsm.edu.pe',
      nombre: 'Valeria Rojas',
      emailVerificado: true,
      universidad: 'UNMSM',
      condicion: StudentCondition.repitiente,
      // Fecha fija para que el test no dependa del día en que corre.
      fechaObjetivo: DateTime(2026, 12, 12),
    ),
  );
}
