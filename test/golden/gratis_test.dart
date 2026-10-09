@Tags(['golden'])
library;

import 'package:enam_app/core/domain/hora_peru.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/presentation/past_exams_screen.dart';
import 'package:enam_app/features/session/presentation/practice_config_screen.dart';
import 'package:enam_app/features/session/presentation/simulacro_hub_screen.dart';
import 'package:enam_app/features/stats/presentation/progress_screen.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/muro_de_venta_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../ayuda/offline.dart';
import '_comun.dart';

/// Banco de capturas del gratis limitado: el muro de venta y las pantallas con
/// funciones de pago, con su etiqueta «Premium» y su vista previa.
///
/// El inicio en gratis está en `inicio_test.dart` (estados `gratis` y
/// `gratisAgotado`).
///
/// ```sh
/// flutter test --update-goldens test/golden/gratis_test.dart
/// ```
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await cargarFuentes();
    congelarReloj(DateTime.utc(2026, 10, 5, 17));
  });

  tearDownAll(soltarReloj);

  const conCupo = AccesoGratis(preguntasPorDia: 10, restantesHoy: 6);
  const sinCupo = AccesoGratis(preguntasPorDia: 10, restantesHoy: 0);

  final pantallas = <({String nombre, Widget pantalla, AccesoGratis gratis})>[
    (
      nombre: '9.3-muro-cupo',
      pantalla: const MuroDeVentaScreen(motivo: CupoAgotado()),
      gratis: sinCupo,
    ),
    (
      nombre: '9.4-muro-funcion',
      pantalla: const MuroDeVentaScreen(
        motivo: FuncionDePago(FuncionPremium.simulacro),
      ),
      gratis: conCupo,
    ),
    (
      nombre: '4.1-configurar-gratis',
      pantalla: const PracticeConfigScreen(),
      gratis: conCupo,
    ),
    (
      nombre: '5.1-progreso-gratis',
      pantalla: const ProgressScreen(),
      gratis: conCupo,
    ),
    (
      nombre: '5.2-simulacros-gratis',
      pantalla: const SimulacroHubScreen(),
      gratis: conCupo,
    ),
    (
      nombre: '5.10-examenes-gratis',
      pantalla: const PastExamsScreen(),
      gratis: conCupo,
    ),
  ];

  for (final dispositivo in dispositivos) {
    group(dispositivo.nombre, () {
      for (final p in pantallas) {
        for (final oscuro in [false, true]) {
          final tema = oscuro ? 'oscuro' : 'claro';

          testWidgets('${p.nombre} · $tema', (tester) async {
            tester.view
              ..devicePixelRatio = 2
              ..physicalSize = dispositivo.tamano * 2;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              Marco(
                tamano: dispositivo.tamano,
                oscuro: oscuro,
                overrides: _enGratis(p.gratis),
                child: p.pantalla,
              ),
            );
            for (var i = 0; i < 4; i++) {
              await tester.pump(const Duration(milliseconds: 600));
            }

            await precargarImagenes(tester);

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '_imagenes/${dispositivo.nombre}/${p.nombre}-$tema.png',
              ),
            );

            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 5));
          });
        }
      }
    });
  }
}

List<Override> _enGratis(AccesoGratis gratis) {
  final repo = MockSessionRepository();
  return [
    authControllerProvider.overrideWith(_ConSesion.new),
    cupoGratisProvider.overrideWithValue(gratis),
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
        acceso: gratis,
      ),
    ),
    sessionRepositoryProvider.overrideWithValue(repo),
    sessionRepositoryRemotoProvider.overrideWithValue(repo),
    almacenOfflineProvider.overrideWithValue(AlmacenEnMemoria()),
  ];
}

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => AuthSignedIn(
    User(
      id: 'u1',
      email: 'valeria.rojas@unmsm.edu.pe',
      nombre: 'Valeria Rojas',
      emailVerificado: true,
      universidad: 'UNMSM',
      condicion: StudentCondition.repitiente,
      fechaObjetivo: DateTime(2026, 12, 12),
    ),
  );
}
