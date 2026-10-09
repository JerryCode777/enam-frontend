import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/auth/presentation/onboarding_screen.dart';
import 'package:enam_app/features/duelo/domain/duelo_models.dart';
import 'package:enam_app/features/profile/presentation/help_screen.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/access_ended_screen.dart';
import 'package:enam_app/features/subscription/presentation/my_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Sin día de prueba ni oferta (decisión de Jerry, 09/10/2026).
///
/// Las cuentas nuevas entran directo a gratis. El servidor les guarda una
/// suscripción del plan de prueba ya vencida desde el alta (billing.DarAlta),
/// y la app no puede leer eso como «se acabó tu día de prueba»: esa cuenta
/// nunca tuvo uno. Tampoco hay descuento: los precios salen de StoreKit.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    PackageInfo.setMockInitialValues(
      appName: 'ENAM Prep',
      packageName: 'pe.jakstech.enam_app',
      version: '1.1.0',
      buildNumber: '8',
      buildSignature: '',
    );
  });

  const prohibidos = [
    'prueba',
    '24 horas',
    'oferta',
    'descuento',
    '%',
  ];

  void sinPruebaNiOferta(WidgetTester tester) {
    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => (t.data ?? t.textSpan?.toPlainText() ?? '').toLowerCase())
        .toList();
    for (final p in prohibidos) {
      expect(
        textos.where((t) => t.contains(p)),
        isEmpty,
        reason: '«$p» en pantalla',
      );
    }
  }

  testWidgets('Mi suscripción de una cuenta nueva: cuenta gratis, sin prueba', (
    tester,
  ) async {
    await tester.pumpWidget(_montar(const MySubscriptionScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Cuenta gratis'), findsOneWidget);
    expect(find.text('10, con su explicación'), findsOneWidget);
    expect(find.text('EXPIRADO'), findsNothing);
    sinPruebaNiOferta(tester);
  });

  testWidgets('Acceso terminado no habla de una prueba', (tester) async {
    await tester.pumpWidget(_montar(const AccessEndedScreen()));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Tu acceso terminó'), findsOneWidget);
    sinPruebaNiOferta(tester);
  });

  testWidgets('la presentación no promete una prueba', (tester) async {
    await tester.pumpWidget(_montar(const OnboardingScreen()));
    await tester.pumpAndSettle();
    // Hasta el último paso, que es donde estaba.
    for (var i = 0; i < 3; i++) {
      final siguiente = find.text('Siguiente');
      if (siguiente.evaluate().isEmpty) break;
      await tester.tap(siguiente);
      await tester.pumpAndSettle();
    }

    expect(find.text('Crear cuenta gratis'), findsOneWidget);
    sinPruebaNiOferta(tester);
  });

  testWidgets('la ayuda no habla de la prueba', (tester) async {
    await tester.pumpWidget(_montar(const HelpScreen()));
    await tester.pumpAndSettle();

    expect(find.text('¿Qué incluye la cuenta gratis?'), findsOneWidget);
    sinPruebaNiOferta(tester);
  });
}

/// Una cuenta nueva como la crea el backend sin prueba: el plan de prueba,
/// vencido desde el alta, y el nivel gratis.
final _cuentaNueva = Subscription(
  id: 's1',
  plan: const Plan(
    id: 'trial',
    nombre: 'Prueba de 1 día',
    precioCentimos: 0,
    duracionDias: 1,
    esGratuito: true,
  ),
  estado: SubscriptionStatus.expirada,
  origen: SubscriptionOrigin.sistema,
  inicia: DateTime(2026, 10, 9),
  expira: DateTime(2026, 10, 9),
  acceso: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 10),
);

Widget _montar(Widget pantalla) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_ConSesion.new),
    subscriptionProvider.overrideWith((ref) async => _cuentaNueva),
    paseDeDueloProvider.overrideWith((ref) async => const PaseDeDuelo()),
  ],
  child: MaterialApp(theme: AppTheme.light, home: pantalla),
);

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    User(
      id: 'u1',
      email: 'valeria.rojas@unmsm.edu.pe',
      nombre: 'Valeria Rojas',
      emailVerificado: true,
    ),
  );
}
