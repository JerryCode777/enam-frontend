import 'package:enam_app/core/error/failure.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/subscription/data/subscription_repository.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/widgets/opciones_de_pago.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Cómo sale el usuario de la app hacia la web, en Android.
///
/// La app ya tiene sesión, así que pide un enlace de un solo uso y abre el
/// navegador **identificado**. Antes esto pasaba por el correo, y la bandeja de
/// entrada era un paso donde se perdía gente: el correo en otro teléfono, en
/// spam, o simplemente no encontrado.
///
/// Lo que estas pruebas fijan es que el respaldo siga existiendo. Un solo camino
/// a la web es un camino que, cuando falla, deja al usuario sin forma de pagar.
class _RepoDePrueba implements SubscriptionRepository {
  _RepoDePrueba({this.falla = false});

  final bool falla;
  int enlacesDirectos = 0;
  int correosEnviados = 0;

  @override
  Future<String> enlaceDeSuscripcion() async {
    enlacesDirectos++;
    if (falla) throw const NetworkFailure();
    return 'https://enamprep.com/activar?token=abc&origen=android';
  }

  @override
  Future<void> enviarEnlaceDeSuscripcion(String email) async {
    correosEnviados++;
  }

  @override
  Future<Subscription> current() async => throw UnimplementedError();

  @override
  Future<void> cancelar() async {}

  @override
  Future<Subscription> canjearCompraApple(String jws) async =>
      throw UnimplementedError();
}

void main() {
  late _RepoDePrueba repo;

  Widget montar(_RepoDePrueba conEste) => ProviderScope(
    overrides: [
      subscriptionRepositoryProvider.overrideWithValue(conEste),
      // El correo de respaldo se manda al de la cuenta, así que hace falta que
      // haya cuenta: es la situación real —esta pantalla solo se ve con sesión
      // iniciada—.
      currentUserProvider.overrideWithValue(
        const User(
          id: 'u1',
          email: 'valeria@unmsm.edu.pe',
          nombre: 'Valeria',
          emailVerificado: true,
        ),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: OpcionesDePago()),
    ),
  );

  testWidgets('en Android se ofrece abrir el navegador, no el correo', (
    tester,
  ) async {
    repo = _RepoDePrueba();
    await tester.pumpWidget(montar(repo));
    await tester.pump();

    expect(find.text('Continuar en el navegador'), findsOneWidget);
    // El correo sigue estando, pero como segunda opción y no como la principal.
    expect(find.text('Mejor mándame el enlace por correo'), findsOneWidget);
  });

  testWidgets('pide el enlace con la sesión que la app ya tiene', (
    tester,
  ) async {
    repo = _RepoDePrueba();
    await tester.pumpWidget(montar(repo));
    await tester.pump();

    await tester.tap(find.text('Continuar en el navegador'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      repo.enlacesDirectos,
      1,
      reason: 'el enlace se pide al servidor, no se arma en el cliente',
    );
    expect(
      repo.correosEnviados,
      0,
      reason: 'con el navegador abierto no hay por qué mandar correo',
    );
  });

  testWidgets('si el enlace falla, se cae al correo en vez de dejar un error', (
    tester,
  ) async {
    repo = _RepoDePrueba(falla: true);
    await tester.pumpWidget(montar(repo));
    await tester.pump();

    await tester.tap(find.text('Continuar en el navegador'));
    await tester.pump(const Duration(milliseconds: 300));

    // Sin red, sin servidor o sin navegador: lo que importa es que llegue a la
    // web, y para eso hay dos caminos.
    expect(repo.correosEnviados, 1);
  });

  testWidgets('el correo sigue disponible a mano', (tester) async {
    repo = _RepoDePrueba();
    await tester.pumpWidget(montar(repo));
    await tester.pump();

    await tester.tap(find.text('Mejor mándame el enlace por correo'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.correosEnviados, 1);
    expect(repo.enlacesDirectos, 0);
  });
}
