import 'dart:math';

import '../../../core/config/api_endpoints.dart';
import '../../../core/domain/blueprint.dart';
import '../../../core/domain/taxonomy.dart';
import '../../../core/network/api_client.dart';
import '../domain/stats_models.dart';

/// Estadísticas y rankings (Módulo 5 del SSD).
abstract interface class StatsRepository {
  Future<DashboardStats> dashboard();
  Future<List<RankingEntry>> rankingGeneral();
}

class ApiStatsRepository implements StatsRepository {
  ApiStatsRepository(this._client);

  final ApiClient _client;

  @override
  Future<DashboardStats> dashboard() async {
    final data = await _client.get<Map<String, dynamic>>(
      ApiEndpoints.statsDashboard,
    );
    return DashboardStats.fromJson(data);
  }

  @override
  Future<List<RankingEntry>> rankingGeneral() async {
    final data = await _client.get<List<dynamic>>(ApiEndpoints.rankingGeneral);
    return data
        .map((e) => RankingEntry.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

class MockStatsRepository implements StatsRepository {
  MockStatsRepository({this.esFree = true, this.sinDatos = false});

  /// Simula un usuario del plan gratuito, para ver el contador de cuota diaria.
  final bool esFree;

  /// Simula el día 1: sin respuestas, la nota proyectada aún no se puede calcular.
  final bool sinDatos;

  final _random = Random(7);
  DashboardStats? _cache;

  @override
  Future<DashboardStats> dashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return _cache ??= _build();
  }

  DashboardStats _build() {
    if (sinDatos) {
      return DashboardStats(
        notaProyectada: 0,
        preguntasVistas: 0,
        preguntasTotalesBanco: 4500,
        porArea: [
          for (final area in Taxonomy.areas)
            AreaPerformance(
              areaId: area.id,
              areaNombre: area.nombre,
              preguntasBlueprint: area.peso ?? 0,
            ),
        ],
        preguntasRestantesHoy: esFree ? Blueprint.freeDailyQuestionLimit : null,
      );
    }

    final porArea = <AreaPerformance>[];
    var vistas = 0;

    for (final area in Taxonomy.areas) {
      final peso = area.peso ?? 0;
      final respondidas = (peso * (1 + _random.nextInt(4))).clamp(0, peso * 5);
      final acierto = 0.42 + _random.nextDouble() * 0.4;
      final correctas = (respondidas * acierto).round();
      vistas += respondidas;

      porArea.add(
        AreaPerformance(
          areaId: area.id,
          areaNombre: area.nombre,
          preguntasBlueprint: peso,
          respondidas: respondidas,
          correctas: correctas,
        ),
      );
    }

    return DashboardStats(
      // Se calcula igual que RN-04: promedio ponderado por el peso del blueprint.
      notaProyectada: _proyectar(porArea),
      preguntasVistas: vistas,
      preguntasTotalesBanco: 4500,
      simulacrosCompletados: 3,
      porArea: porArea,
      evolucion: [
        for (var i = 4; i >= 0; i--)
          GradePoint(
            // Fechas relativas a hoy, hacia atrás cada 12 días.
            fecha: DateTime.now().subtract(Duration(days: i * 12)),
            nota: 9.4 + (4 - i) * 0.55 + _random.nextDouble() * 0.5,
            sessionId: 'sim-${5 - i}',
          ),
      ],
      preguntasRestantesHoy: esFree ? 13 : null,
    );
  }

  /// Promedio ponderado del % de acierto por área, en escala vigesimal (RN-04).
  double _proyectar(List<AreaPerformance> porArea) {
    var suma = 0.0;
    var pesoTotal = 0;

    for (final area in porArea) {
      final acierto = area.porcentajeAcierto;
      if (acierto == null) continue;
      suma += acierto * area.preguntasBlueprint;
      pesoTotal += area.preguntasBlueprint;
    }

    if (pesoTotal == 0) return 0;
    return double.parse(
      (suma / pesoTotal * Blueprint.maxGrade).toStringAsFixed(2),
    );
  }

  @override
  Future<List<RankingEntry>> rankingGeneral() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return [
      for (var i = 1; i <= 20; i++)
        RankingEntry(
          posicion: i,
          usuarioNombre: i == 7 ? 'Tú' : 'Estudiante ${String.fromCharCode(64 + i)}.',
          universidad: ['UNMSM', 'UNSA', 'UPCH', 'UNT'][i % 4],
          promedio: double.parse((17.8 - i * 0.28).toStringAsFixed(2)),
          esUsuarioActual: i == 7,
          tiempoTotalMs: 9600000 + i * 42000,
        ),
    ];
  }
}
