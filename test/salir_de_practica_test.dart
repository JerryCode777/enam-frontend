import 'dart:async';

import 'package:enam_app/core/providers.dart';
import 'package:enam_app/core/router/app_router.dart';
import 'package:enam_app/core/router/routes.dart';
import 'package:enam_app/features/auth/data/auth_repository.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RF-15 — salir de una práctica tiene que devolverte a donde estabas.
///
/// El caso que se rompe solo: la sesión se abre con `pushReplacement` desde el
/// configurador, así que la pila deja de tener la pantalla de configuración. Si
/// además se entró al configurador con `go` en vez de `push`, no queda nada que
/// desapilar y el botón de salir no hace nada.
class _AuthListo implements AuthRepository {
  final _user = User(
    id: 'u1',
    email: 'test@enam.pe',
    nombre: 'Valeria Rojas',
    emailVerificado: true,
    universidad: 'UNSA',
    condicion: StudentCondition.interno,
    fechaObjetivo: DateTime.now().add(const Duration(days: 100)),
  );

  @override
  Future<User?> currentUser() async => _user;

  @override
  Future<User> login({required String email, required String password}) async =>
      _user;

  @override
  Future<User> loginConGoogle(String idToken, {bool aceptaTerminos = false}) async =>
      _user;

  @override
  Future<User> loginConApple({
    required String identityToken,
    String? nombre,
    bool aceptaTerminos = false,
  }) async => _user;

  @override
  Future<void> logout() async {}

  @override
  Future<void> register({
    required String email,
    required String password,
    required String nombre,
    required bool aceptaTerminos,
  }) async {}

  @override
  Future<void> forgotPassword(String email) async {}

  @override
  Future<void> reenviarVerificacion(String email) async {}

  @override
  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {}

  @override
  Future<User> updateProfile({
    String? nombre,
    String? universidad,
    StudentCondition? condicion,
    DateTime? fechaObjetivo,
    bool? ocultoEnRanking,
  }) async => _user;
}

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  setUp(() {
    // El onboarding ya visto, para que el splash resuelva directo al login/home.
    SharedPreferences.setMockInitialValues({'onboarding_visto': true});
  });

  testWidgets('salir de una práctica vuelve a la pantalla anterior', (
    tester,
  ) async {
    late GoRouterHolder holder;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_AuthListo()),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final router = ref.watch(routerProvider);
            holder = GoRouterHolder(router);
            return MaterialApp.router(routerConfig: router);
          },
        ),
      ),
    );

    // Deja pasar el mínimo del splash y la carga de la sesión. Se usa `pump`
    // y no `pumpAndSettle`: el Home tiene animaciones en bucle (la llama de la
    // racha) y `pumpAndSettle` nunca terminaría.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 800));

    expect(holder.router.state.matchedLocation, Routes.home);

    // Home → configurar práctica, tal como lo hace la tarjeta "Practicar".
    unawaited(holder.router.push(Routes.practiceConfig));
    await tester.pump(const Duration(milliseconds: 600));
    expect(holder.router.state.matchedLocation, Routes.practiceConfig);

    // El configurador entra a la sesión con pushReplacement.
    unawaited(holder.router.pushReplacement(Routes.practiceSessionOf('s1')));
    await tester.pump(const Duration(milliseconds: 600));
    expect(
      holder.router.state.matchedLocation,
      Routes.practiceSessionOf('s1'),
    );

    // Salir debe devolver al inicio, no quedarse en la sesión.
    holder.router.pop();
    await tester.pump(const Duration(milliseconds: 600));

    expect(
      holder.router.state.matchedLocation,
      isNot(Routes.practiceSessionOf('s1')),
      reason: 'tras salir de la práctica no se puede seguir en la sesión',
    );
  });

  test('la sesión pendiente del Home se puede abrir', () async {
    // RF-15: el Home ofrece retomar una sesión; si ese id no existe en el
    // repositorio, "Seguir" muere en "no pudimos cargar la sesión".
    final repo = MockSessionRepository();
    final sesion = await repo.session(MockSessionRepository.idSesionPendiente);

    expect(sesion.estado, SessionStatus.enCurso);
    expect(sesion.preguntas, hasLength(20));
    expect(
      sesion.respondidas,
      6,
      reason: 'el detalle del Home dice "pregunta 7 de 20"',
    );
  });
}

/// Guarda el router para poder navegar desde el test.
class GoRouterHolder {
  GoRouterHolder(this.router);
  final GoRouter router;
}
