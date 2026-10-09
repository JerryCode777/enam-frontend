import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/duelo/domain/duelo_models.dart';
import 'package:enam_app/features/profile/presentation/help_screen.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/access_ended_screen.dart';
import 'package:enam_app/features/subscription/presentation/my_subscription_screen.dart';
import 'package:enam_app/features/subscription/presentation/widgets/opciones_de_pago.dart';
import 'package:enam_app/features/subscription/presentation/widgets/planes_de_apple.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// En iPhone se compra solo con App Store (guía 3.1.1).
///
/// Había una nota con la dirección del sitio que abría `/activar` en la web, un
/// «Activar por WhatsApp» con «quiero activar mi cuenta» y una pregunta de la
/// ayuda sobre Yape: las tres eran ofrecer un medio de pago que no es App
/// Store. Estas pruebas recorren esas pantallas como un iPhone y fallan si
/// vuelve cualquier texto que lleve a pagar fuera de la App Store. Los precios
/// de StoreKit sí pueden salir: son de Apple.
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    PackageInfo.setMockInitialValues(
      appName: 'ENAM Prep',
      packageName: 'pe.jakstech.enamApp',
      version: '1.0.0',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  /// Las pruebas de pantalla corren como un iPhone.
  final iPhone = TargetPlatformVariant.only(TargetPlatform.iOS);

  /// Lo que no puede aparecer en iPhone.
  const prohibidos = [
    'navegador',
    'enamprep.com',
    'Gestiona tu cuenta',
    'Activar por WhatsApp',
    'activar mi cuenta',
    'Yape',
    'Mercado Pago',
    'en la web',
  ];

  void soloAppStore(WidgetTester tester) {
    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .toList();
    for (final p in prohibidos) {
      expect(
        textos.where((t) => t.toLowerCase().contains(p.toLowerCase())),
        isEmpty,
        reason: '«$p» lleva a pagar fuera de la App Store',
      );
    }
  }

  test('en un iPhone toca la variante de App Store', () {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(enTiendaApple, isTrue);
  });

  for (final (nombre, pantalla) in [
    ('Acceso terminado', const AccessEndedScreen()),
    ('Mi suscripción', const MySubscriptionScreen()),
  ]) {
    testWidgets('$nombre: la compra con App Store y la ayuda, nada más', (
      tester,
    ) async {
      await tester.pumpWidget(_montar(pantalla));
      // La oferta aparece tras la explicación.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(find.byType(PlanesDeApple), findsOneWidget);
      expect(find.text('Escríbenos si necesitas ayuda'), findsOneWidget);
      soloAppStore(tester);
    }, variant: iPhone);
  }

  testWidgets('la ayuda no habla de pagar fuera de la App Store', (
    tester,
  ) async {
    await tester.pumpWidget(_montar(const HelpScreen()));
    await tester.pumpAndSettle();

    soloAppStore(tester);
    expect(find.text('¿Qué incluye la cuenta gratis?'), findsOneWidget);
  }, variant: iPhone);
}

Widget _montar(Widget pantalla) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_ConSesion.new),
    subscriptionProvider.overrideWith(
      (ref) async => Subscription(
        id: 's1',
        plan: const Plan(
          id: 'prueba',
          nombre: 'Prueba de 1 día',
          precioCentimos: 0,
          duracionDias: 1,
          esGratuito: true,
        ),
        estado: SubscriptionStatus.expirada,
        origen: SubscriptionOrigin.sistema,
        inicia: DateTime(2026, 10, 1),
        expira: DateTime(2026, 10, 2),
      ),
    ),
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
