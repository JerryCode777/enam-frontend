import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/theme/app_theme.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/duelo/domain/duelo_models.dart';
import 'package:enam_app/features/profile/presentation/help_screen.dart';
import 'package:enam_app/features/subscription/data/subscription_repository.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/access_ended_screen.dart';
import 'package:enam_app/features/subscription/presentation/my_subscription_screen.dart';
import 'package:enam_app/features/subscription/presentation/widgets/opciones_de_pago.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// En Android la app no tiene ningún camino de compra.
///
/// Google Play no deja llevar a pagar fuera de Play Billing, y la app no tiene
/// Play Billing. Había un botón que abría la web para pagar, un enlace por
/// correo, un «Activar por WhatsApp» y una pregunta de la ayuda sobre Yape.
/// Estas pruebas recorren las pantallas donde estaban, en los dos estados que
/// importan —sin acceso y Premium por la web— y fallan si vuelve cualquier
/// texto que lleve a comprar.
///
/// Los tests corren en el host, que no es iOS: `enTiendaApple` es falso y sale
/// la variante de Android.
void main() {
  setUpAll(() => initializeDateFormatting('es'));

  /// Lo que no puede aparecer en Android.
  const prohibidos = [
    'navegador',
    'enlace por correo',
    'buzón',
    'Activar por WhatsApp',
    'Ver los planes',
    'activa tu plan',
    'Renuévalo',
    'S/',
    'enamprep.com',
    'Yape',
    'Mercado Pago',
    'precio',
  ];

  void sinCaminoDeCompra(WidgetTester tester) {
    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .toList();
    for (final p in prohibidos) {
      expect(
        textos.where((t) => t.toLowerCase().contains(p.toLowerCase())),
        isEmpty,
        reason: '«$p» lleva a pagar fuera de Google Play',
      );
    }
  }

  test('los tests corren con la variante de Android', () {
    expect(enTiendaApple, isFalse);
  });

  for (final (nombre, sub) in [
    ('sin acceso', _expirada),
    ('Premium por la web', _premiumPorLaWeb),
  ]) {
    group(nombre, () {
      testWidgets('Acceso terminado no ofrece comprar', (tester) async {
        await tester.pumpWidget(_montar(const AccessEndedScreen(), sub));
        // La oferta aparece tras la explicación.
        await tester.pump(const Duration(seconds: 3));
        await tester.pumpAndSettle();

        sinCaminoDeCompra(tester);
        expect(
          find.text('Tu acceso Premium se activa con tu cuenta de ENAM Prep.'),
          findsOneWidget,
        );
      });

      testWidgets('Mi suscripción no ofrece comprar', (tester) async {
        await tester.pumpWidget(_montar(const MySubscriptionScreen(), sub));
        await tester.pumpAndSettle();

        sinCaminoDeCompra(tester);
        expect(
          find.text('Tu acceso Premium se activa con tu cuenta de ENAM Prep.'),
          findsOneWidget,
        );
      });
    });
  }

  testWidgets('quien es Premium por la web puede cancelar la renovación', (
    tester,
  ) async {
    // Gestionar lo que ya se pagó no es comprar: eso se queda.
    await tester.pumpWidget(
      _montar(const MySubscriptionScreen(), _premiumPorLaWeb),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACTIVO'), findsOneWidget);
    expect(find.text('Cancelar renovación'), findsOneWidget);
  });

  testWidgets('la ayuda no habla de pagar fuera de la tienda', (tester) async {
    await tester.pumpWidget(_montar(const HelpScreen(), _expirada));
    await tester.pumpAndSettle();

    sinCaminoDeCompra(tester);
    // Las demás preguntas siguen.
    expect(find.text('¿Qué incluye la cuenta gratis?'), findsOneWidget);
  });

  testWidgets('el botón de WhatsApp es de ayuda, no de activar', (
    tester,
  ) async {
    await tester.pumpWidget(
      _montar(const Scaffold(body: OpcionesDePago()), _expirada),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escríbenos si necesitas ayuda'), findsOneWidget);
    sinCaminoDeCompra(tester);
  });
}

final _expirada = Subscription(
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
);

final _premiumPorLaWeb = Subscription(
  id: 's2',
  plan: const Plan(
    id: 'mensual',
    nombre: 'Premium mensual',
    precioCentimos: 5900,
    duracionDias: 30,
  ),
  estado: SubscriptionStatus.activa,
  origen: SubscriptionOrigin.culqi,
  inicia: DateTime(2026, 10, 1),
  expira: DateTime(2026, 10, 31),
);

Widget _montar(Widget pantalla, Subscription sub) => ProviderScope(
  overrides: [
    authControllerProvider.overrideWith(_ConSesion.new),
    subscriptionProvider.overrideWith((ref) async => sub),
    subscriptionRepositoryProvider.overrideWithValue(_Repo(sub)),
    // Sin pase de duelo: el botón del duelo gratis no se pinta.
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

class _Repo implements SubscriptionRepository {
  _Repo(this.sub);

  final Subscription sub;

  @override
  Future<Subscription> current() async => sub;

  @override
  Future<void> enviarEnlaceDeSuscripcion(String email) =>
      throw StateError('En Android no se manda el enlace de pago');

  @override
  Future<String> enlaceDeSuscripcion() =>
      throw StateError('En Android no se abre la web para pagar');

  @override
  Future<void> cancelar() async {}

  @override
  Future<Subscription> canjearCompraApple(String jws) async => sub;
}
