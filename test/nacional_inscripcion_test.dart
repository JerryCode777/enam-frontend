import 'package:enam_app/core/providers.dart';
import 'package:enam_app/features/session/data/session_repository.dart';
import 'package:enam_app/features/session/domain/session_models.dart';
import 'package:enam_app/features/session/presentation/national_mock_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// La inscripción al simulacro nacional la manda el **servidor**.
///
/// Historia de este archivo, que es la razón de que exista:
///
///  1. Primero la inscripción era un `bool` dentro del `State` de la pantalla.
///     Salir y volver la borraba, así que el botón invitaba a participar otra
///     vez en el mismo simulacro.
///  2. Después se movió a `SharedPreferences`. Eso arregló lo de salir y
///     volver, pero no el problema: es el **dispositivo** el que recuerda, no
///     la cuenta. Cambiar de teléfono perdía la inscripción, y entrar desde dos
///     equipos permitía apuntarse dos veces.
///  3. Ahora llega en el campo `inscrito` de `GET /mock-exams`, que es el único
///     sitio que sabe la verdad.
///
/// Lo mismo con el momento del evento —programado, en curso, cerrado—: salía
/// del reloj del dispositivo, y uno adelantado enseñaba "Entrar al simulacro"
/// para algo que el servidor iba a rechazar.
void main() {
  late _RepoDeSesiones repo;

  setUp(() => repo = _RepoDeSesiones());

  ProviderContainer contenedor() {
    final c = ProviderContainer(
      overrides: [sessionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('sin inscribirse, el usuario no figura como participante', () async {
    final c = contenedor();
    await c.read(nacionalesProvider.future);

    expect(c.read(nacionalProvider)?.inscrito, isFalse);
  });

  test('al entrar, el servidor pasa a decir que está inscrito', () async {
    final c = contenedor();
    await c.read(nacionalesProvider.future);
    final evento = c.read(nacionalProvider)!;

    await repo.joinNationalMock(evento.id);
    c.invalidate(nacionalesProvider);
    await c.read(nacionalesProvider.future);

    expect(c.read(nacionalProvider)?.inscrito, isTrue);
  });

  test('la inscripción no depende del dispositivo', () async {
    // Contenedor nuevo con el MISMO repositorio = la misma cuenta desde otro
    // teléfono. Antes esto fallaba: lo que recordaba era el disco del equipo.
    final primera = contenedor();
    await primera.read(nacionalesProvider.future);
    await repo.joinNationalMock(primera.read(nacionalProvider)!.id);

    final segunda = contenedor();
    await segunda.read(nacionalesProvider.future);

    expect(segunda.read(nacionalProvider)?.inscrito, isTrue);
  });

  test('entrar dos veces no duplica la participación', () async {
    final c = contenedor();
    await c.read(nacionalesProvider.future);
    final evento = c.read(nacionalProvider)!;

    await repo.joinNationalMock(evento.id);
    await repo.joinNationalMock(evento.id);

    expect(repo.inscritos, {evento.id});
  });

  test('sin nacional programado no hay evento que enseñar', () async {
    repo.programados = const [];
    final c = contenedor();
    await c.read(nacionalesProvider.future);

    // La tarjeta del inicio y la pantalla se apagan solas. Antes el evento
    // estaba escrito en el código y siempre había uno, existiera o no.
    expect(c.read(nacionalProvider), isNull);
  });

  test('el momento del evento lo decide el servidor, no el reloj local', () {
    // Un nacional que ya empezó según el servidor, con fecha de inicio en el
    // futuro según este reloj. Si la pantalla mirara el reloj diría
    // "programado"; tiene que decir "en curso".
    final desincronizado = NationalMock(
      id: 'nac-1',
      nombre: 'Nacional',
      inicio: DateTime.now().add(const Duration(hours: 2)),
      fin: DateTime.now().add(const Duration(hours: 5)),
      estado: NationalMockStatus.enCurso,
    );

    expect(desincronizado.estado, NationalMockStatus.enCurso);
    // `faltaParaEmpezar` solo tiene sentido en los programados, y por eso
    // devuelve null en el resto en vez de una cuenta atrás que engaña.
    expect(desincronizado.faltaParaEmpezar, isNull);
  });
}

/// Repositorio de sesiones que solo implementa lo del nacional.
///
/// Guarda las inscripciones como lo haría el servidor: por cuenta, no por
/// dispositivo. Es lo que permite que el test de "otro teléfono" signifique
/// algo.
class _RepoDeSesiones implements SessionRepository {
  final inscritos = <String>{};

  List<NationalMock> programados = [
    NationalMock(
      id: 'nac-2026-08',
      nombre: 'Simulacro Nacional · Agosto',
      inicio: DateTime.now().add(const Duration(days: 6)),
      fin: DateTime.now().add(const Duration(days: 6, hours: 3)),
      duracionMinutos: 180,
      participantes: 1847,
      totalPreguntas: 180,
    ),
  ];

  @override
  Future<List<NationalMock>> nationalMocks() async => [
    for (final n in programados) n.copyWith(inscrito: inscritos.contains(n.id)),
  ];

  @override
  Future<StudySession> joinNationalMock(String mockId) async {
    inscritos.add(mockId);
    return StudySession(
      id: 'sesion-nacional',
      tipo: SessionType.simulacroNacional,
      estado: SessionStatus.enCurso,
      iniciadaEn: DateTime.now(),
    );
  }

  @override
  Future<List<OpenSession>> openSessions() async => const [];

  @override
  Future<List<Question>> markedQuestions() async => const [];

  @override
  Future<StudySession> startPractice(PracticeConfig config) =>
      throw UnimplementedError();

  @override
  Future<StudySession> startSimulacro({bool esMuestra = false}) =>
      throw UnimplementedError();

  @override
  Future<StudySession> session(String id) => throw UnimplementedError();

  @override
  Future<Answer> answer({
    required String sessionId,
    required String questionId,
    String? optionId,
    required int tiempoMs,
    bool marcada = false,
  }) => throw UnimplementedError();

  @override
  Future<StudySession> submit(String sessionId) => throw UnimplementedError();
}
