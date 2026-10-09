import '../../../core/config/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../session/domain/session_models.dart';
import '../domain/aula_models.dart';

/// Los endpoints del aula (`enam-backend/AULA.md` §4).
///
/// Sin respaldo local: las URL de los videos salen firmadas y caducan, así que
/// guardarlas no sirve de nada. El aula es con conexión.
abstract interface class AulaRepository {
  /// El catálogo, también los cursos sin publicar («Próximamente»).
  Future<List<CursoResumen>> cursos();

  /// El temario del curso, con la clase para «Continuar».
  Future<Curso> curso(String id);

  /// La clase con sus URL firmadas.
  ///
  /// Da `ForbiddenFailure` con código `FUNCION_PREMIUM` si la clase está
  /// bloqueada para la cuenta.
  Future<Clase> clase(String id);

  /// Lo visto de la clase. El servidor guarda el máximo de [segundosVistos] y
  /// la última [posicionS], y responde si ya cuenta como completada.
  Future<ProgresoDeClase> progreso(
    String claseId, {
    required int segundosVistos,
    required int posicionS,
  });

  /// Una práctica de 5 preguntas sobre el tema de la clase, que se responde
  /// como cualquier otra sesión.
  Future<StudySession> practica(String claseId);

  /// La última clase a medias, o `null` si no hay ninguna.
  Future<SeguirViendo?> seguirViendo();
}

class ApiAulaRepository implements AulaRepository {
  const ApiAulaRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<CursoResumen>> cursos() async {
    final json = await _client.get<List<dynamic>>(ApiEndpoints.aulaCursos);
    return [
      for (final c in json) CursoResumen.fromJson(c as Map<String, dynamic>),
    ];
  }

  @override
  Future<Curso> curso(String id) async => Curso.fromJson(
    await _client.get<Map<String, dynamic>>(
      ApiEndpoints.aulaCurso(Uri.encodeComponent(id)),
    ),
  );

  @override
  Future<Clase> clase(String id) async => Clase.fromJson(
    await _client.get<Map<String, dynamic>>(
      ApiEndpoints.aulaClase(Uri.encodeComponent(id)),
    ),
  );

  @override
  Future<ProgresoDeClase> progreso(
    String claseId, {
    required int segundosVistos,
    required int posicionS,
  }) async => ProgresoDeClase.fromJson(
    await _client.put<Map<String, dynamic>>(
      ApiEndpoints.aulaProgreso(Uri.encodeComponent(claseId)),
      data: {'segundosVistos': segundosVistos, 'posicionS': posicionS},
    ),
  );

  @override
  Future<StudySession> practica(String claseId) async => StudySession.fromJson(
    await _client.post<Map<String, dynamic>>(
      ApiEndpoints.aulaPractica(Uri.encodeComponent(claseId)),
    ),
  );

  @override
  Future<SeguirViendo?> seguirViendo() async {
    final json = await _client.getOpcional<Map<String, dynamic>>(
      ApiEndpoints.aulaContinuar,
    );
    return json == null ? null : SeguirViendo.fromJson(json);
  }
}
