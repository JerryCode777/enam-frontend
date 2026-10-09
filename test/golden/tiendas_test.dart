@Tags(['golden'])
library;

import 'dart:async';
import 'dart:io';

import 'package:enam_app/core/domain/hora_peru.dart';
import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/aula/data/mock_aula_repository.dart';
import 'package:enam_app/features/aula/presentation/aula_providers.dart';
import 'package:enam_app/features/aula/presentation/cursos_screen.dart';
import 'package:enam_app/features/aula/presentation/widgets/presentacion.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/home/presentation/home_screen.dart';
import 'package:enam_app/features/subscription/domain/acceso.dart';
import 'package:enam_app/features/subscription/domain/subscription_models.dart';
import 'package:enam_app/features/subscription/presentation/muro_de_venta_screen.dart';
import 'package:enam_app/features/subscription/presentation/my_subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../ayuda/inicio.dart';
import '_comun.dart';

/// La 1.1.0 en cada tienda, con una cuenta gratis: el inicio, el aula, el muro
/// de cursos y «Mi suscripción».
///
/// Lo que cambia entre tiendas es el cobro: en iPhone, App Store; en Android,
/// ninguna compra en la app. Por eso cada pantalla se retrata con la plataforma
/// de cada una.
///
/// ```sh
/// flutter test --update-goldens test/golden/tiendas_test.dart
/// ```
void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
    await cargarFuentes();
    congelarReloj(DateTime.utc(2026, 10, 9, 17));
  });

  tearDownAll(soltarReloj);

  final tiendas = [
    (
      nombre: 'android',
      plataforma: TargetPlatform.android,
      tamano: const Size(412, 915),
    ),
    (
      nombre: 'ios',
      plataforma: TargetPlatform.iOS,
      tamano: const Size(393, 852),
    ),
  ];

  final pantallas =
      <({String nombre, Widget pantalla, List<Override> overrides})>[
        (
          nombre: '1-inicio',
          pantalla: const HomeScreen(),
          overrides: [
            // El ENAM ordinario es el 22/11/2026.
            ...overridesDeInicio(
              EstadoInicio.gratis,
              fechaObjetivo: DateTime(2026, 11, 22),
            ),
            aulaRepositoryProvider.overrideWithValue(
              MockAulaRepository(delay: Duration.zero),
            ),
          ],
        ),
        (
          nombre: '2-cursos',
          pantalla: const CursosScreen(),
          overrides: [
            ..._enGratis(),
            aulaRepositoryProvider.overrideWithValue(
              MockAulaRepository(
                premium: false,
                conPortadas: true,
                delay: Duration.zero,
              ),
            ),
            imagenDeRedProvider.overrideWithValue(_portadaLocal),
          ],
        ),
        (
          nombre: '3-muro-cursos',
          pantalla: const MuroDeVentaScreen(
            motivo: FuncionDePago(FuncionPremium.cursos),
          ),
          overrides: _enGratis(),
        ),
        (
          nombre: '4-mi-suscripcion',
          pantalla: const MySubscriptionScreen(),
          overrides: _enGratis(),
        ),
      ];

  for (final tienda in tiendas) {
    group(tienda.nombre, () {
      for (final p in pantallas) {
        for (final oscuro in [false, true]) {
          final tema = oscuro ? 'oscuro' : 'claro';

          testWidgets('${p.nombre} · $tema', (tester) async {
            tester.view
              ..devicePixelRatio = 2
              ..physicalSize = tienda.tamano * 2;
            addTearDown(tester.view.reset);

            if (p.nombre == '2-cursos') await _decodificarPortadas(tester);
            await tester.pumpWidget(
              Marco(
                tamano: tienda.tamano,
                oscuro: oscuro,
                overrides: p.overrides,
                child: p.pantalla,
              ),
            );
            for (var i = 0; i < 4; i++) {
              await tester.pump(const Duration(milliseconds: 600));
            }
            await precargarImagenes(tester);
            await tester.pump(const Duration(milliseconds: 300));

            await expectLater(
              find.byType(MaterialApp),
              matchesGoldenFile(
                '_imagenes/tiendas/${tienda.nombre}/${p.nombre}-$tema.png',
              ),
            );

            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(seconds: 5));
          }, variant: TargetPlatformVariant.only(tienda.plataforma));
        }
      }
    });
  }
}

/// Una cuenta nueva: gratis desde el alta, sin día de prueba.
List<Override> _enGratis() => [
  authControllerProvider.overrideWith(_ConSesion.new),
  cupoGratisProvider.overrideWithValue(
    const AccesoGratis(preguntasPorDia: 10, restantesHoy: 6),
  ),
  subscriptionProvider.overrideWith(
    (ref) async => Subscription(
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
      acceso: const AccesoGratis(preguntasPorDia: 10, restantesHoy: 6),
    ),
  ),
];

class _ConSesion extends AuthController {
  @override
  Future<AuthState> build() async => AuthSignedIn(
    User(
      id: 'u1',
      email: 'valeria.rojas@unmsm.edu.pe',
      nombre: 'Valeria Rojas',
      emailVerificado: true,
      universidad: 'UNMSM',
      condicion: StudentCondition.egresado,
      fechaObjetivo: DateTime(2026, 11, 22),
    ),
  );
}

/// Las portadas de producción, reducidas, en `test/fixtures/portadas`.
ImageProvider _portadaLocal(String url, {int? ancho}) {
  final curso = Uri.parse(url).pathSegments.first;
  return _portadas.putIfAbsent(curso, () {
    final archivo = File('test/fixtures/portadas/$curso.jpg');
    return MemoryImage(
      (archivo.existsSync()
              ? archivo
              : File('test/fixtures/portadas/medicina.jpg'))
          .readAsBytesSync(),
    );
  });
}

final _portadas = <String, MemoryImage>{};

/// Decodifica las portadas con el reloj de verdad, antes de montar.
Future<void> _decodificarPortadas(WidgetTester tester) => tester.runAsync(
  () async {
    for (final curso in const [
      'repaso-final',
      'medicina',
      'pediatria',
      'gineco-obstetricia',
      'cirugia',
      'salud-publica',
      'emergencias',
      'ciencias-basicas',
      'etica',
      'gestion',
      'investigacion',
    ]) {
      final lista = Completer<void>();
      _portadaLocal('https://cdn.example/$curso/portada-v2.jpg')
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (_, _) {
                if (!lista.isCompleted) lista.complete();
              },
              onError: (e, _) {
                if (!lista.isCompleted) lista.completeError(e);
              },
            ),
          );
      await lista.future;
    }
  },
);
