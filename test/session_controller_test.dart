import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/session_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Verifica la conducción de una sesión: seleccionar, confirmar, avanzar, marcar
/// y cerrar. Es donde vive la lógica que más fácil se rompe al tocar la UI.
void main() {
  late MockSessionRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockSessionRepository();
    container = ProviderContainer(
      overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  Future<SessionState> cargar(String id) async {
    return container.read(sessionControllerProvider(id).future);
  }

  SessionController control(String id) =>
      container.read(sessionControllerProvider(id).notifier);

  group('Práctica', () {
    test('arranca en la primera pregunta', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 5),
      );
      final estado = await cargar(session.id);

      expect(estado.indice, 0);
      expect(estado.seleccion, isNull);
      expect(estado.respondida, isFalse);
    });

    test('seleccionar no responde: hace falta confirmar', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 5),
      );
      var estado = await cargar(session.id);
      final opcion = estado.pregunta.opciones.first;

      control(session.id).seleccionar(opcion.id);
      estado = container.read(sessionControllerProvider(session.id)).value!;

      expect(estado.seleccion, opcion.id);
      // Lo importante: sigue sin responder. Un toque accidental leyendo un caso
      // clínico largo no debe enviar la respuesta.
      expect(estado.respondida, isFalse);
      expect(estado.respuesta, isNull);
    });

    test('responder muestra la retroalimentación (RF-13)', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 5),
      );
      var estado = await cargar(session.id);

      // La clave no se conoce antes de responder, así que se elige a ciegas,
      // como hace el estudiante.
      final elegida = estado.pregunta.opciones.first;
      control(session.id).seleccionar(elegida.id);
      await control(session.id).responder();
      estado = container.read(sessionControllerProvider(session.id)).value!;

      expect(estado.respondida, isTrue);
      expect(estado.respuesta?.esCorrecta, isNotNull);
    });

    // El bug que esto fija: responder solo guardaba el resultado y la pantalla
    // de retroalimentación se quedaba con la pregunta SIN revelar. Sin clave,
    // la interfaz caía a la primera alternativa y la señalaba como correcta
    // —enseñando medicina equivocada—, y la explicación salía como "sin
    // explicación disponible".
    test('tras responder, la pregunta trae clave y explicaciones', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 5),
      );
      var estado = await cargar(session.id);

      expect(estado.pregunta.opciones.every((o) => o.esCorrecta == null), isTrue);

      control(session.id).seleccionar(estado.pregunta.opciones.first.id);
      await control(session.id).responder();
      estado = container.read(sessionControllerProvider(session.id)).value!;

      expect(
        estado.pregunta.opciones.where((o) => o.esCorrecta == true).length,
        1,
        reason: 'debe haber exactamente una alternativa marcada como correcta',
      );
      expect(estado.pregunta.explicacion, isNotNull);
      expect(
        estado.pregunta.opciones.every((o) => o.explicacion != null),
        isTrue,
        reason: 'las cuatro explicaciones son lo que hace que la práctica enseñe',
      );
    });

    test('siguiente limpia la selección y el estado de respondida', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 5),
      );
      var estado = await cargar(session.id);

      control(session.id).seleccionar(estado.pregunta.opciones.first.id);
      await control(session.id).responder();
      control(session.id).siguiente();
      estado = container.read(sessionControllerProvider(session.id)).value!;

      expect(estado.indice, 1);
      expect(estado.seleccion, isNull);
      expect(estado.respondida, isFalse);
    });

    test('no avanza más allá de la última', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 2),
      );
      await cargar(session.id);

      control(session.id)
        ..siguiente()
        ..siguiente()
        ..siguiente();
      final estado = container.read(
        sessionControllerProvider(session.id),
      ).value!;

      expect(estado.indice, 1);
      expect(estado.esUltima, isTrue);
    });

    test('no retrocede antes de la primera', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 3),
      );
      await cargar(session.id);

      control(session.id).anterior();
      final estado = container.read(
        sessionControllerProvider(session.id),
      ).value!;

      expect(estado.indice, 0);
    });

    test('marcar y desmarcar es instantáneo (RF-14)', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 3),
      );
      await cargar(session.id);

      await control(session.id).alternarMarca();
      var estado = container.read(sessionControllerProvider(session.id)).value!;
      expect(estado.marcada, isTrue);

      await control(session.id).alternarMarca();
      estado = container.read(sessionControllerProvider(session.id)).value!;
      expect(estado.marcada, isFalse);
    });

    test('dejar en blanco registra la respuesta sin optionId (RN-01)', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 3),
      );
      final estado = await cargar(session.id);
      final primeraId = estado.pregunta.id;

      await control(session.id).dejarEnBlanco();
      final actual = container.read(
        sessionControllerProvider(session.id),
      ).value!;

      // Queda registrada como vista pero sin opción: en blanco e incorrecta
      // valen igual, pero se distinguen para estadísticas.
      expect(actual.session.respuestas[primeraId]?.optionId, isNull);
      expect(actual.indice, 1);
    });
  });

  group('Simulacro', () {
    test('responder NO abre retroalimentación y avanza solo (RF-16)', () async {
      final session = await repo.startSimulacro(esMuestra: true);
      var estado = await cargar(session.id);

      control(session.id).seleccionar(estado.pregunta.opciones.first.id);
      await control(session.id).responder();
      estado = container.read(sessionControllerProvider(session.id)).value!;

      expect(estado.respondida, isFalse);
      // En simulacro no hay pausa para leer: se avanza.
      expect(estado.indice, 1);
    });

    test('irA salta a cualquier pregunta (RF-17)', () async {
      final session = await repo.startSimulacro(esMuestra: true);
      await cargar(session.id);

      control(session.id).irA(25);
      final estado = container.read(
        sessionControllerProvider(session.id),
      ).value!;

      expect(estado.indice, 25);
    });

    test('irA ignora índices fuera de rango', () async {
      final session = await repo.startSimulacro(esMuestra: true);
      await cargar(session.id);

      control(session.id)
        ..irA(-5)
        ..irA(9999);
      final estado = container.read(
        sessionControllerProvider(session.id),
      ).value!;

      expect(estado.indice, 0);
    });

    test('enviar cierra y devuelve la nota (RN-01)', () async {
      final session = await repo.startSimulacro(esMuestra: true);
      await cargar(session.id);

      final finalizada = await control(session.id).enviar();

      expect(finalizada, isNotNull);
      expect(finalizada!.estado, SessionStatus.finalizada);
      expect(finalizada.nota, isNotNull);
      // Sin responder nada: 0, sin puntaje en contra.
      expect(finalizada.nota, 0.0);
    });
  });

  group('Reanudar (RF-15)', () {
    test('vuelve a la primera sin responder, no al inicio', () async {
      final session = await repo.startPractice(
        const PracticeConfig(cantidadPreguntas: 5),
      );

      // Se responden las tres primeras.
      for (var i = 0; i < 3; i++) {
        await repo.answer(
          sessionId: session.id,
          questionId: session.preguntas[i].id,
          optionId: session.preguntas[i].opciones.first.id,
          tiempoMs: 1000,
        );
      }

      // Un contenedor nuevo simula volver a abrir la app.
      final otro = ProviderContainer(
        overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(otro.dispose);

      final estado = await otro.read(
        sessionControllerProvider(session.id).future,
      );

      expect(estado.indice, 3);
    });
  });
}
