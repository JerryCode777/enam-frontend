import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/my_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// «Mi suscripción» no promete lo que no puede hacer.
///
/// Una suscripción de App Store la renueva y la cancela Apple. El botón
/// «Cancelar renovación» llamaba a nuestro servidor, que no detiene ese cobro:
/// quien lo pulsaba creía haber cancelado y Apple seguía cobrando.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Subscription activa(SubscriptionOrigin origen) => Subscription(
    id: 's1',
    plan: const Plan(
      id: 'mensual',
      nombre: 'Premium mensual',
      precioCentimos: 5900,
      duracionDias: 30,
    ),
    estado: SubscriptionStatus.activa,
    origen: origen,
    inicia: DateTime(2026, 7, 1),
    expira: DateTime(2026, 7, 31),
  );

  Future<void> montar(WidgetTester tester, Subscription sub) async {
    tester.view
      ..physicalSize = const Size(393, 1400) * 3
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_ConSesion.new),
          subscriptionProvider.overrideWith((_) async => sub),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MySubscriptionScreen(),
        ),
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('App Store: renovación automática y cancelación en Apple', (
    tester,
  ) async {
    await montar(tester, activa(SubscriptionOrigin.apple));

    expect(find.text('Automática, por App Store'), findsOneWidget);
    expect(find.text('Manual'), findsNothing);
    expect(find.text('Cancelar renovación'), findsNothing);
    expect(find.text('Abrir mis suscripciones de Apple'), findsOneWidget);
  });

  testWidgets('pago por Yape o manual: renovación manual y cancelable aquí', (
    tester,
  ) async {
    await montar(tester, activa(SubscriptionOrigin.manual));

    expect(find.text('Manual'), findsOneWidget);
    expect(find.text('Cancelar renovación'), findsOneWidget);
    expect(find.text('Abrir mis suscripciones de Apple'), findsNothing);
  });
}

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => const AuthSignedIn(
    User(id: 'u1', email: 'a@b.pe', nombre: 'Ana', emailVerificado: true),
  );
}
