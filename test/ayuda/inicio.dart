import 'dart:async';

import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/auth/domain/auth_models.dart';
import 'package:enam_app/features/catalog/domain/catalog_models.dart';
import 'package:enam_app/features/offline/presentation/offline_providers.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/national_mock_screen.dart';
import 'package:enam_app/features/stats/domain/stats_models.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Los estados del inicio contextual (plan §5), listos para montar.
///
/// Los usan el banco de capturas y las pruebas de comportamiento, para que
/// retraten exactamente lo mismo. Todos los datos son de muestra.
enum EstadoInicio {
  cargando,
  retomar,
  primeraPractica,
  areaPrioritaria,
  elegirArea,
  sinConexion,
}

List<Override> overridesDeInicio(EstadoInicio estado) {
  final conHistorial =
      estado == EstadoInicio.areaPrioritaria ||
      estado == EstadoInicio.retomar ||
      estado == EstadoInicio.sinConexion;

  return [
    authControllerProvider.overrideWith(_ConSesion.new),
    hayRedProvider.overrideWith(
      (ref) => Stream.value(estado != EstadoInicio.sinConexion),
    ),
    reservasProvider.overrideWith((ref) async => 2),
    nacionalesProvider.overrideWith((ref) async => [_nacional]),
    catalogProvider.overrideWith((ref) async => _areas),
    sesionesAbiertasProvider.overrideWith(
      (ref) => switch (estado) {
        EstadoInicio.cargando => Completer<List<OpenSession>>().future,
        EstadoInicio.retomar => Future.value([_abierta]),
        _ => Future.value(const <OpenSession>[]),
      },
    ),
    dashboardProvider.overrideWith(
      (ref) => switch (estado) {
        EstadoInicio.cargando => Completer<DashboardStats>().future,
        EstadoInicio.elegirArea => Future.error(Exception('sin dashboard')),
        _ => Future.value(conHistorial ? _conHistorial : _sinHistorial),
      },
    ),
  ];
}

final _abierta = OpenSession(
  id: 'sesion-abierta',
  tipo: SessionType.practica,
  iniciadaEn: DateTime(2026, 7, 30, 9),
  respondidas: 7,
  totalPreguntas: 20,
);

final _nacional = NationalMock(
  id: 'nac-1',
  nombre: 'Simulacro Nacional',
  inicio: DateTime(2026, 8, 2, 9),
  fin: DateTime(2026, 8, 2, 12),
  participantes: 1240,
);

const _areas = [
  CatalogNode(id: 'medicina', nombre: 'Medicina', nivel: 'area', peso: 40),
  CatalogNode(id: 'pediatria', nombre: 'Pediatría', nivel: 'area', peso: 34),
  CatalogNode(id: 'cirugia', nombre: 'Cirugía', nivel: 'area', peso: 24),
];

const _sinHistorial = DashboardStats(
  notaProyectada: 0,
  preguntasTotalesBanco: 4500,
  porArea: [
    AreaPerformance(
      areaId: 'medicina',
      areaNombre: 'Medicina',
      preguntasBlueprint: 40,
    ),
  ],
);

const _conHistorial = DashboardStats(
  notaProyectada: 12.4,
  preguntasVistas: 262,
  preguntasTotalesBanco: 4500,
  simulacrosCompletados: 1,
  racha: Racha(
    dias: 5,
    diasDeLaSemana: [false, true, true, true, true, true, false],
  ),
  porArea: [
    AreaPerformance(
      areaId: 'medicina',
      areaNombre: 'Medicina',
      preguntasBlueprint: 40,
      respondidas: 120,
      correctas: 62,
    ),
    AreaPerformance(
      areaId: 'pediatria',
      areaNombre: 'Pediatría',
      preguntasBlueprint: 34,
      respondidas: 90,
      correctas: 70,
    ),
    AreaPerformance(
      areaId: 'cirugia',
      areaNombre: 'Cirugía',
      preguntasBlueprint: 24,
      respondidas: 52,
      correctas: 41,
    ),
  ],
);

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
      fechaObjetivo: DateTime(2026, 10, 12),
    ),
  );
}
