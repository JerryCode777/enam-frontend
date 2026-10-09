import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/failure.dart';
import '../../../core/providers.dart';
import '../data/aula_repository.dart';
import '../data/mock_aula_repository.dart';
import '../domain/aula_models.dart';

/// Los endpoints del aula.
///
/// Viven en la carpeta del aula y no en `core/providers.dart` porque nadie más
/// los usa. Sin respaldo local: las URL de los videos caducan.
final aulaRepositoryProvider = Provider<AulaRepository>((ref) {
  if (AppConfig.useMocks) {
    return MockAulaRepository(
      sesiones: ref.watch(sessionRepositoryRemotoProvider),
    );
  }
  return ApiAulaRepository(ref.watch(apiClientProvider));
});

/// Solo se reintenta lo que puede salir bien a la segunda: la red.
///
/// Riverpod reintenta por defecto cualquier error. Un 403 de una clase de pago
/// o un 404 no cambian por insistir, y cada reintento volvía a abrir el muro.
Duration? soloSiEsLaRed(int intento, Object error) =>
    (error is NetworkFailure || error is TimeoutFailure) && intento < 3
    ? Duration(seconds: 1 << intento)
    : null;

/// El catálogo, en el orden del servidor.
final cursosProvider = FutureProvider.autoDispose<List<CursoResumen>>(
  (ref) => ref.watch(aulaRepositoryProvider).cursos(),
  retry: soloSiEsLaRed,
);

/// El temario de un curso.
final cursoProvider = FutureProvider.autoDispose.family<Curso, String>(
  (ref, id) => ref.watch(aulaRepositoryProvider).curso(id),
  retry: soloSiEsLaRed,
);

/// La clase, con sus URL firmadas.
///
/// **No se refresca sola**: una URL nueva reiniciaría el video a la mitad. Se
/// vuelve a pedir solo cuando la firma caducó (lo decide el reproductor) o al
/// volver a entrar.
final claseProvider = FutureProvider.autoDispose.family<Clase, String>(
  (ref, id) => ref.watch(aulaRepositoryProvider).clase(id),
  retry: soloSiEsLaRed,
);

/// La última clase a medias, para «Seguir viendo».
final seguirViendoProvider = FutureProvider.autoDispose<SeguirViendo?>(
  (ref) => ref.watch(aulaRepositoryProvider).seguirViendo(),
  retry: soloSiEsLaRed,
);

/// Avisa de que cambió lo visto: el catálogo, el temario y «Seguir viendo»
/// se vuelven a pedir. La clase no, por lo mismo que en [claseProvider].
void refrescarAvance(WidgetRef ref) {
  ref.invalidate(cursosProvider);
  ref.invalidate(cursoProvider);
  ref.invalidate(seguirViendoProvider);
}
