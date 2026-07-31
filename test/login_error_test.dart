import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/app_router.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/auth/data/mock_auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RF-02 — escribir mal la contraseña tiene que enseñar el error, no devolver
/// al usuario a un login en blanco como si no hubiera pasado nada.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    SharedPreferences.setMockInitialValues({'onboarding_visto': true});
  });

  testWidgets('con credenciales malas se queda en el login', (tester) async {
    late GoRouter router;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            router = ref.watch(routerProvider);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 800));
    expect(router.state.matchedLocation, Routes.login);

    // La contraseña "error" hace fallar el login en el mock.
    await tester.enterText(
      find.byType(TextField).first,
      'test@enam.pe',
    );
    await tester.enterText(find.byType(TextField).at(1), 'error');
    await tester.pump();

    await tester.tap(find.text('Ingresar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      router.state.matchedLocation,
      Routes.login,
      reason: 'un login fallido no puede sacar al usuario de la pantalla',
    );
    expect(
      find.text('Correo o contraseña incorrectos.'),
      findsOneWidget,
      reason: 'el error tiene que verse bajo el campo',
    );
  });
}
