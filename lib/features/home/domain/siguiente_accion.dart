import '../../catalog/domain/catalog_models.dart';
import '../../stats/domain/stats_models.dart';

/// Lo que el inicio propone hacer ahora (plan de rediseño §5).
///
/// Es una regla **determinista** sobre datos que la app ya tiene: sin
/// predicciones nuevas, sin IA y sin cifras que no vengan del servidor. La web
/// aplica la misma regla, con el mismo orden y los mismos titulares, para que
/// quien use las dos no reciba consejos distintos.
sealed class SiguienteAccion {
  const SiguienteAccion();
}

/// Hay una sesión a medias. Es lo primero: la persona ya decidió qué estudiar.
final class RetomarSesion extends SiguienteAccion {
  const RetomarSesion({
    required this.sessionId,
    required this.esSimulacro,
    required this.respondidas,
    required this.total,
  });

  final String sessionId;
  final bool esSimulacro;
  final int respondidas;
  final int total;

  /// La que toca, sin pasarse del total.
  int get siguiente => total == 0 ? 0 : (respondidas + 1).clamp(1, total);
}

/// Sin red. Solo se ofrece lo que hay en el teléfono.
final class EstudiarSinConexion extends SiguienteAccion {
  const EstudiarSinConexion({required this.practicasListas});

  /// Prácticas descargadas y listas para usar sin señal.
  final int practicasListas;
}

/// Nunca ha respondido nada: una práctica corta para empezar.
final class PrimeraPractica extends SiguienteAccion {
  const PrimeraPractica();

  /// Diez es el mínimo del selector en las dos plataformas.
  static const cantidad = 10;
}

/// Con historial: el área que el algoritmo de prioridades pone primero.
final class PracticarArea extends SiguienteAccion {
  const PracticarArea({required this.area, this.acierto});

  final CatalogNode area;

  /// Acierto medido en el área, o nulo si todavía no la practicó.
  final double? acierto;

  /// Por qué se sugiere, con los datos reales. Sin acierto medido no se
  /// inventa un porcentaje.
  String get criterio {
    final peso = area.peso;
    final pesa = peso == null ? null : 'Pesa $peso preguntas en el ENAM';
    final avance = acierto == null
        ? 'aún no la practicas'
        : 'vas en ${(acierto! * 100).round()} % de acierto';
    return pesa == null
        ? '${avance[0].toUpperCase()}${avance.substring(1)}.'
        : '$pesa y $avance.';
  }
}

/// No hay datos suficientes para sugerir nada concreto, o algo falló.
final class ElegirArea extends SiguienteAccion {
  const ElegirArea();
}

/// Decide la siguiente acción.
///
/// Orden de prioridad, de arriba abajo:
///
/// 1. Sesión abierta → retomarla.
/// 2. Sin red → lo descargado.
/// 3. Sin ninguna respuesta → primera práctica corta.
/// 4. Con historial → el área prioritaria, explicando por qué.
/// 5. Lo demás (cargando no, eso lo resuelve quien llama; error o datos
///    insuficientes) → elegir un área, sin porcentajes.
///
/// El acceso vencido no llega aquí: lo resuelve la guarda del router antes de
/// pintar el inicio.
///
/// [stats] nulo significa que el dashboard falló o no hay; [prioridades] vacía,
/// que el catálogo no está.
SiguienteAccion decidirSiguienteAccion({
  required ({String sessionId, bool esSimulacro, int respondidas, int total})?
  sesionAbierta,
  required bool sinRed,
  required int practicasOffline,
  required DashboardStats? stats,
  required List<({CatalogNode area, double? acierto})> prioridades,
}) {
  if (sesionAbierta case final s?) {
    return RetomarSesion(
      sessionId: s.sessionId,
      esSimulacro: s.esSimulacro,
      respondidas: s.respondidas,
      total: s.total,
    );
  }

  if (sinRed) return EstudiarSinConexion(practicasListas: practicasOffline);

  if (stats == null) return const ElegirArea();

  final respondidas = stats.porArea.fold(0, (t, a) => t + a.respondidas);
  if (respondidas == 0) return const PrimeraPractica();

  if (prioridades.isEmpty) return const ElegirArea();
  final primera = prioridades.first;
  return PracticarArea(area: primera.area, acierto: primera.acierto);
}
